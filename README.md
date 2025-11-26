# Boundless Node Deployment

**One-command blockchain mining node deployment with automatic wallet generation.**

**Official Repository:** https://github.com/codenlighten/boundless_deploy

## 🚀 SOVRN Genesis Authority - Mainnet Live!

**Genesis Date:** January 1, 2025 00:00:00 UTC  
**Genesis Hash:** `19a89cdb0712ac6fba3445bf686a9fec5322dacaf57351cc9d3d55b87dab8e79`  
**Status:** ✅ **CANONICAL MAINNET LIVE**

The unified Boundless BLS mainnet is now operational with SOVRN as the genesis authority.

## Overview

Deploy Boundless BLS blockchain mining nodes with Lumenbridge's production-ready, schema-first architecture:

- ✅ **JSON Schema validation** for all node configurations
- ✅ **Hardened security** by default (non-root, capability dropping, read-only filesystems)
- ✅ **Hub integration** for centralized monitoring and control
- ✅ **Reproducible deployments** from declarative specs
- ✅ **Multi-node orchestration** with sequential or parallel strategies
- ✅ **Automated Docker installation** on Ubuntu/Debian systems
- ✅ **Automatic wallet generation** with BIP39 24-word recovery phrases
- ✅ **Health monitoring** with built-in health checks

## Network Information

### SOVRN Genesis Authority (Primary)
- **Host:** `159.203.114.205:30333`
- **PeerId:** `12D3KooWQdPKn2koRRkoKZiQz6dBovKgf1ZMAqqFDPjkm7Xrw6Up`
- **Bootnode:** `/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWQdPKn2koRRkoKZiQz6dBovKgf1ZMAqqFDPjkm7Xrw6Up`
- **Role:** Genesis authority and primary bootnode

### SNTNL Authority (Secondary)
- **Host:** `104.248.166.157:30333`
- **PeerId:** `12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`
- **Bootnode:** `/ip4/104.248.166.157/tcp/30333/p2p/12D3KooWHWn3YCYPtd2ewdWehuv61CHWGADMg1fCnY5MHvVrJmJQ`
- **Role:** Secondary bootnode and validator

### Ecosystem
- **Explorer:** https://traceboundless.com
- **Trust:** https://boundlesstrust.org
- **Wallet:** https://e2multipass.com ([GitHub](https://github.com/Saifullah62/E2-Multipass))
- **dApp:** https://swarmproof.com

### Ports
- **P2P:** 30333
- **RPC HTTP:** 9933
- **RPC WebSocket:** 9944
- **API:** 3001

## Features

- ✅ **Mining Nodes** - Earn BLS tokens by contributing to network security
- ✅ **Wallet Generation** - Automatic BIP39 wallet creation with Ed25519 keys
- ✅ **Transaction Sending** - Simple Python tool for peer-to-peer transfers
- ✅ **Balance Checking** - Query any address balance via RPC
- ✅ **Local Testing** - Automated test deployment for development
- ✅ **Schema Validation** - JSON Schema validation for all configurations

## Quick Start (30 seconds)

### Option 1: Simple Setup Script (Recommended)

```bash
# Clone the repository
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy

# Run the setup script
chmod +x setup.sh
./setup.sh YOUR_COINBASE_ADDRESS [node-name] [mining-threads]
```

**Example:**
```bash
./setup.sh bbc7b10e66302282541a8083f3a7243bab9f732c9aed5924df4c2646e98758f2 my-node 2
```

### Option 2: Interactive Setup

```bash
# Clone the repository
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy

# Run the deployment script
./start_boundless_node.sh
```

**Included:** The repository includes `boundless-bls-node-package-complete.tar.gz` (46MB) - the SOVRN Genesis mainnet image. No separate download needed!

Both scripts will:
1. ✅ Auto-install Docker if needed
2. ✅ Generate a new wallet or use your existing address
3. ✅ Download the blockchain node image (46MB)
4. ✅ Start mining to your address

**That's it!** Your node will be mining on the Boundless mainnet.

## Architecture

```
boundless_deploy/
├── schemas/                    # JSON schemas for node validation
│   ├── docker-node.schema.json # Node specification schema
│   └── cluster.schema.json     # Cluster configuration schema
├── nodes/                      # Example node definitions
│   └── boundless-miner-01.json
├── keygen/                     # Wallet generation (from BLS_KeyGen)
│   ├── boundless_wallet_gen.py # Python wallet generator
│   ├── boundless_wallet_gen.rs # Rust wallet generator
│   ├── README.md              # Keygen documentation
│   └── SECURITY.md            # Security best practices
├── controller/                 # Advanced orchestration
│   └── deploy.js              # Node.js deployment controller
├── cluster.json               # Cluster configuration template
├── start_boundless_node.sh    # ⭐ Main deployment script
├── check_system.sh            # System prerequisites checker
└── README.md                  # This file
```

**Wallet Generation Credit:** https://github.com/Saifullah62/BLS_KeyGen

## Installation & Deployment

### Prerequisites

