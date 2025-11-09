#!/usr/bin/env bash 
# script for post-install on docker hosts 

# one-liner to determine os distro and id
OS_ID=$(. /etc/os-release && echo ${ID_LIKE:-$ID})

if [ $OS_ID = 'fedora' ]; then
    echo "$OS_ID"
    dnf update -y --skip-broken
    dnf install -y --skip-broken git curl wget; service wazuh-agent status
elif [ $OS_ID = 'debian' ]; then
    echo "$OS_ID"
    apt-get update -y 
    apt-get install -y --fix-broken git curl wget; systemctl status wazuh-agent
elif [ $OS_ID = 'alpine' ]; then
    echo "$OS_ID"
    apk add -y git curl wget; systemctl status wazuh-agent
elif [ "$OS_ID" = 'Darwin' ]; then
    echo $OS_ID
    brew update
    brew install git curl wget
else
    echo "ERROR: Unsupported distribution: $OS_ID"
fi 

# dnf install -y git curl wget; systemctl status wazuh-agent
