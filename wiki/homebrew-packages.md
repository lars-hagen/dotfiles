# Package Management

This document describes the package management setup using Homebrew and the included packages in our dotfiles.

## Brewfile Overview

Our `Brewfile` manages all package installations through Homebrew. It's organized into several categories:

### Custom Taps
```bash
tap "common-fate/granted"     # AWS credential management
tap "felixkratz/formulae"    # macOS window management (borders)
tap "hashicorp/tap"          # HashiCorp tools
tap "homebrew/bundle"        # Brewfile support
tap "homebrew/services"      # Service management
tap "lars-hagen/dotfiles"    # Personal tap
tap "nikitabobko/tap"        # Additional tools
```

### Core CLI Tools
- `act` - Run GitHub Actions locally
- `bat` - Modern replacement for `cat`
- `direnv` - Directory-specific environment variables
- `eza` - Modern replacement for `ls`
- `fd` - User-friendly alternative to `find`
- `ffmpeg` - Audio/video processing
- `fzf` - Fuzzy finder
- `git-filter-repo` - Git history filtering
- `git-lfs` - Git Large File Storage
- `htop` - Interactive process viewer
- `jq` - JSON processor
- `libmagic` - File type detection
- `ncdu` - NCurses disk usage
- `neovim` - Modern vim editor
- `pkgconf` - Package compiler/linker configuration
- `pipx` - Python application installer
- `ripgrep` - Fast grep replacement
- `tree` - Directory structure viewer
- `zoxide` - Smart directory jumper

### Shell and Terminal
- `zsh-autosuggestions` - Command suggestions
- `zsh-completions` - Additional completions
- `zsh-syntax-highlighting` - Command validation
- `starship` - Cross-shell prompt

### Development Tools
- `ansible` - Infrastructure automation
- `awscli` - AWS Command Line Interface
- `borders` - Window borders for macOS
- `gh` - GitHub CLI
- `granted` - AWS role management
- `maven` - Java build tool
- `node` - JavaScript runtime
- `packer` - Machine image builder
- `python@3.12`, `python@3.13` - Python runtimes
- `ruby` - Ruby runtime
- `rust` - Rust programming language
- `terraform` - Infrastructure as Code
- `tflint` - Terraform linter

### Applications (Casks)
- `aerospace` - Window manager
- `alacritty` - GPU-accelerated terminal
- `cursor` - AI-powered code editor
- `db-browser-for-sqlite` - SQLite GUI
- `docker` - Containerization platform
- `flameshot` - Screenshot tool
- `github` - GitHub desktop client
- `google-chrome` - Web browser
- `iterm2` - Terminal emulator
- `karabiner-elements` - Keyboard customization
- `maccy` - Clipboard manager for macOS
- `keybase` - Security & encryption
- `signal` - Secure messaging
- `slack` - Team communication
- `sourcetree` - Git GUI client
- `spotify` - Music streaming
- `tabby` - Modern terminal
- `tunnelblick` - OpenVPN client
- `visual-studio-code` - Code editor
- `windsurf` - AI-powered code editor

### Fonts
- `font-fira-code-nerd-font` - Primary coding font
- `font-hack-nerd-font` - Alternative coding font
- `font-source-code-pro` - Source Code Pro font

### VSCode Extensions
- GitHub Integration:
  - `github.copilot` - AI pair programmer
  - `github.copilot-chat` - AI chat interface
  - `github.vscode-github-actions` - GitHub Actions
  - `github.vscode-pull-request-github` - PR management
  - `eamodio.gitlens` - Git supercharged
  - `mhutchie.git-graph` - Git graph viewer
- Development Tools:
  - `4ops.terraform` - Terraform support
  - `chop-dbhi.multiline-string-editor` - String editing
  - `dbaeumer.vscode-eslint` - JavaScript linting
  - `fooxly.workspace` - Workspace management
  - `gruntfuggly.todo-tree` - TODO comments
  - `kevinrose.vsc-python-indent` - Python indentation
  - `mechatroner.rainbow-csv` - CSV/TSV viewer
  - `ms-python.python` - Python support
  - `ms-python.debugpy` - Python debugging
  - `ms-python.vscode-pylance` - Python language server
  - `tamasfe.even-better-toml` - TOML support

## Managing Packages

### Update Brewfile
To update the Brewfile with new packages:
```bash
dotfiles-dump-brew
```

### Install Packages
To install all packages from Brewfile:
```bash
brew bundle
```

### Clean Up
To remove unused dependencies:
```bash
brew cleanup
```

## Package Selection Principles

1. **Modern Alternatives**: Prefer modern replacements for traditional Unix tools (e.g., `eza` over `ls`)
2. **Development Focus**: Include tools that enhance development workflow
3. **Cross-Platform**: Select tools that work across different environments
4. **AI Integration**: Incorporate AI-powered development tools
5. **Performance**: Choose tools optimized for speed and efficiency
