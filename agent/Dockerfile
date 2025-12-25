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

# Install Docker CLI (to use host's Docker socket)
# We only need the CLI, not the daemon, since we'll mount the host's Docker socket
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    # Create docker group and add root to it (for socket access)
    groupadd -f docker && \
    usermod -aG docker root || true && \
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
# Check Docker socket access\n\
if [ -S /var/run/docker.sock ]; then\n\
    echo "Docker socket found at /var/run/docker.sock"\n\
    ls -la /var/run/docker.sock\n\
    # Test Docker connectivity\n\
    if docker ps > /dev/null 2>&1; then\n\
        echo "SUCCESS: Docker is accessible!"\n\
        docker version --format "Docker version: {{.Server.Version}}"\n\
    else\n\
        echo "WARNING: Docker socket exists but docker command failed"\n\
        echo "Attempting to fix permissions..."\n\
        chmod 666 /var/run/docker.sock 2>/dev/null || chown root:docker /var/run/docker.sock 2>/dev/null || true\n\
    fi\n\
else\n\
    echo "WARNING: Docker socket not found at /var/run/docker.sock"\n\
    echo "Make sure the socket is mounted in docker-compose.yml"\n\
fi\n\
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
