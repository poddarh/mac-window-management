# Project Instructions for Claude

## Git Workflow

- **Always ask before making any commits.** Do not commit changes without explicit user approval.
- Stage changes and show what will be committed, then wait for confirmation before running `git commit`.

## Yabai Management

- **Always use `~/.yabai/reload.sh` to restart yabai.** This script saves and restores window state so windows, spaces, and workspaces are preserved across restarts.
- Never use `yabai --restart-service` directly as it will lose window positions and workspace state.
