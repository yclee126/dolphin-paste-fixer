#!/usr/bin/env bash
# Remove the Arch-specific hook installation, then uninstall the plugin.
#
# Usage:
#   ./uninstall-arch.sh
#   BUILD_DIR=out ./uninstall-arch.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo --preserve-env=BUILD_DIR bash "$0" "$@"
fi

echo ">> Removing pacman hook"
rm -f /etc/pacman.d/hooks/dolphinpastefixer.hook

echo ">> Removing hook runner"
rm -rf /usr/local/lib/dolphinpastefixer

echo ">> Removing source directory config"
rm -rf /etc/dolphinpastefixer

echo ">> Uninstalling plugin"
"$SCRIPT_DIR/uninstall.sh"
