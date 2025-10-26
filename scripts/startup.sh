#!/bin/bash

# Logging PoC Startup Script

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "================================"
echo "Logging PoC - Startup Script"
echo "================================"
echo ""

# Load environment
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "[+] Environment loaded from .env"
else
    echo "[-] .env file not found!"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "[-] Docker is not installed"
    exit 1
fi

echo "[+] Docker found: $(docker --version)"
echo ""

# Check Docker Compose
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo "[-] Docker Compose is not installed"
    exit 1
fi

echo "[+] Docker Compose found: $(docker compose version)"
echo ""

# Build agent image
echo "[*] Building Ubuntu agent image..."
docker compose build --no-cache ubuntu-agent-1 ubuntu-agent-2

echo -e "[*] Pulling Velociraptor image...\n"
docker compose pull velociraptor-server

echo "[*] Starting services..\n."
docker compose up -d

echo ""
echo "[+] Services starting up..."
echo "[*] Waiting for services to be ready (this may take 2-3 minutes)..."

# Wait for services
for i in {1..30}; do
    if docker compose ps | grep -q "healthy\|running"; then
        echo "[+] Services are running"
        break
    fi
    echo -n "."
    sleep 5
done

echo ""
echo ""
echo "================================"
echo "Logging PoC is ready!"
echo "================================"
echo ""
echo "Service URLs:"
echo "  Wazuh Dashboard:   https://localhost:443"
echo "  Velociraptor GUI:  https://localhost:8000"
echo "  Elasticsearch API: http://localhost:9200"
echo ""
echo "Credentials:"
echo "  Wazuh:"
echo "    Username: admin"
echo "    Password: SecurePassword123"
echo ""
echo "  Velociraptor:"
echo "    Username: admin"
echo "    Password: admin"
echo ""
echo "To view logs:"
echo "  docker compose logs -f [service_name]"
echo ""
echo "To stop services:"
echo "  ./scripts/shutdown.sh"
echo ""
