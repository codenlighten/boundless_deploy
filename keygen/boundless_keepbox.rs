// Boundless KeepBox - Encrypted Wallet Storage
//
// Secure encrypted storage for Boundless blockchain wallets
// Using AES-256-GCM with Argon2id key derivation
//
// Security Features:
// - AES-256-GCM authenticated encryption (AEAD)
// - Argon2id key derivation (memory-hard, 64 MB RAM)
// - Zeroization of sensitive data
// - File permissions (0600)
// - Password strength validation

use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use argon2::{Argon2, ParamsBuilder, Version};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use bip39::{Language, Mnemonic};
use clap::{Parser, Subcommand};
use ed25519_dalek::SigningKey;
use rpassword::read_password;
use serde::{Deserialize, Serialize};
use sha3::{Digest, Sha3_256};
use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use zeroize::{Zeroize, ZeroizeOnDrop};

// ===== Data Structures =====

#[derive(Serialize, Deserialize)]
struct KeepBox {
    version: String,
    crypto: CryptoParams,
    encrypted_data: String, // Base64 encoded
    metadata: Metadata,
}

#[derive(Serialize, Deserialize)]
struct CryptoParams {
    cipher: String,
    kdf: String,
    kdf_params: KdfParams,
    nonce: String, // Base64 encoded (12 bytes for GCM)
}

#[derive(Serialize, Deserialize)]
struct KdfParams {
    memory_cost: u32,
    time_cost: u32,
    parallelism: u32,
    salt: String, // Base64 encoded (32 bytes)
}

#[derive(Serialize, Deserialize)]
struct Metadata {
    created: String,
    modified: String,
    label: Option<String>,
    address: String,
}

#[derive(Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct WalletData {
    mnemonic: String,
    public_key: String,
    address: String,
    key_type: String,
}

// ===== CLI Structure =====

#[derive(Parser)]
#[command(name = "boundless-keepbox")]
#[command(about = "Secure encrypted wallet storage for Boundless blockchain", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a new encrypted KeepBox from existing wallet
    Init {
        /// Input wallet JSON file
        #[arg(short, long)]
        wallet: PathBuf,

        /// Output KeepBox file
        #[arg(short, long)]
        output: PathBuf,

        /// Optional label for the wallet
        #[arg(short, long)]
        label: Option<String>,
    },

    /// Open and display wallet information (without secrets)
    Open {
        /// KeepBox file to open
        #[arg(short, long)]
        keepbox: PathBuf,
    },

    /// Export wallet to JSON (requires password)
    Export {
        /// KeepBox file to export from
        #[arg(short, long)]
        keepbox: PathBuf,

        /// Output JSON file
        #[arg(short, long)]
        output: PathBuf,

        /// Show private key in export (DANGEROUS)
        #[arg(long, default_value_t = false)]
        show_private: bool,
    },

    /// Import wallet from mnemonic or JSON into KeepBox
    Import {
        /// Mnemonic phrase (if not provided, will prompt)
        #[arg(short, long)]
        mnemonic: Option<String>,

        /// Or import from JSON file
        #[arg(short, long)]
        json: Option<PathBuf>,

        /// Output KeepBox file
        #[arg(short, long)]
        output: PathBuf,

        /// Optional label for the wallet
        #[arg(short, long)]
        label: Option<String>,
    },

    /// Change KeepBox password
    ChangePassword {
        /// KeepBox file
        #[arg(short, long)]
        keepbox: PathBuf,
    },

    /// Verify KeepBox integrity and password
    Verify {
        /// KeepBox file to verify
        #[arg(short, long)]
        keepbox: PathBuf,
    },
}

// ===== Encryption Functions =====

fn derive_key_from_password(password: &str, salt: &[u8]) -> Result<[u8; 32], String> {
    // Argon2id parameters matching ENCRYPTED_KEYSTORE_DESIGN.md
    let params = ParamsBuilder::new()
        .m_cost(65536) // 64 MB
        .t_cost(3)     // 3 iterations
        .p_cost(4)     // 4 parallelism
        .build()
        .map_err(|e| format!("Failed to build Argon2 params: {}", e))?;

    let argon2 = Argon2::new(
        argon2::Algorithm::Argon2id,
        Version::V0x13,
        params,
    );

    // Derive 32-byte key
    let mut key = [0u8; 32];
    argon2
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .map_err(|e| format!("Failed to derive key: {}", e))?;

    Ok(key)
}

