# Boundless Deploy - Repository Setup Guide

This guide explains how to set up and publish the Boundless deployment repository.

## Repository Information

- **GitHub:** https://github.com/codenlighten/boundless_deploy
- **Purpose:** One-command Boundless BLS blockchain node deployment
- **Wallet System:** Based on https://github.com/Saifullah62/BLS_KeyGen

## Setup Instructions

### 1. Initialize the Repository

From the `boundless` directory:

```bash
./init_repo.sh
```

This will:
- Initialize git repository
- Create initial commit
- Set up remote to `git@github.com:codenlighten/boundless_deploy.git`
- Prepare for first push

### 2. Verify Repository Status

```bash
git status
git remote -v
```

Should show:
```
origin  git@github.com:codenlighten/boundless_deploy.git (fetch)
origin  git@github.com:codenlighten/boundless_deploy.git (push)
```

### 3. Push to GitHub

**First time:**

```bash
git push -u origin main
```

**Subsequent pushes:**

```bash
git push
```

## Repository Structure

```
boundless_deploy/
├── .gitignore                  # Excludes wallet files, node_modules, etc.
├── README.md                   # Main documentation
├── start_boundless_node.sh     # Interactive deployment script ⭐
├── check_system.sh             # System prerequisites checker
├── init_repo.sh                # This setup script
├── schemas/                    # JSON validation schemas
├── nodes/                      # Example node configurations
├── keygen/                     # Wallet generation (from BLS_KeyGen)
├── controller/                 # Advanced deployment tools
├── cluster.json                # Multi-node configuration template
├── package.json                # Node.js metadata
├── WALLET_INTEGRATION.md       # Wallet setup guide
└── IMPLEMENTATION_SUMMARY.md   # Technical summary
```

## What Gets Committed

✅ **Included in repository:**
- All scripts and source code
- Documentation (*.md files)
- Schemas and templates
- Example configurations (with placeholder addresses)
- Keygen tools

❌ **Excluded from repository (.gitignore):**
- Wallet files (`wallet_*.json`, `boundless_wallet_*.json`)
- Private keys and mnemonics
- Docker images (`*.tar.gz`)
- Node modules
- Build artifacts
- Logs and temporary files

## Security Notes

### Never Commit:

- ❌ Generated wallet files
- ❌ Private keys
- ❌ Recovery phrases / mnemonics
- ❌ Production addresses (use placeholders)
- ❌ Real authentication tokens

### Always Use Placeholders:

```json
{
  "coinbase": "YOUR_ADDRESS_HERE",
  "token": "YOUR_TOKEN_HERE"
}
```

Users will configure their own values during deployment.

## Updating the Repository

### Adding New Features

```bash
# Make your changes
vim start_boundless_node.sh

# Test locally
./start_boundless_node.sh

# Commit
git add .
git commit -m "Added feature: XYZ"
git push
```

### Updating Documentation

```bash
# Edit documentation
vim README.md

# Commit
git add README.md
git commit -m "Updated documentation: XYZ"
git push
```

### Version Tagging

For releases:

```bash
git tag -a v1.0.0 -m "Release v1.0.0: Initial public release"
git push origin v1.0.0
```

## GitHub Repository Settings

### Recommended Settings:

**General:**
- Description: "One-command Boundless BLS blockchain node deployment with automatic wallet generation"
- Topics: `blockchain`, `boundless`, `deployment`, `docker`, `wallet`, `mining`
- Include README in repository

**Security:**
- Enable Dependabot alerts
- Enable secret scanning
- Add security policy (SECURITY.md)

**Branches:**
- Default branch: `main`
- Branch protection: Require PR reviews for main (optional)

## User Instructions

Once published, users can deploy with:

```bash
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
./start_boundless_node.sh
```

## Maintaining Wallet Generator

The `keygen/` folder is based on https://github.com/Saifullah62/BLS_KeyGen

### To Update Keygen:

```bash
# In a separate directory
git clone https://github.com/Saifullah62/BLS_KeyGen.git
cd BLS_KeyGen

# Copy updated files to boundless_deploy
cp boundless_wallet_gen.py /path/to/boundless_deploy/keygen/
cp boundless_wallet_gen.rs /path/to/boundless_deploy/keygen/
cp README.md /path/to/boundless_deploy/keygen/
# etc.

# Test the updates
cd /path/to/boundless_deploy
python3 keygen/boundless_wallet_gen.py generate

# Commit if working
git add keygen/
git commit -m "Updated wallet generator from upstream"
git push
```

## Attribution

Always maintain attribution to the original wallet generator:

**In README.md:**
```markdown
**Wallet Generation Credit:** https://github.com/Saifullah62/BLS_KeyGen
```

**In keygen/README.md:**
```markdown
# Original Repository
This wallet generator is based on: https://github.com/Saifullah62/BLS_KeyGen
```

## Support & Issues

**For deployment issues:**
- Open issue in: https://github.com/codenlighten/boundless_deploy/issues

**For wallet generation issues:**
- Check: https://github.com/Saifullah62/BLS_KeyGen/issues
- Or open in our repo with tag: `wallet-gen`

## License

Ensure compliance with:
- Boundless BLS platform license
- BLS_KeyGen license (MIT)
- Any other dependencies

Add LICENSE file to repository root.

## Next Steps After Publishing

1. **Create GitHub release:**
   - Tag: v1.0.0
   - Title: "Initial Public Release"
   - Description: Key features and installation instructions

2. **Add badges to README:**
   ```markdown
   ![GitHub release](https://img.shields.io/github/v/release/codenlighten/boundless_deploy)
   ![License](https://img.shields.io/github/license/codenlighten/boundless_deploy)
   ```

3. **Create discussion board:**
   - Enable GitHub Discussions
   - Categories: General, Q&A, Show and tell

4. **Set up CI/CD (optional):**
   - GitHub Actions for testing
   - Automated Docker image validation
   - Documentation builds

## Contact

For questions about this deployment system:
- GitHub Issues: https://github.com/codenlighten/boundless_deploy/issues
- Lumenbridge: https://lumenbridge.xyz

---

**Ready to publish!** Run `./init_repo.sh` to get started.
