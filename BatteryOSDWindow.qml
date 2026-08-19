import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

DankOSD {
    id: root

    property int batteryPercentage: BatteryService.batteryLevel
    property bool isPluggedIn: BatteryService.isPluggedIn
    property bool isCharging: BatteryService.isCharging
    property string timeRemaining: (BatteryService.formatTimeRemaining() !== "Unknown") ? BatteryService.formatTimeRemaining() : ""
    property int customHideInterval: 2500

    readonly property bool useVertical: isVerticalLayout

    // Smooth Animated Percentage Transition (0.0 to 1.0)
    property real animatedPercentage: 0.0

    Component.onCompleted: {
        animatedPercentage = Math.max(0, Math.min(100, root.batteryPercentage)) / 100.0;
    }

    onBatteryPercentageChanged: {
        animatedPercentage = Math.max(0, Math.min(100, root.batteryPercentage)) / 100.0;
    }

    Behavior on animatedPercentage {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    // Dynamic Material 3 Status Color
    readonly property color statusColor: {
        if (root.isPluggedIn || root.isCharging) return "#2ecc71"; // Material Green charging
        if (root.batteryPercentage <= 15) return Theme.error; // Material Critical Red
        if (root.batteryPercentage <= 35) return "#ffa502"; // Material Warning Orange
        return Theme.primary;
    }

    // Dynamic Material Battery Icon
    readonly property string batteryIcon: {
        if (root.isPluggedIn || root.isCharging) return "battery_charging_full";
        if (root.batteryPercentage <= 15) return "battery_alert";
        if (root.batteryPercentage <= 30) return "battery_low";
        if (root.batteryPercentage >= 95) return "battery_full";
        return "battery_std";
    }

    osdWidth: useVertical ? (40 + Theme.spacingS * 2) : Math.min(260, screenWidth - Theme.spacingM * 2)
    osdHeight: useVertical ? Math.min(260, screenHeight - Theme.spacingM * 2) : (40 + Theme.spacingS * 2)
    autoHideInterval: customHideInterval
    enableMouseInteraction: true

    content: Loader {
        anchors.fill: parent
        sourceComponent: useVertical ? verticalContent : horizontalContent
    }

    property int chargingWaveSpeed: 1800
    property int dischargingWaveSpeed: 6000

    // Continuous Ocean Wave Movement
    property real phase: 0

    NumberAnimation {
        id: waveAnim
        target: root
        property: "phase"
        from: 0
        to: Math.PI * 2
        duration: root.chargingWaveSpeed
        loops: Animation.Infinite
        running: (root.isPluggedIn || root.isCharging) && root.visible
    }

    NumberAnimation {
        id: gentleAnim
        target: root
        property: "phase"
        from: 0
        to: Math.PI * 2
        duration: root.dischargingWaveSpeed
        loops: Animation.Infinite
        running: !(root.isPluggedIn || root.isCharging) && root.visible
    }

    Component {
        id: horizontalContent

        Item {
            anchors.centerIn: parent
            width: parent.width - Theme.spacingS * 2
            height: 40

            // Main Card Track Container
            Rectangle {
                id: trackBg
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: Theme.surfaceContainer
                border.color: Theme.withAlpha(root.statusColor, 0.3)
                border.width: 1
                clip: true

                // Horizontal Ocean Wave Live Charge Indicator Canvas
                Canvas {
                    id: waveCanvas
                    anchors.fill: parent
                    antialiasing: true

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        let radius = Theme.cornerRadius;

                        // Clip path for rounded rectangle
                        ctx.beginPath();
                        if (typeof ctx.roundRect === "function") {
                            ctx.roundRect(0, 0, width, height, radius);
                        } else {
                            ctx.moveTo(radius, 0);
                            ctx.lineTo(width - radius, 0);
                            ctx.quadraticCurveTo(width, 0, width, radius);
                            ctx.lineTo(width, height - radius);
                            ctx.quadraticCurveTo(width, height, width - radius, height);
                            ctx.lineTo(radius, height);
                            ctx.quadraticCurveTo(0, height, 0, height - radius);
                            ctx.lineTo(0, radius);
                            ctx.quadraticCurveTo(0, 0, radius, 0);
                        }
                        ctx.closePath();
                        ctx.clip();

                        let targetY = height * (1.0 - Math.max(0.02, Math.min(1.0, root.animatedPercentage)));
                        let amp = 2.5;
                        let freq = 0.035;

                        // Back Wave Layer (30% Opacity)
                        drawWave(ctx, targetY, root.phase + Math.PI, root.statusColor, 0.30, amp, freq);

                        // Front Wave Layer (70% Opacity)
                        drawWave(ctx, targetY, root.phase, root.statusColor, 0.70, amp, freq);

                        // Wave Crest Stroke
                        ctx.strokeStyle = "#ffffff";
                        ctx.lineWidth = 1.0;
                        ctx.globalAlpha = 0.4;
                        ctx.beginPath();
                        ctx.moveTo(-10, targetY + amp * Math.sin(root.phase));
                        for (let x = -10; x <= width + 10; x += 4) {
                            let y = targetY + amp * Math.sin(x * freq + root.phase);
                            y = Math.max(-5, Math.min(height + 5, y));
                            ctx.lineTo(x, y);
                        }
                        ctx.stroke();
                    }

                    function drawWave(ctx, targetY, phaseShift, color, opacity, amp, freq) {
                        ctx.fillStyle = color;
                        ctx.globalAlpha = opacity;
                        ctx.beginPath();
                        ctx.moveTo(-10, height + 10);
                        ctx.lineTo(-10, targetY);

                        for (let x = -10; x <= width + 10; x += 4) {
                            let y = targetY + amp * Math.sin(x * freq + phaseShift);
                            y = Math.max(-5, Math.min(height + 5, y));
                            ctx.lineTo(x, y);
                        }

                        ctx.lineTo(width + 10, height + 10);
                        ctx.closePath();
                        ctx.fill();
                    }

                    Connections {
                        target: root
                        function onPhaseChanged() { waveCanvas.requestPaint(); }
                        function onAnimatedPercentageChanged() { waveCanvas.requestPaint(); }
                        function onStatusColorChanged() { waveCanvas.requestPaint(); }
                    }
                }

                // Foreground Content Row with High Contrast Typography
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingS
                    z: 10

                    // Left Battery Icon Badge
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.withAlpha(Theme.surface, 0.4)
                        border.color: Theme.withAlpha("#ffffff", 0.3)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        DankIcon {
                            anchors.centerIn: parent
                            name: root.batteryIcon
                            size: 16
                            color: "#ffffff"
                        }
                    }

                    // Inside Text Label Column (Simple & Responsive)
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: -1

                        Row {
                            spacing: Theme.spacingS

                            StyledText {
                                text: root.batteryPercentage + "%"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }

                            StyledText {
                                text: (root.isPluggedIn || root.isCharging) ? I18n.tr("Charging") : (root.batteryPercentage <= 20 ? I18n.tr("Low Battery") : I18n.tr("Discharging"))
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 1, 1, 0.95)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: root.timeRemaining ? root.timeRemaining : ((root.isPluggedIn || root.isCharging) ? I18n.tr("Connected to AC") : I18n.tr("On Battery"))
                            font.pixelSize: 10
                            color: Qt.rgba(1, 1, 1, 0.8)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: verticalContent

        Item {
            anchors.centerIn: parent
            width: 40
            height: parent.height - Theme.spacingS * 2

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Theme.withAlpha(root.statusColor, 0.15)
                border.color: Theme.withAlpha(root.statusColor, 0.4)
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0

                DankIcon {
                    anchors.centerIn: parent
                    name: root.batteryIcon
                    size: 18
                    color: root.statusColor
                }
            }

            StyledText {
                text: root.batteryPercentage + "%"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                y: 38
            }

            Rectangle {
                width: 10
                height: parent.height - 60
                radius: 5
                color: Theme.surfaceContainerHigh
                anchors.horizontalCenter: parent.horizontalCenter
                y: 58
                clip: true

                Rectangle {
                    width: parent.width
                    height: parent.height * Math.max(0, Math.min(1, root.animatedPercentage))
                    radius: 5
                    color: root.statusColor
                    anchors.bottom: parent.bottom

                    Behavior on height {
                        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
