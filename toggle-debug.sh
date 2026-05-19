#!/bin/bash
# Toggles kwin.dolphinpastefixer* Qt debug logging in qtlogging.ini.
# Watch output with: journalctl --user _COMM=kwin_wayland -f

INI="$HOME/.config/QtProject/qtlogging.ini"
RULE="kwin.dolphinpastefixer*=true"

if grep -qF "$RULE" "$INI" 2>/dev/null; then
    # Remove the exact rule line using fixed-string, whole-line matching.
    tmp="$(mktemp)"
    grep -vxF "$RULE" "$INI" > "$tmp" || true
    mv "$tmp" "$INI"
    echo "Debug logging disabled"
else
    # Ensure [Rules] section exists, then append the rule
    mkdir -p "$(dirname "$INI")"
    if ! grep -qF "[Rules]" "$INI" 2>/dev/null; then
        printf '[Rules]\n' >> "$INI"
    fi
    printf '%s\n' "$RULE" >> "$INI"
    echo "Debug logging enabled — watch with: journalctl --user _COMM=kwin_wayland -f"
fi
