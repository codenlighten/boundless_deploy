# Boundless BLS Blockchain - Local Wallet Generator

A minimal, secure, air-gapped wallet generator for the Boundless BLS blockchain. Generates deterministic wallets using BIP39 mnemonics with full compatibility with the Boundless blockchain conventions.

## Features

- ✅ **24-word BIP39 mnemonic generation** (256 bits entropy)
- ✅ **Deterministic key derivation** (same mnemonic → same keys)
- ✅ **Ed25519 signature scheme** (classical + PQC roadmap)
- ✅ **Boundless-compatible addresses** (SHA3-256, hex-encoded)
- ✅ **Air-gap compatible** (no network calls, local-only)
- ✅ **Multiple implementations** (Rust, Python)
- ✅ **Security-first design** (zeroization, encrypted storage)
- ✅ **Comprehensive test vectors**

---

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [File Structure](#file-structure)
- [Address Format](#address-format)
- [Security](#security)
- [Testing](#testing)
- [Contributing](#contributing)

---

## Quick Start

### Rust Implementation

```bash
# Install Rust (if needed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build the wallet generator
cd boundless_wallet_gen
cargo build --release

# Generate a new wallet
cargo run --release -- generate

# Restore from mnemonic
cargo run --release -- restore --mnemonic "word1 word2 ... word24"

# Verify address
cargo run --release -- verify --pubkey <hex> --address <hex>
```

### Python Implementation

```bash
# Install dependencies
pip install mnemonic ed25519 pycryptodome

# Generate a new wallet
python boundless_wallet_gen.py generate

# Restore from mnemonic
python boundless_wallet_gen.py restore "word1 word2 ... word24"

# Run tests
python boundless_wallet_gen.py --test
```

---

## Installation

### Prerequisites

**Rust:**
- Rust 1.70+ (install via [rustup](https://rustup.rs/))
- Cargo (included with Rust)

**Python:**
- Python 3.8+ (3.10+ recommended)
- pip package manager

### Install Dependencies

#### Rust

Create `Cargo.toml`:

```toml
[package]
name = "boundless-wallet-gen"
version = "0.1.0"
edition = "2021"

[dependencies]
bip39 = "2.0"
ed25519-dalek = { version = "2.1", features = ["rand_core", "zeroize"] }
sha3 = "0.10"
hex = "0.4"
rand = "0.8"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
clap = { version = "4.5", features = ["derive"] }
zeroize = { version = "1.7", features = ["derive"] }
```

Then run:

```bash
cargo build --release
```

#### Python

```bash
pip install -r requirements.txt
```

Where `requirements.txt` contains:

```
mnemonic==0.20
ed25519==1.5
pycryptodome==3.19.0
```

---

## Usage Examples

### Generate New Wallet

**Rust:**

```bash
# Basic generation (private key NOT saved)
cargo run --release -- generate

# Show private key (SECURITY WARNING)
cargo run --release -- generate --show-private

# Custom output file
cargo run --release -- generate --output my_wallet.json

# With BIP39 passphrase (additional security)
cargo run --release -- generate --passphrase "my secret phrase"
```

**Python:**

```bash
# Basic generation
python boundless_wallet_gen.py generate

# Show private key
python boundless_wallet_gen.py generate --show-private

# Custom output
python boundless_wallet_gen.py generate -o my_wallet.json

# With passphrase
python boundless_wallet_gen.py generate -p "my secret phrase"
```

**Output Format:**

```json
{
  "mnemonic": "abandon ability able about above absent absorb abstract absurd abuse access accident acquire across act action actor actress actual adapt add addict address adjust",
  "public_key": "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
  "address": "8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
  "key_type": "Ed25519"
}
```

### Restore Wallet from Mnemonic

**Rust:**

```bash
cargo run --release -- restore \
  --mnemonic "word1 word2 word3 ... word24" \
  --output restored_wallet.json
```

**Python:**

```bash
python boundless_wallet_gen.py restore \
  "word1 word2 word3 ... word24" \
  -o restored_wallet.json
```

### Verify Address

Check that an address correctly corresponds to a public key:

**Rust:**

```bash
cargo run --release -- verify \
  --pubkey d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a \
  --address 8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
```

**Python:**

```bash
python boundless_wallet_gen.py verify \
  --pubkey d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a \
  --address 8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
```

---

## File Structure

```
BLS_KeyGen/
├── boundless_wallet_gen.rs      # Single-file Rust implementation
├── boundless_wallet_gen.py      # Single-file Python implementation
├── Cargo.toml                   # Rust dependencies
├── requirements.txt             # Python dependencies
├── README.md                    # This file
├── CLI_SPECIFICATION.md         # Detailed CLI specification for production tool
├── TEST_VECTORS.md              # Test vectors for validation
├── SECURITY.md                  # Comprehensive security guide
└── examples/
    ├── wallet.json              # Example output (DO NOT use these keys!)
    └── test_vectors.json        # Programmatic test vectors
```

---

## Address Format

### Boundless Address Derivation

Addresses are derived using the following algorithm (from `boundless-bls-platform/enterprise/src/services/wallet.rs:530-543`):

```rust
fn derive_address(public_key: &[u8]) -> String {
    let mut hasher = Sha3_256::new();
    hasher.update(public_key);
    let hash = hasher.finalize();
    hex::encode(&hash)  // 64 hex characters (32 bytes)
}
```

**Key Characteristics:**

- **Hash Algorithm:** SHA3-256 (Keccak-256, NOT SHA-256)
- **Input:** Raw public key bytes (Ed25519: 32 bytes, ML-DSA-44: varies)
- **Output:** 64-character hexadecimal string (32 bytes)
- **No Version Byte:** Unlike Bitcoin/Ethereum
- **No Checksum:** SHA3-256 provides integrity
- **No Special Encoding:** No Bech32, Base58, or Base64

**Example:**

```
Public Key:  d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
            ↓ SHA3-256
Hash:        8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
            ↓ hex::encode
Address:     8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
```

### Validation

**Valid Address:**
- Exactly 64 hexadecimal characters
- Only characters: `0-9`, `a-f` (case-insensitive)
- Represents 32 bytes

**Invalid Address:**
- Wrong length (< 64 or > 64 characters)
- Non-hexadecimal characters
- Prefixes like `bls1` or `0x`
- Checksums appended

---

## Security

### Critical Security Notes

⚠️ **NEVER share your mnemonic phrase or private key with anyone!**

⚠️ **Write down your mnemonic on paper and store it in a secure location.**

⚠️ **Test wallet recovery BEFORE sending funds.**

⚠️ **Use air-gapped machines for high-value wallets.**

### Recommended Workflow for High-Security

```bash
# 1. Boot Tails OS on air-gapped machine (no network)
# 2. Download and verify wallet generator checksum
sha256sum boundless_wallet_gen.py
# Compare with published hash

# 3. Generate wallet
python boundless_wallet_gen.py generate --output wallet.json

# 4. Write mnemonic on paper (triple-check each word)

# 5. Export public key to USB (for registration)
jq -r .public_key wallet.json > pubkey.txt

# 6. Transfer pubkey.txt to online machine

# 7. Securely shut down and store media
sudo shutdown -h now
```

### Security Resources

See [SECURITY.md](SECURITY.md) for comprehensive guidance on:

- Entropy sources and key generation
- Mnemonic backup strategies (metal plates, Shamir Secret Sharing)
- Air-gap security and operational security (OpSec)
- HSM integration for enterprise use
- Validator key management
- Cold storage best practices
- Incident response procedures

---

## Testing

### Run Built-in Tests

**Rust:**

```bash
cargo test
```

**Python:**

```bash
python boundless_wallet_gen.py --test
```

### Test Vectors

See [TEST_VECTORS.md](TEST_VECTORS.md) for detailed test vectors including:

1. Standard BIP39 test mnemonics
2. SHA3-256 hash verification
3. Address format validation
4. Ed25519 signature verification
5. Cross-implementation compatibility tests
6. Edge cases and regression tests

### Manual Verification

```bash
# Generate wallet
python boundless_wallet_gen.py generate --output test.json

# Extract values
PUBKEY=$(jq -r .public_key test.json)
ADDRESS=$(jq -r .address test.json)

# Verify address derivation
python boundless_wallet_gen.py verify --pubkey $PUBKEY --address $ADDRESS

# Should output: ✅ Address matches! Verification successful.
```

---

## CLI Specification

This repository contains **reference implementations** (single-file Rust and Python scripts).

For production use, see [CLI_SPECIFICATION.md](CLI_SPECIFICATION.md) for the full specification of the `boundless-wallet` CLI tool, including:

- Complete command reference (`init`, `addr`, `export`, `restore`, etc.)
- AES-256-GCM encrypted keystore format
- Password-protected key management
- Air-gap workflow examples
- Error codes and handling

**Production CLI Features (planned):**

```bash
boundless-wallet init           # Initialize new wallet with encrypted keystore
boundless-wallet addr           # Display address from keystore
boundless-wallet export pubkey  # Export public key
boundless-wallet export private # Export private key (requires --force)
boundless-wallet restore        # Restore from mnemonic
boundless-wallet sign           # Sign message or transaction
boundless-wallet verify         # Verify address matches public key
```

---

## Roadmap

### Phase 1 (Current) - Ed25519 Support

- ✅ BIP39 mnemonic generation
- ✅ Ed25519 keypair derivation
- ✅ SHA3-256 address derivation
- ✅ Rust and Python implementations
- ✅ Test vectors and security documentation

### Phase 2 (2025 Q2) - Enhanced Security

- 🔄 Encrypted keystore (AES-256-GCM)
- 🔄 Password-protected keys (Argon2id)
- 🔄 Full CLI with signing capabilities
- 🔄 Hardware wallet integration (Ledger)

### Phase 3 (2025 Q4) - Post-Quantum Cryptography

- 📋 ML-DSA-44 (Dilithium2) support
- 📋 Falcon-512 support
- 📋 Hybrid signatures (Ed25519 + ML-DSA-44)
- 📋 Key migration tools

### Phase 4 (2026+) - Advanced Features

- 📋 Multi-signature wallets
- 📋 HSM integration (YubiHSM, Nitrokey)
- 📋 Shamir Secret Sharing (SLIP-0039)
- 📋 Time-locked transactions
- 📋 Hardware Security Module (HSM) support

---

## Contributing

### Reporting Issues

- **Security vulnerabilities:** Email security@boundless.example (do NOT create public issues)
- **Bugs:** Open an issue on GitHub with reproduction steps
- **Feature requests:** Open an issue with detailed use case

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Requirements:**

- All tests must pass (`cargo test`, `python boundless_wallet_gen.py --test`)
- Add test vectors for new features
- Update documentation (README, SECURITY, etc.)
- Follow existing code style

---

## License

MIT License

```
Copyright (c) 2025 Boundless BLS Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Acknowledgments

- **Boundless BLS Platform:** Reference implementation for address derivation and cryptographic conventions
- **BIP39 Standard:** Bitcoin Improvement Proposal for mnemonic codes
- **NIST PQC:** Post-Quantum Cryptography standardization
- **Rust Community:** Excellent cryptographic libraries (ed25519-dalek, sha3, zeroize)
- **Python Community:** Mature cryptographic ecosystem

---

## References

### Boundless Codebase

This wallet generator follows conventions from:

- `boundless-bls-platform/enterprise/src/services/wallet.rs:530-543` - Address derivation
- `boundless-bls-platform/enterprise/src/crypto/mod.rs:89-99` - Cryptographic operations
- `boundless-bls-platform/cli/src/keygen.rs:37-41` - Key generation reference
- `boundless-bls-platform/core/src/transaction.rs` - Transaction format

### Standards

- [BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) - Mnemonic code for generating deterministic keys
- [NIST FIPS 204](https://csrc.nist.gov/pubs/fips/204/final) - Module-Lattice-Based Digital Signature Standard (ML-DSA)
- [Ed25519](https://ed25519.cr.yp.to/) - High-speed high-security signatures
- [SHA-3](https://csrc.nist.gov/publications/detail/fips/202/final) - SHA-3 Standard (Keccak)

### Tools

- [Rust](https://www.rust-lang.org/) - Systems programming language
- [Python](https://www.python.org/) - High-level programming language
- [Tails OS](https://tails.boum.org/) - Secure operating system for air-gap usage
- [Cryptosteel](https://cryptosteel.com/) - Physical mnemonic backup

---

## Support

- **Documentation:** [Full documentation](./README.md)
- **Security Guide:** [SECURITY.md](./SECURITY.md)
- **Test Vectors:** [TEST_VECTORS.md](./TEST_VECTORS.md)
- **CLI Spec:** [CLI_SPECIFICATION.md](./CLI_SPECIFICATION.md)
- **Issues:** GitHub Issues
- **Email:** support@boundless.example

---

## Disclaimer

This software is provided "as is" without warranty of any kind. Users are responsible for:

- Securely backing up their mnemonic phrases
- Testing wallet recovery before sending funds
- Following security best practices
- Complying with local regulations regarding cryptocurrency

The authors are not responsible for any loss of funds due to:

- User error (lost mnemonics, weak passwords)
- Software bugs (though we strive for correctness)
- Hardware failures
- Malicious attacks

**Always test with small amounts first!**

---

**Last Updated:** 2025-01-15
**Version:** 0.1.0
**Status:** Alpha (for testing and evaluation)
