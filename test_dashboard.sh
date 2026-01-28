#!/bin/bash

#===============================================================================
# Test Dashboard Script
# Description: Generate system load to test Netdata monitoring
# Usage: ./test_dashboard.sh [cpu|memory|disk|all]
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

# Configuration
CPU_DURATION=30          # seconds
MEMORY_SIZE=512          # MB to allocate
DISK_SIZE=500            # MB to write
DISK_TEST_FILE="/tmp/netdata_disk_test"

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}           NETDATA DASHBOARD TEST                      ${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

print_usage() {
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./test_dashboard.sh [option]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  cpu       Generate CPU load"
    echo "  memory    Generate memory load"
    echo "  disk      Generate disk I/O load"
    echo "  all       Run all tests sequentially"
    echo "  help      Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./test_dashboard.sh cpu"
    echo "  ./test_dashboard.sh all"
    echo ""
}

#===============================================================================
# CPU Load Test
#===============================================================================
test_cpu() {
    echo -e "${YELLOW}[CPU TEST] Generating CPU load for ${CPU_DURATION} seconds...${NC}"
    echo -e "${YELLOW}→ Watch the CPU chart in Netdata dashboard${NC}"
    echo ""
    
    # Get number of CPU cores
    NUM_CORES=$(nproc)
    echo -e "  Detected ${NUM_CORES} CPU cores"
    echo -e "  Starting ${NUM_CORES} stress workers..."
    echo ""
    
    # Generate CPU load using dd and yes (available on most systems)
    PIDS=()
    for i in $(seq 1 $NUM_CORES); do
        # CPU intensive operation - calculate md5sum of random data
        (timeout ${CPU_DURATION}s bash -c 'while true; do echo "load" | md5sum > /dev/null; done') &
        PIDS+=($!)
    done
    
    # Show countdown
    for i in $(seq ${CPU_DURATION} -1 1); do
        echo -ne "\r  Time remaining: ${i}s  "
        sleep 1
    done
    echo ""
    
    # Kill any remaining processes
    for pid in "${PIDS[@]}"; do
        kill $pid 2>/dev/null
    done
    wait 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ CPU test completed${NC}"
    echo ""
}

#===============================================================================
# Memory Load Test
#===============================================================================
test_memory() {
    echo -e "${YELLOW}[MEMORY TEST] Allocating ${MEMORY_SIZE}MB of RAM for 30 seconds...${NC}"
    echo -e "${YELLOW}→ Watch the RAM chart in Netdata dashboard${NC}"
    echo ""
    
    # Check available memory
    AVAILABLE_MB=$(free -m | awk '/^Mem:/{print $7}')
    echo -e "  Available memory: ${AVAILABLE_MB}MB"
    
    if [ $AVAILABLE_MB -lt $MEMORY_SIZE ]; then
        echo -e "${RED}  Warning: Not enough free memory. Reducing test size.${NC}"
        MEMORY_SIZE=$((AVAILABLE_MB / 2))
        echo -e "  Using ${MEMORY_SIZE}MB instead"
    fi
    
    echo -e "  Allocating memory..."
    echo ""
    
    # Allocate memory using a simple method
    # Create a variable that holds data in memory
    (
        # Use head to read random data into memory
        DATA=$(head -c ${MEMORY_SIZE}M /dev/zero | tr '\0' 'x')
        echo -e "  Memory allocated. Holding for 30 seconds..."
        sleep 30
    ) &
    MEM_PID=$!
    
    # Show countdown
    for i in $(seq 30 -1 1); do
        echo -ne "\r  Time remaining: ${i}s  "
        sleep 1
    done
    echo ""
    
    # Cleanup
    kill $MEM_PID 2>/dev/null
    wait $MEM_PID 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ Memory test completed${NC}"
    echo ""
}

#===============================================================================
# Disk I/O Load Test
#===============================================================================
test_disk() {
    echo -e "${YELLOW}[DISK TEST] Writing ${DISK_SIZE}MB to disk...${NC}"
    echo -e "${YELLOW}→ Watch the Disk I/O charts in Netdata dashboard${NC}"
    echo ""
    
    # Check available disk space
    AVAILABLE_GB=$(df -BG /tmp | awk 'NR==2{print $4}' | tr -d 'G')
    echo -e "  Available disk space: ${AVAILABLE_GB}GB"
    
    if [ $AVAILABLE_GB -lt 1 ]; then
        echo -e "${RED}  Warning: Low disk space. Reducing test size.${NC}"
        DISK_SIZE=100
    fi
    
    echo -e "  Writing ${DISK_SIZE}MB test file..."
    echo ""
    
    # Write test - using dd
    dd if=/dev/zero of=${DISK_TEST_FILE} bs=1M count=${DISK_SIZE} status=progress 2>&1
    
    echo ""
    echo -e "  Reading test file back..."
    echo ""
    
    # Read test
    dd if=${DISK_TEST_FILE} of=/dev/null bs=1M status=progress 2>&1
    
    # Cleanup
    rm -f ${DISK_TEST_FILE}
    
    echo ""
    echo -e "${GREEN}✓ Disk I/O test completed${NC}"
    echo ""
}

#===============================================================================
# Network Load Test (Bonus)
#===============================================================================
test_network() {
    echo -e "${YELLOW}[NETWORK TEST] Generating network traffic...${NC}"
    echo -e "${YELLOW}→ Watch the Network charts in Netdata dashboard${NC}"
    echo ""
    
    # Simple network test using curl
    if command -v curl &> /dev/null; then
        echo -e "  Downloading test file..."
        for i in {1..5}; do
            curl -s -o /dev/null http://speedtest.tele2.net/1MB.zip
            echo -e "  Download $i/5 complete"
        done
    else
        echo -e "${YELLOW}  curl not found, skipping network test${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Network test completed${NC}"
    echo ""
}

#===============================================================================
# Run All Tests
#===============================================================================
test_all() {
    echo -e "${CYAN}Running all tests sequentially...${NC}"
    echo -e "${CYAN}Open Netdata dashboard to watch metrics in real-time!${NC}"
    echo ""
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BOLD}Dashboard URL: http://${SERVER_IP}:19999${NC}"
    echo ""
    
    read -p "Press Enter to start tests..."
    echo ""
    
    test_cpu
    sleep 5
    
    test_memory
    sleep 5
    
    test_disk
    
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}           ALL TESTS COMPLETED! 🎉                     ${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Check your Netdata dashboard to see the recorded metrics."
    echo -e "URL: http://${SERVER_IP}:19999"
    echo ""
}

#===============================================================================
# Main
#===============================================================================
print_header

case "${1:-help}" in
    cpu)
        test_cpu
        ;;
    memory)
        test_memory
        ;;
    disk)
        test_disk
        ;;
    network)
        test_network
        ;;
    all)
        test_all
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        print_usage
        exit 1
        ;;
esac