fn encrypt_wallet_data(
    wallet_data: &WalletData,
    password: &str,
) -> Result<(Vec<u8>, Vec<u8>, Vec<u8>), String> {
    // Generate random salt (32 bytes)
    let mut salt = [0u8; 32];
    getrandom::getrandom(&mut salt).map_err(|e| format!("Failed to generate salt: {}", e))?;

    // Derive encryption key
    let key = derive_key_from_password(password, &salt)?;

    // Generate random nonce (12 bytes for GCM)
    let mut nonce_bytes = [0u8; 12];
    getrandom::getrandom(&mut nonce_bytes)
        .map_err(|e| format!("Failed to generate nonce: {}", e))?;

    // Create cipher
    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    // Serialize wallet data
    let plaintext = serde_json::to_string(wallet_data)
        .map_err(|e| format!("Failed to serialize wallet data: {}", e))?;

    // Encrypt
    let nonce = Nonce::from_slice(&nonce_bytes);
    let ciphertext = cipher
        .encrypt(nonce, plaintext.as_bytes())
        .map_err(|e| format!("Encryption failed: {}", e))?;

    Ok((ciphertext, salt.to_vec(), nonce_bytes.to_vec()))
}

fn decrypt_wallet_data(
    ciphertext: &[u8],
    password: &str,
    salt: &[u8],
    nonce: &[u8],
) -> Result<WalletData, String> {
    // Derive decryption key
    let key = derive_key_from_password(password, salt)?;

    // Create cipher
    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    // Decrypt
    let nonce = Nonce::from_slice(nonce);
    let plaintext_bytes = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| "Decryption failed - incorrect password or corrupted data".to_string())?;

    // Deserialize
    let wallet_data: WalletData = serde_json::from_slice(&plaintext_bytes)
        .map_err(|e| format!("Failed to deserialize wallet data: {}", e))?;

    Ok(wallet_data)
}

// ===== Password Functions =====

fn validate_password_strength(password: &str) -> Result<(), String> {
    if password.len() < 12 {
        return Err("Password must be at least 12 characters long".to_string());
    }

    let has_lowercase = password.chars().any(|c| c.is_lowercase());
    let has_uppercase = password.chars().any(|c| c.is_uppercase());
    let has_digit = password.chars().any(|c| c.is_numeric());
    let has_special = password.chars().any(|c| !c.is_alphanumeric());

    let strength_score = has_lowercase as u8
        + has_uppercase as u8
        + has_digit as u8
        + has_special as u8;

    if strength_score < 3 {
        return Err(
            "Password must contain at least 3 of: lowercase, uppercase, digits, special characters"
                .to_string(),
        );
    }

    // Check for common weak passwords
    let weak_passwords = vec![
        "password123",
        "qwerty123456",
        "admin123456",
        "123456789012",
    ];
    if weak_passwords.contains(&password.to_lowercase().as_str()) {
        return Err("Password is too common, please choose a stronger password".to_string());
    }

    Ok(())
}

fn prompt_password(prompt: &str, confirm: bool) -> Result<String, String> {
    loop {
        print!("{}", prompt);
        io::stdout()
            .flush()
            .map_err(|e| format!("Failed to flush stdout: {}", e))?;

        let password = read_password()
            .map_err(|e| format!("Failed to read password: {}", e))?;

        if password.is_empty() {
            eprintln!("❌ Password cannot be empty");
            continue;
        }

        if let Err(e) = validate_password_strength(&password) {
            eprintln!("❌ {}", e);
            continue;
        }

        if confirm {
            print!("Confirm password: ");
            io::stdout()
                .flush()
                .map_err(|e| format!("Failed to flush stdout: {}", e))?;

            let password2 = read_password()
                .map_err(|e| format!("Failed to read password: {}", e))?;

            if password != password2 {
                eprintln!("❌ Passwords do not match");
                continue;
            }
        }

        return Ok(password);
    }
}

