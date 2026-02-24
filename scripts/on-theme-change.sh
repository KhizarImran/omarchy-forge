#!/bin/bash

# on-theme-change.sh
# Called by hooks/theme-set when the Omarchy theme changes.
# Reads the accent colour from the theme's colors.toml and applies it
# as a static colour to all Razer keyboard/device lighting via OpenRazer.
#
# Usage: on-theme-change.sh <theme-name>
#   <theme-name> is the snake-cased theme name passed by Omarchy, e.g. "tokyo-night"

set -e

THEME_NAME="$1"

if [ -z "$THEME_NAME" ]; then
    echo "on-theme-change: no theme name provided, exiting"
    exit 1
fi

# Omarchy stores themes in these locations (user themes take priority)
USER_THEME_DIR="$HOME/.config/omarchy/themes/$THEME_NAME"
STOCK_THEME_DIR="$HOME/.local/share/omarchy/themes/$THEME_NAME"

if [ -f "$USER_THEME_DIR/colors.toml" ]; then
    COLORS_FILE="$USER_THEME_DIR/colors.toml"
elif [ -f "$STOCK_THEME_DIR/colors.toml" ]; then
    COLORS_FILE="$STOCK_THEME_DIR/colors.toml"
else
    echo "on-theme-change: could not find colors.toml for theme '$THEME_NAME'"
    exit 1
fi

# Extract the accent hex value (format: accent = "#rrggbb")
HEX=$(grep '^accent' "$COLORS_FILE" | sed 's/.*"#\([0-9a-fA-F]\{6\}\)".*/\1/')

if [ -z "$HEX" ]; then
    echo "on-theme-change: could not parse accent colour from $COLORS_FILE"
    exit 1
fi

# Convert hex to decimal R G B
R=$(printf '%d' "0x${HEX:0:2}")
G=$(printf '%d' "0x${HEX:2:2}")
B=$(printf '%d' "0x${HEX:4:2}")

echo "on-theme-change: theme='$THEME_NAME' accent=#$HEX -> RGB($R,$G,$B)"

# Apply colour to all connected Razer devices via python-openrazer
# Note: openrazer 3.x API uses device.fx.static(r, g, b) directly - no Color object
python3 - "$R" "$G" "$B" << 'PYEOF'
import sys

r, g, b = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])

try:
    from openrazer.client import DeviceManager
except ImportError:
    print("on-theme-change: python-openrazer not installed, skipping RGB update")
    sys.exit(0)

try:
    dm = DeviceManager()
except Exception as e:
    print(f"on-theme-change: could not connect to openrazer-daemon: {e}")
    sys.exit(0)

if not dm.devices:
    print("on-theme-change: no Razer devices found")
    sys.exit(0)

# If the accent colour is too dark it won't be visible on the keyboard.
# Perceived brightness via the standard luminance formula (0-255 scale).
# If below threshold, boost the colour to minimum brightness while keeping the hue.
MIN_BRIGHTNESS = 120

def boost_to_min_brightness(r, g, b, target):
    """Scale r,g,b up so perceived brightness reaches target, capping each channel at 255."""
    brightness = (r * 299 + g * 587 + b * 114) // 1000
    if brightness == 0:
        # Pure black - fall back to white
        return 255, 255, 255
    scale = target / brightness
    r2 = min(255, int(r * scale))
    g2 = min(255, int(g * scale))
    b2 = min(255, int(b * scale))
    return r2, g2, b2

brightness = (r * 299 + g * 587 + b * 114) // 1000
if brightness < MIN_BRIGHTNESS:
    orig = f"#{r:02x}{g:02x}{b:02x}"
    r, g, b = boost_to_min_brightness(r, g, b, MIN_BRIGHTNESS)
    print(f"on-theme-change: accent {orig} too dark (brightness={brightness}), boosted to #{r:02x}{g:02x}{b:02x}")

for device in dm.devices:
    try:
        if device.fx.static(r, g, b):
            print(f"on-theme-change: set {device.name} to #{r:02x}{g:02x}{b:02x}")
        else:
            print(f"on-theme-change: static() returned False for {device.name}")
    except Exception as e:
        print(f"on-theme-change: failed to set colour on {device.name}: {e}")

PYEOF
