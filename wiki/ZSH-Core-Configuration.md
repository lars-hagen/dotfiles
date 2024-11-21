# ZSH Core Configuration

This page documents the core ZSH configuration and features.

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

## Prompt Configuration

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

**What it does:**
- Preserves original prompt
- Adds green [P] indicator for personal mode
- Updates automatically when switching modes

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

### macOS Specific
```bash
# Command + Arrow keys
bindkey ";9C" end-of-line           # Command + Right
bindkey ";9D" beginning-of-line     # Command + Left
bindkey ";3C" forward-word          # Option + Right
bindkey ";3D" backward-word         # Option + Left
```

## Terminal Title

```bash
# Update terminal title with current directory
precmd() {
  echo -ne "\033]0;${PWD/#$HOME/~}\007"
}

# Update terminal title with running command
preexec() {
  echo -ne "\033]0;[${1}] ${PWD/#$HOME/~}\007"
}
```

**What it does:**
- Shows current directory in terminal title
- Displays running command when executing
- Replaces home directory with ~ for cleaner display

## ZSH Options

```bash
# Prevent "no matches found" error
setopt NO_NOMATCH

# Additional options
setopt combiningchars    # Better Unicode handling
setopt login            # Login shell behavior
setopt SHARE_HISTORY    # Share history between sessions
```

## Path Configuration

```bash
# Add custom paths
export PATH=$PATH:/Users/lars/repos/reepay/reepay-cli/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.config/shell_gpt/bin
```

## Usage Examples

### Work/Personal Mode
```bash
# Switch to personal mode
toggle_mode
# Check mode (green [P] in prompt indicates personal mode)
# Switch back to work mode
toggle_mode
```

### Key Navigation
```bash
# Use Command + Arrow keys for line navigation
Command + Left   # Beginning of line
Command + Right  # End of line

# Use Option + Arrow keys for word navigation
Option + Left    # Back one word
Option + Right   # Forward one word
```

### History Search
```bash
# Use Up/Down arrows for history search
Up Arrow     # Search history backward
Down Arrow   # Search history forward
```

## Tips

1. **History Management**
   - Commands are immediately shared between sessions
   - Work and personal histories are completely separate
   - Large history size prevents losing old commands

2. **Terminal Title**
   - Glance at terminal title to see current directory
   - Running commands appear in brackets
   - Home directory is shown as ~ for clarity

3. **Key Bindings**
   - Use Command+Arrow for quick line navigation
   - Option+Arrow for word-by-word movement
   - Standard keys work as expected across systems

## See Also
- [ZSH Tools and Plugins](ZSH-Tools-and-Plugins.md)
- [Installation Guide](Installation-Guide.md)
