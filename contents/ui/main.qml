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
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls.Fusion
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: popupLauncher

    property var title: Plasmoid.configuration.title
    property var subtitle: Plasmoid.configuration.subtitle
    property var icon: Plasmoid.configuration.icon
    property var apps: Plasmoid.configuration.apps
    property bool separatorStyle: Plasmoid.configuration.separatorStyle
    property int widgetWidth: Plasmoid.configuration.widgetWidth

    switchWidth: fullRepresentationItem ? fullRepresentationItem.Layout.minimumWidth : Kirigami.Units.iconSizes.huge * 10
    switchHeight: fullRepresentationItem ? fullRepresentationItem.Layout.minimumHeight : Kirigami.Units.iconSizes.huge * 10

    toolTipTextFormat: Text.StyledText
    toolTipMainText: title ? title : (subtitle ? "" : Plasmoid.name)
    toolTipSubText: subtitle ? subtitle : (title ? "" : Plasmoid.name)

    preferredRepresentation: compactRepresentation

    Component.onCompleted: {
        // trigger adding all sources already available
        for (var i in appsSource.sources) {
            appsSource.sourceAdded(appsSource.sources[i]);
        }
        //console.log("separatorHeight " + separatorHeight);
        //console.log("visibleItemCount " + visibleItemCount);
        //console.log("emptyItemCount " + emptyItemCount);
    }

   /* Was needed in Plasma 5 to execute commands with kRun.openUrl
    Logic {
        id: kRun
    }*/

    Plasma5Support.DataSource {
        id: appsSource
        engine: 'apps'

        onSourceAdded: (source) => {
            connectSource(source)
        }

        onSourceRemoved: (source) => {
            disconnectSource(source);
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)
        }

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }


    compactRepresentation: Kirigami.Icon
    {
        source: icon
        width: Kirigami.Units.iconSizes.medium
        height: Kirigami.Units.iconSizes.medium
        active: mouseArea.containsMouse

        MouseArea {
            id: mouseArea
            anchors.fill: parent

            onClicked: {
                popupLauncher.expanded = !popupLauncher.expanded;
                /*if (Plasmoid.expanded) {
                    // Adjust the x position of the FullRepresentation using its Layout
                    //fullRepresentation.Layout.leftMargin = -fullRepresentation.width; // Adjust this value
                }*/
            }

            hoverEnabled: true
        }

    }

    fullRepresentation: FullRepresentation {}


}


