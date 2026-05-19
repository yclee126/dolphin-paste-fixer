# dolphin-paste-fixer

A small C++ KWin plugin for KDE Plasma 6 (Wayland) that fixes clipboard paste in Dolphin popups. It runs entirely inside KWin as a single shared library so it's very lightweight.

## The problem

When a popup opens inside Dolphin (such as the new folder dialog), Ctrl+V always fails to paste even though you copied something. This is a Dolphin bug where it loses track of the clipboard on popup open.

Related bug tickets:

- Can't paste text to the new folder dialog [#516263](https://bugs.kde.org/show_bug.cgi?id=516263) [#517780](https://bugs.kde.org/show_bug.cgi?id=517780)
- Can't paste text to the new file dialog [#519034](https://bugs.kde.org/show_bug.cgi?id=519034)
- Can't paste files after creating a new folder in another window [#519770](https://bugs.kde.org/show_bug.cgi?id=519770)

## The fix

This plugin detects new Dolphin popup by watching the Wayland seat for keyboard focus moving to it. When that happens it silently re-delivers the current clipboard offer to the popup, restoring paste instantly. The manual equivalent is pressing Super+V to pop up the clipboard manager and selecting the top item.

## Requirements

- KDE Plasma 6 on Wayland
- KWin 6.x (shipped with Plasma 6)

## Tested on

| Distribution | KWin | Dolphin |
|---|---|---|
| Arch Linux | 6.6.5 | 25.12.3 |
| KDE neon 260514 | 6.6.5 | 26.04.1 |
| Kubuntu 26.04 LTS | 6.6.4 | 25.12.3 |

To check your KWin version: `kwin_wayland --version`

## Installation

### 1. Install build dependencies

| Distribution | Command |
|---|---|
| **Arch Linux (CachyOS)** | `sudo pacman -S base-devel cmake pkgconf extra-cmake-modules qt6-base kwin kconfig kwindowsystem` |
| **Debian (Ubuntu)** | `sudo apt install build-essential cmake pkg-config extra-cmake-modules kwin-dev libkf6config-dev libkf6windowsystem-dev qt6-base-dev` |
| **Fedora** | `sudo dnf install gcc-c++ cmake pkgconf extra-cmake-modules kwin-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-qtbase-devel` |
| **openSUSE** | `sudo zypper install gcc-c++ cmake pkgconf extra-cmake-modules kwin6-devel kf6-kconfig-devel kf6-kwindowsystem-devel qt6-base-devel` |

### 2. Build and install

```bash
git clone https://github.com/yclee126/dolphin-paste-fixer
cd dolphin-paste-fixer
```

**Arch Linux** — use the Arch installer, which also sets up a pacman hook that rebuilds the plugin automatically after every KWin upgrade. Make sure the cloned repo sits on a permanent location before running it, as the hook needs to find the source directory on every KWin upgrade:

```bash
./install-arch.sh
```

**Other distros** — one-time install:

```bash
./install.sh
```

Then log out and log back in.

## Uninstalling

**Arch Linux:**

```bash
./uninstall-arch.sh
```

**Other distros:**

```bash
./uninstall.sh
```

Then log out and log back in.

## Verifying it works

1. Copy some text.
2. Pop up the new folder dialog in Dolphin. (right-click > Create New > Folder...)
3. Press Ctrl+V in the name field.
4. The text pastes.

## After KWin upgrades

KWin requires all plugins to embed its minor version in their plugin ID (e.g. `org.kde.kwin.PluginFactoryInterface6.6.4`). This is enforced by KWin itself — it uses private, unstable headers that can change between minor versions, so without any safeguards it could cause a system crash.

Rebuild and reinstall by running `./install.sh` again, then log out and back in.

**Arch Linux:** if you installed with `./install-arch.sh`, the pacman hook handles this automatically on every `pacman -Syu`. Just log out and back in afterward.

## How it works

`DolphinPopupObserver` subscribes to `KWin::SeatInterface::focusedKeyboardSurfaceAboutToChange`. When focus is about to move to a popup whose parent toplevel is `org.kde.dolphin`, it queues a call (via `Qt::QueuedConnection`) to toggle `seat->setFocusedDataDeviceSurface()` — first to `nullptr`, then back to the popup's surface. This causes the compositor to re-emit `wl_data_offer` on Dolphin's `wl_data_device` stream, restoring clipboard state naturally.

The queued dispatch is essential: the signal fires *before* KWin updates `focusedKeyboardSurface()`, so toggling synchronously would re-deliver to the old surface. Running one event-loop turn later guarantees the new surface is already focused.

## License

GPL-2.0-or-later
