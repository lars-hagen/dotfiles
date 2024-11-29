# My Development Environment Setup

This repository contains my dotfiles and automated setup for development environment. Detailed documentation is available in the [Wiki](wiki/).

## Quick Start

1. Clone and install:
```bash
git clone https://github.com/lars-hagen/dotfiles.git
cd dotfiles
./install.sh
```

For detailed setup instructions, see the [Setup and Installation Guide](wiki/setup-and-installation.md).

## Overview

My development environment is built around:
- ZSH with [modern plugins and tools](wiki/cli-tools-and-plugins.md)
- [GPU-accelerated terminals](wiki/development-environment.md#terminal-setup) (Alacritty + Tabby)
- [Development tools](wiki/development-environment.md) optimized for efficiency
- [Smart CLI utilities](wiki/cli-tools-and-plugins.md#modern-cli-tools)
- [Tiling window management](wiki/window-management.md) with AeroSpace

All components are documented in detail in the wiki:
- [Setup and Installation](wiki/setup-and-installation.md) - Complete setup guide
- [Shell Customization](wiki/shell-customization.md) - ZSH configuration and features
- [CLI Tools and Plugins](wiki/cli-tools-and-plugins.md) - Command-line tools and utilities
- [Development Environment](wiki/development-environment.md) - IDE, tools, and workflows
- [Window Management](wiki/window-management.md) - AeroSpace tiling window manager setup
- [Homebrew Packages](wiki/homebrew-packages.md) - Package management
- [Dotfiles Scripts](wiki/dotfiles-scripts.md) - Utility scripts for dotfiles management

## Repository Structure
```
./
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

## Contributing

Feel free to fork this repository and customize it for your needs. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
