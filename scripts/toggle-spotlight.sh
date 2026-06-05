#!/bin/bash
# Toggle Spotlight indexing on/off
# Usage: ./toggle-spotlight.sh

set -e

# Check current status
STATUS=$(mdutil -s / 2>/dev/null | grep -o "Indexing [a-z]*" | awk '{print $2}')

if [ "$STATUS" = "enabled" ]; then
    echo "Spotlight is currently ENABLED"
    echo "Disabling Spotlight indexing on all volumes..."
    sudo mdutil -a -i off
    echo "✓ Spotlight DISABLED"
elif [ "$STATUS" = "disabled" ]; then
    echo "Spotlight is currently DISABLED"
    echo "Enabling Spotlight indexing on all volumes..."
    sudo mdutil -a -i on
    echo "✓ Spotlight ENABLED"
else
    echo "Error: Could not determine Spotlight status"
    exit 1
fi

# Show final status
echo ""
echo "Current status:"
mdutil -s /
