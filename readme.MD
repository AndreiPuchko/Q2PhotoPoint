# Q2PhotoPoint

Qt application for desktop platforms and Android for browsing photos and building an image selection. The interface is implemented in QML, with filesystem navigation logic in C++.

## Features

- Browse folders and JPG, JPEG, and PNG images.
- Preview images with asynchronous loading and caching.
- Zoom and rotate images; viewing state is kept in memory when switching between files.
- Add and remove photos from the result, and reorder entries by dragging them between rows.
- Save and open ordered selections and image viewing state as `.q2c` JSON files.
- Export the selected photos to a borderless PDF at 300 DPI, with one full-image page per photo.
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