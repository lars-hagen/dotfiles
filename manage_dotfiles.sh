#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"
DEBUG=false

# Function to print usage information
usage() {
    echo "Usage: $0 [-d] <file_or_folder>"
    echo "  -d    Debug mode (don't actually run commands)"
    echo "  file_or_folder    Path to the file or folder to add to dotfiles"
}

# Parse command-line options
while getopts ":d" opt; do
    case $opt in
        d)
            DEBUG=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# Shift the options so that $1 is the file/folder argument
shift $((OPTIND-1))

# Check if a file/folder argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No file or folder specified."
    usage
    exit 1
fi

# Function to execute or print commands based on debug mode
run_command() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] Would run: $*"
    else
        "$@"
    fi
}

# Main logic
FILE_OR_FOLDER="$1"
FULL_PATH=$(cd "$(dirname "$FILE_OR_FOLDER")" && pwd -P)/$(basename "$FILE_OR_FOLDER")
RELATIVE_PATH=${FULL_PATH#$HOME/}

# Create the dotfiles directory if it doesn't exist
run_command mkdir -p "$DOTFILES_DIR"

# Create the necessary subdirectories in the dotfiles repo
run_command mkdir -p "$DOTFILES_DIR/$(dirname "$RELATIVE_PATH")"

# Move the file/folder to the dotfiles directory, maintaining the structure
run_command mv "$FULL_PATH" "$DOTFILES_DIR/$RELATIVE_PATH"

# Create a symbolic link back to the original location
run_command ln -s "$DOTFILES_DIR/$RELATIVE_PATH" "$FULL_PATH"

# Add the file/folder to git
run_command cd "$DOTFILES_DIR"
run_command git add "$RELATIVE_PATH"
run_command git commit -m "Added $RELATIVE_PATH to dotfiles"

echo "Successfully added $RELATIVE_PATH to dotfiles repository."
