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
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Dialog {
    id: appMenuDialog
    title: i18n('Choose an application')
    standardButtons: Dialog.Cancel

    width: 300
    height: 400

    property string selectedMenuId: ''

    Plasma5Support.DataSource {
        id: appsSource
        engine: 'apps'
        connectedSources: sources
    }

    ListModel {
        id: appsModel
    }

    ScrollView {
        width: parent.width
        height: 400

        ListView {
            id: apps
            anchors.fill: parent
            clip: true

            model: appsModel

            //TODO Plasma 6 highlight: PlasmaComponents.Highlight {}
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            delegate: Item {
                width: parent.width
                height: Kirigami.Units.iconSizes.small + 2* Kirigami.Units.smallSpacing

                property bool isHovered: false

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true
                    onEntered: {
                        apps.currentIndex = index
                        isHovered = true
                    }
                    onExited: {
                        isHovered = false
                    }

                    onClicked: {
                        selectedMenuId = desktop
                        appMenuDialog.accept()
                    }

                    RowLayout {
                        x: Kirigami.Units.smallSpacing
                        y: Kirigami.Units.smallSpacing

                        Item { // Hack - since setting the dimensions of PlasmaCore.IconItem won't work
                            height: Kirigami.Units.iconSizes.small
                            width: height

                            Kirigami.Icon {
                                anchors.fill: parent
                                source: appsSource.data[desktop].iconName
                                active: isHovered
                            }
                        }

                        Label {
                            text: appsSource.data[desktop].name
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            section.property: 'category'
            section.delegate: Item {
                width: parent.width
                height: Kirigami.Units.iconSizes.small + 2* Kirigami.Units.smallSpacing

                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.positiveBackgroundColor

                    Label {
                        x: Kirigami.Units.smallSpacing
                        y: 0
                        width: parent.width - 2* Kirigami.Units.smallSpacing
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: section
                        font.bold: true
                        color: Kirigami.Theme.textColor
                    }
                }
            }

            Component.onCompleted: {
                listMenuEntries('/')
            }
        }
    }

    function listMenuEntries(menuId) {
        if (appsSource.data[menuId] === undefined) {
            console.log("Error: Menu category " + menuId + " does not exist");
            return;
        }
        if (appsSource.data[menuId].entries === undefined) {
            console.log("Warning: Menu category " + menuId + " has no entries");
            return;
        }
        for (var i = 0, length = appsSource.data[menuId].entries.length; i < length; i++) {
            var entry = appsSource.data[menuId].entries[i]
            if (/\.desktop$/.test(entry)) {
                var category = (menuId == '/') ? '/' : menuId.slice(0, -1);
                appsModel.append({desktop: entry, category: category})
            } else if (/\/$/.test(entry) && entry != '.hidden/') {
                listMenuEntries(entry)
            }
        }

    }

}
