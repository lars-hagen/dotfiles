#!/bin/bash

# Set the output directory to the user's home directory
OUTPUT_DIR="$HOME/.dotfiles"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Run brew bundle dump and save the output to Brewfile
brew bundle dump --file="$OUTPUT_DIR/Brewfile" --force

echo "Brewfile has been created in $OUTPUT_DIR/Brewfile"
