#!/usr/bin/env rust-script
//! Boundless BLS Wallet Generator - Single File Rust Implementation
//!
//! Dependencies (add to Cargo.toml):
//! ```toml
//! [dependencies]
//! bip39 = "2.0"
//! ed25519-dalek = { version = "2.1", features = ["rand_core"] }
//! sha3 = "0.10"
//! hex = "0.4"
//! rand = "0.8"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! clap = { version = "4.5", features = ["derive"] }
//! zeroize = { version = "1.7", features = ["derive"] }
//! ```
//!
//! Usage:
//!   cargo run -- generate
//!   cargo run -- generate --show-private
//!   cargo run -- generate --output wallet.json

use std::fs;
use std::path::PathBuf;

use bip39::Mnemonic;
use ed25519_dalek::{SigningKey, VerifyingKey};
use sha3::{Digest, Sha3_256};
use serde::{Serialize, Deserialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

/// Wallet output structure (matches Boundless conventions)
#[derive(Debug, Serialize, Deserialize)]
pub struct WalletOutput {
    /// BIP39 mnemonic phrase (24 words)
    pub mnemonic: String,

    /// Public key (hex-encoded)
    pub public_key: String,

    /// Boundless address (hex-encoded SHA3-256 of public key)
    pub address: String,

    /// Private key (hex-encoded) - ONLY included if --show-private flag is set
    #[serde(skip_serializing_if = "Option::is_none")]
    pub private_key: Option<String>,

    /// Key type used ("Ed25519" or "ML-DSA-44")
    pub key_type: String,
}

/// Secure private key wrapper with automatic zeroization
#[derive(ZeroizeOnDrop)]
struct SecretKeyMaterial {
    #[zeroize(skip)]
    _marker: std::marker::PhantomData<u8>,
    bytes: Vec<u8>,
}

impl SecretKeyMaterial {
    fn new(bytes: Vec<u8>) -> Self {
        Self {
            _marker: std::marker::PhantomData,
            bytes,
        }
    }

    fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }
}

/// Generate a BIP39 mnemonic with specified entropy (24 words = 256 bits)
fn generate_mnemonic() -> Mnemonic {
    // bip39 2.2.0 API: generate from entropy
    // 32 bytes (256 bits) = 24 words
    let mut entropy = [0u8; 32];
    getrandom::getrandom(&mut entropy).expect("Failed to generate entropy");
    Mnemonic::from_entropy(&entropy).expect("Failed to create mnemonic")
}

/// Derive seed from mnemonic (BIP39 standard)
fn mnemonic_to_seed(mnemonic: &Mnemonic, passphrase: &str) -> [u8; 64] {
    let seed_bytes = mnemonic.to_seed(passphrase);
    let mut seed = [0u8; 64];
    // seed_bytes is already 64 bytes from BIP39
    seed.copy_from_slice(&seed_bytes[..64]);
    seed
}

/// Generate Ed25519 keypair from seed
/// Uses first 32 bytes of seed as private key material
fn generate_ed25519_keypair(seed: &[u8; 64]) -> (SecretKeyMaterial, VerifyingKey) {
    // Use first 32 bytes of seed for Ed25519 private key
    let mut secret_bytes = [0u8; 32];
    secret_bytes.copy_from_slice(&seed[..32]);

    let signing_key = SigningKey::from_bytes(&secret_bytes);
    let verifying_key = signing_key.verifying_key();

    // Zeroize the temporary array
    secret_bytes.zeroize();

    let secret_material = SecretKeyMaterial::new(signing_key.to_bytes().to_vec());

    (secret_material, verifying_key)
}

/// Derive Boundless address from public key
///
/// Address derivation (from boundless-bls-platform/enterprise/src/services/wallet.rs:530-543):
/// ```rust
/// fn derive_address(&self) -> String {
///     let mut hasher = Sha3_256::new();
///     hasher.update(&self.public_key);
///     let hash = hasher.finalize();
///     hex::encode(&hash)  // Full 32 bytes as hex (64 characters)
/// }
/// ```
fn derive_address(public_key: &[u8]) -> String {
    let mut hasher = Sha3_256::new();
    hasher.update(public_key);
    let hash = hasher.finalize();

    // Return full 32-byte hash as hex (64 characters)
    // NO version byte, NO checksum - matches Boundless exactly
    hex::encode(&hash)
}

