# Encrypted Keystore ("KeepBox") - Design Document

**Feature:** Secure AES-256-GCM Encrypted Wallet Storage
**Status:** Design Phase
**Target:** Production-ready secure key storage

---

## 1. Overview

### What is a KeepBox?

A **KeepBox** is an encrypted container that securely stores your wallet's private keys, mnemonic, and metadata. It's protected by a password and uses industry-standard encryption.

**Benefits:**
- 🔐 **Military-grade encryption** (AES-256-GCM)
- 🔑 **Password-protected** (Argon2id key derivation)
- 💾 **Single file storage** (portable and easy to backup)
- 🛡️ **Authenticated encryption** (tamper-proof)
- 🌐 **Cross-platform** (works on Windows, Linux, macOS)

---

## 2. Architecture

### File Format

```
┌─────────────────────────────────────────────────────────────┐
│                    KeepBox File Structure                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Header:                                                     │
│    - Magic bytes: "BNDLS" (5 bytes)                         │
│    - Version: 1 (1 byte)                                    │
│    - Reserved: 0x00 (2 bytes)                               │
│                                                              │
│  Metadata (JSON):                                            │
│    - KDF algorithm (Argon2id)                               │
│    - KDF parameters (memory, iterations, parallelism)       │
│    - Salt (32 bytes, random)                                │
│    - Nonce (12 bytes, random)                               │
│    - Created timestamp                                       │
│    - Key type (Ed25519, ML-DSA-44, etc.)                    │
│    - Public address (for quick lookup)                      │
│                                                              │
│  Encrypted Data (AES-256-GCM):                              │
│    - Mnemonic (24 words)                                    │
│    - Private key (32 bytes)                                 │
│    - Public key (32 bytes)                                  │
│    - Address (64 hex chars)                                 │
│    - Custom metadata (optional)                             │
│                                                              │
│  Authentication Tag:                                         │
│    - GCM tag (16 bytes)                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### Encryption Process

```
User Password
    ↓
Argon2id Key Derivation Function
    ↓ (memory-hard, 64 MB RAM, 3 iterations)
256-bit Encryption Key
    ↓
AES-256-GCM Encryption (with 96-bit nonce)
    ↓
Encrypted Keystore + Authentication Tag
    ↓
Save to .keepbox file
```

---

### Decryption Process

```
User Password
    ↓
Load .keepbox file
    ↓
Extract Salt + Nonce
    ↓
Argon2id Key Derivation (same parameters)
    ↓
256-bit Encryption Key
    ↓
AES-256-GCM Decryption + Tag Verification
    ↓
Decrypted Wallet Data (or error if wrong password)
```

---

## 3. Security Specifications

### Encryption Algorithm: AES-256-GCM

**What it is:** Advanced Encryption Standard with Galois/Counter Mode

**Specifications:**
- **Key size:** 256 bits (32 bytes)
- **Block size:** 128 bits (16 bytes)
- **Nonce size:** 96 bits (12 bytes)
- **Authentication tag:** 128 bits (16 bytes)

**Security Properties:**
- ✅ **Confidentiality** - Data is encrypted and unreadable without key
- ✅ **Integrity** - Any tampering is detected via authentication tag
- ✅ **Authenticity** - Proves data came from legitimate source
- ✅ **NIST approved** - Recommended by US government

**Why GCM mode:**
- Provides both encryption AND authentication (AEAD)
- Detects if file is tampered with
- Faster than encrypt-then-MAC schemes
- Industry standard (used by TLS, SSH, etc.)

---

### Key Derivation: Argon2id

**What it is:** Memory-hard password hashing function (winner of Password Hashing Competition 2015)

**Parameters:**
```rust
Argon2id {
    memory_cost: 64 * 1024,      // 64 MB RAM (memory-hard)
    time_cost: 3,                 // 3 iterations
    parallelism: 4,               // 4 threads
    salt_length: 32,              // 32 bytes random salt
    hash_length: 32,              // 32 bytes output (256 bits)
}
```

**Why Argon2id:**
- ✅ **Memory-hard** - Resists GPU/ASIC attacks
- ✅ **Configurable** - Can increase difficulty over time
- ✅ **Side-channel resistant** - Hybrid mode (Argon2i + Argon2d)
- ✅ **Recommended** - By OWASP, NIST, security experts

**Resistance to Attacks:**
- **Brute force:** 64 MB RAM per attempt makes it slow
- **GPU attacks:** Memory requirement makes GPUs inefficient
- **ASIC attacks:** Memory-hardness prevents custom hardware
- **Rainbow tables:** Salt makes precomputation impossible

---

### Password Requirements

**Minimum (enforced):**
- Length: 12 characters
- Must not be common password (check against list)

**Recommended:**
- Length: 20+ characters
- Mix of uppercase, lowercase, numbers, symbols
- Use passphrase: "correct-horse-battery-staple-2025!"
- Use password manager to generate and store

**Password Strength Examples:**

| Password | Entropy | Crack Time | Rating |
|----------|---------|------------|--------|
| `password123` | ~30 bits | < 1 second | ❌ WEAK |
| `P@ssw0rd!23` | ~40 bits | Minutes | ❌ WEAK |
| `MyBoundless2025!` | ~60 bits | Years | ⚠️ OK |
| `correct-horse-battery-staple-78` | ~80 bits | Centuries | ✅ GOOD |
| `aK9#mP2$vL8@nQ5&jR7*tW3^` | ~128 bits | Universe lifetime | ✅ EXCELLENT |

