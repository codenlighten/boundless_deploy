#!/usr/bin/env python3
"""
Boundless BLS Wallet Generator - Single File Python Implementation

This script generates deterministic wallets for the Boundless BLS blockchain.
It follows the exact conventions from the Boundless codebase:
    - Address = hex(SHA3-256(public_key))
    - No version bytes, no checksum
    - 64-character hexadecimal addresses

Dependencies:
    pip install mnemonic ed25519 pycryptodome

Usage:
    python boundless_wallet_gen.py generate
    python boundless_wallet_gen.py generate --show-private
    python boundless_wallet_gen.py restore "word1 word2 ... word24"
    python boundless_wallet_gen.py verify --pubkey <hex> --address <hex>
"""

import sys
import json
import hashlib
import secrets
import argparse
from pathlib import Path
from typing import Dict, Optional, Tuple

try:
    from mnemonic import Mnemonic
    from Crypto.Hash import SHA3_256
    from nacl.signing import SigningKey
    from nacl.encoding import RawEncoder
except ImportError as e:
    print("Missing dependency:", str(e))
    print("\nInstall required packages:")
    print("  pip install mnemonic PyNaCl pycryptodome")
    sys.exit(1)


# ============================================================================
# Boundless Address Derivation
# ============================================================================

def derive_address(public_key_bytes: bytes) -> str:
    """
    Derive Boundless address from public key.

    Matches the exact implementation in boundless-bls-platform:
    - Location: enterprise/src/services/wallet.rs:530-543
    - Algorithm: SHA3-256(public_key) -> hex encoding
    - No version byte, no checksum

    Args:
        public_key_bytes: Raw public key bytes

    Returns:
        64-character hexadecimal address (32 bytes)
    """
    # Use SHA3-256 (Keccak-256)
    hasher = SHA3_256.new()
    hasher.update(public_key_bytes)
    hash_bytes = hasher.digest()

    # Return full 32-byte hash as hex (64 characters)
    return hash_bytes.hex()


# ============================================================================
# Key Generation
# ============================================================================

def generate_mnemonic() -> str:
    """
    Generate a 24-word BIP39 mnemonic phrase.

    Returns:
        24-word mnemonic phrase (256 bits of entropy)
    """
    mnemo = Mnemonic("english")
    # 256 bits = 24 words
    return mnemo.generate(strength=256)


def mnemonic_to_seed(mnemonic_phrase: str, passphrase: str = "") -> bytes:
    """
    Convert BIP39 mnemonic to seed (512 bits / 64 bytes).

    Args:
        mnemonic_phrase: 24-word mnemonic
        passphrase: Optional BIP39 passphrase for additional security

    Returns:
        64-byte seed
    """
    mnemo = Mnemonic("english")

    # Validate mnemonic
    if not mnemo.check(mnemonic_phrase):
        raise ValueError("Invalid mnemonic phrase")

    # Derive seed using BIP39 standard
    seed = mnemo.to_seed(mnemonic_phrase, passphrase)
    return seed


def generate_ed25519_keypair(seed: bytes) -> Tuple[bytes, bytes]:
    """
    Generate Ed25519 keypair from seed.

    Uses first 32 bytes of seed as private key material.

    Args:
        seed: 64-byte seed from mnemonic

    Returns:
        Tuple of (private_key_bytes, public_key_bytes)
    """
    # Use first 32 bytes of seed for Ed25519 private key
    private_key_bytes = seed[:32]

    # Generate Ed25519 signing key using PyNaCl
    signing_key = SigningKey(private_key_bytes)
    verify_key = signing_key.verify_key

    # Return raw key bytes
    return bytes(signing_key), bytes(verify_key)


# ============================================================================
# Wallet Generation
# ============================================================================

