# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum for dependency caching
COPY services/files/go.mod services/files/go.sum ./services/files/
COPY libs ./libs

# Change to files service directory
WORKDIR /app/services/files

# Download dependencies
RUN go mod download

# Copy the rest of the files service source code
COPY services/files/ .

# Copy shared libraries
COPY libs/ ../../libs/

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/files-service ./cmd/server/main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Install Minio client (mc) for S3 interactions
RUN apk add --no-cache curl \
    && curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/bin/mc \
    && chmod +x /usr/bin/mc

# Copy the built binary
COPY --from=builder /app/files-service .

# Copy migrations
COPY services/files/migrations ./migrations

# Copy environment file (will be overridden by docker-compose or env vars)
COPY envs/files.env .

# Expose port for Files Service (default 8081, configurable via env)
EXPOSE 8081

# Command to run the service
CMD ["./files-service"]