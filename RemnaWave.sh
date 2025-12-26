#!/bin/bash

# ======================================================
# Project: RemnaWaveManager
# Developed by: Erfan-XRay
# ======================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Helpers
info() { echo -e "${CYAN}${BOLD}[INFO]${NC} ${CYAN}$1${NC}"; }
warn() { echo -e "${YELLOW}${BOLD}[WARN]${NC} ${YELLOW}$1${NC}"; }
error() { echo -e "${RED}${BOLD}[ERROR]${NC} ${RED}$1${NC}"; exit 1; }

# Root check
if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root (sudo)."
fi

# Install dependencies (figlet)
if ! command -v figlet &> /dev/null; then
    apt-get update && apt-get install -y figlet &> /dev/null
fi

# Function to check installation status
get_status() {
    local status_panel="${RED}Not Installed${NC}"
    local status_node="${RED}Not Installed${NC}"
    local script_version="1.2.0"
    local panel_domain=""
    local node_port=""
    local server_ip=$(curl -s https://ipv4.icanhazip.com || echo "Unknown")

    # Check Panel
    if [ -d "/opt/remnawave" ]; then
        # Try to extract domain from .env
        if [ -f "/opt/remnawave/.env" ]; then
            panel_domain=$(grep "FRONT_END_DOMAIN=" /opt/remnawave/.env | cut -d'=' -f2)
        fi

        if docker ps --format '{{.Names}}' | grep -q "remnawave"; then
            status_panel="${GREEN}Installed & Running${NC}"
            [ ! -z "$panel_domain" ] && status_panel="${status_panel} ${CYAN}(https://${panel_domain})${NC}"
        else
            status_panel="${YELLOW}Installed (Stopped)${NC}"
            [ ! -z "$panel_domain" ] && status_panel="${status_panel} ${CYAN}(Domain: ${panel_domain})${NC}"
        fi
    fi

    # Check Node
    if [ -d "/opt/remnanode" ]; then
        if [ -f "/opt/remnanode/docker-compose.yml" ]; then
            node_port=$(grep "NODE_PORT=" /opt/remnanode/docker-compose.yml | cut -d'=' -f2)
        fi

        if docker ps --format '{{.Names}}' | grep -q "remnanode"; then
            status_node="${GREEN}Installed & Running${NC}"
            [ ! -z "$node_port" ] && status_node="${status_node} ${CYAN}(Port: ${node_port})${NC}"
        else
            status_node="${YELLOW}Installed (Stopped)${NC}"
            [ ! -z "$node_port" ] && status_node="${status_node} ${CYAN}(Port: ${node_port})${NC}"
        fi
    fi

    echo -e "${BOLD}Server IP:${NC} ${YELLOW}${server_ip}${NC}"
    echo -e "${BOLD}Panel Status:${NC} $status_panel"
    echo -e "${BOLD}Node Status: ${NC} $status_node"
    echo -e "${BOLD}Script Version:${NC} ${GREEN}${script_version}${NC}"
}

# Banner Function
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    figlet -f slant "RemnaWave"
    echo -e "                            Manager by ErfanXRay${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    get_status
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo -e "${BOLD}Github:   ${BLUE}github.com/Erfan-XRay/${NC}"
    echo -e "${BOLD}Telegram: ${BLUE}@Erfan_XRay${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo ""
}

# Optimization Function
optimize_system() {
    info "Optimizing system parameters..."
    sysctl -w vm.overcommit_memory=1
    grep -q "vm.overcommit_memory = 1" /etc/sysctl.conf || echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
    sysctl -w net.core.somaxconn=1024
}

# Docker Install Function
install_docker() {
    if ! command -v docker &> /dev/null; then
        info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
    fi
}

# --- SERVICE MANAGEMENT FUNCTION ---

manage_services() {
    while true; do
        show_banner
        echo -e "${PURPLE}${BOLD}>>> Service Management Menu${NC}"
        echo "1) Restart All (Panel & Sub Page)"
        echo "2) Stop All (Panel & Sub Page)"
        echo "3) Start All (Panel & Sub Page)"
        echo -e "${CYAN}------------------------------------------${NC}"
        echo "4) Restart Node"
        echo "5) Stop Node"
        echo "6) Start Node"
        echo -e "${CYAN}------------------------------------------${NC}"
        echo "7) Back to Main Menu"
        echo ""
        read -p "Select an option [1-7]: " SVC_OPT

        case $SVC_OPT in
            1)
                if [ -d "/opt/remnawave" ]; then
                    info "Restarting Panel and Sub Page..."
                    cd /opt/remnawave && docker compose restart
                else
                    warn "Panel directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            2)
                if [ -d "/opt/remnawave" ]; then
                    info "Stopping Panel and Sub Page..."
                    cd /opt/remnawave && docker compose stop
                else
                    warn "Panel directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            3)
                if [ -d "/opt/remnawave" ]; then
                    info "Starting Panel and Sub Page..."
                    cd /opt/remnawave && docker compose start
                else
                    warn "Panel directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            4)
                if [ -d "/opt/remnanode" ]; then
                    info "Restarting Node..."
                    cd /opt/remnanode && docker compose restart
                else
                    warn "Node directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            5)
                if [ -d "/opt/remnanode" ]; then
                    info "Stopping Node..."
                    cd /opt/remnanode && docker compose stop
                else
                    warn "Node directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            6)
                if [ -d "/opt/remnanode" ]; then
                    info "Starting Node..."
                    cd /opt/remnanode && docker compose start
                else
                    warn "Node directory not found."
                fi
                read -p "Press Enter to continue..." ;;
            7) break ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}

