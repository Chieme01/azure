#!/bin/bash

# Create the .kube directory in the user's home directory
mkdir -p $HOME/.kube

# Copy the Kubernetes admin configuration file to the .kube directory
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Change the ownership of the copied configuration file to the current user
sudo chown $(id -u):$(id -g) $HOME/.kube/config

KUBEJOIN=$(sudo kubeadm token create --print-join-command)

az login --identity

az keyvault secret set --vault-name "lockkeyvault" --name "kubejoin" --value "$KUBEJOIN"