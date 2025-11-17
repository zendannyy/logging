#!/usr/bin/env bash
# wazuh-docker-cleanup.sh
# script to be ran as root, for when needing to clean up a broken wazuh installation and start from scratch

# Check for init, SysVinit
# Minimal init wrapper (inline)
detect_init() { [ -d /run/systemd/system ] && echo "systemd" || echo "sysvinit"; }
svc() {
    local cmd=$1 svc=$2 init=$(detect_init)
    case "$init:$cmd" in
        systemd:start|systemd:stop|systemd:enable|systemd:restart)
            systemctl "$cmd" "$svc" 2>/dev/null || true ;;
        systemd:status)
            systemctl status "$svc" --no-pager | head -10 ;;
        systemd:reload)
            systemctl daemon-reload ;;
        *:start|*:stop|*:restart|*:status)
            service "$svc" "$cmd" 2>/dev/null || true ;;
        *:enable)
            update-rc.d "$svc" defaults 2>/dev/null ||  chkconfig "$svc" on 2>/dev/null || true ;;
        *:logs)
            tail -10 /var/log/"$svc".log 2>/dev/null ||  grep "$svc" /var/log/syslog | tail -10 ;;
        *:reload)
            : ;;
    esac
}

INIT=$(detect_init)
echo -e "=== Wazuh Docker Installation [Init: $INIT] ===\n"

# 2. Install docker-compose if needed
if ! command -v docker-compose &>/dev/null; then
     curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
     chmod +x /usr/local/bin/docker-compose
fi

# 3. Clone stable version
rm -rf wazuh-docker
git clone --branch v4.13.1 --depth 1 https://github.com/wazuh/wazuh-docker.git

# 4. Start
cd wazuh-docker/single-node
docker-compose up -d

# 5. Monitor startup
echo "Waiting for services to start (90 seconds)..."
for i in {1..18}; do
    echo -n "."
    sleep 5
done

# 6. Check status
docker-compose ps

# 7. Test
echo -e "Testing indexer...\n"
docker exec single-node-wazuh.indexer-1 curl -k -u admin:admin https://localhost:9200 2>/dev/null | head -5

echo -e "Testing dashboard...\n"
curl -k https://localhost 2>&1 | head -5

echo -e "=== Docker Installation Complete ===\n"
echo -e "Access: https://$(hostname -I | awk '{print $1}')\n"
echo "Default: admin / admin or admin / SecretPassword"
echo -e "Logs: docker-compose logs -f\n"
echo -e "Stop: docker-compose down\n"