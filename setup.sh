#!/bin/bash

# Boundless BLS Network - Node Setup Script
# Based on Bryan's official boundless-node-package

set -e

# Network Configuration
GENESIS_HASH="19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79"
SOVRN_BOOTNODE="/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWQdPKn2koRRkoKZiQz6dBovKgf1ZMAqqFDPjkm7Xrw6Up"
SNTNL_BOOTNODE="/ip4/104.248.166.157/tcp/30333/p2p/12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ"

echo "======================================"
echo "Boundless BLS Network - Node Setup"
echo "======================================"
echo ""
echo "Genesis Hash: $GENESIS_HASH"
echo ""

# Parse arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <coinbase-address> [node-name] [mining-threads]"
    echo ""
    echo "Arguments:"
    echo "  coinbase-address    Your 64-character hex mining address (required)"
    echo "  node-name          Name for this node (optional, default: boundless-node)"
    echo "  mining-threads     Number of CPU threads for mining (optional, default: 2)"
    echo ""
    echo "Example:"
    echo "  $0 bbc7b10e66302282541a8083f3a7243bab9f732c9aed5924df4c2646e98758f2 my-node 4"
    exit 1
fi

COINBASE="$1"
NODE_NAME="${2:-boundless-node}"
MINING_THREADS="${3:-2}"

# Validate coinbase address
if ! echo "$COINBASE" | grep -qE '^[0-9a-fA-F]{64}$'; then
    echo "ERROR: Invalid coinbase address format"
    echo "Expected: 64 hexadecimal characters"
    echo "Got: $COINBASE (${#COINBASE} characters)"
    exit 1
fi

echo "Configuration:"
echo "  - Coinbase Address: $COINBASE"
echo "  - Node Name: $NODE_NAME"
echo "  - Mining Threads: $MINING_THREADS"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    echo "Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if image is loaded
if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "boundless-mainnet:genesis"; then
    echo "ERROR: Docker image 'boundless-mainnet:genesis' not found"
    echo ""
    echo "Please load the image first:"
    echo "  gunzip -c boundless-bls-node-package-complete.tar.gz | docker load"
    echo ""
    echo "Or download from SOVRN:"
    echo "  ssh root@159.203.114.205 'docker save boundless-mainnet:genesis | gzip' > image.tar.gz"
    echo "  gunzip -c image.tar.gz | docker load"
    exit 1
fi

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^${NODE_NAME}$"; then
    echo "Stopping existing container: $NODE_NAME"
    docker stop "$NODE_NAME" 2>/dev/null || true
    docker rm "$NODE_NAME" 2>/dev/null || true
fi

# Create data directory
DATA_DIR="/mnt/boundless_data_${NODE_NAME}"
mkdir -p "$DATA_DIR"
chmod 777 "$DATA_DIR"

echo ""
echo "Starting node..."
echo ""

# Run the node
# Note: Based on the error, the node binary doesn't accept --bootnodes
# Peer discovery may be built into the genesis image or happen via DHT
docker run -d \
    --name "$NODE_NAME" \
    --restart unless-stopped \
    -p 30333:30333 \
    -p 9933:9933 \
    -p 9944:9944 \
    -p 3001:3001 \
    -v "$DATA_DIR:/data" \
    -e RUST_LOG=info \
    boundless-mainnet:genesis \
    --base-path /data \
    --mining \
    --coinbase "$COINBASE" \
    --mining-threads "$MINING_THREADS" \
    --rpc-host 0.0.0.0

if [ $? -eq 0 ]; then
    echo "✅ Node started successfully!"
    echo ""
    echo "Container ID:"
    docker ps --filter "name=$NODE_NAME" --format "{{.ID}}"
    echo ""
    echo "Network Information:"
    echo "  Genesis Hash: $GENESIS_HASH"
    echo "  SOVRN Bootnode: $SOVRN_BOOTNODE"
    echo "  SNTNL Bootnode: $SNTNL_BOOTNODE"
    echo ""
    echo "Useful Commands:"
    echo "  View logs:       docker logs -f $NODE_NAME"
    echo "  Stop node:       docker stop $NODE_NAME"
    echo "  Start node:      docker start $NODE_NAME"
    echo "  Remove node:     docker stop $NODE_NAME && docker rm $NODE_NAME"
    echo ""
    echo "Monitoring:"
    echo "  Block height:    docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"chain_getBlockHeight\",\"params\":[],\"id\":1}' http://localhost:9933/"
    echo "  Health:          docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}' http://localhost:9933/"
    echo ""
    echo "Viewing initial logs (Ctrl+C to exit)..."
    sleep 2
    docker logs -f "$NODE_NAME"
else
    echo "❌ Failed to start node"
    exit 1
fi
