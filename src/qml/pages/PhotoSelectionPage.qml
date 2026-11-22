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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Label {
                    text: "Preview"
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f1f5f9"
                    radius: 6

                    Label {
                        anchors.centerIn: parent
                        text: "Select a photo to preview!"
                        color: "#94a3b8"
                    }
                }

                RowLayout {
                    Button {
                        text: "Rotate"
                    }
                    Button {
                        text: "Crop"
                    }
                    Button {
                        text: "Adjust"
                    }
                    Item {
                        Layout.fillWidth: true
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

            function updateFoundImageCount() {
                var count = 0
                for (var i = 0; i < folderModel.count; ++i) {
                    if (!folderModel.isFolder(i))
                        ++count
                }
                foundImageCount = count
            }

            function showThisPc() {
                thisPcModel.clear()
                var drives = fileSystemNavigator.availableWindowsDrives()
                for (var i = 0; i < drives.length; ++i)
                    thisPcModel.append(drives[i])
                showingThisPc = true
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
                        readonly property real previewHeight: Math.max(
                            sources.minimumPreviewHeight,
                            thumbnail.implicitWidth > 0
                                ? (width - 4) * thumbnail.implicitHeight / thumbnail.implicitWidth
                                : sources.minimumPreviewHeight)
                        height: sources.showingThisPc ? 48
                            : folderModel.isFolder(index) ? 48 : previewHeight + 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
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
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: sources.showingThisPc ? "" : fileItem.fileURL
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: width
                                        fillMode: Image.PreserveAspectFit
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
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
