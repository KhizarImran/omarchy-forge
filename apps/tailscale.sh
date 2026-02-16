#!/bin/bash

# Tailscale VPN installer for Omarchy

set -e

echo "Installing Tailscale..."

# Check if already installed
if command -v tailscale &> /dev/null; then
    echo "Tailscale is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    sudo pacman -Sy --noconfirm --needed tailscale
    
    # Enable and start the service
    sudo systemctl enable --now tailscaled
    
elif command -v apt &> /dev/null; then
    # Debian/Ubuntu-based
    echo "Detected Debian/Ubuntu-based system"
    
    curl -fsSL https://tailscale.com/install.sh | sh
    
elif command -v dnf &> /dev/null; then
    # Fedora-based
    echo "Detected Fedora-based system"
    
    sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    sudo dnf install -y tailscale
    
    # Enable and start the service
    sudo systemctl enable --now tailscaled
    
else
    echo "Unsupported package manager. Please install Tailscale manually."
    exit 1
fi

echo ""
echo "Tailscale installed successfully!"
echo ""
echo "To connect to your Tailscale network, run:"
echo "  sudo tailscale up"
echo ""
echo "To check status:"
echo "  tailscale status"
