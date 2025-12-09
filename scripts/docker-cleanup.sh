#!/usr/bin/env bash

set -e

echo -e "Docker cleanup script\n"
# Stop all docker containers
docker stop $(docker ps -q)
# Remove all docker containers
docker rm $(docker ps -a -q)

docker rmi $(docker images)     # Now, removing the images
echo -e "Cleanup complete\n"
