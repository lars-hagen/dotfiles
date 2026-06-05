#!/bin/bash
set -e

echo "Applying macOS defaults..."

# Keyboard
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# File management
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# UI performance
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.01

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 64
defaults write com.apple.dock wvous-bl-corner -int 4  # Bottom-left hot corner: Desktop

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Mouse
defaults write NSGlobalDomain com.apple.mouse.linear -bool true
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.5

# Window Manager
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager StandardHideDesktopIcons -int 1

# Spotlight — disable Cmd+Space
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
<dict>
  <key>enabled</key><false/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key><array>
      <integer>32</integer><integer>49</integer><integer>1048576</integer>
    </array>
  </dict>
</dict>"

# Hotkey 27 — custom (ported from nix-darwin config)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 "
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key><array>
      <integer>120</integer><integer>7</integer><integer>1835008</integer>
    </array>
  </dict>
</dict>"

# Disable Terminal "Search man Page Index" service
defaults write pbs NSServicesStatus -dict-add "com.apple.Terminal - Search man Page Index in Terminal - searchManPages" '{ enabled_services_menu = 0; }'

# Prevent .DS_Store file creation on network volumes (ported from v1 .macos)
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Spotlight — limit indexed categories to apps/prefs/dirs (ported from v1 .macos)
defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    '{"enabled" = 0;"name" = "PDF";}' \
    '{"enabled" = 0;"name" = "FONTS";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
killall mds >/dev/null 2>&1 || true

for app in "Dock" "Finder" "SystemUIServer"; do
    killall "$app" &>/dev/null || true
done

echo "Done. Some changes require logout/restart to take effect."
