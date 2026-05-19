#!/usr/bin/env bash
# Arch Linux installer: builds and installs the plugin, then registers a
# pacman hook so the plugin is automatically rebuilt after every kwin upgrade.
#
# Usage:
#   ./install-arch.sh
#   BUILD_TYPE=Debug ./install-arch.sh
#
# Re-runs itself under sudo if not already root (needed to write to /etc and
# /usr/local).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo --preserve-env=BUILD_DIR,BUILD_TYPE,JOBS,CMAKE_INSTALL_PREFIX \
        bash "$0" "$@"
fi

echo ">> Building and installing plugin"
"$SCRIPT_DIR/install.sh"

echo ">> Registering pacman hook"

# Store the source directory so the hook can find it after a kwin upgrade.
install -d /etc/dolphinpastefixer
echo "$SCRIPT_DIR" > /etc/dolphinpastefixer/source_dir

# Install the hook runner to a fixed system path.
install -Dm755 /dev/stdin /usr/local/lib/dolphinpastefixer/rebuild.sh <<'HOOKSCRIPT'
#!/usr/bin/env bash
set -euo pipefail
SOURCE_DIR="$(cat /etc/dolphinpastefixer/source_dir)"
echo ">> Source directory: $SOURCE_DIR"
"$SOURCE_DIR/install.sh"
echo ">> Log out and back in to load the updated plugin."
HOOKSCRIPT

# Install the pacman hook definition.
install -d /etc/pacman.d/hooks
install -Dm644 "$SCRIPT_DIR/dolphinpastefixer.hook" \
    /etc/pacman.d/hooks/dolphinpastefixer.hook

cat <<'EOF'

Pacman hook installed at /etc/pacman.d/hooks/dolphinpastefixer.hook

The plugin will be rebuilt automatically after each kwin upgrade.
Log out and back in now to load the freshly installed plugin.

To remove everything later, run ./uninstall.sh and then:
  sudo rm -rf /etc/dolphinpastefixer /usr/local/lib/dolphinpastefixer
  sudo rm -f /etc/pacman.d/hooks/dolphinpastefixer.hook
EOF
