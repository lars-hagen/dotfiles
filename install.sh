#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to create a symbolic link
create_symlink() {
    local src=$1
    local dest=$2
    
    if [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
            echo "Symlink already exists and is correct: $dest -> $src"
            return
        else
            echo "Incorrect symlink exists. Removing and recreating: $dest"
            rm "$dest"
        fi
    elif [ -e "$dest" ]; then
        echo "Removing existing file: $dest"
        rm -rf "$dest"
    fi
    
    echo "Creating symlink: $dest -> $src"
    ln -s "$src" "$dest"
}

# Check for required tools
command -v git >/dev/null 2>&1 || { echo >&2 "Git is required but not installed. Aborting."; exit 1; }

# Confirmation prompt
read -p "This will install dotfiles and may overwrite existing files. Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Create symlinks for dotfiles
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Create symlinks for config files
create_symlink "$DOTFILES_DIR/.config/shell_gpt/functions/execute_shell.py" "$HOME/.config/shell_gpt/functions/execute_shell.py"
create_symlink "$DOTFILES_DIR/.config/shell_gpt/bin" "$HOME/.config/shell_gpt/bin"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"

# fzf-tab-source
FZF_TAB_SOURCE_DIR="$DOTFILES_DIR/fzf-tab-source"
if [ -d "$FZF_TAB_SOURCE_DIR" ]; then
    echo "fzf-tab-source already exists. Updating..."
    git -C "$FZF_TAB_SOURCE_DIR" pull
else
    echo "Cloning fzf-tab-source..."
    git clone https://github.com/Freed-Wu/fzf-tab-source "$FZF_TAB_SOURCE_DIR"
fi

# Check if the system is macOS before creating the Karabiner and Amethyst symlinks
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"
    create_symlink "$DOTFILES_DIR/.config/amethyst" "$HOME/.config/amethyst"
else
    echo "Skipping karabiner and amethyst configurations (not on macOS)"
fi

echo "Dotfiles installation complete!"
