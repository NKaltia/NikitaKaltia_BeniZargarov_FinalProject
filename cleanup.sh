#!/bin/bash
# delete everything the project created in docker

echo "removing containers, network, volumes and images..."
docker compose down -v --rmi all

echo "cleanup done"