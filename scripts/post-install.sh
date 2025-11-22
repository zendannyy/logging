#!/usr/bin/env bash 
# script for post-install on docker linux hosts 

# one-liner to determine os distro and id
OS_ID=$(. /etc/os-release && echo ${ID_LIKE:-$ID})

if [ $OS_ID = 'fedora' ]; then
    echo $OS_ID                                                                                            
    dnf update -y --skip-broken
    dnf install -y --skip-broken git curl wget; service wazuh-agent                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   t status
elif [$OS_ID = 'ubuntu' ]; then
    echo $OS_ID
    apt-get update -y                               
    apt-get install -y --fix-broken git curl wget; systemctl status wazuh-agent
elif [$OS_ID = 'alpine' ]; then
    echo $OS_ID
    apk add -y git curl wget; systemctl status wazuh-agent
else
    echo "ERROR: Unsupported distribution: $OS_ID"
fi 
