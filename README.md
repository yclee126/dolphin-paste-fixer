# dolphin-paste-fixer

A small C++ KWin plugin for KDE Plasma 6 (Wayland) that fixes clipboard paste in Dolphin popups.

## The problem

When a popup opens inside Dolphin (such as the new folder dialog) Ctrl+V fails to paste until you copy something again. Dolphin holds a stale `wl_data_offer` at the point the popup takes keyboard focus, so the clipboard appears empty to the popup.

Related bug tickets:

- Can't paste text to the new folder dialog [#516263](https://bugs.kde.org/show_bug.cgi?id=516263)
- Can't paste text to the new file dialog [#519034](https://bugs.kde.org/show_bug.cgi?id=519034)
- Can't paste files after creating a new folder in another window [#519770](https://bugs.kde.org/show_bug.cgi?id=519770)

## The fix

This plugin detects new Dolphin popup by watching the Wayland seat for keyboard focus moving to it. When that happens it silently re-delivers the current clipboard offer to the popup, restoring paste instantly. The manual equivalent is pressing Super+V to pop up the clipboard manager and selecting the top item.

## Requirements

- KDE Plasma 6 on Wayland
- KWin 6.x (shipped with Plasma 6)

## Installation

### 1. Install build dependencies

| Distribution | Command |
|---|---|
| **Arch Linux** | `sudo pacman -S cmake extra-cmake-modules qt6-base kwin kconfig kwindowsystem` |
| **Debian (Ubuntu)** | `sudo apt install build-essential cmake extra-cmake-modules kwin-dev libkf6config-dev libkf6windowsystem-dev qt6-base-dev` |
| **Fedora** | `sudo dnf install gcc-c++ cmake extra-cmake-modules kwin-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-qtbase-devel` |
| **openSUSE** | `sudo zypper install gcc-c++ cmake extra-cmake-modules kwin6-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-base-devel` |

### 2. Build and install

```bash
git clone https://github.com/yclee126/dolphin-paste-fixer
cd dolphin-paste-fixer
./install.sh
```

Then log out and log back in.

> **Note:** On stable distros (e.g. Ubuntu, Fedora) this is a one-time step. On rolling-release distros (e.g. Arch) the plugin must be rebuilt after every KWin upgrade. See [After KWin upgrades](#after-kwin-upgrades).

## Uninstalling

```bash
./uninstall.sh
```

Then log out and log back in.

## Verifying it works

1. Copy some text.
2. Pop up the new folder dialog in Dolphin. (right-click > Create New > Folder...)
3. Press Ctrl+V in the name field.
4. The text pastes.

## Debug logging

```bash
./toggle-debug.sh
```

Log out and back in, then watch the output:

```bash
journalctl --user _COMM=kwin_wayland -f | grep dolphinpastefixer
```

Run `./toggle-debug.sh` again to turn logging off.

## After KWin upgrades

KWin requires all plugins to embed its minor version in their plugin ID (e.g. `org.kde.kwin.PluginFactoryInterface6.6.4`). This is enforced by KWin itself - it uses private, unstable headers that can change between minor versions, so without any safeguards it could cause a system crash. Rebuild and reinstall it by simply running the same `install.sh` file.

## How it works

`DolphinPopupObserver` subscribes to `KWin::SeatInterface::focusedKeyboardSurfaceAboutToChange`. When focus is about to move to a popup whose parent toplevel is `org.kde.dolphin`, it queues a call (via `Qt::QueuedConnection`) to toggle `seat->setFocusedDataDeviceSurface()` — first to `nullptr`, then back to the popup's surface. This causes the compositor to re-emit `wl_data_offer` on Dolphin's `wl_data_device` stream, restoring clipboard state naturally.

The queued dispatch is essential: the signal fires *before* KWin updates `focusedKeyboardSurface()`, so toggling synchronously would re-deliver to the old surface. Running one event-loop turn later guarantees the new surface is already focused.

## License

GPL-2.0-or-later
