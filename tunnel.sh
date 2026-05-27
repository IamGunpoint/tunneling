#!/bin/bash

# Colors and Styling
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Clear screen and draw header
draw_header() {
    clear
    echo -e "${PURPLE}"
    echo "   ██╗███╗   ███╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗  ██████╗ ██╗███╗   ██╗████████╗"
    echo "   ██║████╗ ████║██╔════╝ ██║   ██║████╗  ██║██╔══██╗██╔═══██╗██║████╗  ██║╚══██╔══╝"
    echo "   ██║██╔████╔██║██║  ███╗██║   ██║██╔██╗ ██║██████╔╝██║   ██║██║██╔██╗ ██║   ██║   "
    echo "   ██║██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║██╔═══╝ ██║   ██║██║██║╚██╗██║   ██║   "
    echo "   ██║██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║██║     ╚██████╔╝██║██║ ╚████║   ██║   "
    echo "   ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚═╝╚═╝  ╚═══╝   ╚═╝   "
    echo -e "${YELLOW}                 Creator: ImGunpoint | @ImGunpoint${NC}"
    echo -e "${CYAN}================================================================================${NC}"
}

# Progress Bar Function
progress_bar() {
    local duration=$1
    local task=$2
    local steps=20
    echo -ne "${YELLOW}[*] $task: [                    ] 0% \r"
    for ((i=1; i<=steps; i++)); do
        sleep 0.1
        percent=$((i * 5))
        bar=$(printf "%${i}s" | tr ' ' '#')
        space=$(printf "%$((steps-i))s")
        echo -ne "${YELLOW}[*] $task: [${GREEN}${bar}${NC}${space}] ${percent}% \r"
    done
    echo -e "\n${GREEN}    Done! ✅${NC}"
}

# 1. Install Dependencies
install_deps() {
    draw_header
    echo -e "${CYAN}🚀 Starting Installation...${NC}\n"
    sudo apt update -y > /dev/null 2>&1
    progress_bar 1 "System Update"
    sudo apt install -y curl npm > /dev/null 2>&1
    progress_bar 1 "Node.js Setup"
    sudo npm install -g pm2 > /dev/null 2>&1
    progress_bar 1 "PM2 Installation"
    curl -Ls https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz | tar -zxf -
    sudo mv bore /usr/local/bin/ > /dev/null 2>&1
    progress_bar 1 "Bore Tunnel Setup"
    echo -e "\n${GREEN}✨ All dependencies installed successfully!${NC}"
    read -p "Press Enter to return to menu..."
}

# Helper function to get address from logs
fetch_address() {
    local NAME=$1
    # Search logs for bore.pub, replace with IP, and ensure we only get the last unique line
    pm2 logs "$NAME" --lines 100 --nostream | grep -oEi 'bore\.pub:[0-9]+' | tail -n 1 | sed 's/bore.pub/161.35.110.36/I'
}

# 2. Run Tunnel
run_tunnel() {
    draw_header
    echo -e "${CYAN}🛠️ Setup New Tunnel${NC}"
    read -p "🎯 Enter the local port to tunnel: " PORT
    if [[ -z "$PORT" ]]; then echo "Invalid port"; sleep 1; return; fi
    
    # Check if process exists to avoid duplicates in pm2
    pm2 delete "tunnel-$PORT" > /dev/null 2>&1
    pm2 start "bore local $PORT --to bore.pub" --name "tunnel-$PORT"
    
    echo -e "\n${GREEN}🚀 Tunnel 'tunnel-$PORT' is now running!${NC}"
    echo -e "${YELLOW}⏳ Fetching public address...${NC}"
    
    for i in {1..5}; do
        sleep 2
        PUB_ADDR=$(fetch_address "tunnel-$PORT")
        if [ ! -z "$PUB_ADDR" ]; then break; fi
    done

    if [ ! -z "$PUB_ADDR" ]; then
        echo -e "${CYAN}🔗 Your Public Address: ${NC}${PURPLE}http://$PUB_ADDR${NC}"
    else
        echo -e "${RED}⚠️ Startup deep-scan: Address not found yet. Check Menu [3] in a moment.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 3. Show Tunnels
show_tunnels() {
    draw_header
    echo -e "${CYAN}📊 Active Tunnels List${NC}"
    echo "----------------------------------------------------"
    
    # Get unique tunnel names only
    TUNNELS=$(pm2 list | grep "tunnel-" | awk '{print $4}' | sort | uniq)
    
    if [ -z "$TUNNELS" ]; then
        echo -e "${RED}No active tunnels found.${NC}"
    else
        for T in $TUNNELS; do
            ADDR=$(fetch_address "$T")
            STATUS=$(pm2 jlist | grep -oP "(?<=\"name\":\"$T\").*?\"status\":\"\K[^\"]+" | head -n 1)
            echo -e "${YELLOW}Name:${NC} $T | ${YELLOW}Status:${NC} ${GREEN}${STATUS}${NC}"
            echo -e "${GREEN}Address:${NC} ${ADDR:-"${RED}Detecting/Offline${NC}"}"
            echo "----------------------------------------------------"
        done
    fi
    read -p "Press Enter to continue..."
}

# 4. Delete Tunnel
delete_tunnel() {
    draw_header
    echo -e "${RED}🗑️ Delete a Tunnel${NC}"
    read -p "❌ Enter the port of the tunnel to kill: " PORT
    pm2 delete "tunnel-$PORT"
    echo -e "${GREEN}✅ Tunnel on port $PORT removed.${NC}"
    read -p "Press Enter to continue..."
}

# Main Loop
while true; do
    draw_header
    echo -e "${CYAN}  [1]${NC} 📥 Install Setup"
    echo -e "${CYAN}  [2]${NC} 🌐 Create New Tunnel"
    echo -e "${CYAN}  [3]${NC} 📋 View Active Tunnels & IPs"
    echo -e "${CYAN}  [4]${NC} 🗑️  Delete Tunnel"
    echo -e "${RED}  [5] 🚪 Exit${NC}"
    echo ""
    read -p "Select options [1-5]: " choice

    case $choice in
        1) install_deps ;;
        2) run_tunnel ;;
        3) show_tunnels ;;
        4) delete_tunnel ;;
        5) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid selection!${NC}"; sleep 1 ;;
    esac
done
