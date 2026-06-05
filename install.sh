#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo -e "${YELLOW}◆${NC}  Dry run mode\n"

echo -e "${BLUE}◆${NC}  Setting up dotfiles..."

OS=$(uname)
echo -e "   OS: ${GREEN}$OS${NC}"

# Phase 1: Homebrew
if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        echo -e "${YELLOW}◆${NC}  Installing Homebrew..."
        if [ "$DRY_RUN" = true ]; then
            echo -e "   Would run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo -e "${GREEN}◇${NC}  Homebrew installed"
        fi
    else
        echo -e "   Homebrew: ${GREEN}✓${NC}"
    fi

    # Phase 2: Brew bundle
    echo -e "${BLUE}◆${NC}  Installing packages..."
    if [ "$DRY_RUN" = true ]; then
        echo -e "   Would run: brew bundle --file=~/dotfiles/Brewfile"
    else
        brew bundle --file=~/dotfiles/Brewfile
        echo -e "${GREEN}◇${NC}  Packages installed"
    fi

    # Phase 3: fzf-tab (not in Homebrew)
    FZF_TAB_DIR="$HOME/dotfiles/fzf-tab"
    if [ ! -d "$FZF_TAB_DIR" ]; then
        echo -e "${BLUE}◆${NC}  Installing fzf-tab..."
        if [ "$DRY_RUN" = true ]; then
            echo -e "   Would clone: Aloxaf/fzf-tab → $FZF_TAB_DIR"
        else
            git clone https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
            echo -e "${GREEN}◇${NC}  fzf-tab installed"
        fi
    else
        echo -e "   fzf-tab: ${GREEN}✓${NC}"
    fi

    # Phase 4: macOS defaults
    echo -e "${BLUE}◆${NC}  Applying macOS defaults..."
    if [ "$DRY_RUN" = true ]; then
        echo -e "   Would run: ~/dotfiles/scripts/macos.sh"
    else
        ~/dotfiles/scripts/macos.sh
        echo -e "${GREEN}◇${NC}  macOS defaults applied"
    fi
fi

# Linux: just install essential packages
if [[ "$OS" == "Linux" ]]; then
    echo -e "${BLUE}◆${NC}  Linux detected — install packages manually or adapt for your distro"
fi

# Phase 4.5: OpenCode plugins (referenced by opencode.json, not in Homebrew).
# Cloned before stow so ~/.config/opencode exists as a real dir and stow does
# per-file symlinks instead of folding the whole dir into the repo.
OPENCODE_PLUGINS=(
    "git@github.com:lars-hagen/opencode-dynamic-delegate.git"
    "git@github.com:lars-hagen/opencode-copilot-hosted-auth.git"
    "git@github.com:lars-hagen/opencode-anthropic-auth.git"
)
PLUGINS_DIR="$HOME/.config/opencode/plugins"
echo -e "${BLUE}◆${NC}  Installing OpenCode plugins..."
for repo in "${OPENCODE_PLUGINS[@]}"; do
    name=$(basename "$repo" .git)
    dest="$PLUGINS_DIR/$name"
    if [ -d "$dest" ]; then
        echo -e "   $name: ${GREEN}✓${NC}"
    elif [ "$DRY_RUN" = true ]; then
        echo -e "   ${YELLOW}→${NC} Would clone: $name → $dest"
    else
        git clone "$repo" "$dest"
        if [ -f "$dest/package.json" ] && command -v bun &>/dev/null; then
            (cd "$dest" && bun install)
        fi
        echo -e "${GREEN}◇${NC}  $name installed"
    fi
done

# Phase 5: Stow dotfiles
backup_conflicts() {
    local is_dry_run=$1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local conflicts
    conflicts=$(stow -n -t ~ home 2>&1 | grep "existing target" | sed -e 's/.*existing target \(.*\) since.*/\1/' -e 's/.*existing target is not owned by stow: \(.*\)/\1/' | sed 's/^[[:space:]]*//')

    if [ -n "$conflicts" ]; then
        while IFS= read -r file; do
            if [ -e "$HOME/$file" ]; then
                if [ "$is_dry_run" = true ]; then
                    echo -e "   ${YELLOW}→${NC} Would backup: ~/$file"
                else
                    cp "$HOME/$file" "$HOME/$file.stow-backup-$timestamp"
                    rm "$HOME/$file"
                    echo -e "   ${GREEN}◇${NC} Backed up: ~/$file"
                fi
            fi
        done <<< "$conflicts"
    fi
}

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}◆${NC}  Checking dotfile links..."
    cd ~/dotfiles
    backup_conflicts true
    stow -n -t ~ home 2>/dev/null || true
    echo -e "${YELLOW}◇${NC}  Dry run complete — run without --dry-run to apply"
else
    echo -e "${BLUE}◆${NC}  Linking dotfiles..."
    cd ~/dotfiles
    backup_conflicts false
    stow -t ~ home
    echo -e "${GREEN}◇${NC}  Setup complete! Run: exec zsh"
fi
