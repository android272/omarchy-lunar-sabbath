import QtQuick
import qs.Commons

Column {
  id: root

  property var day: null
  property var phases: []
  property bool viewingToday: true
  property string basisLabel: ""
  signal jumpPhase(int angle)

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  MoonDisk {
    anchors.horizontalCenter: parent.horizontalCenter
    size: Style.space(132)
    phaseAngleDeg: root.day ? root.day.phaseAngleDeg : 0
    sabbath: root.day ? root.day.isSabbath : false
    litColor: Color.popups.text
    shadowColor: Color.popups.background
    rimColor: Util.alpha(Color.popups.text, 0.85)
  }

  Text {
    width: parent.width
    text: root.day ? root.day.phaseName : "Moon"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.heading
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
  }

  Text {
    width: parent.width
    text: root.day
      ? (root.day.illuminationPercent + "% illuminated · lunar day "
        + root.day.lunarDay + " of " + root.day.monthLength
        + " · age " + root.day.ageDays + " days")
      : ""
    color: Color.popups.text
    opacity: 0.78
    wrapMode: Text.WordWrap
    horizontalAlignment: Text.AlignHCenter
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Text {
    width: parent.width
    visible: !root.viewingToday
    text: "Viewing " + (root.day ? root.day.dateLabel : "another date") + ", not today."
    color: Color.popups.text
    opacity: 0.62
    horizontalAlignment: Text.AlignHCenter
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Rectangle {
    width: parent.width
    implicitHeight: statusText.implicitHeight + Style.space(16)
    radius: Style.space(6)
    color: root.day && root.day.isSabbath
      ? Util.alpha("#e0b44c", 0.18)
      : Util.alpha(Color.popups.text, 0.05)
    border.width: 1
    border.color: root.day && root.day.isSabbath ? "#e0b44c" : Util.alpha(Color.popups.text, 0.16)

    Column {
      id: statusText
      width: parent.width - Style.space(20)
      anchors.centerIn: parent
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: root.day && root.day.status ? root.day.status.title : ""
        color: root.day && root.day.isSabbath ? "#e0b44c" : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
      }
      Text {
        width: parent.width
        text: root.day && root.day.status ? root.day.status.detail : ""
        color: Color.popups.text
        opacity: 0.8
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  Text {
    width: parent.width
    text: root.day ? root.day.riseSetNote : ""
    visible: root.day && root.day.riseSetNote !== ""
    color: Color.popups.text
    opacity: 0.75
    wrapMode: Text.WordWrap
    horizontalAlignment: Text.AlignHCenter
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Row {
    width: parent.width
    spacing: Style.spacing.lg
    visible: root.day && (root.day.moonrise !== "" || root.day.moonset !== "")

    Column {
      width: (parent.width - parent.spacing) / 2
      spacing: Style.space(2)
      Text {
        text: "Moonrise"
        color: Color.popups.text
        opacity: 0.6
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        text: root.day && root.day.moonrise !== "" ? root.day.moonrise : "None"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }
    Column {
      width: (parent.width - parent.spacing) / 2
      spacing: Style.space(2)
      Text {
        text: "Moonset"
        color: Color.popups.text
        opacity: 0.6
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        text: root.day && root.day.moonset !== "" ? root.day.moonset : "None"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }
  }

  Text {
    width: parent.width
    text: "Upcoming phases"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    font.bold: true
  }

  Repeater {
    model: root.phases
    delegate: Row {
      id: phaseRow
      required property var modelData
      width: root.width
      spacing: Style.spacing.md
      MoonDisk {
        width: Style.space(22)
        height: width
        phaseAngleDeg: phaseRow.modelData.angle
        litColor: Color.popups.text
        shadowColor: Color.popups.background
        rimColor: Util.alpha(Color.popups.text, 0.8)
      }
      Column {
        width: phaseRow.width - Style.space(30)
        Text {
          text: phaseRow.modelData.name
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          text: phaseRow.modelData.whenLabel + " · " + phaseRow.modelData.countdown
          color: Color.popups.text
          opacity: 0.68
          elide: Text.ElideRight
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm
    TextButton {
      label: "Next new"
      onClicked: root.jumpPhase(0)
    }
    TextButton {
      label: "Next full"
      onClicked: root.jumpPhase(180)
    }
  }

  Text {
    width: parent.width
    text: "Basis: " + root.basisLabel + ". Lunar days are local dates, midnight to midnight."
    color: Color.popups.text
    opacity: 0.55
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
