pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt.labs.platform
import Q2PhotoPoint

Item {
    id: root

    SplitView {
        anchors.fill: parent
        anchors.margins: 12
        orientation: Qt.Horizontal

        handle: Item {
            implicitWidth: 30
            implicitHeight: 20

            Rectangle {
                width: 14
                height: parent.height
                anchors.centerIn: parent
                color: "#e0e0e0"
            }

            Rectangle {
                width: 4
                height: 36
                radius: 2
                anchors.centerIn: parent
                color: SplitHandle.pressed ? "#1976d2" : (SplitHandle.hovered ? "#64b5f6" : "#9e9e9e")

                scale: SplitHandle.pressed ? 1.2 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }
        }
        // Full preview
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300

            color: "white"
            radius: 8
            id: fullview
            property real zoomFactor: 1
            readonly property real minimumZoomFactor: 1
            readonly property real maximumZoomFactor: 8
            readonly property real zoomStep: 1.25
            property int rotationAngle: 0

            function zoomIn() {
                if (sources.selectedImageIndex < 0)
                    return
                zoomFactor = Math.min(maximumZoomFactor, zoomFactor * zoomStep)
                sources.saveCurrentImageState()
                previewFlickable.forceActiveFocus()
            }

            function zoomOut() {
                if (sources.selectedImageIndex < 0)
                    return
                zoomFactor = Math.max(minimumZoomFactor, zoomFactor / zoomStep)
                sources.saveCurrentImageState()
                previewFlickable.forceActiveFocus()
            }

            function rotateSelectedImage() {
                if (sources.selectedImageIndex < 0)
                    return

                rotationAngle = (rotationAngle + 90) % 360
                previewFlickable.contentX = 0
                previewFlickable.contentY = 0
                sources.saveCurrentImageState()
                folderList.positionViewAtIndex(sources.selectedModelIndex, ListView.Contain)
                previewFlickable.forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Label {
                    text: "Preview"
                    font.bold: true
                }

                Rectangle {
                    id: previewViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f1f5f9"
                    radius: 6
                    clip: true

                    Flickable {
                        id: previewFlickable
                        anchors.fill: parent
                        clip: true
                        focus: false
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: Math.max(width, selectedPreview.rotatedWidth)
                        contentHeight: Math.max(height, selectedPreview.rotatedHeight)

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Plus || event.text === "+") {
                                fullview.zoomIn()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Minus || event.text === "-") {
                                fullview.zoomOut()
                                event.accepted = true
                            }
                        }

                        Image {
                            id: selectedPreview
                            visible: sources.selectedImageUrl.toString() !== ""
                            source: sources.selectedImageUrl
                            asynchronous: true
                            cache: true
                            sourceSize.width: Math.ceil(previewFlickable.width * fullview.zoomFactor)
                            fillMode: Image.PreserveAspectFit

                            readonly property real fitScale: implicitWidth > 0 && implicitHeight > 0
                                ? Math.min(
                                    previewFlickable.width / (fullview.rotationAngle % 180 === 0
                                        ? implicitWidth : implicitHeight),
                                    previewFlickable.height / (fullview.rotationAngle % 180 === 0
                                        ? implicitHeight : implicitWidth))
                                : 1
                            readonly property real rotatedWidth: fullview.rotationAngle % 180 === 0
                                ? width : height
                            readonly property real rotatedHeight: fullview.rotationAngle % 180 === 0
                                ? height : width
                            width: implicitWidth > 0
                                ? implicitWidth * fitScale * fullview.zoomFactor
                                : previewFlickable.width
                            height: implicitHeight > 0
                                ? implicitHeight * fitScale * fullview.zoomFactor
                                : previewFlickable.height
                            x: Math.max(0, (previewFlickable.contentWidth - width) / 2)
                            y: Math.max(0, (previewFlickable.contentHeight - height) / 2)
                            rotation: fullview.rotationAngle
                            transformOrigin: Item.Center

                            onStatusChanged: {
                                if (status === Image.Ready)
                                    sources.restoreCurrentImagePosition()
                            }
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                            onWheel: function(event) {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.angleDelta.y > 0 || event.pixelDelta.y > 0)
                                        fullview.zoomIn()
                                    else if (event.angleDelta.y < 0 || event.pixelDelta.y < 0)
                                        fullview.zoomOut()
                                } else {
                                    var deltaX = event.pixelDelta.x !== 0
                                        ? event.pixelDelta.x : event.angleDelta.x
                                    var deltaY = event.pixelDelta.y !== 0
                                        ? event.pixelDelta.y : event.angleDelta.y
                                    if (deltaX !== 0)
                                        previewFlickable.contentX = Math.max(
                                            0, Math.min(previewFlickable.contentWidth - previewFlickable.width,
                                                        previewFlickable.contentX - deltaX))
                                    if (deltaY !== 0)
                                        previewFlickable.contentY = Math.max(
                                            0, Math.min(previewFlickable.contentHeight - previewFlickable.height,
                                                        previewFlickable.contentY - deltaY))
                                    sources.saveCurrentImageState()
                                }
                                event.accepted = true
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        onMovementEnded: sources.saveCurrentImageState()
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Select a photo to preview!"
                        color: "#94a3b8"
                        visible: sources.selectedImageUrl.toString() === ""
                    }
                }

                ColumnLayout {
                    id: fullviewToolbar
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: "Crop"
                        }
                        Button {
                            text: "Adjust"
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Button {
                            icon.source: "remove.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.selectedImageIndex >= 0 &&
                                fullview.zoomFactor > fullview.minimumZoomFactor
                            Accessible.name: "Zoom out"
                            onClicked: fullview.zoomOut()
                        }
                        Label {
                            text: Math.round(fullview.zoomFactor * 100) + "%"
                        }
                        Button {
                            icon.source: "add.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.selectedImageIndex >= 0 &&
                                fullview.zoomFactor < fullview.maximumZoomFactor
                            Accessible.name: "Zoom in"
                            onClicked: fullview.zoomIn()
                        }
                    }

                    RowLayout {
                        id: pageNavigationLayout
                        Layout.fillWidth: true
                        spacing: 2

                        Item {
                            Layout.fillWidth: true
                        }
                        Button {
                            id: firstPageButton
                            icon.source: "first.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.foundImageCount > 0
                            Accessible.name: "First image"
                            onClicked: sources.selectImageAt(0)
                        }
                        Button {
                            id: previousPageButton
                            icon.source: "previous.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.selectedImageIndex > 0
                            Accessible.name: "Previous image"
                            onClicked: sources.selectImageAt(sources.selectedImageIndex - 1)
                        }
                        TextField {
                            id: pageNumberInput
                            Layout.preferredWidth: 48
                            Layout.minimumWidth: 40
                            text: "0"
                            horizontalAlignment: TextInput.AlignHCenter
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator {
                                bottom: 0
                                top: Math.max(1, sources.foundImageCount)
                            }
                            enabled: sources.foundImageCount > 0
                            Accessible.name: "Image number"
                            onAccepted: {
                                var requestedPage = Number(text)
                                if (requestedPage >= 1 && requestedPage <= sources.foundImageCount) {
                                    sources.selectImageAt(requestedPage - 1)
                                } else {
                                    text = sources.selectedImageIndex >= 0
                                        ? String(sources.selectedImageIndex + 1) : "0"
                                }
                                previewFlickable.forceActiveFocus()
                            }
                        }
                        Label {
                            text: "/ " + sources.foundImageCount
                            color: "#64748b"
                        }
                        Button {
                            id: nextPageButton
                            icon.source: "next.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.foundImageCount > 0 &&
                                sources.selectedImageIndex < sources.foundImageCount - 1
                            Accessible.name: "Next image"
                            onClicked: sources.selectImageAt(
                                sources.selectedImageIndex < 0 ? 0 : sources.selectedImageIndex + 1)
                        }
                        Button {
                            id: lastPageButton
                            icon.source: "last.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.foundImageCount > 0
                            Accessible.name: "Last image"
                            onClicked: sources.selectImageAt(sources.foundImageCount - 1)
                        }
                        Button {
                            id: rotatePageButton
                            icon.source: "rotate.svg"
                            icon.width: 18
                            icon.height: 18
                            icon.color: "#2E39B3"
                            Layout.minimumWidth: 32
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 4
                            enabled: sources.selectedImageIndex >= 0
                            Accessible.name: "Rotate image"
                            onClicked: fullview.rotateSelectedImage()
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
        // Selected photos
        Rectangle {
            SplitView.preferredWidth: 180
            SplitView.minimumWidth: 110
            SplitView.maximumWidth: 350

            color: "white"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label {
                    text: "Selected photos"
                    font.bold: true
                }

                Label {
                    text: "0 photos"
                    color: "#64748b"
                    font.pixelSize: 12
                }

                ListView {
                    id: selectedList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: 0

                    delegate: Rectangle {
                        width: selectedList.width
                        height: width * 0.75
                        color: "#e2e8f0"
                        radius: 4
                    }
                }
            }
        }

        // Current folder
        Rectangle {
            SplitView.preferredWidth: 240
            SplitView.minimumWidth: 120
            SplitView.maximumWidth: 450

            color: "white"
            radius: 8
            id: sources
            readonly property int minimumPreviewHeight: 96
            property int foundImageCount: 0
            property bool showingThisPc: false
            property url selectedImageUrl: ""
            property int selectedImageIndex: -1
            property int selectedModelIndex: -1
            property string selectedImageHash: ""
            property int selectedImageStateIndex: -1

            function updateFoundImageCount() {
                var count = 0
                for (var i = 0; i < folderModel.count; ++i) {
                    if (!folderModel.isFolder(i))
                        ++count
                }
                foundImageCount = count
            }

            function imageStateIndexFor(path, hash) {
                for (var i = 0; i < imageStateCache.count; ++i) {
                    var state = imageStateCache.get(i)
                    if (state.path !== path)
                        continue

                    if (state.hash !== hash) {
                        imageStateCache.setProperty(i, "hash", hash)
                        imageStateCache.setProperty(i, "rotation", 0)
                        imageStateCache.setProperty(i, "zoomFactor", 1)
                        imageStateCache.setProperty(i, "scrollX", 0)
                        imageStateCache.setProperty(i, "scrollY", 0)
                    }
                    return i
                }

                imageStateCache.append({
                    path: path,
                    hash: hash,
                    rotation: 0,
                    zoomFactor: 1,
                    scrollX: 0,
                    scrollY: 0
                })
                return imageStateCache.count - 1
            }

            function rotationForImage(path, hash) {
                for (var i = 0; i < imageStateCache.count; ++i) {
                    var state = imageStateCache.get(i)
                    if (state.path === path && state.hash === hash)
                        return state.rotation
                }
                return 0
            }

            function saveCurrentImageState() {
                if (selectedImageStateIndex < 0)
                    return

                var state = imageStateCache.get(selectedImageStateIndex)
                if (state.path !== selectedImageUrl.toString() || state.hash !== selectedImageHash)
                    return

                imageStateCache.setProperty(selectedImageStateIndex, "rotation", fullview.rotationAngle)
                imageStateCache.setProperty(selectedImageStateIndex, "zoomFactor", fullview.zoomFactor)
                imageStateCache.setProperty(selectedImageStateIndex, "scrollX", previewFlickable.contentX)
                imageStateCache.setProperty(selectedImageStateIndex, "scrollY", previewFlickable.contentY)
            }

            function restoreCurrentImagePosition() {
                if (selectedImageStateIndex < 0 || selectedPreview.status !== Image.Ready)
                    return

                var state = imageStateCache.get(selectedImageStateIndex)
                previewFlickable.contentX = Math.max(
                    0, Math.min(state.scrollX, previewFlickable.contentWidth - previewFlickable.width))
                previewFlickable.contentY = Math.max(
                    0, Math.min(state.scrollY, previewFlickable.contentHeight - previewFlickable.height))
            }

            function selectImageAt(imageIndex) {
                if (imageIndex < 0 || imageIndex >= foundImageCount)
                    return

                var currentImageIndex = 0
                for (var modelIndex = 0; modelIndex < folderModel.count; ++modelIndex) {
                    if (folderModel.isFolder(modelIndex))
                        continue
                    if (currentImageIndex === imageIndex) {
                        selectImageByModelIndex(modelIndex)
                        return
                    }
                    ++currentImageIndex
                }
            }

            function selectImageByModelIndex(modelIndex) {
                if (modelIndex < 0 || modelIndex >= folderModel.count ||
                    folderModel.isFolder(modelIndex))
                    return

                saveCurrentImageState()

                var imageIndex = 0
                for (var i = 0; i < modelIndex; ++i) {
                    if (!folderModel.isFolder(i))
                        ++imageIndex
                }

                selectedImageIndex = imageIndex
                selectedModelIndex = modelIndex
                selectedImageUrl = folderModel.get(modelIndex, "fileURL")
                selectedImageHash = fileSystemNavigator.imageStateHash(selectedImageUrl)
                selectedImageStateIndex = imageStateIndexFor(
                    selectedImageUrl.toString(), selectedImageHash)
                var state = imageStateCache.get(selectedImageStateIndex)
                fullview.rotationAngle = state.rotation
                fullview.zoomFactor = state.zoomFactor
                pageNumberInput.text = String(imageIndex + 1)
                previewFlickable.contentX = 0
                previewFlickable.contentY = 0
                folderList.positionViewAtIndex(modelIndex, ListView.Contain)
                previewFlickable.forceActiveFocus()
                Qt.callLater(restoreCurrentImagePosition)
            }

            function showThisPc() {
                saveCurrentImageState()
                thisPcModel.clear()
                var drives = fileSystemNavigator.availableWindowsDrives()
                for (var i = 0; i < drives.length; ++i)
                    thisPcModel.append(drives[i])
                showingThisPc = true
                selectedImageUrl = ""
                selectedImageIndex = -1
                selectedModelIndex = -1
                selectedImageHash = ""
                selectedImageStateIndex = -1
                pageNumberInput.text = "0"
                fullview.rotationAngle = 0
                fullview.zoomFactor = 1
                foundImageCount = 0
            }

            function isWindowsDriveRoot() {
                return Qt.platform.os === "windows" &&
                    /^file:\/\/\/[a-zA-Z]:\/?$/.test(folderModel.folder.toString())
            }

            FileSystemNavigator {
                id: fileSystemNavigator
            }

            FolderListModel {
                id: folderModel
                folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                nameFilters: ["*.jpg", "*.jpeg", "*.png"]
                showDirs: true
                showFiles: true
                showDirsFirst: true
                showDotAndDotDot: false
                showOnlyReadable: true
                caseSensitive: false
                sortField: FolderListModel.Name
            }

            ListModel {
                id: thisPcModel
            }

            ListModel {
                id: imageStateCache
            }

            Connections {
                target: folderModel

                function onCountChanged() {
                    sources.updateFoundImageCount()
                }

                function onStatusChanged() {
                    if (folderModel.status === FolderListModel.Ready)
                        sources.updateFoundImageCount()
                }

                function onDataChanged() {
                    sources.updateFoundImageCount()
                }

                function onFolderChanged() {
                    sources.saveCurrentImageState()
                    sources.selectedImageUrl = ""
                    sources.selectedImageIndex = -1
                    sources.selectedModelIndex = -1
                    sources.selectedImageHash = ""
                    sources.selectedImageStateIndex = -1
                    pageNumberInput.text = "0"
                    fullview.rotationAngle = 0
                    fullview.zoomFactor = 1
                    previewFlickable.contentX = 0
                    previewFlickable.contentY = 0
                }
            }

            Component.onCompleted: {
                if (sources.showingThisPc)
                    sources.showThisPc()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: sources.showingThisPc ? "This PC" : "Current folder"
                        font.bold: true
                        Layout.minimumWidth: 0
                        elide: Text.ElideRight
                    }

                    Button {
                        icon.source: "folder-up.svg"
                        icon.width: 24
                        icon.height: 24
                        icon.color: "#64748b"
                        Layout.minimumWidth: 36
                        Layout.preferredWidth: 36
                        visible: !sources.showingThisPc &&
                            (sources.isWindowsDriveRoot() ||
                             folderModel.parentFolder.toString() !== folderModel.folder.toString())
                        Accessible.name: "Go to parent folder"
                        ToolTip.text: Accessible.name
                        ToolTip.visible: hovered
                        onClicked: {
                            if (sources.isWindowsDriveRoot())
                                sources.showThisPc()
                            else
                                folderModel.folder = folderModel.parentFolder
                        }
                    }

                    Label {
                        text: sources.foundImageCount + " images"
                        color: "#64748b"
                        font.pixelSize: 11
                        visible: !sources.showingThisPc
                    }

                }

                Label {
                    text: folderModel.folder.toString()
                    color: "#64748b"
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    visible: !sources.showingThisPc
                }

                ListView {
                    id: folderList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    cacheBuffer: height
                    model: sources.showingThisPc ? thisPcModel : folderModel
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: fileItem
                        required property int index
                        required property string fileName
                        required property var fileURL

                        width: folderList.width
                        readonly property string imagePath: fileItem.fileURL.toString()
                        readonly property string imageHash: sources.showingThisPc ||
                            folderModel.isFolder(fileItem.index) ? "" :
                            fileSystemNavigator.imageStateHash(fileItem.fileURL)
                        readonly property bool isSelectedImage: !sources.showingThisPc &&
                            !folderModel.isFolder(index) &&
                            fileItem.imagePath === sources.selectedImageUrl.toString()
                        readonly property int cachedRotation: isSelectedImage
                            ? fullview.rotationAngle
                            : sources.rotationForImage(fileItem.imagePath, fileItem.imageHash)
                        readonly property bool isRotated: cachedRotation % 180 !== 0
                        readonly property real previewHeight: Math.max(
                            sources.minimumPreviewHeight,
                            thumbnail.implicitWidth > 0
                                ? (width - 4) * (isRotated
                                    ? thumbnail.implicitWidth / thumbnail.implicitHeight
                                    : thumbnail.implicitHeight / thumbnail.implicitWidth)
                                : sources.minimumPreviewHeight)
                        height: sources.showingThisPc ? 48
                            : folderModel.isFolder(index) ? 48 : previewHeight + 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            border.width: fileItem.isSelectedImage ? 2 : 0
                            border.color: "#1976d2"
                            color: sources.showingThisPc || folderModel.isFolder(fileItem.index)
                                ? "#f1f5f9" : "#e2e8f0"

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 4

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: fileItem.previewHeight
                                    visible: !sources.showingThisPc && !folderModel.isFolder(fileItem.index)

                                    Image {
                                        id: thumbnail
                                        width: fileItem.isRotated ? parent.height - 4 : parent.width - 4
                                        height: fileItem.isRotated ? parent.width - 4 : parent.height - 4
                                        x: (parent.width - width) / 2
                                        y: (parent.height - height) / 2
                                        source: sources.showingThisPc ? "" : fileItem.fileURL
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: width
                                        fillMode: Image.PreserveAspectFit
                                        rotation: fileItem.cachedRotation
                                        transformOrigin: Item.Center
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 6
                                    Layout.rightMargin: 6
                                    Layout.bottomMargin: 4
                                    Layout.preferredHeight: sources.showingThisPc ||
                                        folderModel.isFolder(fileItem.index) ? 48 : implicitHeight
                                    verticalAlignment: Text.AlignVCenter
                                    text: sources.showingThisPc || folderModel.isFolder(fileItem.index)
                                        ? "\uD83D\uDCC1  " + fileItem.fileName : fileItem.fileName
                                    elide: Text.ElideMiddle
                                    color: "#334155"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (sources.showingThisPc) {
                                    sources.showingThisPc = false
                                    folderModel.folder = fileItem.fileURL
                                } else if (folderModel.isFolder(fileItem.index)) {
                                    folderModel.folder = fileItem.fileURL
                                } else {
                                    sources.selectImageByModelIndex(fileItem.index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
