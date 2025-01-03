#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Exit on undefined variable

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

# Install Homebrew and packages if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Installing packages from Brewfile..."
    # Count total packages (taps, brews, casks, and vscode extensions)
    total_packages=$(grep -E "^(tap|brew|cask|vscode) " Brewfile | wc -l | tr -d ' ')
    current_package=0
    
    # Use brew bundle with verbose output and capture it
    brew bundle --verbose | while read -r line; do
        if [[ $line == *"Installing"* ]]; then
            ((current_package++))
            echo -e "\033[1;34m==> \033[1;37m[$current_package/$total_packages] $line\033[0m"  # Bold blue arrow, bold white text
        elif [[ $line == *"Downloading"* ]]; then
            echo -e "\033[1;32m  -> \033[0;37m$line\033[0m"  # Bold green arrow, normal white text
        elif [[ $line == *"Pouring"* ]] || [[ $line == *"Building"* ]] || [[ $line == *"Checking"* ]]; then
            echo -e "\033[1;33m  -> \033[0;37m$line\033[0m"  # Bold yellow arrow, normal white text
        elif [[ $line == *"Error"* ]] || [[ $line == *"Warning"* ]]; then
            echo -e "\033[1;31m==> \033[1;37m$line\033[0m"  # Bold red arrow, bold white text
        fi
    done
fi

# Install pipx if missing on macOS
if ! command -v pipx >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "pipx not found. Installing via Homebrew..."
        brew install pipx
    else
        echo >&2 "pipx is required but not installed. Aborting."
        exit 1
    fi
fi

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

# Initialize and update submodules
echo "Initializing and updating submodules..."
git submodule update --init --recursive

# Create .config directory if it doesn't exist
echo "Ensuring .config directory exists..."
mkdir -p "$HOME/.config"

# Create all symlinks
echo "Creating symlinks..."
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.config/shell_gpt/functions/execute_shell.py" "$HOME/.config/shell_gpt/functions/execute_shell.py"
create_symlink "$DOTFILES_DIR/.config/shell_gpt/bin" "$HOME/.config/shell_gpt/bin"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"
create_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# Add DOTFILES_DIR to .zshrc if not already present
if ! grep -q "^export DOTFILES_DIR=" "$DOTFILES_DIR/.zshrc"; then
    # Create a temporary file
    temp_file=$(mktemp)
    # Add DOTFILES_DIR export at the top
    echo -e "# Set dotfiles directory\nexport DOTFILES_DIR=\"/Users/lars/dotfiles\"\n" > "$temp_file"
    # Append the rest of .zshrc
    cat "$DOTFILES_DIR/.zshrc" >> "$temp_file"
    # Replace original .zshrc with the new content
    mv "$temp_file" "$DOTFILES_DIR/.zshrc"
fi

# Add bin to PATH in .zshrc if not already present
if ! grep -q "export PATH=\"\$DOTFILES_DIR/bin:\$PATH\"" "$DOTFILES_DIR/.zshrc"; then
    echo -e "\n# Add dotfiles bin to PATH\nexport PATH=\"\$DOTFILES_DIR/bin:\$PATH\"" >> "$DOTFILES_DIR/.zshrc"
fi

# Check if the system is macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"
    create_symlink "$DOTFILES_DIR/.config/borders" "$HOME/.config/borders"

    # Run .macos file
    echo "Applying macOS-specific settings..."
    source "$DOTFILES_DIR/.macos"
else
    echo "Skipping karabiner amethyst YabaiIndicator installations and macOS-specific settings (not on macOS)"
fi

echo "Dotfiles installation complete!"
