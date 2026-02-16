# Omarchy Forge - AI Agent Instructions

This document contains instructions for AI agents (like OpenCode) to help extend and maintain this automation system.

## Project Overview

**Omarchy Forge** is an automation system for managing applications, configurations, and system tweaks on a fresh Omarchy Linux installation. It uses shell scripts organized into categories for easy maintenance and extension.

## Directory Structure

```
omarchy-forge/
├── bootstrap.sh        # Main automation orchestrator
├── apps/              # Application installation scripts
├── scripts/           # System utility scripts
├── configs/           # Config files to deploy to ~/.config/
├── hooks/             # Omarchy hook integrations
├── README.md          # User documentation
└── AGENTS.md          # This file - AI agent instructions
```

## How It Works

1. **bootstrap.sh** - Runs all automation tasks
   - Installs apps from `apps/`
   - Deploys configs from `configs/` to `~/.config/`
   - Sets up hooks in `~/.config/omarchy/hooks/`
   - Runs utility scripts from `scripts/`

2. **App installers** (`apps/*.sh`) - Each script installs one application
   - Detects package manager (pacman/apt/dnf)
   - Checks if already installed
   - Installs with appropriate package manager
   - Performs post-install configuration

3. **Utility scripts** (`scripts/*.sh`) - System-wide tweaks
   - System optimizations
   - Development environment setup
   - Custom configurations

4. **Hooks** (`hooks/*`) - Integrate with Omarchy events
   - `post-update` - Runs after Omarchy updates
   - `theme-set` - Runs when theme changes
   - `font-set` - Runs when font changes

## Adding New Applications

When a user asks to add a new application, follow this pattern:

### Template: `apps/app-name.sh`

```bash
#!/bin/bash

# [App Name] installer for Omarchy

set -e

echo "Installing [App Name]..."

# Check if already installed
if command -v [command] &> /dev/null; then
    echo "[App Name] is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    sudo pacman -S --noconfirm --needed [package-name]
    
elif command -v apt &> /dev/null; then
    # Debian/Ubuntu-based
    echo "Detected Debian/Ubuntu-based system"
    sudo apt update
    sudo apt install -y [package-name]
    
elif command -v dnf &> /dev/null; then
    # Fedora-based
    echo "Detected Fedora-based system"
    sudo dnf install -y [package-name]
    
else
    echo "Unsupported package manager. Please install [App Name] manually."
    exit 1
fi

# Post-install configuration (if needed)
# Add any additional setup here

echo "[App Name] installed successfully!"
```

### Steps:
1. Create new file: `apps/app-name.sh`
2. Use the template above
3. Replace `[App Name]`, `[command]`, `[package-name]` appropriately
4. Make it executable: `chmod +x apps/app-name.sh`
5. Test it: `./apps/app-name.sh`

### Examples in this repo:
- `apps/brave-browser.sh` - Browser installation
- `apps/vscode.sh` - Editor with post-install config
- `apps/remmina.sh` - App with plugins
- `apps/tailscale.sh` - Service with systemd setup

## Adding Utility Scripts

When a user asks for system tweaks or configurations:

### Template: `scripts/purpose-name.sh`

```bash
#!/bin/bash

# [Purpose description]

echo "[What this script does]..."

# Your configuration logic here

echo "[Purpose] complete!"
```

### Steps:
1. Create new file: `scripts/descriptive-name.sh`
2. Add configuration logic
3. Make it executable: `chmod +x scripts/descriptive-name.sh`
4. Bootstrap will auto-run it

### Examples in this repo:
- `scripts/system-tweaks.sh` - System optimizations & touchpad config
- `scripts/install-dev-tools.sh` - Developer utilities

## Adding Configurations

When a user wants to deploy config files:

1. Add config directory/file to `configs/`
2. Bootstrap will automatically copy it to `~/.config/`
3. Existing configs are backed up with timestamp

Example:
```bash
configs/
└── kitty/
    └── kitty.conf
```

Becomes: `~/.config/kitty/kitty.conf`

