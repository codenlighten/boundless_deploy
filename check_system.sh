#!/bin/bash

# Boundless Node - System Check & Quick Start Guide
# Checks prerequisites and guides user to the right deployment method

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Boundless BLS Node - System Check & Deployment Guide"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track issues
ISSUES=0

# Check Docker
echo "🔍 Checking Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "   ✅ Docker installed: $DOCKER_VERSION"
    
    if docker info &> /dev/null; then
        echo "   ✅ Docker daemon running"
    else
        echo "   ❌ Docker daemon not running"
        echo "      Start with: sudo systemctl start docker"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "   ❌ Docker not installed"
    echo "      Install with:"
    echo "        sudo apt update"
    echo "        sudo apt install docker.io -y"
    echo "        sudo systemctl start docker"
    echo "        sudo usermod -aG docker $USER"
    ISSUES=$((ISSUES + 1))
fi

# Check Python
echo ""
echo "🔍 Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo "   ✅ Python installed: $PYTHON_VERSION"
    
    # Check keygen dependencies
    if python3 -c "import mnemonic, Crypto.Hash, nacl" 2>/dev/null; then
        echo "   ✅ Wallet generation dependencies installed"
    else
        echo "   ⚠️  Wallet generation dependencies missing"
        echo "      Install with: pip3 install mnemonic PyNaCl pycryptodome"
        echo "      (Will auto-install on first use)"
    fi
else
    echo "   ❌ Python 3 not installed"
    echo "      Install with: sudo apt install python3 python3-pip -y"
    ISSUES=$((ISSUES + 1))
fi

# Check Node.js (optional, for controller)
echo ""
echo "🔍 Checking Node.js (optional, for advanced deployment)..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js installed: $NODE_VERSION"
else
    echo "   ℹ️  Node.js not installed (optional)"
    echo "      Required only for: node controller/deploy.js"
    echo "      Install with: sudo apt install nodejs npm -y"
fi

# Check keygen folder
echo ""
echo "🔍 Checking wallet generation system..."
if [ -f "keygen/boundless_wallet_gen.py" ]; then
    echo "   ✅ Wallet generator found"
else
    echo "   ❌ Wallet generator not found"
    echo "      Expected: keygen/boundless_wallet_gen.py"
    ISSUES=$((ISSUES + 1))
fi

# Check start script
echo ""
echo "🔍 Checking deployment scripts..."
if [ -f "start_boundless_node.sh" ]; then
    if [ -x "start_boundless_node.sh" ]; then
        echo "   ✅ Interactive script ready: start_boundless_node.sh"
    else
        echo "   ⚠️  Script not executable"
        chmod +x start_boundless_node.sh
        echo "      Fixed: chmod +x start_boundless_node.sh"
    fi
else
    echo "   ❌ start_boundless_node.sh not found"
    ISSUES=$((ISSUES + 1))
fi

if [ -f "controller/deploy.js" ]; then
    echo "   ✅ Controller ready: controller/deploy.js"
else
    echo "   ⚠️  controller/deploy.js not found (optional)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ISSUES -eq 0 ]; then
    echo "✅ System check passed! You're ready to deploy."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📚 Choose your deployment method:"
    echo ""
    echo "1️⃣  QUICK START (Recommended for new users)"
    echo "   Interactive script with automatic wallet generation"
    echo ""
    echo "   ./start_boundless_node.sh"
    echo ""
    echo "2️⃣  ADVANCED (Schema-driven deployment)"
    echo "   For production and multi-node deployments"
    echo ""
    echo "   # Configure cluster.json first, then:"
    echo "   node controller/deploy.js"
    echo ""
    echo "3️⃣  GENERATE WALLET ONLY"
    echo "   Create wallet without starting node"
    echo ""
    echo "   python3 keygen/boundless_wallet_gen.py generate"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📖 Documentation:"
    echo "   README.md - Complete guide"
    echo "   WALLET_INTEGRATION.md - Wallet generation details"
    echo "   keygen/SECURITY.md - Security best practices"
    echo ""
    echo "🌐 Network:"
    echo "   Explorer: https://64.225.16.227/"
    echo "   Bootnode: /ip4/159.203.114.205/tcp/30333/p2p/12D3KooW..."
    echo ""
    
    # Offer to start immediately
    echo -n "Would you like to start the quick deployment now? (yes/no): "
    read -r START_NOW
    
    if [ "$START_NOW" = "yes" ] || [ "$START_NOW" = "y" ]; then
        echo ""
        exec ./start_boundless_node.sh
    fi
    
else
    echo "❌ System check found $ISSUES issue(s)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please fix the issues above and run this script again."
    echo ""
    exit 1
fi

echo ""
