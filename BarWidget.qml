// Widget de barre AI Kit.
//
// Le rendu vit ici, la vérité vit dans `aikit-status` : une seule commande dit
// ce qui tourne, ce qui a atterri et si la synchronisation va bien, au format
// JSON Waybar ({text, tooltip, class}). Le widget ne fait que l'afficher et
// router les clics — aucune logique dupliquée entre le CLI et la barre.
//
// Contrat de widget tiers d'Omarchy : un Item avec implicitWidth/Height, qui
// reçoit `bar`, `moduleName` et `settings` après chargement.

import QtQuick
import Quickshell.Io

Item {
  id: root

  property var bar
  property string moduleName: "atypical.aikit"
  property var settings

  property string text: "󱓞"
  property string tooltipText: "AI Kit"
  property string statusClass: ""

  readonly property int refreshSeconds: settings && settings.interval > 0 ? settings.interval : 10
  readonly property string command: settings && settings.exec ? settings.exec : "aikit-status"
  readonly property string launcher: settings && settings.launcher ? settings.launcher : "aikit"

  implicitWidth: label.implicitWidth + 12
  implicitHeight: bar ? bar.barSize : 26

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 13
    color: root.statusClass === "urgent" || root.statusClass === "warning"
           ? (bar ? bar.urgent : "#ff6b6b")
           : (bar ? bar.foreground : "white")

    Behavior on color { ColorAnimation { duration: 120 } }
  }

  Process {
    id: statusProcess
    command: ["bash", "-lc", root.command]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.apply(text)
    }
  }

  function apply(raw) {
    var payload
    try {
      payload = JSON.parse(String(raw || "").trim())
    } catch (e) {
      // Sortie illisible : on le dit plutôt que de figer un affichage périmé.
      root.text = "󱓞"
      root.tooltipText = "AI Kit — " + String(raw || "").trim()
      root.statusClass = "warning"
      return
    }
    root.text = payload.text || "󱓞"
    root.tooltipText = payload.tooltip || "AI Kit"
    root.statusClass = payload.class || ""
  }

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true

    onEntered: if (bar) bar.showTooltip(root, root.tooltipText)
    onExited: if (bar) bar.hideTooltip(root)

    onClicked: function(mouse) {
      if (!bar) return
      if (mouse.button === Qt.MiddleButton) bar.run(root.launcher + " work")
      else if (mouse.button === Qt.RightButton) bar.run(root.launcher + " attach")
      else bar.run(root.launcher)
      // le geste change l'état : on rafraîchit sans attendre le prochain tick
      refreshAfterAction.restart()
    }
  }

  Timer {
    id: refreshAfterAction
    interval: 1500
    onTriggered: root.refresh()
  }
}
