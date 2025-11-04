#!/usr/bin/env bash
# Logging PoC Startup Script

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "================================\n"
echo -e "Logging PoC - Startup Script\n"
echo -e "================================\n"

# Load environment
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo -e "[+] Environment loaded from .env\n"
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

echo -e "[+] Docker Compose found: $(docker compose version)\n"

# Build agent image
echo "[*] Building Ubuntu agent image..."
docker compose build --no-cache ubuntu-agent-1 ubuntu-agent-2

echo -e "[*] Pulling Velociraptor image...\n"
docker compose pull velociraptor-server

echo -e "[*] Starting services..\n."
docker compose up -d

echo -e "[+] Services starting up...\n"
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


echo -e "\n================================\n"
echo -e "Logging PoC is ready!\n"
echo -e "================================\n"
echo "Service URLs:"
echo "  Wazuh Dashboard:   https://localhost:443"
echo "  Velociraptor GUI:  https://localhost:8000"
echo -e "  Elasticsearch API: http://localhost:9200\n"
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
echo -e "  docker compose logs -f [service_name]\n"
echo "To stop services:"
echo -e "  ./scripts/shutdown.sh\n"
