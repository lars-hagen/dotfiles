# ZSH Core Configuration

This page documents the core ZSH configuration and features.

## Core Environment

```bash
# Set dotfiles directory
export DOTFILES_DIR="/Users/lars/dotfiles"
```

## History Management
```bash
# History settings
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=100000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
```

**What it does:**
- Configures a large history buffer (200,000 commands)
- Enables immediate history sharing between sessions
- Appends new commands to history file

## Work/Personal Mode
```bash
# Define history files
HISTFILE_WORK="$HOME/.zsh_history"
HISTFILE_PERSONAL="$HOME/.zsh_history_p"

# Function to switch between modes
switch_mode() {
    if [[ "$HISTFILE" == "$HISTFILE_WORK" ]]; then
        export HISTFILE="$HISTFILE_PERSONAL"
        export PERSONAL_MODE=1
    else
        export HISTFILE="$HISTFILE_WORK"
        unset PERSONAL_MODE
    fi
    fc -R  # Reload history
    zle && zle reset-prompt
}

alias toggle_mode='switch_mode'
```

**What it does:**
- Maintains separate history files for work and personal use
- Provides `toggle_mode` command to switch between modes
- Updates prompt with [P] indicator in personal mode

## Prompt and Terminal

### Prompt Configuration
```bash
# Function to update prompt
update_prompt() {
    if [[ -z "$ORIGINAL_PS1" ]]; then
        ORIGINAL_PS1=$PS1
    fi

    if [[ -n "$PERSONAL_MODE" ]]; then
        PS1="%F{green}[P]%f $ORIGINAL_PS1"
    else
        PS1=$ORIGINAL_PS1
    fi
}

precmd_functions+=(update_prompt)
```

### Terminal Title
```bash
# Update terminal title
precmd() {
    echo -ne "\033]0;${PWD/#$HOME/~}\007"
}

preexec() {
    echo -ne "\033]0;[${1}] ${PWD/#$HOME/~}\007"
}
```

**What they do:**
- Preserves original prompt
- Adds green [P] indicator for personal mode
- Shows current directory in terminal title
- Displays running command when executing

## Shell Options and Behavior
```bash
# Prevent "no matches found" error
setopt NO_NOMATCH          # Useful for commands like Terraform

# Additional options
setopt combiningchars      # Better Unicode handling
setopt login              # Login shell behavior
setopt SHARE_HISTORY      # Share history between sessions
```

## Key Bindings

### Standard Key Bindings
```bash
# Standard key bindings
bindkey "^[[3~" delete-char      # Delete key
bindkey "^[OH" beginning-of-line # Home key
bindkey "^[OF" end-of-line      # End key
bindkey "^[[A" up-line-or-search   # Up arrow
bindkey "^[[B" down-line-or-search # Down arrow
```

**What it does:**
- Maps common keyboard keys to their expected functions
- Enables history search with arrow keys
- Provides consistent behavior across different terminals

### Additional Navigation
```bash
# Basic navigation
bindkey ";9C" end-of-line           # Command + Right
bindkey ";9D" beginning-of-line     # Command + Left
bindkey ";3C" forward-word          # Option + Right
bindkey ";3D" backward-word         # Option + Left
```

## Directory Navigation

### Zoxide Integration
```bash
eval "$(zoxide init zsh --no-cmd)"
z() {
  if [ $# -eq 0 ]; then
    __zoxide_z
  else
    __zoxide_z "$@" && ls
  fi
}
```

**What it does:**
- Enables smart directory jumping with `z`
- Auto-lists directory contents after jumping
- Maintains a frecency database of visited directories

## Completion System

### Core Configuration
```bash
# Disable sort when completing git checkout
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format for completion groups
zstyle ':completion:*:descriptions' format '[%d]'

# Use color for single groups in fzf-tab
zstyle ':fzf-tab:*' single-group color

# Enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Prevent completion menu for better fzf-tab integration
zstyle ':completion:*' menu no

# Preview directories with eza
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'

# Configure group switching
zstyle ':fzf-tab:*' switch-group '<' '>'
```

**What it does:**
- Customizes completion behavior for different commands
- Enables colorized completion menus
- Adds preview functionality for directory navigation
- Optimizes completion for fzf-tab integration
- Allows switching between completion groups with < and >