- **Operating System:** Ubuntu 20.04+ or Debian 10+ (other Linux distros may work)
- **RAM:** 2GB minimum, 4GB recommended
- **Disk Space:** 10GB available
- **Network:** Internet connection for initial setup

**Docker will be automatically installed if not present.**

### Step-by-Step Deployment

**1. Clone the repository:**

```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
```

**2. (Optional) Check system prerequisites:**

```bash
./check_system.sh
```

This will verify Docker, Python, and all dependencies.

**3. Deploy your node:**

```bash
./start_boundless_node.sh
```

**4. Follow the prompts:**

```
Wallet Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Do you want to:
  1) Generate a NEW wallet (recommended for new users)
  2) Use an EXISTING address

Enter choice (1 or 2):
```

**Option 1: Generate New Wallet**
- ✅ Creates a secure BIP39 24-word recovery phrase
- ✅ Displays your mining address
- ✅ Saves wallet to timestamped JSON file
- ⚠️ **CRITICAL:** Write down your 24-word phrase!

**Option 2: Use Existing Address**
- ✅ Enter your 64-character hexadecimal address
- ✅ Address format validation
- ✅ Start mining immediately

**5. Configure mining threads:**

```
Enter number of mining threads (default: 2):
```

Recommended: 2-4 threads depending on your CPU.

**6. Node starts automatically!**

The script will:
- Download the blockchain image (46MB, one-time)
- Load the Docker image
- Start your mining node
- Connect to the Boundless mainnet
- Display live logs

## Configuration

### Node Schema (`schemas/docker-node.schema.json`)

Defines the complete specification for a blockchain node:

- **Image management**: Registry, versioning, update policies
- **Resources**: CPU/memory limits and reservations  
- **Security**: User/group, capabilities, seccomp, AppArmor
- **Networking**: Networks, aliases, egress filtering
- **Hub integration**: Connection, auth (mTLS/token), heartbeat
- **Blockchain config**: Mining, P2P/RPC ports, bootnodes, storage
- **Observability**: Logging, metrics, healthchecks

### Cluster Schema (`schemas/cluster.schema.json`)

Orchestrates multiple nodes as a fleet:

- **Hub configuration**: Central control plane
- **Secrets management**: Env, Vault, K8s, Docker secrets
- **Deployment strategy**: Sequential or parallel
- **Monitoring**: Prometheus, Grafana integration

## Node Definitions

### Example: Mining Node

`nodes/boundless-miner-01.json`:

```json
{
  "id": "boundless-miner-01",
  "role": "blockchain-miner",
  "image": {
    "repository": "boundless-bls-platform-blockchain",
    "tag": "latest",
    "updatePolicy": {
      "strategy": "fixed"
    }
  },
  "blockchainConfig": {
    "mining": {
      "enabled": true,
      "coinbase": "YOUR_ADDRESS",
      "threads": 2
    },
    "network": {
      "p2pPort": 30333,
      "rpcPort": 9933,
      "bootnodes": [
        "/ip4/159.203.114.205/tcp/30333/p2p/12D3KooW..."
      ]
    }
  },
  "security": {
    "runAsUser": 1000,
    "readOnlyRootFilesystem": false,
    "capabilities": {
      "drop": ["ALL"]
    }
  },
  "hubConnection": {
    "host": "hub.lumenbridge.internal",
    "port": 443,
    "auth": {
      "type": "token",
      "tokenEnvVar": "HUB_AUTH_TOKEN"
    }
  }
}
```

## Security Hardening

All nodes are deployed with:

- **Non-root user** (UID 1000)
- **Dropped capabilities** (ALL by default)
- **No privilege escalation**
- **Resource limits** enforced
- **Network policies** (optional egress filtering)
- **Read-only root filesystem** (where applicable)

## Hub Integration

Nodes connect to the Lumenbridge hub for:

- **Registration** on startup
- **Heartbeat monitoring** (configurable interval)
- **Metrics collection** (Prometheus endpoints)
- **Centralized logging** (json-file, syslog, fluentd)
- **Remote management** and updates

## Deployment Strategies

### Fixed Image

```json
"updatePolicy": {
  "strategy": "fixed",
  "autoRollout": false
}
```

Node stays on specified tag. Manual updates only.

### Track Latest

```json
"updatePolicy": {
  "strategy": "track-latest",
  "autoRollout": true
}
```

Hub automatically pulls and deploys latest image.

### Semver Range

```json
"updatePolicy": {
  "strategy": "semver-range",
  "semverRange": "^1.2.0",
  "autoRollout": true
}
```

Hub deploys any 1.x.x version >= 1.2.0.

## Monitoring

### Metrics

Each node exposes Prometheus metrics:

```
http://localhost:9615/metrics
```

### Logs

View real-time logs:

```bash
docker logs -f boundless-miner-01
```

### Health Checks

Nodes report health via RPC endpoint:

```bash
curl http://localhost:9933/health
```

## Useful Commands

### Cluster Operations

```bash
# Deploy cluster
node controller/deploy.js

# Validate configurations
node controller/validate.js

# Check cluster status
node controller/status.js
```

### Node Operations

