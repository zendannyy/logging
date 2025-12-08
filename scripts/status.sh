#!/usr/bin/env bash
# Logging PoC Status Check Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "================================\n"
echo -e "Logging PoC - Status Check\n"
echo -e "================================\n"

echo -e "[*] Container Status:\n"
docker compose ps

echo -e "\n[*] Service Health Checks:\n"

# Check Wazuh Manager
echo -n "Wazuh Manager API:     "
if curl -s https://localhost:9200 -k 2>/dev/null | grep -q "security\|missing"; then
    echo "✓ Responding"
else
    echo "✗ Not responding"
fi

# Check Wazuh Dashboard
echo -n "Wazuh Dashboard:       "
if curl -s https://localhost:443 -k 2>/dev/null | grep -q "wazuh\|kibana" || curl -s -I https://localhost:443 -k 2>/dev/null | grep -q "HTTP"; then
    echo "✓ Responding"
else
    echo "✗ Not responding"
fi

# Check Velociraptor
echo -n "Velociraptor GUI:      "
if curl -s https://localhost:8000 -k 2>/dev/null > /dev/null; then
    echo "✓ Responding"
else
    echo -e "✗ Not responding\n"
fi

# Check Elasticsearch
echo -e "Elasticsearch API:     \n"
if curl -s http://localhost:9300 2>/dev/null > /dev/null; then
    echo "✓ Responding"
else
    echo -e "✗ Not responding\n"
fi

echo -e "[*] Container Logs (last 5 lines each):\n"

for service in wazuh-manager wazuh-indexer wazuh-dashboard velociraptor-server ubuntu-agent-1; do
    echo -e "--- $service ---\n"
    docker compose logs --tail=5 $service 2>/dev/null || echo "  (no logs)"
done

echo -e "[+] Status check complete\n"
