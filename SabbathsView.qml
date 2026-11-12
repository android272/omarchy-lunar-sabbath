import QtQuick
import qs.Commons

Column {
  id: root

  property var sabbaths: []
  property string ruleShort: ""
  signal pickDate(string iso)

  spacing: Style.spacing.sm
  width: parent ? parent.width : implicitWidth

  Text {
    width: parent.width
    text: "Upcoming under " + root.ruleShort
    color: Color.popups.text
    opacity: 0.7
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Repeater {
    model: root.sabbaths
    delegate: Rectangle {
      id: row
      required property var modelData
      width: root.width
      implicitHeight: body.implicitHeight + Style.space(14)
      radius: Style.space(6)
      color: modelData.isToday ? Util.alpha("#e0b44c", 0.2) : Util.alpha(Color.popups.text, 0.04)
      border.width: 1
      border.color: modelData.isToday ? "#e0b44c" : Util.alpha(Color.popups.text, 0.14)

      Column {
        id: body
        width: parent.width - Style.space(20)
        anchors.centerIn: parent
        spacing: Style.space(2)
        Text {
          width: parent.width
          text: row.modelData.dateLabel + (row.modelData.isToday ? "  ·  today" : "")
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: "Lunar day " + row.modelData.lunarDay + " · " + row.modelData.weekdayName + " · " + row.modelData.countdown
          color: Color.popups.text
          opacity: 0.72
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.pickDate(row.modelData.iso)
      }
      Accessible.role: Accessible.Button
      Accessible.name: row.modelData.dateLabel + " Sabbath"
      Accessible.onPressAction: root.pickDate(row.modelData.iso)
    }
  }

  Text {
    width: parent.width
    text: "Choosing a Sabbath moves Tonight, the calendar, and the cycle to that date."
    color: Color.popups.text
    opacity: 0.55
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
