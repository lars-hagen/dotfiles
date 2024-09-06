#!/bin/bash

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
create_symlink "$DOTFILES_DIR/.config/shell_gpt/bin" "$HOME/.config/shell_gpt/bin"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"

# fzf-tab-source
git clone https://github.com/Freed-Wu/fzf-tab-source

# Check if the system is macOS before creating the Aerospace symlink
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/aerospace" "$HOME/.config/aerospace"
else
    echo "Skipping Aerospace configuration (not on macOS)"
fi

echo "Dotfiles installation complete!"