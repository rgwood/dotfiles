#!/usr/bin/env bash
# Install commonly used tools on exe.dev (Ubuntu-based)
# Run this script after cloning dotfiles to a new exe.dev VM

set -e  # Exit on error

echo "====================================="
echo "Installing tools for exe.dev"
echo "====================================="

# Update package lists
echo ""
echo "[1/5] Updating apt package lists..."
sudo apt update

# Install packages available via apt
echo ""
echo "[2/5] Installing apt packages..."
sudo apt install -y \
    bat \
    micro \
    fd-find \
    build-essential \
    pkg-config \
    libssl-dev \
    curl \
    git

echo "Setting up bat and fd aliases (Ubuntu uses different names)..."
# Ubuntu ships bat as 'batcat' and fd as 'fdfind'
mkdir -p ~/.local/bin
if [ ! -e ~/.local/bin/bat ] && [ -x /usr/bin/batcat ]; then
    ln -sf /usr/bin/batcat ~/.local/bin/bat
    echo "  ✓ Created bat -> batcat symlink"
fi
if [ ! -e ~/.local/bin/fd ] && [ -x /usr/bin/fdfind ]; then
    ln -sf /usr/bin/fdfind ~/.local/bin/fd
    echo "  ✓ Created fd -> fdfind symlink"
fi

# Install Rust/Cargo if not already installed
echo ""
echo "[3/5] Installing Rust/Cargo..."
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    
    # Source cargo env for this script
    source "$HOME/.cargo/env"
    
    echo "  ✓ Rust installed"
else
    echo "  ✓ Rust already installed ($(rustc --version))"
fi

# Install cargo packages
echo ""
echo "[4/5] Installing cargo packages (this may take a while)..."
# Ensure cargo is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Install watchexec
if ! cargo install --list | grep -q "^watchexec-cli "; then
    echo "  Installing watchexec-cli..."
    cargo install watchexec-cli --locked
else
    echo "  ✓ watchexec-cli already installed"
fi

# Install nushell from prebuilt binary (much faster than cargo install)
echo ""
echo "[4.5/5] Installing nushell..."
if ! command -v nu &> /dev/null; then
    echo "  Downloading prebuilt nushell binary..."
    NUSHELL_VERSION=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    NUSHELL_URL="https://github.com/nushell/nushell/releases/download/${NUSHELL_VERSION}/nu-${NUSHELL_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    curl -L -o nushell.tar.gz "$NUSHELL_URL"
    tar xzf nushell.tar.gz
    
    # Install to ~/.cargo/bin to keep it with other rust tools
    mkdir -p ~/.cargo/bin
    cp "nu-${NUSHELL_VERSION}-x86_64-unknown-linux-gnu/nu" ~/.cargo/bin/
    chmod +x ~/.cargo/bin/nu
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "  ✓ nushell installed ($(~/.cargo/bin/nu --version))"
else
    echo "  ✓ nushell already installed ($(nu --version))"
fi

# Install lazygit from prebuilt binary
echo ""
echo "[4.6/5] Installing lazygit..."
if ! command -v lazygit &> /dev/null; then
    echo "  Downloading prebuilt lazygit binary..."
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    curl -L -o lazygit.tar.gz "$LAZYGIT_URL"
    tar xzf lazygit.tar.gz
    
    # Install to ~/.local/bin
    mkdir -p ~/.local/bin
    cp lazygit ~/.local/bin/
    chmod +x ~/.local/bin/lazygit
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "  ✓ lazygit installed ($(~/.local/bin/lazygit --version))"
else
    echo "  ✓ lazygit already installed ($(lazygit --version))"
fi

# Verify installations
echo ""
echo "[5/5] Verifying installations..."
echo ""
echo "Checking installed tools:"
for tool in bat fd micro cargo rustc watchexec nu lazygit; do
    if command -v $tool &> /dev/null; then
        version=$("$tool" --version 2>/dev/null | head -1 || echo "(version check not supported)")
        echo "  ✓ $tool: $version"
    else
        echo "  ✗ $tool: not found"
    fi
done

echo ""
echo "====================================="
echo "Installation complete!"
echo "====================================="
echo ""
echo "Note: Make sure ~/.local/bin and ~/.cargo/bin are in your PATH."
echo "Add these lines to your shell rc file if needed:"
echo '  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"'
echo ""
echo "Restart your shell or run: source ~/.cargo/env"
