#!/bin/bash

# Boundless Local Test Deployment
# Sets up a local node for testing transactions and metrics

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Boundless BLS - Local Test Deployment                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
CONTAINER_NAME="boundless-test-node"
IMAGE_URL="http://159.203.114.205/node/blockchain-image.tar.gz"
IMAGE_FILE="blockchain-image.tar.gz"
IMAGE_NAME="boundless-bls-platform-blockchain:latest"
RPC_PORT=9933
P2P_PORT=30333
METRICS_PORT=9615

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker daemon is running (try with and without sudo)
if ! docker info &> /dev/null; then
    if ! sudo docker info &> /dev/null; then
        echo "❌ Docker daemon is not running. Please start Docker."
        echo "   Run: sudo systemctl start docker"
        exit 1
    fi
    
    # Docker is running but user needs permissions
    echo "⚠️  Docker requires sudo. Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo ""
    echo "✓ Added to docker group. Using sudo for this session."
    echo "  (Log out and back in to use docker without sudo)"
    echo ""
    DOCKER_CMD="sudo docker"
else
    DOCKER_CMD="docker"
fi

echo "✓ Docker is ready"
echo ""

# Generate test wallet
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Generating Test Wallet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Python dependencies
if ! python3 -c "import mnemonic, Crypto.Hash, nacl" 2>/dev/null; then
    echo "Installing Python dependencies..."
    pip3 install mnemonic PyNaCl pycryptodome --break-system-packages 2>/dev/null || \
    pip3 install mnemonic PyNaCl pycryptodome --user
fi

# Generate wallet with private key for testing
WALLET_FILE="test_wallet_$(date +%Y%m%d_%H%M%S).json"
python3 keygen/boundless_wallet_gen.py generate --show-private --output "$WALLET_FILE" > /dev/null 2>&1

MINING_ADDRESS=$(python3 -c "import json; print(json.load(open('$WALLET_FILE'))['address'])")
MNEMONIC=$(python3 -c "import json; print(json.load(open('$WALLET_FILE'))['mnemonic'])")

echo "✅ Test wallet generated!"
echo ""
echo "📬 Address: $MINING_ADDRESS"
echo "💾 Wallet file: $WALLET_FILE"
echo ""
echo "🔑 Recovery phrase (write this down for testing):"
echo "   $MNEMONIC"
echo ""

# Stop existing container if present
if $DOCKER_CMD ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing test container..."
    $DOCKER_CMD stop "$CONTAINER_NAME" 2>/dev/null || true
    $DOCKER_CMD rm "$CONTAINER_NAME" 2>/dev/null || true
    echo ""
fi

# Download and load image if needed
if ! $DOCKER_CMD images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
    if [ ! -f "$IMAGE_FILE" ]; then
        echo "Downloading blockchain image (46MB)..."
        curl -# -O "$IMAGE_URL"
        echo ""
    fi
    
    echo "Loading Docker image..."
    $DOCKER_CMD load < "$IMAGE_FILE"
    echo ""
fi

# Start node
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Test Node"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

$DOCKER_CMD run -d \
    --name "$CONTAINER_NAME" \
    -p $RPC_PORT:9933 \
    -p $P2P_PORT:30333 \
    -v boundless-test-data:/data \
    "$IMAGE_NAME" \
    --base-path /data \
    --mining \
    --coinbase "$MINING_ADDRESS" \
    --mining-threads 2 \
    --rpc-host 0.0.0.0

echo "✅ Node started successfully!"
echo ""

# Wait for node to start
echo "Waiting for node to initialize..."
sleep 5

# Show status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Container:  $CONTAINER_NAME"
echo "Status:     $($DOCKER_CMD ps --format '{{.Status}}' --filter name=$CONTAINER_NAME)"
echo ""
echo "Wallet:"
echo "  Address:  $MINING_ADDRESS"
echo "  File:     $WALLET_FILE"
echo ""
echo "Endpoints:"
echo "  RPC:      http://localhost:$RPC_PORT"
echo "  P2P:      localhost:$P2P_PORT"
echo ""
echo "Network:"
echo "  Primary Node: 104.248.166.157 (SNTNL)"
echo "  Bootnode: /ip4/159.203.114.205/tcp/30333/p2p/12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE"
echo "  Explorer: https://traceboundless.com"
echo "  Resources: http://159.203.114.205/node/"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Testing Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "# View logs"
echo "docker logs -f $CONTAINER_NAME"
echo ""
echo "# Check balance"
echo "python3 send_transaction.py --balance $MINING_ADDRESS"
echo ""
echo "# Create second wallet for testing"
echo "python3 keygen/boundless_wallet_gen.py generate --show-private -o test_wallet2.json"
echo ""
echo "# Send transaction"
echo "python3 send_transaction.py --from $WALLET_FILE --to <address> --amount 10"
echo ""
echo "# Stop node"
echo "docker stop $CONTAINER_NAME"
echo ""
echo "# Remove node"
echo "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏳ Showing logs (Ctrl+C to exit)..."
echo ""
sleep 2

$DOCKER_CMD logs -f "$CONTAINER_NAME"
