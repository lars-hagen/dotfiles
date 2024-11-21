# My Development Environment Setup

This repository contains my dotfiles and automated setup for development environment. Detailed documentation is available in the [Wiki](wiki/).

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Install Homebrew if not already installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Install packages using Homebrew bundle:
```bash
brew bundle
```

4. Run the installation script:
```bash
./install.sh
```

## Core Components

### Shell Environment
- **Shell**: ZSH with [custom configuration](wiki/ZSH-Core-Configuration.md)
- **Prompt**: [Starship](wiki/ZSH-Tools-and-Plugins.md#shell-prompt) - Minimal, blazing-fast prompt
- **Plugins**: 
  - [zsh-autosuggestions](wiki/ZSH-Tools-and-Plugins.md#zsh-autosuggestions) - Command suggestions
  - [zsh-syntax-highlighting](wiki/ZSH-Tools-and-Plugins.md#zsh-syntax-highlighting) - Command validation
  - [fzf-tab](wiki/ZSH-Tools-and-Plugins.md#fzf-tab) - Enhanced completion
  - [fzf-tab-source](wiki/ZSH-Tools-and-Plugins.md#fzf-tab-source) - Additional sources

### Terminal Setup
- **Primary Terminal**: Alacritty (GPU-accelerated terminal emulator)
- **Quick Access**: Tabby (used for quake mode drop-down terminal)
- **Tools**: 
  - [zoxide](wiki/ZSH-Tools-and-Plugins.md#zoxide-smart-cd) (aliased to `z`) for smart directory jumping
  - [eza](wiki/ZSH-Tools-and-Plugins.md#eza-modern-ls) for modern file listing
  - [fzf](wiki/ZSH-Tools-and-Plugins.md#fuzzy-finding) with `fd` for fuzzy finding
  - `bat` for file viewing
  - `ripgrep` for searching
  - `jq` for JSON processing
  - `htop` for process management
  - `ncdu` for disk usage analysis

### Development Tools
- **Editor**: VSCode with extensions
- **Version Control**: Git + GitHub CLI (gh)
- **Containerization**: Docker
- **Infrastructure**: 
  - AWS CLI with [profile management](wiki/ZSH-Tools-and-Plugins.md#aws-integration)
  - Packer

## Documentation

Detailed documentation is available in the Wiki:

- [Installation Guide](wiki/Installation-Guide.md) - Complete setup instructions
- [ZSH Core Configuration](wiki/ZSH-Core-Configuration.md) - Base ZSH setup and features
- [ZSH Tools and Plugins](wiki/ZSH-Tools-and-Plugins.md) - Extended functionality
- [Development Tools](wiki/Development-Tools.md) - Programming languages and tools

## Repository Structure
```
.dotfiles/
├── README.md          # Overview and quick start
├── Brewfile          # Managed packages and applications
├── install.sh        # Automated setup script
├── .zshrc            # Shell configuration
├── .macos            # macOS-specific settings
└── .config/          # Application configurations
    ├── alacritty/    # Alacritty terminal config
    ├── karabiner/    # Keyboard customization
    └── shell_gpt/    # AI shell assistant
```

## Key Features

- [Work/Personal mode](wiki/ZSH-Core-Configuration.md#workpersonal-mode) for separate histories
- [Modern CLI tools](wiki/ZSH-Tools-and-Plugins.md#modern-cli-tools)
- [Fuzzy finding](wiki/ZSH-Tools-and-Plugins.md#fuzzy-finding) with smart completion
- [Smart directory navigation](wiki/ZSH-Tools-and-Plugins.md#zoxide-smart-cd)
- [Shell-GPT integration](wiki/ZSH-Tools-and-Plugins.md#ai-integration)
- [AWS profile management](wiki/ZSH-Tools-and-Plugins.md#aws-integration)
- [Chrome profile integration](wiki/ZSH-Tools-and-Plugins.md#chrome-profile-integration)
- [Utility functions](wiki/ZSH-Tools-and-Plugins.md#utility-functions)

## Contributing

Feel free to fork this repository and customize it for your needs. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
