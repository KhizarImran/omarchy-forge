#!/bin/bash

# Claude usage Waybar widget installer
# Adds a clickable icon to Waybar that opens a popup showing
# 5-hour session and 7-day weekly token usage from opencode's local DB.
# The popup colors automatically match the current Omarchy theme.

set -e

echo "Installing Claude usage widget..."

# ── 1. Install the popup script ──────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/claude-usage-popup" << 'POPUP_SCRIPT'
#!/usr/bin/env python3
"""
Claude usage popup window.
Shows two progress bars (5h session + 7d weekly) as a small floating GTK window.
Re-running while open closes the existing window (toggle behaviour).
Colors are read from the current Omarchy theme at launch.
"""

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

import datetime
import os
import re
import signal
import sqlite3
import sys
import time
from pathlib import Path

# ── Config ───────────────────────────────────────────────────────────────────
DB_PATH          = Path.home() / ".local/share/opencode/opencode.db"
THEME_COLORS     = Path.home() / ".config/omarchy/current/theme/colors.toml"
SESSION_LIMIT    = 88_000      # 5-hour window output token limit (adjust to taste)
SESSION_HOURS    = 5
WEEKLY_LIMIT     = 900_000     # 7-day budget
REFRESH_INTERVAL = 15_000      # ms between auto-refreshes
APP_ID           = "claude-usage-popup"
LOCK_FILE        = Path("/tmp/claude-usage-popup.pid")


# ── Theme colors ──────────────────────────────────────────────────────────────
def load_theme():
    """
    Parse ~/.config/omarchy/current/theme/colors.toml and return a dict.
    Falls back to sane dark defaults if the file is missing.
    """
    defaults = {
        "background": "#1e1e2e",
        "foreground": "#cdd6f4",
        "color0":     "#313244",  # track/muted bg
        "color1":     "#f38ba8",  # red    → critical
        "color2":     "#a6e3a1",  # green  → normal bar
        "color3":     "#f9e2af",  # yellow → warning
        "color5":     "#fab387",  # orange → high
    }

    if not THEME_COLORS.exists():
        return defaults

    colors = dict(defaults)
    for line in THEME_COLORS.read_text().splitlines():
        m = re.match(r'^(\w+)\s*=\s*"(#[0-9a-fA-F]{6})"', line.strip())
        if m:
            colors[m.group(1)] = m.group(2)
    return colors


def blend(hex1, hex2, t=0.15):
    """Blend hex2 into hex1 by factor t (0=all hex1, 1=all hex2)."""
    def parse(h):
        h = h.lstrip("#")
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
    r1, g1, b1 = parse(hex1)
    r2, g2, b2 = parse(hex2)
    return f"#{int(r1+(r2-r1)*t):02x}{int(g1+(g2-g1)*t):02x}{int(b1+(b2-b1)*t):02x}"


def build_css(c):
    bg     = c["background"]
    fg     = c["foreground"]
    track  = blend(bg, fg, 0.12)
    border = blend(bg, fg, 0.20)
    muted  = blend(bg, fg, 0.45)
    subtle = blend(bg, fg, 0.25)
    green  = c["color2"]
    yellow = c["color3"]
    orange = c.get("color5", c["color3"])
    red    = c["color1"]

    return f"""
window {{
  background-color: {bg};
  border-radius: 10px;
  border: 1px solid {border};
}}
.header {{
  font-family: 'JetBrainsMono Nerd Font', monospace;
  font-size: 13px;
  font-weight: bold;
  color: {fg};
}}
.label {{
  font-family: 'JetBrainsMono Nerd Font', monospace;
  font-size: 11px;
  color: {muted};
}}
.value {{
  font-family: 'JetBrainsMono Nerd Font', monospace;
  font-size: 11px;
  color: {fg};
}}
.updated {{
  font-family: 'JetBrainsMono Nerd Font', monospace;
  font-size: 9px;
  color: {subtle};
}}
progressbar {{
  min-height: 10px;
}}
progressbar trough {{
  background-color: {track};
  border-radius: 5px;
  min-height: 10px;
}}
progressbar progress {{
  border-radius: 5px;
  min-height: 10px;
  background-color: {green};
}}
progressbar.warning progress {{
  background-color: {yellow};
}}
progressbar.high progress {{
  background-color: {orange};
}}
progressbar.critical progress {{
  background-color: {red};
}}
"""


