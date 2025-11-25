# Boundless Wallet CLI - Specification

## Overview

A minimal, secure, air-gapped command-line wallet for the Boundless BLS blockchain. Designed for validators and users requiring cold storage solutions with zero network connectivity.

## Design Principles

- **Local-only**: No network calls, no telemetry, no analytics
- **Air-gap compatible**: Can run on machines without network access
- **Encrypted storage**: AES-256-GCM encrypted keystore with password protection
- **Minimal attack surface**: Single binary, minimal dependencies
- **Reproducible builds**: Deterministic compilation for security auditing

---

## Command Structure

```
boundless-wallet <command> [options]
```

---

## Commands

### 1. `init` - Initialize New Wallet

Creates a new wallet with a 24-word BIP39 mnemonic.

```bash
boundless-wallet init [OPTIONS]
```

**Options:**
- `--keystore <path>` - Path to encrypted keystore file (default: `~/.boundless/keystore.enc`)
- `--password` - Prompt for password (required for encryption)
- `--password-file <path>` - Read password from file (for automation)
- `--show-mnemonic` - Display mnemonic on screen (use carefully)
- `--output-mnemonic <path>` - Save mnemonic to file (SECURITY WARNING)

**Example:**
```bash
# Interactive (prompts for password)
boundless-wallet init --keystore wallet.enc

# With password file (for automated setup)
boundless-wallet init --keystore wallet.enc --password-file pass.txt --show-mnemonic
```

**Output:**
```
✓ Generated 24-word mnemonic
✓ Derived Ed25519 keypair
✓ Encrypted keystore created

📝 WRITE DOWN YOUR MNEMONIC (one-time display):
   abandon ability able about above absent absorb abstract absurd abuse access accident

⚠️  WARNING: This is your ONLY backup. Store it securely offline.

📬 Address: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
💾 Keystore: wallet.enc
```

---

### 2. `addr` - Display Address

Derives and displays the Boundless address from the stored keystore.

```bash
boundless-wallet addr [OPTIONS]
```

**Options:**
- `--keystore <path>` - Path to encrypted keystore (default: `~/.boundless/keystore.enc`)
- `--password` - Prompt for password
- `--password-file <path>` - Read password from file
- `--qr` - Display address as QR code (for air-gapped transfers)

**Example:**
```bash
boundless-wallet addr --keystore wallet.enc
```

**Output:**
```
📬 Boundless Address:
   e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

---

### 3. `export` - Export Keys

Exports public key or private key (with confirmation).

```bash
boundless-wallet export <type> [OPTIONS]
```

**Types:**
- `pubkey` - Export public key (safe to share)
- `private` - Export private key (DANGEROUS - requires `--force`)

**Options:**
- `--keystore <path>` - Path to encrypted keystore
- `--password` - Prompt for password
- `--password-file <path>` - Read password from file
- `--output <path>` - Write to file instead of stdout
- `--force` - Required for private key export (safety check)
- `--format <format>` - Output format: `hex` (default), `json`, `pem`

**Examples:**
```bash
# Export public key (safe)
boundless-wallet export pubkey --keystore wallet.enc

# Export private key (dangerous - requires confirmation)
boundless-wallet export private --keystore wallet.enc --force

# Export to file
boundless-wallet export pubkey --keystore wallet.enc --output public.txt
```

**Output (pubkey):**
```
🔐 Public Key:
   d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a

✅ Safe to share publicly
```

**Output (private - with --force):**
```
⚠️  DANGER: You are about to export your PRIVATE KEY!
⚠️  Anyone with this key can spend your funds.
⚠️  Only proceed if you know what you're doing.

Type 'I UNDERSTAND THE RISKS' to confirm: I UNDERSTAND THE RISKS

🔑 Private Key:
   [redacted in this example]

⛔ NEVER share this key with anyone!
⛔ Store it in a secure, encrypted location!
```

---

### 4. `restore` - Restore from Mnemonic

Restores a wallet from a 24-word BIP39 mnemonic.

```bash
boundless-wallet restore [OPTIONS]
```

**Options:**
- `--keystore <path>` - Path for new encrypted keystore
- `--mnemonic <words>` - Mnemonic phrase (quoted)
- `--mnemonic-file <path>` - Read mnemonic from file
- `--password` - Prompt for new password
- `--password-file <path>` - Read password from file

**Example:**
```bash
# Interactive (prompts for mnemonic and password)
boundless-wallet restore --keystore restored.enc

