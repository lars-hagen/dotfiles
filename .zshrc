# Add ~/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"
# Initialize Starship prompt
eval "$(starship init zsh)"
# Load zsh-autosuggestions
if type brew &>/dev/null; then
    # macOS with Homebrew
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
    # Linux (or macOS without Homebrew)
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# zsh
source <(fzf --zsh)

# ZSH syntax highlighting configuration
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_STYLES[default]='fg=blue'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=blue'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=cyan'

alias cd='z'

# Replace ls with eza
alias ls='eza -1 --color=always --group-directories-first --icons' # preferred listing
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

# Case insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Automatically find new executables in path 
zstyle ':completion:*' rehash true

# Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use various completion methods (expand, complete, ignored, approximate)
zstyle ':completion:*' completer _expand _complete _ignored _approximate

# Enable menu-style completion selection
zstyle ':completion:*' menu select

# Uncomment to show scrolling prompt during menu selection
#zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Format for displaying completion descriptions
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'

# Group completions by category (e.g., files, commands)
zstyle ':completion:*' group-name ''

alias assume=". assume"