## Adding Hooks

When a user wants to react to Omarchy events:

### Available hooks:
- `post-update` - After Omarchy system updates
- `theme-set` - When theme changes (receives theme name as $1)
- `font-set` - When font changes (receives font name as $1)

### Steps:
1. Create file in `hooks/` (no .sh extension)
2. Make it executable
3. Bootstrap copies to `~/.config/omarchy/hooks/`

### Example: `hooks/theme-set`
```bash
#!/bin/bash
THEME_NAME="$1"
echo "Theme changed to: $THEME_NAME"
# Your custom logic here
```

## Common Patterns

### Installing from AUR (Arch)
```bash
if command -v yay &> /dev/null; then
    yay -S --noconfirm package-name
elif command -v paru &> /dev/null; then
    paru -S --noconfirm package-name
else
    echo "Please install yay or paru for AUR packages"
    exit 1
fi
```

### Adding repository sources
See `apps/brave-browser.sh` for apt/dnf examples

### Enabling systemd services
```bash
sudo systemctl enable --now service-name
```

### Setting default applications
```bash
# Environment variables
echo "export EDITOR=command" >> ~/.bashrc

# Git config
git config --global core.editor "command"

# XDG mime types
xdg-mime default app.desktop type/format
```

### Hyprland configuration
```bash
CONFIG="$HOME/.config/hypr/hyprland.conf"
# Add configuration to Hyprland
cat >> "$CONFIG" << 'EOF'
# Your config here
EOF
```

## Important Notes

### Pre-installed in Omarchy
These tools come with fresh Omarchy install - don't add them:
- git
- vim
- neovim
- Common shell utilities

### Package Manager Detection
Always support all three: pacman (Arch), apt (Debian/Ubuntu), dnf (Fedora)

### Error Handling
- Use `set -e` to exit on errors
- Check if already installed before installing
- Provide helpful error messages

### Making Scripts Executable
Always remember: `chmod +x path/to/script.sh`

## Testing

### Test individual components:
```bash
# Test single app install
./apps/app-name.sh

# Test single script
./scripts/script-name.sh

# Test specific category
./bootstrap.sh --apps-only
./bootstrap.sh --configs-only
./bootstrap.sh --hooks-only
./bootstrap.sh --scripts-only
```

### Test full automation:
```bash
./bootstrap.sh
```

## User Workflow

When helping users extend this system:

1. **Ask what they want to install/configure**
2. **Plan the changes** (use TodoWrite tool to track)
3. **Create appropriate scripts** following templates above
4. **Make scripts executable**
5. **Test if possible** (or explain how to test)
6. **Update this file** if new patterns emerge

## Troubleshooting

### Script not running?
- Check if executable: `ls -l apps/script.sh`
- Make executable: `chmod +x apps/script.sh`

### Package not found?
- Check package name for each distro
- Use `pacman -Ss`, `apt search`, or `dnf search`

### Config not deploying?
- Check file is in `configs/` directory
- Run `./bootstrap.sh --configs-only`

### Hook not triggering?
- Check file is executable
- Verify it's copied to `~/.config/omarchy/hooks/`
- Remove `.sample` extension if present

## Future Expansion Ideas

- Dotfile management (symlinks)
- Backup/restore functionality
- Update checker for installed apps
- Configuration profiles (minimal/full/dev)
- GUI app installation via flatpak
- Automated theme/font installation

## Quick Reference

```bash
# Install everything
./bootstrap.sh

# Install just apps
./bootstrap.sh --apps-only

# Add new app
vim apps/new-app.sh
chmod +x apps/new-app.sh
./apps/new-app.sh

# Add new script
vim scripts/new-script.sh
chmod +x scripts/new-script.sh
./scripts/new-script.sh

# Deploy configs
cp -r /path/to/config configs/
./bootstrap.sh --configs-only
```

---

**Last Updated:** 2026-02-15  
**Omarchy Version:** Fresh install compatible  
**Maintained by:** AI agents + user customization
