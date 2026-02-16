#!/bin/bash

# Visual Studio Code installer for Omarchy

set -e

echo "Installing Visual Studio Code..."

# Check if already installed
if command -v code &> /dev/null; then
    echo "VSCode is already installed"
else
    # Detect package manager
    if command -v pacman &> /dev/null; then
        # Arch-based
        echo "Detected Arch-based system"
        
        if command -v yay &> /dev/null; then
            yay -S --noconfirm visual-studio-code-bin
        elif command -v paru &> /dev/null; then
            paru -S --noconfirm visual-studio-code-bin
        else
            echo "Please install yay or paru to install VSCode from AUR"
            exit 1
        fi
        
    elif command -v apt &> /dev/null; then
        # Debian/Ubuntu-based
        echo "Detected Debian/Ubuntu-based system"
        
        sudo apt update
        sudo apt install -y wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        sudo apt update
        sudo apt install -y code
        
    elif command -v dnf &> /dev/null; then
        # Fedora-based
        echo "Detected Fedora-based system"
        
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf check-update
        sudo dnf install -y code
        
    else
        echo "Unsupported package manager. Please install VSCode manually."
        exit 1
    fi
    
    echo "VSCode installed successfully!"
fi

# Set VSCode as default editor
echo ""
echo "Setting VSCode as default editor..."

# Set environment variables
PROFILE_FILE="$HOME/.profile"
BASHRC_FILE="$HOME/.bashrc"
ZSHRC_FILE="$HOME/.zshrc"

# Function to add editor exports
add_editor_export() {
    local file="$1"
    
    if [ -f "$file" ]; then
        if ! grep -q "EDITOR=code" "$file"; then
            echo "" >> "$file"
            echo "# Set VSCode as default editor" >> "$file"
            echo "export EDITOR=code" >> "$file"
            echo "export VISUAL=code" >> "$file"
            echo "Added EDITOR export to $file"
        else
            echo "EDITOR already set in $file"
        fi
    fi
}

# Add to profile files
add_editor_export "$PROFILE_FILE"
add_editor_export "$BASHRC_FILE"
[ -f "$ZSHRC_FILE" ] && add_editor_export "$ZSHRC_FILE"

# Set git editor
git config --global core.editor "code --wait"

# Update alternatives (if available)
if command -v update-alternatives &> /dev/null; then
    sudo update-alternatives --set editor /usr/bin/code 2>/dev/null || true
fi

echo ""
echo "VSCode setup complete!"
echo "Default editor set to VSCode"
echo ""
echo "Note: You may need to restart your shell or run 'source ~/.bashrc' for changes to take effect"
