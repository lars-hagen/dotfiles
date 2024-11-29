# Window Management

This document describes the window management setup using AeroSpace, a tiling window manager for macOS.

## Overview

AeroSpace is configured to provide a powerful, keyboard-driven window management system with:
- Multiple workspaces
- Tiling and floating layouts
- Multi-monitor support
- Modal key bindings
- Automatic window arrangement

## Key Bindings

### Window Focus and Movement
- **Focus Windows** (Ctrl-Alt + Arrows)
  - `Ctrl-Alt-Left/Right/Up/Down` - Focus window in direction
  - `Ctrl-Alt-Tab` - Focus next monitor
  - `Ctrl-Alt-Shift-Tab` - Focus previous monitor

- **Move Windows** (Ctrl-Alt-Shift + Arrows)
  - `Ctrl-Alt-Shift-Left/Right/Up/Down` - Move window in direction
  - `Ctrl-Alt-Shift-Cmd-Left/Right/Up/Down` - Move window to adjacent monitor

### Window Resizing
- `Shift-Alt-H` - Shrink width (-50)
- `Shift-Alt-L` - Grow width (+50)
- `Shift-Alt-K` - Shrink height (-50)
- `Shift-Alt-J` - Grow height (+50)

### Layout Controls
- `Ctrl-Alt-/` - Toggle between horizontal/vertical tile layout
- `Ctrl-Alt-,` - Toggle accordion layout
- `Ctrl-Cmd-F` - Toggle fullscreen

### Workspace Management
- **Quick Switch**
  - `Alt-1` through `Alt-6` - Switch to workspace 1-6
  - `Alt-S` - Switch to secondary workspace (S1)
  - `Alt-Tab` - Toggle between last two workspaces

- **Move Windows to Workspace**
  - `Alt-Shift-1` through `Alt-Shift-6` - Move window to workspace 1-6
  - `Alt-Shift-S` - Move window to secondary workspace

## Modal Operations

AeroSpace uses modes to provide additional functionality without requiring more complex key combinations. Think of modes as temporary states where keys have different meanings.

### How Modes Work
1. Enter a mode using its trigger key combination
2. The keys now have mode-specific functions
3. After executing a command, you're usually returned to main mode
4. You can always press `ESC` to return to main mode

### Available Modes

#### Service Mode
**Enter with**: `Ctrl-Alt-Space`
**Available commands**:
- `ESC` - Reload config and return to main mode
- `R` - Reset layout (flatten workspace tree)
- `F` - Toggle floating/tiling layout
- `Backspace` - Close all windows except current
- Arrow keys - Join with window in that direction

**Example workflow**:
1. Press `Ctrl-Alt-Space` to enter service mode
2. Press `R` to reset layout
3. Automatically returns to main mode

#### Workspace Mode
**Enter with**: `Ctrl-Alt-W`
**Available commands**:
- `1-6` - Switch to workspace 1-6
- `Shift-1-6` - Move focused window to workspace 1-6
- `S` - Enter secondary workspace mode
- `T` - Enter temporary workspace mode
- `ESC` - Return to main mode

**Example workflow**:
1. Press `Ctrl-Alt-W` to enter workspace mode
2. Press `3` to switch to workspace 3
3. Automatically returns to main mode

#### Secondary Workspace Mode
**Enter with**: `Ctrl-Alt-S` or `Ctrl-Alt-W` then `S`
**Available commands**:
- `1-3` - Switch to secondary workspace S1-S3
- `Shift-1-3` - Move focused window to secondary workspace S1-S3
- `ESC` - Return to main mode

**Example workflow**:
1. Press `Ctrl-Alt-S` to enter secondary mode
2. Press `1` to switch to workspace S1
3. Automatically returns to main mode

#### Move All Windows Mode
**Enter with**: `Ctrl-Alt-A`
**Available commands**:
- `1-6` - Move all windows to workspace 1-6 and switch to it
- `S` - Move all windows to workspace S1 and switch to it
- `ESC` - Return to main mode without moving windows

**Example workflow**:
1. Press `Ctrl-Alt-A` to enter move-all mode
2. Press `2` to move all windows to workspace 2
3. Automatically returns to main mode

#### Temporary Workspace Mode
**Enter with**: `Ctrl-Alt-T` or `Ctrl-Alt-W` then `T`
**Available commands**:
- `1-3` - Switch to temporary workspace TEMP1-3
- `Shift-1-3` - Move focused window to temporary workspace TEMP1-3
- `ESC` - Return to main mode

**Example workflow**:
1. Press `Ctrl-Alt-T` to enter temporary mode
2. Press `1` to switch to TEMP1
3. Automatically returns to main mode

## Workspace Organization

### Monitor Assignment
- Workspaces 1-6: Assigned to main monitor
- Secondary workspaces (S1-S3): Assigned to secondary monitor
- Temporary workspaces: Available for temporary arrangements

### Window Gaps
```toml
[gaps]
inner.horizontal = 10
inner.vertical = 10
outer.left = 10
outer.bottom = 10
outer.top = 10
outer.right = 10
```

## Special Features

### Move All Windows
The "move-all" mode (Ctrl-Alt-A) allows moving all windows from the current workspace to another workspace at once.

### Floating Windows
- Tabby terminal automatically starts in floating mode
- Toggle floating layout with Service mode (Ctrl-Alt-Space, then F)

### Integration
- Automatically starts at login
- Integrates with [borders](https://github.com/nikitabobko/AeroSpace#installation) for window highlights
- Mouse-aware focus changes

## Tips

1. **Quick Layout Reset**
   - Enter service mode (Ctrl-Alt-Space)
   - Press 'R' to flatten workspace tree

2. **Efficient Multi-monitor Usage**
   - Use workspace S1 for secondary monitor content
   - Quick switch between monitors with Ctrl-Alt-Tab

3. **Window Organization**
   - Use workspaces 1-6 for main tasks
   - S1-S3 for secondary monitor tasks
   - TEMP1-3 for temporary arrangements

4. **Modal Tips**
   - Most mode actions automatically return you to main mode
   - If you get stuck, `ESC` always returns to main mode
   - Watch for the mode indicator in your status bar

## See Also
- [Official AeroSpace Documentation](https://nikitabobko.github.io/AeroSpace/guide)
- [Homebrew Packages](homebrew-packages.md) 