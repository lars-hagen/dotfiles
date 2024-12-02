# My Development Environment Setup

This repository contains my dotfiles and automated setup for development environment. Detailed documentation is available in the [Wiki](../../wiki).

## Quick Start

1. Clone with submodules:
```bash
git clone --recurse-submodules https://github.com/lars-hagen/dotfiles.git
cd dotfiles
./install.sh
```

Or if you already cloned without submodules:
```bash
git submodule update --init --recursive
```

For detailed setup instructions, see the [Setup and Installation Guide](../../wiki/Setup-And-Installation).

## Core Components

- Modern ZSH environment with smart plugins and tools
- GPU-accelerated terminals (Alacritty, Tabby)
- VSCode with AI-powered assistance
- Docker for containerization
- Tiling window management with AeroSpace
- AWS profile management with Chrome integration
- Automated package management through Homebrew

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

## Submodules

This repository uses Git submodules for managing dependencies. Submodule updates are automatically managed by Dependabot, which creates pull requests when updates are available.

## Contributing

Feel free to fork this repository and customize it for your needs. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
