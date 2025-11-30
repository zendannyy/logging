#!usr/bin/env bash
################################################################################
# Wazuh Single-Node Docker Deployment
# Quick deployment for development and testing environments
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WAZUH_VERSION="4.7.0"
OPENSEARCH_VERSION="2.10.0"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╦ ╦┌─┐┌─┐┬ ┬┬ ┬  ╔═╗┬┌┐┌┌─┐┬  ┌─┐
║║║├─┤┌─┘│ ││ │  ╚═╗│││││ ┬│  ├┤ 
╚╩╝┴ ┴└─┘└─┘└─┘  ╚═╝┴┘└┘└─┘┴─┘└─┘
   Single-Node Deployment
EOF
    echo -e "${NC}"
}

check_dependencies() {
    log_info "Checking dependencies..."
    for dep in docker docker-compose; do
        if ! command -v $dep &> /dev/null; then
            log_error "Missing: $dep"
            log_info "Install: apt install docker.io docker-compose"
            exit 1
        fi
    done
    log_info "✓ Dependencies OK"
}

check_resources() {
    log_info "Checking system resources..."
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 8 ]; then
        log_warn "Low memory: ${total_mem}GB (recommended: 8GB+)"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    
    local avail_disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $avail_disk -lt 20 ]; then
        log_error "Low disk: ${avail_disk}GB (minimum: 20GB)"
        exit 1
    fi
    log_info "✓ Resources adequate"
}

generate_passwords() {
    log_info "Generating credentials..."
    export OPENSEARCH_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    export WAZUH_API_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    cat > .env <<EOF
# Wazuh Single-Node Environment
# Generated: $(date)
WAZUH_VERSION=$WAZUH_VERSION
OPENSEARCH_VERSION=$OPENSEARCH_VERSION
OPENSEARCH_ADMIN_PASSWORD=$OPENSEARCH_ADMIN_PASSWORD
WAZUH_API_PASSWORD=$WAZUH_API_PASSWORD
OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g
EOF
    log_info "✓ Credentials saved to .env"
}

create_compose_file() {
    log_info "Creating docker-compose.yml..."
    cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  opensearch:
    image: opensearchproject/opensearch:2.10.0
    container_name: opensearch
    hostname: opensearch
    environment:
      - cluster.name=wazuh-cluster
      - node.name=opensearch
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
      - DISABLE_INSTALL_DEMO_CONFIG=true
      - DISABLE_SECURITY_PLUGIN=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - opensearch-data:/usr/share/opensearch/data
    ports:
      - "9200:9200"
    networks:
      - wazuh-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200/_cluster/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  wazuh-manager:
    image: wazuh/wazuh-manager:4.7.0
    container_name: wazuh-manager
    hostname: wazuh-manager
    restart: always
    environment:
      - INDEXER_URL=http://opensearch:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=admin
      - FILEBEAT_SSL_VERIFICATION_MODE=none
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=${WAZUH_API_PASSWORD:-MyS3cr37P450r.*-}
    volumes:
      - wazuh-manager-data:/var/ossec/data
      - wazuh-manager-logs:/var/ossec/logs
      - wazuh-manager-etc:/var/ossec/etc
      - wazuh-manager-api:/var/ossec/api/configuration
      - wazuh-manager-queues:/var/ossec/queue
      - ./custom-rules:/var/ossec/etc/rules/custom:ro
    ports:        # https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html#exposed-ports
      - "1514:1514/tcp"
      - "1515:1515/tcp"
      - "514:514/udp"
      - "55000:55000/tcp"
    networks:
      - wazuh-net
    depends_on:
      opensearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "/var/ossec/bin/wazuh-control status"]
      interval: 30s
      timeout: 10s
      retries: 5

  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.7.0
    container_name: wazuh-dashboard
    hostname: wazuh-dashboard
    restart: always
    environment:
      - OPENSEARCH_HOSTS=http://opensearch:9200
      - WAZUH_API_URL=https://wazuh-manager
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=${WAZUH_API_PASSWORD:-MyS3cr37P450r.*-}
    ports:
      - "443:5601"
    networks:
      - wazuh-net
    depends_on:
      wazuh-manager:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5601/api/status"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  opensearch-data:
  wazuh-manager-data:
  wazuh-manager-logs:
  wazuh-manager-etc:
  wazuh-manager-api:
  wazuh-manager-queues:

