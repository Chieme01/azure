#!/bin/sh
set -e
mkdir -p /devops

# Install and configure prerequisites
# Enable IPv4 packet forwardin
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Optional verify
sysctl net.ipv4.ip_forward >> "/devops/kubeadm_init_output.txt"

# Install CRI-O
# Install the dependencies for adding repositories
apt-get update
apt-get install -y software-properties-common curl

# Add the Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# Add the CRI-O repository
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

# Install the packages
apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Review this!
# Configure a Container Network Interface (CNI) plugin
# The CRI-O package ships a default IPv4 and IPv6 (dual stack) configuration for the bridge plugin, which is disabled by default. The configuration can be enabled by renaming the disabled configuration file in /etc/cni/net.d:
mv /etc/cni/net.d/10-crio-bridge.conflist.disabled /etc/cni/net.d/10-crio-bridge.conflist

# Start CRI-O
systemctl start crio.service

# Enable the kubelet service before running kubeadm
systemctl enable --now kubelet

# Bootstrap a cluster
swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1

kubeadm init --pod-network-cidr=10.244.0.0/16  >> "/devops/kubeadm_init_output.txt" 2>&1