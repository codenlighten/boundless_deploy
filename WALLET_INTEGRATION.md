# Wallet Generation Integration

The Boundless node deployment system now includes **automatic wallet generation** using the battle-tested keygen system.

## Features

✅ **Automatic wallet generation** on node startup
✅ **BIP39 24-word recovery phrases** for secure backup
✅ **Ed25519 cryptography** with SHA3-256 address derivation
✅ **Flexible deployment** - generate new or use existing address
✅ **Production-ready** security with air-gap compatibility

## Usage

### Method 1: Interactive Script

```bash
./start_boundless_node.sh
```

**You'll be prompted:**

```
Wallet Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Do you want to:
  1) Generate a NEW wallet (recommended for new users)
  2) Use an EXISTING address

Enter choice (1 or 2):
```

**Option 1: Generate New Wallet**
- Automatically creates a new wallet using the keygen system
- Displays your 24-word recovery phrase (WRITE IT DOWN!)
- Saves wallet details to a JSON file
- Uses the generated address for mining

**Option 2: Use Existing Address**
- Prompts for your existing mining address
- Validates address format (64 hex characters)
- Uses your provided address

### Method 2: Controller with Auto-Generation

Set environment variable to automatically generate wallets:

```bash
export AUTO_GENERATE_WALLET=true
node controller/deploy.js
```

This will:
- Generate wallets for any node with `coinbase: "YOUR_ADDRESS_HERE"`
- Save wallet files as `wallet_<node-id>_<timestamp>.json`
- Display recovery phrases in deployment logs
- Update node configs with generated addresses

### Method 3: Pre-Configure Address

Edit `cluster.json` before deployment:

```json
{
  "blockchainConfig": {
    "mining": {
      "coinbase": "8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
      "threads": 2
    }
  }
}
```

Then deploy normally:

```bash
node controller/deploy.js
```

## Wallet Files

Generated wallets are saved with timestamps:

```
boundless_wallet_20251125_143022.json
wallet_boundless-miner-01_1700000000000.json
```

**Wallet File Format:**

```json
{
  "mnemonic": "abandon ability able about above absent absorb abstract absurd abuse access accident acquire across act action actor actress actual adapt add addict address adjust",
  "public_key": "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
  "address": "8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
  "key_type": "Ed25519"
}
```

## Security Best Practices

### 🔐 Recovery Phrase

**CRITICAL:** Your 24-word recovery phrase is the ONLY way to recover your wallet.

✅ **DO:**
- Write it down on paper immediately
- Store it in a secure physical location (fireproof safe)
- Make multiple copies stored in different locations
- Test wallet recovery before receiving funds
- Use a metal backup for long-term storage

❌ **DON'T:**
- Take screenshots or photos
- Store in cloud storage (Google Drive, Dropbox, etc.)
- Email it to yourself
- Share it with anyone
- Store it on any internet-connected device

### 🛡️ Address Validation

All generated addresses:
- Are **exactly 64 hexadecimal characters** (32 bytes)
- Use **SHA3-256** hash of the public key
- Follow **Boundless blockchain conventions**
- Are validated before use

### 💾 Wallet File Storage

**Production Deployments:**

```bash
# Store wallet files in secure location
mkdir -p ~/.boundless/wallets
chmod 700 ~/.boundless/wallets

# Move generated wallet
mv boundless_wallet_*.json ~/.boundless/wallets/

# Backup securely
tar czf wallets_backup_$(date +%Y%m%d).tar.gz ~/.boundless/wallets/
# Store backup offline (USB drive, encrypted volume)
```

**Air-Gapped Setup:**

For maximum security, generate wallets on an air-gapped machine:

```bash
# On air-gapped machine
cd keygen/
python3 boundless_wallet_gen.py generate --output secure_wallet.json

# Write down mnemonic
cat secure_wallet.json | jq -r .mnemonic

# Extract just the address
cat secure_wallet.json | jq -r .address > address.txt

# Transfer address.txt to online machine via USB
# Keep wallet file on air-gapped machine
```

## Integration with Keygen

The integrated system uses:

