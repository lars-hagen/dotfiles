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

# Function to install YabaiIndicator
install_yabai_indicator() {
    INSTALL_DIR="/Applications"
    APP_PATH="$INSTALL_DIR/YabaiIndicator.app"

    if [ -d "$APP_PATH" ]; then
        echo "YabaiIndicator is already installed in $APP_PATH"
        return
    fi

    echo "Installing YabaiIndicator..."

    DOWNLOAD_URL="https://github.com/xiamaz/YabaiIndicator/releases/latest/download/YabaiIndicator-0.3.4.zip"
    TEMP_ZIP="/tmp/YabaiIndicator_temp.zip"

    if curl -L "$DOWNLOAD_URL" -o "$TEMP_ZIP"; then
        if file "$TEMP_ZIP" | grep -q "Zip archive data"; then
            sudo unzip -o "$TEMP_ZIP" -d "$INSTALL_DIR"
            rm "$TEMP_ZIP"
            sudo mv "$INSTALL_DIR/YabaiIndicator-0.3.4/YabaiIndicator.app" "$INSTALL_DIR/"
            sudo rm -rf "$INSTALL_DIR/YabaiIndicator-0.3.4"
            echo "YabaiIndicator installed successfully in $INSTALL_DIR"
        else
            echo "Error: Downloaded file is not a valid zip archive."
            rm "$TEMP_ZIP"
        fi
    else
        echo "Error: Failed to download YabaiIndicator."
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

# Check if the system is macOS before creating the Karabiner and Amethyst symlinks
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"
    create_symlink "$DOTFILES_DIR/.config/amethyst" "$HOME/.config/amethyst"

    # Install YabaiIndicator
    install_yabai_indicator
else
    echo "Skipping karabiner, amethyst, and YabaiIndicator installations (not on macOS)"
fi

echo "Dotfiles installation complete!"
