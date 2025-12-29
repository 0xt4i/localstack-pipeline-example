#!/bin/bash

# Start LocalStack with k3d support for EKS cluster creation
# This script mounts k3d binary and Docker socket into LocalStack container

set -e

# Activate LocalStack venv
source /home/tainh/Documents/localstack-pipeline-example/localstack/bin/activate

# Create network with lower MTU to fix HTTPS connectivity issues in WSL2
# MTU 1350 is recommended for WSL2 to prevent TLS handshake failures
docker network create localstack-network --driver bridge --opt com.docker.network.driver.mtu=1350 2>/dev/null || true

# Export Docker flags for k3d support
# Mount k3d binary from host (WSL2 HTTPS issue prevents auto-download)
# Mount Docker socket and binary for k3d to create clusters
export DOCKER_FLAGS="-v /usr/local/bin/k3d:/usr/local/bin/k3d -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -e EKS_START_K3D_LB_INGRESS=1 --network localstack-network"

echo "Starting LocalStack with k3d support..."
echo "Docker flags: $DOCKER_FLAGS"
echo ""

# Start LocalStack
localstack start -d

echo ""
echo "LocalStack container started!"
echo "Waiting for LocalStack to be ready..."

# Wait for LocalStack to be healthy
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        echo "LocalStack is ready!"
        break
    fi
    echo "Attempt $((attempt + 1))/$max_attempts - waiting..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "ERROR: LocalStack failed to start within timeout"
    exit 1
fi

# Show health status
echo ""
echo "LocalStack Health Status:"
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool || echo "Failed to parse JSON"

echo ""
echo "Verifying k3d availability in container:"
docker exec localstack-main which k3d && docker exec localstack-main k3d version || echo "WARNING: k3d not available"

echo ""
echo "LocalStack is ready for EKS cluster creation!"
