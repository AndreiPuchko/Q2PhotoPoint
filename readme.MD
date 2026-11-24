# Q2PhotoPoint

Qt application for desktop platforms and Android for browsing photos and building an image selection. The interface is implemented in QML, with filesystem navigation logic in C++.

## Features

- Browse folders and JPG, JPEG, and PNG images.
- Drag a folder or image from the system file manager into the source pane to open its folder and select the image.
- Preview images with asynchronous loading and caching.
- Zoom and rotate images; viewing state is kept in memory when switching between files.
- Add and remove photos from the result, and reorder entries by dragging them between rows.
- Save and open ordered selections and image viewing state as `.q2c` JSON files.
- Drop a `.q2c` file onto an empty result list to open that collection.
- Export the selected photos to a borderless PDF at 300 DPI, with one full-image page per photo.
- Copy the original files in a selection to a chosen folder; existing filenames are preserved where possible, and collisions get a numbered suffix.
- Source images already in the result are marked with a green border.
- Navigate lists with the keyboard and scroll through long lists.
- On Windows, the file browser also shows available drives and network locations.

The selection and viewing state are stored in memory for the current session.

## Controls

### Source list

| Action | Result |
| --- | --- |
| Click an image | Select it and show it in the preview |
| Double-click, `Enter`, or `+` | Add the image to the result |
| Drag an image to the result list | Insert it at the target row |
| `↑` / `↓`, `Page Up` / `Page Down`, `Home` / `End` | Navigate the list |
| `→` | Rotate the selected image |
| `/` | Go to the parent folder |
| `Enter` on a folder | Open the folder |

The Add button in the preview toolbar also adds the selected source image.

### Result list

| Action | Result |
| --- | --- |
| Click a row | Select the image and show it in the preview |
| Drag a row up or down | Reorder the images |
| `↑` / `↓`, `Page Up` / `Page Down`, `Home` / `End` | Navigate the list |
| `→` | Rotate the selected image |
| `Delete` or `-` | Remove the selected image from the result |
| Open collection button | Replace the result with a saved `.q2c` collection |
| Save collection button | Save the selection as a `.q2c` JSON file |

### Preview

The toolbar buttons control zoom, image navigation, and rotation. Use the mouse wheel to switch images and `Ctrl` + mouse wheel to zoom.

## Requirements

- CMake 3.16 or later.
- A C++17 compiler.
- Qt 6.8 or later with the `Quick`, `QuickControls2`, `WebEngineQuick`, and `WebChannel` components.

Building for Android also requires a matching Qt for Android kit, the Android SDK/NDK, and permissions for photo access. Android builds and permissions have not yet been verified for this project.

## Build

Specify the path to your Qt installation if CMake cannot find it automatically:

```powershell
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:\Qt\6.8.3\msvc2022_64"
cmake --build build --config Release
```

Replace `CMAKE_PREFIX_PATH` with the path to your Qt version and compiler kit. After building, run `Q2PhotoPoint.exe` from the build directory (or from `build\Release` when using a multi-configuration generator).

## Windows distribution

Run the packaging script from PowerShell:

```powershell
.\build-distribution.ps1
```

By default, the script uses Qt at `C:\Qt\6.8.3\msvc2022_64`, builds a 64-bit Release version with Visual Studio 2022, deploys the required Qt libraries and QML modules with `windeployqt`, and places the distribution in `dist\Q2PhotoPoint`. It requires a Qt 6.8+ MSVC kit with `WebEngineQuick`; the `QTDIR` environment variable is not used as the default. To use another compatible Qt kit, pass its installation directory:

```powershell
.\build-distribution.ps1 -QtRoot "D:\Qt\6.8.3\msvc2022_64"
```

The application executable will be at `dist\Q2PhotoPoint\bin\Q2PhotoPoint.exe`. The script requires CMake and the Visual Studio 2022 C++ build tools.