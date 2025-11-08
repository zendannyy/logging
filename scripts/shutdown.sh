#!/bin/bash

# Logging PoC Shutdown Script

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "================================"
echo "Logging PoC - Shutdown Script"
echo "================================"
echo ""

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    echo "[*] Force stopping and removing containers..."
    docker compose down -v --remove-orphans
    echo "[+] All containers and volumes removed"
else
    echo "[*] Stopping containers gracefully..."
    docker compose down
    echo "[+] Containers stopped"
fi

echo ""
echo "[+] Shutdown complete"
