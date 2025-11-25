# Boundless Transaction Testing - Quick Start

This directory contains tools for sending transactions and testing the Boundless blockchain locally.

## Files

- **`send_transaction.py`** - Python tool for sending BLS tokens between wallets
- **`test_local_deployment.sh`** - Automated local test node deployment
- **`TRANSACTION_GUIDE.md`** - Complete transaction usage documentation

## Quick Test

### 1. Deploy Local Test Node

```bash
./test_local_deployment.sh
```

This will:
- Generate a test wallet with private key
- Start a local mining node with RPC enabled
- Show wallet address and recovery phrase
- Display testing commands

### 2. Generate Second Wallet

```bash
python3 keygen/boundless_wallet_gen.py generate --show-private -o wallet2.json
```

### 3. Wait for Mining Rewards

Check balance (wait for a few blocks to be mined):
```bash
# Get address from first wallet
ADDR1=$(python3 -c "import json; print(json.load(open('test_wallet_*.json'))['address'])")

# Check balance
python3 send_transaction.py --balance $ADDR1
```

### 4. Send Transaction

```bash
# Extract addresses
ADDR1=$(python3 -c "import json; f=open([f for f in __import__('os').listdir('.') if f.startswith('test_wallet_')][0]); print(json.load(f)['address'])")
ADDR2=$(python3 -c "import json; print(json.load(open('wallet2.json'))['address'])")

# Send 10 BLS from wallet1 to wallet2
python3 send_transaction.py --from test_wallet_*.json --to $ADDR2 --amount 10

# Verify wallet2 received funds
python3 send_transaction.py --balance $ADDR2
```

## Testing Commands

### Check Balance
```bash
python3 send_transaction.py --balance <address>
```

### Send Transaction
```bash
python3 send_transaction.py --from wallet.json --to <address> --amount 50
```

### Check Transaction Status
```bash
python3 send_transaction.py --tx-status <tx_hash>
```

### View Node Logs
```bash
docker logs -f boundless-test-node
```

### View Metrics
```bash
curl http://localhost:9615/metrics
```

### Stop Test Node
```bash
docker stop boundless-test-node
docker rm boundless-test-node
```

## Node Endpoints

When test node is running:

- **RPC:** http://localhost:9933
- **P2P:** localhost:30333
- **Metrics:** http://localhost:9615/metrics

## Production Usage

For production deployments, use:
```bash
./start_boundless_node.sh
```

This provides a more secure deployment without exposing private keys in wallet files.

## Documentation

See **[TRANSACTION_GUIDE.md](TRANSACTION_GUIDE.md)** for:
- Complete API reference
- Advanced usage examples
- Security best practices
- Troubleshooting guide
- RPC method documentation

## Explorer

View transactions on the blockchain explorer:
https://64.225.16.227/

## Support

- **Repository:** https://github.com/codenlighten/boundless_deploy
- **Mainnet Bootnode:** 159.203.114.205:30333
