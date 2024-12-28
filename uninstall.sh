#!/bin/bash

# This script uninstalls SLURM and MUNGE from the system.

# Stop SLURM and MUNGE services
sudo systemctl stop slurmctld
sudo systemctl stop slurmd
sudo systemctl stop munge

# Disable SLURM and MUNGE services
sudo systemctl disable slurmctld
sudo systemctl disable slurmd
sudo systemctl disable munge

# Remove SLURM and MUNGE packages
sudo apt remove --purge -y slurm-wlm munge

# Remove SLURM user and group
sudo userdel -r slurm
sudo groupdel slurm

# Remove configuration and data directories
sudo rm -rf /etc/slurm-llnl /var/log/slurm-llnl /var/lib/slurm-llnl /var/spool/slurmd /run/slurm-llnl
sudo rm -rf /etc/munge /var/log/munge /var/lib/munge /run/munge

echo "SLURM single-node cluster uninstallation completed."

