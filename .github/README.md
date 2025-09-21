# GitHub Actions & Homebrew Release Setup

This directory contains GitHub Actions workflows for automated building, testing, and releasing Reactor to Homebrew.

## Workflows Overview

### 1. `release.yml` - Build and Release
**Trigger**: Git tags (v*) or manual dispatch

**Features**:
- ✅ Builds universal binary (Intel + Apple Silicon)
- ✅ Creates release tarball with SHA256
- ✅ Generates macOS app bundle and DMG
- ✅ Creates GitHub release with assets
- ✅ Generates Homebrew formula
- ✅ Updates Homebrew tap repository

**Outputs**:
- `reactor-{version}-universal.tar.gz` - Universal binary for Homebrew
- `Reactor-{version}.dmg` - macOS app bundle
- `reactor.rb` - Homebrew formula
- Detailed release notes

### 2. `build-test.yml` - Continuous Integration
**Trigger**: Push/PR to main/develop branches

**Features**:
- ✅ Multi-configuration builds (debug/release)
- ✅ Swift Package Manager dependency caching
- ✅ Binary verification and analysis
- ✅ Makefile build system testing
- ✅ Code formatting and linting checks
- ✅ Project structure validation

### 3. `update-homebrew-tap.yml` - Homebrew Maintenance
**Trigger**: Release publication or manual dispatch

**Features**:
- ✅ Downloads release assets and calculates SHA256
- ✅ Updates Homebrew formula with correct version and hash
- ✅ Commits and pushes to tap repository
- ✅ Creates detailed installation documentation

## Setup Instructions

### 1. Create Homebrew Tap Repository

Run the setup script to create your Homebrew tap repository:

```bash
# Make sure GitHub CLI is installed and authenticated
brew install gh
gh auth login

# Run the setup script
./scripts/setup-homebrew-tap.sh
```

This creates a new repository at `https://github.com/farfary/homebrew-reactor` with:
- Initial Homebrew formula template
- README with installation instructions
- Proper repository structure

### 2. Configure Repository Secrets

No additional secrets are required! The workflows use the built-in `GITHUB_TOKEN` which automatically has the necessary permissions.

### 3. Create Your First Release

#### Option A: Create Git Tag (Recommended)
```bash
# Create and push a release tag
git tag v1.0.0
git push origin v1.0.0
```

#### Option B: Manual Workflow Dispatch
1. Go to GitHub Actions tab
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. Enter version (e.g., v1.0.0)

### 4. Verify Release

After the workflow completes:

1. **Check GitHub Release**: New release appears with all assets
2. **Verify Homebrew Tap**: Formula updated in tap repository
3. **Test Installation**:
   ```bash
   brew tap farfary/reactor
   brew install reactor
   reactor
   ```

## Workflow Details

### Build Process
```
1. Checkout code
2. Setup Xcode and Swift toolchain
3. Cache Swift Package Manager dependencies
4. Build universal binary (arm64 + x86_64)
5. Create tarball and calculate SHA256
6. Generate macOS app bundle and DMG
7. Create Homebrew formula with correct metadata
8. Upload all assets to GitHub release
9. Update Homebrew tap repository
```

### Release Assets
Every release includes:
- **Binary**: `reactor-{version}-universal.tar.gz`
- **App Bundle**: `Reactor-{version}.dmg`
- **Formula**: `reactor.rb` (for manual installation)
- **Release Notes**: Comprehensive installation guide

### Homebrew Formula Features
- ✅ Universal binary support (Intel + Apple Silicon)
- ✅ macOS version checking (Monterey 12.0+)
- ✅ Helpful installation caveats
- ✅ Basic functionality tests
- ✅ Automatic SHA256 verification

## Usage Examples

### For Users
```bash
# Install via Homebrew
brew tap farfary/reactor
brew install reactor

# Or one-liner
brew install farfary/reactor/reactor

# Run the application
reactor
```

### For Developers
```bash
# Test local changes
swift build && swift run

# Create release
git tag v1.1.0 && git push origin v1.1.0

# Manual workflow trigger
gh workflow run release.yml -f version=v1.1.0
```

## Customization

### Modifying the Build
Edit `release.yml` to customize:
- Build configurations
- Asset generation
- Release notes format
- Homebrew formula template

### Changing Tap Repository
Update the `HOMEBREW_TAP_REPO` environment variable in workflows:
```yaml
env:
  HOMEBREW_TAP_REPO: yourusername/homebrew-yourapp
```

### Adding Tests
Extend `build-test.yml` to include:
- Unit tests (`swift test`)
- Integration tests
- Performance benchmarks
- Security scans

## Troubleshooting

### Common Issues

**Workflow fails with "Repository not found"**
- Ensure the Homebrew tap repository exists
- Check repository name in `HOMEBREW_TAP_REPO` variable

**Binary not universal**
- Verify Xcode supports universal builds
- Check build flags in `swift build` command

**Homebrew installation fails**
- Verify SHA256 matches in formula
- Check tarball URL accessibility
- Ensure binary is executable in tarball

**Permission denied errors**
- Workflows use `GITHUB_TOKEN` automatically
- No additional secrets required

### Debug Commands
```bash
# Test workflow locally (requires act)
act -j build-and-release

# Verify Homebrew formula
brew audit --strict farfary/reactor/reactor

# Test installation in clean environment
docker run --rm -it homebrew/brew:latest bash -c "
  brew tap farfary/reactor &&
  brew install reactor &&
  reactor --help
"
```

## Security Considerations

- ✅ No custom secrets required
- ✅ Uses GitHub's built-in token system
- ✅ SHA256 verification for all downloads
- ✅ Signed commits from github-actions bot
- ✅ Public audit trail for all changes

## Performance Optimizations

- ✅ Swift Package Manager dependency caching
- ✅ Parallel job execution where possible
- ✅ Minimal asset generation (only essential files)
- ✅ Efficient universal binary creation

---

**Ready to release?** Just create a git tag and let the automation handle the rest! 🚀