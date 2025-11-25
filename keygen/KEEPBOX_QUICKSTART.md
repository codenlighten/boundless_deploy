# KeepBox Quick Start Guide

**Your Wallet is Valuable - Encrypt It!**

This guide will help you encrypt your Boundless wallet in under 2 minutes.

---

## What is KeepBox?

KeepBox encrypts your wallet file with **military-grade encryption** (AES-256-GCM), making it safe to:
- ✅ Backup to cloud storage
- ✅ Store on USB drives
- ✅ Keep on your computer
- ✅ Share storage with others (they can't decrypt it)

**Without a password, your mnemonic is unreadable.**

---

## Quick Start (3 Steps)

### Step 1: Encrypt Your Wallet

```bash
cd C:\Users\ripva\Desktop\BLS_KeyGen

.\target\release\boundless-keepbox.exe init ^
  --wallet my_wallet.json ^
  --output my_wallet.keepbox ^
  --label "My Main Wallet"
```

**You'll be prompted to create a password:**
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, and symbols
- Example good password: `MyBoundless2025!Wallet`

**Output:**
```
🔐 Creating encrypted KeepBox from wallet...

✓ Loaded wallet
  Address: d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793

⚠️  Choose a strong password to encrypt your wallet.
    Minimum 12 characters with mixed case, numbers, and symbols.

Enter password: ****************
Confirm password: ****************

🔒 Encrypting wallet data...
✓ Encrypted wallet data
✓ Created KeepBox

✅ Successfully created encrypted KeepBox: my_wallet.keepbox

📝 Important:
   - Remember your password - it CANNOT be recovered
   - Store a backup of this file in a secure location
   - The original wallet.json can now be securely deleted
```

### Step 2: Verify It Works

```bash
.\target\release\boundless-keepbox.exe verify --keepbox my_wallet.keepbox
```

**Enter your password when prompted.**

**Output:**
```
🔍 Verifying KeepBox integrity...

✓ KeepBox file structure valid
✓ Encrypted data encoding valid
Enter password to verify: ****************

🔓 Attempting decryption...
✓ Password correct
✓ Decryption successful
✓ Address verification passed

✅ KeepBox verification SUCCESSFUL

Wallet Address: d66fdfc9ba885109f1f932fb70868321edc1541ca3eec3f38c0f94fa6a90f793
```

### Step 3: Delete Original (Optional)

Once you've verified the KeepBox works, you can delete the original unencrypted wallet:

```bash
# IMPORTANT: Only do this AFTER verifying Step 2!

del my_wallet.json
```

**⚠️ CRITICAL:** Make sure you can decrypt your KeepBox BEFORE deleting the original!

---

## Daily Use

### View Wallet Info (No Password)

```bash
.\target\release\boundless-keepbox.exe open --keepbox my_wallet.keepbox
```

Shows:
- Wallet address
- Label
- Created/modified dates
- Encryption info

**Does NOT show:** Mnemonic or private key (those require password)

### Export Wallet When Needed (Requires Password)

When you need to use your wallet with Boundless software:

```bash
.\target\release\boundless-keepbox.exe export ^
  --keepbox my_wallet.keepbox ^
  --output temp_wallet.json
```

**Enter password when prompted.**

**IMPORTANT:** Delete `temp_wallet.json` after using it!

```bash
del temp_wallet.json
```

---

## Common Commands

### Change Password

```bash
.\target\release\boundless-keepbox.exe change-password --keepbox my_wallet.keepbox
```

### Import from Mnemonic

If you have a 24-word mnemonic and want to encrypt it:

```bash
.\target\release\boundless-keepbox.exe import ^
  --output new_wallet.keepbox ^
  --label "Restored Wallet"
```

You'll be prompted to:
1. Enter your 24-word mnemonic
2. Create a password for the KeepBox

---

## Backup Strategy

**Recommended Backup Plan:**

1. **Primary:** `my_wallet.keepbox` on your computer
2. **Backup 1:** Copy to USB drive, store in safe
3. **Backup 2:** Upload to encrypted cloud (Dropbox, Google Drive, etc.)
4. **Backup 3:** Copy to second USB drive, store at different location

**Why it's safe to backup to cloud:**
- Your mnemonic is encrypted with AES-256-GCM
- Without your password, it's unreadable
- Even if Dropbox is hacked, your wallet is safe
- **BUT:** Use a strong password!

---

## Security Reminders

### ✅ DO:
- Use a strong password (12+ characters)
- Store password in password manager (1Password, Bitwarden)
- Keep multiple backups
- Test your password regularly
- Delete exported JSON files after use

### ❌ DON'T:
- Don't use a weak password
- Don't forget your password (it's unrecoverable!)
- Don't store password with KeepBox file
- Don't share your password
- Don't leave exported JSON files on your computer

---

## Help & Documentation

**Quick Help:**
```bash
.\target\release\boundless-keepbox.exe --help
```

**Command-Specific Help:**
```bash
.\target\release\boundless-keepbox.exe init --help
.\target\release\boundless-keepbox.exe export --help
```

**Full Documentation:**
- `KEEPBOX_README.md` - Complete user guide (24KB)
- `ENCRYPTED_KEYSTORE_DESIGN.md` - Technical design
- `KEEPBOX_IMPLEMENTATION_SUMMARY.md` - Implementation details

---

## Troubleshooting

### "Decryption failed - incorrect password"

**Solution:** Try password again carefully. Password is case-sensitive.

### "Password must be at least 12 characters"

**Solution:** Your password is too weak. Use a longer password with mixed characters.

Example strong password: `MyBoundless2025!SecureWallet`

### "File not found"

**Solution:** Check the file path. Use full path if needed:
```bash
.\target\release\boundless-keepbox.exe init ^
  --wallet "C:\Users\ripva\Desktop\BLS_KeyGen\my_wallet.json" ^
  --output "C:\Users\ripva\Desktop\BLS_KeyGen\my_wallet.keepbox"
```

---

## Next Steps

1. ✅ Encrypt your wallet (Step 1)
2. ✅ Verify it works (Step 2)
3. ✅ Create backups
4. ✅ Test password recovery
5. ✅ Delete original JSON (optional)
6. ✅ Read full documentation (KEEPBOX_README.md)

---

**Your wallet is now encrypted and secure!** 🔐

**Remember:**
- 🔑 Your password protects your KeepBox
- 📝 Your mnemonic (on paper) is still your ultimate backup
- 💾 Keep multiple backups of your KeepBox
- 🔍 Test your password regularly

---

**Questions?** Read `KEEPBOX_README.md` for detailed documentation.
