#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status.

LOG_FILE="logs/install-kubernetes.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "[INFO] Kubernetes installation started at $(date)"

# Function to run a task with logging
run_task() {
    task_script=$1
    echo "[INFO] Running: $task_script"
    if ./$task_script; then
        echo "[SUCCESS] Completed: $task_script"
    else
        echo "[ERROR] Failed: $task_script"
        exit 1
    fi
}

# Step 1: Install Container Runtime (ContainerD)
run_task "tasks/setup-cri.sh"

# Step 2: Install Required Dependencies
run_task "tasks/setup-kubetools.sh"

log "[INFO] Kubernetes cluster installation completed successfully at $(date)"