FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update and install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    openssh-server \
    openssh-client \
    systemctl \
    vim \
    net-tools \
    htop \
    git \
    python3 \
    python3-pip \
    apt-transport-https \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Wazuh agent
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && \
    apt-get install -y wazuh-agent && \
    systemctl disable wazuh-agent && \
    rm -rf /var/lib/apt/lists/*

# Install Velociraptor client
RUN mkdir -p /opt/velociraptor && \
    cd /opt/velociraptor && \
    wget https://github.com/Velocidex/velociraptor/releases/download/v0.72.0/velociraptor-v0.72.0-linux-x86_64 \
    -O velociraptor && \
    chmod +x velociraptor

# Create startup script
RUN mkdir -p /root/.ssh && \
    echo '#!/bin/bash\n\
\n\
# Enable SSH\n\
service ssh start\n\
\n\
# Configure Wazuh agent\n\
if [ ! -z "$WAZUH_MANAGER" ]; then\n\
    sed -i "s/<address>MANAGER_IP<\/address>/<address>$WAZUH_MANAGER<\/address>/g" /var/ossec/etc/ossec.conf\n\
fi\n\
\n\
if [ ! -z "$AGENT_NAME" ]; then\n\
    sed -i "s/<agent_name>.*<\/agent_name>/<agent_name>$AGENT_NAME<\/agent_name>/g" /var/ossec/etc/ossec.conf\n\
fi\n\
\n\
# Start Wazuh agent\n\
/var/ossec/bin/wazuh-control start\n\
\n\
# Start Velociraptor client (if client.config exists)\n\
if [ -f /opt/velociraptor/client.config.yaml ]; then\n\
    /opt/velociraptor/velociraptor --config /opt/velociraptor/client.config.yaml client &\n\
fi\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Create test logging script
RUN echo '#!/bin/bash\n\
# Generate sample logs for testing\n\
while true; do\n\
    echo "[$(date)] Test log entry from $AGENT_NAME" >> /var/log/test.log\n\
    sleep 30\n\
done\n\
' > /usr/local/bin/generate-logs.sh && chmod +x /usr/local/bin/generate-logs.sh

# Configure Wazuh agent basic settings
RUN sed -i 's/<address>MANAGER_IP<\/address>/<address>wazuh-manager<\/address>/g' /var/ossec/etc/ossec.conf && \
    sed -i 's/<agent_name>.*<\/agent_name>/<agent_name>ubuntu-agent<\/agent_name>/g' /var/ossec/etc/ossec.conf

ENTRYPOINT ["/entrypoint.sh"]
