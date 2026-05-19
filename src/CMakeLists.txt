set(dolphinpastefixer_SRCS
    dolphin_paste_fixer_plugin.cpp
    dolphin_popup_observer.cpp
)

add_library(dolphinpastefixer MODULE ${dolphinpastefixer_SRCS})

target_include_directories(dolphinpastefixer PRIVATE
    ${KWIN_INCLUDE_DIR}
    ${KWIN_INCLUDE_DIR}/kwin
)

target_link_libraries(dolphinpastefixer PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Widgets
    KF6::ConfigCore
    KF6::WindowSystem
    ${KWIN_LIBRARY}
)

# KWin loads plugins from $libdir/kwin/plugins/.
install(TARGETS dolphinpastefixer
    DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/plugins
)