# ── Helpers ───────────────────────────────────────────────────────────────────
def fmt_tokens(n):
    if n < 1_000:
        return str(n)
    elif n < 1_000_000:
        return f"{n/1_000:.1f}k"
    else:
        return f"{n/1_000_000:.2f}M"


def query_tokens(since_ms):
    try:
        con = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True, timeout=5)
        cur = con.execute(
            """
            SELECT COALESCE(SUM(json_extract(data, '$.tokens.output')), 0)
            FROM message
            WHERE json_extract(data, '$.role') = 'assistant'
              AND time_created >= ?
              AND json_extract(data, '$.tokens.output') > 0
            """,
            (since_ms,),
        )
        result = int(cur.fetchone()[0])
        con.close()
        return result
    except Exception:
        return -1


def css_class(fraction):
    if fraction < 0.5:
        return None
    elif fraction < 0.75:
        return "warning"
    elif fraction < 0.9:
        return "high"
    else:
        return "critical"


def try_toggle():
    if LOCK_FILE.exists():
        try:
            pid = int(LOCK_FILE.read_text().strip())
            os.kill(pid, signal.SIGTERM)
            LOCK_FILE.unlink(missing_ok=True)
            sys.exit(0)
        except (ProcessLookupError, ValueError):
            LOCK_FILE.unlink(missing_ok=True)
    LOCK_FILE.write_text(str(os.getpid()))


