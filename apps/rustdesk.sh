#!/bin/bash

# RustDesk remote desktop installer for Omarchy

set -e

RUSTDESK_VERSION="1.4.5"

echo "Installing RustDesk ${RUSTDESK_VERSION}..."

# Check if already installed
if command -v rustdesk &> /dev/null; then
    echo "RustDesk is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    
    if command -v yay &> /dev/null; then
        echo "Installing via yay..."
        yay -S --noconfirm rustdesk-bin
    elif command -v paru &> /dev/null; then
        echo "Installing via paru..."
        paru -S --noconfirm rustdesk-bin
    else
        echo "Installing from GitHub releases (yay/paru not found)..."
        
        # Sync database for fallback install method
        sudo pacman -Sy
        
        # Download latest release
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        echo "Downloading RustDesk ${RUSTDESK_VERSION}..."
        curl -L -o rustdesk.pkg.tar.zst "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0-x86_64.pkg.tar.zst"
        
        echo "Installing package..."
        sudo pacman -U --noconfirm rustdesk.pkg.tar.zst
        
        cd -
        rm -rf "$TEMP_DIR"
    fi
    
elif command -v apt &> /dev/null; then
    # Debian/Ubuntu-based
    echo "Detected Debian/Ubuntu-based system"
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    echo "Downloading RustDesk ${RUSTDESK_VERSION}..."
    wget "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"
    
    echo "Installing package..."
    sudo apt install -y "./rustdesk-${RUSTDESK_VERSION}-x86_64.deb"
    
    cd -
    rm -rf "$TEMP_DIR"
    
elif command -v dnf &> /dev/null; then
    # Fedora-based
    echo "Detected Fedora-based system"
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    echo "Downloading RustDesk ${RUSTDESK_VERSION}..."
    wget "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"
    
    echo "Installing package..."
    sudo dnf install -y "./rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"
    
    cd -
    rm -rf "$TEMP_DIR"
    
else
    echo "Unsupported package manager. Please install RustDesk manually."
    exit 1
fi

echo ""
echo "RustDesk installed successfully!"
echo ""
echo "Launch RustDesk from your application menu or run:"
echo "  rustdesk"