---

## 4. File Format Specification

### Version 1.0 Format

```json
{
  "version": 1,
  "magic": "BNDLS",

  "crypto": {
    "cipher": "aes-256-gcm",
    "kdf": "argon2id",

    "kdf_params": {
      "memory_cost": 65536,      // 64 MB in KB
      "time_cost": 3,
      "parallelism": 4,
      "salt": "base64-encoded-32-bytes"
    },

    "cipher_params": {
      "nonce": "base64-encoded-12-bytes"
    },

    "ciphertext": "base64-encoded-encrypted-data",
    "auth_tag": "base64-encoded-16-bytes"
  },

  "metadata": {
    "created_at": "2025-01-15T14:32:11Z",
    "modified_at": "2025-01-15T14:32:11Z",
    "key_type": "Ed25519",
    "address": "d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793",
    "label": "My Boundless Wallet",
    "version": "1.0.0"
  }
}
```

### Plaintext Structure (Before Encryption)

```json
{
  "mnemonic": "aunt carpet sleep device pear morning demand indoor boss sad connect knee sample recall hidden strike juice tray genius tragic prefer tornado enjoy prevent",
  "private_key": "hex-encoded-32-bytes",
  "public_key": "e7626b7f165a76b63ad96195fd8a3764d65c811b41b746489da779f9300b6357",
  "address": "d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793",
  "key_type": "Ed25519",
  "custom_data": {
    "notes": "Optional user notes",
    "tags": ["validator", "main-wallet"]
  }
}
```

---

## 5. CLI Commands

### New Commands

#### `init` - Create Encrypted KeepBox

```bash
# Create new wallet with encrypted keystore
boundless-wallet init --keepbox my_wallet.keepbox

# With custom label
boundless-wallet init --keepbox validator.keepbox --label "Validator Node 1"

# With passphrase for additional BIP39 security
boundless-wallet init --keepbox wallet.keepbox --bip39-passphrase
```

**Flow:**
1. Prompt for password (hidden input)
2. Confirm password (re-enter)
3. Validate password strength
4. Generate wallet (mnemonic + keys)
5. Display mnemonic (WRITE IT DOWN!)
6. Derive encryption key from password
7. Encrypt wallet data
8. Save to .keepbox file
9. Done!

---

#### `open` - Decrypt and Display Info

```bash
# Show wallet info (without revealing secrets)
boundless-wallet open my_wallet.keepbox

# Show with public key
boundless-wallet open my_wallet.keepbox --show-pubkey

# Export address only
boundless-wallet open my_wallet.keepbox --address-only
```

**Output:**
```
🔓 KeepBox: my_wallet.keepbox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Label:      My Boundless Wallet
Key Type:   Ed25519
Created:    2025-01-15 14:32:11 UTC
Modified:   2025-01-15 14:32:11 UTC

📬 Address:
   d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793

🔐 Public Key:
   e7626b7f165a76b63ad96195fd8a3764d65c811b41b746489da779f9300b6357

⚠️  Private data NOT shown (use --export-private to export)
```

---

#### `export` - Export Keys Safely

