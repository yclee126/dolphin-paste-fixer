#!/usr/bin/env bash
# Wipe the build directory and do a clean configure + build.
# Used for fast iteration; does not install (run ./install.sh for that).
#
# Usage:
#   ./rebuild.sh
#   BUILD_DIR=out ./rebuild.sh
#   BUILD_TYPE=Debug ./rebuild.sh
#   JOBS=8 ./rebuild.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

rm -rf "$BUILD_DIR"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$BUILD_DIR" -j "$JOBS"
