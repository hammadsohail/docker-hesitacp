#!/bin/bash

#Pull updated files from repo
git pull

# Stop all running containers forcefully
docker stop $(docker ps -aq) || true

# Remove all containers forcefully
docker rm -f $(docker ps -aq) || true

# Remove all images forcefully
docker rmi -f $(docker images -aq) || true

# Remove all volumes forcefully
docker volume prune -f || true

# Remove all networks forcefully
docker network prune -f || true

# Remove all dangling images forcefully
docker image prune -f || true

# Remove all unused images, containers, networks, and volumes forcefully
docker system prune -af || true

# Restart Docker service (may require sudo privileges)
sudo systemctl restart docker

#Clear Terminal
clear

# Start Building HCP Without Cache
sudo docker build --no-cache -t hcpnewamd .

# Start running image 
HSTC_HOSTNAME="example.com" docker-compose up -d