# --- UNINSTALL FUNCTIONS ---

uninstall_panel() {
    echo -e "${RED}${BOLD}WARNING: All Panel data and database will be permanently deleted!${NC}"
    read -p "Are you sure you want to proceed? (y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Uninstalling RemnaWave Panel..."
        if [ -d "/opt/remnawave" ]; then
            cd /opt/remnawave && docker compose down -v 2>/dev/null
            cd / && rm -rf /opt/remnawave
        fi
        rm -f /etc/nginx/sites-enabled/remnawave
        rm -f /etc/nginx/sites-available/remnawave
        systemctl restart nginx 2>/dev/null
        info "Panel uninstalled successfully."
    else
        info "Uninstall cancelled."
    fi
}

uninstall_node() {
    echo -e "${RED}${BOLD}WARNING: RemnaNode container and configuration will be deleted!${NC}"
    read -p "Are you sure you want to proceed? (y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Uninstalling RemnaWave Node..."
        if [ -d "/opt/remnanode" ]; then
            cd /opt/remnanode && docker compose down -v 2>/dev/null
            cd / && rm -rf /opt/remnanode
        fi
        info "Node uninstalled successfully."
    else
        info "Uninstall cancelled."
    fi
}

# --- INSTALLER FUNCTIONS ---

install_node() {
    install_docker
    mkdir -p /opt/remnanode && cd /opt/remnanode || exit

    echo -e "${YELLOW}Enter the Node Secret Key from your Panel:${NC}"
    read -p "Secret Key: " SECRET_KEY
    
    if [[ -z "$SECRET_KEY" ]]; then
        error "Secret Key is required."
    fi

    echo -e "${YELLOW}Enter the Node Port (Default: 2222):${NC}"
    read -p "Port: " NODE_PORT
    NODE_PORT=${NODE_PORT:-2222}

    info "Creating docker-compose.yml for Node on port ${NODE_PORT}..."
    cat <<EOF > docker-compose.yml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY=${SECRET_KEY}
EOF

    info "Starting Node container..."
    docker compose down 2>/dev/null
    docker compose up -d
    
    info "RemnaWave Node started successfully on port ${NODE_PORT}!"
    read -p "Press Enter to continue..."
}

full_install() {
    if [ -d "/opt/remnawave" ]; then
        echo -e "${RED}${BOLD}WARNING: RemnaWave Panel is already installed!${NC}"
        read -p "Do you want to perform a clean re-install? (y/n): " CLEAN_CONFIRM
        if [[ "$CLEAN_CONFIRM" =~ ^[Yy]$ ]]; then
            uninstall_panel
        else
            return
        fi
    fi

    optimize_system
    install_docker

    echo -e "${YELLOW}Enter PANEL Domain (e.g. panel.example.com):${NC}"
    read -r RAW_DOMAIN
    [ -z "$RAW_DOMAIN" ] && error "Domain cannot be empty."

    echo -e "${YELLOW}Enter SUBSCRIPTION Domain (e.g. sub.example.com):${NC}"
    read -r RAW_SUB_DOMAIN
    [ -z "$RAW_SUB_DOMAIN" ] && error "Subscription domain cannot be empty."

    DOMAIN=$(echo "$RAW_DOMAIN" | sed -e 's|^https\?://||' -e 's|/$||')
    SUB_DOMAIN=$(echo "$RAW_SUB_DOMAIN" | sed -e 's|^https\?://||' -e 's|/$||')

    echo -e "${YELLOW}Enter an Email for SSL renewal alerts (Leave empty to skip):${NC}"
    read -r SSL_EMAIL
    if [ -z "$SSL_EMAIL" ]; then
        EMAIL_FLAG="--register-unsafely-without-email"
    else
        EMAIL_FLAG="-m $SSL_EMAIL"
    fi

    INSTALL_DIR="/opt/remnawave"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit

    info "1/4: Fetching Panel files..."
    curl -L https://raw.githubusercontent.com/remnawave/backend/main/docker-compose-prod.yml -o docker-compose.yml
    curl -L https://raw.githubusercontent.com/remnawave/backend/main/.env.sample -o .env

    docker network create remnawave-network 2>/dev/null || true

    JWT_SECRET=$(openssl rand -hex 32)
    API_SECRET=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -hex 16)
    METRICS_PW=$(openssl rand -hex 12)
    WEBHOOK_PW=$(openssl rand -hex 12)

    sed -i "s|JWT_AUTH_SECRET=.*|JWT_AUTH_SECRET=$JWT_SECRET|" .env
    sed -i "s|JWT_API_TOKENS_SECRET=.*|JWT_API_TOKENS_SECRET=$API_SECRET|" .env
    sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASSWORD|" .env
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://postgres:$DB_PASSWORD@remnawave-db:5432/remnawave?schema=public|" .env
    sed -i "s|FRONT_END_DOMAIN=.*|FRONT_END_DOMAIN=$DOMAIN|" .env
    sed -i "s|SUB_PUBLIC_DOMAIN=.*|SUB_PUBLIC_DOMAIN=$SUB_DOMAIN|" .env
    sed -i "s|METRICS_PASS=.*|METRICS_PASS=$METRICS_PW|" .env
    sed -i "s|WEBHOOK_SECRET_HEADER=.*|WEBHOOK_SECRET_HEADER=$WEBHOOK_PW|" .env

    sed -i "/POSTGRES_PASSWORD: .*/a \      POSTGRES_DB: remnawave" docker-compose.yml

    info "2/4: Setting up Subscription Page..."

    echo -e "${YELLOW}Create API Token in Panel → Settings → API Tokens${NC}"
    read -p "Paste API Token: " API_TOKEN
    [ -z "$API_TOKEN" ] && error "API Token is required"

    cat <<EOF > sub-compose.yml
