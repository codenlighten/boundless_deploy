# Boundless Wallet - Security Notes & Best Practices

## Overview

This document provides comprehensive security guidance for Boundless wallet generation, key management, and operational security for validators and users.

---

## Table of Contents

1. [Threat Model](#threat-model)
2. [Entropy Sources](#entropy-sources)
3. [Key Generation Security](#key-generation-security)
4. [Storage Security](#storage-security)
5. [Operational Security (OpSec)](#operational-security-opsec)
6. [Air-Gap Security](#air-gap-security)
7. [HSM Integration](#hsm-integration)
8. [Validator Security](#validator-security)
9. [Cold Storage Best Practices](#cold-storage-best-practices)
10. [Incident Response](#incident-response)
11. [Cryptographic Considerations](#cryptographic-considerations)

---

## Threat Model

### Adversaries

1. **Remote Attackers**
   - Network-based malware
   - Supply chain attacks (compromised dependencies)
   - Phishing and social engineering
   - Man-in-the-middle attacks

2. **Local Attackers**
   - Malware on the generation machine
   - Keyloggers and screen recorders
   - Memory dumps and core files
   - Physical access to storage media

3. **Insider Threats**
   - Compromised team members
   - Stolen backups
   - Social engineering of staff

4. **State-Level Adversaries**
   - Advanced persistent threats (APTs)
   - Hardware backdoors
   - Cryptanalysis attacks
   - Quantum computing (future threat)

### Assets to Protect

1. **Private Keys** - Primary asset; compromise = total loss
2. **Mnemonic Phrases** - Backup/recovery mechanism
3. **Keystore Files** - Encrypted private keys
4. **Passwords** - Key derivation material
5. **Transaction Signing** - Operational security

---

## Entropy Sources

### Critical Importance

**Private key security depends entirely on entropy quality.** Weak entropy = predictable keys = theft.

### Operating System RNGs

**Recommended (High Quality):**

```rust
// Rust: OsRng from rand_core
use rand::rngs::OsRng;
let mut rng = OsRng;

// Uses:
// - Linux: /dev/urandom (with getrandom() syscall)
// - Windows: BCryptGenRandom
// - macOS: SecRandomCopyBytes
```

```python
# Python: secrets module
import secrets
entropy = secrets.token_bytes(32)

# Uses:
# - os.urandom() on all platforms
# - Same sources as Rust OsRng
```

**NEVER USE:**
- `rand()` without proper seeding
- Timestamp-based generation
- Predictable PRNGs (LCGs, Mersenne Twister without crypto seeding)
- User-provided "randomness" (mouse movements, keyboard timing)

### Hardware RNGs

**High-Security Environments:**

1. **CPU-based RNGs:**
   - Intel RDRAND/RDSEED instructions
   - ARM TrustZone RNG
   - Used by OS RNG automatically (mixed with other sources)

2. **External Hardware RNGs:**
   - USB hardware RNGs (e.g., TrueRNG, OneRNG)
   - HSM-integrated RNGs
   - Should be mixed with OS RNG, not used exclusively

3. **Physical RNGs:**
   - Quantum RNGs
   - Atmospheric noise RNGs (e.g., random.org API - NOT recommended for keys)
   - Avalanche noise generators

**Best Practice:** Mix multiple entropy sources using a cryptographic hash:

```rust
use sha3::{Digest, Sha3_256};

let os_entropy = OsRng.gen::<[u8; 32]>();
let hw_entropy = hardware_rng.generate(32);  // hypothetical

let mut hasher = Sha3_256::new();
hasher.update(b"BOUNDLESS-ENTROPY-MIX");
hasher.update(&os_entropy);
hasher.update(&hw_entropy);
let mixed_entropy = hasher.finalize();
```

### Entropy Testing

**Verify entropy quality with statistical tests:**

```bash
# Linux: Check /dev/random entropy
cat /proc/sys/kernel/random/entropy_avail
# Should be > 128 (ideally > 1000)

# Test randomness with dieharder
dd if=/dev/urandom of=random_sample.bin bs=1M count=10
dieharder -a -g 201 -f random_sample.bin
```

---

## Key Generation Security

### Environment Requirements

**Minimum Requirements:**

1. ✅ Clean OS install (or known-good state)
2. ✅ No network connectivity during generation
3. ✅ No USB devices (except for transfer after generation)
4. ✅ Encrypted disk (BitLocker, LUKS, FileVault)
5. ✅ Physical security (private room, no cameras)

**Recommended:**

1. ✅ Fresh Tails OS or QubesOS installation
2. ✅ Air-gapped machine (never connected to network)
3. ✅ Hardware-verified boot (Secure Boot, measured boot)
4. ✅ Faraday cage for advanced threat protection
5. ✅ Write-once media for storage (BD-R, paper)

### Generation Process

**High-Security Generation Workflow:**

```bash
# 1. Boot into clean OS (Tails, Ubuntu live USB)
# 2. Verify checksum of wallet generator binary
sha256sum boundless-wallet
# Compare with published hash

# 3. Disconnect all network interfaces
sudo rfkill block all
sudo ip link set <interface> down

# 4. Disable swap (prevent key leakage to disk)
sudo swapoff -a

# 5. Generate wallet
./boundless-wallet init --keystore validator.enc

# 6. Write mnemonic on paper (see below)

# 7. Export public key to USB (read-only mount)
./boundless-wallet export pubkey --keystore validator.enc --output /mnt/usb/pubkey.txt

# 8. Secure shutdown (zeroes memory)
sudo shutdown -h now

# 9. Remove and store keystore media securely
```

### Memory Security

**Prevent private key leakage from RAM:**

1. **Zeroization:** Overwrite private keys after use

```rust
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(ZeroizeOnDrop)]
struct PrivateKey {
    bytes: Vec<u8>,
}

impl Drop for PrivateKey {
    fn drop(&mut self) {
        self.bytes.zeroize();  // Overwrites with zeros
    }
}
```

2. **No Swapping:** Lock memory pages to prevent swap

```rust
// Linux: mlock()
unsafe {
    libc::mlock(key_ptr, key_len);
}

// Entire process:
unsafe {
    libc::mlockall(libc::MCL_CURRENT | libc::MCL_FUTURE);
}
```

3. **Core Dump Prevention:**

```bash
# Disable core dumps for wallet process
ulimit -c 0

# System-wide (persist across reboots)
echo "* hard core 0" >> /etc/security/limits.conf
```

---

## Storage Security

### Mnemonic Backup

**Physical Storage (Recommended):**

1. **Metal Plates:**
   - Cryptosteel, Billfodl, or similar
   - Fire-resistant, water-resistant, crush-resistant
   - Stainless steel (not aluminum)
   - Store in fireproof safe

2. **Paper Backup (Less Durable):**
   - Archival-quality paper (acid-free)
   - Indelible ink (carbon-based, not water-soluble)
   - Lamination (heat-seal, not thermal)
   - Multiple copies in separate locations

3. **Shamir Secret Sharing (Advanced):**
   - Split mnemonic into M-of-N shares (e.g., 3-of-5)
   - Distribute shares to trusted parties/locations
   - Prevents single point of failure
   - Use SLIP-0039 standard

```python
# Example: 3-of-5 Shamir shares
from shamir_mnemonic import generate_mnemonics

# Split into 5 shares, need any 3 to recover
shares = generate_mnemonics(
    group_threshold=1,
    groups=[(3, 5)],  # 3-of-5
    master_secret=master_seed
)

# Store shares separately:
# Share 1 → Bank safe deposit box
# Share 2 → Home safe
# Share 3 → Trusted family member
# Share 4 → Lawyer/executor
# Share 5 → Secondary location
```

**NEVER:**
- ❌ Store mnemonic in password manager
- ❌ Take a photo of mnemonic
- ❌ Store on cloud storage (Google Drive, Dropbox, etc.)
- ❌ Email mnemonic to yourself
- ❌ Store in plaintext on computer

### Keystore Encryption

**AES-256-GCM Parameters:**

```json
{
  "cipher": "aes-256-gcm",
  "key_derivation": "argon2id",
  "argon2_params": {
    "memory": "64 MB",     // Memory-hard (resist ASICs)
    "iterations": 3,       // Time cost
    "parallelism": 4,      // Thread count
    "salt_length": 16      // Random per-keystore
  },
  "nonce": "96 bits",      // Random per-encryption
  "tag": "128 bits"        // Authentication tag
}
```

**Password Requirements:**

```
Minimum: 12 characters
Recommended: 20+ characters

Good password examples:
  - "correct-horse-battery-staple-78!Q"  (Diceware + random chars)
  - "MyBoundlessValidatorKey#2025!Secure"  (Passphrase + year + symbols)
  - Generated: "aK9#mP2$vL8@nQ5&jR7*"  (Random, store separately)

Bad passwords:
  - "password123"  (Common password)
  - "BoundlessWallet"  (Too short, no special chars)
  - "qwerty12345"  (Keyboard pattern)
```

**Password Storage:**

- Store in encrypted password manager (1Password, Bitwarden, KeePassXC)
- Physical backup in safe (separate from mnemonic)
- HSM-protected password (enterprise environments)

### File System Security

**Keystore File Protection:**

```bash
# Set restrictive permissions (owner read/write only)
chmod 600 keystore.enc

# Verify permissions
ls -l keystore.enc
# -rw------- 1 user user 1234 Jan 15 14:32 keystore.enc

# Store in encrypted directory
mkdir -p ~/.boundless
chmod 700 ~/.boundless
mv keystore.enc ~/.boundless/

# Optional: Encrypt entire home directory
# - Linux: ecryptfs, LUKS
# - macOS: FileVault
# - Windows: BitLocker
```

**Backup Verification:**

```bash
# Create backup
cp ~/.boundless/keystore.enc /mnt/backup/keystore_backup_2025-01-15.enc

# Verify backup integrity (compare hashes)
sha256sum ~/.boundless/keystore.enc
sha256sum /mnt/backup/keystore_backup_2025-01-15.enc

# Test restore (on isolated system)
boundless-wallet addr --keystore /mnt/backup/keystore_backup_2025-01-15.enc
# Should show correct address
```

---

## Operational Security (OpSec)

### Daily Operations

**Validator Key Management:**

1. **Hot Wallet:** Small amount for daily operations
2. **Warm Wallet:** Moderate amount, encrypted on server
3. **Cold Wallet:** Bulk of funds, offline storage

**Transaction Signing Workflow:**

```bash
# Online machine (no private keys)
1. Create unsigned transaction
   boundless-cli tx create --to <addr> --amount <amt> --output unsigned.tx

2. Transfer unsigned.tx to air-gapped machine (USB)

# Air-gapped machine (has private keys)
3. Sign transaction offline
   boundless-wallet sign --keystore validator.enc --message-file unsigned.tx --output signed.tx

4. Transfer signed.tx back to online machine (USB)

# Online machine
5. Broadcast signed transaction
   boundless-cli tx broadcast --file signed.tx
```

### Access Control

**Multi-Person Operations (for organizations):**

1. **Separation of Duties:**
   - Person A: Generates keystore
   - Person B: Knows password
   - Person C: Has physical access to storage
   - Requires 2-of-3 collaboration

2. **Audit Trail:**
   - Log all key operations (without exposing secrets)
   - Regular security audits
   - Video recording of key ceremony (stored securely)

3. **Time Locks:**
   - Implement delays for large transactions
   - Requires multiple approvals
   - Allows fraud detection window

---

## Air-Gap Security

### True Air-Gap Requirements

**Definition:** A computer that has NEVER been connected to a network and NEVER will be.

**Setup:**

1. **Hardware:**
   - Dedicated laptop/desktop (never used online)
   - Remove WiFi/Bluetooth modules physically
   - Disable network cards in BIOS
   - Use Faraday bag for storage

2. **Software:**
   - Install OS from verified media (DVD, USB)
   - Transfer wallet generator binary via USB
   - Verify checksums offline

3. **Data Transfer:**
   - Use write-protected USB drives
   - One-way data flow (online → air-gap → online)
   - Virus scan all media before insertion
   - QR codes for small data (public keys, addresses)

**Common Air-Gap Failures:**

- ❌ WiFi enabled but "not connected"
- ❌ Bluetooth not physically removed
- ❌ Printer with network/WiFi capability
- ❌ USB drives used bidirectionally without sanitization
- ❌ Air-gap machine with camera (privacy risk)

### QR Code Data Transfer

**For Public Keys and Addresses:**

```bash
# Generate QR code (on air-gap)
qrencode -o pubkey_qr.png < pubkey.txt

# Display on screen, scan with phone camera (offline phone)

# Or print to dumb printer (no network, no storage)
```

---

## HSM Integration

### Hardware Security Modules

**Benefits:**
- Private keys never leave HSM
- Tamper-resistant hardware
- Key generation inside HSM
- Audit logs for all operations
- FIPS 140-2 Level 3+ certification

**Supported HSMs (Future Integration):**

1. **YubiHSM 2:**
   - USB form factor
   - FIPS 140-2 Level 2
   - $650 USD
   - Supports Ed25519

2. **Nitrokey HSM 2:**
   - Open source firmware
   - SmartCard-HSM standard
   - €60-100 EUR
   - PKCS#11 interface

3. **Ledger Nano S/X:**
   - Consumer hardware wallet
   - Secure Element (CC EAL5+)
   - $79-149 USD
   - Custom app required

4. **Enterprise HSMs:**
   - Thales Luna Network HSM
   - AWS CloudHSM
   - Azure Dedicated HSM
   - $10,000-50,000+ USD

### HSM Integration Pattern

```rust
// Hypothetical HSM integration
use boundless_hsm::{HSM, SignRequest};

// Connect to HSM
let hsm = HSM::connect("/dev/hsm0", password)?;

// Generate key inside HSM (never exposed)
let key_id = hsm.generate_key(KeyType::Ed25519)?;

// Derive address from HSM public key
let public_key = hsm.export_public_key(key_id)?;
let address = derive_address(&public_key);

// Sign transaction using HSM
let tx_hash = transaction.signing_hash();
let signature = hsm.sign(SignRequest {
    key_id,
    message: tx_hash,
    algorithm: SignAlgorithm::Ed25519,
})?;
```

**HSM OpSec:**
- Physical security for HSM devices
- Backup HSM with same keys (M-of-N setup)
- HSM admin PINs in separate safe
- Regular HSM firmware updates
- Audit logs reviewed periodically

---

## Validator Security

### Validator Key Management

**Key Types:**

1. **Consensus Key:**
   - Used for block signing
   - Hot wallet (online server)
   - Rotated periodically

2. **Validator Identity Key:**
   - Proves validator ownership
   - Warm wallet (encrypted storage)
   - Used for consensus key rotation

3. **Withdrawal Key:**
   - Controls validator funds
   - Cold wallet (air-gapped)
   - Rarely used

**Key Rotation:**

```bash
# Generate new consensus key
boundless-wallet init --keystore consensus_new.enc

# Sign rotation transaction with identity key
boundless-validator rotate-key \
  --identity-key identity.enc \
  --new-consensus-key consensus_new.pub \
  --output rotation.tx

# Broadcast rotation
boundless-cli tx broadcast --file rotation.tx

# Update validator node with new key
boundless-node update-consensus-key consensus_new.enc
```

### Server Hardening

**Validator Server Security:**

1. **Network:**
   - Firewall: Only allow P2P port (e.g., 26656)
   - Rate limiting: Prevent DDoS
   - VPN: Sentry node architecture
   - No SSH from internet (bastion host only)

2. **OS Hardening:**
   - Minimal install (no GUI)
   - Automatic security updates
   - SELinux/AppArmor enabled
   - Disable unnecessary services

3. **Key Storage:**
   - Encrypted filesystem (LUKS)
   - Key stored in `/secure` mount (encrypted)
   - Loaded into memory on boot (manual unlock)
   - Never written to logs

4. **Monitoring:**
   - Alerting for unexpected restarts
   - Monitoring for unusual transactions
   - Audit logs for key access
   - Intrusion detection (OSSEC, Wazuh)

**Example systemd Unit (secure key loading):**

```ini
[Unit]
Description=Boundless Validator Node
After=network-online.target

[Service]
Type=simple
User=boundless
# Prompt for keystore password on boot
ExecStartPre=/usr/local/bin/unlock-validator-key.sh
ExecStart=/usr/local/bin/boundless-node \
  --keystore /secure/consensus.enc \
  --password-file /tmp/validator_password
# Delete password from disk after loading
ExecStartPost=/bin/rm -f /tmp/validator_password
Restart=on-failure

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/boundless

[Install]
WantedBy=multi-user.target
```

### Slashing Protection

**Prevent validator penalties:**

1. **Double Signing Prevention:**
   - Run only ONE validator instance per key
   - Use slashing protection database
   - Graceful failover (wait for timeout)

2. **Liveness Monitoring:**
   - Uptime monitoring (>95%)
   - Automatic alerting for downtime
   - Backup validator on standby (different key)

3. **Validator Backup:**
   - Secondary server with different consensus key
   - Switch via key rotation (not simultaneous operation)
   - Geographic diversity (different datacenter/region)

---

## Cold Storage Best Practices

### Long-Term Storage

**For users holding funds long-term:**

1. **Generation:**
   - Use Tails OS on air-gapped machine
   - Generate wallet with strong passphrase
   - Write mnemonic on metal plate

2. **Storage:**
   - Metal plate in bank safe deposit box
   - Copy #2 in home safe
   - Copy #3 with trusted executor (will)

3. **Verification:**
   - Test recovery BEFORE sending funds
   - Verify address matches public key
   - Small test transaction first

4. **Monitoring:**
   - Watch-only address in wallet app
   - Alerts for incoming/outgoing transactions
   - Periodic balance checks

### Estate Planning

**Ensure heirs can access funds:**

1. **Documentation:**
   - Letter of instruction (how to recover wallet)
   - Location of mnemonic backup
   - Passphrase hints (secure storage)

2. **Legal:**
   - Include in will or trust
   - Executor access to safe deposit box
   - Legal framework for crypto inheritance

3. **Testing:**
   - Practice recovery with trusted person
   - Update documentation if process changes
   - Regular reviews (annually)

---

## Incident Response

### Suspected Compromise

**Immediate Actions:**

1. **Stop using compromised key immediately**
2. **Generate new wallet on clean system**
3. **Transfer all funds to new address**
4. **Revoke compromised key (validator identity)**
5. **Investigate source of compromise**

**Post-Incident:**

1. Forensic analysis (what was exposed?)
2. Review logs and security practices
3. Update security procedures
4. Notify relevant parties (if validator)

### Key Recovery

**Lost Keystore File (have mnemonic):**

```bash
# Restore from mnemonic
boundless-wallet restore \
  --mnemonic "your 24 word mnemonic" \
  --keystore recovered.enc

# Verify address matches
boundless-wallet addr --keystore recovered.enc
```

**Lost Password (have mnemonic):**

```bash
# Same as above - generate new keystore
# Mnemonic is the ultimate backup
```

**Lost Mnemonic (catastrophic failure):**

- **No recovery possible**
- This is why multiple backups are critical
- Test recovery periodically

---

## Cryptographic Considerations

### Post-Quantum Cryptography

**Threat Timeline:**

- **2025-2030:** Large-scale quantum computers unlikely
- **2030-2035:** NISQ devices may break RSA/ECC
- **2035+:** Practical attacks on Ed25519 possible

**Boundless PQC Roadmap:**

1. **Phase 1 (Current):** Ed25519 (classical)
2. **Phase 2 (2026):** Hybrid (Ed25519 + ML-DSA-44)
3. **Phase 3 (2028):** Pure PQC (ML-DSA-44 or Falcon-512)

**Migration Strategy:**

```rust
// Current: Ed25519 only
signature = ed25519_sign(private_key, message);

// Future: Hybrid signatures
signature = HybridSignature {
    classical: ed25519_sign(ed25519_key, message),
    pqc: dilithium_sign(dilithium_key, message),
};

// Verification requires BOTH to pass
verify(signature) = verify_ed25519(sig.classical)
                    AND verify_dilithium(sig.pqc);
```

**User Impact:**
- Addresses will remain compatible (hash-based)
- Key rotation to PQC recommended by 2027
- Automatic migration for active validators

### Side-Channel Attacks

**Timing Attacks:**
- Use constant-time implementations
- ed25519-dalek has constant-time verification
- Avoid branching on secret data

**Power Analysis:**
- Less concern for software wallets
- Critical for HSM implementations
- Use HSMs with side-channel protections

**Cache Attacks:**
- Flush caches after key operations
- Use constant-time memory access patterns
- OS mitigations (KPTI, Spectre/Meltdown patches)

---

## Security Checklist

### Before Generation

- [ ] Clean OS install or Tails live USB
- [ ] Network disconnected and verified
- [ ] Verified wallet generator checksum
- [ ] Secure physical environment
- [ ] Mnemonic backup materials ready

### During Generation

- [ ] Entropy source verified (OS RNG)
- [ ] Mnemonic written down correctly (triple-check)
- [ ] Address generated and recorded
- [ ] Private key never displayed (unless --show-private)
- [ ] Test recovery before funding

### After Generation

- [ ] Mnemonic stored in fireproof safe (or metal backup)
- [ ] Keystore encrypted with strong password
- [ ] File permissions set to 600
- [ ] Backup keystore tested
- [ ] Secure disposal of generation media (if applicable)

### Operational

- [ ] Regular security audits
- [ ] Key rotation schedule (validators)
- [ ] Incident response plan documented
- [ ] Monitoring and alerting configured
- [ ] Backup restoration tested periodically

---

## Additional Resources

**Standards:**
- BIP39: Mnemonic code for generating deterministic keys
- NIST FIPS 204: ML-DSA (Dilithium)
- NIST FIPS 203: ML-KEM (Kyber)
- SLIP-0039: Shamir's Secret Sharing for mnemonics

**Tools:**
- Tails OS: https://tails.boum.org/
- QubesOS: https://www.qubes-os.org/
- Cryptosteel: https://cryptosteel.com/
- KeePassXC: https://keepassxc.org/

**Reading:**
- "Mastering Bitcoin" - Andreas Antonopoulos (key management chapters)
- NIST Post-Quantum Cryptography standards
- "Serious Cryptography" - Jean-Philippe Aumasson

---

## Contact

**Security Issues:** security@boundless.example (PGP key: [fingerprint])
**General Questions:** support@boundless.example

---

**Last Updated:** 2025-01-15
**Version:** 1.0.0
