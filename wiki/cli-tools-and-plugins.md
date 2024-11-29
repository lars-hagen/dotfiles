# ZSH Tools and Plugins

This page documents the various tools, plugins, and integrations used to enhance the shell environment.

## Shell Prompt

### Starship
**What is it?**
- Cross-shell prompt written in Rust
- Fast and feature-rich
- Customizable through configuration

**Features:**
- Git status integration
- AWS profile display
- Command duration
- Python environment info

**Configuration:**
```bash
eval "$(starship init zsh)"
```

**Installation:**
```bash
brew install starship
```

## Core Plugins

### ZSH Completions
**What is it?**
- Enhanced completion system for ZSH
- Provides smart suggestions based on context
- Supports custom completion rules

**Features:**
- Enhanced tab completion
- Context-aware suggestions
- Custom completion styles

**Configuration:**
```bash
# Setup completion paths
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
else
  FPATH=/usr/share/zsh/site-functions:$FPATH
fi

autoload -Uz compinit
compinit
```

### ZSH Autosuggestions
**What is it?**
- Suggests commands as you type based on history
- Shows suggestions in a light gray
- Helps recall and type common commands faster

**Features:**
- Real-time command suggestions
- History-based recommendations
- Accept with right arrow key

**Configuration:**
```bash
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

### ZSH Syntax Highlighting
**What is it?**
- Real-time syntax highlighting for shell commands
- Validates commands and paths as you type
- Makes command errors visible before execution

**Features:**
- Real-time syntax highlighting
- Path validation
- Command validation
- Custom color scheme

**Configuration:**
```bash
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Custom colors
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_STYLES[default]='fg=blue'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=cyan'
```

## Fuzzy Finding

### FZF Integration
**What is it?**
- General-purpose fuzzy finder
- Enhances command-line search and selection
- Integrates with file search, history, and completion

**Features:**
- Interactive fuzzy search
- File and directory navigation
- History search with preview
- Integration with other tools

**Configuration:**
```bash
# Default configuration using fd
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Preview configuration
export FZF_DEFAULT_OPTS="--bind 'ctrl-/:toggle-preview'"
```

**Usage:**
- `Ctrl-T`: Paste selected files/folders into command line
- `Ctrl-R`: Search command history
- `Alt-C`: CD into selected directory
- `Ctrl-/`: Toggle preview window in any mode

### FZF-Tab
**What is it?**
- Replaces ZSH's default completion selection menu with fzf
- Adds preview capability to completion
- Supports grouping and filtering of completion options

**Features:**
- Enhanced completion menu
- File/directory preview
- Group support
- Custom preview commands

**Configuration:**
```bash
source $HOME/.dotfiles/fzf-tab/fzf-tab.plugin.zsh

# Preview configuration
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
```

## Modern CLI Tools

### Eza (Modern ls)
**What is it?**
- Modern replacement for `ls`
- Written in Rust for performance
- Adds colors, icons, and git integration

**Features:**
- Color-coded output
- Git status integration
- Tree view support
- Detailed file information

**Configuration:**
```bash
# Base alias
alias ls='eza -1 --color=always --group-directories-first --icons'

