# ZSH Tools and Plugins

This page documents the various tools, plugins, and integrations used to enhance the shell environment.

## Shell Prompt

### Starship
```bash
eval "$(starship init zsh)"
```

**What is it?**
- Cross-shell prompt written in Rust
- Fast and feature-rich
- Customizable through configuration

**Features:**
- Git status integration
- AWS profile display
- Command duration
- Python environment info

**Installation:**
```bash
brew install starship
```

## Core Plugins

### ZSH Completions
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

**Features:**
- Enhanced tab completion
- Context-aware suggestions
- Custom completion styles

### ZSH Autosuggestions
```bash
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

**What it does:**
- Shows command suggestions as you type
- Based on command history
- Accept with right arrow key

### ZSH Syntax Highlighting
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

**Features:**
- Real-time syntax highlighting
- Path validation
- Command validation
- Custom color scheme

## Fuzzy Finding

### FZF Integration
```bash
# Default configuration using fd
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Preview configuration
export FZF_DEFAULT_OPTS="--bind 'ctrl-/:toggle-preview'"
```

### FZF-Tab
```bash
source $HOME/.dotfiles/fzf-tab/fzf-tab.plugin.zsh

# Preview configuration
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
```

### FZF-Tab-Source
```bash
source $HOME/.dotfiles/fzf-tab-source/fzf-tab-source.plugin.zsh
```

**Key Features:**
- Enhanced completion menu
- File/directory preview
- Group support
- Custom preview commands

## Modern CLI Tools

### Eza (Modern ls)
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

## AI Integration

### Shell-GPT
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

**Features:**
- AI-powered command assistance
- Bound to Ctrl+L
- Non-blocking operation

## AWS Integration

### Account Aliases
```bash
alias assume=". assume"
alias staging="assume reepay-staging"
alias dev="assume reepay-dev"
alias prod="assume reepay-prod"
alias pci="assume reepay-pci"
alias sandbox="assume reepay-sandbox"
```

### Direnv Integration
```bash
export CHROME_PROFILE="Default"
eval "$(direnv hook zsh)"

# AWS profile auto-switching
direnv_hook_for_envrc() {
    run_assume() {
        if [[ -n "$CHROME_PROFILE" && "$CHROME_PROFILE" != "Default" ]]; then
            FORCE_NO_ALIAS=true assume "$AWS_PROFILE" --es --browser-launch-template-arg "profile-directory=Profile $CHROME_PROFILE"
        else
            FORCE_NO_ALIAS=true assume "$AWS_PROFILE" --es
        fi
        export LAST_ASSUME_TIME=$(date +%s)
    }

    if [[ -n "$DIRENV_DIR" && -n "$AWS_PROFILE" ]]; then
        local current_time=$(date +%s)
        if [[ -z "$LAST_ASSUME_TIME" ]] || (( current_time - LAST_ASSUME_TIME >= 1800 )); then
            run_assume
        fi
    fi
}

precmd_functions+=(direnv_hook_for_envrc)
export DIRENV_LOG_FORMAT=""
```

## Utility Functions

### Quick Script Creation
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
```bash
alias treegithub="echo 'pwd' && echo $(pwd) && echo 'tree -a -I '.git' -L 8' && tree -a -I '.git' -L 8"
```

## Usage Tips

### FZF Navigation
- **Ctrl+T**: File search
- **Ctrl+R**: History search
- **Alt+C**: Directory jump
- **Ctrl+/**: Toggle preview

### Completion System
- Use Tab for completion
- Arrow keys to navigate options
- `<` and `>` to switch groups
- Preview window shows file/directory content

### AWS Workflow
1. Set up .envrc with AWS_PROFILE
2. Directory change triggers profile switch
3. Credentials refresh every 30 minutes
4. Chrome profile handles SSO

### Shell-GPT Usage
1. Type a command or question
2. Press Ctrl+L
3. Wait for ⌛ indicator
4. Get AI-suggested command

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
- [ZSH Core Configuration](ZSH-Core-Configuration.md)
- [Installation Guide](Installation-Guide.md)
