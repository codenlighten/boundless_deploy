# Boundless Wallet Generator - Deployment Guide

## Recommended File Structure

Place the generated files in your Boundless project structure as follows:

```
boundless-bls-platform/
├── tools/
│   └── wallet/
│       ├── boundless_wallet_gen.rs       # Rust implementation
│       ├── boundless_wallet_gen.py       # Python implementation
│       ├── Cargo.toml                    # Rust dependencies
│       ├── requirements.txt              # Python dependencies
│       ├── README.md                     # Documentation
│       ├── CLI_SPECIFICATION.md          # Full CLI spec
│       ├── TEST_VECTORS.md               # Test vectors
│       ├── SECURITY.md                   # Security guide
│       └── DEPLOYMENT_GUIDE.md           # This file
│
├── crates/
│   └── wallet_cli/                       # Future: Full CLI implementation
│       ├── src/
│       │   ├── main.rs
│       │   ├── commands/
│       │   │   ├── init.rs
│       │   │   ├── addr.rs
│       │   │   ├── export.rs
│       │   │   ├── restore.rs
│       │   │   ├── sign.rs
│       │   │   └── verify.rs
│       │   ├── keystore.rs               # AES-256-GCM encrypted storage
│       │   └── lib.rs
│       ├── Cargo.toml
│       └── README.md
│
├── scripts/
│   └── keygen/
│       ├── local_wallet_gen.py           # Symlink to tools/wallet/boundless_wallet_gen.py
│       └── air_gap_setup.sh              # Air-gap machine setup script
│
└── docs/
    └── wallet/
        ├── getting-started.md
        ├── security-best-practices.md    # Symlink to tools/wallet/SECURITY.md
        └── validator-key-management.md
```

---

## Installation Options

### Option 1: Standalone Tool (Current)

Copy the single-file implementations to your preferred location:

```bash
# Create directory
mkdir -p ~/boundless-tools/wallet
cd ~/boundless-tools/wallet

# Copy files
cp boundless_wallet_gen.rs .
cp boundless_wallet_gen.py .
cp Cargo.toml .
cp requirements.txt .
cp *.md .

# Build Rust version
cargo build --release

# Install Python dependencies
pip install -r requirements.txt

# Test
cargo run --release -- generate --output test_wallet.json
python boundless_wallet_gen.py generate --output test_wallet.json
```

### Option 2: Integrated with Boundless Platform

If you have access to the Boundless platform repository:

```bash
# Navigate to platform root
cd /path/to/boundless-bls-platform

# Create wallet tools directory
mkdir -p tools/wallet

# Copy all files
cp /path/to/BLS_KeyGen/* tools/wallet/

# Add to workspace (edit boundless-bls-platform/Cargo.toml)
# [workspace]
# members = [
#     "tools/wallet",
#     # ... other members
# ]

# Build
cargo build --release -p boundless-wallet-gen

# Binary will be at:
# target/release/boundless-wallet-gen
```

### Option 3: System-wide Installation

Install as a system command:

```bash
# Build release binary
cargo build --release

# Install to system (Linux/macOS)
sudo cp target/release/boundless-wallet-gen /usr/local/bin/

# Or create symlink
sudo ln -s $(pwd)/target/release/boundless-wallet-gen /usr/local/bin/

# Verify
boundless-wallet-gen --version

# Python version
sudo cp boundless_wallet_gen.py /usr/local/bin/boundless-wallet-gen-py
sudo chmod +x /usr/local/bin/boundless-wallet-gen-py
```

---

## Building Static Binary (for Air-Gap)

For air-gapped machines, build a fully static binary with no dependencies:

### Linux (x86_64)

```bash
# Install musl target
rustup target add x86_64-unknown-linux-musl

# Build static binary
cargo build --release --target x86_64-unknown-linux-musl

# Verify it's static (should output "not a dynamic executable")
ldd target/x86_64-unknown-linux-musl/release/boundless-wallet-gen

# Copy to USB for air-gap transfer
cp target/x86_64-unknown-linux-musl/release/boundless-wallet-gen /media/usb/
```

### macOS (Universal Binary)

```bash
# Install targets
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build both architectures
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin

# Create universal binary
lipo -create \
  target/x86_64-apple-darwin/release/boundless-wallet-gen \
  target/aarch64-apple-darwin/release/boundless-wallet-gen \
  -output boundless-wallet-gen-universal

# Verify
file boundless-wallet-gen-universal
# Should show: Mach-O universal binary with 2 architectures
```

### Windows (MSVC Static)

```bash
# Build with static CRT
$env:RUSTFLAGS="-C target-feature=+crt-static"
cargo build --release --target x86_64-pc-windows-msvc

# Binary at: target\x86_64-pc-windows-msvc\release\boundless-wallet-gen.exe
```

---

## Verification (Checksums)

### Generate Checksums

After building, generate checksums for distribution:

