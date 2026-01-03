#!/bin/bash

# SnokNAS Installer
# This script installs all necessary dependencies for SnokNAS and sets up the environment.

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check for root
if [ "$EUID" -ne 0 ]; then
  log_error "Please run as root"
  exit 1
fi

log_info "Starting SnokNAS Environment Setup..."

# 1. Update System
log_info "Updating system repositories..."
apt-get update

# 2. Install System Dependencies
log_info "Installing system dependencies (ZFS, Samba, NFS, SMART, Python)..."
apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    smartmontools \
    samba \
    nfs-kernel-server \
    zfsutils-linux \
    git \
    curl \
    hdparm \
    pciutils

# 3. Setup Python Backend
BASE_DIR="/home/snokpc/Desktop/Build_SnokOS-linux-2026/SnokNAS"
BACKEND_DIR="$BASE_DIR/backend"
VENV_DIR="$BASE_DIR/venv"

log_info "Setting up Python Virtual Environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv and install requirements
# We assume requirements.txt exists or we install manually
log_info "Installing Python packages..."
"$VENV_DIR/bin/pip" install flask psutil gunicorn

# 4. Create Systemd Service
SERVICE_FILE="/etc/systemd/system/snoknas.service"

log_info "Creating Systemd Service at $SERVICE_FILE..."
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=SnokNAS Backend Agent
After=network.target

[Service]
User=root
WorkingDirectory=$BACKEND_DIR
ExecStart=$VENV_DIR/bin/gunicorn -w 4 -b 0.0.0.0:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 5. Auto-Repair & Verification Function
check_and_fix() {
    log_info "Running Auto-Repair & Diagnostics..."
    
    # Check 1: Python Virtual Environment
    if [ ! -f "$VENV_DIR/bin/python3" ]; then
        log_error "Virtual Environment broken or missing. Recreating..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install -r "$BACKEND_DIR/requirements.txt"
    else
        log_info "✔ Python Venv: OK"
    fi

    # Check 2: Service Status
    if ! systemctl is-active --quiet snoknas; then
        log_error "Service is not running. Attempting to start..."
        systemctl daemon-reload
        systemctl enable snoknas
        systemctl start snoknas
        sleep 2
        if systemctl is-active --quiet snoknas; then
             log_info "✔ Service Started Successfully"
        else
             log_error "✘ Service Failed to Start. Check logs: journalctl -u snoknas"
        fi
    else
        log_info "✔ SnokNAS Service: RUNNING"
    fi

    # Check 3: Permissions
    chown -R root:root "$BASE_DIR"
    log_info "✔ Permissions Fixed"
}

# 6. Final Steps
log_info "Reloading systemd daemon..."
systemctl daemon-reload
systemctl enable snoknas

# Run the repair/check function
check_and_fix

log_info "SnokNAS System Setup Complete!"
log_info "Access the Dashboard at: http://$(hostname -I | awk '{print $1}'):8000"

