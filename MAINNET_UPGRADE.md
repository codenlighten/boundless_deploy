# Boundless BLS Mainnet Upgrade Guide

## SOVRN Genesis Authority Launch

**Date:** November 25, 2025  
**Genesis Timestamp:** Jan 1, 2025 00:00:00 UTC (1735689600)

The unified Boundless BLS mainnet is now live with **SOVRN** as the genesis authority. Any node joining with the proper bootnodes will automatically sync from the canonical chain.

---

## Critical Information

### Genesis Configuration
- **Genesis Hash:** `19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79`
- **Genesis Timestamp:** `1735689600` (Jan 1, 2025 00:00:00 UTC)

### Network Authorities

#### SOVRN Genesis Authority (Primary)
- **IP Address:** 159.203.114.205
- **Peer ID:** `12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8`
- **Bootnode:** `/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8`

#### SNTNL Authority (Secondary)
- **IP Address:** 104.248.166.157
- **Peer ID:** `12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`
- **Bootnode:** `/ip4/104.248.166.157/tcp/30333/p2p/12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`

### Ecosystem Resources
- **Explorer:** https://traceboundless.com
- **Trust Platform:** https://boundlesstrust.org
- **Wallet:** https://e2multipass.com ([GitHub](https://github.com/Saifullah62/E2-Multipass))
- **dApp:** https://swarmproof.com

---

## Upgrade Instructions

### For Existing Node at 137.184.40.224

⚠️ **WARNING:** This process will delete all existing blockchain data and resync from SOVRN Genesis Authority.

#### Step 1: Stop and Clean Existing Node

```bash
# Stop existing container
docker stop boundless-node 2>/dev/null
docker rm boundless-node 2>/dev/null

# Clear all blockchain data
rm -rf /mnt/boundless_data/* /data/*

# Recreate data directory with proper permissions
mkdir -p /mnt/boundless_data
chmod 777 /mnt/boundless_data
```

#### Step 2: Get Official Docker Image

**Option A: Download from SOVRN (Recommended)**
```bash
# Download genesis image
scp root@159.203.114.205:/tmp/boundless-mainnet-genesis.tar.gz /tmp/

# Load image (handles gzip compression)
gunzip -c /tmp/boundless-mainnet-genesis.tar.gz | docker load
```

**Option B: Use Updated Deployment Script**
```bash
# Clone/update deployment repo
cd /root
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy

# Run updated script (automatically downloads genesis image)
./start_boundless_node.sh
```

**Option C: Build from Source**
```bash
cd /opt/boundless
git pull origin main
docker build -t boundless-mainnet:genesis .
```

#### Step 3: Start Mainnet Node

The updated `start_boundless_node.sh` script now automatically:
- Downloads the SOVRN genesis image
- Configures proper bootnodes
- Sets up health checks
- Connects to the canonical mainnet chain

```bash
./start_boundless_node.sh
```

When prompted:
1. Choose option **2** (Use existing address) if you have a wallet
2. Or option **1** to generate a new mainnet wallet
3. Enter your mining threads (default: 2)

---

## Manual Configuration (Advanced)

If you prefer manual setup, create a configuration file:

### Create Config File

```bash
mkdir -p /opt/boundless
cat > /opt/boundless/config.toml << 'EOF'
# Boundless BLS Mainnet Node Configuration
# Connects to SOVRN Genesis Authority

[network]
listen_addr = "/ip4/0.0.0.0/tcp/30333"
bootnodes = [
    "/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8",
    "/ip4/104.248.166.157/tcp/30333/p2p/12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ"
]

[consensus]
target_block_time_secs = 300
difficulty_adjustment_interval = 1008
max_adjustment_factor = 4

[storage]
database_path = "/data/db"
cache_size_mb = 2048

[rpc]
http_addr = "0.0.0.0:9933"
ws_addr = "0.0.0.0:9944"
cors_allowed_origins = ["*"]

[mempool]
max_transactions = 10000
max_tx_size = 100000
min_fee_per_byte = 1

[mining]
enabled = true
threads = 2
coinbase_address = "YOUR_WALLET_ADDRESS_HERE"

[security]
enable_tls = false
max_request_size_bytes = 1000000
rate_limit_per_minute = 60
require_authentication = false

[operational]
enable_metrics = false
metrics_addr = "127.0.0.1:9615"
enable_health_check = true
shutdown_timeout_secs = 10
log_level = "info"
structured_logging = false
checkpoint_interval = 1000
EOF
```

