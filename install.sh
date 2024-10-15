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

# Function to clone or update a git repository
clone_or_update_repo() {
    local repo_url=$1
    local target_dir=$2

    if [ -d "$target_dir" ]; then
        echo "Updating $target_dir..."
        git -C "$target_dir" pull
    else
        echo "Cloning $repo_url to $target_dir..."
        git clone "$repo_url" "$target_dir"
    fi
}

# Check for required tools
command -v git >/dev/null 2>&1 || { echo >&2 "Git is required but not installed. Aborting."; exit 1; }
command -v pipx >/dev/null 2>&1 || { echo >&2 "pipx is required but not installed. Aborting."; exit 1; }

# Confirmation prompt
read -p "This will install dotfiles and may overwrite existing files. Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Install shell-gpt via pipx
echo "Installing shell-gpt via pipx..."
pipx install shell-gpt

# Inject readchar into shell-gpt
echo "Injecting readchar into shell-gpt..."
pipx inject shell-gpt readchar

# fzf-tab-source
FZF_TAB_SOURCE_DIR="$DOTFILES_DIR/fzf-tab-source"
clone_or_update_repo "https://github.com/Freed-Wu/fzf-tab-source" "$FZF_TAB_SOURCE_DIR"

# fzf-tab
FZF_TAB_DIR="$DOTFILES_DIR/fzf-tab"
clone_or_update_repo "https://github.com/Aloxaf/fzf-tab.git" "$FZF_TAB_DIR"

# Create all symlinks
echo "Creating symlinks..."
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.config/shell_gpt/functions/execute_shell.py" "$HOME/.config/shell_gpt/functions/execute_shell.py"
create_symlink "$DOTFILES_DIR/.config/shell_gpt/bin" "$HOME/.config/shell_gpt/bin"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"

# Check if the system is macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"

    # Run .macos file
    echo "Applying macOS-specific settings..."
    source "$DOTFILES_DIR/.macos"
else
    echo "Skipping karabiner, amethyst, YabaiIndicator installations, and macOS-specific settings (not on macOS)"
fi

echo "Dotfiles installation complete!"