```bash
# View logs
docker logs -f boundless-miner-01

# Restart node
docker restart boundless-miner-01

# Execute shell
docker exec -it boundless-miner-01 /bin/sh

# View resource usage
docker stats boundless-miner-01

# Inspect configuration
docker inspect boundless-miner-01
```

### Network Operations

```bash
# Check P2P connections
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_peers"}' \
  http://localhost:9933

# Check mining status
curl http://localhost:9933/mining/status
```

## Blockchain Network

- **Mainnet Bootnode**: `/ip4/159.203.114.205/tcp/30333/p2p/12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE`
- **Explorer**: https://64.225.16.227/
- **P2P Port**: 30333
- **RPC Port**: 9933

## Adding More Nodes

1. **Create node definition**: `nodes/boundless-miner-02.json`
2. **Update cluster**: Add to `cluster.json` nodes array
3. **Deploy**: `node controller/deploy.js`

The controller handles:
- Network creation
- Volume management
- Port allocation
- Hub registration
- Metric scraping

## Extending for Other Roles

The schema supports multiple node roles:

- `blockchain-miner`: Mining nodes (current)
- `terminal-agent`: Interactive terminals
- `schema-registry`: Schema validation services
- `api-gateway`: API proxies and routers
- `custom-service`: Your own services

Add role-specific config sections as needed.

## Lumenbridge Integration

This deployment integrates with:

- **Hub**: `hub.lumenbridge.internal:443`
- **Auth**: Token or mTLS
- **Heartbeat**: 60s interval
- **Metrics**: Scraped by Prometheus
- **Logs**: Centralized via hub

## Sending Transactions

Send BLS tokens between wallets using the included transaction tool.

### Quick Transaction Example

```bash
# Generate two wallets for testing
python3 keygen/boundless_wallet_gen.py generate --show-private -o alice.json
python3 keygen/boundless_wallet_gen.py generate --show-private -o bob.json

# Extract Bob's address
BOB_ADDRESS=$(python3 -c "import json; print(json.load(open('bob.json'))['address'])")

# Send 100 BLS from Alice to Bob
python3 send_transaction.py --from alice.json --to $BOB_ADDRESS --amount 100

# Check Bob's balance
python3 send_transaction.py --balance $BOB_ADDRESS
```

### Transaction Commands

**Send Transaction:**
```bash
python3 send_transaction.py --from wallet.json --to <address> --amount 50
```

**Check Balance:**
```bash
python3 send_transaction.py --balance <address>
```

**Transaction Status:**
```bash
python3 send_transaction.py --tx-status <tx_hash>
```

**Send from Mnemonic:**
```bash
python3 send_transaction.py --mnemonic "word1 word2 ..." --to <address> --amount 25
```

**Full Documentation:** See [TRANSACTION_GUIDE.md](TRANSACTION_GUIDE.md) for complete usage instructions.

## Local Testing

Deploy a local test node to experiment with transactions and metrics:

```bash
./test_local_deployment.sh
```

This will:
- Generate a test wallet with private key
- Start a local mining node
- Enable RPC on `localhost:9933`
- Enable metrics on `localhost:9615`
- Show useful testing commands

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs boundless-miner-01

# Check events
docker events --filter container=boundless-miner-01

# Verify image
docker images | grep boundless
```

### Network issues

```bash
# Inspect network
docker network inspect lumen-blockchain-net

# Check connectivity
docker exec boundless-miner-01 ping -c 3 159.203.114.205
```

### Hub connection failures

```bash
# Verify hub is reachable
curl -k https://hub.lumenbridge.internal:443/health

# Check auth token
docker exec boundless-miner-01 env | grep HUB_AUTH_TOKEN
```

## License

MIT License

**Attribution:**
- Wallet Generation: https://github.com/Saifullah62/BLS_KeyGen
- Deployment System: https://github.com/codenlighten/boundless_deploy

## Documentation

- **[README.md](README.md)** - Main documentation (this file)
- **[TRANSACTION_GUIDE.md](TRANSACTION_GUIDE.md)** - Complete guide for sending transactions
- **[WALLET_INTEGRATION.md](WALLET_INTEGRATION.md)** - Wallet generation details
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Technical implementation
- **[ACTIVE_NODES.md](ACTIVE_NODES.md)** - Production deployment tracker
- **[keygen/README.md](keygen/README.md)** - Wallet generator documentation
- **[keygen/SECURITY.md](keygen/SECURITY.md)** - Security best practices

## Quick Links

- **Repository:** https://github.com/codenlighten/boundless_deploy
- **Explorer:** https://traceboundless.com
- **Boundless Trust:** https://boundlesstrust.org
- **E² Multipass Wallet:** https://e2multipass.com
- **SwarmProof dApp:** https://swarmproof.com
- **Quick Start Resources:** http://159.203.114.205/node/
- **Primary Node (SNTNL):** 104.248.166.157:30333
- **Bootnode:** 159.203.114.205:30333
- **RPC Endpoint:** localhost:9933 (local node)

---

**Last Updated:** November 25, 2025
**Version:** 1.0.0
**Status:** ✅ Production Ready

🚀 **Start mining on Boundless mainnet in 30 seconds!**
