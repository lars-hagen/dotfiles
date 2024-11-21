# History settings (added to match Mac Zsh configuration on Linux)
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=100000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY   # Share command history between multiple zsh sessions
setopt APPEND_HISTORY

# Define history files
HISTFILE_WORK="$HOME/.zsh_history"
HISTFILE_PERSONAL="$HOME/.zsh_history_p"

# Function to switch between work and personal modes
switch_mode() {
    if [[ "$HISTFILE" == "$HISTFILE_WORK" ]]; then
        export HISTFILE="$HISTFILE_PERSONAL"
        export PERSONAL_MODE=1
    else
        export HISTFILE="$HISTFILE_WORK"
        unset PERSONAL_MODE
    fi
    fc -R  # Reload history
    zle && zle reset-prompt  # Force prompt update if zle is active
}

# Alias for switching modes
alias toggle_mode='switch_mode'

# Set initial mode (default to work mode)
export HISTFILE="$HISTFILE_WORK"

# Function to update prompt
update_prompt() {
    # Store the original PS1 if not already stored
    if [[ -z "$ORIGINAL_PS1" ]]; then
        ORIGINAL_PS1=$PS1
    fi

    if [[ -n "$PERSONAL_MODE" ]]; then
        PS1="%F{green}[P]%f $ORIGINAL_PS1"
    else
        PS1=$ORIGINAL_PS1
    fi
}

# Add the update_prompt function to precmd_functions
precmd_functions+=(update_prompt)

# Prevent "no matches found" error when using square brackets
# This is useful for commands like Terraform that use square brackets in resource addresses
setopt NO_NOMATCH

# Set options (added to match Mac Zsh configuration on Linux)
# Note: These may not have a noticeable effect but are included for consistency
setopt combiningchars  # Enable granular handling of Unicode combining characters
setopt login           # Treat this shell as a login shell (caution: may affect startup behavior)

# The following key bindings are typically missing on Linux
# They are added here to be consistent with Mac OS X behavior
# Bind the Delete key
bindkey "^[[3~" delete-char
# Bind the Home key
bindkey "^[OH" beginning-of-line
# Bind the End key
bindkey "^[OF" end-of-line
# Modify Up and Down arrow keys for better history search
bindkey "^[[A" up-line-or-search
bindkey "^[[B" down-line-or-search

# Initialize Starship prompt
eval "$(starship init zsh)"
# ZSH completion
if type brew &>/dev/null; then
  # macOS with Homebrew
  FPATH=$(brew --prefix)/share/zsh-completions:$(brew --prefix)/share/zsh/site-functions:$FPATH
else
  # Linux (or macOS without Homebrew)
  FPATH=/usr/share/zsh/site-functions:$FPATH
fi

autoload -Uz compinit
compinit

# Share history across multiple zsh sessions
setopt SHARE_HISTORY
# Detect dotfiles directory
DOTFILES_DIR=$(dirname "$(readlink -f "${(%):-%x}")")

# Load zsh-autosuggestions
if type brew &>/dev/null; then
    # macOS with Homebrew
    source "$DOTFILES_DIR/fzf-tab/fzf-tab.plugin.zsh"
    source "$DOTFILES_DIR/fzf-tab-source/fzf-tab-source.plugin.zsh"
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
    # Linux (or macOS without Homebrew)
    source "$DOTFILES_DIR/fzf-tab/fzf-tab.plugin.zsh"
    source "$DOTFILES_DIR/fzf-tab-source/fzf-tab-source.plugin.zsh"
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# zsh
source <(fzf --zsh)

# Configure zsh-syntax-highlighting colors
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_STYLES[default]='fg=blue'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=cyan'

# Replace cd command with zoxide (z) for smart directory navigation
alias cd='z'

# Alias ls to eza with desired options
alias ls='eza -1 --color=always --group-directories-first --icons'

# Preserve default ls completion for the eza alias
compdef _ls eza

alias lsz='eza -al --color=always --total-size --group-directories-first --icons' # include file size
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.='eza -ald --color=always --group-directories-first --icons .*' # show only dotfiles

# -- Use fd instead of fzf --
# Set the default command for fzf to use fd, including hidden files but excluding .git
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"

# Use the same command for CTRL-T (file/directory search) as the default command
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Set ALT-C (change directory) to only search for directories, including hidden ones but excluding .git
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}

eval "$(zoxide init zsh --no-cmd)"
z() {
  if [ $# -eq 0 ]; then
    __zoxide_z
  else
    __zoxide_z "$@" && ls
  fi
}

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'

# Use color for single groups in fzf-tab
zstyle ':fzf-tab:*' single-group color

# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# preview directory's content with eza when completing z
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'

# disable preview for options
zstyle ':fzf-tab:complete:*:options' fzf-preview ''

# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Configure zstyle for better completion behavior
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'  # Enable fuzzy matching for completions

# set default options for fzf, binding Ctrl+/ to toggle preview
export FZF_DEFAULT_OPTS="--bind 'ctrl-/:toggle-preview'"

# Shell-GPT integration ZSH v0.2
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
# Shell-GPT integration ZSH v0.2

# For macOS Terminal and iTerm2
# Keybindings for Command + Arrow keys
bindkey ";9C" end-of-line                 # Command + Right Arrow: Move to end of line
bindkey ";9D" beginning-of-line           # Command + Left Arrow: Move to beginning of line
bindkey ";3C" forward-word                # Option + Right Arrow: Move forward one word
bindkey ";3D" backward-word               # Option + Left Arrow: Move backward one word

export PATH=$PATH:/Users/lars/repos/reepay/reepay-cli/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.config/shell_gpt/bin

# AWS account aliases
alias staging="assume reepay-staging"
alias dev="assume reepay-dev"
alias prod="assume reepay-prod"
alias pci="assume reepay-pci"
alias sandbox="assume reepay-sandbox"

alias treegithub="echo 'pwd' && echo $(pwd) && echo 'tree -a -I '.git' -L 8' && tree -a -I '.git' -L 8"

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

eval "$(direnv hook zsh)"
alias assume=". assume"

# Chrome profile configuration for AWS SSO login:
# - Leave empty ("") if not using Chrome
# - Use "Default" if using Chrome's default profile
# - Specify profile name if using a different Chrome profile for work (e.g., "Work")
export CHROME_PROFILE="Default"

# Hook for direnv to check AWS_PROFILE and run assume
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

# Add to the Direnv reload hook
precmd_functions+=(direnv_hook_for_envrc)
# Disable Direnv messages when loading a folder that contains .envrc
export DIRENV_LOG_FORMAT=""

# Terminal title configuration
# Update terminal title to show current directory
precmd() {
  echo -ne "\033]0;${PWD/#$HOME/~}\007"
}

# Update terminal title to show running command and current directory
preexec() {
  echo -ne "\033]0;[${1}] ${PWD/#$HOME/~}\007"
}
