import QtQuick
import qs.Commons

Column {
  id: root

  property var cycle: null
  signal pickDate(string iso)

  // One lunar month, drawn north-up. A new moon sits on each end of the bar.
  // The phase markers carry the same fractions as the progress fill and the
  // date labels, so all three share one timeline.
  readonly property var phaseMoons: root.cycle && root.cycle.phaseMarkers ? root.cycle.phaseMarkers : []
  readonly property var phaseDates: {
    var marks = root.cycle && root.cycle.phaseMarkers ? root.cycle.phaseMarkers : []
    var out = []
    for (var i = 0; i < marks.length; i++) if (marks[i].showDate) out.push(marks[i])
    return out
  }

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  // The bar runs from the center of the opening new moon to the center of
  // the closing one. Phase dates and the fill use that same span.
  function dateX(fraction, labelWidth) {
    var rowWidth = dateRow.width
    var textWidth = labelWidth > 0 ? labelWidth : 0
    if (rowWidth < 1) return 0
    var span = Math.max(0, rowWidth - trackBox.moonSize)
    var center = trackBox.moonSize / 2 + fraction * span
    var left = Math.round(center - textWidth / 2)
    var maxLeft = Math.max(0, rowWidth - textWidth)
    if (left < 0) left = 0
    if (left > maxLeft) left = maxLeft
    return left
  }

  function activatePhase(index) {
    if (index < 0 || index >= root.phaseDates.length) return
    root.pickDate(root.phaseDates[index].iso)
  }

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

  function phaseDatesOk() {
    var labels = []
    var i
    for (i = 0; i < dateRow.children.length; i++) {
      var child = dateRow.children[i]
      if (!child || child.text === undefined) continue
      labels.push(child)
    }
    labels.sort(function (a, b) { return a.x - b.x })
    if (labels.length !== root.phaseDates.length) {
      console.log("CycleView: expected " + root.phaseDates.length + " dates, saw " + labels.length)
      return false
    }
    var span = Math.max(0, width - trackBox.moonSize)
    for (i = 0; i < labels.length; i++) {
      var mark = root.phaseDates[i]
      // The opening and closing new-moon dates sit at the row edges. Wider
      // labels are pushed inward there, so check the edge instead of center.
      if (mark.fraction === 0) {
        if (Math.abs(labels[i].x) > 0.6) {
          console.log("CycleView: opening date x " + labels[i].x)
          return false
        }
        continue
      }
      if (mark.fraction === 1) {
        if (Math.abs(labels[i].x + labels[i].width - width) > 0.6) {
          console.log("CycleView: closing date right " + (labels[i].x + labels[i].width))
          return false
        }
        continue
      }
      var expectedCenter = trackBox.moonSize / 2 + mark.fraction * span
      var actualCenter = labels[i].x + labels[i].width / 2
      if (Math.abs(actualCenter - expectedCenter) > 0.6) {
        console.log("CycleView: date " + i + " center " + actualCenter + " expected " + expectedCenter)
        return false
      }
    }
    return true
  }

  function phaseCardsOk() {
    var cards = []
    var i
    for (i = 0; i < phaseGrid.children.length; i++) {
      var child = phaseGrid.children[i]
      if (!child || child.cardTitle === undefined) continue
      cards.push(child)
    }
    cards.sort(function (a, b) {
      if (a.y !== b.y) return a.y - b.y
      return a.x - b.x
    })
    if (cards.length !== root.phaseDates.length) {
      console.log("CycleView: expected " + root.phaseDates.length + " cards, saw " + cards.length)
      return false
    }
    for (i = 0; i < cards.length; i++) {
      var expected = root.phaseDates[i]
      if (cards[i].cardTitle !== expected.cardName || cards[i].cardDate !== expected.dateLabel) {
        console.log("CycleView: card " + i + " is " + cards[i].cardTitle + " " + cards[i].cardDate)
        return false
      }
      if (Math.abs(cards[i].width - phaseGrid.cardWidth) > 0.6) {
        console.log("CycleView: card " + i + " width " + cards[i].width + " expected " + phaseGrid.cardWidth)
        return false
      }
    }
    return true
  }

  Text {
    width: parent.width
    text: root.cycle
      ? ("Lunar day " + root.cycle.lunarDay + " of " + root.cycle.monthLength)
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
          color: Color.popups.text
        }
      }
    }
  }

  // Principal phase dates sit under the matching moon disks. Crescent and
  // gibbous disks stay unlabeled; they are ranges, not dated events.
  Item {
    id: dateRow
    width: parent.width
    height: Style.space(18)

    Repeater {
      model: root.phaseDates
      delegate: Text {
        required property var modelData
        text: modelData.dateLabel
        x: root.dateX(modelData.fraction, implicitWidth)
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Accessible.name: modelData.name + " " + modelData.dateLabel
      }
    }
  }

  Grid {
    id: phaseGrid
    width: parent.width
    columns: 2
    spacing: Style.spacing.sm

    readonly property real cardWidth: Math.max(0, (width - spacing) / columns)

    Repeater {
      model: root.phaseDates
      delegate: Rectangle {
        id: card
        required property var modelData
        required property int index
        readonly property string cardTitle: modelData.cardName
        readonly property string cardDate: modelData.dateLabel
        width: phaseGrid.cardWidth
        implicitHeight: cardBody.implicitHeight + Style.space(16)
        height: implicitHeight
        radius: Style.space(6)
        color: cardMouse.containsMouse
          ? Util.alpha(Color.popups.text, 0.1)
          : Util.alpha(Color.popups.text, 0.05)
        border.width: 1
        border.color: Util.alpha(Color.popups.text, 0.18)

        Column {
          id: cardBody
          width: parent.width - Style.space(20)
          anchors.centerIn: parent
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: card.cardTitle
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: card.cardDate
            color: Color.popups.text
            opacity: 0.72
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: cardMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activatePhase(card.index)
        }

        Accessible.role: Accessible.Button
        Accessible.name: card.cardTitle + " " + card.cardDate
        Accessible.onPressAction: root.activatePhase(card.index)
      }
    }
  }

  Text {
    width: parent.width
    text: "Choose a phase to open that date on Tonight."
    color: Color.popups.text
    opacity: 0.7
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }
}
