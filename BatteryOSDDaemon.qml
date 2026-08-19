import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Configurable plugin settings
    property bool enableOSD: (pluginData && pluginData.enableOSD !== undefined) ? pluginData.enableOSD : true
    property bool enablePlugAlert: (pluginData && pluginData.enablePlugAlert !== undefined) ? pluginData.enablePlugAlert : true
    property int osdDuration: (pluginData && pluginData.osdDuration) ? pluginData.osdDuration : 2500
    property int lowThreshold: (pluginData && pluginData.lowThreshold) ? pluginData.lowThreshold : 20
    property int chargingWaveSpeed: (pluginData && pluginData.chargingWaveSpeed) ? pluginData.chargingWaveSpeed : 1800
    property int dischargingWaveSpeed: (pluginData && pluginData.dischargingWaveSpeed) ? pluginData.dischargingWaveSpeed : 6000

    // Direct reactivity to native BatteryService singleton (matches DankBar Battery Widget)
    readonly property int batteryPercentage: BatteryService.batteryLevel
    readonly property bool isPluggedIn: BatteryService.isPluggedIn
    readonly property bool isCharging: BatteryService.isCharging
    readonly property string timeRemaining: (BatteryService.formatTimeRemaining() !== "Unknown") ? BatteryService.formatTimeRemaining() : ""

    property bool _isInitialState: true
    property bool _prevPluggedIn: false
    property int _prevLevel: -1

    // Instantiator creating OSD windows for all connected screens
    Instantiator {
        id: osdInstantiator
        model: Quickshell.screens

        delegate: BatteryOSDWindow {
            modelData: modelData
            batteryPercentage: root.batteryPercentage
            isPluggedIn: root.isPluggedIn
            isCharging: root.isCharging
            timeRemaining: root.timeRemaining
            customHideInterval: root.osdDuration
            chargingWaveSpeed: root.chargingWaveSpeed
            dischargingWaveSpeed: root.dischargingWaveSpeed
        }
    }

    function showAllOSDs() {
        if (!root.enableOSD || SessionData.suppressOSD) return;
        for (let i = 0; i < osdInstantiator.count; i++) {
            let item = osdInstantiator.objectAt(i);
            if (item && typeof item.show === "function") {
                item.show();
            }
        }
    }

    // Reactive Listeners to BatteryService singleton
    Connections {
        target: BatteryService

        function onIsPluggedInChanged() {
            if (root._isInitialState) {
                root._prevPluggedIn = BatteryService.isPluggedIn;
                return;
            }
            if (root.enablePlugAlert && BatteryService.isPluggedIn !== root._prevPluggedIn) {
                root._prevPluggedIn = BatteryService.isPluggedIn;
                root.showAllOSDs();
            }
        }

        function onBatteryLevelChanged() {
            if (root._isInitialState) {
                root._prevLevel = BatteryService.batteryLevel;
                root._isInitialState = false;
                return;
            }
            if (!BatteryService.isPluggedIn && BatteryService.batteryLevel <= root.lowThreshold && root._prevLevel > root.lowThreshold) {
                root.showAllOSDs();
            }
            root._prevLevel = BatteryService.batteryLevel;
        }
    }

    // IPC Command Handler (`dms ipc call batteryOSD <command>`)
    IpcHandler {
        target: "batteryOSD"

        function get(): string {
            return JSON.stringify({
                percentage: root.batteryPercentage,
                isPluggedIn: root.isPluggedIn,
                isCharging: root.isCharging,
                timeRemaining: root.timeRemaining
            });
        }

        function show(): string {
            root.showAllOSDs();
            return "battery osd shown";
        }

        function toggle(): string {
            root.showAllOSDs();
            return "battery osd toggled";
        }
    }

    Component.onCompleted: {
        // Auto-populate default plugin settings in plugin_settings.json upon install / load
        if (typeof SettingsData !== "undefined" && SettingsData.setPluginSetting) {
            let currentSettings = SettingsData.getPluginSettingsForPlugin("batteryOSD");
            if (!currentSettings || currentSettings.enabled === undefined) {
                SettingsData.setPluginSetting("batteryOSD", "enabled", true);
                SettingsData.setPluginSetting("batteryOSD", "enableOSD", true);
                SettingsData.setPluginSetting("batteryOSD", "enablePlugAlert", true);
                SettingsData.setPluginSetting("batteryOSD", "osdDuration", 2500);
                SettingsData.setPluginSetting("batteryOSD", "lowThreshold", 20);
                SettingsData.setPluginSetting("batteryOSD", "chargingWaveSpeed", 1800);
                SettingsData.setPluginSetting("batteryOSD", "dischargingWaveSpeed", 6000);
            }
        }
        root._prevPluggedIn = BatteryService.isPluggedIn;
        root._prevLevel = BatteryService.batteryLevel;
        root._isInitialState = false;
    }
}
