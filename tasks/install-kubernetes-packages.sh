#!/bin/bash
set -e

LOG_FILE="logs/install-kubernetes-packages.log"
echo "Installing Kubernetes packages..." | tee -a $LOG_FILE

# Update apt package index
echo "Updating apt package index..." | tee -a $LOG_FILE
if ! sudo apt-get update >> $LOG_FILE 2>&1; then
    echo "Failed to update package index. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

# Install kubelet, kubeadm, kubectl
echo "Installing Kubernetes packages (kubelet, kubeadm, kubectl)..." | tee -a $LOG_FILE
if ! sudo apt-get install -y kubelet kubeadm kubectl >> $LOG_FILE 2>&1; then
    echo "Failed to install Kubernetes packages. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

# Hold the Kubernetes packages to prevent upgrades
echo "Holding Kubernetes packages at current version..." | tee -a $LOG_FILE
if ! sudo apt-mark hold kubelet kubeadm kubectl >> $LOG_FILE 2>&1; then
    echo "Failed to hold Kubernetes packages. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

echo "Kubernetes packages installed and held successfully!" | tee -a $LOG_FILE

