#!/bin/bash

# Boundless BLS Node - Start Script for Ubuntu
# This script will download, load, and run the Boundless blockchain node

set -e  # Exit on error

echo "======================================"
echo "Boundless BLS Node - Quick Start"
echo "======================================"
echo ""

# Configuration
IMAGE_URL="http://159.203.114.205/node/blockchain-image.tar.gz"
IMAGE_FILE="blockchain-image.tar.gz"
CONTAINER_NAME="boundless-node"
IMAGE_NAME="boundless-bls-platform-blockchain:latest"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker is not installed!"
    echo ""
    echo "Docker is required to run the Boundless node."
    echo -n "Would you like to install Docker now? (yes/no): "
    read -r INSTALL_DOCKER
    
    if [ "$INSTALL_DOCKER" = "yes" ] || [ "$INSTALL_DOCKER" = "y" ]; then
        echo ""
        echo "Installing Docker..."
        sudo apt update
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add current user and root to docker group
        sudo usermod -aG docker $USER
        sudo usermod -aG docker root
        
        echo ""
        echo "✅ Docker installed successfully!"
        echo ""
        echo "⚠️  IMPORTANT: You need to log out and log back in for group changes to take effect."
        echo "   Or run: newgrp docker"
        echo ""
        echo -n "Continue anyway? (yes/no): "
        read -r CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            echo "Please log out and run this script again."
            exit 0
        fi
    else
        echo ""
        echo "Docker installation cancelled."
        echo "Please install Docker manually and run this script again."
        exit 1
    fi
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "⚠️  Docker daemon is not running!"
    echo ""
    echo -n "Would you like to start Docker now? (yes/no): "
    read -r START_DOCKER
    
    if [ "$START_DOCKER" = "yes" ] || [ "$START_DOCKER" = "y" ]; then
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "✅ Docker started successfully!"
    else
        echo "ERROR: Docker must be running to continue."
        echo "Start Docker with: sudo systemctl start docker"
        exit 1
    fi
fi

# Wallet/Mining Address Setup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Wallet Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Do you want to:"
echo "  1) Generate a NEW wallet (recommended for new users)"
echo "  2) Use an EXISTING address"
echo ""
echo -n "Enter choice (1 or 2): "
read -r WALLET_CHOICE

if [ "$WALLET_CHOICE" = "1" ]; then
    # Generate new wallet using Python keygen
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Generating New Wallet"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if Python keygen exists
    KEYGEN_SCRIPT="$(dirname "$0")/keygen/boundless_wallet_gen.py"
    if [ ! -f "$KEYGEN_SCRIPT" ]; then
        echo "ERROR: Wallet generator not found at: $KEYGEN_SCRIPT"
        echo "Please ensure the keygen folder exists in the same directory as this script."
        exit 1
    fi
    
    # Check Python dependencies
    if ! python3 -c "import mnemonic, Crypto.Hash, nacl" 2>/dev/null; then
        echo "Installing required Python dependencies..."
        pip3 install mnemonic PyNaCl pycryptodome --quiet || {
            echo "ERROR: Failed to install dependencies"
            echo "Please run: pip3 install mnemonic PyNaCl pycryptodome"
            exit 1
        }
    fi
    
    # Generate wallet
    WALLET_FILE="boundless_wallet_$(date +%Y%m%d_%H%M%S).json"
    python3 "$KEYGEN_SCRIPT" generate --output "$WALLET_FILE" 2>&1 | grep -v "^━\|^🔐\|^📝\|^💾\|^⚠️\|^✅"
    
    if [ ! -f "$WALLET_FILE" ]; then
        echo "ERROR: Wallet generation failed"
        exit 1
    fi
    
    # Extract address from wallet file
    MINING_ADDRESS=$(python3 -c "import json; print(json.load(open('$WALLET_FILE'))['address'])")
    MNEMONIC=$(python3 -c "import json; print(json.load(open('$WALLET_FILE'))['mnemonic'])")
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 CRITICAL: Save Your Recovery Phrase"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Write down these 24 words in order on paper:"
    echo ""
    echo "$MNEMONIC"
    echo ""
    echo "⚠️  SECURITY WARNINGS:"
    echo "   • This phrase is the ONLY way to recover your wallet"
    echo "   • Store it in a secure physical location"
    echo "   • NEVER share it with anyone"
    echo "   • NEVER store it digitally (no photos, no cloud)"
    echo ""
    echo "📬 Your mining address: $MINING_ADDRESS"
    echo "💾 Wallet saved to: $WALLET_FILE"
    echo ""
    echo -n "Have you written down your 24-word recovery phrase? (yes/no): "
    read -r CONFIRMED
    
    if [ "$CONFIRMED" != "yes" ]; then
        echo ""
        echo "❌ Please write down your recovery phrase before continuing."
        echo "   Your wallet file: $WALLET_FILE"
        exit 1
    fi
    
    echo ""
    echo "✅ Wallet setup complete!"
    