networks:
  wazuh-net:
    driver: bridge
EOF
    log_info "✓ docker-compose.yml created"
}

deploy() {
    log_info "Deploying Wazuh..."
    mkdir -p custom-rules
    
    log_info "Setting vm.max_map_count..."
    sudo sysctl -w vm.max_map_count=262144
    
    log_info "Starting containers..."
    docker-compose up -d
    
    log_info "Waiting for services (60 seconds)..."
    sleep 60
    
    docker-compose ps
    print_access_info
}

print_access_info() {
    echo -e "${GREEN}========================================${NC}\n"
    echo -e "${GREEN}  Wazuh Single-Node Ready!${NC}"
    echo -e "${GREEN}========================================${NC}\n""
    echo -e "${BLUE}Dashboard:${NC} https://localhost:443"
    echo -e "${BLUE}Username:${NC} admin"
    echo -e "${BLUE}Password:${NC} admin\n"
    echo -e "${BLUE}API:${NC} https://localhost:55000"
    echo -e "${BLUE}Username:${NC} wazuh-wui"
    echo -e "${BLUE}Password:${NC} ${WAZUH_API_PASSWORD}"
    
    echo -e "${BLUE}Agent Registration:${NC} localhost:1514"
    echo -e "${BLUE}OpenSearch:${NC} http://localhost:9200"
    
    echo -e "${YELLOW}Commands:${NC}"
    echo "  Logs:    docker-compose logs -f"
    echo "  Status:  $0 status"
    echo "  Stop:    docker-compose down"
    echo -e "  Cleanup: $0 cleanup\n"
}

status() {
    log_info "Checking status..."
    [ ! -f docker-compose.yml ] && log_error "No deployment found" && exit 1
    
    echo -e "\n${BLUE}Containers:${NC}"
    docker-compose ps
    
    echo -e "\n${BLUE}Resources:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        $(docker-compose ps -q)
    
    echo -e "\n${BLUE}OpenSearch Health:${NC}"
    curl -s http://localhost:9200/_cluster/health?pretty 2>/dev/null || echo "Not accessible"
}

cleanup() {
    log_warn "Remove all containers and data?"
    read -p "Type 'yes' to confirm: " -r
    [ "$REPLY" != "yes" ] && log_info "Cancelled" && exit 0
    
    log_info "Stopping containers..."
    docker-compose down -v
    
    log_info "Removing volumes..."
    docker volume ls -q | grep -E 'wazuh|opensearch' | xargs -r docker volume rm
    
    log_info "Removing files..."
    rm -f docker-compose.yml .env
    rm -rf custom-rules
    
    log_info "✓ Cleanup complete"
}

register_agent() {
    log_info "Agent Registration"
    read -p "Agent name: " agent_name
    read -p "Agent IP: " agent_ip
    
    docker-compose exec -T wazuh-manager /var/ossec/bin/manage_agents << EOF
A         # Choose your action: A or E or L or R or Q:
$agent_name
$agent_ip

y
q
EOF
    
    log_info "✓ Agent registered"
    log_info "Extract key: docker-compose exec wazuh-manager /var/ossec/bin/manage_agents -l"
}

show_help() {
    cat << EOF
Wazuh Single-Node Docker Deployment

Usage: $0 [COMMAND]

Commands:
  deploy          Deploy Wazuh (default)
  status          Show status
  logs            Follow logs
  register-agent  Register new agent
  cleanup         Remove everything
  help            Show this help

Examples:
  $0              # Deploy
  $0 status       # Check status
  $0 cleanup      # Remove all
EOF
}

case "${1:-deploy}" in
    deploy)
        print_banner
        check_dependencies
        check_resources
        generate_passwords
        create_compose_file
        deploy
        ;;
    status)
        status
        ;;
    logs)
        docker-compose logs -f
        ;;
    register-agent)
        register_agent
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
