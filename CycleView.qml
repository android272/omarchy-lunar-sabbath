import QtQuick
import qs.Commons

Column {
  id: root

  property var cycle: null
  property var day: null
  property string ruleShort: ""

  // One lunar month, drawn north-up. A new moon sits on each end of the bar.
  readonly property var phaseMoons: [
    { angle: 0, fraction: 0, name: "New Moon" },
    { angle: 45, fraction: 0.125, name: "Waxing Crescent" },
    { angle: 90, fraction: 0.25, name: "First Quarter" },
    { angle: 135, fraction: 0.375, name: "Waxing Gibbous" },
    { angle: 180, fraction: 0.5, name: "Full Moon" },
    { angle: 225, fraction: 0.625, name: "Waning Gibbous" },
    { angle: 270, fraction: 0.75, name: "Last Quarter" },
    { angle: 315, fraction: 0.875, name: "Waning Crescent" },
    { angle: 0, fraction: 1, name: "Next New Moon" }
  ]

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  // The bar runs from the center of the opening new moon to the center of
  // the closing one. Sabbath ticks and the fill use that same span.
  function phaseStripOk() {
    if (width < trackBox.moonSize * 4) {
      console.log("CycleView: width " + width + " is too small to place the phase moons")
      return false
    }
    var disks = []
    var i
    for (i = 0; i < moonRow.children.length; i++) {
      var child = moonRow.children[i]
      if (!child || Math.abs(child.height - trackBox.moonSize) > 0.5) continue
      disks.push(child)
    }
    disks.sort(function (a, b) { return a.x - b.x })
    if (disks.length !== root.phaseMoons.length) {
      console.log("CycleView: expected " + root.phaseMoons.length + " moons, saw " + disks.length)
      return false
    }
    for (i = 0; i < disks.length; i++) {
      var expected = root.phaseMoons[i]
      if (Math.abs(disks[i].phaseAngleDeg - expected.angle) > 0.01 || disks[i].phaseName !== expected.name) {
        console.log("CycleView: moon " + i + " is " + disks[i].phaseName + " at " + disks[i].phaseAngleDeg)
        return false
      }
      var expectedX = expected.fraction * (width - trackBox.moonSize)
      if (Math.abs(disks[i].x - expectedX) > 0.6) {
        console.log("CycleView: moon " + i + " x " + disks[i].x + " expected " + expectedX)
        return false
      }
    }
    var leftCenter = disks[0].x + disks[0].width / 2
    var rightCenter = disks[disks.length - 1].x + disks[disks.length - 1].width / 2
    var trackRight = track.x + track.width
    if (Math.abs(track.x - leftCenter) > 0.6 || Math.abs(trackRight - rightCenter) > 0.6) {
      console.log("CycleView: track " + track.x + ".." + trackRight + " moons " + leftCenter + ".." + rightCenter)
      return false
    }
    return true
  }

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
    readonly property int moonSize: Style.space(28)
    readonly property int barHeight: Style.space(18)
    height: moonSize + Style.spacing.sm + barHeight

    Item {
      id: moonRow
      width: parent.width
      height: trackBox.moonSize

      Repeater {
        model: root.phaseMoons
        delegate: Item {
          id: moonSlot
          required property var modelData
          readonly property real phaseAngleDeg: modelData.angle
          readonly property string phaseName: modelData.name
          width: trackBox.moonSize
          height: width
          x: modelData.fraction * (moonRow.width - width)

          MoonDisk {
            anchors.fill: parent
            phaseAngleDeg: moonSlot.phaseAngleDeg
            litColor: Color.popups.text
            shadowColor: Color.popups.background
            rimColor: Util.alpha(Color.popups.text, 0.8)
            Accessible.name: moonSlot.phaseName
          }
        }
      }
    }

    Item {
      id: barHost
      width: parent.width
      height: trackBox.barHeight
      anchors.top: moonRow.bottom
      anchors.topMargin: Style.spacing.sm

      Item {
        id: track
        x: trackBox.moonSize / 2
        width: parent.width - trackBox.moonSize
        height: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          anchors.fill: parent
          radius: height / 2
          color: Util.alpha(Color.popups.text, 0.12)
        }

        Rectangle {
          width: parent.width * (root.cycle ? root.cycle.progress : 0)
          height: parent.height
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
