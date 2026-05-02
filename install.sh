#!/bin/bash
# Wokku CLI Installer
# Usage: curl -sL https://wokku.cloud/cli/install.sh | bash

set -e

INSTALL_DIR="/usr/local/bin"
# require_relative "lib/wokku/..." in the wokku script is relative to the
# script's own location, so the lib tree must live next to it.
LIB_DIR="$INSTALL_DIR/lib/wokku"
# Source of truth: wokku-cloud's cli/wokku, served at this URL. The
# Homebrew tap fetches the same URL. The public OSS UI repo no longer
# carries the CLI — it lives only in wokku-cloud (closed source).
BASE_URL="https://wokku.cloud/cli"
CLI_URL="$BASE_URL/wokku"

echo "Installing Wokku CLI..."

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Creating $INSTALL_DIR..."
  sudo mkdir -p "$INSTALL_DIR"
fi

sudo mkdir -p "$LIB_DIR"

sudo curl -fsSL "$CLI_URL" -o "$INSTALL_DIR/wokku"
sudo curl -fsSL "$BASE_URL/lib/wokku/config.rb"     -o "$LIB_DIR/config.rb"
sudo curl -fsSL "$BASE_URL/lib/wokku/output.rb"     -o "$LIB_DIR/output.rb"
sudo curl -fsSL "$BASE_URL/lib/wokku/api_client.rb" -o "$LIB_DIR/api_client.rb"
sudo chmod +x "$INSTALL_DIR/wokku"

echo "Wokku CLI installed to $INSTALL_DIR/wokku"
echo ""
echo "Get started:"
echo "  wokku auth:login"
echo "  wokku apps"
echo "  wokku help"
