#!/bin/bash

# NotesMD CLI installer for Omarchy
# Community CLI tool for interacting with Obsidian vaults

set -e

echo "Installing NotesMD CLI..."

# Check if already installed
if command -v notesmd-cli &> /dev/null; then
    echo "NotesMD CLI is already installed"
    exit 0
fi

# Detect package manager
if command -v pacman &> /dev/null; then
    # Arch-based
    echo "Detected Arch-based system"
    
    if command -v yay &> /dev/null; then
        echo "Installing via yay..."
        yay -S --noconfirm notesmd-cli-bin
    elif command -v paru &> /dev/null; then
        echo "Installing via paru..."
        paru -S --noconfirm notesmd-cli-bin
    else
        echo "Error: yay or paru required for AUR package installation"
        echo "Please install yay or paru first"
        exit 1
    fi
    
elif command -v brew &> /dev/null; then
    # macOS/Linux with Homebrew
    echo "Detected Homebrew"
    brew tap yakitrak/yakitrak
    brew install yakitrak/yakitrak/notesmd-cli
    
else
    echo "Unsupported package manager."
    echo "Please install manually from: https://github.com/Yakitrak/notesmd-cli"
    exit 1
fi

echo ""
echo "NotesMD CLI installed successfully!"
echo ""
echo "Usage:"
echo "  notesmd-cli set-default \"vault-name\"   # Set default vault"
echo "  notesmd-cli search                      # Fuzzy search notes"
echo "  notesmd-cli create \"note-name\"          # Create new note"
echo "  notesmd-cli daily                       # Open/create daily note"
echo ""
echo "Run 'notesmd-cli --help' for more commands"
