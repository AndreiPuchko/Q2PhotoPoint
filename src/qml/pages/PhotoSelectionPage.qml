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
            id: fullview
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300

            color: "white"
            radius: 8
            property real zoomFactor: 1
            readonly property real minimumZoomFactor: 1
            readonly property real maximumZoomFactor: 8
            readonly property real zoomStep: 1.25
            property int rotationAngle: 0
            property url currentImageUrl: ""
            property string currentImageHash: ""
            property int currentImageStateIndex: -1

            function zoomIn() {
                if (currentImageStateIndex < 0)
                    return;
                zoomFactor = Math.min(maximumZoomFactor, zoomFactor * zoomStep);
                sources.saveCurrentImageState();
                previewFlickable.forceActiveFocus();
            }

            function zoomOut() {
                if (currentImageStateIndex < 0)
                    return;
                zoomFactor = Math.max(minimumZoomFactor, zoomFactor / zoomStep);
                sources.saveCurrentImageState();
                previewFlickable.forceActiveFocus();
            }

            function rotateSelectedImage(keepSourceFocus) {
                if (currentImageStateIndex < 0)
                    return;
                rotationAngle = (rotationAngle + 90) % 360;
                previewFlickable.contentX = 0;
                previewFlickable.contentY = 0;
                sources.saveCurrentImageState();
                if (keepSourceFocus) {
                    if (result.navigationActive)
                        selectedList.forceActiveFocus();
                    else
                        folderList.forceActiveFocus();
                } else {
                    previewFlickable.forceActiveFocus();
                }
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

                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Plus || event.text === "+") {
                                fullview.zoomIn();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Minus || event.text === "-") {
                                fullview.zoomOut();
                                event.accepted = true;
                            }
                        }
                        Image {
                            id: selectedPreview
                            visible: fullview.currentImageUrl.toString() !== ""
                            source: fullview.currentImageUrl
                            asynchronous: true
                            cache: true
                            sourceSize.width: Math.ceil(previewFlickable.width * fullview.zoomFactor)
                            fillMode: Image.PreserveAspectFit

                            readonly property real fitScale: implicitWidth > 0 && implicitHeight > 0 ? Math.min(previewFlickable.width / (fullview.rotationAngle % 180 === 0 ? implicitWidth : implicitHeight), previewFlickable.height / (fullview.rotationAngle % 180 === 0 ? implicitHeight : implicitWidth)) : 1
                            readonly property real rotatedWidth: fullview.rotationAngle % 180 === 0 ? width : height
                            readonly property real rotatedHeight: fullview.rotationAngle % 180 === 0 ? height : width
                            width: implicitWidth > 0 ? implicitWidth * fitScale * fullview.zoomFactor : previewFlickable.width
                            height: implicitHeight > 0 ? implicitHeight * fitScale * fullview.zoomFactor : previewFlickable.height
                            x: Math.max(0, (previewFlickable.contentWidth - width) / 2)
                            y: Math.max(0, (previewFlickable.contentHeight - height) / 2)
                            rotation: fullview.rotationAngle
                            transformOrigin: Item.Center

                            onStatusChanged: {
                                if (status === Image.Ready)
                                    sources.restoreCurrentImagePosition();
                            }
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                            onWheel: function (event) {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.angleDelta.y > 0 || event.pixelDelta.y > 0)
                                        fullview.zoomIn();
                                    else if (event.angleDelta.y < 0 || event.pixelDelta.y < 0)
                                        fullview.zoomOut();
                                } else {
                                    if (event.angleDelta.y < 0)
                                        sources.navigateCurrentBy(1);
                                    else if (event.angleDelta.y > 0)
                                        sources.navigateCurrentBy(-1);
                                }
                                event.accepted = true;
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
                        visible: fullview.currentImageUrl.toString() === ""
                    }
                }

                RowLayout {
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
                            enabled: fullview.currentImageStateIndex >= 0 && fullview.zoomFactor > fullview.minimumZoomFactor
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
                            enabled: fullview.currentImageStateIndex >= 0 && fullview.zoomFactor < fullview.maximumZoomFactor
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
                            enabled: sources.navigationCount > 0
                            Accessible.name: "First image"
                            onClicked: sources.navigateCurrentTo(0)
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
                            enabled: sources.navigationIndex > 0
                            Accessible.name: "Previous image"
                            onClicked: sources.navigateCurrentTo(sources.navigationIndex - 1)
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
                                top: Math.max(1, sources.navigationCount)
                            }
                            enabled: sources.navigationCount > 0
                            Accessible.name: "Image number"
                            onAccepted: {
                                var requestedPage = Number(text);
                                if (requestedPage >= 1 && requestedPage <= sources.navigationCount) {
                                    sources.navigateCurrentTo(requestedPage - 1);
                                } else {
                                    text = sources.navigationIndex >= 0 ? String(sources.navigationIndex + 1) : "0";
                                }
                                previewFlickable.forceActiveFocus();
                            }
                        }
                        Label {
                            text: "/ " + sources.navigationCount
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
                            enabled: sources.navigationCount > 0 && sources.navigationIndex < sources.navigationCount - 1
                            Accessible.name: "Next image"
                            onClicked: sources.navigateCurrentTo(sources.navigationIndex < 0 ? 0 : sources.navigationIndex + 1)
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
                            enabled: sources.navigationCount > 0
                            Accessible.name: "Last image"
                            onClicked: sources.navigateCurrentTo(sources.navigationCount - 1)
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
                            enabled: fullview.currentImageStateIndex >= 0
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
            id: result
            SplitView.preferredWidth: 180
            SplitView.minimumWidth: 110
            SplitView.maximumWidth: 350

            color: "white"
            radius: 8
            property bool navigationActive: false
            property int selectedPhotoIndex: -1

            function photoIndex(path, hash) {
                for (var i = 0; i < selectedPhotos.count; ++i) {
                    var photo = selectedPhotos.get(i);
                    if (photo.path === path && photo.hash === hash)
                        return i;
                }
                return -1;
            }

            function selectPhotoAt(index, focusResult) {
                if (index < 0 || index >= selectedPhotos.count)
                    return;

                selectedPhotoIndex = index;
                selectedList.currentIndex = index;
                var photo = selectedPhotos.get(index);
                sources.syncSourceSelection(photo.fileURL);
                sources.showImageInPreview(photo.fileURL, photo.hash);
                pageNumberInput.text = String(index + 1);
                if (focusResult !== false) {
                    navigationActive = true;
                    selectedList.forceActiveFocus();
                }
            }

            function addPhoto(fileURL, fileName, hash, insertionIndex, focusResult) {
                var path = String(fileURL);
                if (!hash)
                    hash = fileSystemNavigator.imageStateHash(fileURL);
                sources.imageStateIndexFor(path, hash);

                var existingIndex = photoIndex(path, hash);
                if (existingIndex >= 0) {
                    var targetIndex = insertionIndex === undefined ? existingIndex : movePhoto(existingIndex, insertionIndex);
                    selectPhotoAt(targetIndex, focusResult);
                    return;
                }

                var targetIndex = insertionIndex === undefined ? selectedPhotos.count : Math.max(0, Math.min(selectedPhotos.count, insertionIndex));
                selectedPhotos.insert(targetIndex, {
                    path: path,
                    hash: hash,
                    fileName: fileName,
                    fileURL: path
                });
                selectPhotoAt(targetIndex, focusResult);
            }

            function movePhoto(fromIndex, insertionIndex) {
                if (fromIndex < 0 || fromIndex >= selectedPhotos.count)
                    return;

                var targetIndex = Math.max(0, Math.min(selectedPhotos.count, insertionIndex));
                if (targetIndex > fromIndex)
                    --targetIndex;
                if (targetIndex === fromIndex) {
                    selectPhotoAt(fromIndex, false);
                    return fromIndex;
                }

                selectedPhotos.move(fromIndex, targetIndex, 1);
                selectPhotoAt(targetIndex, false);
                return targetIndex;
            }

            function movePhotoToIndex(fromIndex, targetIndex) {
                if (fromIndex < 0 || fromIndex >= selectedPhotos.count)
                    return;

                targetIndex = Math.max(0, Math.min(selectedPhotos.count - 1, targetIndex));
                if (targetIndex === fromIndex) {
                    selectPhotoAt(fromIndex, false);
                    return;
                }

                selectedPhotos.move(fromIndex, targetIndex, 1);
                selectPhotoAt(targetIndex, false);
            }

            function rowIndexAt(y) {
                if (selectedPhotos.count === 0)
                    return -1;

                var rowHeight = (selectedList.width - resultVbar.width) * 0.75;
                var stride = rowHeight + selectedList.spacing;
                var index = stride > 0 ? Math.floor((selectedList.contentY + y) / stride) : 0;
                return Math.max(0, Math.min(selectedPhotos.count - 1, index));
            }

            function insertionIndexAt(y) {
                var rowIndex = rowIndexAt(y);
                if (rowIndex < 0)
                    return 0;

                var rowHeight = (selectedList.width - resultVbar.width) * 0.75;
                var stride = rowHeight + selectedList.spacing;
                var rowOffset = selectedList.contentY + y - rowIndex * stride;
                return rowIndex + (rowOffset > rowHeight / 2 ? 1 : 0);
            }

            ListModel {
                id: selectedPhotos
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label {
                    text: "Selected photos"
                    font.bold: true
                }

                Label {
                    text: selectedPhotos.count + " photos"
                    color: "#64748b"
                    font.pixelSize: 12
                }

                Item {
                    id: selectedListViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    DropArea {
                        id: resultDragArea
                        anchors.fill: parent
                        z: 2
                        keys: ["application/x-q2photopoint-origin", "q2photopoint-photo"]

                        onEntered: function (drag) {
                            var origin = drag.getDataAsString("application/x-q2photopoint-origin");
                            if (origin === "result" && drag.supportedActions & Qt.MoveAction)
                                drag.accept(Qt.MoveAction);
                            else if (origin === "source" && drag.supportedActions & Qt.CopyAction)
                                drag.accept(Qt.CopyAction);
                            else
                                drag.accepted = false;
                        }

                        onDropped: function (drop) {
                            var origin = drop.getDataAsString("application/x-q2photopoint-origin");
                            if (origin === "result") {
                                result.navigationActive = true;
                                var fromIndex = Number(drop.getDataAsString("application/x-q2photopoint-index"));
                                result.movePhotoToIndex(fromIndex, result.rowIndexAt(drop.y));
                            } else if (origin === "source") {
                                result.addPhoto(drop.getDataAsString("application/x-q2photopoint-path"), drop.getDataAsString("application/x-q2photopoint-name"), drop.getDataAsString("application/x-q2photopoint-hash"), result.insertionIndexAt(drop.y), true);
                            }
                            drop.acceptProposedAction();
                        }
                    }

                    ListView {
                        id: selectedList
                        anchors.fill: parent
                        z: 1
                        clip: true
                        spacing: 8
                        model: selectedPhotos
                        currentIndex: -1
                        activeFocusOnTab: true

                        function moveCurrentIndexBy(delta) {
                            if (count === 0)
                                return;
                            currentIndex = Math.max(0, Math.min(count - 1, currentIndex < 0 ? 0 : currentIndex + delta));
                            positionViewAtIndex(currentIndex, ListView.Contain);
                            result.selectPhotoAt(currentIndex, false);
                        }

                        Keys.onPressed: function (event) {
                            var handled = true;
                            switch (event.key) {
                            case Qt.Key_Up:
                                selectedList.moveCurrentIndexBy(-1);
                                break;
                            case Qt.Key_Down:
                                selectedList.moveCurrentIndexBy(1);
                                break;
                            case Qt.Key_PageUp:
                                selectedList.moveCurrentIndexBy(-Math.max(1, Math.floor(height / 120)));
                                break;
                            case Qt.Key_PageDown:
                                selectedList.moveCurrentIndexBy(Math.max(1, Math.floor(height / 120)));
                                break;
                            case Qt.Key_Home:
                                selectedList.currentIndex = 0;
                                result.selectPhotoAt(0, false);
                                break;
                            case Qt.Key_End:
                                selectedList.currentIndex = selectedList.count - 1;
                                result.selectPhotoAt(selectedList.currentIndex, false);
                                break;
                            case Qt.Key_Right:
                                fullview.rotateSelectedImage(true);
                                break;
                            default:
                                handled = false;
                            }
                            if (handled)
                                event.accepted = true;
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                result.navigationActive = true;
                                if (currentIndex >= 0)
                                    result.selectPhotoAt(currentIndex, false);
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: resultVbar
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Item {
                            id: resultDropTarget
                            required property int index
                            required property string path
                            required property string hash
                            required property string fileName
                            required property string fileURL

                            width: selectedList.width - resultVbar.width
                            height: width * 0.75

                            Item {
                                id: resultPhoto
                                x: 0
                                y: 0
                                width: parent.width
                                height: parent.height

                                Drag.active: resultMouseArea.drag.active
                                Drag.dragType: Drag.Automatic
                                Drag.keys: ["q2photopoint-photo"]
                                Drag.supportedActions: Qt.MoveAction
                                Drag.mimeData: ({
                                        "application/x-q2photopoint-origin": "result",
                                        "application/x-q2photopoint-path": resultDropTarget.path,
                                        "application/x-q2photopoint-name": resultDropTarget.fileName,
                                        "application/x-q2photopoint-hash": resultDropTarget.hash,
                                        "application/x-q2photopoint-index": String(resultDropTarget.index)
                                    })

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 4
                                    clip: true
                                    color: "#e2e8f0"
                                    border.width: selectedList.currentIndex === resultDropTarget.index ? 2 : 0
                                    border.color: "#1976d2"

                                    Image {
                                        id: resultThumbnail
                                        property int cachedRotation: sources.rotationForImage(resultDropTarget.path, resultDropTarget.hash)
                                        width: cachedRotation % 180 === 0 ? parent.width - 4 : parent.height - 4
                                        height: cachedRotation % 180 === 0 ? parent.height - 4 : parent.width - 4
                                        x: (parent.width - width) / 2
                                        y: (parent.height - height) / 2
                                        source: resultDropTarget.fileURL
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: width
                                        fillMode: Image.PreserveAspectFit
                                        rotation: cachedRotation
                                        transformOrigin: Item.Center
                                    }
                                }

                                MouseArea {
                                    id: resultMouseArea
                                    anchors.fill: parent
                                    drag.target: resultPhoto
                                    drag.axis: Drag.YAxis

                                    onClicked: {
                                        selectedList.currentIndex = resultDropTarget.index;
                                        result.selectPhotoAt(resultDropTarget.index, true);
                                    }
                                    onReleased: {
                                        resultPhoto.x = 0;
                                        resultPhoto.y = 0;
                                    }
                                    onCanceled: {
                                        resultPhoto.x = 0;
                                        resultPhoto.y = 0;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Current folder
        Rectangle {
            id: sources
            SplitView.preferredWidth: 240
            SplitView.minimumWidth: 120
            SplitView.maximumWidth: 450

            color: "white"
            radius: 8
            readonly property int minimumPreviewHeight: 96
            property int foundImageCount: 0
            property bool showingThisPc: false
            property url selectedImageUrl: ""
            property int selectedImageIndex: -1
            property int selectedModelIndex: -1
            readonly property int navigationCount: result.navigationActive ? selectedPhotos.count : foundImageCount
            readonly property int navigationIndex: result.navigationActive ? result.selectedPhotoIndex : selectedImageIndex

            function updateFoundImageCount() {
                var count = 0;
                for (var i = 0; i < folderModel.count; ++i) {
                    if (!folderModel.isFolder(i))
                        ++count;
                }
                foundImageCount = count;
            }

            function imageStateIndexFor(path, hash) {
                for (var i = 0; i < imageStateCache.count; ++i) {
                    var state = imageStateCache.get(i);
                    if (state.path !== path)
                        continue;
                    if (state.hash !== hash) {
                        imageStateCache.setProperty(i, "hash", hash);
                        imageStateCache.setProperty(i, "rotation", 0);
                        imageStateCache.setProperty(i, "zoomFactor", 1);
                        imageStateCache.setProperty(i, "scrollX", 0);
                        imageStateCache.setProperty(i, "scrollY", 0);
                    }
                    return i;
                }

                imageStateCache.append({
                    path: path,
                    hash: hash,
                    rotation: 0,
                    zoomFactor: 1,
                    scrollX: 0,
                    scrollY: 0
                });
                return imageStateCache.count - 1;
            }

            function rotationForImage(path, hash) {
                for (var i = 0; i < imageStateCache.count; ++i) {
                    var state = imageStateCache.get(i);
                    if (state.path === path && state.hash === hash)
                        return state.rotation;
                }
                return 0;
            }

            function showImageInPreview(fileURL, hash) {
                saveCurrentImageState();
                var path = String(fileURL);
                var imageHash = hash || fileSystemNavigator.imageStateHash(fileURL);
                var stateIndex = imageStateIndexFor(path, imageHash);
                var state = imageStateCache.get(stateIndex);
                fullview.currentImageUrl = fileURL;
                fullview.currentImageHash = imageHash;
                fullview.currentImageStateIndex = stateIndex;
                fullview.rotationAngle = state.rotation;
                fullview.zoomFactor = state.zoomFactor;
                previewFlickable.contentX = 0;
                previewFlickable.contentY = 0;
                Qt.callLater(restoreCurrentImagePosition);
            }

            function saveCurrentImageState() {
                if (fullview.currentImageStateIndex < 0)
                    return;
                var state = imageStateCache.get(fullview.currentImageStateIndex);
                if (state.path !== fullview.currentImageUrl.toString() || state.hash !== fullview.currentImageHash)
                    return;
                imageStateCache.setProperty(fullview.currentImageStateIndex, "rotation", fullview.rotationAngle);
                imageStateCache.setProperty(fullview.currentImageStateIndex, "zoomFactor", fullview.zoomFactor);
                imageStateCache.setProperty(fullview.currentImageStateIndex, "scrollX", previewFlickable.contentX);
                imageStateCache.setProperty(fullview.currentImageStateIndex, "scrollY", previewFlickable.contentY);
            }

            function restoreCurrentImagePosition() {
                if (fullview.currentImageStateIndex < 0 || selectedPreview.status !== Image.Ready)
                    return;
                var state = imageStateCache.get(fullview.currentImageStateIndex);
                previewFlickable.contentX = Math.max(0, Math.min(state.scrollX, previewFlickable.contentWidth - previewFlickable.width));
                previewFlickable.contentY = Math.max(0, Math.min(state.scrollY, previewFlickable.contentHeight - previewFlickable.height));
            }

            function syncSourceSelection(fileURL) {
                var path = String(fileURL);
                var imageIndex = 0;
                for (var modelIndex = 0; modelIndex < folderModel.count; ++modelIndex) {
                    if (folderModel.isFolder(modelIndex))
                        continue;
                    if (folderModel.get(modelIndex, "fileURL").toString() === path) {
                        selectedImageUrl = fileURL;
                        selectedImageIndex = imageIndex;
                        selectedModelIndex = modelIndex;
                        folderList.currentIndex = modelIndex;
                        folderList.positionViewAtIndex(modelIndex, ListView.Contain);
                        return;
                    }
                    ++imageIndex;
                }
                selectedImageUrl = "";
                selectedImageIndex = -1;
                selectedModelIndex = -1;
            }

            function navigateCurrentTo(index) {
                if (result.navigationActive)
                    result.selectPhotoAt(index, false);
                else
                    selectImageAt(index);
            }

            function navigateCurrentBy(delta) {
                var index = navigationIndex < 0 ? 0 : navigationIndex + delta;
                navigateCurrentTo(index);
            }

            function selectImageAt(imageIndex, focusPreview) {
                if (imageIndex < 0 || imageIndex >= foundImageCount)
                    return;
                var currentImageIndex = 0;
                for (var modelIndex = 0; modelIndex < folderModel.count; ++modelIndex) {
                    if (folderModel.isFolder(modelIndex))
                        continue;
                    if (currentImageIndex === imageIndex) {
                        selectImageByModelIndex(modelIndex, focusPreview);
                        return;
                    }
                    ++currentImageIndex;
                }
            }

            function selectImageByModelIndex(modelIndex, focusPreview) {
                if (modelIndex < 0 || modelIndex >= folderModel.count || folderModel.isFolder(modelIndex))
                    return;
                saveCurrentImageState();

                var imageIndex = 0;
                for (var i = 0; i < modelIndex; ++i) {
                    if (!folderModel.isFolder(i))
                        ++imageIndex;
                }

                selectedImageIndex = imageIndex;
                selectedModelIndex = modelIndex;
                selectedImageUrl = folderModel.get(modelIndex, "fileURL");
                showImageInPreview(selectedImageUrl);
                pageNumberInput.text = String(imageIndex + 1);
                folderList.positionViewAtIndex(modelIndex, ListView.Contain);
                if (focusPreview !== false)
                    previewFlickable.forceActiveFocus();
                Qt.callLater(restoreCurrentImagePosition);
            }

            function showThisPc() {
                saveCurrentImageState();
                thisPcModel.clear();
                var drives = fileSystemNavigator.availableWindowsDrives();
                for (var i = 0; i < drives.length; ++i)
                    thisPcModel.append(drives[i]);
                showingThisPc = true;
                selectedImageUrl = "";
                selectedImageIndex = -1;
                selectedModelIndex = -1;
                fullview.currentImageUrl = "";
                fullview.currentImageHash = "";
                fullview.currentImageStateIndex = -1;
                pageNumberInput.text = "0";
                fullview.rotationAngle = 0;
                fullview.zoomFactor = 1;
                foundImageCount = 0;
                folderList.currentIndex = thisPcModel.count > 0 ? 0 : -1;
            }

            function isWindowsDriveRoot() {
                return Qt.platform.os === "windows" && /^file:\/\/\/[a-zA-Z]:\/?$/.test(folderModel.folder.toString());
            }

            function goToParentFolder() {
                if (showingThisPc)
                    return;
                if (isWindowsDriveRoot())
                    showThisPc();
                else if (folderModel.parentFolder.toString() !== folderModel.folder.toString())
                    folderModel.folder = folderModel.parentFolder;
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
                    sources.updateFoundImageCount();
                }

                function onStatusChanged() {
                    if (folderModel.status === FolderListModel.Ready) {
                        sources.updateFoundImageCount();
                        if (folderList.activeFocus && folderList.currentIndex < 0 && folderModel.count > 0)
                            folderList.currentIndex = 0;
                        if (!sources.showingThisPc && sources.selectedImageIndex < 0 && sources.foundImageCount > 0)
                            sources.selectImageAt(0, false);
                    }
                }

                function onDataChanged() {
                    sources.updateFoundImageCount();
                }

                function onFolderChanged() {
                    sources.saveCurrentImageState();
                    sources.selectedImageUrl = "";
                    sources.selectedImageIndex = -1;
                    sources.selectedModelIndex = -1;
                    fullview.currentImageUrl = "";
                    fullview.currentImageHash = "";
                    fullview.currentImageStateIndex = -1;
                    folderList.currentIndex = -1;
                    pageNumberInput.text = "0";
                    fullview.rotationAngle = 0;
                    fullview.zoomFactor = 1;
                    previewFlickable.contentX = 0;
                    previewFlickable.contentY = 0;
                    sources.updateFoundImageCount();
                    if (folderModel.status === FolderListModel.Ready)
                        sources.selectImageAt(0, false);
                }
            }

            Component.onCompleted: {
                if (sources.showingThisPc)
                    sources.showThisPc();
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
                        visible: !sources.showingThisPc && (sources.isWindowsDriveRoot() || folderModel.parentFolder.toString() !== folderModel.folder.toString())
                        Accessible.name: "Go to parent folder"
                        ToolTip.text: Accessible.name
                        ToolTip.visible: hovered
                        onClicked: sources.goToParentFolder()
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
                    currentIndex: -1
                    activeFocusOnTab: true

                    function moveCurrentIndexTo(index) {
                        if (count === 0)
                            return;

                        var nextIndex = Math.max(0, Math.min(count - 1, index));
                        currentIndex = nextIndex;
                        positionViewAtIndex(nextIndex, ListView.Contain);
                        if (!sources.showingThisPc && !folderModel.isFolder(nextIndex))
                            sources.selectImageByModelIndex(nextIndex, false);
                    }

                    function moveCurrentIndexBy(delta) {
                        moveCurrentIndexTo(currentIndex < 0 ? 0 : currentIndex + delta);
                    }

                    function visiblePageStep() {
                        var firstVisible = indexAt(1, 1);
                        var lastVisible = indexAt(1, Math.max(1, height - 1));
                        return firstVisible >= 0 && lastVisible > firstVisible ? lastVisible - firstVisible : Math.max(1, Math.floor(height / 96));
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            result.navigationActive = false;
                            if (!sources.showingThisPc && currentIndex >= 0 && !folderModel.isFolder(currentIndex))
                                sources.selectImageByModelIndex(currentIndex, false);
                        }
                    }

                    Keys.onPressed: function (event) {
                        var handled = true;
                        switch (event.key) {
                        case Qt.Key_Up:
                            folderList.moveCurrentIndexBy(-1);
                            break;
                        case Qt.Key_Down:
                            folderList.moveCurrentIndexBy(1);
                            break;
                        case Qt.Key_PageUp:
                            folderList.moveCurrentIndexBy(-folderList.visiblePageStep());
                            break;
                        case Qt.Key_PageDown:
                            folderList.moveCurrentIndexBy(folderList.visiblePageStep());
                            break;
                        case Qt.Key_Home:
                            folderList.moveCurrentIndexTo(0);
                            break;
                        case Qt.Key_End:
                            folderList.moveCurrentIndexTo(folderList.count - 1);
                            break;
                        case Qt.Key_Right:
                            if (!sources.showingThisPc && folderList.currentIndex >= 0 && !folderModel.isFolder(folderList.currentIndex)) {
                                sources.selectImageByModelIndex(folderList.currentIndex, false);
                                fullview.rotateSelectedImage(true);
                            }
                            break;
                        case Qt.Key_Slash:
                            sources.goToParentFolder();
                            folderList.forceActiveFocus();
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (folderList.currentIndex >= 0) {
                                if (sources.showingThisPc) {
                                    var drive = thisPcModel.get(folderList.currentIndex);
                                    sources.showingThisPc = false;
                                    folderModel.folder = drive.fileURL;
                                } else if (folderModel.isFolder(folderList.currentIndex)) {
                                    folderModel.folder = folderModel.get(folderList.currentIndex, "fileURL");
                                } else {
                                    var imageURL = folderModel.get(folderList.currentIndex, "fileURL");
                                    var imageName = folderModel.get(folderList.currentIndex, "fileName");
                                    var imageHash = fileSystemNavigator.imageStateHash(imageURL);
                                    result.addPhoto(imageURL, imageName, imageHash, undefined, false);
                                }
                            }
                            break;
                        case Qt.Key_Plus:
                        case Qt.Key_Equal:
                            if (event.key === Qt.Key_Plus || event.text === "+") {
                                if (sources.showingThisPc || folderList.currentIndex < 0 || folderModel.isFolder(folderList.currentIndex))
                                    break;
                                var imageURL = folderModel.get(folderList.currentIndex, "fileURL");
                                var imageName = folderModel.get(folderList.currentIndex, "fileName");
                                var imageHash = fileSystemNavigator.imageStateHash(imageURL);
                                result.addPhoto(imageURL, imageName, imageHash, undefined, false);
                            } else {
                                handled = false;
                            }
                            break;
                        default:
                            handled = false;
                        }
                        if (handled)
                            event.accepted = true;
                    }

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: fileItem
                        required property int index
                        required property string fileName
                        required property var fileURL

                        width: folderList.width - (vbar.visible ? vbar.width : 0)
                        readonly property string imagePath: fileItem.fileURL.toString()
                        readonly property string imageHash: sources.showingThisPc || folderModel.isFolder(fileItem.index) ? "" : fileSystemNavigator.imageStateHash(fileItem.fileURL)
                        readonly property bool isInResult: !sources.showingThisPc && !folderModel.isFolder(fileItem.index) && result.photoIndex(fileItem.imagePath, fileItem.imageHash) >= 0
                        readonly property bool isSelectedImage: !sources.showingThisPc && !folderModel.isFolder(index) && fileItem.imagePath === sources.selectedImageUrl.toString()
                        readonly property int cachedRotation: isSelectedImage ? fullview.rotationAngle : sources.rotationForImage(fileItem.imagePath, fileItem.imageHash)
                        readonly property bool isRotated: cachedRotation % 180 !== 0
                        readonly property real unrotatedPreviewHeight: thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0 ? (width - 4) * thumbnail.implicitHeight / thumbnail.implicitWidth : sources.minimumPreviewHeight
                        readonly property real rotatedPreviewHeight: thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0 ? (width - 4) * (isRotated ? thumbnail.implicitWidth / thumbnail.implicitHeight : thumbnail.implicitHeight / thumbnail.implicitWidth) : sources.minimumPreviewHeight
                        readonly property real previewHeight: Math.max(sources.minimumPreviewHeight, isRotated && unrotatedPreviewHeight < sources.minimumPreviewHeight ? sources.minimumPreviewHeight : rotatedPreviewHeight)
                        height: sources.showingThisPc ? 48 : folderModel.isFolder(index) ? 48 : previewHeight + 34

                        // Drag.active: !sources.showingThisPc && !folderModel.isFolder(fileItem.index) && sourceDragArea.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.keys: ["q2photopoint-photo"]
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: ({
                                "application/x-q2photopoint-origin": "source",
                                "application/x-q2photopoint-path": fileItem.imagePath,
                                "application/x-q2photopoint-name": fileItem.fileName,
                                "application/x-q2photopoint-hash": fileItem.imageHash
                            })

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            border.width: fileItem.isSelectedImage ? 2 : folderList.activeFocus && folderList.currentIndex === fileItem.index ? 1 : 0
                            border.color: fileItem.isSelectedImage ? "#1976d2" : "#64748b"
                            color: sources.showingThisPc || folderModel.isFolder(fileItem.index) ? "#f1f5f9" : "#e2e8f0"

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

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        radius: 4
                                        color: "transparent"
                                        border.width: fileItem.isInResult ? 3 : 0
                                        border.color: '#5aec90'
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 6
                                    Layout.rightMargin: 6
                                    Layout.bottomMargin: 4
                                    Layout.preferredHeight: sources.showingThisPc || folderModel.isFolder(fileItem.index) ? 48 : implicitHeight
                                    verticalAlignment: Text.AlignVCenter
                                    text: sources.showingThisPc || folderModel.isFolder(fileItem.index) ? "\uD83D\uDCC1  " + fileItem.fileName : fileItem.fileName
                                    elide: Text.ElideMiddle
                                    color: "#334155"
                                }
                            }
                        }

                        MouseArea {
                            id: sourceDragArea
                            anchors.fill: parent
                            property point pressPos

                            onPressed: function (mouse) {
                                pressPos = Qt.point(mouse.x, mouse.y);
                            }

                            onPositionChanged: function (mouse) {
                                if (!pressed)
                                    return;
                                if (Math.abs(mouse.x - pressPos.x) > 8) {
                                    fileItem.Drag.active = true;
                                }
                            }

                            onReleased: {
                                fileItem.Drag.active = false;
                            }
                            onClicked: {
                                folderList.currentIndex = fileItem.index;
                                folderList.forceActiveFocus();
                                if (sources.showingThisPc) {
                                    sources.showingThisPc = false;
                                    folderModel.folder = fileItem.fileURL;
                                } else if (folderModel.isFolder(fileItem.index)) {
                                    folderModel.folder = fileItem.fileURL;
                                } else {
                                    sources.selectImageByModelIndex(fileItem.index, false);
                                }
                            }
                            onDoubleClicked: {
                                if (!sources.showingThisPc && !folderModel.isFolder(fileItem.index)) {
                                    sources.selectImageByModelIndex(fileItem.index, false);
                                    result.addPhoto(fileItem.fileURL, fileItem.fileName, fileItem.imageHash, undefined, true);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
