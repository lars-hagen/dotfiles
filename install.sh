#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to create a symbolic link
create_symlink() {
    local src=$1
    local dest=$2
    
    if [ -e "$dest" ]; then
        echo "Backing up existing $dest to ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    
    echo "Creating symlink: $dest -> $src"
    ln -s "$src" "$dest"
}

# Create symlinks for dotfiles
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Create symlinks for config files
create_symlink "$DOTFILES_DIR/.config/shell_gpt/functions/execute_shell.py" "$HOME/.config/shell_gpt/functions/execute_shell.py"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"

# Check if the system is macOS before creating the Aerospace symlink
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/aerospace" "$HOME/.config/aerospace"
else
    echo "Skipping Aerospace configuration (not on macOS)"
fi

echo "Dotfiles installation complete!"