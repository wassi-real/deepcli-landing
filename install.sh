#!/bin/sh
# DeepCLI Install Script for macOS and Linux
# One-liner: curl -fsSL https://deepcli.org/install.sh | sh
# Alternative: wget -qO- https://deepcli.org/install.sh | sh

set -e

VERSION="0.1.1"
BASE_URL="https://deepcli.org/releases/v${VERSION}"
GITHUB_BASE="https://github.com/wassi-real/DeepCLI/releases/download/v${VERSION}"

# Detect OS and arch
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Darwin)  PLATFORM="darwin" ;;
    Linux)   PLATFORM="linux" ;;
    *)       echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
    x86_64|amd64)  TARGET_ARCH="x86_64" ;;
    aarch64|arm64) TARGET_ARCH="aarch64" ;;
    *)             echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

ASSET_NAME="deepcli-${VERSION}-${PLATFORM}-${TARGET_ARCH}.tar.gz"
URL="${BASE_URL}/${ASSET_NAME}"
FALLBACK_URL="${GITHUB_BASE}/${ASSET_NAME}"

# Install to ~/.local/bin (or /usr/local/bin if no write to home)
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "DeepCLI ${VERSION} installer"
echo "Platform: ${PLATFORM}-${TARGET_ARCH}"
echo ""

# Download
TMP_FILE=$(mktemp)
if curl -fsSL -o "$TMP_FILE" "$URL" 2>/dev/null; then
    echo "Downloaded from deepcli.org"
elif curl -fsSL -L -o "$TMP_FILE" "$FALLBACK_URL" 2>/dev/null; then
    echo "Downloaded from GitHub Releases"
else
    echo "Download failed. Try manually: https://github.com/wassi-real/DeepCLI/releases"
    rm -f "$TMP_FILE"
    exit 1
fi

# Extract
echo "Extracting to ${INSTALL_DIR}..."
tar xzf "$TMP_FILE" -C "$INSTALL_DIR"
rm -f "$TMP_FILE"

# The tarball contains deepcli-0.1.1-darwin-x86_64/deepcli - move to INSTALL_DIR
EXTRACTED_DIR="${INSTALL_DIR}/deepcli-${VERSION}-${PLATFORM}-${TARGET_ARCH}"
if [ -d "$EXTRACTED_DIR" ]; then
    mv -f "${EXTRACTED_DIR}/deepcli" "${INSTALL_DIR}/deepcli"
    rmdir "$EXTRACTED_DIR" 2>/dev/null || rm -rf "$EXTRACTED_DIR"
fi

chmod +x "${INSTALL_DIR}/deepcli"

# Add to PATH if not already
SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -n "$ZSH_NAME" ]; then
    SHELL_RC="${HOME}/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="${HOME}/.bashrc"
fi

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo '# DeepCLI' >> "$SHELL_RC"
        echo "export PATH=\"\${HOME}/.local/bin:\$PATH\"" >> "$SHELL_RC"
        echo "Added ~/.local/bin to PATH in $SHELL_RC"
    fi
else
    echo ""
    echo "Add to your PATH: export PATH=\"\${HOME}/.local/bin:\$PATH\""
fi

echo ""
echo "DeepCLI installed successfully!"
echo "Open a new terminal and run: deepcli init"
echo ""
