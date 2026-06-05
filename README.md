# dotfiles

macOS configuration using Homebrew + GNU Stow for dotfiles.

## Quick Start

```bash
git clone https://github.com/lars-hagen/dotfiles.git ~/dotfiles

# Preview
~/dotfiles/install.sh --dry-run

# Install
~/dotfiles/install.sh

exec zsh
```

## Structure

```
~/dotfiles/
├── Brewfile         # All packages (brews + casks)
├── install.sh       # Bootstrap script
├── scripts/
│   └── macos.sh     # macOS system defaults
└── home/            # Stowed to ~
    ├── .zshrc
    └── Library/Application Support/...
```

## What's Installed

**Packages**: git, neovim, fzf, fd, starship, eza, stow, node@22, pnpm, python, bun, uv, htop, btop, ncdu, gh, jq, rclone, rustup, ffmpeg, macmon, aria2

**Casks**: 1password, claude, ghostty, google-chrome, google-cloud-sdk, localsend, monitorcontrol, obsidian, proxyman, raycast, shottr, spotify, tart, telegram-desktop, visual-studio-code

**System Settings**: Fast key repeat, hidden files visible, dock auto-hide, list view, mouse linear tracking, Spotlight Cmd+Space disabled

**Shell**: zsh with autosuggestions, syntax-highlighting, fzf-tab, fzf keybindings (Ctrl+R/T, Alt+C)

## Usage

### Update packages
```bash
brew bundle --file=~/dotfiles/Brewfile
```

### Edit dotfiles
Files are symlinked — edit directly:
```bash
vim ~/.zshrc
cd ~/dotfiles && git add -A && git commit
```

### Add new dotfiles
```bash
cp ~/.gitconfig ~/dotfiles/home/.gitconfig
stow -t ~ home
```

### Re-apply macOS defaults
```bash
~/dotfiles/scripts/macos.sh
```

## Manual Stow Commands

```bash
stow -t ~ home     # Link dotfiles
stow -D -t ~ home  # Unlink
stow -R -t ~ home  # Restow (after structure changes)
```
