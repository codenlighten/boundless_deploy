# Boundless Blockchain - Transaction Guide

Complete guide for sending and receiving BLS tokens between wallets.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Sending Transactions](#sending-transactions)
4. [Checking Balances](#checking-balances)
5. [Transaction Status](#transaction-status)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)
8. [API Reference](#api-reference)

---

## Prerequisites

### 1. Install Dependencies

```bash
pip3 install requests PyNaCl pycryptodome mnemonic
```

### 2. Running Node

You need access to a running Boundless node with RPC enabled:

**Local Node:**
```bash
# Start local node (see start_boundless_node.sh)
docker run -d \
  --name boundless-node \
  -p 30333:30333 \
  -p 9933:9933 \
  boundless-bls-platform-blockchain:latest \
  --rpc-host 0.0.0.0
```

**Remote Node:**
- Default RPC: `http://localhost:9933`
- You can connect to any node with RPC enabled

### 3. Wallet with Private Key

To send transactions, you need a wallet file that includes the `private_key`:

```bash
# Generate wallet WITH private key
python3 keygen/boundless_wallet_gen.py generate --show-private -o my_wallet.json
```

⚠️ **SECURITY WARNING:** Only generate wallets with `--show-private` on secure, offline machines. Store wallet files securely!

---

## Quick Start

### 1. Check Your Balance

```bash
python3 send_transaction.py --balance YOUR_ADDRESS
```

Example:
```bash
python3 send_transaction.py --balance 7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
```

### 2. Send a Transaction

```bash
python3 send_transaction.py \
  --from sender_wallet.json \
  --to RECIPIENT_ADDRESS \
  --amount 100
```

### 3. Check Transaction Status

```bash
python3 send_transaction.py --tx-status TRANSACTION_HASH
```

---

## Sending Transactions

### Method 1: From Wallet File (Recommended)

```bash
python3 send_transaction.py \
  --from my_wallet.json \
  --to 8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5 \
  --amount 50.5
```

**Output:**
```
💸 Boundless Transaction Sender
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Loading wallet from: my_wallet.json
✓ Wallet loaded: 7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
✓ Connected to node (block #12345)

💰 Balance: 1000.0 BLS
📊 Nonce: 5

📤 Preparing transaction:
   From:   7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
   To:     8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
   Amount: 50.5 BLS
   Fee:    0.0 BLS
   Nonce:  5

Send transaction? (yes/no): yes

✓ Transaction signed

✅ Transaction sent!
   Hash: 0xa1b2c3d4e5f6...
   
   View on explorer: https://64.225.16.227/tx/0xa1b2c3d4e5f6...
```

### Method 2: From Mnemonic

```bash
python3 send_transaction.py \
  --mnemonic "word1 word2 word3 ... word24" \
  --to RECIPIENT_ADDRESS \
  --amount 25
```

**With Passphrase:**
```bash
python3 send_transaction.py \
  --mnemonic "word1 word2 word3 ... word24" \
  --passphrase "my secret phrase" \
  --to RECIPIENT_ADDRESS \
  --amount 25
```

### Skip Confirmation

Add `-y` flag to skip confirmation prompt:

```bash
python3 send_transaction.py --from wallet.json --to ADDRESS --amount 10 -y
```

### Specify Transaction Fee

```bash
python3 send_transaction.py \
  --from wallet.json \
  --to ADDRESS \
  --amount 100 \
  --fee 0.01
```

### Connect to Remote Node

```bash
python3 send_transaction.py \
  --rpc-url http://159.203.114.205:9933 \
  --from wallet.json \
  --to ADDRESS \
  --amount 50
```

---

## Checking Balances

### Check Any Address

```bash
python3 send_transaction.py --balance ADDRESS
```

**Output:**
```
💰 Boundless Balance Checker
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📬 Address: 7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
💰 Balance: 1500.5 BLS
📊 Nonce:   12
```

### Check Remote Node

```bash
python3 send_transaction.py \
  --rpc-url http://159.203.114.205:9933 \
  --balance ADDRESS
```

---

## Transaction Status

### Check Transaction

```bash
python3 send_transaction.py --tx-status TRANSACTION_HASH
```

**Output:**
```
📋 Boundless Transaction Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Transaction: 0xa1b2c3d4e5f6...

   Status: confirmed
   Block:  #12346
   From:   7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
   To:     8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
   Amount: 50.5 BLS
   Fee:    0.0 BLS
```

---

## Examples

### Example 1: Local Transfer Between Two Wallets

```bash
# Generate two wallets
python3 keygen/boundless_wallet_gen.py generate --show-private -o alice.json
python3 keygen/boundless_wallet_gen.py generate --show-private -o bob.json

# Extract Bob's address
BOB_ADDRESS=$(python3 -c "import json; print(json.load(open('bob.json'))['address'])")

# Send from Alice to Bob
python3 send_transaction.py --from alice.json --to $BOB_ADDRESS --amount 100

# Check Bob's balance
python3 send_transaction.py --balance $BOB_ADDRESS
```

### Example 2: Send to Multiple Recipients (Script)

```bash
#!/bin/bash

SENDER_WALLET="my_wallet.json"
RECIPIENTS=(
  "7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01"
  "8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5"
  "9f3e2c4a6b8d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5"
)
AMOUNT=10

for recipient in "${RECIPIENTS[@]}"; do
  echo "Sending $AMOUNT BLS to $recipient..."
  python3 send_transaction.py \
    --from "$SENDER_WALLET" \
    --to "$recipient" \
    --amount "$AMOUNT" \
    -y
  sleep 2
done
```

### Example 3: Monitor Transaction Until Confirmed

```bash
#!/bin/bash

TX_HASH="$1"

echo "Monitoring transaction: $TX_HASH"
while true; do
  STATUS=$(python3 send_transaction.py --tx-status "$TX_HASH" 2>&1 | grep "Status:")
  echo "$STATUS"
  
  if echo "$STATUS" | grep -q "confirmed"; then
    echo "✅ Transaction confirmed!"
    break
  fi
  
  sleep 5
done
```

### Example 4: Automated Mining Rewards Distribution

```bash
#!/bin/bash

# Mining pool payout script
POOL_WALLET="pool_wallet.json"
PAYOUTS_FILE="payouts.json"

# Read payouts from JSON file
# Format: [{"address": "0xabc...", "amount": 50.5}, ...]

while IFS= read -r line; do
  address=$(echo "$line" | jq -r '.address')
  amount=$(echo "$line" | jq -r '.amount')
  
  echo "Paying $amount BLS to $address..."
  python3 send_transaction.py \
    --from "$POOL_WALLET" \
    --to "$address" \
    --amount "$amount" \
    -y
  
  sleep 1
done < <(jq -c '.[]' "$PAYOUTS_FILE")
```

---

## Troubleshooting

### Cannot Connect to Node

**Error:**
```
❌ Cannot connect to node at http://localhost:9933. Is it running?
```

**Solutions:**
1. Check if node is running: `docker ps | grep boundless`
2. Start node: `docker start boundless-node`
3. Check RPC is enabled: Node must be started with `--rpc-host 0.0.0.0`
4. Verify port mapping: `docker port boundless-node`
5. Try different RPC URL: `--rpc-url http://127.0.0.1:9933`

### Private Key Not Found

**Error:**
```
❌ Wallet file does not contain private_key
```

**Solution:**
Regenerate wallet with `--show-private` flag:
```bash
python3 keygen/boundless_wallet_gen.py generate --show-private -o wallet.json
```

Or restore from mnemonic:
```bash
python3 keygen/boundless_wallet_gen.py restore \
  --mnemonic "your 24 words here" \
  --show-private \
  -o wallet.json
```

### Insufficient Balance

**Error:**
```
❌ Failed to send transaction: Insufficient balance
```

**Solutions:**
1. Check balance: `python3 send_transaction.py --balance YOUR_ADDRESS`
2. Mine blocks to earn rewards (if mining node)
3. Receive funds from another wallet
4. Reduce transaction amount

### Invalid Address Format

**Error:**
```
❌ Invalid address format
```

**Solution:**
Boundless addresses are 64 hexadecimal characters:
```
Valid:   7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01
Invalid: 0x7adb34d0... (no 0x prefix)
Invalid: 7adb34d0fa  (too short)
```

### Transaction Pending Forever

**Possible Causes:**
1. Node not mining blocks
2. Network congestion
3. Invalid transaction signature

**Solutions:**
1. Check block production: `python3 send_transaction.py --balance YOUR_ADDRESS` (nonce increases = blocks being produced)
2. Wait longer (blocks may be slow)
3. Check transaction status: `python3 send_transaction.py --tx-status TX_HASH`
4. Check node logs: `docker logs -f boundless-node`

---

## API Reference

### Transaction Format

```json
{
  "from": "7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01",
  "to": "8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
  "amount": 50500000000000000000,
  "nonce": 5,
  "fee": 0,
  "signature": "3a5b2c8d9e4f1a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b..."
}
```

### RPC Methods

**Get Balance:**
```json
{
  "jsonrpc": "2.0",
  "method": "account_balance",
  "params": ["ADDRESS"],
  "id": 1
}
```

**Get Nonce:**
```json
{
  "jsonrpc": "2.0",
  "method": "account_nonce",
  "params": ["ADDRESS"],
  "id": 1
}
```

**Submit Transaction:**
```json
{
  "jsonrpc": "2.0",
  "method": "submit_transaction",
  "params": ["SIGNED_TX_JSON"],
  "id": 1
}
```

**Get Transaction:**
```json
{
  "jsonrpc": "2.0",
  "method": "get_transaction",
  "params": ["TX_HASH"],
  "id": 1
}
```

**Get Block Number:**
```json
{
  "jsonrpc": "2.0",
  "method": "block_number",
  "params": [],
  "id": 1
}
```

### Amount Precision

- **Decimals:** 18 (like Ethereum)
- **Smallest Unit:** 1 wei = 0.000000000000000001 BLS
- **1 BLS:** 1,000,000,000,000,000,000 wei

**Examples:**
- 1 BLS = `1000000000000000000`
- 0.5 BLS = `500000000000000000`
- 100 BLS = `100000000000000000000`

---

## Security Best Practices

### 1. Wallet Storage

✅ **DO:**
- Store wallet files with private keys in encrypted storage
- Use hardware wallets for large amounts
- Backup recovery phrases offline (paper, metal)
- Use strong passphrases for additional security

❌ **DON'T:**
- Share wallet files with anyone
- Store private keys in cloud storage
- Take photos of recovery phrases
- Email or message recovery phrases

### 2. Transaction Safety

✅ **DO:**
- Double-check recipient addresses before sending
- Start with small test transactions
- Verify transaction on explorer after sending
- Keep transaction records

❌ **DON'T:**
- Send to untrusted addresses
- Send maximum balance without keeping reserve
- Ignore transaction confirmation prompts
- Use public/shared computers for transactions

### 3. Network Security

✅ **DO:**
- Use HTTPS for remote RPC connections
- Run your own node when possible
- Verify RPC endpoint authenticity
- Use VPN for sensitive operations

❌ **DON'T:**
- Use untrusted public RPC endpoints
- Send transactions over public WiFi
- Disable SSL/TLS verification
- Store credentials in scripts

---

## Advanced Usage

### Custom RPC Client

```python
from send_transaction import BoundlessRPC, BoundlessWallet

# Initialize RPC client
rpc = BoundlessRPC("http://localhost:9933")

# Load wallet
wallet = BoundlessWallet.from_file("my_wallet.json")

# Get account state
balance = rpc.get_balance(wallet.address)
nonce = rpc.get_nonce(wallet.address)

# Create and send transaction
signed_tx = wallet.sign_transaction(
    to_address="0x...",
    amount=1000000000000000000,  # 1 BLS
    nonce=nonce,
    fee=0
)

tx_hash = rpc.send_transaction(signed_tx)
print(f"Transaction sent: {tx_hash}")
```

### Batch Transactions

```python
import time
from send_transaction import BoundlessRPC, BoundlessWallet

rpc = BoundlessRPC()
wallet = BoundlessWallet.from_file("sender.json")

recipients = [
    ("0xabc...", 10),  # (address, amount)
    ("0xdef...", 20),
    ("0x123...", 30),
]

nonce = rpc.get_nonce(wallet.address)

for to_address, amount in recipients:
    amount_wei = amount * (10 ** 18)
    signed_tx = wallet.sign_transaction(to_address, amount_wei, nonce, 0)
    tx_hash = rpc.send_transaction(signed_tx)
    print(f"Sent {amount} BLS to {to_address}: {tx_hash}")
    nonce += 1
    time.sleep(1)  # Rate limiting
```

---

## Support

- **Explorer:** https://64.225.16.227/
- **Mainnet Bootnode:** 159.203.114.205:30333
- **GitHub:** https://github.com/codenlighten/boundless_deploy
- **Documentation:** See README.md and WALLET_INTEGRATION.md

---

**Last Updated:** November 25, 2025
