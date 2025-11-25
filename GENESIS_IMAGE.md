# SOVRN Genesis Image - Download & Verification

## Image Information

- **Filename:** `boundless-bls-node-package-complete.tar.gz`
- **Size:** 46 MB (48,234,496 bytes)
- **MD5 Checksum:** `e0d87277251b1896444259c8671c6de4`
- **Format:** Gzip-compressed tar archive
- **Contains:** SOVRN Genesis Authority Docker image
- **Image Name:** `boundless-mainnet:genesis`
- **Source:** Downloaded from SOVRN (159.203.114.205)

## Download Options

### Option 1: Official Package Method (Recommended by Bryan)

Download the Docker image directly from SOVRN:

```bash
# SSH into SOVRN and stream the image
ssh root@159.203.114.205 "docker save boundless-mainnet:genesis | gzip" > boundless-mainnet-genesis.tar.gz

# Load the image
gunzip -c boundless-mainnet-genesis.tar.gz | docker load

# Verify
docker images | grep boundless-mainnet
```

**Benefits:**
- Direct from genesis authority
- Always latest version
- Guaranteed integrity
- No git corruption issues

### Option 2: Git Clone (Bundled)

The image is bundled with the repository:

```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
```

**Verify integrity:**
```bash
md5sum boundless-bls-node-package-complete.tar.gz
# Expected: acd7ecd0ccef4a86efa85b2d3178ece6
```

**If corrupted during clone:**
```bash
# Remove corrupted file
rm boundless-bls-node-package-complete.tar.gz

# Re-download just this file
git checkout HEAD -- boundless-bls-node-package-complete.tar.gz

# Or use Git LFS if available
git lfs pull
```

### Option 2: Direct Download from GitHub Releases

If the bundled file is corrupted, download directly:

```bash
# Download from GitHub release (if published)
curl -L -o boundless-bls-node-package-complete.tar.gz \
  https://github.com/codenlighten/boundless_deploy/releases/download/v1.0/boundless-bls-node-package-complete.tar.gz

# Verify checksum
md5sum boundless-bls-node-package-complete.tar.gz
```

### Option 3: SCP from SOVRN Authority

Direct download from the genesis authority server:

```bash
scp root@159.203.114.205:/tmp/boundless-mainnet-genesis.tar.gz boundless-bls-node-package-complete.tar.gz

# Verify it loads
file boundless-bls-node-package-complete.tar.gz
```

### Option 4: Use Alternate CDN/Mirror

```bash
# If a mirror is available (update URL as needed)
curl -O https://downloads.boundlesstrust.org/boundless-bls-node-package-complete.tar.gz

# Verify checksum
md5sum boundless-bls-node-package-complete.tar.gz
```

## Verification Steps

### 1. Check File Size
```bash
ls -lh boundless-bls-node-package-complete.tar.gz
# Should show: ~46M
```

### 2. Check File Type
```bash
file boundless-bls-node-package-complete.tar.gz
# Should show: gzip compressed data
```

### 3. Verify Checksum
```bash
md5sum boundless-bls-node-package-complete.tar.gz
# Should match: acd7ecd0ccef4a86efa85b2d3178ece6
```

### 4. Test Extraction
```bash
# Test gzip integrity
gunzip -t boundless-bls-node-package-complete.tar.gz
# Should complete without errors
```

### 5. Verify Docker Image Contents
```bash
# Load and check
gunzip -c boundless-bls-node-package-complete.tar.gz | docker load

# Verify image exists
docker images | grep boundless-mainnet
# Should show: boundless-mainnet:genesis
```

## Troubleshooting

### "unexpected EOF" Error

**Cause:** File is corrupted or incomplete

**Solutions:**
1. Delete corrupted file: `rm boundless-bls-node-package-complete.tar.gz`
2. Re-download using one of the options above
3. Verify checksum after download
4. Try SCP from SOVRN directly

### File Too Small

**Cause:** Git clone may have truncated the file

**Solutions:**
1. Check file size: `ls -lh boundless-bls-node-package-complete.tar.gz`
2. Should be ~46MB (48,234,496 bytes)
3. If smaller, delete and re-download
4. Use `git lfs` if repository uses Git LFS

### Checksum Mismatch

**Cause:** File corrupted during transfer

**Solutions:**
1. Delete file
2. Re-download from different source
3. Verify network connection is stable
4. Try SCP from SOVRN (most reliable)

## Manual Image Load

If you have the correct file:

```bash
# Load with gzip decompression
gunzip -c boundless-bls-node-package-complete.tar.gz | docker load

# Or if already decompressed
docker load < boundless-mainnet-genesis.tar

# Verify
docker images | grep boundless-mainnet
```

## Alternative: Build from Source

If image download continues to fail:

```bash
# Clone Boundless source
git clone https://github.com/boundless/boundless-bls-blockchain.git
cd boundless-bls-blockchain

# Build Docker image
docker build -t boundless-mainnet:genesis .

# No download needed - built locally
```

## Contact Support

If you continue having issues:

- **Email:** verify@boundlesstrust.org
- **Issue Tracker:** https://github.com/codenlighten/boundless_deploy/issues
- **Network Status:** https://traceboundless.com

---

**Note:** The `start_boundless_node.sh` script automatically detects and uses this file when present in the workspace.
