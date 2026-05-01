#!/bin/bash
# Wokku CLI Installer
# Usage: curl -sL https://wokku.cloud/cli/install.sh | bash

set -e

INSTALL_DIR="/usr/local/bin"
# Source of truth: wokku-cloud's cli/wokku, served at this URL. The
# Homebrew tap fetches the same URL. The public OSS UI repo no longer
# carries the CLI — it lives only in wokku-cloud (closed source).
CLI_URL="https://wokku.cloud/cli/wokku"

echo "Installing Wokku CLI..."

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating $INSTALL_DIR..."
  sudo mkdir -p "$INSTALL_DIR"
fi

sudo curl -fsSL "$CLI_URL" -o "$INSTALL_DIR/wokku"
sudo chmod +x "$INSTALL_DIR/wokku"

echo "Wokku CLI installed to $INSTALL_DIR/wokku"
echo ""
echo "Get started:"
echo "  wokku auth:login"
echo "  wokku apps"
echo "  wokku help"
