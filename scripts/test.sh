#!/usr/bin/env bash
# Logging PoC Testing Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "================================"
echo -e "Logging PoC - Testing Script\n"
echo -e "================================\n"
# Test API connectivity
test_connectivity() {
    echo -e "[*] Testing Service Connectivity...\n"

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
    echo -e "[*] Testing Agent Status...\n"

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
            echo -e "    ✗ Velociraptor binary missing\n"
        fi
    done
}

# Generate sample logs
generate_logs() {
    echo -e "[*] Generating Sample Logs...\n"

    for agent in ubuntu-agent-1 ubuntu-agent-2; do
        echo "  Generating logs on $agent..."
        docker compose exec -T $agent bash -c '
            for i in {1..10}; do
                echo -e "[$(date)] Test alert - Event $i from $AGENT_NAME" >> /var/log/test.log
                logger -t "test-app" "Test message $i from $AGENT_NAME"
            done
        ' 2>/dev/null && echo "    ✓ Logs generated\n"
    done

    echo -e "[*] Check Wazuh dashboard for alerts (may take a few moments)\n"
}

# Check storage
check_storage() {
    echo -e "[*] Storage Usage...\n"

    docker compose exec -T wazuh-indexer df -h /usr/share/elasticsearch/data 2>/dev/null || echo "  (Unable to check)\n"

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
        echo "Usage: $0 {connectivity|agents|logs|storage|all}\n"
        echo "  connectivity - Test connection to services"
        echo "  agents       - Check agent status"
        echo "  logs         - Generate sample logs"
        echo "  storage      - Check storage usage"
        echo -e "  all          - Run all tests\n"
        exit 1
        ;;
esac

echo "[+] Test complete"
