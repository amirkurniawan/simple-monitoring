#!/bin/bash

#===============================================================================
# Netdata Cleanup Script
# Description: Remove Netdata monitoring agent and all configurations
# Usage: sudo ./cleanup.sh
#
# Project: https://roadmap.sh/projects/simple-monitoring
#===============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}           NETDATA CLEANUP                             ${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (sudo ./cleanup.sh)${NC}"
    exit 1
fi

# Confirmation
echo -e "${YELLOW}WARNING: This will completely remove Netdata and all its data!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo ""

#===============================================================================
# Step 1: Stop Netdata Service
#===============================================================================
echo -e "${CYAN}[1/4] Stopping Netdata service...${NC}"

if systemctl is-active --quiet netdata; then
    systemctl stop netdata
    systemctl disable netdata
    echo -e "${GREEN}✓ Netdata service stopped${NC}"
else
    echo -e "${YELLOW}Netdata service not running${NC}"
fi
echo ""

#===============================================================================
# Step 2: Run Official Uninstaller (if exists)
#===============================================================================
echo -e "${CYAN}[2/4] Running Netdata uninstaller...${NC}"

UNINSTALLER="/usr/libexec/netdata/netdata-uninstaller.sh"
if [ -f "$UNINSTALLER" ]; then
    echo -e "  Using official uninstaller..."
    $UNINSTALLER --yes --force
    echo -e "${GREEN}✓ Netdata uninstalled${NC}"
else
    # Manual removal if uninstaller doesn't exist
    echo -e "  Official uninstaller not found, removing manually..."
    
    # Stop any running processes
    pkill -9 netdata 2>/dev/null
    
    # Remove packages
    apt remove --purge netdata netdata-plugin-* -y 2>/dev/null
    apt autoremove -y 2>/dev/null
    
    echo -e "${GREEN}✓ Netdata packages removed${NC}"
fi
echo ""

#===============================================================================
# Step 3: Remove Configuration Files
#===============================================================================
echo -e "${CYAN}[3/4] Removing configuration files...${NC}"

# List of directories to remove
DIRS_TO_REMOVE=(
    "/etc/netdata"
    "/var/lib/netdata"
    "/var/cache/netdata"
    "/var/log/netdata"
    "/usr/share/netdata"
    "/usr/libexec/netdata"
    "/opt/netdata"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo -e "  Removed: $dir"
    fi
done

echo -e "${GREEN}✓ Configuration files removed${NC}"
echo ""

#===============================================================================
# Step 4: Remove User and Group
#===============================================================================
echo -e "${CYAN}[4/4] Removing Netdata user and group...${NC}"

# Remove user
if id "netdata" &>/dev/null; then
    userdel netdata 2>/dev/null
    echo -e "  Removed user: netdata"
fi

# Remove group
if getent group netdata &>/dev/null; then
    groupdel netdata 2>/dev/null
    echo -e "  Removed group: netdata"
fi

echo -e "${GREEN}✓ User and group removed${NC}"
echo ""

#===============================================================================
# Summary
#===============================================================================
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}           CLEANUP COMPLETE! 🧹                        ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Netdata has been completely removed from this system."
echo ""
echo -e "${YELLOW}To reinstall, run:${NC}"
echo -e "  sudo ./setup.sh"
echo ""
