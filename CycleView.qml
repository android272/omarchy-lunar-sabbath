import QtQuick
import qs.Commons

Column {
  id: root

  property var cycle: null
  property var day: null
  property string ruleShort: ""

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  Text {
    width: parent.width
    text: root.day
      ? ("Lunar day " + root.day.lunarDay + " of " + root.day.monthLength)
      : ""
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.heading
    font.bold: true
  }

  Text {
    width: parent.width
    text: root.cycle
      ? (root.cycle.daysRemaining === 0
        ? "The next lunar month begins on the following local date."
        : (root.cycle.daysRemaining + (root.cycle.daysRemaining === 1 ? " day remains" : " days remain") + " in this lunar month."))
      : ""
    color: Color.popups.text
    opacity: 0.75
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Item {
    id: trackBox
    width: parent.width
    height: Style.space(36)

    Rectangle {
      id: track
      width: parent.width
      height: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      radius: height / 2
      color: Util.alpha(Color.popups.text, 0.12)
    }

    Rectangle {
      width: track.width * (root.cycle ? root.cycle.progress : 0)
      height: track.height
      anchors.verticalCenter: parent.verticalCenter
      radius: height / 2
      color: root.day && root.day.isSabbath ? "#e0b44c" : Color.popups.text
    }

    Repeater {
      model: root.cycle ? root.cycle.markers : []
      delegate: Rectangle {
        required property var modelData
        width: Style.space(2)
        height: Style.space(18)
        x: Math.max(0, track.width * modelData.fraction - width / 2)
        anchors.verticalCenter: parent.verticalCenter
        color: "#e0b44c"
        Accessible.name: "Sabbath " + modelData.label
      }
    }
  }

  Text {
    width: parent.width
    text: root.day
      ? (root.day.monthStart + "  →  " + root.day.nextMonthStart)
      : ""
    color: Color.popups.text
    opacity: 0.6
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    width: parent.width
    text: "Gold marks are Sabbath days under " + root.ruleShort + "."
    color: Color.popups.text
    opacity: 0.7
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Repeater {
    model: root.cycle ? root.cycle.markers : []
    delegate: Text {
      required property var modelData
      width: root.width
      text: modelData.label
      color: "#e0b44c"
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }
}
