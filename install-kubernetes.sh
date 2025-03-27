#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status.

# Function to run a workflow and handle cleanup on failure
run_task() {
    task_name=$1
    cleanup_name=$2

    echo "Running $task_name..."
    ./$task_name || { echo "$task_name failed. Running cleanup..."; ./$cleanup_name; exit 1; }
}

# Run workflows
run_task "tasks/install-dependencies.sh" "cleanups/cleanup-install-dependencies.sh"
# run_task "tasks/disable-swap.sh" "cleanups/cleanup-disable-swap.sh"
run_task "tasks/install-kubernetes-packages.sh" "cleanups/cleanup-install-kubernetes-packages.sh"
# run_task "tasks/initialize-kubernetes.sh" "cleanups/cleanup-initialize-kubernetes.sh"
# run_task "tasks/configure-kubeconfig.sh" "cleanups/cleanup-verify-installation.sh"
# run_task "tasks/install-cni-plugin.sh" "cleanups/cleanup-install-cni-plugin.sh"
# run_task "tasks/verify-installation.sh" "cleanups/cleanup-verify-installation.sh"

echo "Kubernetes cluster installation complete!"

