#!/bin/bash
# Script to install Docker inside a container, how meta
# WARNING: This requires the container to be run with --privileged flag

set -e

echo "Installing Docker inside container..."

# Check if we're in a container
if [ ! -f /.dockerenv ]; then
    echo "WARNING: This doesn't appear to be a container environment"
fi

# Install Docker using the official script
if [ ! -f /usr/bin/docker ]; then
    echo "Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Start Docker daemon
echo "Starting Docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &

# Wait for Docker to be ready
echo "Waiting for Docker to start..."
timeout=30
counter=0
while ! docker info > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo "ERROR: Docker failed to start within $timeout seconds"
        echo "Check logs: tail -f /var/log/dockerd.log"
        exit 1
    fi
    sleep 1
    counter=$((counter + 1))
done

echo "Docker is now running!"
docker version
