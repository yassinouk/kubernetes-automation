#!/usr/bin/env bash
set -e

LOG_FILE="logs/install-dependencies.log"
echo "Installing dependencies..." | tee -a $LOG_FILE

echo "Detecting package manager..."

# Check for package manager
if command -v apt >/dev/null 2>&1; then
    PM="apt"
else
    echo "No supported package manager found. Exiting." | tee -a $LOG_FILE
    exit 1
fi

echo "Using $PM to install dependencies..." | tee -a $LOG_FILE

# Update apt package index
echo "Updating apt package index..." | tee -a $LOG_FILE
if ! sudo apt-get update >> $LOG_FILE 2>&1; then
    echo "Failed to update package index. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

# Install dependencies
echo "Installing required dependencies..." | tee -a $LOG_FILE
if ! sudo apt-get install -y apt-transport-https ca-certificates curl gpg >> $LOG_FILE 2>&1; then
    echo "Failed to install dependencies. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

# Remove existing Kubernetes key file if it exists (to avoid overwrite prompt)
if [ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
    echo "Removing existing Kubernetes APT key..." | tee -a $LOG_FILE
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
fi

# Add Kubernetes APT repository (Ubuntu/Debian)
echo "Adding Kubernetes APT repository..." | tee -a $LOG_FILE
if ! curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg; then
    echo "Failed to add Kubernetes APT repository key. Check logs for details." | tee -a $LOG_FILE
    exit 1
fi

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >> $LOG_FILE 2>&1

echo "Dependencies installed successfully!" | tee -a $LOG_FILE
