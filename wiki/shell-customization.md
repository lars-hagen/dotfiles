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

### Standard Keys
```bash
# Basic navigation
bindkey "^[[3~" delete-char          # Delete
bindkey "^[OH" beginning-of-line     # Home
bindkey "^[OF" end-of-line          # End
bindkey "^[[A" up-line-or-search    # Up arrow
bindkey "^[[B" down-line-or-search  # Down arrow
```

### macOS Terminal Specific
```bash
# For macOS Terminal and iTerm2
bindkey ";9C" end-of-line           # Command + Right
bindkey ";9D" beginning-of-line     # Command + Left
bindkey ";3C" forward-word          # Option + Right
bindkey ";3D" backward-word         # Option + Left
```

## Completion System
```bash
# ZSH completion setup
if type brew &>/dev/null; then
    # macOS with Homebrew
    FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
else
    # Linux (or macOS without Homebrew)
    FPATH=/usr/share/zsh/site-functions:$FPATH
fi

autoload -Uz compinit
compinit

# Git completion customization
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
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

### Zoxide Integration
```bash
# Initialize zoxide
eval "$(zoxide init zsh --no-cmd)"
```

### Direnv Integration
```bash
# Initialize direnv
eval "$(direnv hook zsh)"
alias assume=". assume"
export DIRENV_LOG_FORMAT=""  # Disable verbose messages
```

## Tool Configuration

### FZF Configuration
```bash
# Use fd for path/directory completion
_fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
}
```

### Shell-GPT Integration
```bash
# Shell-GPT keybinding
zle -N _sgpt_zsh
bindkey ^l _sgpt_zsh
```

### AWS Integration
```bash
# Chrome profile for AWS SSO
export AWS_CHROME_PROFILE="Profile 1"
alias assume=". assume"
```

## PATH Configuration
```bash
# Add custom paths
export PATH="/Users/lars/.codeium/windsurf/bin:$PATH"
export PATH="$DOTFILES_DIR/bin:$PATH"
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

### AWS Profile Management
```bash
assume      # Switch AWS profiles
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

## See Also
- [ZSH Tools and Plugins](ZSH-Tools-and-Plugins.md)
- [Installation Guide](Installation-Guide.md)
- [Package Management](Package-Management.md)
