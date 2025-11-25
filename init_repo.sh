#!/bin/bash

# Initialize Git Repository for Boundless Deploy
# This script sets up the repository for https://github.com/codenlighten/boundless_deploy

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Boundless Deploy - Repository Initialization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed"
    echo "   Install with: sudo apt install git -y"
    exit 1
fi

# Check if already a git repository
if [ -d .git ]; then
    echo "⚠️  This directory is already a git repository"
    echo ""
    echo "Current remotes:"
    git remote -v
    echo ""
    echo -n "Do you want to reinitialize? (yes/no): "
    read -r REINIT
    
    if [ "$REINIT" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
    
    echo "Removing existing .git directory..."
    rm -rf .git
fi

# Initialize repository
echo "Initializing git repository..."
git init

# Create initial commit
echo "Creating initial commit..."
git add .
git commit -m "Initial commit: Boundless node deployment with automatic wallet generation

Features:
- Automated Docker installation
- Interactive wallet generation (BIP39 24-word mnemonic)
- Schema-driven node deployment
- Lumenbridge hub integration
- Production-ready security hardening

Network:
- Mainnet: 159.203.114.205:30333
- Explorer: https://64.225.16.227/
"

# Set main branch
echo "Setting main branch..."
git branch -M main

# Add remote
echo "Adding remote origin..."
git remote add origin git@github.com:codenlighten/boundless_deploy.git

echo ""
echo "✅ Repository initialized successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Verify remote:"
echo "   git remote -v"
echo ""
echo "2. Push to GitHub:"
echo "   git push -u origin main"
echo ""
echo "   Note: Ensure you have SSH key configured on GitHub"
echo "   See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
echo ""
echo "3. After pushing, share the repository:"
echo "   https://github.com/codenlighten/boundless_deploy"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
