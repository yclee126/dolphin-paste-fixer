#include "dolphin_popup_observer.h"

#include <kwin/wayland/seat.h>
#include <kwin/wayland_server.h>
#include <kwin/window.h>
#include <kwin/workspace.h>

#include <QLoggingCategory>

Q_LOGGING_CATEGORY(LOG_DPF, "kwin.dolphinpastefixer", QtWarningMsg)

DolphinPopupObserver::DolphinPopupObserver()
{
    auto *server = KWin::waylandServer();
    if (!server) {
        qCWarning(LOG_DPF) << "No WaylandServer at construction; observer inactive";
        return;
    }
    auto *seat = server->seat();
    if (!seat) {
        qCWarning(LOG_DPF) << "No seat at construction; observer inactive";
        return;
    }
    connect(seat, &KWin::SeatInterface::focusedKeyboardSurfaceAboutToChange,
            this, &DolphinPopupObserver::onFocusedKeyboardSurfaceAboutToChange);
}

DolphinPopupObserver::~DolphinPopupObserver() = default;

void DolphinPopupObserver::onFocusedKeyboardSurfaceAboutToChange(KWin::SurfaceInterface *nextSurface)
{
    if (!nextSurface) {
        return;
    }
    auto *workspace = KWin::Workspace::self();
    if (!workspace) {
        return;
    }
    auto *window = workspace->findWindow([nextSurface](const KWin::Window *w) {
        return w->surface() == nextSurface;
    });
    if (!window || !window->isPopupWindow()) {
        return;
    }

    qCDebug(LOG_DPF) << "Popup gaining focus; queueing clipboard refresh"
                     << "(app=" << window->resourceClass()
                     << "pid=" << window->pid() << ")";
    // Queued: the signal fires before KWin updates focusedKeyboardSurface(),
    // so a synchronous call here would re-deliver to the old surface.
    QMetaObject::invokeMethod(this, &DolphinPopupObserver::refreshClipboard, Qt::QueuedConnection);
}

void DolphinPopupObserver::refreshClipboard()
{
    auto *server = KWin::waylandServer();
    if (!server) {
        return;
    }
    auto *seat = server->seat();
    if (!seat) {
        return;
    }
    if (!seat->selection()) {
        qCDebug(LOG_DPF) << "Clipboard is empty; nothing to refresh";
        return;
    }
    auto *focused = seat->focusedKeyboardSurface();
    if (!focused) {
        qCDebug(LOG_DPF) << "No focused keyboard surface; nothing to refresh";
        return;
    }

    // Do not use setFocusedKeyboardSurface - triggers Qt to rebuild QShortcutMap,
    // causing Ctrl+V to be reported as ambiguous.
    // Do not use setSelection(nullptr, ...) - records a spurious empty entry in
    // Plasma's clipboard manager. setSelection(currentSource, serial) alone
    // short-circuits and does nothing.
    qCDebug(LOG_DPF) << "Re-delivering selection via data-device focus toggle (surface=" << focused << ")";
    seat->setFocusedDataDeviceSurface(nullptr);
    seat->setFocusedDataDeviceSurface(focused);
}
