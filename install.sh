#!/usr/bin/env bash
# Build and install the Dolphin Paste Fixer KWin plugin.
#
# Usage:
#   ./install.sh                    # configure, build, install with sudo
#   BUILD_DIR=out ./install.sh      # use a different build directory
#   BUILD_TYPE=Debug ./install.sh   # change CMake build type
#   JOBS=8 ./install.sh             # override parallel build jobs
#   CMAKE_INSTALL_PREFIX=/usr/local ./install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX:-/usr}"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "warning: not root and sudo is not on PATH; the install step will likely fail." >&2
    fi
fi

missing=()
for tool in cmake make g++ pkg-config; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "error: required tools missing: ${missing[*]}" >&2
    echo "  Debian/Ubuntu: sudo apt install build-essential cmake pkg-config" >&2
    echo "  Fedora:        sudo dnf install gcc-c++ cmake pkgconf" >&2
    echo "  Arch:          sudo pacman -S base-devel cmake pkgconf" >&2
    exit 1
fi

echo ">> Configuring  ($BUILD_DIR, $BUILD_TYPE, prefix=$INSTALL_PREFIX)"
cmake -S . -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"

echo ">> Building     (-j $JOBS)"
cmake --build "$BUILD_DIR" -j "$JOBS"

echo ">> Installing   (with ${SUDO:-no sudo})"
$SUDO cmake --install "$BUILD_DIR"

cat <<'EOF'

Installed.

KWin only loads plugins at start-up, so to pick up the new plugin you need
to log out and log back in.

To remove the plugin later, run ./uninstall.sh from this directory.
EOF
