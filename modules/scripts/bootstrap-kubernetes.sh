#!/bin/sh
# Exit on error, but we'll use a trap to log the failure before we die
set -e

# These are now placeholders that Terraform will fill
export KUBERNETES_VERSION="${k8s_version}"
export CRIO_VERSION="${crio_version}"

mkdir -p /devops
LOG_FILE="/devops/kubeadm_init_output.txt"

# Function to log start, success, and failure of steps
log_action() {
    local description="$1"
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTING: $description" >> "$LOG_FILE"
    
    # Execute the command and capture output
    if "$@" >> "$LOG_FILE" 2>&1; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $description" >> "$LOG_FILE"
        echo "------------------------------------------------" >> "$LOG_FILE"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] FAILED: $description" >> "$LOG_FILE"
        exit 1
    fi
}

# --- SCRIPT STEPS ---

log_action "Enabling IPv4 Forwarding" sh -c 'echo "net.ipv4.ip_forward = 1" | tee /etc/sysctl.d/k8s.conf && sysctl --system'

log_action "Installing software-properties-common and curl" apt-get update && apt-get install -y software-properties-common curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

# log_action "Adding Kubernetes Repository" sh -c "
#     curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg &&
#     echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
# "

# log_action "Adding the CRI-O repository" sh -c "
#     curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg &&
#     echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list
# "

log_action "Installing K8s Packages (cri-o, kubelet, kubeadm, kubectl)" sh -c "
    apt-get update && 
    apt-get install -y cri-o kubelet kubeadm kubectl && 
    apt-mark hold kubelet kubeadm kubectl
"

log_action "Enabling CRI-O Bridge Plugin" \
    mv /etc/cni/net.d/10-crio-bridge.conflist.disabled /etc/cni/net.d/10-crio-bridge.conflist

log_action "Starting CRI-O Service" \
    systemctl start crio.service

# Note: Kubelet will flap/crash until 'kubeadm init' is run, this is normal.
log_action "Enabling Kubelet service" \
    systemctl enable --now kubelet

log_action "Disabling Swap" swapoff -a

log_action "Loading br_netfilter module" modprobe br_netfilter

log_action "Forcing IPv4 Forwarding (Final check)" sysctl -w net.ipv4.ip_forward=1

log_action "Initializing Kubernetes Cluster" \
    kubeadm init --pod-network-cidr=${pod_network_cidr} --apiserver-advertise-address=$(hostname -I | awk '{print \$1}')

log_action "Configuring Kubeconfig for ${target_user}" sh -c '
    # Define the target user
    TARGET_USER="${target_user}"
    TARGET_HOME="/home/$TARGET_USER"

    # Create the directory
    mkdir -p "$TARGET_HOME/.kube"

    # Copy the config from the system location
    cp -i /etc/kubernetes/admin.conf "$TARGET_HOME/.kube/config"

    # Set the correct ownership so the user can actually read/write it
    chown $(id -u $TARGET_USER):$(id -g $TARGET_USER) "$TARGET_HOME/.kube/config"
'

log_action "Installing Helm" sh -c '
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
'
# Wait for the API Server port to start listening
until nc -z localhost 6443; do
  echo "Waiting for Kubernetes API Server..." >> "$LOG_FILE"
  sleep 2
done

log_action "Installing Cilium" sh -c '
    helm repo add cilium https://helm.cilium.io/

    KUBECONFIG=/etc/kubernetes/admin.conf helm install cilium cilium/cilium \
        --namespace kube-system \
        --set ipam.operator.clusterPoolIPv4PodCIDRList="${pod_network_cidr}"
'
