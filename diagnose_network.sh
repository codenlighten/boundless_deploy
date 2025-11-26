#!/bin/bash

echo "=========================================="
echo "Boundless Network Connectivity Diagnosis"
echo "=========================================="
echo ""

NODE_NAME="${1:-boundless-node}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Container Network Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker ps --filter "name=$NODE_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Testing Connectivity to SOVRN (159.203.114.205:30333)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

timeout 5 nc -zv 159.203.114.205 30333 2>&1 || echo "⚠️  Cannot reach SOVRN bootnode"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Testing Connectivity to SNTNL (104.248.166.157:30333)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

timeout 5 nc -zv 104.248.166.157 30333 2>&1 || echo "⚠️  Cannot reach SNTNL bootnode"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking if Port 30333 is Listening Inside Container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker exec $NODE_NAME netstat -tuln 2>/dev/null | grep 30333 || \
  docker exec $NODE_NAME ss -tuln 2>/dev/null | grep 30333 || \
  echo "⚠️  Cannot check listening ports (netstat/ss not available)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Firewall Status on Host"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v ufw &> /dev/null; then
    echo "UFW Status:"
    sudo ufw status | grep -E "30333|Status:" || echo "Port 30333 not explicitly allowed"
elif command -v iptables &> /dev/null; then
    echo "IPTables rules for port 30333:"
    sudo iptables -L -n | grep 30333 || echo "No specific iptables rules for 30333"
else
    echo "⚠️  Cannot check firewall (ufw/iptables not found)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Docker Network Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker inspect $NODE_NAME --format '{{.HostConfig.NetworkMode}}' 2>/dev/null || echo "⚠️  Cannot inspect container"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Recent Node Logs (Network/Discovery Messages)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker logs $NODE_NAME 2>&1 | tail -50 | grep -iE "network|discover|dial|libp2p|bootnode|peer" || \
  echo "No network-related messages found in recent logs"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Checking Node's Own Peer ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker logs $NODE_NAME 2>&1 | grep -i "local peer id\|peer id:" | tail -1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary & Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If connectivity tests fail:"
echo "  1. Check DigitalOcean firewall rules (allow TCP 30333)"
echo "  2. Verify Docker is using host network or proper port mapping"
echo "  3. Check if VPS provider blocks P2P ports"
echo ""
echo "If connectivity tests pass but still 0 peers:"
echo "  1. Check node logs for bootnode connection errors"
echo "  2. Verify genesis hash matches SOVRN (should be in logs)"
echo "  3. Try restarting container to retry bootnode discovery"
echo ""
