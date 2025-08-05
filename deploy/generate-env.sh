#!/bin/bash

# Script to scaffold environment files for users and files services
# Usage: ./generate-env.sh [users|files] [region]

SERVICE=$1
REGION=$2

# Generate users.env
if [ "$SERVICE" == "users" ] || [ -z "$SERVICE" ]; then
    cat > envs/users.env << EOL
# Users Service environment variables
APP_PORT=8080
DB_HOST=users-db
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=users
JWT_PRIVATE_KEY_DIR=/app/keystore/private
JWT_PUBLIC_KEY_DIR=/app/keystore/public
JWKS_URL=http://users-service:8080/jwks
LOG_LEVEL=info
EOL
    echo "Generated envs/users.env"
fi

# Generate files.env
if [ "$SERVICE" == "files" ] || [ -z "$SERVICE" ]; then
    if [ -z "$REGION" ]; then
        REGION="DE"
    fi
    cat > envs/files.env << EOL
# Files Service environment variables
APP_PORT=8081
DB_HOST=files-db
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=files
MINIO_HOST=minio
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=miniosecret
MINIO_BUCKET=daleks-files
JWKS_URL=http://users-service:8080/jwks
LOG_LEVEL=info
REGION=$REGION
EOL
    echo "Generated envs/files.env for region $REGION"
fi

if [ -z "$SERVICE" ]; then
    echo "Generated environment files for all services"
else
    echo "Generated environment file for $SERVICE service"
fi