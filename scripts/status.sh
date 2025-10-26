#!/bin/bash

# Logging PoC Status Check Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "================================"
echo "Logging PoC - Status Check"
echo "================================"
echo ""

echo "[*] Container Status:"
docker compose ps

echo ""
echo "[*] Service Health Checks:"
echo ""

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
    echo "✗ Not responding"
fi

# Check Elasticsearch
echo -n "Elasticsearch API:     "
if curl -s http://localhost:9300 2>/dev/null > /dev/null; then
    echo "✓ Responding"
else
    echo "✗ Not responding"
fi

echo ""
echo "[*] Container Logs (last 5 lines each):"
echo ""

for service in wazuh-manager wazuh-indexer wazuh-dashboard velociraptor-server ubuntu-agent-1; do
    echo "--- $service ---"
    docker compose logs --tail=5 $service 2>/dev/null || echo "  (no logs)"
done

echo ""
echo "[+] Status check complete"
