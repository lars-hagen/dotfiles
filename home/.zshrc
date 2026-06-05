typeset -U PATH

# Detect OS
OS=$(uname)

# Set dotfiles directory
export DOTFILES_DIR="$HOME/dotfiles"

# Set PATH early so binaries are available for initialization
export PATH=$DOTFILES_DIR/scripts/bin:$PATH
export PATH=$PATH:$HOME/.local/bin

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=100000

setopt SHARE_HISTORY     # Share command history between multiple zsh sessions (includes incremental append)
setopt EXTENDED_HISTORY  # Save timestamp and duration information
setopt HIST_LEX_WORDS    # Better word parsing for history debugging

# Prevent "no matches found" error when using square brackets
setopt NO_NOMATCH

# Enable inline comments in interactive shell (bash compatibility)
setopt INTERACTIVE_COMMENTS

# Hide the percent sign for missing newlines (still preserves output)
PROMPT_EOL_MARK=''

# Filter out VSCode Augment extension's terminal capability test from history
zshaddhistory() {
  # Skip VSCode Augment extension's terminal capability test command
  [[ $1 == "echo 'Terminal capability test'"* ]] && return 1
  return 0
}

# Initialize Starship prompt
eval "$(starship init zsh)"

# Work/personal history mode toggle (ported from v1)
HISTFILE_WORK="$HOME/.zsh_history"
HISTFILE_PERSONAL="$HOME/.zsh_history_p"
export HISTFILE="$HISTFILE_WORK"   # default to work mode

switch_mode() {
    if [[ "$HISTFILE" == "$HISTFILE_WORK" ]]; then
        export HISTFILE="$HISTFILE_PERSONAL"
        export PERSONAL_MODE=1
    else
        export HISTFILE="$HISTFILE_WORK"
        unset PERSONAL_MODE
    fi
    fc -R                     # reload history from the now-active file
    zle && zle reset-prompt   # refresh prompt if zle is active
}
alias toggle_mode='switch_mode'

# Prepend a green [P] to the starship prompt while in personal mode.
# Registered after starship so it runs later in precmd and can amend $PROMPT.
_personal_mode_indicator() {
    [[ -n "$PERSONAL_MODE" ]] && PROMPT="%F{green}[P]%f $PROMPT"
}
precmd_functions+=(_personal_mode_indicator)

# ZSH completion setup (OS-specific)
if [[ "$OS" == "Darwin" ]]; then
    FPATH=/opt/homebrew/share/zsh/site-functions:$FPATH
else
    FPATH=/usr/share/zsh/site-functions:$FPATH
fi

# Add dotfiles bin to completion path
fpath=($DOTFILES_DIR/scripts/bin $fpath)

# Optimize completion system
autoload -Uz compinit
# Only regenerate compdump once a day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Configure zsh-syntax-highlighting colors (must be set before plugin loads)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_STYLES[default]='fg=blue'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[comment]='fg=246'

# Load zsh plugins and fzf keybindings (Homebrew)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f $DOTFILES_DIR/fzf-tab/fzf-tab.plugin.zsh ]] && source $DOTFILES_DIR/fzf-tab/fzf-tab.plugin.zsh
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh

# Disable npm preview
zstyle ':fzf-tab:complete:npm:' fzf-preview ''

# Disable pnpm preview
zstyle ':fzf-tab:complete:pnpm:' fzf-preview ''

# Only use eza aliases in interactive shells (not Claude Code)
if [[ -z "$CLAUDECODE" ]]; then
  # Alias ls to eza with desired options
  alias ls='eza -1 --color=auto --group-directories-first --icons'

  # Preserve default ls completion for the eza alias
  compdef _ls eza

  alias lsz='eza -al --color=auto --total-size --group-directories-first --icons' # include file size
  alias la='eza -a --color=auto --group-directories-first --icons'  # all files and dirs
  alias ll='eza -l --color=auto --group-directories-first --icons'  # long format
  alias lt='eza -aT --color=auto --group-directories-first --icons' # tree listing
  alias l.='eza -ald --color=auto --group-directories-first --icons .*' # show only dotfiles
fi

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
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=auto $realpath'

# disable preview for options
zstyle ':fzf-tab:complete:*:options' fzf-preview ''

# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Enable the use of FZF_DEFAULT_OPTS for fzf-tab (by default, fzf-tab ignores these options)
zstyle ':fzf-tab:*' use-fzf-default-opts true

# Configure zstyle for better completion behavior
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'  # Enable fuzzy matching for completions

# set default options for fzf, binding Ctrl+/ to toggle preview
export FZF_DEFAULT_OPTS="--bind 'ctrl-/:toggle-preview'"

# Environment variables
export EDITOR="code --wait"
export MAX_MCP_OUTPUT_TOKENS="50000"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="50000"