```bash
# Export mnemonic (with confirmation)
boundless-wallet export my_wallet.keepbox --mnemonic

# Export private key (DANGEROUS - requires --force)
boundless-wallet export my_wallet.keepbox --private-key --force

# Export to new JSON file (for migration)
boundless-wallet export my_wallet.keepbox --to-json wallet.json

# Export public key only (safe)
boundless-wallet export my_wallet.keepbox --public-key
```

**Safety Features:**
- Private key export requires `--force` flag
- Mnemonic export shows warning and requires confirmation
- Displays warning about clipboard if using copy
- Auto-clears screen after timeout (optional)

---

#### `import` - Import Existing Wallet

```bash
# Import from mnemonic
boundless-wallet import --mnemonic "24 words..." --keepbox new_wallet.keepbox

# Import from JSON (migrate existing wallet)
boundless-wallet import --from-json old_wallet.json --keepbox migrated.keepbox

# Import from mnemonic file
boundless-wallet import --mnemonic-file backup.txt --keepbox restored.keepbox
```

---

#### `change-password` - Update Password

```bash
# Change password for existing keepbox
boundless-wallet change-password my_wallet.keepbox

# Flow:
# 1. Enter current password
# 2. Enter new password
# 3. Confirm new password
# 4. Re-encrypt with new key
# 5. Save
```

---

#### `verify` - Integrity Check

```bash
# Verify keepbox integrity (no decryption)
boundless-wallet verify my_wallet.keepbox

# Verify with full decryption test
boundless-wallet verify my_wallet.keepbox --full
```

**Checks:**
- File format valid
- Magic bytes correct
- JSON parseable
- Crypto parameters valid
- Authentication tag present
- (With --full) Decryption successful

---

#### `backup` - Create Encrypted Backup

```bash
# Create encrypted backup
boundless-wallet backup my_wallet.keepbox --output backup/wallet_2025-01-15.keepbox

# Verify backup
boundless-wallet verify backup/wallet_2025-01-15.keepbox --full
```

---

#### `sign` - Sign Message/Transaction

```bash
# Sign a message
boundless-wallet sign my_wallet.keepbox --message "Hello Boundless"

# Sign transaction hash
boundless-wallet sign my_wallet.keepbox --tx-hash <hex>

# Output signature to file
boundless-wallet sign my_wallet.keepbox --message "..." --output signature.sig
```

---

## 6. Security Features

### Implemented

1. **Authenticated Encryption (AEAD)**
   - AES-256-GCM provides both confidentiality and integrity
   - Tampered files are detected immediately
   - Authentication tag verification prevents modified ciphertext

2. **Memory-Hard Key Derivation**
   - Argon2id requires 64 MB RAM per password attempt
   - Makes brute-force attacks impractical
   - Resistant to GPU/ASIC attacks

3. **Secure Random Generation**
   - Salt: 32 bytes from OS RNG
   - Nonce: 12 bytes from OS RNG (unique per encryption)
   - Ensures unique encryption even with same password

4. **Password Validation**
   - Minimum length enforcement (12 chars)
   - Common password blacklist
   - Strength estimation displayed

5. **Private Key Zeroization**
   - Decrypted keys automatically zeroed after use
   - Prevents memory dumps from revealing keys
   - Rust's `zeroize` crate ensures cleanup

6. **File Permissions**
   - KeepBox files created with 0600 (owner only)
   - Prevents other users from reading
   - Warning if permissions are too open

7. **Secure Password Input**
   - Hidden input (no echo to screen)
   - Not logged to terminal history
   - Cleared from memory after use

---

### Additional Security (Future)

8. **Two-Factor Authentication**
   - Require hardware token (YubiKey) for unlock
   - TOTP support for additional verification

9. **Biometric Unlock**
   - Fingerprint on supported devices
   - Face ID on macOS

10. **HSM Integration**
    - Store keys in hardware security module
    - Never expose private key to software

11. **Multi-Signature**
    - Require M-of-N keys to unlock
    - Distributed trust

---

## 7. Usage Examples

### Example 1: Create New Wallet

