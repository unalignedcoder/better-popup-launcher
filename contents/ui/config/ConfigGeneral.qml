/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.iconthemes as KIconThemes
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
//import "code/tools.js" as Tools

Item {
    id:root

    property alias cfg_title: title.text
    property string cfg_titleDefault
    property alias cfg_subtitle: subtitle.text
    property string cfg_subtitleDefault
    property bool cfg_separatorStyle: Plasmoid.configuration.separatorStyle
    property bool cfg_separatorStyleDefault
    property alias cfg_icon: icon.text
    property string cfg_iconDefault
    property var cfg_apps: []
    property var cfg_appsDefault: []
    property alias cfg_widgetWidth: widgetWidth.value
    property int cfg_widgetWidthDefault
    property int scrollY: 0
    property int startY: 0
    property int lastMouseY: 0
    property string title: 'Popup Launcher'
    property ListModel appsModel: ListModel {}

    property int listViewHeight: 0
    property ListView listViewReference: apps // Store a reference to the ListView here

    Plasma5Support.DataSource {
        id: appsSource
        engine: 'apps'
        connectedSources: sources
    }


    GridLayout {
        columns: 2

        Label {
            text: i18n('Title:')
        }

        TextField {
            id: title
        }
        Label {
            text: i18n('Subtitle:')
        }

        TextField {
            id: subtitle
        }
        Label {
            text: i18n('Icon:')
        }

        RowLayout {
            TextField {
                id: icon
            }

        Button {
            id: iconButton

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2
            hoverEnabled: true

            Accessible.name: i18nc("@action:button", "Change Application Launcher's icon")
            Accessible.description: i18nc("@info:whatsthis", "Current icon is %1. Click to open menu to change the current icon or reset to the default icon.", cfg_icon)
            Accessible.role: Accessible.ButtonMenu

            ToolTip.text: i18nc("@info:tooltip", "Icon name is \"%1\"", cfg_icon)
            ToolTip.visible: iconButton.hovered && cfg_icon.length > 0

            // Initialize cfg_icon with the user's chosen icon when the configuration window is loaded
            Component.onCompleted: {
                if (cfg_icon === "") {
                    // Initialize with a default icon for the first time use
                    cfg_icon = Plasmoid.configuration.icon;
                }
                previewFrame.imagePath = cfg_icon;
            }

            KIconThemes.IconDialog {
                id: iconDialog2
                onIconNameChanged: (iconName) => {
                    cfg_icon = iconName || "start-here-kde" // Update the cfg_icon property
                    previewFrame.imagePath = cfg_icon; // Update the icon displayed in previewFrame
                }
            }

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            KSvg.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: plasmoid.formFactor === PlasmaCore.Types.Vertical || plasmoid.formFactor === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.medium + fixedMargins.left + fixedMargins.right
                height: Kirigami.Units.iconSizes.medium + fixedMargins.top + fixedMargins.bottom

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: cfg_icon
                }
            }

            Menu {
                id: iconMenu

                // Appear below the button
                y: +parent.height

                MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    Accessible.description: i18nc("@info:whatsthis", "Choose an icon for Application Launcher")
                    onClicked: iconDialog2.open()
                }
                MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Reset to default icon")
                    icon.name: "edit-clear"
                    enabled: cfg_icon !== "start-here-kde"
                    onClicked: cfg_icon = "start-here-kde"
                }
                MenuItem {
                    text: i18nc("@action:inmenu", "Remove icon")
                    icon.name: "delete"
                    enabled: cfg_icon !== "" && "start-here-kde" && plasmoid.formFactor !== PlasmaCore.Types.Vertical
                    onClicked: cfg_icon = ""
                }
            }
        }


        }

        Label {
            text: i18n('Applications:')
        }

        Component.onCompleted: {
            listViewHeight = apps.height; // Set listViewHeight to the height of the ListView
        }

        ColumnLayout {
            Rectangle {
                width: 300
                height: 200
                border {
                    width: 1
                    color: "lightgrey"
                }
                radius: 2
                //color: "#20FFFFFF"

                ScrollView {
                    anchors.fill: parent

                    ListView {
                        id: apps
                        anchors.fill: parent
                        clip: true
                        property int appsHeight: apps.height

                        delegate: Item {
                            id: appItem
                            width: apps.width
                            height: Kirigami.Units.iconSizes.smallMedium + 2* Kirigami.Units.smallSpacing

                            property bool isHovered: false
                            property bool isUpHovered: false
                            property bool isDownHovered: false
                            property bool isRemoveHovered: false

                            //empty entries appear as separator lines
                            Rectangle {
                                height: 1
                                width: parent.width
                                color: "gray"
                                border.color: "transparent"
                                visible: modelData === ""
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter // Corrected property
                            }

                            MouseArea {
                                id: container
                                anchors.fill: parent
                                drag.target: parent // Enable dragging on the whole item

                                property int originalIndex
                                property int currentIndex: originalIndex // Initialize currentIndex
                                property bool isDragging: false

                                hoverEnabled: true

                                onEntered: {
                                    apps.currentIndex = index
                                    isHovered = true
                                }
                                onExited: {
                                    isHovered = false
                                }

                                // Implement drag and drop handlers
                                onPressed: {
                                    if (!isHovered) return
                                    drag.source = appItem
                                    originalIndex = apps.currentIndex
                                    currentIndex = originalIndex // Initialize currentIndex
                                    startY = mouse.y // Store the initial mouse position
                                    isDragging = true
                                    drag.hotSpot = Qt.point(width / 2, height / 2) // Initialize hotSpot here
                                    //console.log("Original Index:", originalIndex, "Current Index:", apps.currentIndex);
                                }

                                onReleased: {
                                    if (drag.active) {
                                        drag.source = null;
                                        isDragging = false;
                                        if (currentIndex !== originalIndex && originalIndex !== -1) {
                                            moveAndApplyChanges(originalIndex, currentIndex);
                                        }
                                    }

                                }


                                onPositionChanged: {
                                    if (isDragging) {
                                        var newIndex = Math.floor((drag.target.y + (appItem.height / 2)) / appItem.height); // Calculate the new index based on the Y position
                                        newIndex = Math.max(0, Math.min(newIndex, cfg_apps.length - 1)); // Ensure the index is within bounds
                                        if (currentIndex !== newIndex) {
                                            currentIndex = newIndex; // Update the currentIndex
                                            //console.log("Current Index:", originalIndex, "New Index:", currentIndex);
                                        }


                                    }
                                }

                                RowLayout {
                                    x: Kirigami.Units.smallSpacing
                                    y: Kirigami.Units.smallSpacing

                                    //1) Icon
                                    Item { // Hack - since setting the dimensions of PlasmaCore.IconItem won't work
                                        height: Kirigami.Units.iconSizes.smallMedium
                                        width: height

                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: modelData !== "" ? appsSource.data[modelData].iconName : ""
                                            active: isHovered
                                        }
                                    }
                                    //2) Label
                                    Label {
                                        text: modelData !== "" ? appsSource.data[modelData].name : ""
                                        //height: parent.height
                                        verticalAlignment: Text.AlignVCenter
                                    }


                                    //3) Remove
                                    Rectangle {
                                        height: Kirigami.Units.iconSizes.smallMedium
                                        width: Kirigami.Units.iconSizes.small
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                        visible: isHovered
                                        z: 1
                                        radius: Kirigami.Units.iconSizes.smallMedium / 4
                                        color: 'white'
                                        opacity: 1

                                        Behavior on color { NumberAnimation { duration: Kirigami.Units.shortDuration * 3 } }

                                        Label {
                                            id: labelRemove
                                            opacity: 1
                                            text: 'x'
                                            color: isRemoveHovered ? 'red' : 'gray'
                                            horizontalAlignment: Text.AlignHCenter // Center the label horizontally
                                            verticalAlignment: Text.AlignVCenter // Center the label vertically
                                            anchors.fill: parent

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true

                                                onEntered: {
                                                    isRemoveHovered = true;
                                                    labelColorAnimation.running = true;
                                                }
                                                onExited: {
                                                    isRemoveHovered = false;
                                                    labelColorAnimation.running = true;
                                                }

                                                onClicked: {
                                                    var m = apps.model;
                                                    var i = null;
                                                    while ((i = m.indexOf(modelData)) !== -1) {
                                                        m.splice(i, 1);
                                                    }
                                                    cfg_apps = m;
                                                    apps.model = m;
                                                }
                                            }

                                            ColorAnimation {
                                                id: labelColorAnimation
                                                target: labelRemove
                                                property: "color"
                                                duration: Kirigami.Units.shortDuration * 3
                                                from: labelRemove.color
                                                to: isRemoveHovered ? 'red' : 'gray'
                                            }
                                        }
                                    } //Rectangle

                                } //RowLayout

                            } //MouseArea

                        } //delegate: Item

                        Component.onCompleted: {
                            model = Plasmoid.configuration.apps
                            listViewHeight = height; // Set listViewHeight to the height of the ListView
                            //updateScrollPosition(newItemPosition);
                        }
                    } //ListView

                }//ScrollView
            }

            Button {
                id: addAppButton
                //Layout.alignment: Qt.AlignRight
                text: i18n('Add application')
                icon.name: 'list-add-symbolic'
                onClicked: {
                    appMenuDialog.open()
                }
            }

            Button {
                id: addSeparatorButton
                //Layout.alignment: Qt.AlignRight
                text: i18n('Add separator')
                icon.name: 'list-add-symbolic' // Use an appropriate icon here
                onClicked: {
                    addSeparator();
                }
            }

            CheckBox {
                text: i18n('Use thin lines as separators')
                checked: Plasmoid.configuration.separatorStyle
                onCheckedChanged: {
                    var m = apps.model
                    m.push(Plasmoid.configuration.separatorStyle = checked) //applied immediately
                    cfg_apps = m
                    apps.model = m
                    //Plasmoid.configuration.separatorStyle = checked;
                    //Plasmoid.configuration.save();
                }
            }

        } //ColumnLayout

        Label {
            text: i18n('Widget width:')
        }

        SpinBox {
            id: widgetWidth
            from: Kirigami.Units.iconSizes.medium + 2* Kirigami.Units.smallSpacing
            to: 1000
            stepSize: 10
            value: Math.max(from, Math.min(value, to))
            textFromValue: function(value) {
                return value.toFixed(0) + " px";
            }
        }

    } //GridLayout

    FileDialog {
        id: iconDialog
        title: 'Please choose an image file'
        currentFolder: '/usr/share/icons/breeze/'
        nameFilters: ['Image files (*.png *.jpg *.xpm *.svg *.svgz)', 'All files (*)']
        onAccepted: {
            icon.text = iconDialog.fileUrl
        }
    }

    AppMenuDialog {
        id: appMenuDialog
        onAccepted: {
            var m = apps.model
            m.push(selectedMenuId)
            cfg_apps = m
            apps.model = m
        }
    }

    function addSeparator() {
        var m = apps.model
        m.push("")
        cfg_apps = m
        apps.model = m
        //cfg_apps.push(""); // Add an empty item to the list
        //apps.model = cfg_apps; // Update the model directly
    }

    function updateScrollPosition(newPosition) {
        apps.contentY = newPosition;
    }


    function moveAndApplyChanges(fromIndex, toIndex) {
    var movedItem = cfg_apps[fromIndex];
    if (movedItem !== undefined) {
        var updatedModel = cfg_apps.slice(); // Create a copy of the array to modify
        updatedModel.splice(fromIndex, 1);
        updatedModel.splice(toIndex, 0, movedItem);

        cfg_apps = updatedModel; // Update the model
        apps.model = updatedModel; // Update the ListView's model
    }
}


}
