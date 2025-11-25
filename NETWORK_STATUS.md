# Boundless Network Status

**Last Updated:** November 25, 2025

---

## 🚀 SOVRN Genesis Authority Launch

**THE UNIFIED BOUNDLESS BLS MAINNET IS NOW LIVE!**

| Metric | Value |
|--------|-------|
| **Genesis Date** | January 1, 2025 00:00:00 UTC |
| **Genesis Hash** | `19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79` |
| **Genesis Timestamp** | `1735689600` |
| **Genesis Authority** | SOVRN (159.203.114.205) |
| **Block Time Target** | 5 minutes (300 seconds) |
| **Block Reward** | 50 BLS |
| **Status** | ✅ **LIVE & CANONICAL** |

---

## 🖥️ Network Authorities

### SOVRN Genesis Authority (Primary) 🌟
**The canonical mainnet starts here**

- **PeerId:** `12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8`
- **Host:** `159.203.114.205`
- **Role:** Genesis authority and primary bootnode
- **Bootnode:** `/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWN5ZJAXXZviBDteowfWRsxXuDUMp6YuEzcRDoSuwMSod8`
- **Status:** ✅ Active - **GENESIS AUTHORITY**
- **Ports:**
  - P2P: `30333`
  - RPC: `9933`
  - WS: `9944`
  - HTTP: `3001`

### SNTNL (Sentinel) Authority
**Secondary validator and bootnode**

- **PeerId:** `12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`
- **Host:** `104.248.166.157`
- **Role:** Secondary bootnode and validator
- **Bootnode:** `/ip4/104.248.166.157/tcp/30333/p2p/12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`
- **Status:** ✅ Active
- **Ports:**
  - P2P: `30333`
  - RPC: `9933`
  - WS: `9944`
  - HTTP: `3001`

---

## 📦 Quick Start Resources

### ⚠️ IMPORTANT: Mainnet Upgrade Required

**All existing nodes must upgrade to the new SOVRN Genesis mainnet.**

See **[MAINNET_UPGRADE.md](MAINNET_UPGRADE.md)** for complete upgrade instructions.

### One-Line Installation (New Nodes)
```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
./start_boundless_node.sh
```

**Genesis Image Included:** The repository includes the complete SOVRN genesis image (46MB) - no separate download required!

The updated script automatically:
- Uses bundled SOVRN genesis image
- Configures proper bootnodes
- Sets up health monitoring
- Connects to canonical mainnet

### Manual Download (Advanced)
```bash
# Download SOVRN Genesis image
scp root@159.203.114.205:/tmp/boundless-mainnet-genesis.tar.gz /tmp/

# Load image (handles gzip)
gunzip -c /tmp/boundless-mainnet-genesis.tar.gz | docker load

# Or use direct docker load
docker load < /tmp/boundless-mainnet-genesis.tar.gz
```

---

## 🔗 Ecosystem Sites

### Boundless Trust
- **Website:** https://boundlesstrust.org
- **Email:** verify@boundlesstrust.org
- **Purpose:** Trust and verification services

### TraceBoundless Explorer
- **Website:** https://traceboundless.com
- **Email:** telemetry@traceboundless.com
- **Purpose:** Blockchain explorer and network telemetry

### E² Multipass Wallet & Identity
- **Website:** https://e2multipass.com
- **Email:** access@e2multipass.com
- **GitHub:** https://github.com/Saifullah62/E2-Multipass
- **Purpose:** Wallet and identity management

### SwarmProof dApp
- **Website:** https://swarmproof.com
- **Email:** hive@proofswarm.com
- **Purpose:** Decentralized application

---

## 🚀 Getting Started

### 1. Using This Repository (Recommended)
```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
./start_boundless_node.sh
```

**The script will:**
- Download the SOVRN genesis image
- Generate a secure wallet (or use existing)
- Configure proper bootnodes automatically
- Set up health monitoring
- Start mining on the canonical mainnet

### 2. Upgrading Existing Node
See **[MAINNET_UPGRADE.md](MAINNET_UPGRADE.md)** for complete instructions.

Quick upgrade:
```bash
cd boundless_deploy
git pull origin main
./start_boundless_node.sh
```

Choose option **2** (Start fresh) when prompted.

---

## 🔧 Verification Commands

### Check Node Health
```bash
docker inspect --format="{{.State.Health.Status}}" boundless-node
```

### Check Block Height
```bash
docker exec boundless-node curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"chain_getBlockHeight","params":[],"id":1}' \
  http://localhost:9933/
```

### Check Peer Connections
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
- ✅ `Connected to SOVRN` or `Connected to bootnode`
- ✅ `Syncing blocks` or `Block synced`
- ✅ `Mined block` (if mining enabled)

---

## 📊 Network Ports

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| 30333 | TCP | P2P Network | ✅ Yes |
| 9933 | TCP | RPC (JSON) | Optional |
| 9944 | TCP | WebSocket | Optional |
| 3001 | TCP | HTTP API | Optional |

---

## 🔐 Mining Information

### Network Parameters
- **Difficulty Adjustment:** Every 1008 blocks (~3.5 days)
- **Max Adjustment Factor:** 4x per period
- **Block Reward:** 50 BLS
- **Target Block Time:** 5 minutes (300 seconds)
- **Consensus:** Proof-of-Work with Ed25519 BLS signatures

### Start Mining
1. Run deployment script: `./start_boundless_node.sh`
2. Choose option 1 to generate new wallet
3. Save your 24-word recovery phrase securely
4. Node automatically mines to your address
5. Rewards paid immediately when block found
6. Track your blocks on: https://traceboundless.com

---

## 📈 Recent Milestones

- ✅ **November 25, 2025:** SOVRN Genesis Authority launched
- ✅ **New peer discovery logic** implemented
- ✅ **E² Multipass wallet** released (open source)
- ✅ **Health check monitoring** integrated
- ✅ **Unified canonical mainnet** established
- ✅ **Genesis hash published:** `19a89cdb0712ac6fba3445bf686a9fec...`
- ✅ **Ecosystem sites** live and operational

---

## 🛠️ Troubleshooting

### Node Won't Connect
```bash
# Check if port 30333 is open
sudo ufw allow 30333/tcp

# Verify bootnode is reachable
ping 159.203.114.205

# Check logs
docker logs -f boundless-node
```

### Not Mining Blocks
- Verify mining address is correct (64 hex characters)
- Check mining threads are set (default: 2)
- Ensure node is synced with network
- View logs for mining status

### Need Help?
- Check explorer: https://traceboundless.com
- Review documentation: http://159.203.114.205/node/README.md
- Contact: verify@boundlesstrust.org

---

## 📝 Additional Resources

- **Deployment Repository:** https://github.com/codenlighten/boundless_deploy
- **Transaction Guide:** See TRANSACTION_GUIDE.md
- **Wallet Integration:** See WALLET_INTEGRATION.md
- **Testing Guide:** See TESTING_GUIDE.md
- **Active Nodes:** See ACTIVE_NODES.md

---

**Network Status:** ✅ **OPERATIONAL**  
**Last Block Update:** Block 1008  
**Maintained By:** Boundless Trust  
**Support:** verify@boundlesstrust.org
