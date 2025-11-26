#!/bin/bash

# Boundless BLS Node - Peer Connection Checker

echo "=========================================="
echo "Boundless Node Peer Connection Check"
echo "=========================================="
echo ""

NODE_NAME="${1:-boundless-node}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${NODE_NAME}$"; then
    echo "❌ Container '$NODE_NAME' is not running"
    echo ""
    echo "Start your node with:"
    echo "  docker start $NODE_NAME"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Known peer IDs
SOVRN_PEER="12D3KooWQdPKn2koRRkoKZiQz6dBovKgf1ZMAqqFDPjkm7Xrw6Up"
SNTNL_PEER="12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking RPC Methods"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try system_peers
echo "Trying 'system_peers' method..."
PEERS_RESULT=$(docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"system_peers","params":[],"id":1}' \
  http://localhost:9933/ 2>/dev/null)

if echo "$PEERS_RESULT" | grep -q '"result"'; then
    echo "$PEERS_RESULT" | python3 -m json.tool 2>/dev/null || echo "$PEERS_RESULT"
elif echo "$PEERS_RESULT" | grep -q '"error"'; then
    echo "⚠️  Method 'system_peers' not available"
else
    echo "⚠️  No response from RPC"
fi

echo ""
echo "Trying 'system_health' method..."
HEALTH_RESULT=$(docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
  http://localhost:9933/ 2>/dev/null)

if echo "$HEALTH_RESULT" | grep -q '"result"'; then
    echo "$HEALTH_RESULT" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESULT"
elif echo "$HEALTH_RESULT" | grep -q '"error"'; then
    echo "⚠️  Method 'system_health' not available"
else
    echo "⚠️  No response from RPC"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Logs for Peer Connections"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check logs for peer-related messages
RECENT_LOGS=$(docker logs $NODE_NAME 2>&1 | tail -100)

echo "Looking for SOVRN peer: $SOVRN_PEER"
if echo "$RECENT_LOGS" | grep -q "$SOVRN_PEER"; then
    echo "✅ Found SOVRN peer ID in logs!"
    echo "$RECENT_LOGS" | grep "$SOVRN_PEER" | tail -3
else
    echo "⚠️  SOVRN peer ID not found in recent logs"
fi

echo ""
echo "Looking for SNTNL peer: $SNTNL_PEER"
if echo "$RECENT_LOGS" | grep -q "$SNTNL_PEER"; then
    echo "✅ Found SNTNL peer ID in logs!"
    echo "$RECENT_LOGS" | grep "$SNTNL_PEER" | tail -3
else
    echo "⚠️  SNTNL peer ID not found in recent logs"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Recent Connection/Peer Messages"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$RECENT_LOGS" | grep -iE "peer|connect|discover|dial|handshake" | tail -15

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Network Listening Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$RECENT_LOGS" | grep -iE "listening|started|address" | tail -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Block Sync Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BLOCK_HEIGHT=$(docker exec $NODE_NAME curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"chain_getBlockHeight","params":[],"id":1}' \
  http://localhost:9933/ 2>/dev/null)

if echo "$BLOCK_HEIGHT" | grep -q '"result"'; then
    HEIGHT=$(echo "$BLOCK_HEIGHT" | python3 -c "import sys, json; print(json.load(sys.stdin)['result'])" 2>/dev/null)
    echo "Current block height: $HEIGHT"
    
    if [ "$HEIGHT" -gt 0 ]; then
        echo "✅ Node is syncing/mining blocks"
    else
        echo "⚠️  Node at genesis (block 0)"
    fi
else
    echo "⚠️  Could not get block height"
fi

echo ""
echo "Recent block activity:"
echo "$RECENT_LOGS" | grep -iE "block|mined|synced" | tail -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Expected mainnet peers:"
echo "  SOVRN: /ip4/159.203.114.205/tcp/30333/p2p/$SOVRN_PEER"
echo "  SNTNL: /ip4/104.248.166.157/tcp/30333/p2p/$SNTNL_PEER"
echo ""
echo "To view full logs:"
echo "  docker logs -f $NODE_NAME"
echo ""
