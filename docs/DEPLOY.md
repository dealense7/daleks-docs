# Deployment and Local Run Guide

This document outlines how to deploy and run the **Daleks** project locally using Docker. The project consists of two main services: **Users Service** (handles authentication) and **Files Service** (manages file storage with Minio as the S3 backend). Each service has its own database and configuration. JWT keys are rotated daily via a cronjob, and the Users Service dynamically selects the latest key at runtime.

## Prerequisites
- **Docker** and **Docker Compose** installed.
- Project files in the structure described in `docs/ARCHITECTURE.md`.
- Bash shell for running scripts (Linux/macOS or WSL on Windows).
- `openssl` installed for key generation.

## Project Files
Key files for deployment and local run:
- **Dockerfiles**: `docker/users/Dockerfile`, `docker/files/Dockerfile`
- **Compose Files**: `docker/compose/users.yml`, `docker/compose/files.yml`
- **Environment Files**: `envs/users.env`, `envs/files.env`
- **Scripts**: `deploy/deploy.sh`, `deploy/generate-env.sh`, `deploy/key-rotate.sh`

## Setup Instructions

### 1. Generate Environment Files
Create environment files for the services to configure database, Minio, and JWT settings. The Users Service dynamically selects the latest JWT key from the keystore directory.

```bash
chmod +x deploy/generate-env.sh
./deploy/generate-env.sh users
./deploy/generate-env.sh files DE
```
- Generates envs/users.env for the Users Service.
- Generates envs/files.env for the Files Service with region set to DE (modify for other regions like FR, US).

### 2. Deploy Services
Use the deployment script to build and run the services with Docker Compose.
```bash
chmod +x deploy/deploy.sh
./deploy/deploy.sh users
./deploy/deploy.sh files DE
```
- **Users Service**: Runs on `http://localhost:8080` with a PostgreSQL database (users-db). Selects the latest key from /app/keystore/private/ for token signing.
- **Files Service**: Runs on `http://localhost:8081` with a PostgreSQL database (files-db) and Minio (`http://localhost:9001` for console, minioadmin/miniosecret for login).

### 3. Verify Services
- **Users Service**: Test authentication endpoints (e.g., /login, /jwks) at `http://localhost:8080`.
- **Files Service**: Test file operations (e.g., upload/download) at `http://localhost:8081`.
- **Minio Console**: Access at `http://localhost:9001` to verify file storage.

### 4. Stop Services
Stop and remove containers:
```bash
docker-compose -f docker/compose/users.yml down
docker-compose -f docker/compose/files.yml down
```

### Notes
- **Security**: Update minioadmin/miniosecret in files.yml and files.env for production.
- **Regions**: For other regions, run `./deploy/generate-env.sh files [REGION]` and `./deploy/deploy.sh files [REGION]`.
- **Networking**: Services are isolated on separate networks (users-network, files-network). For cross-service communication (e.g., JWKS fetching), ensure JWKS_URL is accessible or add a shared network.
- **Databases**: Default credentials (postgres/postgres) are used. Update in users.yml, files.yml, and .env files for production.

### Troubleshooting
- **Port Conflicts**: If ports `8080`, `8081`, `5432`, `5433`, `9000`, or `9001` are in use, modify the Compose files.
- **Missing Files**: Ensure all migrations and keystore files are in place (`services/users/migrations`, `services/users/keystore`, `services/files/migrations`).
- **Logs**: Check container logs with `docker-compose -f docker/compose/[users|files].yml logs`.

For detailed architecture, see `docs/ARCHITECTURE.md`. For key rotation and JWKS setup, see `docs/TRUSTED-AUTH.md`.