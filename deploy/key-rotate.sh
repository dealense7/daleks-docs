#!/bin/bash

# Script to generate daily JWT key pairs and clean up expired keys
# Usage: ./key-rotate.sh

set -e

# Directories for key storage
PRIVATE_KEY_DIR="services/users/keystore/private"
PUBLIC_KEY_DIR="services/users/keystore/public"

# Create directories if they don't exist
mkdir -p "$PRIVATE_KEY_DIR" "$PUBLIC_KEY_DIR"

# Generate new key pair for tomorrow
TOMORROW=$(date -d "tomorrow" +%Y-%m-%d)
PRIVATE_KEY="$PRIVATE_KEY_DIR/$TOMORROW.pem"
PUBLIC_KEY="$PUBLIC_KEY_DIR/$TOMORROW.pem.pub"

echo "Generating new key pair for $TOMORROW..."
openssl genrsa -out "$PRIVATE_KEY" 2048
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY"
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

# Clean up keys older than 48 hours (24 hours validity + 24 hours grace)
find "$PRIVATE_KEY_DIR" -name "*-*.pem" -mtime +2 -delete
find "$PUBLIC_KEY_DIR" -name "*-*.pem.pub" -mtime +2 -delete
echo "Deleted keys older than 48 hours"