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

# Install to /usr/local/bin if we can (then it's on PATH everywhere, no config). Else ~/.local/bin.
USE_SUDO=""
if [ -w /usr/local/bin ] 2>/dev/null; then
    INSTALL_DIR="/usr/local/bin"
elif command -v sudo >/dev/null 2>&1; then
    INSTALL_DIR="/usr/local/bin"
    USE_SUDO="1"
else
    INSTALL_DIR="${HOME}/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

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
    if [ -n "$USE_SUDO" ]; then
        sudo cp -f "$DEEPCLI_BIN" "${INSTALL_DIR}/deepcli"
        sudo chmod +x "${INSTALL_DIR}/deepcli"
    else
        mv -f "$DEEPCLI_BIN" "${INSTALL_DIR}/deepcli"
        chmod +x "${INSTALL_DIR}/deepcli"
    fi
fi
if [ ! -f "${INSTALL_DIR}/deepcli" ]; then
    echo "deepcli binary not found in archive. Contents of archive:"
    find "$EXTRACT_TO" -type f 2>/dev/null | while read -r f; do echo "  $f"; done
    rm -rf "$EXTRACT_TO"
    exit 1
fi
rm -rf "$EXTRACT_TO"

# Only add to PATH when using ~/.local/bin ( /usr/local/bin is already on PATH )
if [ "$INSTALL_DIR" = "${HOME}/.local/bin" ]; then
    PATH_LINE="export PATH=\"\${HOME}/.local/bin:\$PATH\""
    SHELL_RC=""
    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile"; do
        if [ -f "$rc" ]; then
            SHELL_RC="$rc"
            break
        fi
    done
    if [ -z "$SHELL_RC" ]; then
        SHELL_RC="${HOME}/.profile"
        touch "$SHELL_RC"
    fi
    if ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo '# DeepCLI' >> "$SHELL_RC"
        echo "$PATH_LINE" >> "$SHELL_RC"
    fi
fi

echo ""
echo "DeepCLI installed successfully to $INSTALL_DIR"
echo "Run: deepcli init"
echo ""
