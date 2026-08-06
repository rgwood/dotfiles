#!/usr/bin/env bash
# Install commonly used tools on exe.dev (Ubuntu-based)
set -euo pipefail

echo "Installing tools for exe.dev"
echo "============================="

# --- Helpers ---

install_github_binary() {
    local name=$1 repo=$2 url_pattern=$3 binary_path=$4 dest=$5

    if command -v "$name" &>/dev/null; then
        echo "  ✓ $name already installed"
        return
    fi

    local version
    version=$(curl -sfL "https://api.github.com/repos/${repo}/releases/latest" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
    if [[ -z "$version" ]]; then
        echo "  ✗ $name: failed to fetch latest version"
        return 1
    fi

    # Some tags are "v0.1.2", some are "0.1.2" — strip the v for URL patterns that need it
    local version_bare=${version#v}

    local url binary_resolved
    url=$(echo "$url_pattern" | sed "s|{VERSION}|${version}|g; s|{VERSION_BARE}|${version_bare}|g")
    binary_resolved=$(echo "$binary_path" | sed "s|{VERSION}|${version}|g; s|{VERSION_BARE}|${version_bare}|g")

    local tmp
    tmp=$(mktemp -d)
    trap "rm -rf '$tmp'" RETURN

    echo "  Downloading $name $version..."
    local archive="$tmp/archive"
    curl -sfL -o "$archive" "$url" || { echo "  ✗ $name: download failed"; return 1; }
    tar xf "$archive" -C "$tmp"

    mkdir -p "$(dirname "$dest")"
    cp "$tmp/$binary_resolved" "$dest"
    chmod +x "$dest"
    echo "  ✓ $name installed ($version)"
}

# --- apt packages ---

echo ""
echo "[1/5] Updating apt and installing packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    bat fd-find micro \
    build-essential pkg-config libssl-dev \
    curl git >/dev/null

# Ubuntu ships bat as 'batcat' and fd as 'fdfind'
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true
ln -sf /usr/bin/fdfind ~/.local/bin/fd 2>/dev/null || true

# --- Rust ---

echo ""
echo "[2/5] Rust toolchain..."
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    echo "  ✓ Rust installed"
else
    echo "  ✓ Rust already installed ($(rustc --version))"
fi

# --- Prebuilt binaries from GitHub ---

echo ""
echo "[3/5] watchexec..."
install_github_binary watchexec watchexec/watchexec \
    "https://github.com/watchexec/watchexec/releases/download/{VERSION}/watchexec-{VERSION_BARE}-x86_64-unknown-linux-gnu.tar.xz" \
    "watchexec-{VERSION_BARE}-x86_64-unknown-linux-gnu/watchexec" \
    "$HOME/.local/bin/watchexec"

echo ""
echo "[4/5] nushell..."
install_github_binary nu nushell/nushell \
    "https://github.com/nushell/nushell/releases/download/{VERSION}/nu-{VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    "nu-{VERSION}-x86_64-unknown-linux-gnu/nu" \
    "$HOME/.cargo/bin/nu"

echo ""
echo "[5/5] lazygit..."
install_github_binary lazygit jesseduffield/lazygit \
    "https://github.com/jesseduffield/lazygit/releases/download/{VERSION}/lazygit_{VERSION_BARE}_linux_x86_64.tar.gz" \
    "lazygit" \
    "$HOME/.local/bin/lazygit"

# --- Done ---

echo ""
echo "Done. Installed tools:"
for tool in bat fd micro cargo rustc watchexec nu lazygit; do
    if command -v "$tool" &>/dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool"
    fi
done
