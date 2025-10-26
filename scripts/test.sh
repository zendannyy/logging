#!/bin/bash

# Logging PoC Testing Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "================================"
echo "Logging PoC - Testing Script"
echo "================================"
echo ""

# Test API connectivity
test_connectivity() {
    echo "[*] Testing Service Connectivity..."
    echo ""

    # Test Elasticsearch
    echo -n "  Elasticsearch (9200): "
    if curl -s -u admin:SecurePassword123 http://localhost:9200/_cluster/health 2>/dev/null | grep -q "status"; then
        echo "✓ Connected"
    else
        echo "✗ Failed"
    fi

    # Test Wazuh Manager API
    echo -n "  Wazuh Manager API (9200): "
    if curl -s -k https://localhost:9200 2>/dev/null | grep -q "security\|missing"; then
        echo "✓ Connected"
    else
        echo "✗ Failed"
    fi

    # Test Velociraptor
    echo -n "  Velociraptor (8000): "
    if curl -s -k https://localhost:8000 2>/dev/null > /dev/null; then
        echo "✓ Connected"
    else
        echo "✗ Failed"
    fi

    echo ""
}

# Test agent status
test_agents() {
    echo "[*] Testing Agent Status..."
    echo ""

    for agent in ubuntu-agent-1 ubuntu-agent-2; do
        echo "  $agent:"
        if docker compose exec -T $agent /var/ossec/bin/wazuh-control status 2>/dev/null | grep -q "running"; then
            echo "    ✓ Wazuh agent running"
        else
            echo "    ✗ Wazuh agent not responding"
        fi

        if docker compose exec -T $agent test -f /opt/velociraptor/velociraptor 2>/dev/null; then
            echo "    ✓ Velociraptor binary present"
        else
            echo "    ✗ Velociraptor binary missing"
        fi
    done

    echo ""
}

# Generate sample logs
generate_logs() {
    echo "[*] Generating Sample Logs..."
    echo ""

    for agent in ubuntu-agent-1 ubuntu-agent-2; do
        echo "  Generating logs on $agent..."
        docker compose exec -T $agent bash -c '
            for i in {1..10}; do
                echo "[$(date)] Test alert - Event $i from $AGENT_NAME" >> /var/log/test.log
                logger -t "test-app" "Test message $i from $AGENT_NAME"
            done
        ' 2>/dev/null && echo "    ✓ Logs generated"
    done

    echo ""
    echo "[*] Check Wazuh dashboard for alerts (may take a few moments)"
    echo ""
}

# Check storage
check_storage() {
    echo "[*] Storage Usage..."
    echo ""

    docker compose exec -T wazuh-indexer df -h /usr/share/elasticsearch/data 2>/dev/null || echo "  (Unable to check)"

    echo ""
}

# Run tests
case "${1}" in
    connectivity)
        test_connectivity
        ;;
    agents)
        test_agents
        ;;
    logs)
        generate_logs
        ;;
    storage)
        check_storage
        ;;
    all)
        test_connectivity
        test_agents
        generate_logs
        check_storage
        ;;
    *)
        echo "Usage: $0 {connectivity|agents|logs|storage|all}"
        echo ""
        echo "  connectivity - Test connection to services"
        echo "  agents       - Check agent status"
        echo "  logs         - Generate sample logs"
        echo "  storage      - Check storage usage"
        echo "  all          - Run all tests"
        echo ""
        exit 1
        ;;
esac

echo "[+] Test complete"
