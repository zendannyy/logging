#!/usr/bin/env bash
################################################################################
# Wazuh Multi-Node Docker Deployment (HA)
# Production-grade high availability deployment
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
╦ ╦┌─┐┌─┐┬ ┬┬ ┬  ╔╦╗┬ ┬┬  ┌┬┐┬
║║║├─┤┌─┘│ ││ │  ║║║│ ││   │ │
╚╩╝┴ ┴└─┘└─┘└─┘  ╩ ╩└─┘┴─┘ ┴ ┴
   Multi-Node HA Deployment
EOF
    echo -e "${NC}\n"
}

check_dependencies() {
    log_info "Checking dependencies..."
    for dep in docker docker-compose; do
        if ! command -v $dep &> /dev/null; then
            log_error "Missing: $dep"
            exit 1
        fi
    done
    log_info "✓ Dependencies OK"
}

check_resources() {
    log_info "Checking system resources..."
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 16 ]; then
        log_warn "Low memory: ${total_mem}GB (recommended: 16GB+)"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    
    local avail_disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $avail_disk -lt 40 ]; then
        log_error "Low disk: ${avail_disk}GB (minimum: 40GB)"
        exit 1
    fi
    log_info "✓ Resources adequate"
}

generate_passwords() {
    log_info "Generating credentials..."
    export OPENSEARCH_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    export WAZUH_API_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    export WAZUH_CLUSTER_KEY=$(openssl rand -hex 16)
    
    cat > .env <<EOF
# Wazuh Multi-Node HA Environment
# Generated: $(date)
WAZUH_VERSION=$WAZUH_VERSION
OPENSEARCH_VERSION=$OPENSEARCH_VERSION
OPENSEARCH_ADMIN_PASSWORD=$OPENSEARCH_ADMIN_PASSWORD
WAZUH_API_PASSWORD=$WAZUH_API_PASSWORD
WAZUH_CLUSTER_KEY=$WAZUH_CLUSTER_KEY
OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g
EOF
    log_info "✓ Credentials saved to .env"
}

create_compose_file() {
    log_info "Creating docker-compose.yml..."
    cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  opensearch1:
    image: opensearchproject/opensearch:2.10.0
    container_name: opensearch1
    hostname: opensearch1
    environment:
      - cluster.name=wazuh-cluster
      - node.name=opensearch1
      - discovery.seed_hosts=opensearch2,opensearch3
      - cluster.initial_master_nodes=opensearch1,opensearch2,opensearch3
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g"
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
      - opensearch-data1:/usr/share/opensearch/data
    ports:
      - "9200:9200"
    networks:
      - wazuh-net

  opensearch2:
    image: opensearchproject/opensearch:2.10.0
    container_name: opensearch2
    hostname: opensearch2
    environment:
      - cluster.name=wazuh-cluster
      - node.name=opensearch2
      - discovery.seed_hosts=opensearch1,opensearch3
      - cluster.initial_master_nodes=opensearch1,opensearch2,opensearch3
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g"
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
      - opensearch-data2:/usr/share/opensearch/data
    networks:
      - wazuh-net

  opensearch3:
    image: opensearchproject/opensearch:2.10.0
    container_name: opensearch3
    hostname: opensearch3
    environment:
      - cluster.name=wazuh-cluster
      - node.name=opensearch3
      - discovery.seed_hosts=opensearch1,opensearch2
      - cluster.initial_master_nodes=opensearch1,opensearch2,opensearch3
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g"
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
      - opensearch-data3:/usr/share/opensearch/data
    networks:
      - wazuh-net

  wazuh-manager1:
    image: wazuh/wazuh-manager:4.7.0
    container_name: wazuh-manager1
    hostname: wazuh-manager1
    restart: always
    environment:
      - INDEXER_URL=http://opensearch1:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=admin
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=${WAZUH_API_PASSWORD}
      - WAZUH_CLUSTER_ENABLED=yes
      - WAZUH_CLUSTER_NODE_NAME=wazuh-manager1
      - WAZUH_CLUSTER_NODE_TYPE=master
      - WAZUH_CLUSTER_KEY=${WAZUH_CLUSTER_KEY}
      - WAZUH_CLUSTER_NODES=wazuh-manager1 wazuh-manager2
    volumes:
      - wazuh-manager1-data:/var/ossec/data
      - wazuh-manager1-logs:/var/ossec/logs
      - wazuh-manager1-etc:/var/ossec/etc
    ports:
      - "1514:1514/tcp"
      - "1515:1515/tcp"
      - "55000:55000/tcp"
    networks:
      - wazuh-net
    depends_on:
      - opensearch1

  wazuh-manager2:
    image: wazuh/wazuh-manager:4.7.0
    container_name: wazuh-manager2
    hostname: wazuh-manager2
    restart: always
    environment:
      - INDEXER_URL=http://opensearch2:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=admin
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=${WAZUH_API_PASSWORD}
      - WAZUH_CLUSTER_ENABLED=yes
      - WAZUH_CLUSTER_NODE_NAME=wazuh-manager2
      - WAZUH_CLUSTER_NODE_TYPE=worker
      - WAZUH_CLUSTER_KEY=${WAZUH_CLUSTER_KEY}
      - WAZUH_CLUSTER_NODES=wazuh-manager1 wazuh-manager2
    volumes:
      - wazuh-manager2-data:/var/ossec/data
      - wazuh-manager2-logs:/var/ossec/logs
      - wazuh-manager2-etc:/var/ossec/etc
    ports:
      - "1516:1514/tcp"
      - "1517:1515/tcp"
    networks:
      - wazuh-net
    depends_on:
      - opensearch2
      - wazuh-manager1

  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.7.0
    container_name: wazuh-dashboard
    hostname: wazuh-dashboard
    restart: always
    environment:
      - OPENSEARCH_HOSTS=http://opensearch1:9200
      - WAZUH_API_URL=https://wazuh-manager1
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=${WAZUH_API_PASSWORD}
    ports:
      - "443:5601"
    networks:
      - wazuh-net
    depends_on:
      - wazuh-manager1

volumes:
  opensearch-data1:
  opensearch-data2:
  opensearch-data3:
  wazuh-manager1-data:
  wazuh-manager1-logs:
  wazuh-manager1-etc:
  wazuh-manager2-data:
  wazuh-manager2-logs:
  wazuh-manager2-etc:

networks:
  wazuh-net:
    driver: bridge
EOF
    log_info "✓ docker-compose.yml created"
}

