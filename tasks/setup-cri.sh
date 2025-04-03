#!/usr/bin/env bash
set -e  # Exit on error

LOG_FILE="logs/setup-cri.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Installing necessary tools..."
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
log "Installing container runtime..."

MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
OSVERSION=$(hostnamectl | awk '/Operating/ { print $4 }')
[ $(arch) = x86_64 ] && PLATFORM=amd64
sudo apt install -y jq

if [ "$MYOS" = "Ubuntu" ]; then
    log "Configuring kernel modules... ⚙️"
cat <<- EOF | sudo tee /etc/modules-load.d/containerd.conf
	overlay
	br_netfilter
EOF

	sudo modprobe overlay
    sudo modprobe br_netfilter

log "Setting sysctl parameters... ⚙️"
        cat <<- EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

        # Apply sysctl params without reboot
    sudo sysctl --system

        # (Install containerd)
    log "Installing containerd... ⚙️"
	CONTAINERD_VERSION=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | jq -r '.tag_name')
	CONTAINERD_VERSION=${CONTAINERD_VERSION#v}
    wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${PLATFORM}.tar.gz
    sudo tar xvf containerd-${CONTAINERD_VERSION}-linux-${PLATFORM}.tar.gz -C /usr/local

    # Configure containerd
    log "Configuring containerd..."
    sudo mkdir -p /etc/containerd
        cat <<- TOML | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      discard_unpacked_layers = true
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
TOML
# expirementing with sandbox_image = "registry.k8s.io/pause:3.10" in future releases.

    RUNC_VERSION=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | jq -r '.tag_name')
    wget https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${PLATFORM}
    sudo install -m 755 runc.${PLATFORM} /usr/local/sbin/runc

    log "Setting up containerd service..."
    wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
    sudo mv containerd.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now containerd

    log "Container runtime installation complete!"
fi

# sudo ln -sf /etc/apparmor.d/runc /etc/apparmor.d/disable/
# sudo apparmor_parser -R /etc/apparmor.d/runc


touch /tmp/container.txt