# From file (for air-gapped restore)
boundless-wallet restore --keystore restored.enc --mnemonic-file backup.txt
```

**Output:**
```
✓ Mnemonic validated
✓ Keypair restored
✓ Encrypted keystore created

📬 Address: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
💾 Keystore: restored.enc

✅ Wallet restored successfully!
```

---

### 5. `verify` - Verify Address

Verifies that an address matches a public key (useful for auditing).

```bash
boundless-wallet verify --pubkey <hex> --address <hex>
```

**Options:**
- `--pubkey <hex>` - Public key (hex-encoded)
- `--address <hex>` - Expected address (hex-encoded)

**Example:**
```bash
boundless-wallet verify \
  --pubkey d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a \
  --address e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

**Output:**
```
✅ Address matches! Verification successful.
```

---

### 6. `sign` - Sign Message (for validators)

Signs a message or transaction hash with the private key.

```bash
boundless-wallet sign [OPTIONS]
```

**Options:**
- `--keystore <path>` - Path to encrypted keystore
- `--password` - Prompt for password
- `--message <hex>` - Message to sign (hex-encoded)
- `--message-file <path>` - Read message from file
- `--output <path>` - Write signature to file

**Example:**
```bash
# Sign a transaction hash
boundless-wallet sign --keystore wallet.enc --message "a1b2c3..."

# Sign from file (for offline signing)
boundless-wallet sign --keystore wallet.enc --message-file tx_hash.txt --output signature.sig
```

---

### 7. `info` - Display Keystore Info

Shows metadata about the keystore (without decrypting).

```bash
boundless-wallet info --keystore <path>
```

**Options:**
- `--keystore <path>` - Path to encrypted keystore

**Example:**
```bash
boundless-wallet info --keystore wallet.enc
```

**Output:**
```
📦 Keystore Information:
   File: wallet.enc
   Created: 2025-01-15 14:32:11 UTC
   Modified: 2025-01-15 14:32:11 UTC
   Encryption: AES-256-GCM
   Key Type: Ed25519
   Version: 1.0.0
```

---

### 8. `change-password` - Change Keystore Password

Changes the password for an encrypted keystore.

```bash
boundless-wallet change-password [OPTIONS]
```

**Options:**
- `--keystore <path>` - Path to encrypted keystore
- `--old-password` - Prompt for old password
- `--new-password` - Prompt for new password

**Example:**
```bash
boundless-wallet change-password --keystore wallet.enc
```

---

## Keystore File Format

### Encryption Scheme

**Algorithm:** AES-256-GCM (Authenticated Encryption)

**Key Derivation:**
- Algorithm: Argon2id
- Memory: 64 MB
- Iterations: 3
- Parallelism: 4
- Salt: 16 bytes (random per keystore)

**Nonce:** 96-bit random nonce (unique per encryption)

### File Structure

```json
{
  "version": "1.0.0",
  "crypto": {
    "cipher": "aes-256-gcm",
    "ciphertext": "<base64-encoded-encrypted-data>",
    "cipherparams": {
      "nonce": "<base64-encoded-nonce>"
    },
    "kdf": "argon2id",
    "kdfparams": {
      "salt": "<base64-encoded-salt>",
      "memlimit": 67108864,
      "opslimit": 3,
      "parallelism": 4
    },
    "mac": "<base64-encoded-auth-tag>"
  },
  "metadata": {
    "created_at": "2025-01-15T14:32:11Z",
    "key_type": "Ed25519",
    "address": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
}
```

### Plaintext Structure (before encryption)

```json
{
  "private_key": "<hex-encoded-private-key>",
  "public_key": "<hex-encoded-public-key>",
  "address": "<hex-encoded-address>",
  "mnemonic": "<24-word-bip39-mnemonic>",
  "key_type": "Ed25519"
}
```

---

## Security Features

### 1. Password Security
- **Minimum length:** 12 characters
- **Recommended:** 20+ characters with mixed case, numbers, symbols
- **Storage:** Never stored; only used for key derivation
- **Memory security:** Passwords zeroed in memory after use

### 2. Key Security
- **Zeroization:** Private keys automatically zeroed after use
- **No swap:** mlock() to prevent swapping to disk (where supported)
- **No core dumps:** Disable core dumps during execution
- **Constant-time operations:** Prevent timing attacks

### 3. File Security
- **Permissions:** Keystores created with 0600 (owner read/write only)
- **Atomic writes:** Write to temp file, then atomic rename
- **Backup:** Never overwrite existing keystores without confirmation

