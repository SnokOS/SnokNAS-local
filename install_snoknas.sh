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

# 1.1 Remove Broken Repos (Fix for 45drives error)
if [ -f /etc/apt/sources.list.d/45drives.list ]; then
    log_warn "Removing broken 45drives repository..."
    rm -f /etc/apt/sources.list.d/45drives.list
fi

# 2. Dependencies
DEPENDENCIES=(
    "curl" "wget" "git" "build-essential" "software-properties-common"
    "zfsutils-linux" "samba" "smbclient" "nfs-kernel-server"
    "python3" "python3-pip" "python3-venv"
    "smartmontools" "lm-sensors" "hdparm"
    "qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils"
    "nginx" "npm" "nodejs"
)

echo -e "${BLUE}>>> Installing Core Dependencies...${NC}"
sudo apt-get update --allow-releaseinfo-change
# Forced install of critical packages first to ensure command availability
sudo apt-get install -y nginx npm nodejs
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

# 8. Web UI Setup (Build & Deploy)
echo -e "${BLUE}>>> Building Web UI...${NC}"
# We assume the source is in the current directory where the script is run
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -d "$SCRIPT_DIR/web-ui" ]; then
    echo "Found Web UI source. Copying to install directory..."
    cp -r "$SCRIPT_DIR/web-ui" "$INSTALL_DIR/"
    
    echo "Installing NPM dependencies..."
    cd "$INSTALL_DIR/web-ui" || exit
    # Attempt to install dependencies
    # Fix for npm not found: reload bash hash or specify path if needed, but apt install should handle it.
    hash -r
    npm install --silent
    check_error
    
    echo "Building React Application..."
    npm run build
    check_error
else
    log_error "Web UI source directory not found in $SCRIPT_DIR/web-ui"
    exit 1
fi

# 9. Backend Setup
echo -e "${BLUE}>>> Setting up Backend...${NC}"
cp -r "$SCRIPT_DIR/backend" "$INSTALL_DIR/"
cd "$INSTALL_DIR/backend" || exit
pip install -r requirements.txt --break-system-packages
check_error

# 10. Service Configuration (Nginx & Systemd)
echo -e "${BLUE}>>> Configuring Services...${NC}"

# Nginx
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
cp "$SCRIPT_DIR/snoknas.nginx" /etc/nginx/sites-available/snoknas
ln -sf /etc/nginx/sites-available/snoknas /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
check_error

# Systemd Backend
cp "$SCRIPT_DIR/snoknas-backend.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable snoknas-backend
systemctl start snoknas-backend
check_error

echo -e "${GREEN}"
echo "================================================="
echo "   SnokNAS Installation Complete!                "
echo "================================================="
echo " 1. Access Dashboard at: http://$(hostname -I | awk '{print $1}')"
echo " 2. Backend API is active."
echo " 3. Default user: admin / admin"
echo "================================================="
echo -e "${NC}"

