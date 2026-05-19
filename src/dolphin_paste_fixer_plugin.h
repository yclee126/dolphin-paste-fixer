#pragma once

#include <kwin/plugin.h>

#include <memory>

class DolphinPopupObserver;

class DolphinPasteFixerPlugin : public KWin::Plugin
{
    Q_OBJECT

public:
    explicit DolphinPasteFixerPlugin();
    ~DolphinPasteFixerPlugin() override;

private:
    std::unique_ptr<DolphinPopupObserver> m_observer;
};

class DolphinPasteFixerPluginFactory : public KWin::PluginFactory
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID PluginFactory_iid FILE "metadata.json")
    Q_INTERFACES(KWin::PluginFactory)

public:
    std::unique_ptr<KWin::Plugin> create() const override;
};
