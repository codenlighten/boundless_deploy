#!/bin/bash

# Boundless BLS Node - Start Script for Ubuntu
# This script will download, load, and run the Boundless blockchain node

set -e  # Exit on error

echo "======================================"
echo "Boundless BLS Node - Quick Start"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  WARNING: Running as root user"
    echo ""
    echo "It's recommended to run this script as a regular user with sudo privileges."
    echo -n "Continue as root? (yes/no): "
    read -r CONTINUE_AS_ROOT
    
    if [ "$CONTINUE_AS_ROOT" != "yes" ] && [ "$CONTINUE_AS_ROOT" != "y" ]; then
        echo "Please run this script as a regular user."
        exit 1
    fi
    echo ""
fi

# Configuration
IMAGE_URL="http://159.203.114.205/tmp/boundless-mainnet-genesis.tar.gz"
IMAGE_FILE="boundless-mainnet-genesis.tar.gz"
CONTAINER_NAME="boundless-node"
IMAGE_NAME="boundless-mainnet:genesis"

# SOVRN Genesis Authority Configuration
GENESIS_HASH="19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79"
GENESIS_TIMESTAMP="1735689600"  # Jan 1, 2025 00:00:00 UTC
SOVRN_PEER_ID="12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8"
SNTNL_PEER_ID="12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ"

# Check if curl is installed (needed for downloading)
if ! command -v curl &> /dev/null; then
    echo "⚠️  curl is not installed!"
    echo ""
    echo "curl is required to download the blockchain image."
    echo -n "Would you like to install curl now? (yes/no): "
    read -r INSTALL_CURL
    
    if [ "$INSTALL_CURL" = "yes" ] || [ "$INSTALL_CURL" = "y" ]; then
        echo "Installing curl..."
        sudo apt update
        sudo apt install curl -y
        echo "✅ curl installed successfully!"
        echo ""
    else
        echo "ERROR: curl is required to download the blockchain image."
        exit 1
    fi
fi

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
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        echo "⚠️  Python 3 is not installed!"
        echo ""
        echo -n "Would you like to install Python 3 now? (yes/no): "
        read -r INSTALL_PYTHON
        
        if [ "$INSTALL_PYTHON" = "yes" ] || [ "$INSTALL_PYTHON" = "y" ]; then
            echo "Installing Python 3..."
            sudo apt update
            sudo apt install python3 python3-pip -y
            echo "✅ Python 3 installed successfully!"
        else
            echo "ERROR: Python 3 is required for wallet generation."
            exit 1
        fi
    fi
    
    # Check if pip3 is installed
    if ! command -v pip3 &> /dev/null; then
        echo "⚠️  pip3 is not installed!"
        echo ""
        echo -n "Would you like to install pip3 now? (yes/no): "
        read -r INSTALL_PIP
        
        if [ "$INSTALL_PIP" = "yes" ] || [ "$INSTALL_PIP" = "y" ]; then
            echo "Installing pip3..."
            sudo apt update
            sudo apt install python3-pip -y
            echo "✅ pip3 installed successfully!"
        else
            echo "ERROR: pip3 is required for wallet generation."
            exit 1
        fi
    fi
    
    # Check Python dependencies
    if ! python3 -c "import mnemonic, Crypto.Hash, nacl" 2>/dev/null; then
        echo "Installing required Python dependencies..."
        echo "This may take a minute..."
        
        # Try pip3 install
        if pip3 install mnemonic PyNaCl pycryptodome 2>/dev/null; then
            echo "✅ Dependencies installed successfully!"
        else
            # If pip3 fails, try with --break-system-packages flag (for newer Ubuntu versions)
            echo "Retrying with --break-system-packages flag..."
            pip3 install mnemonic PyNaCl pycryptodome --break-system-packages || {
                echo "ERROR: Failed to install dependencies"
                echo ""
                echo "Please try manually:"
                echo "  pip3 install mnemonic PyNaCl pycryptodome"
                echo ""
                echo "Or use option 2 to provide an existing wallet address."
                exit 1
            }
            echo "✅ Dependencies installed successfully!"
        fi
        echo ""
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Existing Node Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "A Boundless node container already exists."
    echo ""
    echo "Options:"
    echo "  1) Resume existing node (keeps all blockchain data)"
    echo "  2) Start fresh (WARNING: deletes all blockchain data and wallet config)"
    echo ""
    echo -n "Enter choice (1 or 2): "
    read -r EXISTING_CHOICE
    
    if [ "$EXISTING_CHOICE" = "1" ]; then
        echo ""
        echo "Resuming existing node..."
        
        # Check if container is already running
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "✅ Node is already running!"
            echo ""
            echo "Useful commands:"
            echo "  - View logs:    docker logs -f $CONTAINER_NAME"
            echo "  - Stop node:    docker stop $CONTAINER_NAME"
            echo "  - Restart:      docker restart $CONTAINER_NAME"
            echo ""
            echo "Viewing logs now (Ctrl+C to exit)..."
            sleep 2
            docker logs -f "$CONTAINER_NAME"
        else
            docker start "$CONTAINER_NAME"
            echo "✅ Node resumed successfully!"
            echo ""
            echo "The node will continue from where it left off."
            echo ""
            echo "Viewing logs now (Ctrl+C to exit)..."
            sleep 2
            docker logs -f "$CONTAINER_NAME"
        fi
        exit 0
        
    elif [ "$EXISTING_CHOICE" = "2" ]; then
        echo ""
        echo "⚠️  WARNING: This will DELETE all blockchain data!"
        echo ""
        echo "This includes:"
        echo "  • All downloaded blocks"
        echo "  • Wallet configuration"
        echo "  • Mining progress"
        echo ""
        echo -n "Are you absolutely sure? Type 'DELETE' to confirm: "
        read -r CONFIRM_DELETE
        
        if [ "$CONFIRM_DELETE" = "DELETE" ]; then
            echo ""
            echo "Stopping and removing existing container..."
            docker stop "$CONTAINER_NAME" 2>/dev/null || true
            docker rm "$CONTAINER_NAME" 2>/dev/null || true
            
            echo "Removing blockchain data volume..."
            docker volume rm boundless-data 2>/dev/null || true
            
            echo "✅ Cleanup complete. Starting fresh..."
            echo ""
        else
            echo ""
            echo "Deletion cancelled. Exiting."
            exit 0
        fi
    else
        echo ""
        echo "ERROR: Invalid choice. Please enter 1 or 2."
        exit 1
    fi
