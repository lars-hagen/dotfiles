# Installation Guide

This guide walks you through setting up your development environment using these dotfiles.

## Prerequisites

Before you begin, ensure you have:
- A macOS system
- Command Line Tools for Xcode installed
- Administrator access to your machine

## Step-by-Step Installation

### 1. Install Command Line Tools

```bash
xcode-select --install
```

### 2. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Clone the Repository

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 4. Install Required Packages

The Brewfile includes all necessary packages and applications:

```bash
brew bundle
```

This will install:
- Core utilities (eza, bat, ripgrep, etc.)
- Development tools (VSCode, Docker, etc.)
- Terminal emulators (Alacritty for primary use, Tabby for quake mode)
- Infrastructure tools (AWS CLI, Packer)
- Applications (Chrome, Slack, etc.)

### 5. Run the Installation Script

```bash
./install.sh
```

The script will:
- Clone required ZSH plugins (fzf-tab, fzf-tab-source)
- Install shell-gpt via pipx
- Create necessary symlinks
- Configure macOS-specific settings
- Set up Karabiner Elements (macOS only)

### 6. Configure Shell

The installation script will symlink the ZSH configuration:
- `.zshrc` → `~/.zshrc`
- Various config files to `~/.config/`

Restart your terminal to apply the new shell configuration.

## Post-Installation Setup

### 1. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Configure AWS CLI

```bash
aws configure
```

### 3. Set Up VSCode

1. Open VSCode
2. Install extensions (automatically listed in Brewfile)
3. Sign in to GitHub for Copilot and other GitHub features

### 4. Configure Terminal Setup

#### Alacritty (Primary Terminal)
- Configuration is automatically linked to `~/.config/alacritty`
- Verify font settings in configuration
- Test key bindings and color scheme

#### Tabby (Quake Mode)
- Configure as drop-down terminal
- Set up keyboard shortcut for quick access
- Configure preferred Nerd Font

### 5. Set Up Shell-GPT

```bash
sgpt --config-dir
```

## Verification

Test your installation by checking:

1. ZSH plugins and features:
```bash
# Test autosuggestions
echo "Test command"  # Should show suggestions

# Test fzf
ctrl-r  # Should show history search

# Test zoxide
z  # Should work for directory jumping
```

2. Development tools:
```bash
# Check versions
aws --version
docker --version
```

3. Shell-GPT:
```bash
# Test Shell-GPT
sgpt "Hello"
```

## Troubleshooting

### Common Issues

1. **Homebrew Installation Fails**
   ```bash
   # Fix permissions
   sudo chown -R $(whoami) /usr/local/share/zsh /usr/local/share/zsh/site-functions
   ```

2. **Symlinks Not Created**
   ```bash
   # Manual symlink creation
   ln -s ~/dotfiles/.zshrc ~/.zshrc
   ```

3. **ZSH Plugins Not Loading**
   ```bash
   # Verify plugin installations
   ls ~/dotfiles/fzf-tab
   ls ~/dotfiles/fzf-tab-source
   ```

### Getting Help

If you encounter issues:
1. Check the [Issues](../../issues) page
2. Review error messages in `install.sh` output
3. Verify all prerequisites are met
4. Try running problematic commands manually

## Updating

To update your environment:

```bash
# Update Homebrew packages
brew bundle

# Update dotfiles
cd ~/dotfiles
git pull

# Rerun installation script
./install.sh
```

## Next Steps

After installation, explore:
- [Shell Customization](shell-customization.md) for shell features
- [CLI Tools and Plugins](cli-tools-and-plugins.md) for tool documentation
- [Development Environment](development-environment.md) for tool-specific setup