```bash
# SHA256 checksums
sha256sum target/release/boundless-wallet-gen > checksums.txt
sha256sum boundless_wallet_gen.py >> checksums.txt
sha256sum boundless_wallet_gen.rs >> checksums.txt

# Sign checksums with GPG (for distribution)
gpg --clearsign checksums.txt
```

### Verify Before Use

Users should verify checksums before running:

```bash
# Download checksums.txt.asc from official source
gpg --verify checksums.txt.asc

# Verify binary
sha256sum -c checksums.txt
```

---

## Docker Container (Reproducible Builds)

Create a Docker image for reproducible builds:

**Dockerfile:**

```dockerfile
# Reproducible build environment
FROM rust:1.75-alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev

# Set working directory
WORKDIR /build

# Copy source
COPY boundless_wallet_gen.rs .
COPY Cargo.toml .
COPY Cargo.lock .

# Build static binary
RUN cargo build --release --target x86_64-unknown-linux-musl

# Runtime image (minimal)
FROM scratch
COPY --from=builder /build/target/x86_64-unknown-linux-musl/release/boundless-wallet-gen /boundless-wallet-gen

# Verify it's truly static
# Should have no dependencies

ENTRYPOINT ["/boundless-wallet-gen"]
```

**Build and Use:**

```bash
# Build Docker image
docker build -t boundless-wallet-gen:latest .

# Run (mount output directory)
docker run --rm \
  -v $(pwd)/output:/output \
  boundless-wallet-gen:latest \
  generate --output /output/wallet.json

# Extract binary for air-gap use
docker create --name temp boundless-wallet-gen:latest
docker cp temp:/boundless-wallet-gen ./boundless-wallet-gen-static
docker rm temp

# Verify checksum matches published hash
sha256sum boundless-wallet-gen-static
```

---

## Air-Gap Setup Script

Automate air-gap machine setup:

**air_gap_setup.sh:**

```bash
#!/bin/bash
set -e

echo "🔒 Boundless Air-Gap Wallet Setup"
echo "=================================="
echo ""

# 1. Verify network is disconnected
if ping -c 1 google.com &> /dev/null; then
    echo "❌ ERROR: Network is connected! Disconnect before proceeding."
    exit 1
fi
echo "✓ Network disconnected"

# 2. Disable network interfaces
echo "Disabling network interfaces..."
sudo rfkill block all
sudo ip link set $(ip link | grep -oP '^\d+: \K\w+' | grep -v lo) down 2>/dev/null || true
echo "✓ Network interfaces disabled"

# 3. Disable swap (prevent key leakage)
echo "Disabling swap..."
sudo swapoff -a
echo "✓ Swap disabled"

# 4. Verify wallet generator checksum
echo "Verifying wallet generator..."
EXPECTED_HASH="[insert published SHA256 here]"
ACTUAL_HASH=$(sha256sum boundless-wallet-gen | cut -d' ' -f1)

if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
    echo "❌ ERROR: Checksum mismatch!"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    exit 1
fi
echo "✓ Checksum verified"

# 5. Create secure output directory
echo "Creating secure directory..."
mkdir -p ~/.boundless_secure
chmod 700 ~/.boundless_secure
echo "✓ Secure directory created: ~/.boundless_secure"

echo ""
echo "✅ Air-gap setup complete!"
echo ""
echo "Next steps:"
echo "  1. Generate wallet: ./boundless-wallet-gen generate"
echo "  2. Write mnemonic on paper (triple-check each word)"
echo "  3. Export public key to USB: ./boundless-wallet-gen export pubkey"
echo "  4. Shut down securely: sudo shutdown -h now"
echo ""
```

---

## Testing Deployment

### Integration Test Script

**test_deployment.sh:**

