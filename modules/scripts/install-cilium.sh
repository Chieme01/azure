#!/bin/sh

set -e

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

# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

log_action "Installing Cilium network add-on" cilium install --version 1.19.3