```bash
$ boundless-wallet init --keepbox my_wallet.keepbox

🔐 Create New KeepBox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter password: ******************** (hidden)
Confirm password: ********************

Password strength: STRONG ✅

✓ Generating 24-word mnemonic
✓ Deriving Ed25519 keypair
✓ Encrypting wallet data

🔑 WRITE DOWN YOUR MNEMONIC:

   aunt carpet sleep device pear morning demand indoor boss sad connect knee
   sample recall hidden strike juice tray genius tragic prefer tornado enjoy prevent

⚠️  This is your ONLY backup! Write it down NOW on paper!

Press ENTER after writing down mnemonic...

✓ Mnemonic confirmed
✓ Saved to my_wallet.keepbox

📬 Address: d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793

✅ KeepBox created successfully!
```

---

### Example 2: Open KeepBox

```bash
$ boundless-wallet open my_wallet.keepbox

🔓 Unlock KeepBox: my_wallet.keepbox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter password: ********************

✓ Password verified
✓ KeepBox unlocked

Label:      My Boundless Wallet
Key Type:   Ed25519
Created:    2025-01-15 14:32:11 UTC

📬 Address:
   d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793
```

---

### Example 3: Export Mnemonic

```bash
$ boundless-wallet export my_wallet.keepbox --mnemonic

⚠️  WARNING: You are about to export your mnemonic!
⚠️  Anyone with this can steal your funds!

Type 'I UNDERSTAND' to confirm: I UNDERSTAND

Enter password: ********************

🔑 Mnemonic:

   aunt carpet sleep device pear morning demand indoor boss sad connect knee
   sample recall hidden strike juice tray genius tragic prefer tornado enjoy prevent

⚠️  Write this down immediately!
⚠️  This screen will clear in 60 seconds...

Press ENTER to clear screen...
```

---

### Example 4: Sign Transaction

```bash
$ boundless-wallet sign my_wallet.keepbox --tx-hash a1b2c3d4e5f6...

🔓 Unlock KeepBox: my_wallet.keepbox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter password: ********************

✓ KeepBox unlocked
✓ Signing transaction...

📝 Signature (Ed25519):
   3a5b2c8d9e4f1a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b
   1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d

✓ Signature saved to signature.sig
```

---

### Example 5: Change Password

```bash
$ boundless-wallet change-password my_wallet.keepbox

🔐 Change KeepBox Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter current password: ********************

✓ Current password verified

Enter new password: ********************
Confirm new password: ********************

Password strength: STRONG ✅

✓ Re-encrypting wallet data
✓ Password changed successfully

⚠️  Make sure you remember your new password!
    There is NO way to recover if you forget it!
```

---

## 8. Implementation Plan

### Phase 1: Core Encryption (Week 1-2)

- [ ] Implement AES-256-GCM encryption/decryption
- [ ] Implement Argon2id key derivation
- [ ] Create KeepBox file format (save/load)
- [ ] Add password input utilities (hidden)
- [ ] Implement zeroization for decrypted keys

### Phase 2: CLI Commands (Week 3-4)

- [ ] `init` - Create new encrypted wallet
- [ ] `open` - Display wallet info
- [ ] `export` - Export keys with safety checks
- [ ] `import` - Import from mnemonic/JSON
- [ ] `verify` - Integrity verification

### Phase 3: Advanced Features (Week 5-6)

- [ ] `change-password` - Password rotation
- [ ] `sign` - Transaction/message signing
- [ ] `backup` - Automated backups
- [ ] Password strength validation
- [ ] Common password blacklist

### Phase 4: Testing & Documentation (Week 7-8)

- [ ] Unit tests for all crypto operations
- [ ] Integration tests for workflows
- [ ] Security audit of implementation
- [ ] User documentation
- [ ] Migration guide (JSON → KeepBox)

---

## 9. Migration Path

### From JSON to KeepBox

```bash
# Step 1: Import existing JSON wallet
boundless-wallet import --from-json old_wallet.json --keepbox new_wallet.keepbox

# Step 2: Verify migration
boundless-wallet verify new_wallet.keepbox --full

# Step 3: Delete old JSON (after confirming backup)
shred -u old_wallet.json  # Linux
rm old_wallet.json        # Or just delete
```

### Batch Migration Script

```bash
#!/bin/bash
# migrate_all.sh - Convert all JSON wallets to KeepBox

for json_file in *.json; do
    keepbox_file="${json_file%.json}.keepbox"

    echo "Migrating: $json_file → $keepbox_file"

    boundless-wallet import \
        --from-json "$json_file" \
        --keepbox "$keepbox_file"

    # Verify
    if boundless-wallet verify "$keepbox_file" --full; then
        echo "✓ Migration successful"
        # Optionally delete JSON
        # rm "$json_file"
    else
        echo "✗ Migration failed!"
        exit 1
    fi
done
```

