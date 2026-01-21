#!/bin/bash
# Neovim Config Installer

set -e

NVIM_DIR="$HOME/.config/nvim"
REPO_URL="https://github.com/koko3453/nvim-config.git"

echo "Installing Neovim config..."

# Backup existing config
if [ -d "$NVIM_DIR" ]; then
    echo "Backing up existing config to ~/.config/nvim.bak"
    mv "$NVIM_DIR" "$NVIM_DIR.bak"
fi

# Clone the repo
git clone "$REPO_URL" "$NVIM_DIR"

# Remove install script from config dir (not needed after install)
rm -f "$NVIM_DIR/install.sh"

echo ""
echo "Installation complete!"
echo "Run 'nvim' and lazy.nvim will automatically install plugins."
echo ""
echo "Dependencies you may need:"
echo "  - pyright (pip install pyright) for Python LSP"
echo "  - typescript-language-server (npm i -g typescript-language-server) for JS/TS"
echo "  - clangd (apt install clangd) for C/C++"
echo "  - A Nerd Font for icons (https://www.nerdfonts.com)"
