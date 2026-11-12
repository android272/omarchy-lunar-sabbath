import QtQuick
import qs.Commons

Column {
  id: root

  property var calendar: null
  signal pickDate(string iso)
  signal shiftMonth(int delta)

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  Row {
    width: parent.width
    spacing: Style.spacing.sm
    TextButton { label: "Prev"; onClicked: root.shiftMonth(-1) }
    Text {
      width: parent.width - Style.space(140)
      anchors.verticalCenter: parent.verticalCenter
      text: root.calendar ? root.calendar.label : ""
      color: Color.popups.text
      horizontalAlignment: Text.AlignHCenter
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
      elide: Text.ElideRight
    }
    TextButton { label: "Next"; onClicked: root.shiftMonth(1) }
  }

  Row {
    width: parent.width
    spacing: Style.space(4)
    Repeater {
      model: root.calendar ? root.calendar.weekdays : []
      delegate: Text {
        required property var modelData
        width: (parent.width - Style.space(4) * 6) / 7
        text: modelData
        color: Color.popups.text
        opacity: 0.55
        horizontalAlignment: Text.AlignHCenter
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  Grid {
    id: dayGrid
    width: parent.width
    columns: 7
    columnSpacing: Style.space(4)
    rowSpacing: Style.space(4)

    Repeater {
      model: root.calendar ? root.calendar.cells : []
      delegate: Rectangle {
        id: cell
        required property var modelData
        width: (dayGrid.width - dayGrid.columnSpacing * 6) / 7
        height: Style.space(54)
        radius: Style.space(5)
        opacity: modelData.inMonth ? 1 : 0.38
        color: modelData.isSabbath
          ? Util.alpha("#e0b44c", 0.2)
          : (modelData.isSelected ? Util.alpha(Color.popups.text, 0.12) : Util.alpha(Color.popups.text, 0.04))
        border.width: modelData.isSabbath || modelData.isToday || modelData.isSelected ? 1 : 0
        border.color: modelData.isSabbath
          ? "#e0b44c"
          : (modelData.isToday ? Color.popups.text : Util.alpha(Color.popups.text, 0.45))

        MoonDisk {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(4)
          size: Style.space(18)
          phaseAngleDeg: cell.modelData.phaseAngleDeg
          sabbath: cell.modelData.isSabbath
          litColor: Color.popups.text
          shadowColor: Color.popups.background
          rimColor: Util.alpha(Color.popups.text, 0.8)
        }
        Text {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: Style.space(2)
          text: cell.modelData.day
          color: cell.modelData.isSabbath ? "#e0b44c" : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: cell.modelData.isToday
        }
        MouseArea {
          anchors.fill: parent
          onClicked: root.pickDate(cell.modelData.iso)
        }
        Accessible.role: Accessible.Button
        Accessible.name: (cell.modelData.isSabbath ? "Sabbath " : "") + cell.modelData.iso
        Accessible.onPressAction: root.pickDate(cell.modelData.iso)
      }
    }
  }

  Text {
    width: parent.width
    text: "Gold marks a Sabbath under the active rule. Click a day to open it on Tonight."
    color: Color.popups.text
    opacity: 0.55
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