### Start with Config File

```bash
docker run -d --name boundless-node \
  --restart unless-stopped \
  -p 9933:9933 -p 9944:9944 -p 30333:30333 -p 3001:3001 \
  -v /mnt/boundless_data:/data \
  -v /opt/boundless/config.toml:/config/config.toml:ro \
  -e RUST_LOG=info \
  --health-cmd="curl -sf -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}' http://localhost:9933/ || exit 1" \
  --health-interval=30s --health-timeout=10s --health-retries=5 --health-start-period=60s \
  boundless-mainnet:genesis \
  --base-path /data --config /config/config.toml
```

---

## Verification Commands

### Check Container Status
```bash
docker ps | grep boundless
```

### Check Health Status
```bash
docker inspect --format="{{.State.Health.Status}}" boundless-node
```

Expected: `healthy` (may show `starting` for first 60 seconds)

### Check Block Height
```bash
docker exec boundless-node curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"chain_getBlockHeight","params":[],"id":1}' \
  http://localhost:9933/
```

### Check Network Health and Peers
```bash
docker exec boundless-node curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
  http://localhost:9933/
```

### View Live Logs
```bash
docker logs -f boundless-node
```

Look for:
- ✅ Connection to SOVRN bootnode
- ✅ Connection to SNTNL bootnode
- ✅ Syncing blocks from genesis
- ✅ Mining enabled (if configured)

---

## Port Configuration

The mainnet node exposes these ports:

| Port | Protocol | Purpose |
|------|----------|---------|
| 30333 | TCP | Peer-to-peer networking |
| 9933 | HTTP | JSON-RPC API |
| 9944 | WebSocket | WebSocket RPC API |
| 3001 | HTTP | Additional API endpoint |

Ensure these ports are open in your firewall:
```bash
# UFW example
sudo ufw allow 30333/tcp
sudo ufw allow 9933/tcp
sudo ufw allow 9944/tcp
sudo ufw allow 3001/tcp
```

---

## Troubleshooting

### Node Not Syncing

**Check peer connections:**
```bash
docker logs boundless-node 2>&1 | grep -i "peer\|connection"
```

**Verify bootnodes are reachable:**
```bash
telnet 159.203.114.205 30333
telnet 104.248.166.157 30333
```

### Health Check Failing

**Check RPC endpoint:**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
  http://localhost:9933/
```

### Stuck on Old Chain

If your node doesn't switch to the new genesis chain:
```bash
# Complete cleanup and restart
docker stop boundless-node
docker rm boundless-node
rm -rf /mnt/boundless_data/*
docker volume prune -f

# Re-run deployment script
./start_boundless_node.sh
```

---

## Key Changes from Previous Version

### What's New
1. ✅ **SOVRN Genesis Authority** - New canonical mainnet with proper genesis
2. ✅ **New Genesis Hash** - `19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79`
3. ✅ **Updated Peer Discovery** - New peer discovery logic
4. ✅ **Health Checks** - Built-in container health monitoring
5. ✅ **WebSocket Support** - Port 9944 for WS RPC
6. ✅ **Proper Bootnodes** - Both SOVRN and SNTNL configured
7. ✅ **E² Multipass Wallet** - New wallet interface available

### Breaking Changes
- ⚠️ **Old blockchain data incompatible** - Must resync from genesis
- ⚠️ **New genesis timestamp** - Jan 1, 2025 (not earlier dates)
- ⚠️ **Old peer IDs obsolete** - Must use new SOVRN/SNTNL peer IDs
- ⚠️ **Image location changed** - Now at `/tmp/boundless-mainnet-genesis.tar.gz`

---

## For New Node Operators

If you're setting up a Boundless node for the first time:

1. **Clone the deployment repository:**
   ```bash
   git clone https://github.com/codenlighten/boundless_deploy.git
   cd boundless_deploy
   ```

2. **Run the start script:**
   ```bash
   ./start_boundless_node.sh
   ```

3. **Generate a new wallet** when prompted (option 1)

4. **Save your 24-word recovery phrase** securely

5. **Monitor your node:**
   ```bash
   docker logs -f boundless-node
   ```

That's it! Your node will automatically connect to the mainnet and start syncing.

---

## Support

- **Documentation:** https://github.com/codenlighten/boundless_deploy
- **Explorer:** https://traceboundless.com
- **Wallet:** https://e2multipass.com

---

**The unified Boundless BLS mainnet is now live. Welcome to the network! 🚀**
