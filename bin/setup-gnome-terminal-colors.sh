#!/bin/bash
# Setup Argonaut color scheme for GNOME Terminal

# Get the default profile UUID
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Base path for the profile
PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"

# Set colors
gsettings set $PROFILE_PATH use-theme-colors false
gsettings set $PROFILE_PATH foreground-color '#ffffff'
gsettings set $PROFILE_PATH background-color '#0e1019'
gsettings set $PROFILE_PATH cursor-color '#ffffff'
gsettings set $PROFILE_PATH cursor-background-color '#ffffff'
gsettings set $PROFILE_PATH bold-color '#ffffff'
gsettings set $PROFILE_PATH bold-color-same-as-fg true

# Set palette (16 colors)
gsettings set $PROFILE_PATH palette "['#232323', '#ff000f', '#8ce10b', '#ffb900', '#008df8', '#6d43a6', '#00d8eb', '#ffffff', '#444444', '#ff2740', '#abe15b', '#ffd242', '#0092ff', '#9a5feb', '#67fff0', '#ffffff']"

# Set font
gsettings set $PROFILE_PATH use-system-font false
gsettings set $PROFILE_PATH font 'FiraCode Nerd Font Mono 11'

# Enable transparency (closest to opacity 0.94)
gsettings set $PROFILE_PATH use-transparent-background true
gsettings set $PROFILE_PATH background-transparency-percent 6

echo "✓ Argonaut color scheme applied to GNOME Terminal"
echo "✓ Profile: $PROFILE"
echo ""
echo "You may need to restart GNOME Terminal for all changes to take effect."
