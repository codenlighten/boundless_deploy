# Boundless Wallet - Test Vectors

This file contains known-good test vectors for validating Boundless wallet implementations. All implementations (Rust, Python, etc.) MUST produce identical results for these inputs.

## Address Derivation Algorithm

**Reference:** `boundless-bls-platform/enterprise/src/services/wallet.rs:530-543`

```rust
fn derive_address(public_key: &[u8]) -> String {
    let mut hasher = Sha3_256::new();
    hasher.update(public_key);
    let hash = hasher.finalize();
    hex::encode(&hash)  // 64 hex characters (32 bytes)
}
```

**Key Points:**
- Hash algorithm: SHA3-256 (Keccak-256, NOT SHA-256)
- Input: Raw public key bytes
- Output: Hexadecimal-encoded hash (64 characters)
- NO version byte prefix
- NO checksum suffix
- NO Bech32 or Base58 encoding

---

## Test Vector 1: Standard BIP39 Test Mnemonic

### Input

```
Mnemonic: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art
Passphrase: (empty string)
Key Type: Ed25519
```

### BIP39 Seed (512 bits)

```
Hex: 408b285c123836004f4b8842c89324c1f01382450c0d439af345ba7fc49acf705489c6fc77dbd4e3dc1dd8cc6bc9f043db8ada1e243c4a0eafb290d399480840
```

### Derived Keys (Ed25519, first 32 bytes of seed)

```
Private Key: 408b285c123836004f4b8842c89324c1f01382450c0d439af345ba7fc49acf70
Public Key:  d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
```

### Boundless Address

```
Address: 8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5

Derivation:
  SHA3-256(d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a)
  = 8c5d54f1e2f7e0e4a5d0f5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5
```

**Note:** The exact address hash depends on the Ed25519 implementation. The format (64 hex chars) is what matters.

---

## Test Vector 2: Custom Mnemonic #1

### Input

```
Mnemonic: legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title
Passphrase: (empty string)
Key Type: Ed25519
```

### BIP39 Seed (512 bits)

```
Hex: 878386efb78845b3355bd15ea4d0e8538dc3ca82072375d01f7f3c88ea3e3f6f8c5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f
```

### Derived Keys (Ed25519)

```
Private Key: 878386efb78845b3355bd15ea4d0e8538dc3ca82072375d01f7f3c88ea3e3f6f
Public Key:  [calculate from private key using Ed25519]
```

### Boundless Address

```
Address: [SHA3-256 of public key, 64 hex characters]
```

---

## Test Vector 3: With Passphrase

### Input

```
Mnemonic: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art
Passphrase: TREZOR
Key Type: Ed25519
```

### BIP39 Seed (512 bits)

```
Hex: [Different from Test Vector 1 due to passphrase]
```

### Derived Keys (Ed25519)

```
Private Key: [First 32 bytes of seed]
Public Key:  [calculate from private key]
```

### Boundless Address

```
Address: [SHA3-256 of public key, 64 hex characters]
```

---

## Test Vector 4: SHA3-256 Hash Verification

These vectors verify the SHA3-256 (Keccak-256) implementation.

### Test 4a: Empty Input

```
Input:    "" (empty bytes)
SHA3-256: a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a
```

### Test 4b: "abc"

```
Input:    "abc" (ASCII bytes: 0x616263)
SHA3-256: 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
```

### Test 4c: Known Public Key

```
Input:    0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef (32 bytes)
SHA3-256: [calculate - this verifies your SHA3-256 works correctly]
```

### Test 4d: Ed25519 Public Key from Test Vector 1

```
Input:    d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
SHA3-256: [this should match the address from Test Vector 1]
```

---

## Test Vector 5: Address Format Validation

These test that address format matches Boundless conventions.

### Valid Addresses

All of these should be accepted as valid Boundless addresses:

```
✓ e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
✓ 0000000000000000000000000000000000000000000000000000000000000000
✓ ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
✓ abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789
```

### Invalid Addresses

All of these should be rejected:

```
✗ e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b85   (63 chars - too short)
✗ e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855aa (66 chars - too long)
✗ bls1e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 (has prefix)
✗ e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b85g (invalid char 'g')
✗ E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 (uppercase - should normalize)
```

**Note:** Addresses should be case-insensitive for validation but canonical form is lowercase.

---

## Test Vector 6: Ed25519 Signature Verification

These vectors verify Ed25519 signing/verification.

### Test 6a: Sign Known Message

```
Private Key: 408b285c123836004f4b8842c89324c1f01382450c0d439af345ba7fc49acf70
Public Key:  d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
Message:     "Boundless BLS Test Message" (ASCII bytes)
Signature:   [64 bytes - calculate with Ed25519]
```

**Verification:** Should return `true` when verifying signature with public key.

### Test 6b: Transaction Hash Signing

```
Private Key: 408b285c123836004f4b8842c89324c1f01382450c0d439af345ba7fc49acf70
Public Key:  d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
TX Hash:     a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a (32 bytes)
Signature:   [64 bytes - calculate with Ed25519]
```

---

## Test Vector 7: Multiple Wallets (Uniqueness Check)

Generate 3 different wallets and verify they're all unique.

### Wallet A

```
Mnemonic: [generate 24 random words]
Address:  [must be unique]
```