# Additional formats
alias lsz='eza -al --color=always --total-size --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.='eza -ald --color=always --group-directories-first --icons .*'
```

### Zoxide (Smart cd)
**What is it?**
- Smarter alternative to `cd`
- Learns your most frequently used directories
- Allows jumping to directories with fuzzy matching

**Features:**
- Automatic directory tracking
- Fuzzy directory matching
- Frequency-based ranking
- Integration with `ls` after jumps

**Configuration:**
```bash
eval "$(zoxide init zsh --no-cmd)"
z() {
  if [ $# -eq 0 ]; then
    __zoxide_z
  else
    __zoxide_z "$@" && ls
  fi
}
alias cd='z'
```

**Usage:**
- `z foo` - Jump to highest ranked directory matching foo
- `z foo bar` - Jump to highest ranked directory matching foo and bar
- `z -` - Jump to previous directory

## AI Integration

### Shell-GPT
**What is it?**
- AI-powered command-line assistant
- Helps generate and explain shell commands
- Integrates with OpenAI's GPT models

**Features:**
- AI-powered command assistance
- Command explanation
- Non-blocking operation
- Custom key binding

**Configuration:**
```bash
_sgpt_zsh() {
if [[ -n "$BUFFER" ]]; then
    _sgpt_prev_cmd=$BUFFER
    BUFFER+="⌛"
    zle -I && zle redisplay
    BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd" --no-interaction)
    zle end-of-line
fi
}
zle -N _sgpt_zsh
bindkey ^l _sgpt_zsh
```

**Usage:**
1. Type a command or question
2. Press Ctrl+L
3. Wait for ⌛ indicator
4. Get AI-suggested command

## AWS Integration

### Account Aliases
**What is it?**
- Quick shortcuts for AWS profile switching
- Integrates with granted for role assumption
- Supports multiple environments

**Configuration:**
```bash
alias assume=". assume"
alias staging="assume reepay-staging"
alias dev="assume reepay-dev"
alias prod="assume reepay-prod"
alias pci="assume reepay-pci"
alias sandbox="assume reepay-sandbox"
```

### Automatic AWS SSO Role Assumption with direnv and Chrome Profiles
**What is it?**
A directory-aware automation system that:
- Manages environment variables using direnv (loading/unloading based on directory)
- Handles AWS SSO authentication and role assumption automatically
- Integrates with Chrome profiles for seamless SSO login

**Key Features:**
- Automatic environment switching based on project directories
- Smart credential refresh and AWS role management
- Chrome profile integration for SSO authentication
- Silent operation with configurable logging

**Configuration:**
```bash
# Enable direnv and assume alias
eval "$(direnv hook zsh)"
alias assume=". assume"

# Chrome profile configuration for AWS SSO login
# - Leave empty ("") if not using Chrome
# - Specify profile name if using a different Chrome profile for work (e.g., "Work")
CHROME_PROFILE="Default"

# AWS assume function
run_assume() {
    if [[ -n "$CHROME_PROFILE" ]]; then
        FORCE_NO_ALIAS=true assume "$1" --es --browser-launch-template-arg "--profile-directory=$CHROME_PROFILE"
    else
        FORCE_NO_ALIAS=true assume "$1" --es
    fi
}

# Hook for direnv to check AWS_PROFILE and run assume
direnv_hook_for_envrc() {
    if [[ -n "$DIRENV_DIR" && -n "$AWS_PROFILE" ]]; then
        run_assume "$AWS_PROFILE"
    fi
}

# Add to the Direnv reload hook
precmd_functions+=(direnv_hook_for_envrc)
# Disable Direnv messages when loading a folder that contains .envrc
export DIRENV_LOG_FORMAT=""
```

**Setup:**
1. Add the configuration to your `.zshrc`
2. Ensure direnv hook is enabled: `eval "$(direnv hook zsh)"`
3. Create `.envrc` files in your project directories with:
   ```bash
   export AWS_PROFILE=your-profile-name
   # Add any other environment variables needed for the project
   ```
4. Allow the direnv file: `direnv allow`

**How it works:**
1. When entering a directory, direnv looks for `.envrc` file
2. If found, it loads environment variables (e.g., AWS_PROFILE)
3. Our hook detects the AWS_PROFILE change and triggers the assume function
4. Chrome profile is automatically used for SSO authentication
5. AWS credentials are refreshed as needed
6. When leaving the directory, environment variables are automatically unloaded

## Utility Functions

### Quick Script Creation
**What is it?**
- Quickly create and execute temporary scripts
- Useful for testing or one-off automation
- Automatically handles permissions

**Usage:**
```bash
temp_script() {
    local tmp_script="/tmp/script.sh"
    vim "$tmp_script"
    if [[ -s "$tmp_script" ]]; then
        chmod +x "$tmp_script"
        "$tmp_script"
    fi
}
```

### Repository Tree View
**What is it?**
- Enhanced tree view for git repositories
- Excludes .git directory
- Shows current path context

**Usage:**
```bash
alias treegithub="echo 'pwd' && echo $(pwd) && echo 'tree -a -I '.git' -L 8' && tree -a -I '.git' -L 8"
```

## Installation

```bash
# Core tools
brew install starship zoxide eza fzf fd

# ZSH plugins
brew install zsh-autosuggestions zsh-syntax-highlighting

# AWS tools
brew install common-fate/granted/granted

# Additional tools
brew install direnv tree bat

# Shell-GPT
pipx install shell-gpt
pipx inject shell-gpt readchar
```

## See Also
- [ZSH Core Configuration](shell-customization.md)
- [Installation Guide](setup-and-installation.md)
- [Window Management](window-management.md)
