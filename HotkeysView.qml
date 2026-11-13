import QtQuick
import qs.Commons
import qs.Ui as Ui

Column {
  id: root

  signal invoked(string id)

  // The panel flickable. Keyboard movement scrolls this so the cursor row stays visible.
  property Flickable viewport: null
  property int selectedIndex: 0
  readonly property int rowHeight: Math.max(Style.space(50), Style.font.body + Style.spacing.rowPaddingX * 2)
  readonly property int rowPeek: Math.round(rowHeight * 0.55)

  function disarmPointer() {
    pointerGate.reset()
  }

  function resetCursor() {
    root.selectedIndex = 0
    root.disarmPointer()
    root.revealCursor()
  }

  function moveCursor(delta) {
    var count = root.entries.length
    if (count < 1) return
    root.disarmPointer()
    root.selectedIndex = (root.selectedIndex + delta + count) % count
    root.revealCursor()
  }

  function activate() {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.entries.length) return
    root.invoked(root.entries[root.selectedIndex].id)
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    if (index < 0 || index >= root.entries.length) return
    root.selectedIndex = index
  }

  // Keep the cursor row on screen. The ends jump to the top or bottom of the
  // scroll, matching a wrap. Middle rows also leave a peek of the neighbor.
  function revealCursor() {
    var flick = root.viewport
    if (!flick || flick.height < 1) return
    var count = root.entries.length
    var index = root.selectedIndex
    if (count < 1 || index < 0 || index >= count) return
    var maxY = Math.max(0, flick.contentHeight - flick.height)
    if (index === 0) {
      flick.contentY = 0
      return
    }
    if (index === count - 1) {
      flick.contentY = maxY
      return
    }
    var row = keyRepeater.itemAt(index)
    if (!row) return
    var pos = row.mapToItem(flick.contentItem, 0, 0)
    var top = pos.y
    var bottom = top + row.height
    var y = flick.contentY
    if (top < y) y = top
    if (bottom > y + flick.height) y = bottom - flick.height
    flick.contentY = Math.max(0, Math.min(y, maxY))

    var peek = root.rowPeek + Style.spacing.xs
    var overhang = bottom + peek - (flick.contentY + flick.height)
    if (overhang > 0) flick.contentY = Math.min(flick.contentY + overhang, maxY)
    var underhang = flick.contentY - (top - peek)
    if (underhang > 0) flick.contentY = Math.max(flick.contentY - underhang, 0)
  }

  Ui.PointerMoveGate {
    id: pointerGate
  }

  // Same order the panel handles. Labels match the Omarchy keybindings
  // menu: uppercase key, arrow, short action.
  readonly property var entries: [
    { id: "tonight", key: "1", action: "Tonight" },
    { id: "calendar", key: "2", action: "Calendar" },
    { id: "cycle", key: "3", action: "Cycle" },
    { id: "sabbaths", key: "4", action: "Sabbaths" },
    { id: "eclipses", key: "5", action: "Eclipses" },
    { id: "prev-day", key: "LEFT", action: "Previous day" },
    { id: "prev-day", key: "H", action: "Previous day" },
    { id: "next-day", key: "RIGHT", action: "Next day" },
    { id: "next-day", key: "L", action: "Next day" },
    { id: "prev-week", key: "UP", action: "Previous week" },
    { id: "prev-week", key: "K", action: "Previous week" },
    { id: "next-week", key: "DOWN", action: "Next week" },
    { id: "next-week", key: "J", action: "Next week" },
    { id: "today", key: "T", action: "Today" },
    { id: "new-moon", key: "N", action: "Next new moon" },
    { id: "full-moon", key: "F", action: "Next full moon" },
    { id: "next-sabbath", key: "B", action: "Next Sabbath" },
    { id: "settings", key: "G", action: "Settings" },
    { id: "hotkeys", key: "?", action: "Hotkeys" },
    { id: "close", key: "ESCAPE", action: "Close this menu, then the panel" },
    { id: "panel-next", key: "TAB", action: "Next shell panel" },
    { id: "panel-prev", key: "SHIFT + TAB", action: "Previous shell panel" }
  ]

  function widestKey() {
    var best = ""
    for (var i = 0; i < root.entries.length; i++) {
      var key = root.entries[i].key
      if (key.length > best.length) best = key
    }
    return best
  }

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  // Prompt line from the Omarchy menu card. No ellipsis: this list does not filter.
  Item {
    width: parent.width
    height: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)

    Text {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "Keybindings"
      color: Color.menu.text
      opacity: 0.58
      font.family: Style.font.menuFamily
      font.pixelSize: Style.font.heading
      font.weight: Font.Medium
      elide: Text.ElideRight
    }
  }

  TextMetrics {
    id: keyMetrics
    font.family: Style.font.menuFamily
    font.pixelSize: Style.font.heading
    font.weight: Font.Medium
    text: root.widestKey()
  }

  Column {
    width: parent.width
    spacing: Style.spacing.xs

    Repeater {
      id: keyRepeater
      model: root.entries
      delegate: Rectangle {
        id: row
        required property int index
        required property var modelData
        readonly property bool highlighted: root.selectedIndex === index
        readonly property color lineColor: highlighted ? Color.menu.selectedText : Color.menu.text

        width: root.width
        // Omarchy menu base row: at least 50px, heading type, menu font.
        height: root.rowHeight
        radius: Style.cornerRadius
        color: highlighted ? Color.menu.selectedBackground : "transparent"

        Row {
          id: line
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: Style.space(18)
          anchors.rightMargin: Style.space(18)
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Text {
            id: keyText
            width: keyMetrics.width
            text: row.modelData.key
            color: row.lineColor
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.Medium
            elide: Text.ElideRight
          }

          Text {
            id: arrowText
            text: " → "
            color: row.lineColor
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.Medium
          }

          Text {
            width: Math.max(0, line.width - keyText.width - arrowText.implicitWidth)
            text: row.modelData.action
            color: row.lineColor
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.Medium
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.selectFromPointer(row.index, row, { x: mouse.mouseX, y: mouse.mouseY })
          onPositionChanged: function (mousePos) { root.selectFromPointer(row.index, row, mousePos) }
          onClicked: {
            root.selectedIndex = row.index
            root.invoked(row.modelData.id)
          }
        }

        Accessible.role: Accessible.Button
        Accessible.name: row.modelData.key + " " + row.modelData.action
        Accessible.onPressAction: root.invoked(row.modelData.id)
      }
    }
  }
}