def generate_wallet(show_private: bool = False, passphrase: str = "") -> Dict[str, str]:
    """
    Generate a new Boundless wallet.

    Args:
        show_private: Whether to include private key in output
        passphrase: Optional BIP39 passphrase

    Returns:
        Dictionary containing wallet data
    """
    print("✓ Generating 24-word mnemonic...")
    mnemonic_phrase = generate_mnemonic()

    print("✓ Deriving seed from mnemonic...")
    seed = mnemonic_to_seed(mnemonic_phrase, passphrase)

    print("✓ Generating Ed25519 keypair...")
    private_key, public_key = generate_ed25519_keypair(seed)

    print("✓ Deriving Boundless address...")
    address = derive_address(public_key)

    # Build wallet output
    wallet = {
        "mnemonic": mnemonic_phrase,
        "public_key": public_key.hex(),
        "address": address,
        "key_type": "Ed25519"
    }

    if show_private:
        wallet["private_key"] = private_key.hex()

    return wallet


def restore_wallet(mnemonic_phrase: str, show_private: bool = False, passphrase: str = "") -> Dict[str, str]:
    """
    Restore wallet from mnemonic phrase.

    Args:
        mnemonic_phrase: 24-word mnemonic
        show_private: Whether to include private key in output
        passphrase: Optional BIP39 passphrase

    Returns:
        Dictionary containing wallet data
    """
    print("✓ Validating mnemonic...")
    seed = mnemonic_to_seed(mnemonic_phrase, passphrase)

    print("✓ Regenerating Ed25519 keypair...")
    private_key, public_key = generate_ed25519_keypair(seed)

    print("✓ Deriving Boundless address...")
    address = derive_address(public_key)

    # Build wallet output
    wallet = {
        "mnemonic": mnemonic_phrase,
        "public_key": public_key.hex(),
        "address": address,
        "key_type": "Ed25519"
    }

    if show_private:
        wallet["private_key"] = private_key.hex()

    return wallet


# ============================================================================
# Address Verification
# ============================================================================

def verify_address(pubkey_hex: str, expected_address: str) -> bool:
    """
    Verify that an address matches a public key.

    Args:
        pubkey_hex: Hexadecimal-encoded public key
        expected_address: Expected address

    Returns:
        True if address matches
    """
    try:
        pubkey_bytes = bytes.fromhex(pubkey_hex)
        derived_address = derive_address(pubkey_bytes)
        return derived_address.lower() == expected_address.lower()
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


# ============================================================================
# CLI Interface
# ============================================================================

def cmd_generate(args):
    """Handle 'generate' command."""
    print("\n🔐 Boundless Wallet Generator")
    print("━" * 60)

    if args.show_private:
        print("\n⚠️  WARNING: Private key will be included in output!")
        print("⚠️  Only use --show-private in secure, offline environments!\n")

    # Generate wallet
    wallet = generate_wallet(
        show_private=args.show_private,
        passphrase=args.passphrase or ""
    )

    # Save to file
    output_path = Path(args.output)
    with open(output_path, 'w') as f:
        json.dump(wallet, f, indent=2)

    # Display wallet info
    print("\n📝 Wallet Details:")
    print("━" * 60)
    if not args.show_private:
        print(f"\n🔑 Mnemonic:\n   {wallet['mnemonic']}")
    print(f"\n🔐 Public Key:\n   {wallet['public_key']}")
    print(f"\n📬 Address:\n   {wallet['address']}")
    print(f"\n💾 Saved to: {output_path}")

    if not args.show_private:
        print("\n⚠️  SECURITY NOTICE:")
        print("   • Write down your mnemonic phrase on paper")
        print("   • Store it in a secure location")
        print("   • NEVER share it with anyone")
        print("   • Private key NOT saved (use --show-private if needed)")

    print("\n✅ Wallet generated successfully!\n")


def cmd_restore(args):
    """Handle 'restore' command."""
    print("\n🔓 Restoring Boundless Wallet")
    print("━" * 60 + "\n")

    try:
        # Restore wallet
        wallet = restore_wallet(
            mnemonic_phrase=args.mnemonic,
            show_private=args.show_private,
            passphrase=args.passphrase or ""
        )

        # Save to file
        output_path = Path(args.output)
        with open(output_path, 'w') as f:
            json.dump(wallet, f, indent=2)

        # Display wallet info
        print("\n📝 Wallet Details:")
        print("━" * 60)
        print(f"\n🔐 Public Key:\n   {wallet['public_key']}")
        print(f"\n📬 Address:\n   {wallet['address']}")
        print(f"\n💾 Saved to: {output_path}")
        print("\n✅ Wallet restored successfully!\n")

    except ValueError as e:
        print(f"\n❌ Error: {e}\n")
        sys.exit(1)


