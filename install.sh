#!/bin/sh
# DeepCLI Install Script for macOS and Linux
# One-liner: curl -fsSL https://deepcli.org/install.sh | sh
# Alternative: wget -qO- https://deepcli.org/install.sh | sh

set -e

VERSION="0.1.1"
ASSET_NAME="DeepCLI-${VERSION}.tar.gz"
BASE_URL="https://deepcli.org/releases/v${VERSION}"
GITHUB_URL="https://github.com/wassi-real/DeepCLI/releases/download/v${VERSION}/${ASSET_NAME}"

# Install to ~/.local/bin
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "DeepCLI ${VERSION} installer"
echo ""

# Download
TMP_FILE=$(mktemp)
if curl -fsSL -o "$TMP_FILE" "${BASE_URL}/${ASSET_NAME}" 2>/dev/null; then
    echo "Downloaded from deepcli.org"
elif curl -fsSL -L -o "$TMP_FILE" "$GITHUB_URL" 2>/dev/null; then
    echo "Downloaded from GitHub Releases"
else
    echo "Download failed. Try manually: https://github.com/wassi-real/DeepCLI/releases"
    rm -f "$TMP_FILE"
    exit 1
fi

# Validate tar.gz (first bytes should be 1f 8b for gzip)
if ! head -c 2 "$TMP_FILE" | od -An -tx1 | grep -q '1f 8b'; then
    echo "Downloaded file is not a valid tar.gz. Check if release exists: https://github.com/wassi-real/DeepCLI/releases"
    rm -f "$TMP_FILE"
    exit 1
fi

# Extract
echo "Extracting to ${INSTALL_DIR}..."
EXTRACT_TO=$(mktemp -d)
tar xzf "$TMP_FILE" -C "$EXTRACT_TO"
rm -f "$TMP_FILE"

# Find deepcli binary (name may be deepcli or DeepCLI; could be at root or in subfolder)
DEEPCLI_BIN=$(find "$EXTRACT_TO" -iname "deepcli" -type f 2>/dev/null | head -1)
if [ -n "$DEEPCLI_BIN" ]; then
    mv -f "$DEEPCLI_BIN" "${INSTALL_DIR}/deepcli"
fi
if [ ! -f "${INSTALL_DIR}/deepcli" ]; then
    echo "deepcli binary not found in archive. Contents of archive:"
    find "$EXTRACT_TO" -type f 2>/dev/null | while read -r f; do echo "  $f"; done
    rm -rf "$EXTRACT_TO"
    exit 1
fi
rm -rf "$EXTRACT_TO"

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
