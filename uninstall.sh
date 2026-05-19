#!/usr/bin/env bash
# Remove the installed Dolphin Paste Fixer KWin plugin.
#
# Prefers the install_manifest.txt CMake writes during `cmake --install`. If
# that is gone (e.g. the build directory was wiped) it falls back to scanning
# the well-known KWin plugin directories for libdolphinpastefixer.so.
#
# Usage:
#   ./uninstall.sh
#   BUILD_DIR=out ./uninstall.sh    # if you used a non-default BUILD_DIR
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${BUILD_DIR:-build}"
# KDE / Qt drop the "lib" prefix for module plugins, so the installed file is
# `dolphinpastefixer.so` (no "lib" prefix).
PLUGIN_LIB="dolphinpastefixer.so"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "warning: not root and sudo is not on PATH; removal will likely fail." >&2
    fi
fi

remove_path() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        echo "  rm $path"
        $SUDO rm -f -- "$path"
        return 0
    fi
    return 1
}

manifest="$BUILD_DIR/install_manifest.txt"
removed=0

if [ -f "$manifest" ]; then
    echo ">> Removing files listed in $manifest"
    while IFS= read -r path || [ -n "$path" ]; do
        [ -z "$path" ] && continue
        if remove_path "$path"; then
            removed=$((removed + 1))
        fi
    done < "$manifest"
fi

if [ "$removed" -eq 0 ]; then
    echo ">> install_manifest.txt missing; searching kwin plugin dirs for $PLUGIN_LIB"
    # Use find so we don't have to enumerate every libdir flavor across distros.
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        if remove_path "$path"; then
            removed=$((removed + 1))
        fi
    done < <(find /usr /usr/local -path "*/kwin/plugins/$PLUGIN_LIB" 2>/dev/null)
fi

if [ "$removed" -eq 0 ]; then
    echo "error: no installed copy of $PLUGIN_LIB was found." >&2
    echo "If you installed to an unusual prefix, locate and remove it manually:" >&2
    echo "  ${SUDO:-} find / -name $PLUGIN_LIB 2>/dev/null" >&2
    exit 1
fi

cat <<EOF

Removed $removed file(s).

Log out and log back so KWin unloads the plugin:
EOF
