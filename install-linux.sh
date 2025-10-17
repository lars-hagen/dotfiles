#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Exit on undefined variable

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to create a symbolic link
create_symlink() {
    local src=$1
    local dest=$2

    # Create parent directories if they don't exist
    local dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    if [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
            echo "✓ Symlink already exists: $dest -> $src"
            return
        else
            echo "⚠ Incorrect symlink exists. Removing and recreating: $dest"
            rm "$dest"
        fi
    elif [ -e "$dest" ]; then
        echo "⚠ Backing up existing file: $dest -> $dest.backup"
        mv "$dest" "$dest.backup"
    fi

    echo "→ Creating symlink: $dest -> $src"
    ln -s "$src" "$dest"
}

echo "======================================"
echo "  Dotfiles Installation (Linux)"
echo "======================================"
echo ""

#whats up!

# Check for required tools
command -v git >/dev/null 2>&1 || { echo "❌ Git is required but not installed. Aborting."; exit 1; }

# Confirmation prompt
read -p "This will install dotfiles and may overwrite existing files. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
echo "Step 1: Installing required packages..."
echo "========================================"

# Install packages
sudo apt update
sudo apt install -y \
    zsh \
    tree \
    zsh-autosuggestions \
    zsh-syntax-highlighting

# Install fd (fast alternative to find)
if ! command -v fd >/dev/null 2>&1; then
    echo "Installing fd..."
    FD_VERSION="10.3.0"
    wget -q "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd_${FD_VERSION}_amd64.deb" -O /tmp/fd.deb
    sudo dpkg -i /tmp/fd.deb
    rm /tmp/fd.deb
fi

# Install bat (better cat)
if ! command -v bat >/dev/null 2>&1; then
    echo "Installing bat..."
    BAT_VERSION="0.24.0"
    wget -q "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_amd64.deb" -O /tmp/bat.deb
    sudo dpkg -i /tmp/bat.deb
    rm /tmp/bat.deb
fi

# Install fzf binaries (submodule already cloned in Step 2)
if ! command -v fzf >/dev/null 2>&1; then
    echo "Installing fzf binaries..."
    "$DOTFILES_DIR/fzf/install" --all --no-bash --no-fish --xdg
fi

# Install eza (modern ls replacement)
if ! command -v eza >/dev/null 2>&1; then
    echo "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# Install zoxide (smart cd)
if ! command -v zoxide >/dev/null 2>&1; then
    echo "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# Install starship prompt
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo ""
echo "Step 2: Setting up git submodules..."
echo "========================================"
git submodule update --init --recursive

echo ""
echo "Step 3: Creating symlinks..."
echo "========================================"
mkdir -p "$HOME/.config"

# Create symlink for .zshrc
create_symlink "$DOTFILES_DIR/.zshrc.linux" "$HOME/.zshrc"

echo ""
echo "======================================"
echo "✓ Dotfiles installation complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Install FiraCode Nerd Font (if not already installed)"
echo "2. Set zsh as your default shell: chsh -s \$(which zsh)"
echo "3. Restart your terminal"
echo ""
echo "Optional:"
echo "- Install GNOME extensions for better window management"
echo "- Configure your terminal font to 'FiraCode Nerd Font Mono'"
