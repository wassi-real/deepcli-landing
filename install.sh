#!/bin/sh
# DeepCLI Install Script for macOS and Linux
# One-liner: curl -fsSL https://deepcli.org/install.sh | sh
# Alternative: wget -qO- https://deepcli.org/install.sh | sh

set -e

VERSION="0.1.1"
# Base URL after version: https://deepcli.org/releases/v0.1.1/
BASE_URL="https://deepcli.org/releases/v${VERSION}"
# File at that base URL (e.g. DeepCLI-0.1.1.tar.gz)
RELEASE_FILE="DeepCLI-${VERSION}.tar.gz"
GITHUB_BASE="https://github.com/wassi-real/DeepCLI/releases/download/v${VERSION}"

# Detect OS and arch for platform-specific asset (Linux/macOS only)
OS=""; ARCH=""
case "$(uname -s)" in Linux) OS="linux";; Darwin) OS="darwin";; *) OS="";; esac
case "$(uname -m)" in x86_64|amd64) ARCH="x86_64";; aarch64|arm64) ARCH="aarch64";; *) ARCH="";; esac
PLATFORM_ASSET=""
if [ -n "$OS" ] && [ -n "$ARCH" ]; then
    PLATFORM_ASSET="deepcli-${VERSION}-${OS}-${ARCH}.tar.gz"
fi

# Install to ~/.local/bin
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "DeepCLI ${VERSION} installer"
echo ""

# Download: try platform-specific first (Linux/macOS), then generic
TMP_FILE=$(mktemp)
DOWNLOADED=""
if [ -n "$PLATFORM_ASSET" ]; then
    if curl -fsSL -o "$TMP_FILE" "${BASE_URL}/${PLATFORM_ASSET}" 2>/dev/null; then
        DOWNLOADED="deepcli.org (${OS}-${ARCH})"
    elif curl -fsSL -L -o "$TMP_FILE" "${GITHUB_BASE}/${PLATFORM_ASSET}" 2>/dev/null; then
        DOWNLOADED="GitHub (${OS}-${ARCH})"
    fi
fi
if [ -z "$DOWNLOADED" ]; then
    if curl -fsSL -o "$TMP_FILE" "${BASE_URL}/${RELEASE_FILE}" 2>/dev/null; then
        DOWNLOADED="deepcli.org (generic)"
    elif curl -fsSL -L -o "$TMP_FILE" "${GITHUB_BASE}/${RELEASE_FILE}" 2>/dev/null; then
        DOWNLOADED="GitHub (generic)"
    fi
fi
if [ -z "$DOWNLOADED" ]; then
    echo "Download failed. Try manually: https://github.com/wassi-real/DeepCLI/releases"
    rm -f "$TMP_FILE"
    exit 1
fi
echo "Downloaded from $DOWNLOADED"

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

# Find native binary "deepcli" or "DeepCLI" (no .exe). On Linux/macOS we must not use deepcli.exe (Windows).
DEEPCLI_BIN=$(find "$EXTRACT_TO" \( -name "deepcli" -o -name "DeepCLI" \) -type f 2>/dev/null | head -1)
# If no native binary, check if archive only has Windows build
if [ -z "$DEEPCLI_BIN" ]; then
    EXE_BIN=$(find "$EXTRACT_TO" -name "deepcli.exe" -type f 2>/dev/null | head -1)
    if [ -n "$EXE_BIN" ]; then
        echo "This archive contains the Windows build (deepcli.exe). On Linux/macOS you need the native build."
        if [ -n "$PLATFORM_ASSET" ]; then
            echo "Download the correct build from: ${GITHUB_BASE}/${PLATFORM_ASSET}"
        fi
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
