# Single-Node SLURM Cluster Installation Script

## Overview
This script automates the installation and configuration of a single-node SLURM cluster on an Ubuntu system. It ensures idempotency, robust error handling, and proper setup of all necessary components, including MUNGE and SLURM services.

---

## Features
- Automates the creation of the SLURM user and group.
- Installs required packages (`slurmd`, `slurmctld`, `munge`, etc.).
- Configures necessary directories with appropriate permissions.
- Automatically generates a MUNGE authentication key (fallback to manual generation if needed).
- Creates a basic `slurm.conf` configuration for a single-node setup.
- Starts and enables the MUNGE and SLURM services (`slurmctld` and `slurmd`).

---

## Prerequisites
- **Ubuntu OS**: Ensure you are running a compatible version of Ubuntu.
- **Root Privileges**: The script must be executed with `sudo` to ensure proper permissions.

---

## Usage Instructions

### Step 1: Download the Script
Save the script to a file, for example, `setup_slurm.sh`:
```bash
nano setup_slurm.sh
# Paste the script content
```

### Step 2: Make the Script Executable
Make the script executable:
```bash
chmod +x setup_slurm.sh
```

### Step 3: Run the Script
Run the script with `sudo`:
```bash
sudo ./setup_slurm.sh
```

---

## Output
Upon successful execution, the script will:
1. Install and configure SLURM and MUNGE.
2. Create a working `slurm.conf` configuration for the cluster.
3. Start the SLURM services (`slurmctld` and `slurmd`).
4. Log a success message:
   ```
   [INFO] SLURM single-node cluster installation completed successfully.
   ```

---

## Troubleshooting
### 1. **Permission Denied for MUNGE Key**
If the script encounters a `Permission denied` error when generating the MUNGE key:
- Ensure the script is run with `sudo`.
- Verify the `/etc/munge/` directory exists and has correct ownership:
  ```bash
  sudo chown munge: /etc/munge
  sudo chmod 700 /etc/munge
  ```

### 2. **SLURM Services Not Starting**
If SLURM services fail to start:
- Check the logs for detailed error messages:
  ```bash
  sudo journalctl -u slurmctld
  sudo journalctl -u slurmd
  ```

### 3. **Test SLURM**
After the script completes, test the SLURM setup using:
```bash
sinfo
```
You should see the partition and node information.

---

## Notes
- The `slurm.conf` file created by this script is a basic configuration suitable for single-node setups. Modify it as needed for more complex deployments.
- Ensure network ports `6817` and `6818` are not blocked by a firewall if running in a restricted environment.

---

## License
This script is provided under the MIT License. Use and modify it as needed.

---

## Author
This script was created to simplify the setup of a SLURM cluster for single-node use cases. For questions or support, feel free to reach out!