### ZSH Completion Setup
```bash
if type brew &>/dev/null; then
    # macOS with Homebrew
    FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
else
    # Linux (or macOS without Homebrew)
    FPATH=/usr/share/zsh/site-functions:$FPATH
fi

autoload -Uz compinit
compinit
```

## Plugin Integration

### Core Plugins
```bash
# Load ZSH plugins based on environment
if type brew &>/dev/null; then
    # macOS with Homebrew
    source "$DOTFILES_DIR/fzf-tab/fzf-tab.plugin.zsh"
    source "$DOTFILES_DIR/fzf-tab-source/fzf-tab-source.plugin.zsh"
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
```

### Starship Prompt
```bash
# Initialize Starship prompt
eval "$(starship init zsh)"
```

### Direnv Integration
```bash
# Initialize direnv
eval "$(direnv hook zsh)"
export DIRENV_LOG_FORMAT=""  # Disable verbose messages
```

## Tool Configurations

### FZF Integration
```bash
# Default configuration using fd
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Preview configuration
export FZF_DEFAULT_OPTS="--bind 'ctrl-/:toggle-preview'"

# Use fd for path/directory completion
_fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
}
```

**What it does:**
- Configures fd as the default file finder
- Sets up preview toggle binding
- Customizes behavior for different FZF modes
- Provides custom path completion functions using fd

### Eza Aliases
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

**What it does:**
- Replaces standard ls with eza
- Provides various listing formats
- Enables icons and colors by default
- Groups directories first

### Shell-GPT Integration
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

**What it does:**
- Binds Ctrl+L to Shell-GPT integration
- Shows loading indicator during processing
- Replaces command line with AI suggestion
- Preserves command history

## AWS Integration

### Account Aliases
```bash
# AWS account aliases
alias staging="assume reepay-staging"
alias dev="assume reepay-dev"
alias prod="assume reepay-prod"
alias pci="assume reepay-pci"
alias sandbox="assume reepay-sandbox"

# Source AWS profile management
source "$DOTFILES_DIR/bin/aws-profile-management"
```

**What it does:**
- Provides shortcuts for assuming different AWS roles
- Sources dedicated AWS profile management script
- Manages AWS profile switching and Chrome integration
- Automatically assumes AWS roles based on direnv configuration

## Custom Functions and Aliases

### Directory Tree Visualization
```bash
alias treegithub="echo 'pwd' && echo $(pwd) && echo 'tree -a -I '.git' -L 8' && tree -a -I '.git' -L 8"
```

### Temporary Script Creation
```bash
# Function to create and execute temporary scripts
temp_script() {
    local tmp_script="/tmp/script.sh"      # Path to the temporary script file

    vim "$tmp_script"                      # Open Vim to edit the script

    if [[ -s "$tmp_script" ]]; then        # Check if script is non-empty
        chmod +x "$tmp_script"             # Make the script executable
        "$tmp_script"                      # Run the script
    else
        echo "Script was empty. Nothing to run."    # Message if script was empty
    fi
}
```

**What it does:**
- Creates and executes temporary shell scripts
- Provides quick way to test shell script snippets
- Automatically handles permissions and execution

## PATH Configuration
```bash
# Add custom paths
export PATH="/Users/lars/.codeium/windsurf/bin:$PATH"
export PATH="$DOTFILES_DIR/bin:$PATH"
export PATH="$PATH:/Users/lars/repos/reepay/reepay-cli/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/shell_gpt/bin"
```

## Usage Examples

### Work/Personal Mode
```bash
toggle_mode  # Switch between work and personal mode
```

### Directory Navigation
```bash
z           # Smart directory jump
cd          # Traditional directory change
```

### AWS Role Management
```bash
staging     # Switch to staging AWS account
dev         # Switch to development AWS account
prod        # Switch to production AWS account
```

### Script Creation
```bash
temp_script # Create and run a temporary script
```

## Tips

1. **History Management**
   - Commands are immediately shared between sessions
   - Work and personal histories are completely separate
   - Large history size prevents losing old commands

2. **Terminal Integration**
   - Starship provides a modern, informative prompt
   - Terminal title shows current context
   - Key bindings match macOS expectations

3. **Development Workflow**
   - Direnv automatically loads environment variables
   - FZF provides fuzzy finding everywhere
   - Shell-GPT assists with command-line tasks
   - AWS role management is automated

## See Also
- [CLI Tools and Plugins](cli-tools-and-plugins.md)
- [Setup and Installation](setup-and-installation.md)
- [Homebrew Packages](homebrew-packages.md)
