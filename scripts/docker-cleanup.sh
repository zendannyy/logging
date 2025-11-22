#!/usr/bin/env bash

set -e

echo -e "Docker cleanup script\n"
# Stop all docker containers
docker stop $(docker ps -q)
# Remove all docker containers
docker rm $(docker ps -a -q)

# Now, removing the images
docker rmi $(docker images)
echo -e "Cleanup complete\n"
