#include "dolphin_popup_observer.h"

#include <kwin/wayland/seat.h>
#include <kwin/wayland_server.h>
#include <kwin/window.h>
#include <kwin/workspace.h>

#include <QLoggingCategory>

Q_LOGGING_CATEGORY(LOG_DPF, "kwin.dolphinpastefixer", QtWarningMsg)

namespace
{
bool matchesDolphin(const QString &resourceClass)
{
    return resourceClass.compare(QLatin1String("org.kde.dolphin"), Qt::CaseInsensitive) == 0;
}
} // namespace

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
    auto *parent = window->transientFor();
    if (!parent || !matchesDolphin(parent->resourceClass())) {
        return;
    }

    qCDebug(LOG_DPF) << "Dolphin popup gaining focus; queueing clipboard refresh";
    // The signal fires *before* KWin updates focusedKeyboardSurface(), so we
    // can't toggle the data-device surface synchronously here - the current
    // focused surface is still the parent toplevel. A queued invocation runs
    // after KWin finishes the focus change, at which point
    // seat->focusedKeyboardSurface() is the popup and the toggle re-delivers
    // wl_data_offer to it.
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

    // Toggle the seat's data-device focus surface (separate from keyboard
    // focus) to force re-delivery of wl_data_offer for the current selection.
    // setFocusedDataDeviceSurface only touches the wl_data_device protocol
    // stream, so Qt's shortcut/focus widgets are untouched. We do not call
    // setSelection(nullptr, ...) - that causes Plasma's clipboard manager to
    // record a spurious empty entry; and setSelection(currentSource, newSerial)
    // on its own short-circuits and does nothing.
    qCDebug(LOG_DPF) << "Re-delivering selection via data-device focus toggle (surface=" << focused << ")";
    seat->setFocusedDataDeviceSurface(nullptr);
    seat->setFocusedDataDeviceSurface(focused);
}
