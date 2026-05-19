cmake_minimum_required(VERSION 3.16)
project(dolphin-paste-fixer LANGUAGES CXX VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(QT_MIN_VERSION 6.5.0)
set(KF_MIN_VERSION 6.0.0)

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    DBus
    Gui
    Widgets
)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    Config
    WindowSystem
)

# KWin does not ship a stable public CMake config file for out-of-tree input
# plugins. We resolve the headers and library manually. On Debian/Ubuntu this
# comes from `kwin-dev`; on Arch it is part of `kwin`; on Fedora it is
# `kwin-devel`. Override with -DKWIN_INCLUDE_DIR=... / -DKWIN_LIBRARY=... if
# your distro lays them out differently.
find_path(KWIN_INCLUDE_DIR
    NAMES kwin/plugin.h
    HINTS /usr/include /usr/local/include
)
find_library(KWIN_LIBRARY
    NAMES kwin
    HINTS /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu
)

if(NOT KWIN_INCLUDE_DIR OR NOT KWIN_LIBRARY)
    message(FATAL_ERROR
        "KWin development files were not found.\n"
        "Install the kwin development package (kwin-dev / kwin-devel) or pass\n"
        "  -DKWIN_INCLUDE_DIR=<path-to-kwin-headers>\n"
        "  -DKWIN_LIBRARY=<path-to-libkwin.so>\n"
        "to cmake.")
endif()

message(STATUS "Using KWin headers : ${KWIN_INCLUDE_DIR}")
message(STATUS "Using KWin library : ${KWIN_LIBRARY}")

add_subdirectory(src)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
