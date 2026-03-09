#!/bin/bash

# add-hackerman-wallpaper.sh
# Adds the "Lock In" wallpaper to the Hackerman theme backgrounds.
# The wallpaper is bundled in omarchy-forge/wallpapers/.
# If a user theme override for Hackerman exists it is used, otherwise the
# stock theme directory is used (safe – omarchy-theme-set copies from there).

set -e

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WALLPAPER_SRC="$FORGE_DIR/wallpapers/hackerman-lockin.jpg"
WALLPAPER_DST_NAME="3-lockin.jpg"

echo "[forge] add-hackerman-wallpaper: starting..."

# Verify the source wallpaper exists
if [ ! -f "$WALLPAPER_SRC" ]; then
    echo "[forge] ERROR: wallpaper not found at $WALLPAPER_SRC"
    exit 1
fi

# Prefer a user-level theme override; fall back to stock
USER_BG_DIR="$HOME/.config/omarchy/themes/hackerman/backgrounds"
STOCK_BG_DIR="$HOME/.local/share/omarchy/themes/hackerman/backgrounds"

if [ -d "$USER_BG_DIR" ]; then
    TARGET_DIR="$USER_BG_DIR"
    echo "[forge] Using user theme dir: $TARGET_DIR"
else
    TARGET_DIR="$STOCK_BG_DIR"
    echo "[forge] Using stock theme dir: $TARGET_DIR"
fi

# Create the backgrounds directory if somehow missing
mkdir -p "$TARGET_DIR"

DEST="$TARGET_DIR/$WALLPAPER_DST_NAME"

if [ -f "$DEST" ]; then
    echo "[forge] Wallpaper already present at $DEST – skipping copy"
else
    cp "$WALLPAPER_SRC" "$DEST"
    echo "[forge] Wallpaper installed to $DEST"
fi

echo "[forge] add-hackerman-wallpaper: done!"
