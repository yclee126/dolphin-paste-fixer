#include "dolphin_paste_fixer_plugin.h"

#include "dolphin_popup_observer.h"

DolphinPasteFixerPlugin::DolphinPasteFixerPlugin()
    : m_observer(std::make_unique<DolphinPopupObserver>())
{
}

DolphinPasteFixerPlugin::~DolphinPasteFixerPlugin() = default;

std::unique_ptr<KWin::Plugin> DolphinPasteFixerPluginFactory::create() const
{
    return std::make_unique<DolphinPasteFixerPlugin>();
}
