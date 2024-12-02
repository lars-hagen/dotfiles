# My Development Environment Setup

This repository contains my dotfiles and automated setup for development environment. Detailed documentation is available in the [Wiki](../../wiki).

## Quick Start

1. Clone and install:
```bash
git clone https://github.com/lars-hagen/dotfiles.git
cd dotfiles
./install.sh
```

For detailed setup instructions, see the [Setup and Installation Guide](../../wiki/Setup-And-Installation).

## Core Components

### Shell Environment
- Modern ZSH setup with [smart plugins and tools](../../wiki/CLI-Tools-And-Plugins)
- Efficient [shell customization](../../wiki/Shell-Customization) for productivity
- Advanced command-line completion and fuzzy finding

### Development Tools
- [GPU-accelerated terminals](../../wiki/Development-Environment#terminal-setup)
  - Alacritty as primary terminal
  - Tabby for quake-style dropdown
- Comprehensive [development environment](../../wiki/Development-Environment)
  - VSCode with AI-powered assistance
  - Docker for containerization
  - Advanced Git integration
- [Smart CLI utilities](../../wiki/CLI-Tools-And-Plugins#modern-cli-tools)
  - Modern alternatives to traditional tools
  - AI-powered shell assistance
  - Efficient file navigation

### System Configuration
- [Tiling window management](../../wiki/Window-Management) with AeroSpace
- [AWS profile management](../../wiki/AWS-Profile-Management) with Chrome integration
- Automated [package management](../../wiki/Homebrew-Packages) through Homebrew

## Documentation

All components are documented in detail in the wiki:

### Setup and Configuration
- [Setup and Installation](../../wiki/Setup-And-Installation) - Complete setup guide
- [Shell Customization](../../wiki/Shell-Customization) - ZSH configuration and features
- [CLI Tools and Plugins](../../wiki/CLI-Tools-And-Plugins) - Command-line tools and utilities

### Development Environment
- [Development Environment](../../wiki/Development-Environment) - IDE, tools, and workflows
- [AWS Profile Management](../../wiki/AWS-Profile-Management) - AWS role assumption and Chrome integration
- [Window Management](../../wiki/Window-Management) - AeroSpace tiling window manager setup

### System Management
- [Homebrew Packages](../../wiki/Homebrew-Packages) - Package management
- [Dotfiles Scripts](../../wiki/Dotfiles-Scripts) - Utility scripts for dotfiles management

## Repository Structure
```
./
├── README.md              # Overview and quick start
├── Brewfile              # Managed packages and applications
├── install.sh            # Automated setup script
├── .zshrc                # Shell configuration
├── .macos                # macOS-specific settings
├── .aerospace.toml       # AeroSpace window manager config
├── .config/              # Application configurations
│   ├── borders/         # Window border customization
│   ├── karabiner/       # Keyboard customization
│   ├── nvim/            # Neovim configuration
│   └── shell_gpt/       # AI shell assistant
├── bin/                  # Utility scripts
│   ├── aws-profile-management    # AWS profile and Chrome integration
│   ├── dotfiles-dump-brew       # Update Brewfile from current packages
│   ├── dotfiles-manage          # Dotfiles management utilities
│   └── dotfiles-update-brew-wiki # Update Homebrew packages documentation
└── Library/              # macOS Library configurations
```

## Contributing

Feel free to fork this repository and customize it for your needs. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