# ── Main window ───────────────────────────────────────────────────────────────
class UsageWindow(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title(APP_ID)
        self.set_resizable(False)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_keep_above(True)
        self.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)

        theme = load_theme()
        provider = Gtk.CssProvider()
        provider.load_from_data(build_css(theme).encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.connect("key-press-event", self._on_key)
        self.connect("focus-out-event", self._on_focus_out)
        self._build_ui()
        self._refresh()
        GLib.timeout_add(REFRESH_INTERVAL, self._refresh)

    def _build_ui(self):
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        outer.set_margin_top(14)
        outer.set_margin_bottom(14)
        outer.set_margin_start(18)
        outer.set_margin_end(18)
        self.add(outer)

        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icon = Gtk.Label(label="󰭹")
        icon.get_style_context().add_class("header")
        title = Gtk.Label(label="Claude Usage")
        title.get_style_context().add_class("header")
        hbox.pack_start(icon, False, False, 0)
        hbox.pack_start(title, False, False, 0)
        outer.pack_start(hbox, False, False, 0)

        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep.set_margin_top(8)
        sep.set_margin_bottom(10)
        outer.pack_start(sep, False, False, 0)

        self._session_bar, self._session_label, self._session_pct = \
            self._make_bar_row(outer, "5h window")
        outer.pack_start(Gtk.Box(), False, False, 4)
        self._weekly_bar, self._weekly_label, self._weekly_pct = \
            self._make_bar_row(outer, "7d week  ")

        self._updated_label = Gtk.Label(label="")
        self._updated_label.get_style_context().add_class("updated")
        self._updated_label.set_halign(Gtk.Align.END)
        self._updated_label.set_margin_top(10)
        outer.pack_start(self._updated_label, False, False, 0)

    def _make_bar_row(self, parent, label_text):
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        lbl = Gtk.Label(label=label_text)
        lbl.get_style_context().add_class("label")
        lbl.set_halign(Gtk.Align.START)
        pct = Gtk.Label(label="")
        pct.get_style_context().add_class("value")
        pct.set_halign(Gtk.Align.END)
        hbox.pack_start(lbl, True, True, 0)
        hbox.pack_end(pct, False, False, 0)
        vbox.pack_start(hbox, False, False, 0)
        bar = Gtk.ProgressBar()
        bar.set_fraction(0)
        bar.set_size_request(260, 10)
        vbox.pack_start(bar, False, False, 0)
        parent.pack_start(vbox, False, False, 0)
        return bar, lbl, pct

    def _set_bar(self, bar, pct_label, tokens, limit):
        frac = min(1.0, tokens / limit) if limit > 0 else 0
        bar.set_fraction(frac)
        ctx = bar.get_style_context()
        for cls in ("warning", "high", "critical"):
            ctx.remove_class(cls)
        cls = css_class(frac)
        if cls:
            ctx.add_class(cls)
        pct_label.set_text(f"{fmt_tokens(tokens)} / {fmt_tokens(limit)}  ({round(frac*100)}%)")

    def _refresh(self):
        now_ms = int(time.time() * 1000)
        session_tokens = query_tokens(now_ms - SESSION_HOURS * 3600 * 1000)
        weekly_tokens  = query_tokens(now_ms - 7 * 24 * 3600 * 1000)
        if session_tokens >= 0:
            self._set_bar(self._session_bar, self._session_pct, session_tokens, SESSION_LIMIT)
        if weekly_tokens >= 0:
            self._set_bar(self._weekly_bar, self._weekly_pct, weekly_tokens, WEEKLY_LIMIT)
        self._updated_label.set_text(f"updated {datetime.datetime.now().strftime('%H:%M:%S')}")
        return True

    def _on_key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self._quit()

    def _on_focus_out(self, widget, event):
        self._quit()

    def _quit(self):
        LOCK_FILE.unlink(missing_ok=True)
        Gtk.main_quit()


def main():
    try_toggle()
    win = UsageWindow()
    win.show_all()

    display = Gdk.Display.get_default()
    monitor = display.get_primary_monitor() or display.get_monitor(0)
    geom = monitor.get_geometry()
    win.realize()
    w, h = win.get_size()
    x = geom.x + geom.width - w - 10
    y = geom.y + 32
    win.move(x, y)

    signal.signal(signal.SIGTERM, lambda *_: (LOCK_FILE.unlink(missing_ok=True), Gtk.main_quit()))
    Gtk.main()


if __name__ == "__main__":
    main()
POPUP_SCRIPT

chmod +x "$HOME/.local/bin/claude-usage-popup"
echo "  ✓ Popup script installed to ~/.local/bin/claude-usage-popup"

# ── 2. Patch Waybar config ───────────────────────────────────────────────────
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"

if [ -f "$WAYBAR_CONFIG" ]; then
    if ! grep -q "claude-usage" "$WAYBAR_CONFIG"; then
        python3 - "$WAYBAR_CONFIG" << 'PATCHER'
import re, sys

path = sys.argv[1]
content = open(path).read()

# Insert custom/claude-usage before "cpu" in modules-right
content = re.sub(
    r'("pulseaudio",\s*\n(\s*))"cpu"',
    r'\1"custom/claude-usage",\n\2"cpu"',
    content
)

# Insert module config before the "cpu" block
module_def = '''  "custom/claude-usage": {
    "format": "\\u{f0ebf9}",
    "on-click": "setsid uwsm-app -- python3 ~/.local/bin/claude-usage-popup",
    "tooltip-format": "Claude usage",
    "interval": "once"
  },

  '''
content = re.sub(r'(\s*"cpu":\s*\{)', module_def + r'\1', content, count=1)

open(path, 'w').write(content)
print("  ✓ Waybar config patched")
PATCHER
    else
        echo "  ✓ Waybar config already has claude-usage module, skipping"
    fi
else
    echo "  ! Waybar config not found at $WAYBAR_CONFIG, skipping"
fi

# ── 3. Patch Waybar CSS ──────────────────────────────────────────────────────
WAYBAR_CSS="$HOME/.config/waybar/style.css"

if [ -f "$WAYBAR_CSS" ]; then
    if ! grep -q "claude-usage" "$WAYBAR_CSS"; then
        cat >> "$WAYBAR_CSS" << 'CSS'

#custom-claude-usage {
  margin: 0 7.5px;
  font-size: 14px;
  min-width: 12px;
}
CSS
        echo "  ✓ Waybar CSS patched"
    else
        echo "  ✓ Waybar CSS already has claude-usage styles, skipping"
    fi
else
    echo "  ! Waybar CSS not found at $WAYBAR_CSS, skipping"
fi

# ── 4. Patch Hyprland config ─────────────────────────────────────────────────
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    if ! grep -q "claude-usage-popup" "$HYPR_CONFIG"; then
        cat >> "$HYPR_CONFIG" << 'HYPR'

# Claude usage popup
windowrule = float on, match:title ^claude-usage-popup$
windowrule = pin on, match:title ^claude-usage-popup$
windowrule = move 100%- 32, match:title ^claude-usage-popup$
HYPR
        echo "  ✓ Hyprland window rules added"
    else
        echo "  ✓ Hyprland config already has claude-usage rules, skipping"
    fi
else
    echo "  ! Hyprland config not found at $HYPR_CONFIG, skipping"
fi

# ── 5. Restart Waybar ────────────────────────────────────────────────────────
if command -v omarchy-restart-waybar &> /dev/null; then
    omarchy-restart-waybar
    echo "  ✓ Waybar restarted"
fi

echo ""
echo "Claude usage widget installed!"
echo "Click the 󰭹 icon in your Waybar to open the usage popup."