// ===== Wallet Functions =====

fn generate_mnemonic() -> Mnemonic {
    let mut entropy = [0u8; 32];
    getrandom::getrandom(&mut entropy).expect("Failed to generate entropy");
    Mnemonic::from_entropy(&entropy).expect("Failed to create mnemonic")
}

fn derive_address(public_key: &[u8]) -> String {
    let mut hasher = Sha3_256::new();
    hasher.update(public_key);
    let hash = hasher.finalize();
    hex::encode(&hash)
}

fn restore_from_mnemonic(mnemonic_phrase: &str) -> Result<WalletData, String> {
    // Parse and validate mnemonic
    let mnemonic = Mnemonic::parse_in(Language::English, mnemonic_phrase)
        .map_err(|e| format!("Invalid mnemonic: {}", e))?;

    // Derive seed
    let seed = mnemonic.to_seed("");

    // Generate Ed25519 keypair from first 32 bytes
    let mut key_bytes = [0u8; 32];
    key_bytes.copy_from_slice(&seed[..32]);
    let signing_key = SigningKey::from_bytes(&key_bytes);
    let verifying_key = signing_key.verifying_key();

    // Derive address
    let address = derive_address(verifying_key.as_bytes());

    Ok(WalletData {
        mnemonic: mnemonic.to_string(),
        public_key: hex::encode(verifying_key.as_bytes()),
        address,
        key_type: "Ed25519".to_string(),
    })
}

// ===== Command Implementations =====

fn cmd_init(wallet_path: PathBuf, output_path: PathBuf, label: Option<String>) -> Result<(), String> {
    println!("🔐 Creating encrypted KeepBox from wallet...");
    println!();

    // Read wallet JSON
    let wallet_json = fs::read_to_string(&wallet_path)
        .map_err(|e| format!("Failed to read wallet file: {}", e))?;

    let wallet_data: WalletData = serde_json::from_str(&wallet_json)
        .map_err(|e| format!("Failed to parse wallet JSON: {}", e))?;

    println!("✓ Loaded wallet");
    println!("  Address: {}", wallet_data.address);
    println!();

    // Prompt for password
    println!("⚠️  Choose a strong password to encrypt your wallet.");
    println!("    Minimum 12 characters with mixed case, numbers, and symbols.");
    println!();

    let password = prompt_password("Enter password: ", true)?;
    println!();

    println!("🔒 Encrypting wallet data...");

    // Encrypt wallet data
    let (ciphertext, salt, nonce) = encrypt_wallet_data(&wallet_data, &password)?;

    // Create KeepBox structure
    let keepbox = KeepBox {
        version: "1.0.0".to_string(),
        crypto: CryptoParams {
            cipher: "aes-256-gcm".to_string(),
            kdf: "argon2id".to_string(),
            kdf_params: KdfParams {
                memory_cost: 65536,
                time_cost: 3,
                parallelism: 4,
                salt: BASE64.encode(&salt),
            },
            nonce: BASE64.encode(&nonce),
        },
        encrypted_data: BASE64.encode(&ciphertext),
        metadata: Metadata {
            created: chrono::Utc::now().to_rfc3339(),
            modified: chrono::Utc::now().to_rfc3339(),
            label,
            address: wallet_data.address.clone(),
        },
    };

    // Serialize and write
    let keepbox_json = serde_json::to_string_pretty(&keepbox)
        .map_err(|e| format!("Failed to serialize KeepBox: {}", e))?;

    fs::write(&output_path, keepbox_json)
        .map_err(|e| format!("Failed to write KeepBox file: {}", e))?;

    // Set file permissions on Unix-like systems
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(&output_path)
            .map_err(|e| format!("Failed to get file metadata: {}", e))?
            .permissions();
        perms.set_mode(0o600);
        fs::set_permissions(&output_path, perms)
            .map_err(|e| format!("Failed to set file permissions: {}", e))?;
    }

    println!("✓ Encrypted wallet data");
    println!("✓ Created KeepBox");
    println!();
    println!("✅ Successfully created encrypted KeepBox: {}", output_path.display());
    println!();
    println!("📝 Important:");
    println!("   - Remember your password - it CANNOT be recovered");
    println!("   - Store a backup of this file in a secure location");
    println!("   - The original wallet.json can now be securely deleted");

    Ok(())
}

