#!/bin/bash

LOG_FILE="/tmp/aerospace_workspace_log.txt"

log() {
    echo "$(date): $1" >> "$LOG_FILE"
    logger -t "AeroSpace" "$1"
}

log "Script started"

# Check if aerospace command exists
if ! command -v aerospace &> /dev/null; then
    log "Error: aerospace command not found"
    exit 1
fi

log "Attempting to list workspaces"
workspace_list=$(aerospace list-workspaces --all 2>&1)
if [ $? -ne 0 ]; then
    log "Error listing workspaces: $workspace_list"
    exit 1
fi

log "Workspace list: $workspace_list"

highest=$(echo "$workspace_list" | grep -E "^[0-9]+$" | sort -n | tail -n 1)
if [ -z "$highest" ]; then
    log "No numeric workspaces found, starting with 1"
    highest=0
fi

new_workspace=$((highest + 1))
log "Highest existing workspace: $highest, Creating workspace: $new_workspace"

log "Attempting to create workspace $new_workspace and move focused window"
result=$(aerospace move-node-to-workspace "$new_workspace" 2>&1)
if [ $? -ne 0 ]; then
    log "Error creating workspace and moving window: $result"
    exit 1
fi

log "Attempting to switch to workspace $new_workspace"
result=$(aerospace workspace "$new_workspace" 2>&1)
if [ $? -ne 0 ]; then
    log "Error switching to workspace: $result"
    exit 1
fi

log "Successfully created workspace $new_workspace, moved focused window, and switched to it"
