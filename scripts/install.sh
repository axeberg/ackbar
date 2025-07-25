#!/bin/bash

set -e

REPO_URL="https://github.com/axeberg/ackbar"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)

echo "🚀 Installing ackbar..."

# Download latest release
echo "📦 Downloading latest version..."
cd "$TEMP_DIR"
curl -sL "$REPO_URL/releases/latest/download/ackbar" -o ackbar || {
    echo "❌ Failed to download. Building from source..."
    git clone "$REPO_URL" .
    just build
}

# Make executable
chmod +x ackbar

# Install
echo "📁 Installing to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo mv ackbar "$INSTALL_DIR/"

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "✅ Installation complete!"
echo ""
echo "Usage: ackbar"
echo ""
echo "Keyboard shortcuts:"
echo "  ⌘⌃M - Toggle hide/show icons"
echo "  ⌘⌃⌥M - Emergency reset"
echo ""
echo "Note: Enable accessibility permissions for keyboard shortcuts"
echo "Run 'just enable-shortcuts' for setup help"