- **Script:** `keygen/boundless_wallet_gen.py`
- **Dependencies:** `mnemonic`, `PyNaCl`, `pycryptodome`
- **Format:** BIP39 24-word mnemonic → Ed25519 keypair → SHA3-256 address

### Address Derivation

```python
# Follows boundless-bls-platform conventions exactly
from Crypto.Hash import SHA3_256

def derive_address(public_key_bytes):
    hasher = SHA3_256.new()
    hasher.update(public_key_bytes)
    return hasher.digest().hex()  # 64 hex characters
```

### Compatibility

✅ Cross-compatible with:
- Rust implementation (`boundless_wallet_gen.rs`)
- Boundless platform wallet service
- Standard BIP39 tools (for recovery)

✅ Deterministic:
- Same mnemonic always produces same address
- Reproducible across implementations
- Test vectors validate correctness

## Recovery

### Restore from Mnemonic

**Using the script:**

```bash
python3 keygen/boundless_wallet_gen.py restore \
  "word1 word2 word3 ... word24" \
  --output restored_wallet.json
```

**Using the Rust implementation:**

```bash
cd keygen/
cargo run --release -- restore \
  --mnemonic "word1 word2 ... word24" \
  --output restored_wallet.json
```

### Verify Address

Confirm an address matches your recovery phrase:

```bash
# Restore wallet
python3 keygen/boundless_wallet_gen.py restore "your 24 words here"

# Compare addresses
# If they match, your backup is correct
```

## Troubleshooting

### Missing Dependencies

**Error:** `ModuleNotFoundError: No module named 'mnemonic'`

**Solution:**
```bash
pip3 install mnemonic PyNaCl pycryptodome
```

### Keygen Script Not Found

**Error:** `Wallet generator not found`

**Solution:**
Ensure directory structure:
```
boundless/
├── start_boundless_node.sh
├── keygen/
│   └── boundless_wallet_gen.py
```

### Invalid Address Format

**Warning:** `Address format may be invalid`

Valid addresses:
- Exactly 64 characters
- Only hex digits (0-9, a-f)
- No prefix (`0x`, `bls1`, etc.)
- No checksum suffix

**Example valid address:**
```
8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
```

## Environment Variables

### AUTO_GENERATE_WALLET

Auto-generate wallets during controller deployment:

```bash
export AUTO_GENERATE_WALLET=true
node controller/deploy.js
```

**Use case:** Automated testing, development environments

**Warning:** Not recommended for production (you should manually secure recovery phrases)

## Examples

### New User Quick Start

```bash
# 1. Run the script
./start_boundless_node.sh

# 2. Choose option 1 (Generate NEW wallet)
# 3. Write down the 24-word recovery phrase
# 4. Confirm you've saved it
# 5. Node starts mining to your new address
```

### Existing User

```bash
# 1. Run the script
./start_boundless_node.sh

# 2. Choose option 2 (Use EXISTING address)
# 3. Paste your 64-character address
# 4. Node starts mining to your address
```

### Multi-Node Deployment

```bash
# Generate wallet for first node
export AUTO_GENERATE_WALLET=true
node controller/deploy.js

# Save the recovery phrase from wallet file
cat wallet_boundless-miner-01_*.json | jq -r .mnemonic > mnemonic_node1.txt

# Secure the mnemonic
chmod 600 mnemonic_node1.txt
# Backup offline immediately
```

## Advanced: Encrypted Keystore

For enhanced security, the keygen system supports encrypted keystores (see `CLI_SPECIFICATION.md`):

```bash
# Future: Production CLI with encrypted storage
boundless-wallet init --password
# Creates AES-256-GCM encrypted keystore
# Requires password for all operations
```

## References

- **Keygen Documentation:** `keygen/README.md`
- **Security Guide:** `keygen/SECURITY.md`
- **Test Vectors:** `keygen/TEST_VECTORS.md`
- **CLI Specification:** `keygen/CLI_SPECIFICATION.md`

## Support

**Issues:**
- Wallet generation problems: Check `keygen/README.md`
- Address validation: See `keygen/TEST_VECTORS.md`
- Security questions: Read `keygen/SECURITY.md`

**Blockchain Explorer:**
- View your mining rewards: https://64.225.16.227/
