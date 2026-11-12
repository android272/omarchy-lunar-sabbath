import QtQuick
import Quickshell
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root

  moduleName: "lunar.sabbath"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true : false
  property string flashText: ""

  readonly property var moonView: lunarModel.view && lunarModel.view.now ? lunarModel.view.now : null
  readonly property bool sabbathNow: moonView ? moonView.isSabbath === true : false
  readonly property string modeText: {
    if (root.vertical || !moonView) return ""
    if (lunarModel.displayMode === "illumination")
      return Math.round(moonView.illuminationPercent) + "%"
    if (lunarModel.displayMode === "letter") return sabbathNow ? "S" : ""
    if (lunarModel.displayMode === "word") return sabbathNow ? "Sabbath" : ""
    return ""
  }
  readonly property string hoverText: {
    if (!moonView || !lunarModel.view) return "Lunar Sabbath"
    return moonView.phaseName + " · " + Math.round(moonView.illuminationPercent) + "% · "
      + lunarModel.view.sabbathCountdown + " · " + lunarModel.view.rule.short
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("model" in target) target.model = lunarModel
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refreshLocal() {
    lunarModel.refresh()
  }

  function refresh() {
    root.broadcast("refreshLocal")
  }

  function pullSession() {
    lunarModel.pullSession()
  }

  function open() {
    lunarModel.pendingView = "tonight"
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function openNextSabbath() {
    lunarModel.focusNextSabbath()
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch)
      panelLoader.item.closeForPopoutSwitch()
  }

  function cycleDisplayMode() {
    var modes = ["moon", "illumination", "letter", "word"]
    var labels = ["Moon only", "Moon + illumination", "Moon + S", "Moon + Sabbath"]
    var index = modes.indexOf(lunarModel.displayMode)
    var next = modes[(index + 1) % modes.length]
    if (index < 0) next = modes[0]
    lunarModel.setDisplayMode(next)
    root.flashText = labels[modes.indexOf(next)]
    if (root.bar) root.bar.showTooltip(button, root.flashText)
    flashTimer.restart()
    root.broadcast("pullSession")
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onSettingsChanged: {
    lunarModel.shellSettings = root.settings
    injectPanel()
  }

  LunarModel {
    id: lunarModel
    shellSettings: root.settings
  }

  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: lunarModel.refresh()
  }

  Timer {
    id: flashTimer
    interval: 1600
    repeat: false
    onTriggered: {
      root.flashText = ""
      if (root.bar && button.tooltipHovered) root.bar.showTooltip(button, root.hoverText)
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.flashText !== "" ? root.flashText : root.hoverText
    labelVisible: false
    hasVisualContent: true
    active: root.opened
    fixedWidth: root.vertical ? root.barSize
      : (contentRow.implicitWidth + (root.modeText !== "" ? Style.spacing.controlPaddingX * 2 : Style.spacing.md * 2))
    fixedHeight: root.barSize

    onPressed: function (buttonCode) {
      if (buttonCode === Qt.MiddleButton) root.openNextSabbath()
      else if (buttonCode === Qt.RightButton) root.cycleDisplayMode()
      else root.open()
    }

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: root.modeText !== "" ? Style.spacing.controlGap : 0

      MoonDisk {
        anchors.verticalCenter: parent.verticalCenter
        size: Style.space(16)
        phaseAngleDeg: root.moonView ? root.moonView.phaseAngleDeg : 0
        sabbath: root.sabbathNow
        litColor: root.sabbathNow ? "#e0b44c" : button.foreground
        shadowColor: root.bar ? root.bar.background : Color.bar.background
        rimColor: root.sabbathNow ? "#e0b44c" : button.foreground
      }

      Text {
        visible: root.modeText !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.modeText
        color: root.sabbathNow ? "#e0b44c" : button.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }
  }
}
