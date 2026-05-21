# dolphin-paste-fixer

**Note:** As of May 21 the relevant bugfix is active on [The Qt Project](https://codereview.qt-project.org/c/qt/qtbase/+/737101), so please check if it's fixed in the latest Qt library before installing this fix.

A small C++ KWin plugin for KDE Plasma 6 (Wayland) that fixes a bug in Dolphin where you can't paste text or files after opening a new folder dialog through the context menu. It watches for context menu popups and re-arms the clipboard afterward. The fix also applies to other Qt apps with nested context menus.

## The problem

After opening the new folder dialog in Dolphin, Ctrl+V fails to paste any text. Originally it was thought of a popup triggered problem, but turns out it was caused by nested context menus.

From the comments posted by David Edmundson in [#516263](https://bugs.kde.org/show_bug.cgi?id=516263#c7), it's a communication error between KWin and Qt, which results in Dolphin throwing away the clipboard content after the context menu gets closed.

## The fix

This plugin detects focus change between popups which includes context menus and re-delivers the clipboard content. This is queued in the event queue, so at the end it receives the clipboard content, restoring the paste functionality. The manual equivalent is pressing Super+V to pop up the clipboard manager and selecting the top item.

Since the bug affects other Qt apps it detects such popups system-wide. The code hardly generates any overhead so you won't notice anything.

(Just a dev footnote: The code was actually written to detect the new folder dialog, but it just so happens that it detected the context menu re-gaining focus shortly after the child context menu closed, creating the illusion. If it works then it works I guess.)

## Related bugs

- Can't paste text to the new folder dialog [#516263](https://bugs.kde.org/show_bug.cgi?id=516263) [#517780](https://bugs.kde.org/show_bug.cgi?id=517780)
- Can't paste text to the new file dialog [#519034](https://bugs.kde.org/show_bug.cgi?id=519034)
- Can't paste files after creating a new folder in another window [#519770](https://bugs.kde.org/show_bug.cgi?id=519770)

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

```bash
./install.sh
```

Then log out and log back in.

## Uninstalling

```bash
./uninstall.sh
```

Then log out and log back in.

## Arch Linux

Automated build scripts are available. (`install-arch.sh` / `uninstall-arch.sh`) They additionally set up a pacman hook that rebuilds the plugin automatically after every KWin upgrade. Since the bugfix is active it might get fixed in the next release so I placed this section at the end. You can use the standard scripts just fine.

## Verifying it works

1. Copy some text.
2. Pop up the new folder dialog in Dolphin. (right-click > Create New > Folder...)
3. Press Ctrl+V in the name field.
4. The text pastes.

## After KWin upgrades

KWin requires all plugins to embed its minor version in their plugin ID (e.g. `org.kde.kwin.PluginFactoryInterface6.6.4`). This is enforced by KWin itself — it uses private, unstable headers that can change between minor versions, so without any safeguards it could cause a system crash.

Rebuild and reinstall by running `./install.sh` again, then log out and back in.

**Arch Linux:** if you installed with `./install-arch.sh`, the pacman hook handles this automatically on every `pacman -Syu`. Just log out and back in afterward.

## How it works (technical)

`DolphinPopupObserver` subscribes to `KWin::SeatInterface::focusedKeyboardSurfaceAboutToChange`. On every focus transition it queues a call (via `Qt::QueuedConnection`) to toggle `seat->setFocusedDataDeviceSurface()` — first to `nullptr`, then back to the now-focused surface. Because `wl_data_device` is per-client, this causes the compositor to re-emit `wl_data_offer` on the focused app's data device stream.

The queued dispatch is essential: `focusedKeyboardSurfaceAboutToChange` fires *before* KWin updates `focusedKeyboardSurface()`, so toggling synchronously would re-deliver to the old surface. Running one event-loop turn later guarantees the new surface is already focused.

## License

GPL-2.0-or-later
