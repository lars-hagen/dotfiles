# Utility Scripts

This document describes the utility scripts available in the `bin/` directory of our dotfiles.

## Available Scripts

### dotfiles-manage
A utility for managing dotfiles:
- Adds new files to the dotfiles repository
- Creates appropriate symlinks
- Maintains consistent structure

Usage:
```bash
dotfiles-manage add ~/.config/some-config  # Add a new file/directory
```

### dotfiles-dump-brew
Manages the Brewfile:
- Dumps current Homebrew packages to Brewfile
- Includes formulae, casks, and VSCode extensions
- Maintains consistent formatting

Usage:
```bash
dotfiles-dump-brew  # Update Brewfile with current packages
```

## Script Conventions

1. **Naming**: Scripts follow the `dotfiles-*` naming convention
2. **Location**: All scripts are stored in `$DOTFILES_DIR/bin`
3. **Execution**: Scripts are available in PATH via `.zshrc` configuration
4. **Error Handling**: All scripts use `set -e` and `set -u` for robust error handling

## Common Features

All scripts share these common features:
1. **Directory Resolution**: Use `$DOTFILES_DIR` for consistent paths
2. **Error Checking**: Validate inputs and dependencies
3. **Helpful Messages**: Clear output for user feedback
4. **Safe Operations**: Confirm before destructive actions

## Development Guidelines

When creating new utility scripts:
1. Follow the `dotfiles-*` naming convention
2. Add to `bin/` directory
3. Make executable (`chmod +x`)
4. Use shellcheck for validation
5. Add documentation in this wiki
6. Test on both macOS and Linux if applicable