fi

# Download Docker image if not already present
if [ ! -f "$IMAGE_FILE" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Download SOVRN Genesis Image"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The genesis image needs to be obtained from SOVRN authority."
    echo ""
    echo "Options:"
    echo "  1) Download via SCP from SOVRN (requires SSH access)"
    echo "  2) I already have the image file in current directory"
    echo "  3) Build from source (advanced - requires git repo)"
    echo ""
    echo -n "Enter choice (1, 2, or 3): "
    read -r DOWNLOAD_CHOICE
    
    if [ "$DOWNLOAD_CHOICE" = "1" ]; then
        echo ""
        echo "Downloading from SOVRN (159.203.114.205)..."
        echo "You may be prompted for the SOVRN server password."
        echo ""
        
        if scp root@159.203.114.205:/tmp/boundless-mainnet-genesis.tar.gz "$IMAGE_FILE"; then
            echo "✅ Download successful!"
        else
            echo ""
            echo "❌ Download failed. Please ensure:"
            echo "   • You have SSH access to 159.203.114.205"
            echo "   • The image exists at /tmp/boundless-mainnet-genesis.tar.gz"
            echo ""
            echo "Alternative: Contact Bryan for image access"
            exit 1
        fi
        
    elif [ "$DOWNLOAD_CHOICE" = "2" ]; then
        echo ""
        echo "Looking for $IMAGE_FILE in current directory..."
        
        if [ -f "$IMAGE_FILE" ]; then
            echo "✅ Found $IMAGE_FILE"
        else
            echo "❌ File not found: $IMAGE_FILE"
            echo ""
            echo "Please copy the genesis image to:"
            echo "  $(pwd)/$IMAGE_FILE"
            echo ""
            echo "Then run this script again."
            exit 1
        fi
        
    elif [ "$DOWNLOAD_CHOICE" = "3" ]; then
        echo ""
        echo "Building from source..."
        echo ""
        echo "This option requires:"
        echo "  • Boundless source code repository"
        echo "  • Rust toolchain installed"
        echo "  • Docker build capabilities"
        echo ""
        echo -n "Do you have the Boundless source repo? (yes/no): "
        read -r HAS_SOURCE
        
        if [ "$HAS_SOURCE" = "yes" ] || [ "$HAS_SOURCE" = "y" ]; then
            echo ""
            echo -n "Enter path to Boundless source directory: "
            read -r SOURCE_PATH
            
            if [ -d "$SOURCE_PATH" ]; then
                echo "Building Docker image from source..."
                cd "$SOURCE_PATH"
                
                if docker build -t "$IMAGE_NAME" .; then
                    cd - > /dev/null
                    echo "✅ Build successful!"
                    # Skip the load step since we built directly
                    IMAGE_FILE=""
                else
                    cd - > /dev/null
                    echo "❌ Build failed"
                    exit 1
                fi
            else
                echo "ERROR: Directory not found: $SOURCE_PATH"
                exit 1
            fi
        else
            echo ""
            echo "Please obtain the source code or genesis image."
            echo "Contact Bryan for access."
            exit 1
        fi
    else
        echo "ERROR: Invalid choice. Please enter 1, 2, or 3."
        exit 1
    fi
else
    echo ""
    echo "Docker image file already exists, skipping download."
fi

# Load Docker image (if we downloaded a file)
if [ -n "$IMAGE_FILE" ] && [ -f "$IMAGE_FILE" ]; then
    echo ""
    echo "Loading Docker image..."
    
    # Check if it's gzipped
    if file "$IMAGE_FILE" | grep -q "gzip compressed"; then
        echo "Detected gzip compression, decompressing..."
        gunzip -c "$IMAGE_FILE" | docker load
    else
        echo "Loading tar archive..."
        docker load < "$IMAGE_FILE"
    fi
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ Failed to load Docker image"
        echo ""
        echo "The image file may be corrupted or in an unexpected format."
        echo "File info:"
        file "$IMAGE_FILE"
        echo ""
        echo "Please verify the image file or re-download."
        exit 1
    fi
    
    echo "✅ Image loaded successfully!"
fi

# Verify the image exists
echo ""
echo "Verifying Docker image..."
if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "❌ Image not found: $IMAGE_NAME"
    echo ""
    echo "Available images:"
    docker images
    echo ""
    echo "Please ensure the image is loaded correctly."
    exit 1
fi
echo "✅ Image verified: $IMAGE_NAME"

# Create data directory with proper permissions
echo ""
echo "Preparing data directory..."
sudo mkdir -p /mnt/boundless_data
sudo chmod 777 /mnt/boundless_data

# Run the container
echo ""
echo "Starting Boundless BLS mainnet node..."
echo "Genesis Hash: $GENESIS_HASH"
echo "Connecting to SOVRN Genesis Authority..."
echo ""
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p 30333:30333 \
    -p 9933:9933 \
    -p 9944:9944 \
    -p 3001:3001 \
    -v /mnt/boundless_data:/data \
    -e RUST_LOG=info \
    --health-cmd="curl -sf -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}' http://localhost:9933/ || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=5 \
    --health-start-period=60s \
    "$IMAGE_NAME" \
    --base-path /data \
    --mining \
    --coinbase "$MINING_ADDRESS" \
    --mining-threads "$MINING_THREADS" \
    --rpc-host 0.0.0.0 \
    --bootnodes "/ip4/159.203.114.205/tcp/30333/p2p/$SOVRN_PEER_ID" \
    --bootnodes "/ip4/104.248.166.157/tcp/30333/p2p/$SNTNL_PEER_ID"

echo ""
echo "======================================"
echo "Node started successfully!"
echo "======================================"
echo ""
echo "Configuration:"
echo "  - Mining Address: $MINING_ADDRESS"
echo "  - Mining Threads: $MINING_THREADS"
echo "  - P2P Port: 30333"
echo "  - RPC HTTP Port: 9933"
echo "  - RPC WebSocket Port: 9944"
echo "  - API Port: 3001"
echo ""
echo "Boundless BLS Mainnet Information:"
echo "  Genesis Authority: SOVRN (159.203.114.205)"
echo "  Genesis Hash: $GENESIS_HASH"
echo "  Genesis Timestamp: Jan 1, 2025 00:00:00 UTC"
echo "  SOVRN Peer: $SOVRN_PEER_ID"
echo "  SNTNL Peer: $SNTNL_PEER_ID"
echo ""
echo "Ecosystem:"
echo "  Explorer: https://traceboundless.com"
echo "  Trust: https://boundlesstrust.org"
echo "  Wallet: https://e2multipass.com (https://github.com/Saifullah62/E2-Multipass)"
echo "  dApp: https://swarmproof.com"
echo ""
echo "Useful commands:"
echo "  - View logs:       docker logs -f $CONTAINER_NAME"
echo "  - Stop node:       docker stop $CONTAINER_NAME"
echo "  - Start node:      docker start $CONTAINER_NAME"
echo "  - Restart node:    docker restart $CONTAINER_NAME"
echo "  - Node health:     docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME"
echo "  - Block height:    docker exec $CONTAINER_NAME curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"chain_getBlockHeight\",\"params\":[],\"id\":1}' http://localhost:9933/"
echo "  - Peer count:      docker exec $CONTAINER_NAME curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}' http://localhost:9933/"
echo "  - Remove node:     docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo ""
echo "Waiting for node to start (checking health)..."
sleep 10
echo ""
echo "Node health status:"
docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "Health check starting..."
echo ""
echo "Viewing logs now (Ctrl+C to exit)..."
sleep 2
docker logs -f "$CONTAINER_NAME"