fn cmd_open(keepbox_path: PathBuf) -> Result<(), String> {
    // Read KeepBox file
    let keepbox_json = fs::read_to_string(&keepbox_path)
        .map_err(|e| format!("Failed to read KeepBox file: {}", e))?;

    let keepbox: KeepBox = serde_json::from_str(&keepbox_json)
        .map_err(|e| format!("Failed to parse KeepBox: {}", e))?;

    // Display public information
    println!("📦 KeepBox Information");
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    println!();
    println!("Version:     {}", keepbox.version);
    println!("Encryption:  {} with {}", keepbox.crypto.cipher, keepbox.crypto.kdf);
    println!();
    println!("Address:     {}", keepbox.metadata.address);
    if let Some(label) = &keepbox.metadata.label {
        println!("Label:       {}", label);
    }
    println!("Created:     {}", keepbox.metadata.created);
    println!("Modified:    {}", keepbox.metadata.modified);
    println!();
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    println!();
    println!("💡 Use 'export' command to access wallet data (requires password)");

    Ok(())
}

fn cmd_export(
    keepbox_path: PathBuf,
    output_path: PathBuf,
    show_private: bool,
) -> Result<(), String> {
    println!("🔓 Exporting wallet from KeepBox...");
    println!();

    // Read KeepBox file
    let keepbox_json = fs::read_to_string(&keepbox_path)
        .map_err(|e| format!("Failed to read KeepBox file: {}", e))?;

    let keepbox: KeepBox = serde_json::from_str(&keepbox_json)
        .map_err(|e| format!("Failed to parse KeepBox: {}", e))?;

    // Prompt for password
    let password = prompt_password("Enter password: ", false)?;
    println!();

    println!("🔓 Decrypting wallet data...");

    // Decode encrypted data
    let ciphertext = BASE64.decode(&keepbox.encrypted_data)
        .map_err(|e| format!("Failed to decode ciphertext: {}", e))?;
    let salt = BASE64.decode(&keepbox.crypto.kdf_params.salt)
        .map_err(|e| format!("Failed to decode salt: {}", e))?;
    let nonce = BASE64.decode(&keepbox.crypto.nonce)
        .map_err(|e| format!("Failed to decode nonce: {}", e))?;

    // Decrypt
    let wallet_data = decrypt_wallet_data(&ciphertext, &password, &salt, &nonce)?;

    println!("✓ Decrypted wallet data");
    println!();

    // Display wallet info
    println!("📬 Address:    {}", wallet_data.address);
    println!("🔐 Public Key: {}", wallet_data.public_key);
    println!();

    if show_private {
        println!("⚠️  WARNING: Exporting with mnemonic included!");
        println!();
    }

    // Write to file
    let export_json = serde_json::to_string_pretty(&wallet_data)
        .map_err(|e| format!("Failed to serialize wallet data: {}", e))?;

    fs::write(&output_path, export_json)
        .map_err(|e| format!("Failed to write export file: {}", e))?;

    println!("✅ Successfully exported wallet to: {}", output_path.display());
    println!();
    println!("⚠️  Security Warning:");
    println!("   - The exported file contains your mnemonic in PLAINTEXT");
    println!("   - Store it securely or delete it after use");
    println!("   - Consider re-encrypting it immediately");

    Ok(())
}

