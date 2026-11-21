cmake_minimum_required(VERSION 3.16)

project(PhotoPoint VERSION 0.1 LANGUAGES CXX)


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QML_IMPORT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src/qml" CACHE STRING "" FORCE)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 WebEngineQuick WebChannel)

qt_standard_project_setup(REQUIRES 6.8)


qt_add_executable(PhotoPoint
    src/main.cpp
)

set_source_files_properties(src/qml/Main.qml PROPERTIES
    QT_RESOURCE_ALIAS Main.qml
)

target_compile_definitions(PhotoPoint
    PRIVATE QT_QML_DEBUG
)


qt_add_qml_module(PhotoPoint
    URI PhotoPoint
    VERSION 1.0
        QML_FILES
            src/qml/Main.qml
            src/qml/pages/PhotoSelectionPage.qml
        NO_CACHEGEN
        SOURCES
            src/backend/ApplicationBackend.h
            src/backend/ApplicationBackend.cpp
)

set_target_properties(PhotoPoint PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(PhotoPoint
    PRIVATE Qt6::Quick
    Qt6::QuickControls2
    Qt6::WebEngineQuick
    Qt6::WebChannel
)

target_include_directories(PhotoPoint PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend
)

include(GNUInstallDirs)
install(TARGETS PhotoPoint
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
