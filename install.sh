#!/bin/bash
# Neovim Config Installer (Ubuntu/Debian)
# Installs: neovim, config, LSP servers, opencode, nerd font

set -e

NVIM_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/koko3453/nvim.git"

echo "========================================"
echo "  Neovim Config Installer"
echo "========================================"
echo ""

# Check if running on Debian/Ubuntu
if ! command -v apt &> /dev/null; then
    echo "Error: This installer is for Ubuntu/Debian systems only."
    exit 1
fi

# Install system dependencies
echo "[1/7] Installing system dependencies..."
sudo apt update
sudo apt install -y git curl wget unzip build-essential

# Install Neovim (requires 0.11+)
echo "[2/7] Installing Neovim..."
REQUIRED_NVIM="0.11"
install_neovim() {
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y neovim
}

if ! command -v nvim &> /dev/null; then
    install_neovim
else
    NVIM_VER=$(nvim --version | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+')
    if [ "$(printf '%s\n' "$REQUIRED_NVIM" "$NVIM_VER" | sort -V | head -1)" != "$REQUIRED_NVIM" ]; then
        echo "  Neovim $NVIM_VER found, but $REQUIRED_NVIM+ required. Upgrading..."
        install_neovim
    else
        echo "  Neovim $NVIM_VER already installed (meets $REQUIRED_NVIM+ requirement)"
    fi
fi

# Install Node.js (for LSP servers)
echo "[3/7] Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "  Node.js already installed: $(node --version)"
fi

# Install Python and pip
echo "[4/7] Installing Python dependencies..."
sudo apt install -y python3 python3-pip python3-venv

# Create nvim python venv and install pyright
echo "  Setting up Python venv for nvim..."
if [ ! -d "$HOME/.venv/nvim" ]; then
    python3 -m venv "$HOME/.venv/nvim"
fi
"$HOME/.venv/nvim/bin/pip" install --upgrade pip pyright pynvim

# Install LSP servers
echo "[5/7] Installing LSP servers..."
# TypeScript/JavaScript
sudo npm install -g typescript typescript-language-server
# C/C++
sudo apt install -y clangd

# Install OpenCode
echo "[6/7] Installing OpenCode..."
if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
    curl -fsSL https://opencode.ai/install | bash
else
    echo "  OpenCode already installed"
fi

# Install Nerd Font (JetBrainsMono)
echo "[7/7] Installing Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    mkdir -p "$FONT_DIR"
    cd /tmp
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip -d "$FONT_DIR"
    rm JetBrainsMono.zip
    fc-cache -fv > /dev/null 2>&1
    echo "  JetBrainsMono Nerd Font installed"
    echo "  NOTE: Set your terminal font to 'JetBrainsMono Nerd Font'"
else
    echo "  Nerd Font already installed"
fi

# Backup and install nvim config
echo ""
echo "Installing nvim config..."
if [ -d "$NVIM_DIR" ]; then
    echo "  Backing up existing config to ~/.config/nvim.bak"
    rm -rf "$NVIM_DIR.bak"
    mv "$NVIM_DIR" "$NVIM_DIR.bak"
fi

git clone "$REPO_URL" "$NVIM_DIR"
rm -f "$NVIM_DIR/install.sh"

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Set your terminal font to 'JetBrainsMono Nerd Font'"
echo "  2. Run 'nvim' - plugins will auto-install on first launch"
echo "  3. Run ':Copilot auth' in nvim to setup GitHub Copilot"
echo "  4. Run 'opencode' to configure OpenCode AI"
echo ""