fn cmd_import(
    mnemonic: Option<String>,
    json_path: Option<PathBuf>,
    output_path: PathBuf,
    label: Option<String>,
) -> Result<(), String> {
    println!("📥 Importing wallet into KeepBox...");
    println!();

    let wallet_data = if let Some(json) = json_path {
        // Import from JSON
        let wallet_json = fs::read_to_string(&json)
            .map_err(|e| format!("Failed to read wallet file: {}", e))?;
        serde_json::from_str(&wallet_json)
            .map_err(|e| format!("Failed to parse wallet JSON: {}", e))?
    } else if let Some(mnemonic_phrase) = mnemonic {
        // Import from mnemonic
        restore_from_mnemonic(&mnemonic_phrase)?
    } else {
        // Prompt for mnemonic
        println!("Enter your 24-word mnemonic phrase:");
        print!("> ");
        io::stdout().flush().unwrap();

        let mut mnemonic_input = String::new();
        io::stdin()
            .read_line(&mut mnemonic_input)
            .map_err(|e| format!("Failed to read input: {}", e))?;

        restore_from_mnemonic(mnemonic_input.trim())?
    };

    println!("✓ Loaded wallet");
    println!("  Address: {}", wallet_data.address);
    println!();

    // Now create encrypted KeepBox (reuse init logic)
    println!("⚠️  Choose a strong password to encrypt your wallet.");
    println!("    Minimum 12 characters with mixed case, numbers, and symbols.");
    println!();

    let password = prompt_password("Enter password: ", true)?;
    println!();

    println!("🔒 Encrypting wallet data...");

    let (ciphertext, salt, nonce) = encrypt_wallet_data(&wallet_data, &password)?;

    let keepbox = KeepBox {
        version: "1.0.0".to_string(),
        crypto: CryptoParams {
            cipher: "aes-256-gcm".to_string(),
            kdf: "argon2id".to_string(),
            kdf_params: KdfParams {
                memory_cost: 65536,
                time_cost: 3,
                parallelism: 4,
                salt: BASE64.encode(&salt),
            },
            nonce: BASE64.encode(&nonce),
        },
        encrypted_data: BASE64.encode(&ciphertext),
        metadata: Metadata {
            created: chrono::Utc::now().to_rfc3339(),
            modified: chrono::Utc::now().to_rfc3339(),
            label,
            address: wallet_data.address.clone(),
        },
    };

    let keepbox_json = serde_json::to_string_pretty(&keepbox)
        .map_err(|e| format!("Failed to serialize KeepBox: {}", e))?;

    fs::write(&output_path, keepbox_json)
        .map_err(|e| format!("Failed to write KeepBox file: {}", e))?;

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(&output_path)
            .map_err(|e| format!("Failed to get file metadata: {}", e))?
            .permissions();
        perms.set_mode(0o600);
        fs::set_permissions(&output_path, perms)
            .map_err(|e| format!("Failed to set file permissions: {}", e))?;
    }

    println!("✓ Encrypted wallet data");
    println!("✓ Created KeepBox");
    println!();
    println!("✅ Successfully imported wallet into KeepBox: {}", output_path.display());

    Ok(())
}

fn cmd_change_password(keepbox_path: PathBuf) -> Result<(), String> {
    println!("🔄 Changing KeepBox password...");
    println!();

    // Read KeepBox file
    let keepbox_json = fs::read_to_string(&keepbox_path)
        .map_err(|e| format!("Failed to read KeepBox file: {}", e))?;

    let mut keepbox: KeepBox = serde_json::from_str(&keepbox_json)
        .map_err(|e| format!("Failed to parse KeepBox: {}", e))?;

    // Prompt for old password
    let old_password = prompt_password("Enter current password: ", false)?;
    println!();

    println!("🔓 Decrypting wallet data...");

    // Decode and decrypt with old password
    let ciphertext = BASE64.decode(&keepbox.encrypted_data)
        .map_err(|e| format!("Failed to decode ciphertext: {}", e))?;
    let salt = BASE64.decode(&keepbox.crypto.kdf_params.salt)
        .map_err(|e| format!("Failed to decode salt: {}", e))?;
    let nonce = BASE64.decode(&keepbox.crypto.nonce)
        .map_err(|e| format!("Failed to decode nonce: {}", e))?;

    let wallet_data = decrypt_wallet_data(&ciphertext, &old_password, &salt, &nonce)?;

    println!("✓ Decrypted with old password");
    println!();

    // Prompt for new password
    println!("⚠️  Choose a new strong password.");
    println!();

    let new_password = prompt_password("Enter new password: ", true)?;
    println!();

    println!("🔒 Re-encrypting with new password...");

    // Re-encrypt with new password
    let (new_ciphertext, new_salt, new_nonce) = encrypt_wallet_data(&wallet_data, &new_password)?;

    // Update KeepBox
    keepbox.crypto.kdf_params.salt = BASE64.encode(&new_salt);
    keepbox.crypto.nonce = BASE64.encode(&new_nonce);
    keepbox.encrypted_data = BASE64.encode(&new_ciphertext);
    keepbox.metadata.modified = chrono::Utc::now().to_rfc3339();

    // Write updated KeepBox
    let keepbox_json = serde_json::to_string_pretty(&keepbox)
        .map_err(|e| format!("Failed to serialize KeepBox: {}", e))?;

    fs::write(&keepbox_path, keepbox_json)
        .map_err(|e| format!("Failed to write KeepBox file: {}", e))?;

    println!("✓ Re-encrypted wallet data");
    println!();
    println!("✅ Successfully changed KeepBox password");
    println!();
    println!("⚠️  Remember your new password - it CANNOT be recovered");

    Ok(())
}