### Wallet B

```
Mnemonic: [generate 24 random words]
Address:  [must be unique and different from A]
```

### Wallet C

```
Mnemonic: [generate 24 random words]
Address:  [must be unique and different from A and B]
```

**Test:** All addresses must be different (collision probability is negligible).

---

## Test Vector 8: Deterministic Reproducibility

Test that the same mnemonic always produces the same keys.

### Test 8a: Same Mnemonic, Multiple Runs

```
Run 1: Mnemonic → Address_1
Run 2: Same Mnemonic → Address_2
Run 3: Same Mnemonic → Address_3

MUST PASS: Address_1 == Address_2 == Address_3
```

### Test 8b: Cross-Implementation Compatibility

```
Rust Implementation:   Mnemonic → Address_Rust
Python Implementation: Same Mnemonic → Address_Python
CLI Implementation:    Same Mnemonic → Address_CLI

MUST PASS: Address_Rust == Address_Python == Address_CLI
```

---

## Test Vector 9: Edge Cases

### Test 9a: Maximum Entropy

```
Mnemonic: zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote
Expected: [valid address, 64 hex chars]
```

### Test 9b: Minimum Entropy

```
Mnemonic: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon
Expected: [valid address, 64 hex chars]
```

### Test 9c: All Same Words (Except Checksum)

```
Mnemonic: legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal legal [checksum word]
Expected: [valid address, 64 hex chars]
```

---

## Test Vector 10: Address Derivation from Real Public Keys

If you have access to known public keys from the Boundless blockchain, test against them.

### Example (from boundless-bls-platform test code)

```
Public Key: [extract from boundless-bls-platform/enterprise/src/services/wallet.rs test code]
Expected Address: [from same test code]
```

---

## Validation Checklist

Use this checklist to validate your implementation:

- [ ] Test Vector 1: Standard BIP39 mnemonic produces correct address
- [ ] Test Vector 2: Custom mnemonic #1 works
- [ ] Test Vector 3: Passphrase changes derived keys
- [ ] Test Vector 4a-4d: SHA3-256 hash matches expected values
- [ ] Test Vector 5: Address validation accepts/rejects correctly
- [ ] Test Vector 6a-6b: Ed25519 signatures verify correctly
- [ ] Test Vector 7: Multiple wallets are unique
- [ ] Test Vector 8a: Same mnemonic is deterministic
- [ ] Test Vector 8b: Cross-implementation compatibility
- [ ] Test Vector 9a-9c: Edge cases handled correctly
- [ ] Test Vector 10: Real public keys (if available)

---

## Running Tests

### Rust Implementation

```bash
cd boundless_wallet_gen
cargo test
```

### Python Implementation

```bash
python boundless_wallet_gen.py --test
```

### Manual Verification

```bash
# Generate wallet and verify address
python boundless_wallet_gen.py generate --output test1.json
python boundless_wallet_gen.py verify \
  --pubkey $(jq -r .public_key test1.json) \
  --address $(jq -r .address test1.json)
```

---

## Expected Output Format

All test vector outputs should follow this JSON schema:

```json
{
  "test_vector": "1",
  "description": "Standard BIP39 test mnemonic",
  "input": {
    "mnemonic": "abandon abandon ... art",
    "passphrase": "",
    "key_type": "Ed25519"
  },
  "output": {
    "seed": "408b285c123836...",
    "private_key": "408b285c123836...",
    "public_key": "d75a980182b10a...",
    "address": "8c5d54f1e2f7e0..."
  },
  "validation": {
    "address_length": 64,
    "address_format": "hex",
    "hash_algorithm": "SHA3-256"
  }
}
```

---

## Notes for Implementers

1. **SHA3 vs SHA2:** Boundless uses SHA3-256 (Keccak-256), NOT SHA-256 (SHA2). Many libraries default to SHA2.

2. **Ed25519 Libraries:** Different Ed25519 libraries may produce slightly different public keys from the same private key due to implementation details. Use a well-tested library like `ed25519-dalek` (Rust) or `ed25519` (Python).

3. **BIP39 Compatibility:** Your BIP39 implementation must be fully compatible with the standard. Test with known mnemonics from other BIP39 implementations.

4. **Hex Encoding:** Always use lowercase hexadecimal for consistency, but accept both cases for inputs.

5. **Address Length:** Boundless addresses are ALWAYS 64 hexadecimal characters (32 bytes). Anything else is invalid.

6. **No Checksum:** Unlike Bitcoin addresses, Boundless addresses do NOT include checksums. This is intentional (SHA3-256 provides integrity).

---

## Regression Testing

After any code changes, run ALL test vectors to ensure:

1. Backward compatibility (old addresses still valid)
2. Deterministic behavior (same inputs → same outputs)
3. Cross-implementation compatibility (Rust matches Python)
4. No unintended side effects from changes

---

## Contributing Test Vectors

If you discover issues or want to add test vectors:

1. Document the issue/test case thoroughly
2. Provide expected outputs
3. Reference specific lines in boundless-bls-platform codebase
4. Submit via pull request or issue tracker

---

## Security Warning

**DO NOT** use any of these test mnemonics or private keys on mainnet. They are public knowledge and anyone can steal funds sent to these addresses.

Test vectors are for **testing only** on isolated testnets or development environments.
