import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Q2PhotoPoint

ApplicationWindow {
    id: window

    x: 0
    y: 0
    width: 1280
    height: 800
    visible: true

    title: "Q2PhotoPoint"
    color: "#f4f6f9"

    // visibility: Window.Maximized

    ApplicationBackend {
        id: backend
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2
        PhotoSelectionPage {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