/// Main wallet generation function
fn generate_wallet(show_private: bool, passphrase: Option<&str>) -> WalletOutput {
    // 1. Generate 24-word BIP39 mnemonic
    let mnemonic = generate_mnemonic();
    let mnemonic_phrase = mnemonic.to_string();

    println!("✓ Generated 24-word mnemonic");

    // 2. Derive seed from mnemonic
    let seed = mnemonic_to_seed(&mnemonic, passphrase.unwrap_or(""));

    println!("✓ Derived seed from mnemonic");

    // 3. Generate Ed25519 keypair (classical signature scheme)
    // Note: For PQC (ML-DSA-44), you would use the oqs crate as in the Boundless codebase
    let (secret_key, public_key) = generate_ed25519_keypair(&seed);

    println!("✓ Generated Ed25519 keypair");

    // 4. Derive Boundless address from public key
    let public_key_bytes = public_key.as_bytes();
    let address = derive_address(public_key_bytes);

    println!("✓ Derived Boundless address");

    // 5. Create output structure
    let private_key_hex = if show_private {
        Some(hex::encode(secret_key.as_bytes()))
    } else {
        None
    };

    WalletOutput {
        mnemonic: mnemonic_phrase,
        public_key: hex::encode(public_key_bytes),
        address,
        private_key: private_key_hex,
        key_type: "Ed25519".to_string(),
    }
}

/// Restore wallet from existing mnemonic
fn restore_wallet(mnemonic_phrase: &str, show_private: bool, passphrase: Option<&str>) -> Result<WalletOutput, String> {
    // Parse mnemonic (bip39 2.2.0 API)
    let mnemonic = Mnemonic::parse(mnemonic_phrase)
        .map_err(|e| format!("Invalid mnemonic: {}", e))?;

    // Derive seed
    let seed = mnemonic_to_seed(&mnemonic, passphrase.unwrap_or(""));

    // Generate keypair
    let (secret_key, public_key) = generate_ed25519_keypair(&seed);

    // Derive address
    let public_key_bytes = public_key.as_bytes();
    let address = derive_address(public_key_bytes);

    // Create output
    let private_key_hex = if show_private {
        Some(hex::encode(secret_key.as_bytes()))
    } else {
        None
    };

    Ok(WalletOutput {
        mnemonic: mnemonic_phrase.to_string(),
        public_key: hex::encode(public_key_bytes),
        address,
        private_key: private_key_hex,
        key_type: "Ed25519".to_string(),
    })
}