# Linux-specific
if [[ "$OS" == "Linux" ]]; then
    alias pbcopy='xsel --clipboard'
    alias pbpaste='xsel --clipboard'
    export PATH=$PATH:/usr/local/go/bin
fi

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

# Terminal title configuration
# Update terminal title to show current directory
precmd() {
  local dir="${PWD/#$HOME/~}"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local path_above_repo=${repo_root%/*}
    local path_in_repo=${PWD#$repo_root}

    # Convert path above repo to abbreviated form (~/a/b), including the last directory
    local abbreviated_path=$(echo ${path_above_repo/#$HOME/\~} | sed 's:\([^/]\)[^/]*/:\1/:g; s:/[^/]*$:/r:')

    # Handle root of repository differently
    if [[ -z "$path_in_repo" ]]; then
      dir="${abbreviated_path}/${repo_name}"
    else
      dir="${abbreviated_path}/${repo_name}${path_in_repo}"
    fi
  fi

  echo -ne "\033]0;${dir}\007"
}

# Update terminal title to show running command and current directory
preexec() {
  echo -ne "\033]0;[${1}] ${PWD/#$HOME/~}\007"
}

# Git aliases
alias g='git'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --pretty=format:"%C(yellow)%h%Creset %C(blue)%ad%Creset %C(cyan)%an%Creset %C(green)%s%Creset" --date=short'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'
alias gau='git add -u'

# OpenCode alias
alias oc='opencode'

# Claude aliases
alias s="claude --model sonnet --dangerously-skip-permissions"
alias o="claude --model opus --dangerously-skip-permissions"
alias h="claude --model haiku --dangerously-skip-permissions"

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dup='docker-compose up'
alias ddown='docker-compose down'

# Python virtual environment
alias mkvenv='python -m venv venv && source venv/bin/activate'
alias workon='source ./venv/bin/activate'
alias workoff='deactivate'
alias rmvenv='deactivate 2>/dev/null; rm -rf venv/'

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm (OS-specific paths)
if [[ "$OS" == "Darwin" ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# pnpm completion with package.json scripts support
if command -v pnpm &> /dev/null; then
  # Helper: recursively look for file (reused from zsh-better-npm-completion pattern)
  _zbpc_recursively_look_for() {
    local filename="$1"
    local dir=$PWD
    while [ ! -e "$dir/$filename" ]; do
      dir=${dir%/*}
      [[ "$dir" = "" ]] && break
    done
    [[ ! "$dir" = "" ]] && echo "$dir/$filename"
  }

  # Helper: parse package.json scripts into completion format
  _zbpc_parse_package_json_for_script_suggestions() {
    local package_json="$1"
    cat "$package_json" |
      sed -nE "/^  \"scripts\": \{$/,/^  \},?$/p" |  # Grab scripts object
      sed '1d;$d' |                                   # Remove first/last lines
      sed -E 's/    "([^"]+)": "(.+)",?/\1=>\2/' |   # Parse into key=>value
      sed -E 's/(.+)=>(.+)/\1:$ \2/' |               # Format: name:$ command
      sed 's/\(:\)[^$]/\\&/g' |                      # Escape ":" in commands
      sed 's/\(:\)$[^ ]/\\&/g'                       # Escape ":$" without space
  }

  # Helper: get default pnpm completions
  _zbpc_default_pnpm_completion() {
    local si=$IFS
    local reply
    IFS=$'\n' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" SHELL=zsh pnpm completion-server -- "${words[@]}" 2>/dev/null))
    IFS=$si

    if [ "$reply" = "__tabtab_complete_files__" ]; then
      _files
    else
      _describe 'values' reply
    fi
  }

  # Main completion function
  _zbpc_zsh_better_pnpm_completion() {
    # Only complete scripts on first argument if package.json exists
    if [[ "$CURRENT" = "2" ]]; then
      local package_json="$(_zbpc_recursively_look_for package.json)"

      if [[ ! "$package_json" = "" ]]; then
        # Parse scripts in package.json
        local -a script_completions
        script_completions=(${(f)"$(_zbpc_parse_package_json_for_script_suggestions $package_json)"})

        # If we have scripts, show ONLY scripts (like npm run)
        if [[ ! "$#script_completions" = 0 ]]; then
          _describe 'values' script_completions
          return
        fi
      fi
    fi

    # Fall back to default pnpm completion
    _zbpc_default_pnpm_completion
  }

  compdef _zbpc_zsh_better_pnpm_completion pnpm
fi
# pnpm end

export PATH="$HOME/go/bin:$PATH"

# Custom function: run command N times
run() {
    local n=1
    [[ "$1" == "-n" ]] && { n="$2"; shift 2; }
    for i in $(seq $n); do "$@"; done
}

export PATH="/Users/lars/.bun/bin:$PATH"
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Added by Antigravity
export PATH="/Users/lars/.antigravity/antigravity/bin:$PATH"