def cmd_verify(args):
    """Handle 'verify' command."""
    print("\n🔍 Verifying Address")
    print("━" * 60 + "\n")

    pubkey_bytes = bytes.fromhex(args.pubkey)
    derived_address = derive_address(pubkey_bytes)

    print(f"Public Key:  {args.pubkey}")
    print(f"Expected:    {args.address}")
    print(f"Derived:     {derived_address}")

    if derived_address.lower() == args.address.lower():
        print("\n✅ Address matches! Verification successful.\n")
    else:
        print("\n❌ Address mismatch! Verification failed.\n")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Boundless BLS Blockchain - Secure Local Wallet Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Generate command
    gen_parser = subparsers.add_parser('generate', help='Generate a new wallet')
    gen_parser.add_argument('--show-private', action='store_true',
                           help='Show private key in output (SECURITY WARNING)')
    gen_parser.add_argument('-o', '--output', default='wallet.json',
                           help='Output file path (default: wallet.json)')
    gen_parser.add_argument('-p', '--passphrase',
                           help='Optional BIP39 passphrase for additional security')

    # Restore command
    restore_parser = subparsers.add_parser('restore', help='Restore wallet from mnemonic')
    restore_parser.add_argument('mnemonic', help='24-word mnemonic phrase (in quotes)')
    restore_parser.add_argument('--show-private', action='store_true',
                               help='Show private key in output')
    restore_parser.add_argument('-o', '--output', default='wallet_restored.json',
                               help='Output file path (default: wallet_restored.json)')
    restore_parser.add_argument('-p', '--passphrase',
                               help='Optional BIP39 passphrase')

    # Verify command
    verify_parser = subparsers.add_parser('verify', help='Verify an address matches a public key')
    verify_parser.add_argument('--pubkey', required=True,
                              help='Public key (hex-encoded)')
    verify_parser.add_argument('--address', required=True,
                              help='Expected address (hex-encoded)')

    args = parser.parse_args()

    if args.command == 'generate':
        cmd_generate(args)
    elif args.command == 'restore':
        cmd_restore(args)
    elif args.command == 'verify':
        cmd_verify(args)
    else:
        parser.print_help()
        sys.exit(1)


# ============================================================================
# Tests
# ============================================================================

def run_tests():
    """Run basic tests."""
    print("\n🧪 Running Tests...")
    print("━" * 60)

    # Test 1: Address derivation
    print("\n[Test 1] Address derivation format")
    test_pubkey = bytes.fromhex("1234567890abcdef" * 4)
    address = derive_address(test_pubkey)
    assert len(address) == 64, "Address should be 64 hex characters"
    assert all(c in '0123456789abcdef' for c in address.lower()), "Address should be valid hex"
    print("  ✓ Address format correct (64 hex chars)")

    # Test 2: Deterministic generation
    print("\n[Test 2] Deterministic wallet generation")
    test_mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
    wallet1 = restore_wallet(test_mnemonic, show_private=False, passphrase="")
    wallet2 = restore_wallet(test_mnemonic, show_private=False, passphrase="")
    assert wallet1['public_key'] == wallet2['public_key'], "Public keys should match"
    assert wallet1['address'] == wallet2['address'], "Addresses should match"
    print("  ✓ Same mnemonic produces same keys")

    # Test 3: Address verification
    print("\n[Test 3] Address verification")
    pubkey_hex = wallet1['public_key']
    address = wallet1['address']
    assert verify_address(pubkey_hex, address), "Address should verify"
    print("  ✓ Address verification works")

    print("\n✅ All tests passed!\n")


if __name__ == "__main__":
    # Run tests if --test flag is provided
    if len(sys.argv) > 1 and sys.argv[1] == '--test':
        run_tests()
    else:
        main()