deploy() {
    log_info "Deploying Wazuh HA cluster..."
    
    log_info "Setting kernel parameters..."
    sudo sysctl -w vm.max_map_count=262144
    if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf 2>/dev/null; then
        echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
    fi
    
    log_info "Starting containers..."
    docker-compose up -d
    
    log_info "Waiting for cluster formation (120 seconds)..."
    sleep 120
    
    log_info "Checking cluster health..."
    curl -s http://localhost:9200/_cluster/health?pretty
    
    docker-compose ps
    print_access_info
}

print_access_info() {
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Wazuh Multi-Node HA Ready!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "${BLUE}Dashboard:${NC} https://localhost:443"
    echo -e "${BLUE}Username:${NC} admin"
    echo -e "${BLUE}Password:${NC} admin\n"
    
    echo -e "${BLUE}Manager APIs:${NC}"
    echo "  Master:  https://localhost:55000"
    echo -e "  Worker:  Check container logs\n"
    
    echo -e "${BLUE}Agent Registration:${NC}"
    echo "  Manager 1: localhost:1514"
    echo "  Manager 2: localhost:1516"
    echo -e "${BLUE}OpenSearch Cluster:${NC} http://localhost:9200"
    
    echo -e "${YELLOW}Credentials in .env file${NC}\n"
    echo -e "${YELLOW}Commands:${NC}"
    echo "  Status:  $0 status"
    echo "  Cluster: $0 cluster-info"
    echo -e "  Cleanup: $0 cleanup\n"
    
}

status() {
    log_info "Checking status..."
    [ ! -f docker-compose.yml ] && log_error "No deployment" && exit 1
    
    echo -e "\n${BLUE}Containers:${NC}"
    docker-compose ps
    
    echo -e "\n${BLUE}Resources:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        $(docker-compose ps -q)
}

cluster_info() {
    log_info "Cluster information..."
    
    echo -e "\n${BLUE}OpenSearch Cluster:${NC}"
    curl -s http://localhost:9200/_cluster/health?pretty
    curl -s http://localhost:9200/_cat/nodes?v
    
    echo -e "\n${BLUE}Wazuh Cluster:${NC}"
    docker-compose exec wazuh-manager1 /var/ossec/bin/cluster_control -l
}

cleanup() {
    log_warn "Remove all containers and data?"
    read -p "Type 'yes' to confirm: " -r
    [ "$REPLY" != "yes" ] && log_info "Cancelled" && exit 0
    
    log_info "Stopping cluster..."
    docker-compose down -v
    
    log_info "Removing volumes..."
    docker volume ls -q | grep -E 'wazuh|opensearch' | xargs -r docker volume rm
    log_info "Removing files..."
    rm -f docker-compose.yml .env
    
    log_info "✓ Cleanup complete"
}

show_help() {
    cat << EOF
Wazuh Multi-Node HA Docker Deployment

Usage: $0 [COMMAND]

Commands:
  deploy          Deploy HA cluster (default)
  status          Show status
  cluster-info    Show cluster details
  logs            Follow logs
  cleanup         Remove everything
  help            Show this help

Architecture:
  - 3 OpenSearch nodes (clustered)
  - 2 Wazuh managers (master + worker)
  - 1 Wazuh dashboard
  - High availability & load balancing

Examples:
  $0                  # Deploy
  $0 status           # Check status
  $0 cluster-info     # Cluster details
  $0 cleanup          # Remove all

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
    cluster-info)
        cluster_info
        ;;
    logs)
        docker-compose logs -f
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