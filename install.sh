#!/bin/sh
# DeepCLI Install Script for macOS and Linux
# One-liner: curl -fsSL https://deepcli.org/install.sh | sh
# Alternative: wget -qO- https://deepcli.org/install.sh | sh

set -e

VERSION="0.1.1"
# Base URL after version: https://deepcli.org/releases/v0.1.1/
BASE_URL="https://deepcli.org/releases/v${VERSION}"
# Single release file: zip (contains both deepcli and deepcli.exe) or fallback tar.gz
RELEASE_ZIP="DeepCLI-${VERSION}.zip"
RELEASE_TAR="DeepCLI-${VERSION}.tar.gz"
GITHUB_BASE="https://github.com/wassi-real/DeepCLI/releases/download/v${VERSION}"

# Install to ~/.local/bin
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "DeepCLI ${VERSION} installer"
echo ""

# Download: try zip first (mixed exe + native binary), then tar.gz
TMP_FILE=$(mktemp)
DOWNLOADED=""
if curl -fsSL -o "$TMP_FILE" "${BASE_URL}/${RELEASE_ZIP}" 2>/dev/null; then
    DOWNLOADED="deepcli.org"
elif curl -fsSL -L -o "$TMP_FILE" "${GITHUB_BASE}/${RELEASE_ZIP}" 2>/dev/null; then
    DOWNLOADED="GitHub"
fi
if [ -z "$DOWNLOADED" ]; then
    if curl -fsSL -o "$TMP_FILE" "${BASE_URL}/${RELEASE_TAR}" 2>/dev/null; then
        DOWNLOADED="deepcli.org"
    elif curl -fsSL -L -o "$TMP_FILE" "${GITHUB_BASE}/${RELEASE_TAR}" 2>/dev/null; then
        DOWNLOADED="GitHub"
    fi
fi
if [ -z "$DOWNLOADED" ]; then
    echo "Download failed. Try manually: https://github.com/wassi-real/DeepCLI/releases"
    rm -f "$TMP_FILE"
    exit 1
fi
echo "Downloaded from $DOWNLOADED"

# Detect archive type: PK = zip, 1f 8b = gzip
EXTRACT_TO=$(mktemp -d)
FIRST_BYTES=$(head -c 2 "$TMP_FILE" | od -An -tx1 | tr -d ' \n')
if [ "$FIRST_BYTES" = "504b" ]; then
    echo "Extracting archive..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$TMP_FILE" -d "$EXTRACT_TO"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m zipfile -e "$TMP_FILE" "$EXTRACT_TO"
    else
        echo "Need unzip or python3 to extract. Install with: apt-get install unzip   or   yum install unzip"
        rm -rf "$EXTRACT_TO"
        rm -f "$TMP_FILE"
        exit 1
    fi
elif [ "$FIRST_BYTES" = "1f8b" ]; then
    echo "Extracting archive..."
    tar xzf "$TMP_FILE" -C "$EXTRACT_TO"
else
    echo "Downloaded file is not a supported archive (zip or tar.gz)."
    rm -rf "$EXTRACT_TO"
    rm -f "$TMP_FILE"
    exit 1
fi
rm -f "$TMP_FILE"

# Find native binary "deepcli" or "DeepCLI" (no .exe). On Linux/macOS we must not use deepcli.exe (Windows).
DEEPCLI_BIN=$(find "$EXTRACT_TO" \( -name "deepcli" -o -name "DeepCLI" \) -type f 2>/dev/null | head -1)
# If no native binary, check if archive only has Windows build
if [ -z "$DEEPCLI_BIN" ]; then
    EXE_BIN=$(find "$EXTRACT_TO" -name "deepcli.exe" -type f 2>/dev/null | head -1)
    if [ -n "$EXE_BIN" ]; then
        echo "This archive contains only the Windows build (deepcli.exe). The native Linux/macOS binary (deepcli) was not found."
        echo "Ensure the release zip includes the deepcli binary: https://github.com/wassi-real/DeepCLI/releases"
        rm -rf "$EXTRACT_TO"
        exit 1
    fi
fi
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
