#!/bin/bash

#===============================================================================
# Netdata Setup Script
# Description: Install and configure Netdata monitoring agent
# Usage: sudo ./setup.sh
#
# Project: https://roadmap.sh/projects/simple-monitoring
#===============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
NETDATA_CONFIG_DIR="/etc/netdata"
HEALTH_CONFIG_DIR="${NETDATA_CONFIG_DIR}/health.d"

echo ""
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}           NETDATA MONITORING SETUP                    ${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (sudo ./setup.sh)${NC}"
    exit 1
fi

#===============================================================================
# Step 1: Update System
#===============================================================================
echo -e "${CYAN}[1/5] Updating system packages...${NC}"
apt update -qq
echo -e "${GREEN}✓ System updated${NC}"
echo ""

#===============================================================================
# Step 2: Install Netdata
#===============================================================================
echo -e "${CYAN}[2/5] Installing Netdata...${NC}"

# Check if Netdata is already installed
if command -v netdata &> /dev/null; then
    echo -e "${YELLOW}Netdata is already installed${NC}"
    netdata -v
else
    # Install using official one-liner (recommended method)
    echo -e "${YELLOW}Downloading and installing Netdata...${NC}"
    
    # Install dependencies
    apt install -y curl wget gnupg apt-transport-https -qq
    
    # Install Netdata using kickstart script
    wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
    bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel
    
    echo -e "${GREEN}✓ Netdata installed successfully${NC}"
fi
echo ""

#===============================================================================
# Step 3: Configure Netdata
#===============================================================================
echo -e "${CYAN}[3/5] Configuring Netdata...${NC}"

# Backup original config if exists
if [ -f "${NETDATA_CONFIG_DIR}/netdata.conf" ]; then
    cp ${NETDATA_CONFIG_DIR}/netdata.conf ${NETDATA_CONFIG_DIR}/netdata.conf.backup
fi

# Create custom configuration
cat > ${NETDATA_CONFIG_DIR}/netdata.conf << 'EOF'
# Netdata Configuration
# Documentation: https://learn.netdata.cloud/docs/configuring/configuration

[global]
    # Data collection interval (seconds)
    update every = 1
    
    # History retention (seconds) - 1 hour
    history = 3600
    
    # Memory mode
    memory mode = ram
    
    # Access from any IP (for dashboard access)
    bind to = 0.0.0.0

[web]
    # Web dashboard port
    default port = 19999
    
    # Allow connections from anywhere
    allow connections from = *
    
    # Allow dashboard access from anywhere
    allow dashboard from = *

[plugins]
    # Enable common plugins
    proc = yes
    diskspace = yes
    cgroups = yes
    tc = no
    
[plugin:proc]
    # Monitor /proc filesystem
    /proc/stat = yes
    /proc/meminfo = yes
    /proc/vmstat = yes
    /proc/net/dev = yes
    /proc/diskstats = yes
    /proc/loadavg = yes
EOF

echo -e "${GREEN}✓ Netdata configured${NC}"
echo ""

#===============================================================================
# Step 4: Setup Custom Alerts
#===============================================================================
echo -e "${CYAN}[4/5] Setting up custom alerts...${NC}"

# Create custom CPU alert (>80%)
cat > ${HEALTH_CONFIG_DIR}/cpu_custom.conf << 'EOF'
# Custom CPU Usage Alert
# Alert when CPU usage exceeds 80%

alarm: cpu_usage_high
on: system.cpu
lookup: average -1m percentage of user,system,softirq,irq,guest
units: %
every: 10s
warn: $this > 80
crit: $this > 95
info: CPU usage is high
to: sysadmin
EOF

# Create custom Memory alert (>85%)
cat > ${HEALTH_CONFIG_DIR}/memory_custom.conf << 'EOF'
# Custom Memory Usage Alert
# Alert when RAM usage exceeds 85%

alarm: ram_usage_high
on: system.ram
lookup: average -1m percentage of used
units: %
every: 10s
warn: $this > 85
crit: $this > 95
info: RAM usage is high
to: sysadmin
EOF

# Create custom Disk alert (>90%)
cat > ${HEALTH_CONFIG_DIR}/disk_custom.conf << 'EOF'
# Custom Disk Space Alert
# Alert when disk usage exceeds 90%

alarm: disk_space_low
on: disk_space._
lookup: average -1m percentage of used
units: %
every: 1m
warn: $this > 90
crit: $this > 95
info: Disk space is running low
to: sysadmin
EOF

echo -e "${GREEN}✓ Custom alerts configured${NC}"
echo ""

#===============================================================================
# Step 5: Start Netdata Service
#===============================================================================
echo -e "${CYAN}[5/5] Starting Netdata service...${NC}"

# Restart Netdata to apply changes
systemctl restart netdata

# Enable Netdata to start on boot
systemctl enable netdata

# Wait for service to start
sleep 3

# Check status
if systemctl is-active --quiet netdata; then
    echo -e "${GREEN}✓ Netdata is running${NC}"
else
    echo -e "${RED}✗ Netdata failed to start${NC}"
    systemctl status netdata
    exit 1
fi
echo ""

#===============================================================================
# Get Server IP and Display Info
#===============================================================================
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}           SETUP COMPLETE! 🎉                          ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Dashboard URL:${NC}  http://${SERVER_IP}:19999"
echo ""
echo -e "  ${BOLD}Alerts Configured:${NC}"
echo -e "    • CPU usage    > 80%  (warning), > 95% (critical)"
echo -e "    • Memory usage > 85%  (warning), > 95% (critical)"
echo -e "    • Disk usage   > 90%  (warning), > 95% (critical)"
echo ""
echo -e "  ${BOLD}Useful Commands:${NC}"
echo -e "    • Status:   sudo systemctl status netdata"
echo -e "    • Restart:  sudo systemctl restart netdata"
echo -e "    • Logs:     sudo journalctl -u netdata -f"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
