# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum for dependency caching
COPY services/users/go.mod services/users/go.sum ./services/users/
COPY libs ./libs

# Change to users service directory
WORKDIR /app/services/users

# Download dependencies
RUN go mod download

# Copy the rest of the users service source code
COPY services/users/ .

# Copy shared libraries
COPY libs/ ../../libs/

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/users-service ./cmd/server/main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Install openssl for key generation and busybox for crond
RUN apk add --no-cache openssl busybox

# Copy the built binary
COPY --from=builder /app/users-service .

# Copy migrations and keystore
COPY services/users/migrations ./migrations
COPY services/users/keystore ./keystore

# Copy key-rotate.sh script
COPY deploy/key-rotate.sh ./key-rotate.sh

# Copy cron configuration
COPY deploy/users-cron /etc/crontabs/root

# Set permissions for key-rotate.sh and cron file
RUN chmod +x ./key-rotate.sh
RUN chmod 600 /etc/crontabs/root

# Copy environment file (will be overridden by docker-compose or env vars)
COPY envs/users.env .

# Expose port for Users Service (default 8080, configurable via env)
EXPOSE 8080

# Start crond in the foreground and the Users Service
CMD ["sh", "-c", "crond -f & ./users-service"]