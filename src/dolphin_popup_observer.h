#pragma once

#include <QObject>

namespace KWin {
class SurfaceInterface;
}

// Re-delivers wl_data_offer on every keyboard focus transition to fix a
// Qt/KWin roundtrip timing bug that causes apps to discard the clipboard.
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
