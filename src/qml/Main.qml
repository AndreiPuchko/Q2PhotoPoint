import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


import PhotoPoint

ApplicationWindow {
    id: window

    width: 1280
    height: 800
    visible: true

    title: "PhotoPoint"
    color: "#f4f6f9"

    // visibility: Window.Maximized

    ApplicationBackend {
        id: backend
    }

    property var steps: [
        "Welcome",
        "Photos",
        "Products",
        "Order"
    ]


    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            color: "#ffffff"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32

                Label {
                    text: "PhotoPoint"
                    font.pixelSize: 27
                    font.bold: true
                    color: "#1769aa"
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: "Self-service photo kiosk"
                    color: "#64748b"
                    font.pixelSize: 16
                }
            }
        }

        // Main content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: backend.currentPage

            Rectangle {
                color: "#f4f6f9"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 28

                    Label {
                        text: "Welcome to PhotoPoint"
                        font.pixelSize: 38
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: "Create beautiful photo prints in just a few steps."
                        font.pixelSize: 20
                        color: "#64748b"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        text: "Start"
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 72
                        Layout.alignment: Qt.AlignHCenter

                        font.pixelSize: 24

                        onClicked: backend.navigateTo(1)
                    }
                }
            }

            PhotoSelectionPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Rectangle {
                color: "#f4f6f9"

                Label {
                    anchors.centerIn: parent
                    text: "Product selection — coming next"
                    font.pixelSize: 28
                }
            }

            Rectangle {
                color: "#f4f6f9"

                Label {
                    anchors.centerIn: parent
                    text: "Your order — coming next"
                    font.pixelSize: 28
                }
            }
        }

        // Navigation
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 86
            color: "#ffffff"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32

                Button {
                    text: "Back"
                    enabled: backend.currentPage > 0

                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 52

                    onClicked: backend.navigateTo(
                        backend.currentPage - 1
                    )
                }

                Item {
                    Layout.fillWidth: true
                }

                Repeater {
                    model: window.steps

                    delegate: Label {
                        required property int index
                        required property string modelData

                        text: modelData

                        color: index === backend.currentPage
                               ? "#1769aa"
                               : "#94a3b8"

                        font.pixelSize: 16
                        font.bold: index === backend.currentPage

                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Continue"

                    enabled: backend.currentPage < 3

                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 52

                    onClicked: backend.navigateTo(
                        backend.currentPage + 1
                    )
                }
            }
        }
    }
}
