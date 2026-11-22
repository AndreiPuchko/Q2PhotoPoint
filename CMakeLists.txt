cmake_minimum_required(VERSION 3.16)

project(Q2PhotoPoint VERSION 0.1 LANGUAGES CXX)


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QML_IMPORT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src/qml" CACHE STRING "" FORCE)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 WebEngineQuick WebChannel)

qt_standard_project_setup(REQUIRES 6.8)


qt_add_executable(Q2PhotoPoint
    src/main.cpp
)

set_source_files_properties(src/qml/Main.qml PROPERTIES
    QT_RESOURCE_ALIAS Main.qml
)

target_compile_definitions(Q2PhotoPoint
    PRIVATE QT_QML_DEBUG
)


qt_add_qml_module(Q2PhotoPoint
    URI Q2PhotoPoint
    VERSION 1.0
        QML_FILES
            src/qml/Main.qml
            src/qml/pages/PhotoSelectionPage.qml
        RESOURCES
            src/qml/pages/folder-up.svg
        NO_CACHEGEN
        SOURCES
            src/backend/ApplicationBackend.h
            src/backend/ApplicationBackend.cpp
            src/backend/FileSystemNavigator.h
            src/backend/FileSystemNavigator.cpp
)

set_target_properties(Q2PhotoPoint PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(Q2PhotoPoint
    PRIVATE Qt6::Quick
    Qt6::QuickControls2
    Qt6::WebEngineQuick
    Qt6::WebChannel
)

target_include_directories(Q2PhotoPoint PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend
)

include(GNUInstallDirs)
install(TARGETS Q2PhotoPoint
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
