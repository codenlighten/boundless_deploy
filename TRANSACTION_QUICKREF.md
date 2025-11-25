# Boundless Transaction Quick Reference

One-page command reference for sending BLS tokens.

---

## 🚀 Quick Start (3 Commands)

```bash
# 1. Generate wallet with private key
python3 keygen/boundless_wallet_gen.py generate --show-private -o my_wallet.json

# 2. Check balance
python3 send_transaction.py --balance <your_address>

# 3. Send transaction
python3 send_transaction.py --from my_wallet.json --to <recipient> --amount 100
```

---

## 📋 Essential Commands

### Send Transaction
```bash
python3 send_transaction.py --from wallet.json --to <address> --amount 50
```

### Check Balance
```bash
python3 send_transaction.py --balance <address>
```

### Transaction Status
```bash
python3 send_transaction.py --tx-status <tx_hash>
```

### Skip Confirmation
```bash
python3 send_transaction.py --from wallet.json --to <address> --amount 10 -y
```

### Custom RPC Endpoint
```bash
python3 send_transaction.py --rpc-url http://node.example.com:9933 --balance <address>
```

### Send from Mnemonic
```bash
python3 send_transaction.py --mnemonic "word1 word2 ... word24" --to <address> --amount 25
```

---

## 🔧 Wallet Management

### Generate New Wallet (with private key)
```bash
python3 keygen/boundless_wallet_gen.py generate --show-private -o wallet.json
```

### Restore from Mnemonic (with private key)
```bash
python3 keygen/boundless_wallet_gen.py restore \
  --mnemonic "word1 word2 ... word24" \
  --show-private \
  -o restored_wallet.json
```

### Extract Address from Wallet
```bash
python3 -c "import json; print(json.load(open('wallet.json'))['address'])"
```

---

## 🧪 Local Testing

### Start Test Node
```bash
./test_local_deployment.sh
```

### View Logs
```bash
docker logs -f boundless-test-node
```

### View Metrics
```bash
curl http://localhost:9615/metrics
```

### Stop Test Node
```bash
docker stop boundless-test-node && docker rm boundless-test-node
```

---

## 📊 Common Workflows

### Transfer Between Two Wallets
```bash
# Generate two wallets
python3 keygen/boundless_wallet_gen.py generate --show-private -o alice.json
python3 keygen/boundless_wallet_gen.py generate --show-private -o bob.json

# Get Bob's address
BOB=$(python3 -c "import json; print(json.load(open('bob.json'))['address'])")

# Send from Alice to Bob
python3 send_transaction.py --from alice.json --to $BOB --amount 100

# Check Bob received it
python3 send_transaction.py --balance $BOB
```

### Batch Send to Multiple Recipients
```bash
RECIPIENTS=("addr1" "addr2" "addr3")
for addr in "${RECIPIENTS[@]}"; do
  python3 send_transaction.py --from wallet.json --to $addr --amount 10 -y
  sleep 1
done
```

---

## ⚠️ Important Notes

### Address Format
- **Length:** 64 hexadecimal characters
- **No prefix:** Don't use `0x` prefix
- **Example:** `7adb34d0fa0d6e74fbf41fafde4329e1953495d8d091c19ae5e964d3def93e01`

### Amount Format
- **Decimals:** 18 (like Ethereum)
- **1 BLS:** `1.0` or `1`
- **0.5 BLS:** `0.5`
- **100 BLS:** `100`

### Security
- ⚠️ Only generate wallets with `--show-private` on secure, offline machines
- ⚠️ Never share private keys or wallet files
- ⚠️ Backup recovery phrases on paper, not digitally

### Prerequisites
```bash
pip3 install requests PyNaCl pycryptodome mnemonic
```

---

## 🔗 Resources

- **Full Guide:** [TRANSACTION_GUIDE.md](TRANSACTION_GUIDE.md)
- **Testing Guide:** [TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Explorer:** https://64.225.16.227/
- **Repository:** https://github.com/codenlighten/boundless_deploy

---

## 🆘 Troubleshooting

### Cannot connect to node
```bash
# Check if node is running
docker ps | grep boundless

# Start node
docker start boundless-node

# Check RPC port
docker port boundless-node
```

### Private key not found
```bash
# Wallet needs --show-private flag
python3 keygen/boundless_wallet_gen.py generate --show-private -o new_wallet.json
```

### Insufficient balance
```bash
# Check balance first
python3 send_transaction.py --balance <your_address>

# Mine blocks to earn rewards (if mining node)
# Or receive funds from another wallet
```

---

**Quick Help:** `python3 send_transaction.py --help`