fn cmd_verify(keepbox_path: PathBuf) -> Result<(), String> {
    println!("🔍 Verifying KeepBox integrity...");
    println!();

    // Read KeepBox file
    let keepbox_json = fs::read_to_string(&keepbox_path)
        .map_err(|e| format!("Failed to read KeepBox file: {}", e))?;

    let keepbox: KeepBox = serde_json::from_str(&keepbox_json)
        .map_err(|e| format!("Failed to parse KeepBox: {}", e))?;

    println!("✓ KeepBox file structure valid");

    // Verify base64 encoding
    let _ = BASE64.decode(&keepbox.encrypted_data)
        .map_err(|_| "Invalid base64 encoding in encrypted_data".to_string())?;
    let _ = BASE64.decode(&keepbox.crypto.kdf_params.salt)
        .map_err(|_| "Invalid base64 encoding in salt".to_string())?;
    let _ = BASE64.decode(&keepbox.crypto.nonce)
        .map_err(|_| "Invalid base64 encoding in nonce".to_string())?;

    println!("✓ Encrypted data encoding valid");

    // Prompt for password
    let password = prompt_password("Enter password to verify: ", false)?;
    println!();

    println!("🔓 Attempting decryption...");

    // Try to decrypt
    let ciphertext = BASE64.decode(&keepbox.encrypted_data).unwrap();
    let salt = BASE64.decode(&keepbox.crypto.kdf_params.salt).unwrap();
    let nonce = BASE64.decode(&keepbox.crypto.nonce).unwrap();

    let wallet_data = decrypt_wallet_data(&ciphertext, &password, &salt, &nonce)?;

    println!("✓ Password correct");
    println!("✓ Decryption successful");

    // Verify address derivation
    let restored_wallet = restore_from_mnemonic(&wallet_data.mnemonic)?;
    if restored_wallet.address != wallet_data.address {
        return Err("Address mismatch - wallet data may be corrupted".to_string());
    }

    println!("✓ Address verification passed");
    println!();
    println!("✅ KeepBox verification SUCCESSFUL");
    println!();
    println!("Wallet Address: {}", wallet_data.address);

    Ok(())
}

// ===== Main =====

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Init {
            wallet,
            output,
            label,
        } => cmd_init(wallet, output, label),
        Commands::Open { keepbox } => cmd_open(keepbox),
        Commands::Export {
            keepbox,
            output,
            show_private,
        } => cmd_export(keepbox, output, show_private),
        Commands::Import {
            mnemonic,
            json,
            output,
            label,
        } => cmd_import(mnemonic, json, output, label),
        Commands::ChangePassword { keepbox } => cmd_change_password(keepbox),
        Commands::Verify { keepbox } => cmd_verify(keepbox),
    };

    if let Err(e) = result {
        eprintln!("❌ Error: {}", e);
        std::process::exit(1);
    }
}