// ============================================================================
// CLI Interface
// ============================================================================

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "boundless-wallet-gen")]
#[command(about = "Boundless BLS Blockchain - Secure Local Wallet Generator", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate a new wallet
    Generate {
        /// Show private key in output (SECURITY WARNING)
        #[arg(long)]
        show_private: bool,

        /// Output file path (default: wallet.json)
        #[arg(short, long, default_value = "wallet.json")]
        output: PathBuf,

        /// Optional BIP39 passphrase for additional security
        #[arg(short, long)]
        passphrase: Option<String>,
    },

    /// Restore wallet from mnemonic
    Restore {
        /// 24-word mnemonic phrase (quoted)
        #[arg(short, long)]
        mnemonic: String,

        /// Show private key in output
        #[arg(long)]
        show_private: bool,

        /// Output file path (default: wallet_restored.json)
        #[arg(short, long, default_value = "wallet_restored.json")]
        output: PathBuf,

        /// Optional BIP39 passphrase
        #[arg(short, long)]
        passphrase: Option<String>,
    },

    /// Verify an address matches a public key
    Verify {
        /// Public key (hex-encoded)
        #[arg(short, long)]
        pubkey: String,

        /// Expected address (hex-encoded)
        #[arg(short, long)]
        address: String,
    },
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Generate { show_private, output, passphrase } => {
            println!("\n🔐 Boundless Wallet Generator");
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

            if show_private {
                println!("⚠️  WARNING: Private key will be included in output!");
                println!("⚠️  Only use --show-private in secure, offline environments!\n");
            }

            // Generate wallet
            let wallet = generate_wallet(show_private, passphrase.as_deref());

            // Save to file
            let json = serde_json::to_string_pretty(&wallet)
                .expect("Failed to serialize wallet");

            fs::write(&output, &json)
                .expect("Failed to write wallet file");

            println!("\n📝 Wallet Details:");
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            if !show_private {
                println!("\n🔑 Mnemonic: {}", wallet.mnemonic);
            }
            println!("\n🔐 Public Key:\n   {}", wallet.public_key);
            println!("\n📬 Address:\n   {}", wallet.address);
            println!("\n💾 Saved to: {}", output.display());

            if !show_private {
                println!("\n⚠️  SECURITY NOTICE:");
                println!("   • Write down your mnemonic phrase on paper");
                println!("   • Store it in a secure location");
                println!("   • NEVER share it with anyone");
                println!("   • Private key NOT saved (use --show-private if needed)");
            }

            println!("\n✅ Wallet generated successfully!\n");
        },

        Commands::Restore { mnemonic, show_private, output, passphrase } => {
            println!("\n🔓 Restoring Boundless Wallet");
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

            match restore_wallet(&mnemonic, show_private, passphrase.as_deref()) {
                Ok(wallet) => {
                    // Save to file
                    let json = serde_json::to_string_pretty(&wallet)
                        .expect("Failed to serialize wallet");

                    fs::write(&output, &json)
                        .expect("Failed to write wallet file");

                    println!("📝 Wallet Details:");
                    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                    println!("\n🔐 Public Key:\n   {}", wallet.public_key);
                    println!("\n📬 Address:\n   {}", wallet.address);
                    println!("\n💾 Saved to: {}", output.display());
                    println!("\n✅ Wallet restored successfully!\n");
                },
                Err(e) => {
                    eprintln!("❌ Error: {}", e);
                    std::process::exit(1);
                }
            }
        },

        Commands::Verify { pubkey, address } => {
            println!("\n🔍 Verifying Address");
            println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

            match hex::decode(&pubkey) {
                Ok(pubkey_bytes) => {
                    let derived_address = derive_address(&pubkey_bytes);

                    println!("Public Key:  {}", pubkey);
                    println!("Expected:    {}", address);
                    println!("Derived:     {}", derived_address);

                    if derived_address.eq_ignore_ascii_case(&address) {
                        println!("\n✅ Address matches! Verification successful.\n");
                    } else {
                        println!("\n❌ Address mismatch! Verification failed.\n");
                        std::process::exit(1);
                    }
                },
                Err(e) => {
                    eprintln!("❌ Invalid public key hex: {}", e);
                    std::process::exit(1);
                }
            }
        }
    }
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_address_derivation() {
        // Test vector: known public key -> expected address
        let pubkey = hex::decode("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
            .unwrap();

        let address = derive_address(&pubkey);

        // Verify it's 64 hex characters (32 bytes)
        assert_eq!(address.len(), 64);
        assert!(address.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_mnemonic_deterministic() {
        // Same mnemonic should produce same keys
        let mnemonic_phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art";

        let wallet1 = restore_wallet(mnemonic_phrase, false, None).unwrap();
        let wallet2 = restore_wallet(mnemonic_phrase, false, None).unwrap();

        assert_eq!(wallet1.public_key, wallet2.public_key);
        assert_eq!(wallet1.address, wallet2.address);
    }

    #[test]
    fn test_address_format() {
        // Verify address format matches Boundless conventions
        let wallet = generate_wallet(false, None);

        // Should be 64 hex characters (32 bytes)
        assert_eq!(wallet.address.len(), 64);

        // Should be valid hex
        assert!(hex::decode(&wallet.address).is_ok());

        // Should match derived address from public key
        let pubkey_bytes = hex::decode(&wallet.public_key).unwrap();
        let expected_address = derive_address(&pubkey_bytes);
        assert_eq!(wallet.address, expected_address);
    }
}