elif [ "$WALLET_CHOICE" = "2" ]; then
    # Use existing address
    echo ""
    echo "Enter your mining address (coinbase):"
    read -r MINING_ADDRESS
    
    if [ -z "$MINING_ADDRESS" ]; then
        echo "ERROR: Mining address cannot be empty!"
        exit 1
    fi
    
    # Validate address format (64 hex characters)
    if ! echo "$MINING_ADDRESS" | grep -qE '^[0-9a-fA-F]{64}$'; then
        echo "WARNING: Address format may be invalid"
        echo "Expected: 64 hexadecimal characters"
        echo "Got: $MINING_ADDRESS (${#MINING_ADDRESS} characters)"
        echo ""
        echo -n "Continue anyway? (yes/no): "
        read -r CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            exit 1
        fi
    fi
else
    echo "ERROR: Invalid choice. Please enter 1 or 2."
    exit 1
fi

echo ""

# Prompt for mining threads
echo ""
echo "Enter number of mining threads (default: 2):"
read -r MINING_THREADS
MINING_THREADS=${MINING_THREADS:-2}

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo "Container '$CONTAINER_NAME' already exists."
    echo "Do you want to remove it and start fresh? (y/n)"
    read -r REMOVE_EXISTING
    
    if [ "$REMOVE_EXISTING" = "y" ] || [ "$REMOVE_EXISTING" = "Y" ]; then
        echo "Stopping and removing existing container..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    else
        echo "Starting existing container..."
        docker start "$CONTAINER_NAME"
        echo ""
        echo "Container started! View logs with:"
        echo "  docker logs -f $CONTAINER_NAME"
        exit 0
    fi
fi

# Download Docker image if not already present
if [ ! -f "$IMAGE_FILE" ]; then
    echo ""
    echo "Downloading Docker image (46MB)..."
    curl -O "$IMAGE_URL"
else
    echo ""
    echo "Docker image file already exists, skipping download."
fi

# Load Docker image
echo ""
echo "Loading Docker image..."
docker load < "$IMAGE_FILE"

# Run the container
echo ""
echo "Starting Boundless BLS node..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p 30333:30333 \
    -p 9933:9933 \
    -v boundless-data:/data \
    "$IMAGE_NAME" \
    --base-path /data \
    --mining \
    --coinbase "$MINING_ADDRESS" \
    --mining-threads "$MINING_THREADS" \
    --rpc-host 0.0.0.0

echo ""
echo "======================================"
echo "Node started successfully!"
echo "======================================"
echo ""
echo "Configuration:"
echo "  - Mining Address: $MINING_ADDRESS"
echo "  - Mining Threads: $MINING_THREADS"
echo "  - P2P Port: 30333"
echo "  - RPC Port: 9933"
echo ""
echo "Mainnet Bootnode:"
echo "  /ip4/159.203.114.205/tcp/30333/p2p/12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE"
echo ""
echo "Explorer:"
echo "  https://64.225.16.227/"
echo ""
echo "Useful commands:"
echo "  - View logs:       docker logs -f $CONTAINER_NAME"
echo "  - Stop node:       docker stop $CONTAINER_NAME"
echo "  - Start node:      docker start $CONTAINER_NAME"
echo "  - Restart node:    docker restart $CONTAINER_NAME"
echo "  - Remove node:     docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo "  - Node status:     docker ps | grep $CONTAINER_NAME"
echo ""
echo "Viewing logs now (Ctrl+C to exit)..."
sleep 2
docker logs -f "$CONTAINER_NAME"
