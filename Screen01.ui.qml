

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick 2.15
import QtQuick.Controls 2.15
// import UntitledProject
import QtQuick.Layouts 2.15
import QtQuick.Dialogs
import QtQml
import QtCore

// import QtQuick.Studio.Components 1.0
ApplicationWindow {
    // Rectangle {
    visible: true
    id: myApp
    objectName: "myApp"
    width: 1920
    height: 1080
    property string target_full_path: ""
    property string source_full_path: ""
    property string save_trans_path: ""
    property string save_pcd_path: ""
    property bool _live_draw: true
    property bool _target_loaded: false
    property bool _source_loaded: false
    // property double roll: 0.0
    // property double pitch: 0.0
    // property double yaw: 0.0
    // property double x: 0.0
    // property double y: 0.0
    // property double z: 0.0
    x: 1586
    y: 229

    FileDialog {
        id: target_fileDialog
        nameFilters: ["PCD files (*.pcd)", "All files (*)"]
        fileMode: FileDialog.OpenFile
        // @disable-check M223
        onAccepted: {
            myApp.target_full_path = selectedFile
            // @disable-check M222
            var pathList = myApp.target_full_path.split("/")
            text_show_target_path.text = pathList[pathList.length - 1]
            // @disable-check M222
            backend.get_path()
            button_open_target.enabled = true
            button_open_target.opacity = 1.0
        }
    }

    FileDialog {
        id: source_fileDialog
        nameFilters: ["PCD files (*.pcd)", "All files (*)"]
        fileMode: FileDialog.OpenFile
        // @disable-check M223
        onAccepted: {
            myApp.source_full_path = selectedFile
            // @disable-check M222
            var pathList = myApp.source_full_path.split("/")
            text_show_source_path.text = pathList[pathList.length - 1]
            // @disable-check M222
            backend.get_path()
            button_open_source.enabled = true
            button_open_source.opacity = 1.0
        }
    }

    FileDialog {
        id: save_trans_fileDialog
        nameFilters: ["Text files (*.txt)", "CSV files (*.csv)", "All files (*)"]
        selectedNameFilter.index: 0
        // @disable-check M223
        fileMode: FileDialog.SaveFile
        defaultSuffix: selectedNameFilter.extensions[0]
        // @disable-check M223
        onAccepted: {
            // @disable-check M222
            myApp.save_trans_path = selectedFile
            // @disable-check M222
            backend.save_transform()
            button_save.enabled = true
            button_save.opacity = 1.0
        }
        onRejected: {
            button_save.enabled = true
            button_save.opacity = 1.0
        }
    }

    FileDialog {
        id: save_pcd_fileDialog
        nameFilters: ["PCD files (*.pcd)", "All files (*)"]
        selectedNameFilter.index: 0
        // @disable-check M223
        fileMode: FileDialog.SaveFile
        defaultSuffix: selectedNameFilter.extensions[0]
        // @disable-check M223
        onAccepted: {
            // @disable-check M222
            myApp.save_pcd_path = selectedFile
            // @disable-check M222
            backend.save_pcd()
            button_save.enabled = true
            button_save.opacity = 1.0
        }
        onRejected: {
            button_save.enabled = true
            button_save.opacity = 1.0
        }
    }

    Text {
        id: header
        // x: 1540
        y: 10
        anchors.horizontalCenter: init_panel.horizontalCenter
        width: header_mtcs.width
        height: 28
        text: qsTr("ICP Tools")
        font.pixelSize: 24
        verticalAlignment: Text.AlignVCenter
        TextMetrics {
            id: header_mtcs
            font: header.font
            text: header.text
        }
    }

    Rectangle {
        id: v_line_0
        // x: 1540
        y: 165
        anchors.left: init_panel.left
        width: parent.width * 0.195
        height: 2
        color: "#000000"
    }

    Button {
        id: button_open_target
        objectName: "button_open_target"
        y: 78
        signal receivedInfo(string status)
        signal finished(bool status)
        anchors.right: init_panel.right
        width: 63
        height: 22
        enabled: false
        opacity: 0.5
        text: qsTr("Open")
        // @disable-check M223
        onClicked: {
            button_open_target.enabled = false
            button_open_target.opacity = 0.5
            init_panel.enabled = false
            init_panel.opacity = 0.5
            // @disable-check M222
            frame_timer.stop()
            // @disable-check M222
            backend.load_file_qml_cb("target")
        }
        // @disable-check M222
        onReceivedInfo: function (status) {
            text_info.text = status
        }
        // @disable-check M223
        onFinished: {
            parent._target_loaded = true
            button_open_target.enabled = true
            button_open_target.opacity = 1.0
            init_panel.enabled = true
            init_panel.opacity = 1.0
            // @disable-check M222
            backend.add_item_geometry("target")
            if (_live_draw)
                // @disable-check M222
                frame_timer.start()
            // @disable-check M223
            else {
                // @disable-check M222
                backend.update_render()
                // Force the Image to refresh by changing the source URL
                o3d_image.source = "image://open3d/scene?" + Date.now()
            }
            // @disable-check M223
            if (parent._source_loaded && parent._target_loaded) {

                button_start.enabled = true
                button_start.opacity = 1.0
                button_save.enabled = true
                button_save.opacity = 1.0
            }
        }
    }

    Button {
        id: button_select_target
        y: 49

        anchors.left: init_panel.left
        width: init_panel.width
        height: 23
        text: qsTr("Select Target")
        Layout.preferredWidth: 250
        Layout.preferredHeight: 23
        // @disable-check M223
        onClicked: {
            // @disable-check M222
            target_fileDialog.open()
        }
    }

    Text {
        id: text_show_target_path
        // x: 1540
        y: 77
        anchors.left: init_panel.left
        height: 23
        width: button_select_target.width * 0.5
        text: qsTr("Please select target pcd")
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        rightPadding: 0
        Layout.preferredWidth: 250
        Layout.preferredHeight: 23
        clip: true
    }

    Item {
        id: voxel_size_target
        objectName: "voxel_size_target"
        anchors.left: text_show_target_path.right
        anchors.verticalCenter: text_show_target_path.verticalCenter
        width: init_panel.width * 0.5 - 65
        height: 23
        // anchors.left: parent.left
        Text {
            id: voxel_size_target_text
            // x: 1555
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Voxel size")
            font.pixelSize: 12
        }

        TextInput {
            id: textInput_voxel_size_target
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.3
            // height: 20
            text: qsTr("0.05")
            font.pixelSize: 12
            rightPadding: -5
            leftPadding: 5
            selectByMouse: true
            Rectangle {
                // x: sphere_handle.width / 2
                // anchors.left: parent.left - 5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: parent.parent.height
                radius: 1
                border.width: 1
                color: "#00d3d3d3"
            }

            validator: DoubleValidator {}
            // @disable-check M223
            onEditingFinished: {
                // @disable-check M222
                backend.update_load_param(parseFloat(text), "target")
            }
        }
    }

    Button {
        id: button_open_source
        objectName: "button_open_source"
        y: 134
        signal receivedInfo(string status)
        signal finished(bool status)
        anchors.right: init_panel.right
        width: 63
        height: 22
        enabled: false
        opacity: 0.5
        text: qsTr("Open")
        // @disable-check M223
        onClicked: {
            button_open_source.enabled = false
            button_open_source.opacity = 0.5
            init_panel.enabled = false
            init_panel.opacity = 0.5
            // @disable-check M222
            frame_timer.stop()
            // @disable-check M222
            backend.load_file_qml_cb("source")
        }
        // @disable-check M222
        onReceivedInfo: function (status) {
            text_info.text = status
        }
        // @disable-check M223
        onFinished: {
            parent._source_loaded = true
            button_open_source.enabled = true
            button_open_source.opacity = 1.0
            init_panel.enabled = true
            init_panel.opacity = 1.0
            // @disable-check M222
            backend.add_item_geometry("source")
            if (_live_draw)
                // @disable-check M222
                frame_timer.start()
            // @disable-check M223
            else {
                // @disable-check M222
                backend.update_render()
                // Force the Image to refresh by changing the source URL
                o3d_image.source = "image://open3d/scene?" + Date.now()
            }
            // @disable-check M223
            if (parent._source_loaded && parent._target_loaded) {

                button_start.enabled = true
                button_start.opacity = 1.0
                button_save.enabled = true
                button_save.opacity = 1.0
            }
        }
    }

    Item {
        id: voxel_size_source
        objectName: "voxel_size_source"
        anchors.left: text_show_source_path.right
        anchors.verticalCenter: text_show_source_path.verticalCenter
        width: init_panel.width * 0.5 - 65
        height: 23
        // anchors.left: parent.left
        Text {
            id: voxel_size_source_text
            // x: 1555
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Voxel size")
            font.pixelSize: 12
        }

        TextInput {
            id: textInput_voxel_size_source
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.3
            // height: 20
            text: qsTr("0.05")
            font.pixelSize: 12
            rightPadding: -5
            leftPadding: 5
            selectByMouse: true
            Rectangle {
                // x: sphere_handle.width / 2
                // anchors.left: parent.left - 5
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: parent.parent.height
                radius: 1
                border.width: 1
                color: "#00d3d3d3"
            }
            validator: DoubleValidator {}
            // @disable-check M223
            onEditingFinished: {
                // @disable-check M222
                backend.update_load_param(parseFloat(text), "source")
            }
        }
    }

    Button {
        id: button_select_source
        // x: 1540
        y: 105
        anchors.left: init_panel.left
        width: init_panel.width
        height: 23
        text: qsTr("Select Source")
        Layout.preferredWidth: 250
        Layout.preferredHeight: 23
        // @disable-check M223
        onClicked: {
            // @disable-check M222
            source_fileDialog.open()
        }
    }

    Text {
        id: text_show_source_path
        // x: 1540
        y: 133
        width: button_select_source.width * 0.5
        anchors.left: init_panel.left
        height: 23
        text: qsTr("Please select source pcd")
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        Layout.preferredWidth: 250
        Layout.preferredHeight: 23
        clip: true
    }

    Text {
        id: _text_initial_transformation
        // x: 1540
        y: 173
        height: 23
        anchors.horizontalCenter: init_panel.horizontalCenter
        text: qsTr("Initial Transformation")
        font.pixelSize: 15
        verticalAlignment: Text.AlignVCenter
    }

    ColumnLayout {
        id: init_panel
        objectName: "init_panel"
        // x: 1540
        y: 202
        // width: 400
        // rows: 6
        // columns: 1
        width: parent.width * 0.195
        height: parent.height * 0.3
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.003

        // yaw
        ListModel {
            id: control_list
            objectName: "repeater_model"
            ListElement {
                text: "Roll"
                color: "red"
                low_bond: -3.14
                high_bond: 3.14
            }
            ListElement {
                text: "Pitch"
                color: "orange"
                low_bond: -3.14
                high_bond: 3.14
            }
            ListElement {
                text: "Yaw"
                color: "gold"
                low_bond: -3.14
                high_bond: 3.14
            }
            ListElement {
                text: "X"
                color: "green"
                low_bond: -10
                high_bond: 10
            }
            ListElement {
                text: "Y"
                color: "blue"
                low_bond: -10
                high_bond: 10
            }
            ListElement {
                text: "Z"
                color: "purple"
                low_bond: -10
                high_bond: 10
            }
        }

        Component {
            id: control_component
            Item {
                required property int index
                required property var model
                id: control_element
                objectName: "control_" + index
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width
                // @disable-check M222
                // Component.onCompleted: console.log("Completed Running!" + index)
                Text {
                    id: _text

                    objectName: "_text_" + index
                    text: qsTr(model.text)
                    font.pixelSize: 15
                    verticalAlignment: Text.AlignVCenter
                    // Layout.fillHeight: true
                    // Layout.preferredWidth: parent.width * 0.1
                    height: parent.height
                    width: parent.width * 0.1
                }

                Slider {
                    id: _slider
                    // id: parent.objectName
                    objectName: "_slider_" + index
                    value: 0
                    enabled: true
                    height: parent.height
                    width: parent.width * 0.75
                    // anchors.left: parent.left
                    transformOrigin: Item.Center
                    // anchors.centerIn: parent
                    anchors.left: _text.right
                    // anchors.leftMargin: parent.width * 0.01
                    snapMode: RangeSlider.NoSnap
                    live: true
                    // @disable-check M223
                    onMoved: {
                        // myApp.yaw = value
                        _textInput.text = (value).toFixed(4)
                        // @disable-check M222
                        _textInput.selectAll()
                        // @disable-check M223
                        if (_live_draw) {
                            // @disable-check M222
                            backend.update_init(value, model.text)
                        }
                    }
                    // @disable-check M223
                    onPressedChanged: {
                        // show slider Hover when pressed, hide otherwise
                        // @disable-check M223
                        if (!pressed) {
                            // @disable-check M222
                            backend.update_init(value, model.text)
                            // @disable-check M222
                            backend.update_render()
                            // Force the Image to refresh by changing the source URL
                            o3d_image.source = "image://open3d/scene?" + Date.now()
                        }
                    }
                    handle: Rectangle {
                        id: sphere_handle
                        x: parent.visualPosition * (parent.width - width)
                        y: (parent.height - height) / 2
                        width: 15
                        height: 15
                        radius: 15
                        color: "gray"
                    }
                    background: Rectangle {
                        id: background_rect
                        x: sphere_handle.width / 2
                        y: (parent.height - height) / 2
                        width: parent.width - sphere_handle.width
                        height: 6
                        radius: 2
                        color: "lightgray"

                        Rectangle {
                            x: Math.min(
                                   parent.parent.visualPosition,
                                   0.5) * (parent.parent.width - sphere_handle.width)
                            y: (parent.height - height) / 2
                            width: Math.abs(
                                       parent.parent.visualPosition - 0.5) * parent.width
                            height: 6
                            color: model.color
                            radius: 2
                        }
                    }
                    // @disable-check M222
                    from: parseFloat(low_bond_text.text)
                    // @disable-check M222
                    to: parseFloat(high_bond.text)
                    TextInput {
                        id: low_bond_text
                        text: (model.low_bond).toFixed(2)
                        // text: "-5"
                        width: low_bond_mtcs.width
                        anchors.left: parent.left
                        selectByMouse: true
                        font.pixelSize: 12
                        validator: DoubleValidator {}
                        TextMetrics {
                            id: low_bond_mtcs
                            font: low_bond_text.font
                            text: low_bond_text.text
                        }
                    }
                    TextInput {
                        id: high_bond
                        text: (model.high_bond).toFixed(2)
                        width: high_bond_mtcs.width
                        anchors.right: parent.right
                        selectByMouse: true
                        font.pixelSize: 12
                        validator: DoubleValidator {}
                        TextMetrics {
                            id: high_bond_mtcs
                            font: high_bond.font
                            text: high_bond.text
                        }
                    }
                }

                TextInput {
                    id: _textInput
                    objectName: "_textInput_" + index
                    text: qsTr("0.0000")
                    enabled: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    rightPadding: 5
                    leftPadding: 10
                    selectByMouse: true
                    // Layout.preferredHeight: 23
                    // Layout.preferredWidth: 25
                    height: parent.height
                    width: parent.width * 0.12 + 15

                    anchors.right: parent.right
                    // anchors.leftMargin: parent.width * 0.03
                    // borde.color: "black"
                    validator: DoubleValidator {
                        bottom: model.low_bond
                        top: model.high_bond
                        decimals: 4
                    }
                    // @disable-check M223
                    onEditingFinished: {
                        // @disable-check M222
                        // myApp.yaw = parseFloat(text)
                        // @disable-check M222
                        _slider.value = parseFloat(text)
                        // @disable-check M222
                        backend.update_init(_slider.value, model.text)
                        // @disable-check M222
                        backend.update_render()
                        // Force the Image to refresh by changing the source URL
                        o3d_image.source = "image://open3d/scene?" + Date.now()
                    }

                    // @disable-check M223
                    // onTextChanged: {
                    //     // @disable-check M222
                    //     backend.update_init_yaw(slider_yaw.value)
                    // }
                    // selectionColor: model.color
                    Rectangle {
                        // x: sphere_handle.width / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        // anchors.leftMargin: -12
                        // y: (parent.height - height) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: parent.height * 0.5
                        radius: 3
                        border.width: 1
                        color: "#00d3d3d3"
                    }
                }
            }
        }

        Repeater {
            id: init_panel_repeater
            objectName: "init_panel_repeater"
            model: control_list
            delegate: control_component
        }
    }

    // color: Constants.backgroundColor
    Image {
        id: o3d_image
        objectName: "o3d_image"
        x: 0
        y: 0
        width: parent.width * 0.8
        height: parent.height
        // source: "../../Pictures/Screenshot from 2024-03-24 22-35-36.png"
        source: "image://open3d/scene"
        fillMode: Image.PreserveAspectFit
        smooth: true
        cache: false // Disable caching to ensure image updates
        scale: 1
    }

    Button {
        id: reset_disp
        objectName: "reset_disp"
        text: qsTr("Reset")
        width: 63
        height: 22
        anchors.left: change_disp_mode.right
        // @disable-check M223
        onClicked: {
            // @disable-check M222
            backend.reset_disp()
            // @disable-check M223
            if (!_live_draw) {
                // @disable-check M222
                backend.update_render()
                // Force the Image to refresh by changing the source URL
                o3d_image.source = "image://open3d/scene?" + Date.now()
            }
        }
    }

    Button {
        id: change_disp_mode
        objectName: "change_disp_mode"
        text: qsTr("Pop!")
        width: 63
        height: 22
        // @disable-check M223
        onClicked: {
            // @disable-check M222
            backend.change_disp_mode()
            // @disable-check M223
            if (!_live_draw) {
                // @disable-check M222
                backend.update_render()
                // Force the Image to refresh by changing the source URL
                o3d_image.source = "image://open3d/scene?" + Date.now()
            }
        }
    }
    Timer {
        id: frame_timer
        objectName: "frame_timer"
        interval: 1000 / 30 // Update at 30 FPS
        running: true
        repeat: true
        // @disable-check M223
        onTriggered: {
            // @disable-check M222
            backend.update_render()
            // Force the Image to refresh by changing the source URL
            o3d_image.source = "image://open3d/scene?" + Date.now()
        }
    }

    Timer {
        id: update_panel
        interval: 1000 / 30 // Update at 30 FPS
        running: false
        repeat: true
        // @disable-check M223
        onTriggered: {
            // @disable-check M222
            var roll = backend.get_value("Roll")
            // @disable-check M222
            var pitch = backend.get_value("Pitch")
            // @disable-check M222
            var yaw = backend.get_value("Yaw")
            // @disable-check M222
            var x_t = backend.get_value("X")
            // @disable-check M222
            var y_t = backend.get_value("Y")
            // @disable-check M222
            var z_t = backend.get_value("Z")
            var pose = [roll, pitch, yaw, x_t, y_t, z_t]
            // @disable-check M223
            for (var i = 0; i < 6; i++) {
                // @disable-check M223
                for (var j = 1; j < 3; j++) {
                    // @disable-check M223
                    if (j == 1) {
                        // @disable-check M222
                        init_panel_repeater.itemAt(
                                    i).children[j].value = pose[i]
                        // @disable-check M223
                    } else {
                        // @disable-check M222
                        init_panel_repeater.itemAt(
                                    i).children[j].text = (pose[i]).toFixed(4)
                    }
                }
            }
        }
    }

    Switch {
        id: _switch_live_draw
        // width: 144
        height: _text_initial_transformation.height
        text: qsTr("Live Draw")
        font.pixelSize: 15
        anchors.verticalCenterOffset: 0
        anchors.verticalCenter: _text_initial_transformation.verticalCenter
        anchors.right: init_panel.right
        anchors.rightMargin: -21
        scale: 0.7
        checked: true
        // @disable-check M223
        onCheckedChanged: {
            _live_draw = checked
            if (!_live_draw)
                // @disable-check M222
                frame_timer.stop()
            else
                // @disable-check M222
                frame_timer.start()
        }
    }

    Button {
        id: button_stop
        objectName: "botton_stop"
        anchors.fill: button_start
        enabled: false
        opacity: 0.0
        text: qsTr("Stop!")
        onClicked: {
            button_stop.enabled = false
            button_stop.opacity = 0.5
            backend.stop_icp()
        }
    }

    Button {
        id: button_start
        objectName: "button_start"
        width: init_panel.width / 2
        height: 0.04 * parent.height
        enabled: false
        opacity: 0.5
        anchors.left: init_panel.left
        anchors.top: icp_panel.bottom
        signal finished(string status)
        signal processing(string status)
        // signal succeed(bool status)
        text: qsTr("Start!")
        // @disable-check M223
        onClicked: {
            button_start.enabled = false
            button_stop.enabled = true
            button_save.enabled = false
            init_panel.enabled = false
            init_panel.opacity = 0.5
            button_start.opacity = 0.0
            button_stop.opacity = 1.0
            button_save.opacity = 0.5
            // @disable-check M222
            backend.button_start_cb()
            update_panel.running = true
        }
        // @disable-check M222
        onFinished: function (status) {
            button_start.enabled = true
            button_stop.enabled = false
            init_panel.enabled = true
            button_start.opacity = 1.0
            button_stop.opacity = 0.0
            init_panel.opacity = 1.0
            update_panel.running = false
            text_info.text = status
            button_save.opacity = 1.0
            button_save.enabled = true
            // @disable-check M223
            if (!_live_draw) {
                // @disable-check M222
                backend.update_render()
                // Force the Image to refresh by changing the source URL
                o3d_image.source = "image://open3d/scene?" + Date.now()
            }
        }
        // @disable-check M222
        onProcessing: function (status) {
            text_info.text = status
        }
        // @disable-check M223
        // onSucceed: {

        // }
    }

    // Button {
    //     id: button_save
    //     objectName: "button_save"
    //     width: button_start.width
    //     height: button_start.height
    //     anchors.left: button_start.right
    //     anchors.verticalCenter: button_start.verticalCenter
    //     enabled: true
    //     flat: false
    //     highlighted: false
    //     text: qsTr("Save~")
    //     // @disable-check M223
    //     onClicked: {
    //         // @disable-check M222
    //         save_folderDialog.open()
    //     }
    // }
    ComboBox {
        id: button_save
        objectName: "button_save"
        width: button_start.width
        height: button_start.height
        anchors.left: button_start.right
        anchors.verticalCenter: button_start.verticalCenter
        enabled: false
        opacity: 0.5
        flat: false
        selectTextByMouse: false
        editable: false
        model: ListModel {
            id: save_model
            ListElement {
                text: "Save Trans"
            }
            ListElement {
                text: "Save PCD"
            }
        }
        // @disable-check M223
        onActivated: {
            // @disable-check M223
            button_save.enabled = false
            button_save.opacity = 0.5
            if (currentIndex === 0) {
                // @disable-check M222
                save_trans_fileDialog.open()
                // @disable-check M223
            } else if (currentIndex === 1) {
                // @disable-check M222
                save_pcd_fileDialog.open()
            }
        }
    }

    ScrollView {
        id: text_info_scroll
        objectName: "text_info_scroll"
        anchors.left: init_panel.left
        anchors.top: button_save.bottom
        anchors.topMargin: 20
        width: init_panel.width
        height: parent.height * 0.29
        Text {
            id: text_info
            objectName: "text_info"
            width: text_info_scroll.width
            height: text_info_scroll.height
            text: qsTr("")
            font.pixelSize: 12
            wrapMode: Text.Wrap
            padding: 5
            Rectangle {
                // x: sphere_handle.width / 2
                // anchors.left: parent.left - 5
                width: parent.width
                height: parent.height
                radius: 1
                border.width: 1
                color: "#00d3d3d3"
            }
        }
    }

    Text {
        id: text_icp_info
        // x: 1540
        // y: 173
        anchors.top: init_panel.bottom
        height: 23
        anchors.horizontalCenter: init_panel.horizontalCenter
        text: qsTr("ICP Param")
        font.pixelSize: 15
        verticalAlignment: Text.AlignVCenter
    }

    ColumnLayout {
        id: icp_panel
        objectName: "icp_panel"
        // x: 1540
        // y: 202
        // width: 400
        // rows: 6
        // columns: 1
        width: init_panel.width
        height: init_panel.height * 0.4
        anchors.top: text_icp_info.bottom
        // anchors.topMargin: 10
        anchors.left: init_panel.left

        // yaw
        ListModel {
            id: control_list_icp
            objectName: "repeater_model_icp"
            ListElement {
                text: "Max correspondence distance"
                label: "max_dist"
                init_value: "10.0"
            }
            ListElement {
                text: "Max iterations"
                label: "max_iter"
                init_value: "100"
            }
            ListElement {
                text: "Stop relative RMSE"
                label: "stop_rmse"
                init_value: "0.0001"
            }
        }

        Component {
            id: control_component_icp
            Item {
                id: control_element_icp
                required property int index
                required property var model
                objectName: "control_icp_" + index
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width
                // anchors.left: parent.left
                Text {
                    id: _text_max_correspondence_distance
                    // x: 1555
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr(model.text)
                    font.pixelSize: 15
                }

                TextInput {
                    id: textInput_max_correspondence_distance
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.2
                    // height: 20
                    text: qsTr(model.init_value)
                    font.pixelSize: 12
                    selectByMouse: true
                    Rectangle {
                        // x: sphere_handle.width / 2
                        // anchors.left: parent.left - 5
                        x: -5
                        y: -5
                        width: parent.width + 10
                        height: parent.height + 10
                        radius: 1
                        border.width: 1
                        color: "#00d3d3d3"
                    }
                    validator: DoubleValidator {}
                    // @disable-check M222
                    onEditingFinished: backend.update_icp_param(
                                           // @disable-check M222
                                           parseFloat(text), model.label)
                }
            }
        }

        Repeater {
            id: icp_panel_repeater
            objectName: "icp_panel_repeater"
            model: control_list_icp
            delegate: control_component_icp
        }
    }
}
