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
    
    echo -e "${YELLOW}📦 Updating Repository...${NC}"
    sudo apt update -y > /dev/null 2>&1
    progress_bar 1 "System Update"

    echo -e "${YELLOW}📦 Installing Node.js & NPM...${NC}"
    sudo apt install -y curl npm > /dev/null 2>&1
    progress_bar 1 "Node.js Setup"

    echo -e "${YELLOW}📦 Installing PM2 Manager...${NC}"
    sudo npm install -g pm2 > /dev/null 2>&1
    progress_bar 1 "PM2 Installation"

    echo -e "${YELLOW}📦 Fetching Bore Tunnel Binary...${NC}"
    curl -Ls https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz | tar -zxf -
    sudo mv bore /usr/local/bin/ > /dev/null 2>&1
    progress_bar 1 "Bore Tunnel Setup"

    echo -e "\n${GREEN}✨ All dependencies installed successfully!${NC}"
    read -p "Press Enter to return to menu..."
}

# 2. Run Tunnel
run_tunnel() {
    draw_header
    echo -e "${CYAN}🛠️ Setup New Tunnel${NC}"
    read -p "🎯 Enter the local port to tunnel: " PORT
    if [[ -z "$PORT" ]]; then echo "Invalid port"; sleep 1; return; fi
    
    pm2 start "bore local $PORT --to bore.pub" --name "tunnel-$PORT" --log-date-format "YYYY-MM-DD HH:mm Z"
    
    echo -e "\n${GREEN}🚀 Tunnel 'tunnel-$PORT' is now running in background!${NC}"
    echo -e "${YELLOW}⏳ Waiting 3s for server to assign your public IP...${NC}"
    sleep 3
    # Attempt to show the assigned port immediately
    PUB_ADDR=$(pm2 logs "tunnel-$PORT" --lines 5 --nostream | grep -o 'bore.pub:[0-9]*' | tail -n 1)
    if [ ! -z "$PUB_ADDR" ]; then
        echo -e "${CYAN}🔗 Your Public Address: ${NC}${PURPLE}http://$PUB_ADDR${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 3. Show Tunnels
show_tunnels() {
    draw_header
    echo -e "${CYAN}📊 Active Tunnels List${NC}"
    echo "----------------------------------------------------"
    
    # List all PM2 processes starting with tunnel-
    TUNNELS=$(pm2 list | grep "tunnel-" | awk '{print $4}')
    
    if [ -z "$TUNNELS" ]; then
        echo -e "${RED}No active tunnels found.${NC}"
    else
        for T in $TUNNELS; do
            # Extracting the public address from logs
            ADDR=$(pm2 logs "$T" --lines 10 --nostream | grep -o 'bore.pub:[0-9]*' | tail -n 1)
            STATUS=$(pm2 jlist | grep -o "\"name\":\"$T\".*\"status\":\"[a-z]*\"" | cut -d'"' -f8)
            echo -e "${YELLOW}Name:${NC} $T | ${YELLOW}Status:${NC} $STATUS"
            echo -e "${GREEN}Address:${NC} ${ADDR:-"Detecting..."}"
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
    echo -e "${GREEN}✅ Tunnel on port $PORT has been stopped and deleted.${NC}"
    read -p "Press Enter to continue..."
}

# Main Loop
while true; do
    draw_header
    echo -e "${CYAN}  [1]${NC} 📥 Install Setup ${GRAY}(First time only)${NC}"
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
