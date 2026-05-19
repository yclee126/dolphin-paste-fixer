#include "dolphinpastefixerplugin.h"

#include "dolphinpopupobserver.h"

DolphinPasteFixerPlugin::DolphinPasteFixerPlugin()
    : m_observer(std::make_unique<DolphinPopupObserver>())
{
}

DolphinPasteFixerPlugin::~DolphinPasteFixerPlugin() = default;

std::unique_ptr<KWin::Plugin> DolphinPasteFixerPluginFactory::create() const
{
    return std::make_unique<DolphinPasteFixerPlugin>();
}
