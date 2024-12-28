#!/bin/bash

# This script installs and configures a single-node SLURM cluster on Ubuntu.
# Improved for idempotency, error handling, and resolving MUNGE and SLURM setup issues.

set -e  # Exit immediately on error
set -u  # Treat unset variables as errors
set -o pipefail  # Catch errors in piped commands

log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
    exit 1
}

# Update package list
log "Updating package list..."
sudo apt update || error "Failed to update package list."

# Create SLURM user and group before installing packages
if ! id -u slurm >/dev/null 2>&1; then
    log "Creating SLURM user and group..."
    sudo groupadd slurm || error "Failed to create SLURM group."
    sudo useradd -r -g slurm -d /nonexistent -s /usr/sbin/nologin slurm || error "Failed to create SLURM user."
else
    log "SLURM user and group already exist. Skipping."
fi

# Install necessary packages
log "Installing required packages..."
sudo apt install -y slurmd slurmctld munge libmunge-dev libmunge2 || error "Failed to install required packages."

# Create necessary directories with appropriate permissions
log "Setting up directories and permissions..."
dirs=(/etc/slurm-llnl /var/lib/slurm-llnl /var/log/slurm-llnl /var/spool/slurmd /run/slurm-llnl)
for dir in "${dirs[@]}"; do
    sudo mkdir -p "$dir" || error "Failed to create directory $dir."
    sudo chown -R slurm:slurm "$dir" || error "Failed to set ownership for $dir."
    sudo chmod -R 755 "$dir" || error "Failed to set permissions for $dir."
done

# Generate MUNGE key if it doesn't exist
if [ ! -f /etc/munge/munge.key ]; then
    log "Generating MUNGE key..."
    if command -v create-munge-key >/dev/null 2>&1; then
        sudo /usr/sbin/create-munge-key || error "Failed to create MUNGE key using create-munge-key."
    else
        log "create-munge-key not found, generating manually..."
        sudo dd if=/dev/urandom bs=1 count=1024 of=/etc/munge/munge.key || error "Failed to generate MUNGE key manually."
        sudo chown munge: /etc/munge/munge.key || error "Failed to set ownership of MUNGE key."
        sudo chmod 400 /etc/munge/munge.key || error "Failed to set permissions for MUNGE key."
    fi
else
    log "MUNGE key already exists. Skipping."
fi

# Enable and start MUNGE service
log "Starting and enabling MUNGE service..."
sudo systemctl enable --now munge || error "Failed to start or enable MUNGE service."

# Wait for MUNGE to start properly
sleep 2

# Create SLURM configuration file
log "Creating SLURM configuration file..."
sudo tee /etc/slurm-llnl/slurm.conf > /dev/null <<EOL
# SLURM configuration for a single-node setup

ClusterName=single_node_cluster
ControlMachine=$(hostname)

AuthType=auth/munge
SlurmUser=slurm
StateSaveLocation=/var/lib/slurm-llnl
SlurmdSpoolDir=/var/spool/slurmd
SlurmctldPidFile=/run/slurm-llnl/slurmctld.pid
SlurmdPidFile=/run/slurm-llnl/slurmd.pid
SlurmctldLogFile=/var/log/slurm-llnl/slurmctld.log
SlurmdLogFile=/var/log/slurm-llnl/slurmd.log

SlurmctldPort=6817
SlurmdPort=6818

SchedulerType=sched/backfill
SelectType=select/cons_res
SelectTypeParameters=CR_Core

SlurmctldDebug=info
SlurmdDebug=info

NodeName=$(hostname) CPUs=$(nproc) RealMemory=$(free -m | awk '/^Mem:/{print $2}') State=UNKNOWN
PartitionName=debug Nodes=$(hostname) Default=YES MaxTime=INFINITE State=UP
EOL

# Enable and start SLURM services
log "Starting and enabling SLURM services..."
sudo systemctl enable --now slurmctld || error "Failed to start or enable slurmctld service."
sudo systemctl enable --now slurmd || error "Failed to start or enable slurmd service."

log "SLURM single-node cluster installation completed successfully."
