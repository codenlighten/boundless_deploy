# Boundless Network Status

**Last Updated:** November 25, 2025

---

## 🌐 Mainnet Status

| Metric | Value |
|--------|-------|
| **Block Height** | 1,008+ (and growing) |
| **Total Supply** | 50,450+ BLS |
| **Difficulty** | ~486M (adaptive) |
| **Hash Rate** | ~3.7 MH/s |
| **Block Time** | ~4-5 minutes average |
| **Status** | ✅ **LIVE & MINING** |

---

## 🖥️ Primary Mainnet Nodes

### SNTNL (Sentinel) — Primary Download
**Recommended for all participants**

- **PeerId:** `12D3KooWCv2ETgGZx5i8rzebmAHuu57iDnqFxGa5ZR8D29CNrpXR`
- **Host:** `104.248.166.157`
- **Mining:** Active (~1–2.5 MH/s)
- **Coinbase:** `3ef54ef75ba8d594572598d7505e001349a58061aa768d67ec233581d5c59fe6`
- **Ports:**
  - P2P: `30333`
  - RPC: `9933`
  - WS: `9944`
  - HTTP: `3001`

### Bootnode (Discovery)
- **PeerId:** `12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE`
- **Host:** `159.203.114.205`
- **Port:** `30333`
- **Multiaddr:** `/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE`

### SOVRN (Sovereign) — Backbone Node
- **Purpose:** Internal stability and operations
- **Status:** Active
- **Use:** Optional / backbone support

---

## 📦 Quick Start Resources

### One-Line Installation
```bash
curl -fsSL http://159.203.114.205/node/setup.sh | sudo bash
```

### Manual Download
```bash
# Download Docker image (45-46 MB)
curl -O http://159.203.114.205/node/blockchain-image.tar.gz

# Load image
docker load < blockchain-image.tar.gz

# Run node
docker run -d \
  --name boundless-node \
  --restart unless-stopped \
  -p 30333:30333 \
  -p 9933:9933 \
  -v boundless-data:/data \
  boundless-bls-platform-blockchain:latest \
  --base-path /data \
  --mining \
  --coinbase YOUR_ADDRESS_HERE \
  --mining-threads 2 \
  --rpc-host 0.0.0.0

# View logs
docker logs -f boundless-node
```

### Resource Links
- **Quick Start Page:** http://159.203.114.205/node/
- **Setup Script:** http://159.203.114.205/node/setup.sh
- **Config Template:** http://159.203.114.205/node/config.toml
- **Docker Image:** http://159.203.114.205/node/blockchain-image.tar.gz
- **Documentation:** http://159.203.114.205/node/README.md

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
- **Purpose:** Wallet and identity management

### SwarmProof dApp
- **Website:** https://swarmproof.com
- **Email:** hive@proofswarm.com
- **Purpose:** Decentralized application

---

## 🚀 Getting Started

### 1. Using This Repository
```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
./start_boundless_node.sh
```

### 2. Using Official Setup Script
```bash
curl -fsSL http://159.203.114.205/node/setup.sh | sudo bash
```

### 3. Manual Docker Deployment
Follow the manual download steps above.

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

### Current Metrics
- **Difficulty:** ~486M (auto-adjusts)
- **Network Hash Rate:** ~3.7 MH/s
- **Block Reward:** 50 BLS
- **Target Block Time:** ~5 minutes

### Start Mining
1. Generate wallet: `./start_boundless_node.sh` (option 1)
2. Node automatically mines to your address
3. Rewards paid at each block found
4. Track on explorer: https://traceboundless.com

---

## 📈 Recent Milestones

- ✅ **Block 1000+** reached
- ✅ **50,000+ BLS** total supply
- ✅ **Multiple active miners** on network
- ✅ **Stable ~5 min** block times
- ✅ **Production deployment** validated (137.184.40.224)
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
