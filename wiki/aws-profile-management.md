# AWS Profile Management

This document describes the AWS profile management script located at `bin/aws-profile-management`.

## Overview

The script provides automated AWS profile management with Chrome integration for SSO login and direnv hooks for automatic profile assumption. It handles the technical aspects of AWS role assumption, particularly focusing on browser integration and automatic profile switching through direnv.

## Requirements

- direnv: For loading/unloading environment variables
- granted: For AWS credentials management and role assumption

### Installation

```bash
# Install direnv
brew install direnv

# Install granted
brew tap common-fate/granted
brew install common-fate/granted/granted
```

## Configuration

### Chrome Profile
```bash
# Chrome profile configuration for AWS SSO login:
# - Leave empty ("") if not using Chrome
# - Specify profile name if using a different Chrome profile for work (e.g., "Work")
CHROME_PROFILE="Default"
```

**What it does:**
- Configures which Chrome profile to use for AWS SSO login
- Allows separation of work and personal AWS logins
- Can be disabled by setting to empty string

## Core Functions

### AWS Assume Function
```bash
run_assume() {
    if [[ -n "$CHROME_PROFILE" ]]; then
        FORCE_NO_ALIAS=true assume "$1" --es --browser-launch-template-arg "--profile-directory=$CHROME_PROFILE"
    else
        FORCE_NO_ALIAS=true assume "$1" --es
    fi
}
```

**What it does:**
- Handles AWS role assumption with Chrome profile integration
- Uses `--es` flag for enhanced security
- Configures browser launch with specific Chrome profile
- Falls back to default behavior if no Chrome profile is set

### Direnv Integration
```bash
direnv_hook_for_envrc() {
    if [[ -n "$DIRENV_DIR" && -n "$AWS_PROFILE" ]]; then
        run_assume "$AWS_PROFILE"
    fi
}

# Add to the Direnv reload hook
precmd_functions+=(direnv_hook_for_envrc)
```

**What it does:**
- Automatically assumes AWS roles based on direnv configuration
- Triggers when entering directories with .envrc files
- Checks for presence of AWS_PROFILE in environment
- Integrates with shell's precmd hook system

## Setup and Usage

### Basic Setup
1. Create an `.envrc` file in your project directory:
   ```bash
   export AWS_PROFILE=your-profile-name
   ```
2. Allow the configuration:
   ```bash
   direnv allow
   ```

### How It Works
1. When you enter a directory, direnv checks for an `.envrc` file
2. If found, it loads the AWS_PROFILE environment variable
3. The direnv hook automatically runs assume with the configured Chrome profile
4. When leaving the directory, the environment is automatically unloaded

### Integration
The script is automatically sourced by .zshrc:
```bash
source "$DOTFILES_DIR/bin/aws-profile-management"
```

## Tips

1. **Chrome Profile Management**
   - Use separate Chrome profiles for different AWS organizations
   - Set CHROME_PROFILE="" to disable Chrome integration
   - Profile names are case-sensitive

2. **Security Considerations**
   - Script uses FORCE_NO_ALIAS for explicit role assumption
   - Enhanced security mode is always enabled (--es flag)
   - Automatic role assumption only occurs in directories with .envrc

3. **Direnv Integration**
   - Automatic profile switching is seamless
   - No manual intervention needed after initial setup
   - Works alongside other direnv configurations

## See Also
- [Shell Customization](shell-customization.md)
- [Development Environment](development-environment.md)
- [CLI Tools and Plugins](cli-tools-and-plugins.md)
