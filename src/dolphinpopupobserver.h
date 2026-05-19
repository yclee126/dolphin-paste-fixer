#pragma once

#include <QObject>

namespace KWin {
class SurfaceInterface;
}

// Watches the Wayland seat for keyboard focus moving to an xdg_popup whose
// parent toplevel belongs to Dolphin (e.g. the "New Folder" rename popup,
// context menus that host editable fields). On that transition we re-deliver
// the current clipboard selection so paste lands on the right item.
//
// We hook focusedKeyboardSurfaceAboutToChange (the only seat-level signal that
// carries the upcoming surface) and queue the refresh via Qt::QueuedConnection
// so it runs after KWin has actually moved focus to the popup.
class DolphinPopupObserver : public QObject
{
    Q_OBJECT

public:
    DolphinPopupObserver();
    ~DolphinPopupObserver() override;

private:
    void onFocusedKeyboardSurfaceAboutToChange(KWin::SurfaceInterface *nextSurface);
    void refreshClipboard();
};