---

## 10. Security Considerations

### Threat Model

**Protected Against:**
- ✅ Stolen keepbox file (without password)
- ✅ Brute-force password attacks (Argon2id)
- ✅ Rainbow table attacks (salt)
- ✅ File tampering (authentication tag)
- ✅ Memory dumps (zeroization)
- ✅ Weak passwords (validation)

**NOT Protected Against:**
- ❌ Keyloggers (can capture password when typed)
- ❌ Screen recording (can see mnemonic during export)
- ❌ Physical access + unlimited time (can brute-force weak password)
- ❌ Social engineering (user giving away password)
- ❌ Malware on the system

**Mitigations:**
- Use hardware wallet for high-value storage
- Use air-gapped machine for critical operations
- Enable full-disk encryption
- Use strong, unique password
- Keep system malware-free

---

### Best Practices

1. **Password Management**
   - Use unique password (not reused)
   - Store password in password manager OR
   - Memorize strong passphrase
   - Write down and store in safe (for estate planning)

2. **Backup Strategy**
   - Keep mnemonic on paper (primary backup)
   - Keep encrypted keepbox on multiple devices
   - Store backup keepbox in cloud (Dropbox, etc.) - it's encrypted!
   - Test recovery regularly

3. **Operational Security**
   - Lock screen when away from computer
   - Don't export mnemonic unless absolutely necessary
   - Clear screen after displaying secrets
   - Use separate user account for crypto operations

4. **Incident Response**
   - If password compromised: change immediately
   - If keepbox file lost: restore from mnemonic
   - If mnemonic lost: funds are PERMANENTLY LOST

---

## 11. Future Enhancements

### v1.1 - Enhanced Security

- Hardware token support (YubiKey)
- Biometric unlock (fingerprint, Face ID)
- Auto-lock after timeout
- Clipboard security (auto-clear)

### v1.2 - Multi-Wallet

- Store multiple wallets in one keepbox
- Hierarchical deterministic (HD) wallets
- Account derivation (BIP44/BIP84)

### v1.3 - Advanced Features

- Time-locked transactions
- Multi-signature support
- Smart contract integration
- Hardware wallet integration (Ledger, Trezor)

### v2.0 - Post-Quantum

- ML-DSA-44 (Dilithium) support
- Falcon-512 support
- Hybrid encryption (classical + PQC)

---

## 12. Comparison with Alternatives

| Feature | KeepBox | Hardware Wallet | Paper Wallet | Password Manager |
|---------|---------|-----------------|--------------|------------------|
| **Encryption** | ✅ AES-256-GCM | ✅ Hardware | ❌ None | ✅ AES-256 |
| **Password Protected** | ✅ Yes | ✅ PIN | ❌ No | ✅ Yes |
| **Offline Use** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Sync required |
| **Signing** | ✅ Yes | ✅ Yes | ❌ Manual | ❌ No |
| **Backup** | ✅ Easy | ⚠️ Seed | ✅ Copy | ✅ Cloud |
| **Cost** | ✅ Free | ❌ $50-200 | ✅ Free | ⚠️ $0-50/yr |
| **Security** | ✅ Good | ✅ Excellent | ⚠️ Physical only | ✅ Good |
| **Ease of Use** | ✅ Easy | ⚠️ Setup required | ❌ Manual | ✅ Easy |

**Recommendation:**
- **KeepBox** - Daily use, moderate amounts
- **Hardware Wallet** - Large amounts, validators
- **Paper Wallet** - Long-term cold storage
- **All Three** - Defense in depth!

---

## 13. Conclusion

The KeepBox encrypted keystore provides:

✅ **Strong Security** - Military-grade encryption (AES-256-GCM)
✅ **Ease of Use** - Simple CLI commands
✅ **Portability** - Single file, easy to backup
✅ **Compatibility** - Works with existing wallets (migration)
✅ **Future-Proof** - Designed for post-quantum upgrades

**Next Step:** Implement Phase 1 (Core Encryption)

---

**Document Version:** 1.0
**Last Updated:** 2025-01-15
**Status:** Design Complete - Ready for Implementation
