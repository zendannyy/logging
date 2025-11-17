#!/usr/bin/env bash
# install-wazuh-manager.sh      # run as root 

set -e

echo -e "=== Installing Wazuh Manager Packages===\n"

# 1. Update system
apt update && apt upgrade -y

# 2. Install dependencies
apt install -y curl apt-transport-https lsb-release gnupg

# 3. Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt update

# 4. Install Wazuh Manager
apt install -y wazuh-manager

# 5. Enable and start service
# service daemon-reload
service docker restart
service wazuh-manager enable
service wazuh-manager start

# 6. Verify installation
service wazuh-manager status

echo "✓ Wazuh Manager installed successfully"
