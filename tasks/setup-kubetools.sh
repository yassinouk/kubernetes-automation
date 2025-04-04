#!/usr/bin/env bash
set -e  # Exit on error

LOG_FILE="logs/setup-kubetools.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Installing Kubernetes packages..."

if ! [ -f /tmp/container.txt ]
 then
    log "Container runtime is not installed! Run setup-cri.sh first."
    exit 4
fi

# setting MYOS variable
MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
OSVERSION=$(hostnamectl | awk '/Operating/ { print $4 }')

# detecting latest Kubernetes version
KUBEVERSION=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | jq -r '.tag_name')
KUBEVERSION=${KUBEVERSION%.*}


if [ $MYOS = "Ubuntu" ]
then
	echo RUNNING UBUNTU CONFIG
	cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
	br_netfilter
EOF
    
    sudo apt-get update && sudo apt-get install -y apt-transport-https curl
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sleep 2

    log "Installing Kubernetes tools..."
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo swapoff -a
	
    sudo sed -i 's/\/swap/#\/swap/' /etc/fstab
fi

# Set iptables bridging
#sudo cat <<EOF >  /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sudo sysctl --system

sudo crictl config --set \
    runtime-endpoint=unix:///run/containerd/containerd.sock
echo 'after initializing the control node, follow instructions and use kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml to install the calico plugin (control node only). On the worker nodes, use sudo kubeadm join ... to join'
log "Kubernetes package installation complete!"
exit