### 4. Audit Trail
- **Logging:** Optional audit log for all operations (disabled by default)
- **No secrets in logs:** Never log keys or passwords
- **Read-only audit:** Audit log is append-only

---

## Environment Variables

```bash
# Default keystore location
export BOUNDLESS_KEYSTORE=~/.boundless/keystore.enc

# Password (NOT RECOMMENDED - use password prompts instead)
export BOUNDLESS_PASSWORD="your-password"

# Disable colored output
export NO_COLOR=1

# Enable audit logging
export BOUNDLESS_AUDIT_LOG=~/.boundless/audit.log
```

---

## Air-Gap Workflow Example

### Setup (on air-gapped machine)

```bash
# 1. Generate wallet offline
boundless-wallet init --keystore validator.enc --show-mnemonic

# 2. Write down mnemonic on paper (backup)

# 3. Export public key for registration
boundless-wallet export pubkey --keystore validator.enc --output pubkey.txt

# 4. Transfer pubkey.txt to online machine via USB
```

### Signing (on air-gapped machine)

```bash
# 1. Receive unsigned transaction on USB (tx_hash.txt)

# 2. Sign transaction offline
boundless-wallet sign --keystore validator.enc \
  --message-file tx_hash.txt \
  --output signature.sig

# 3. Transfer signature.sig to online machine via USB
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 0    | Success |
| 1    | Invalid arguments |
| 2    | Keystore not found |
| 3    | Invalid password |
| 4    | Encryption error |
| 5    | Invalid mnemonic |
| 6    | File I/O error |
| 7    | Permission denied |
| 8    | Keystore already exists |
| 9    | Invalid key format |
| 10   | Signature verification failed |

---

## Build & Installation

### From Source (Rust)

```bash
# Clone or copy source
cd boundless-wallet

# Build release binary
cargo build --release

# Install to system
cargo install --path .

# Verify installation
boundless-wallet --version
```

### Reproducible Build

```bash
# Use Docker for reproducible builds
docker build -t boundless-wallet-builder .
docker run --rm -v $(pwd):/build boundless-wallet-builder

# Verify build hash
sha256sum target/release/boundless-wallet
```

### Static Binary (for air-gap)

```bash
# Build fully static binary (no dependencies)
cargo build --release --target x86_64-unknown-linux-musl

# Verify it's static
ldd target/x86_64-unknown-linux-musl/release/boundless-wallet
# Output: "not a dynamic executable"
```

---

## Testing

### Unit Tests

```bash
cargo test
```

### Integration Tests

```bash
# Test full workflow
./tests/integration_test.sh
```

### Test Vectors

See `TEST_VECTORS.md` for known-good inputs and expected outputs.

---

## Dependencies

### Rust Crates

```toml
[dependencies]
# Cryptography
ed25519-dalek = "2.1"
oqs = { version = "0.10", optional = true }  # For PQC support
sha3 = "0.10"
zeroize = "1.7"
argon2 = "0.5"
aes-gcm = "0.10"

# BIP39
bip39 = "2.0"

# Utilities
clap = "4.5"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
hex = "0.4"
base64 = "0.22"
chrono = "0.4"

# Security
subtle = "2.5"
```

---

## Future Enhancements

### Phase 1 (Current)
- ✅ Ed25519 keypair generation
- ✅ BIP39 mnemonic support
- ✅ AES-256-GCM encrypted keystores
- ✅ Basic CLI commands

### Phase 2 (Planned)
- 🔄 ML-DSA-44 (Dilithium2) support
- 🔄 Falcon-512 support
- 🔄 Hybrid signatures (Ed25519 + ML-DSA-44)
- 🔄 Hardware wallet integration (Ledger, Trezor)

### Phase 3 (Roadmap)
- 📋 Multi-signature support
- 📋 HSM integration
- 📋 Shamir Secret Sharing for mnemonic backup
- 📋 Time-locked transactions
- 📋 Offline transaction creation

---

## License

MIT License (or match Boundless platform license)

---

## Security Audit

**Status:** Pending security audit

**Recommendations:**
1. Independent security audit before production use
2. Bug bounty program for vulnerability disclosure
3. Regular updates for cryptographic dependencies
4. Formal verification of critical cryptographic code

---

## Support

**Issues:** Report security issues privately to security@boundless.example
**Documentation:** https://docs.boundless.example/wallet-cli
**Community:** https://discord.gg/boundless