services:
  remnawave-sub-page:
    image: remnawave/subscription-page:latest
    container_name: remnawave-sub-page
    restart: always
    environment:
      - APP_PORT=3010
      - REMNAWAVE_PANEL_URL=http://remnawave:3000
      - REMNAWAVE_API_TOKEN=$API_TOKEN
    ports:
      - "127.0.0.1:3010:3010"
    networks:
      - remnawave-network

networks:
  remnawave-network:
    external: true
EOF

    info "3/4: Starting Containers..."
    docker compose -f docker-compose.yml -f sub-compose.yml up -d

    info "Waiting for database stability..."
    sleep 15

    docker exec remnawave-db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'remnawave'" | grep -q 1 || \
    docker exec remnawave-db psql -U postgres -c "CREATE DATABASE remnawave;"

    docker compose restart remnawave

    info "4/4: Configuring Nginx and SSL..."
    apt-get update && apt-get install -y nginx certbot python3-certbot-nginx

    rm -f /etc/nginx/sites-enabled/default
    systemctl stop nginx

    certbot certonly --standalone \
        -d "$DOMAIN" \
        -d "$SUB_DOMAIN" \
        --non-interactive --agree-tos $EMAIL_FLAG

    systemctl start nginx

    cat <<EOF > "/etc/nginx/sites-available/remnawave"
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
    }
}
EOF

    cat <<EOF > "/etc/nginx/sites-available/remnawave-sub"
server {
    listen 80;
    server_name $SUB_DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name $SUB_DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3010;
        proxy_set_header Host \$host;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/remnawave /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/remnawave-sub /etc/nginx/sites-enabled/

    nginx -t && systemctl restart nginx

    info "Installation completed!"
    info "Panel URL: https://$DOMAIN"
    info "Subscription URL: https://$SUB_DOMAIN"
}


# --- MAIN MENU ---
while true; do
    show_banner
    echo -e "${PURPLE}${BOLD}>>> Main Menu${NC}"
    echo "1) Full Install (Panel + SSL + Sub Page)"
    echo "2) Install RemnaWave Node"
    echo -e "${CYAN}------------------------------------------${NC}"
    echo "3) Manage Services (Start/Stop/Restart)"
    echo "4) View Panel Logs"
    echo "5) View Node Logs"
    echo "6) View Status"
    echo -e "${CYAN}------------------------------------------${NC}"
    echo "7) Uninstall PANEL"
    echo "8) Uninstall NODE"
    echo "9) Exit"
    echo ""
    read -p "Select an option [1-9]: " OPT

    case $OPT in
        1) full_install; read -p "Press Enter to continue..." ;;
        2) install_node ;;
        3) manage_services ;;
        4) 
            if [ -d "/opt/remnawave" ]; then
                cd /opt/remnawave && docker compose logs -f --tail=100
            else
                warn "Panel directory not found."
            fi
            read -p "Press Enter to continue..." ;;
        5) 
            if [ -d "/opt/remnanode" ]; then
                cd /opt/remnanode && docker compose logs -f --tail=100
            else
                warn "Node directory not found."
            fi
            read -p "Press Enter to continue..." ;;
        6) docker ps; read -p "Press Enter to continue..." ;;
        7) uninstall_panel; read -p "Press Enter to continue..." ;;
        8) uninstall_node; read -p "Press Enter to continue..." ;;
        9) exit 0 ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done