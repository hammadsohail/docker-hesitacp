#!/bin/bash

# Stop all running containers
echo "Stopping all running containers..."
docker stop $(docker ps -a -q)

# Remove all containers
echo "Removing all containers..."
docker rm $(docker ps -a -q)

# Remove all images
echo "Removing all images..."
docker rmi $(docker images -q)

# Remove all volumes
echo "Removing all volumes..."
docker volume rm $(docker volume ls -q)

# Remove all networks
echo "Removing all networks..."
docker network rm $(docker network ls -q)

echo "Docker cleanup is complete."

# Stop and remove all containers
sudo docker-compose down

# Remove all images
sudo docker-compose rm -fsv

# Remove all volumes
sudo docker-compose down -v

# Remove all networks
sudo docker-compose down --remove-orphans

# Perform system prune
sudo docker system prune -a --volumes --force

# Remove Docker cache
sudo docker builder prune --all --force

# Remove unused Docker volumes
sudo docker volume prune --force
