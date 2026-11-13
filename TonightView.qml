import QtQuick
import qs.Commons

Column {
  id: root

  property var day: null
  property var phases: []
  property bool viewingToday: true
  property string basisLabel: ""

  readonly property bool skyReady: root.day && root.day.hasLocation === true
  readonly property string riseValue: {
    if (!root.skyReady) return "—"
    return root.day.moonrise !== "" ? root.day.moonrise : "None"
  }
  readonly property string setValue: {
    if (!root.skyReady) return "—"
    return root.day.moonset !== "" ? root.day.moonset : "None"
  }
  readonly property string horizonValue: root.skyReady && root.day.horizonLabel ? root.day.horizonLabel : "—"
  readonly property var skyMetrics: [
    { icon: "rise", label: "Moonrise", value: root.riseValue },
    { icon: "set", label: "Moonset", value: root.setValue },
    { icon: "horizon", label: "Horizon", value: root.horizonValue }
  ]

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

  Rectangle {
    id: skyBox
    width: parent.width
    implicitHeight: Style.space(88)
    radius: Style.space(6)
    color: Util.alpha(Color.popups.text, 0.05)
    border.width: 1
    border.color: Util.alpha(Color.popups.text, 0.16)

    Row {
      anchors.fill: parent

      Repeater {
        model: root.skyMetrics

        delegate: Item {
          id: skyCell
          required property var modelData
          required property int index
          width: skyBox.width / 3
          height: skyBox.height

          Rectangle {
            visible: skyCell.index > 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - Style.space(20)
            color: Util.alpha(Color.popups.text, 0.16)
          }

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(8)
            spacing: Style.space(3)

            Item {
              width: parent.width
              height: skyMark.implicitHeight
              SkyIcon {
                id: skyMark
                anchors.horizontalCenter: parent.horizontalCenter
                name: skyCell.modelData.icon
                size: Style.space(18)
                color: Color.popups.text
              }
            }
            Text {
              width: parent.width
              text: skyCell.modelData.label
              color: Color.popups.text
              opacity: 0.6
              horizontalAlignment: Text.AlignHCenter
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
            Text {
              width: parent.width
              text: skyCell.modelData.value
              color: Color.popups.text
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }
        }
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
