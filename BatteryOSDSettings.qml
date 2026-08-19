import QtQuick
import Quickshell

import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "batteryOSD"

    // -------------------------------------------------------------------------
    // REUSABLE SECTION CONTAINER
    // -------------------------------------------------------------------------
    component SectionContainer: Rectangle {
        width: parent.width
        height: sectionContent.implicitHeight + Theme.spacingM * 2
        color: Theme.surfaceContainer
        radius: Theme.cornerRadius
        border.color: Theme.outline
        border.width: 1
        opacity: 0.8

        default property alias content: sectionContent.data

        Column {
            id: sectionContent
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM
        }
    }

    // -------------------------------------------------------------------------
    // REUSABLE SETTINGS SLIDER
    // -------------------------------------------------------------------------
    component SettingsSlider: Column {
        id: sliderSection
        width: parent.width
        spacing: Theme.spacingXS

        property string iconName: ""
        property string title: ""
        property string description: ""
        property string settingKey: ""
        property int defaultValue: 0
        property int minimumValue: 0
        property int maximumValue: 100
        property string unit: "%"

        Row {
            width: parent.width
            spacing: Theme.spacingM
            DankIcon {
                name: sliderSection.iconName
                size: 22
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
            }
            Column {
                width: Math.max(0, parent.width - 54 - Theme.spacingM * 2)
                StyledText {
                    text: sliderSection.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }
                StyledText {
                    text: sliderSection.description
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
            Rectangle {
                id: resetBtn
                width: 32; height: 32
                radius: Theme.cornerRadius
                anchors.verticalCenter: parent.verticalCenter
                color: resetMa.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.04)
                border.color: resetMa.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15)
                border.width: 1
                opacity: (slider.value !== sliderSection.defaultValue) ? (resetMa.containsMouse ? 1.0 : 0.9) : 0.0
                visible: opacity > 0

                DankIcon {
                    name: "restart_alt"
                    size: 18
                    anchors.centerIn: parent
                    color: resetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                }

                MouseArea {
                    id: resetMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.saveValue(sliderSection.settingKey, sliderSection.defaultValue);
                        slider.value = sliderSection.defaultValue;
                    }
                }
            }
        }

        DankSlider {
            id: slider
            property string settingKey: sliderSection.settingKey
            width: parent.width
            minimum: sliderSection.minimumValue
            maximum: sliderSection.maximumValue
            unit: sliderSection.unit
            value: root.loadValue(settingKey, sliderSection.defaultValue)
            onSliderValueChanged: newValue => {
                value = newValue;
                root.saveValue(settingKey, newValue);
            }
        }
    }

    // -------------------------------------------------------------------------
    // REUSABLE SETTINGS TOGGLE
    // -------------------------------------------------------------------------
    component SettingsToggle: Column {
        id: toggleSection
        width: parent.width
        spacing: Theme.spacingXS

        property string iconName: ""
        property string title: ""
        property string description: ""
        property string settingKey: ""
        property bool defaultValue: true

        Row {
            width: parent.width
            spacing: Theme.spacingM

            DankIcon {
                name: toggleSection.iconName
                size: 22
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
            }

            Column {
                width: Math.max(0, parent.width - 22 - Theme.spacingM - 60)
                StyledText {
                    text: toggleSection.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }
                StyledText {
                    text: toggleSection.description
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                width: 52
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                DankToggle {
                    id: toggle
                    anchors.centerIn: parent
                    checked: root.loadValue(toggleSection.settingKey, toggleSection.defaultValue)
                    onToggled: function (c) {
                        root.saveValue(toggleSection.settingKey, c);
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // SETTINGS UI CONTAINERS
    // -------------------------------------------------------------------------
    Column {
        id: rootWrapper
        width: parent.width
        spacing: Theme.spacingM

        // OSD Enable & Charger Plug Toggle
        SectionContainer {
            SettingsToggle {
                iconName: "battery_charging_full"
                title: I18n.tr("Enable Battery OSD")
                description: I18n.tr("Show On-Screen Display popup when charger is plugged or unplugged.")
                settingKey: "enableOSD"
                defaultValue: true
            }

            SettingsToggle {
                iconName: "power"
                title: I18n.tr("Charger Connect/Disconnect Popup")
                description: I18n.tr("Trigger OSD popup whenever charger state changes.")
                settingKey: "enablePlugAlert"
                defaultValue: true
            }
        }

        // OSD Duration & Low Battery Threshold
        SectionContainer {
            SettingsSlider {
                iconName: "timer"
                title: I18n.tr("OSD Display Duration")
                description: I18n.tr("Duration in milliseconds before auto-hiding OSD popup.")
                settingKey: "osdDuration"
                defaultValue: 2500
                minimumValue: 1000
                maximumValue: 5000
                unit: "ms"
            }

            SettingsSlider {
                iconName: "battery_alert"
                title: I18n.tr("Low Battery Warning Threshold")
                description: I18n.tr("Battery percentage to trigger low battery warning OSD.")
                settingKey: "lowThreshold"
                defaultValue: 20
                minimumValue: 5
                maximumValue: 40
                unit: "%"
            }
        }

        // Ocean Wave Animation Speed
        SectionContainer {
            SettingsSlider {
                iconName: "waves"
                title: I18n.tr("Charging Wave Speed")
                description: I18n.tr("Speed of the liquid ocean wave animation while charging (lower is faster).")
                settingKey: "chargingWaveSpeed"
                defaultValue: 1800
                minimumValue: 1000
                maximumValue: 4000
                unit: "ms"
            }

            SettingsSlider {
                iconName: "water"
                title: I18n.tr("Discharging Wave Speed")
                description: I18n.tr("Speed of the liquid ocean wave animation while on battery (lower is faster).")
                settingKey: "dischargingWaveSpeed"
                defaultValue: 6000
                minimumValue: 2000
                maximumValue: 12000
                unit: "ms"
            }
        }
    }
}
