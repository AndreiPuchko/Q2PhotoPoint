import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
                        text: "Select a photo to preview"
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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label {
                    text: "Current folder"
                    font.bold: true
                }

                Label {
                    text: "Demo photos"
                    color: "#64748b"
                    font.pixelSize: 12
                }

                ListView {
                    id: folderList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: 0

                    delegate: Rectangle {
                        width: folderList.width
                        height: width * 0.75
                        color: "#e2e8f0"
                        radius: 4
                    }
                }
            }
        }
    }
}