```bash
#!/bin/bash
set -e

echo "🧪 Testing Boundless Wallet Deployment"
echo "======================================"

# Test 1: Generate wallet (Rust)
echo ""
echo "[1/5] Testing Rust wallet generation..."
./target/release/boundless-wallet-gen generate --output test_rust.json
if [ ! -f test_rust.json ]; then
    echo "❌ Failed: test_rust.json not created"
    exit 1
fi
echo "✓ Rust generation successful"

# Test 2: Generate wallet (Python)
echo ""
echo "[2/5] Testing Python wallet generation..."
python boundless_wallet_gen.py generate --output test_python.json
if [ ! -f test_python.json ]; then
    echo "❌ Failed: test_python.json not created"
    exit 1
fi
echo "✓ Python generation successful"

# Test 3: Restore wallet (Rust)
echo ""
echo "[3/5] Testing wallet restore..."
MNEMONIC=$(jq -r .mnemonic test_rust.json)
./target/release/boundless-wallet-gen restore \
    --mnemonic "$MNEMONIC" \
    --output test_restored.json
echo "✓ Wallet restore successful"

# Test 4: Verify address
echo ""
echo "[4/5] Testing address verification..."
PUBKEY=$(jq -r .public_key test_rust.json)
ADDRESS=$(jq -r .address test_rust.json)
./target/release/boundless-wallet-gen verify \
    --pubkey "$PUBKEY" \
    --address "$ADDRESS"
echo "✓ Address verification successful"

# Test 5: Cross-implementation compatibility
echo ""
echo "[5/5] Testing cross-implementation compatibility..."
MNEMONIC=$(jq -r .mnemonic test_rust.json)
python boundless_wallet_gen.py restore "$MNEMONIC" --output test_cross.json

RUST_ADDR=$(jq -r .address test_restored.json)
PYTHON_ADDR=$(jq -r .address test_cross.json)

if [ "$RUST_ADDR" != "$PYTHON_ADDR" ]; then
    echo "❌ Failed: Addresses don't match!"
    echo "Rust:   $RUST_ADDR"
    echo "Python: $PYTHON_ADDR"
    exit 1
fi
echo "✓ Cross-implementation compatibility verified"

# Cleanup
rm -f test_rust.json test_python.json test_restored.json test_cross.json

echo ""
echo "✅ All tests passed!"
echo ""
```

---

## Distribution Package

### Create Release Archive

```bash
#!/bin/bash

VERSION="0.1.0"
PACKAGE="boundless-wallet-gen-${VERSION}"

# Create package directory
mkdir -p "$PACKAGE"

# Copy files
cp boundless_wallet_gen.rs "$PACKAGE/"
cp boundless_wallet_gen.py "$PACKAGE/"
cp Cargo.toml "$PACKAGE/"
cp requirements.txt "$PACKAGE/"
cp README.md "$PACKAGE/"
cp CLI_SPECIFICATION.md "$PACKAGE/"
cp TEST_VECTORS.md "$PACKAGE/"
cp SECURITY.md "$PACKAGE/"
cp DEPLOYMENT_GUIDE.md "$PACKAGE/"

# Build binaries
cargo build --release
cp target/release/boundless-wallet-gen "$PACKAGE/boundless-wallet-gen-linux-x64"

cargo build --release --target x86_64-unknown-linux-musl
cp target/x86_64-unknown-linux-musl/release/boundless-wallet-gen "$PACKAGE/boundless-wallet-gen-linux-x64-static"

# Generate checksums
cd "$PACKAGE"
sha256sum * > SHA256SUMS
cd ..

# Create archive
tar czf "${PACKAGE}.tar.gz" "$PACKAGE"

# Sign (optional)
gpg --detach-sign --armor "${PACKAGE}.tar.gz"

echo "✅ Package created: ${PACKAGE}.tar.gz"
echo "   Signature: ${PACKAGE}.tar.gz.asc"
```

---

## Platform-Specific Notes

### Linux

```bash
# Install system-wide
sudo make install

# Or use package managers
# DEB package
cargo deb

# RPM package
cargo rpm build
```

### macOS

```bash
# Install via Homebrew (create formula)
brew tap boundless/tap
brew install boundless-wallet-gen

# Or manual install
sudo cp target/release/boundless-wallet-gen /usr/local/bin/
```

### Windows

```powershell
# Build
cargo build --release --target x86_64-pc-windows-msvc

# Install to user directory
Copy-Item target\release\boundless-wallet-gen.exe $env:USERPROFILE\bin\

# Add to PATH (PowerShell)
$env:PATH += ";$env:USERPROFILE\bin"
```

---

## CI/CD Integration

### GitHub Actions Example

**.github/workflows/build.yml:**

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable

      - name: Build
        run: cargo build --release

      - name: Run tests
        run: cargo test

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: boundless-wallet-gen-linux
          path: target/release/boundless-wallet-gen

  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: python boundless_wallet_gen.py --test
```

---

## Security Considerations

### Before Deployment

1. **Code Review:** Independent security review of all code
2. **Dependency Audit:** Check all dependencies for vulnerabilities
3. **Checksum Verification:** Publish official checksums
4. **Signature:** GPG-sign all release artifacts
5. **Documentation:** Comprehensive security documentation

### During Deployment

1. **Secure Channel:** Distribute via HTTPS, Tor, or physical media
2. **Verification:** Users must verify checksums before running
3. **Air-Gap:** Recommend air-gapped usage for high-value wallets
4. **Training:** Provide security training for validators

### After Deployment

1. **Updates:** Regular security updates
2. **Incident Response:** Clear process for vulnerability disclosure
3. **Monitoring:** Track usage and reported issues
4. **Audits:** Periodic third-party security audits

---

## Support

**Issues:** Report via GitHub Issues or security@boundless.example
**Documentation:** Full docs at docs.boundless.example/wallet
**Community:** Discord, Telegram, or Matrix

---

**Version:** 1.0.0
**Last Updated:** 2025-01-15
