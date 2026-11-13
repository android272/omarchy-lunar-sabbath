import QtQuick
import qs.Commons

Column {
  id: root

  signal invoked(string id)

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
      model: root.entries
      delegate: Rectangle {
        id: row
        required property var modelData
        readonly property bool highlighted: mouse.containsMouse
        readonly property color lineColor: highlighted ? Color.menu.selectedText : Color.menu.text

        width: root.width
        // Omarchy menu base row: at least 50px, heading type, menu font.
        height: Math.max(Style.space(50), Style.font.body + Style.spacing.rowPaddingX * 2)
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
          onClicked: root.invoked(row.modelData.id)
        }

        Accessible.role: Accessible.Button
        Accessible.name: row.modelData.key + " " + row.modelData.action
        Accessible.onPressAction: root.invoked(row.modelData.id)
      }
    }
  }
}
