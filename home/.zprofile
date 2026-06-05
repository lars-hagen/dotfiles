# Homebrew: prepend /opt/homebrew/bin to PATH so brew-installed tools shadow system ones
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
