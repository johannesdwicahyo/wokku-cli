#!/bin/bash
# Wokku CLI Installer
# Usage: curl -sL https://wokku.cloud/cli/install.sh | bash
set -e
INSTALL_DIR="/usr/local/bin"
LIB_DIR="$INSTALL_DIR/lib/wokku"
TARBALL_URL="https://wokku.cloud/cli/wokku.tar.gz"

echo "Installing Wokku CLI..."

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating $INSTALL_DIR..."
  sudo mkdir -p "$INSTALL_DIR"
fi

# Clear stale per-file installs from older bootstraps so we don't
# leave behind orphaned config.rb / output.rb / api_client.rb that
# might shadow the new tree.
sudo rm -rf "$LIB_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

sudo curl -fsSL "$TARBALL_URL" -o "$TMP/wokku-cli.tar.gz"
sudo tar -xzf "$TMP/wokku-cli.tar.gz" -C "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/wokku"

echo "Wokku CLI installed to $INSTALL_DIR/wokku"
echo
echo "Get started:"
echo "  wokku auth:login"
echo "  wokku apps"
echo "  wokku help"
