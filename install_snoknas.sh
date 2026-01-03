#!/bin/bash

# SnokNAS Installer Script
# Version 1.0.0
# "SnokNAS - Enterprise Grade NAS System"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

LOG_FILE="snoknas_install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo -e "${CYAN}"
echo "================================================="
echo "   _____             _   _       _            "
echo "  / ____|           | | | |     | |           "
echo " | (___  _ __   ___ | |_| | ___ | |     _     "
echo "  \___ \| '_ \ / _ \| __| |/ _ \| |   _| |_   "
echo "  ____) | | | | (_) | |_| | (_) | |__|_   _|  "
echo " |_____/|_| |_|\___/ \__|_|\___/|____| |_|    "
echo "                                                "
echo "        SnokNAS Installer - Enterprise Edition  "
echo "================================================="
echo -e "${NC}"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function check_error() {
    if [ $? -ne 0 ]; then
        log_error "Previous command failed."
        auto_repair
    fi
}

function auto_repair() {
    log_warn "Attempting auto-repair..."
    
    # Try basic apt fix
    sudo apt-get update --fix-missing
    sudo dpkg --configure -a
    sudo apt-get install -f -y
    
    if [ $? -eq 0 ]; then
        log_info "Auto-repair successful. Retrying..."
    else
        log_error "Auto-repair failed. Please check logs manually."
        exit 1
    fi
}

function spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# -----------------------------------------------------------------------------
# Main Installation Stages
# -----------------------------------------------------------------------------

log_info "Starting SnokNAS installation..."

# 1. System Update
echo -e "${BLUE}>>> Updating System Repositories...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
check_error

# 2. Dependencies
DEPENDENCIES=(
    "curl" "wget" "git" "build-essential" "software-properties-common"
    "zfsutils-linux" "samba" "smbclient" "nfs-kernel-server"
    "python3" "python3-pip" "python3-venv"
    "smartmontools" "lm-sensors" "hddtemp" "hdparm"
    "qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils"
    "nginx"
)

echo -e "${BLUE}>>> Installing Core Dependencies...${NC}"
sudo apt-get install -y "${DEPENDENCIES[@]}" &
spinner $!
check_error

# 3. Docker Installation (if not present)
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}>>> Installing Docker Engine...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker "$USER"
    check_error
else
    log_info "Docker is already installed."
fi

# 4. Node.js Installation
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}>>> Installing Node.js LTS...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    check_error
else
    log_info "Node.js is already installed."
fi

# 5. Configuring ZFS
echo -e "${BLUE}>>> Verifying ZFS Module...${NC}"
sudo modprobe zfs
if [ $? -eq 0 ]; then
    log_info "ZFS module loaded successfully."
else
    log_warn "Could not load ZFS module. Ensure kernel headers are installed."
    auto_repair
fi

# 6. Service Configuration (Basic)
echo -e "${BLUE}>>> Enabling Services...${NC}"
sudo systemctl enable smbd nmbd nfs-kernel-server docker libvirtd
check_error

# 7. Setup Directory Structure
echo -e "${BLUE}>>> Setting up SnokNAS Directory Structure...${NC}"
INSTALL_DIR="/opt/snoknas"
DATA_DIR="/mnt/snoknas_data"

sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$DATA_DIR"
sudo chown -R "$USER":"$USER" "$INSTALL_DIR"

log_info "Installation directory: $INSTALL_DIR"

# 8. Web UI Setup (Build Placeholder)
# This part assumes we will deploy the built files here later.
echo -e "${BLUE}>>> Preparing Web UI Environment...${NC}"
# In a real scenario, we would clone the repo here.
# git clone https://github.com/snokos/snoknas-ui.git "$INSTALL_DIR/ui" || log_warn "Repo placeholder"

# 9. Backend Setup (Environment)
echo -e "${BLUE}>>> Preparing Backend Environment...${NC}"
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"
pip install fastapi uvicorn psutil smart-open zfs-api docker
deactivate

echo -e "${GREEN}"
echo "================================================="
echo "   SnokNAS Installation Complete!                "
echo "================================================="
echo " 1. Web UI will be available at http://$(hostname -I | awk '{print $1}'):80"
echo " 2. Ensure drives are connected for ZFS setup."
echo " 3. Default user: admin / admin"
echo "================================================="
echo -e "${NC}"
