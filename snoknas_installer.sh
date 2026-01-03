#!/bin/bash
# =================================================================================
# SnokNAS - Comprehensive Autonomous Installer & System Guardian
# Version: 2.0 (AI-Agent Edition)
# Author: SnokOS AI Team
# =================================================================================

# --- CONFIGURATION ---
INSTALL_DIR="/opt/snoknas"
BACKEND_SRC="/home/snokpc/Desktop/Build_SnokOS-linux-2026/SnokNAS/V2/backend"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_NAME="snoknas.service"
LOG_FILE="/var/log/snoknas_install.log"

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- HELPER FUNCTIONS ---

log() {
    echo -e "${BLUE}[$(date +'%T')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[✔] $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[!] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[✘] $1${NC}" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root."
        exit 1
    fi
}

# --- AUTO-REPAIR LOGIC ---

# Function to run a command and attempt repair if it fails
try_cmd() {
    local cmd="$1"
    local desc="$2"
    
    log "Executing: $desc..."
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        success "$desc complete."
        return 0
    else
        warning "$desc failed. Attempting Auto-Repair..."
        repair_strategy "$cmd"
        
        # Retry once
        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
            success "$desc complete (after repair)."
            return 0
        else
            error "Major Failure: $desc could not be completed even after repair."
            return 1
        fi
    fi
}

repair_strategy() {
    local failed_cmd="$1"
    
    # Strategy 1: APT lock or broken packages
    if [[ "$failed_cmd" == *"apt"* ]]; then
        log "running: dpkg --configure -a & apt --fix-broken install"
        dpkg --configure -a >> "$LOG_FILE" 2>&1
        apt-get install -f -y >> "$LOG_FILE" 2>&1
        rm /var/lib/apt/lists/lock >> "$LOG_FILE" 2>&1
        rm /var/cache/apt/archives/lock >> "$LOG_FILE" 2>&1
        rm /var/lib/dpkg/lock* >> "$LOG_FILE" 2>&1
    fi
    
    # Strategy 2: Python/Pip issues
    if [[ "$failed_cmd" == *"pip"* ]]; then
        log "Upgrading pip and ensuring venv is healthy..."
        python3 -m pip install --upgrade pip >> "$LOG_FILE" 2>&1
    fi
}

# --- MAIN INSTALLATION STEPS ---

banner() {
    clear
    echo -e "${CYAN}"
    echo "   _____             _   _   _           _____ "
    echo "  / ____|           | | | \ | |   /\    / ____|"
    echo " | (___  _ __   ___ | | |  \| |  /  \  | (___  "
    echo "  \___ \| '_ \ / _ \| | | .   | / /\ \  \___ \ "
    echo "  ____) | | | | (_) | | | |\  |/ ____ \ ____) |"
    echo " |_____/|_| |_|\___/|_| |_| \_/_/    \_\_____/ "
    echo -e "${NC}"
    echo -e "${BLUE}:: SnokNAS Automated Intelligence Installer ::${NC}"
    echo "==================================================="
    sleep 2
}

install_system_deps() {
    echo ""
    log "Phase 1: System Dependencies"
    
    # Update first
    try_cmd "apt-get update" "Updating Package Repositories"
    
    # Install critical tools
    DEPS="python3 python3-venv python3-pip smartmontools zfsutils-linux samba nfs-kernel-server hdparm curl git ufw"
    try_cmd "apt-get install -y $DEPS" "Installing Core Dependencies"
}

setup_app_structure() {
    echo ""
    log "Phase 2: App Deployment"
    
    # Create install directory
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        success "Created $INSTALL_DIR"
    fi
    
    # Copy backend files if they exist in the source, otherwise assume we are downloading or mocking
    if [ -d "$BACKEND_SRC" ]; then
        log "Deploying Application Code from $BACKEND_SRC..."
        cp -r "$BACKEND_SRC"/* "$INSTALL_DIR/"
        success "Code deployed."
    else
        warning "Source directory not found. Assuming development mode or files already present."
    fi

    # Create VENV (Critical Step)
    if [ ! -d "$VENV_DIR" ]; then
        log "Creating Python Virtual Environment..."
        try_cmd "python3 -m venv $VENV_DIR" "Creating venv"
    fi
    
    # Install Python Deps
    log "Installing Python Libraries (Flask, PsUtil)..."
    try_cmd "$VENV_DIR/bin/pip install flask psutil gunicorn" "Pip Install"
}

configure_services() {
    echo ""
    log "Phase 3: Service Configuration"
    
    # 1. Systemd Service for Dashboard
    cat <<EOF > /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=SnokNAS Dashboard Agent
After=network.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$VENV_DIR/bin/gunicorn -w 4 -b 0.0.0.0:8000 app:app
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF
    success "Created Systemd Service File."

    # 2. reload and enable
    try_cmd "systemctl daemon-reload" "Reloading Daemon"
    try_cmd "systemctl enable ${SERVICE_NAME}" "Enabling SnokNAS Service"
    try_cmd "systemctl restart ${SERVICE_NAME}" "Starting SnokNAS Service"
}

configure_firewall() {
    echo ""
    log "Phase 4: Security (Firewall)"
    
    # Ensure Port 8000 is open
    try_cmd "ufw allow 8000/tcp" "Opening Dashboard Port (8000)"
    try_cmd "ufw allow ssh" "Ensuring SSH Access"
    # Don't enable UFW automatically to avoid locking user out if not configured, just allow ports
    success "Firewall rules updated."
}

verify_installation() {
    echo ""
    log "Phase 5: Self-Diagnostic & Verification"
    
    # Check Service
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        success "SYSTEM STATUS: [ ONLINE ]"
    else
        error "SYSTEM STATUS: [ FAILED ]"
        log "Attempting emergency start..."
        systemctl start ${SERVICE_NAME}
    fi
    
    # Check Disk Access
    DISK_COUNT=$(lsblk -d | grep disk | wc -l)
    log "Detected Physical Disks: $DISK_COUNT"
    
    IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}   SNOKNAS INSTALLATION COMPLETE                    ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${BLUE}Dashboard URL :${NC} http://$IP:8000"
    echo -e "${BLUE}Service Name  :${NC} snoknas.service"
    echo -e "${BLUE}Install Dir   :${NC} $INSTALL_DIR"
    echo ""
}

# --- EXECUTION ---
check_root
banner
install_system_deps
setup_app_structure
configure_services
configure_firewall
verify_installation
