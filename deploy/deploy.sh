#!/bin/bash

# Deployment script for Daleks project
# Usage: ./deploy.sh [users|files] [region]

set -e

SERVICE=$1
REGION=$2

if [ -z "$SERVICE" ]; then
    echo "Error: Service name required (users or files)"
    exit 1
fi

if [ "$SERVICE" == "files" ] && [ -z "$REGION" ]; then
    echo "Error: Region required for files service (e.g., DE, FR, US)"
    exit 1
fi

# Ensure environment files exist
if [ ! -f "./envs/$SERVICE.env" ]; then
    echo "Error: Environment file envs/$SERVICE.env not found"
    exit 1
fi

# Set compose file based on service
COMPOSE_FILE="docker/compose/$SERVICE.yml"

# For files service, update region in environment file if provided
if [ "$SERVICE" == "files" ]; then
    sed -i "s/REGION=.*/REGION=$REGION/" ./envs/files.env
fi

# Run docker-compose
echo "Deploying $SERVICE service..."
docker-compose -f $COMPOSE_FILE up -d --build

echo "$SERVICE service deployed successfully"