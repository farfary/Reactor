#!/bin/bash

# Script to set up Homebrew tap repository
# Run this script to create the homebrew-reactor repository

set -e

GITHUB_USERNAME="farfary"
TAP_REPO_NAME="homebrew-reactor"
TAP_REPO_URL="https://github.com/${GITHUB_USERNAME}/${TAP_REPO_NAME}"

echo "🍺 Setting up Homebrew tap repository..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is required but not installed."
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "🔐 Please authenticate with GitHub CLI first:"
    echo "gh auth login"
    exit 1
fi

# Create the repository
echo "📁 Creating repository ${TAP_REPO_URL}..."

if gh repo create "${GITHUB_USERNAME}/${TAP_REPO_NAME}" --public --description "Homebrew tap for Reactor - macOS process monitoring tool" --clone; then
    echo "✅ Repository created successfully"
else
    echo "⚠️ Repository might already exist, cloning instead..."
    git clone "${TAP_REPO_URL}.git" "${TAP_REPO_NAME}"
fi

cd "${TAP_REPO_NAME}"

# Create basic repository structure
echo "📝 Setting up repository structure..."

# Create Formula directory
mkdir -p Formula

# Create initial README
cat > README.md << 'EOF'
# Homebrew Tap for Reactor

This is the official Homebrew tap for [Reactor](https://github.com/farfary/Reactor), a sophisticated macOS menubar application for real-time system process monitoring.

## Installation

```bash
# Add the tap
brew tap farfary/reactor

# Install Reactor
brew install reactor

# Run Reactor
reactor
```

## About Reactor

Reactor is a native macOS application that provides real-time process monitoring with intelligent categorization, interactive management, and comprehensive performance metrics.

## System Requirements

- macOS 12.0+ (Monterey or later)
- Intel or Apple Silicon Mac
- No additional dependencies

## Support

- **Documentation**: [GitHub Repository](https://github.com/farfary/Reactor)
- **Issues**: [Report Bugs](https://github.com/farfary/Reactor/issues)
- **Discussions**: [Feature Requests](https://github.com/farfary/Reactor/discussions)

## License

MIT License - see the [main repository](https://github.com/farfary/Reactor) for details.
EOF

# Create placeholder formula
cat > Formula/reactor.rb << 'EOF'
class Reactor < Formula
  desc "Sophisticated macOS menubar application for real-time system process monitoring"
  homepage "https://github.com/farfary/Reactor"
  url "https://github.com/farfary/Reactor/releases/download/v1.0.0/reactor-1.0.0-universal.tar.gz"
  sha256 "placeholder-sha256-will-be-updated-by-release-workflow"
  version "1.0.0"
  license "MIT"
  
  depends_on :macos => :monterey
  
  def install
    bin.install "reactor"
  end
  
  def caveats
    <<~EOS
      Reactor has been installed as a command-line tool.
      
      To start Reactor:
        reactor
      
      The app will appear in your macOS menubar as ⚡
      
      For more information:
        https://github.com/farfary/Reactor
    EOS
  end
  
  test do
    assert_predicate bin/"reactor", :exist?
    assert_predicate bin/"reactor", :executable?
  end
end
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk
EOF

# Initial commit
echo "🚀 Creating initial commit..."
git add .
git commit -m "Initial setup of Homebrew tap for Reactor

- Added Formula/reactor.rb placeholder
- Created README with installation instructions
- Set up repository structure for automated updates"

# Push to GitHub
git push origin main

echo ""
echo "✅ Homebrew tap repository setup complete!"
echo ""
echo "📋 Repository Details:"
echo "- Repository: ${TAP_REPO_URL}"
echo "- Tap Command: brew tap ${GITHUB_USERNAME}/reactor"
echo "- Install Command: brew install reactor"
echo ""
echo "🔄 The formula will be automatically updated when you create releases"
echo "   in the main Reactor repository using the GitHub Actions workflow."
echo ""
echo "🍺 Next steps:"
echo "1. Create a release in the main Reactor repository"
echo "2. The GitHub Actions workflow will automatically update this tap"
echo "3. Users can then install via: brew install ${GITHUB_USERNAME}/reactor"