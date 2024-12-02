# ZSH Tools and Plugins

This page documents the various tools, plugins, and integrations used to enhance the shell environment. For core ZSH configuration, see [Shell Customization](shell-customization.md).

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

**Installation:**
```bash
brew install starship
```

## Core Plugins

### ZSH Completions
See [Shell Customization - Completion System](shell-customization.md#completion-system) for configuration details.

**Installation:**
```bash
brew install zsh-completions
```

### ZSH Autosuggestions
**What is it?**
- Suggests commands as you type based on history
- Shows suggestions in a light gray
- Helps recall and type common commands faster

**Installation:**
```bash
brew install zsh-autosuggestions
```

### ZSH Syntax Highlighting
**What is it?**
- Real-time syntax highlighting for shell commands
- Validates commands and paths as you type
- Makes command errors visible before execution

**Installation:**
```bash
brew install zsh-syntax-highlighting
```

See [Shell Customization - Plugin Integration](shell-customization.md#plugin-integration) for configuration details.

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

**Installation:**
```bash
# Install core fuzzy finder
brew install fzf
$(brew --prefix)/opt/fzf/install

# Install fd for better file finding
brew install fd
```

See [Shell Customization - Tool Configurations](shell-customization.md#fzf-integration) for configuration details.

**Usage:**
- `Ctrl-T`: Paste selected files/folders into command line
- `Ctrl-R`: Search command history
- `Alt-C`: CD into selected directory
- `Ctrl-/`: Toggle preview window in any mode

### FZF Tab
**What is it?**
- Enhanced tab completion using fzf
- Replaces ZSH's default completion selection menu with fzf
- Provides interactive filtering and preview

**Features:**
- Interactive fuzzy completion
- File/directory preview
- Group support
- Custom preview commands

**Installation:**
```bash
git clone https://github.com/Aloxaf/fzf-tab $DOTFILES_DIR/fzf-tab
```

See [Shell Customization - Completion System](shell-customization.md#completion-system) for configuration details.

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

**Installation:**
```bash
brew install eza
```

See [Shell Customization - Tool Configurations](shell-customization.md#eza-aliases) for alias configuration.

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

**Installation:**
```bash
brew install zoxide
```

### Bat (Modern cat)
**What is it?**
- Modern replacement for `cat`
- Syntax highlighting
- Git integration
- Line numbers and paging

**Installation:**
```bash
brew install bat
```

### Tree (Directory viewer)
**What is it?**
- Visual directory structure viewer
- Shows nested hierarchies
- Supports various output formats

**Installation:**
```bash
brew install tree
```

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

**Installation:**
```bash
pip install shell-gpt
pipx inject shell-gpt readchar
```

See [Shell Customization - Tool Configurations](shell-customization.md#shell-gpt-integration) for configuration details.

**Usage:**
1. Type a command or question
2. Press Ctrl+L
3. Wait for ⌛ indicator
4. Get AI-suggested command

## AWS Integration

### Granted
**What is it?**
- AWS credentials manager
- Command-line interface for AWS role assumption
- Supports multiple environments
- Browser integration for SSO

**Installation:**
```bash
# Add the tap first
brew tap common-fate/granted
brew install common-fate/granted/granted
```

For AWS profile management, Chrome integration, and automated role switching, see [AWS Profile Management](aws-profile-management.md).

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

### Core Tools
```bash
# Add required taps
brew tap common-fate/granted

# Install core tools
brew install starship fzf fd eza zoxide direnv tree bat

# Install ZSH plugins
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-completions

# Install AWS tools
brew install common-fate/granted/granted

# Install Shell-GPT
pip install shell-gpt
pipx inject shell-gpt readchar

# Clone FZF-tab
git clone https://github.com/Aloxaf/fzf-tab $DOTFILES_DIR/fzf-tab
```

## See Also
- [ZSH Core Configuration](shell-customization.md)
- [Installation Guide](setup-and-installation.md)
- [Window Management](window-management.md)
- [AWS Profile Management](aws-profile-management.md)
