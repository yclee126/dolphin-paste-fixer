# Debugging

## Enable debug logging

Add the following line under the `[Rules]` section of `~/.config/QtProject/qtlogging.ini`:

```
kwin.dolphinpastefixer*=true
```

If the file or section doesn't exist, create them:

```ini
[Rules]
kwin.dolphinpastefixer*=true
```

The `toggle-debug.sh` script (not included in the repository) automates this toggle.

Log out and back in for the change to take effect.

## Watch the output

```bash
journalctl --user _COMM=kwin_wayland -f
```

Log lines are emitted at `QtWarningMsg` level, so they are silent by default and only appear when the rule above is active.

## Disable debug logging

Remove the `kwin.dolphinpastefixer*=true` line from `qtlogging.ini`, then log out and back in.
