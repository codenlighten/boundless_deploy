#!/bin/bash

echo "=========================================="
echo "Genesis Hash & Chain Verification"
echo "=========================================="
echo ""

NODE_NAME="${1:-boundless-node}"

echo "Expected Genesis Hash (SOVRN Mainnet):"
echo "19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Your Node's Genesis Hash"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try RPC method to get genesis hash
GENESIS_RESULT=$(docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"chain_getBlockHash","params":[0],"id":1}' \
  http://localhost:9933/ 2>/dev/null)

if echo "$GENESIS_RESULT" | grep -q '"result"'; then
    ACTUAL_GENESIS=$(echo "$GENESIS_RESULT" | python3 -c "import sys, json; print(json.load(sys.stdin)['result'])" 2>/dev/null | sed 's/0x//')
    echo "Your node's genesis hash:"
    echo "$ACTUAL_GENESIS"
    echo ""
    
    if [ "$ACTUAL_GENESIS" = "19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79" ]; then
        echo "✅ Genesis hash MATCHES - you're on the correct chain"
    else
        echo "❌ Genesis hash MISMATCH - you're on a different chain!"
        echo ""
        echo "This means:"
        echo "  - Your node started with a different genesis"
        echo "  - You're mining an isolated fork, not the mainnet"
        echo "  - Bootnodes reject your connection (wrong chain)"
        echo ""
        echo "Solution:"
        echo "  1. Stop and remove the container"
        echo "  2. Delete the data directory"
        echo "  3. Make sure you're using the official SOVRN genesis image"
        echo "  4. Start fresh"
    fi
else
    echo "⚠️  Could not retrieve genesis hash via RPC"
    echo ""
    echo "Checking container startup logs for genesis info..."
    docker logs $NODE_NAME 2>&1 | head -50 | grep -iE "genesis|chain|spec"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Full Container Startup Logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
docker logs $NODE_NAME 2>&1 | head -100

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Docker Image Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
docker inspect $NODE_NAME --format '{{.Config.Image}}' 2>/dev/null
docker images boundless-mainnet:genesis --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"

echo ""
