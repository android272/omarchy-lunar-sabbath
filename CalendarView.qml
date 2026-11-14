import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Item {
  id: root

  property var calendar: null
  property bool pickerOpen: false
  property string pickerMode: "years"
  property int chosenYear: 0
  property int yearStart: 1900
  property var yearList: []
  property bool yearPinned: false

  readonly property var monthNames: [
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December"
  ]
  readonly property int pickerCell: Style.space(40)

  signal pickDate(string iso)
  signal shiftMonth(int delta)
  signal showMonth(int year, int month)

  // The picker paints over the day grid. Keep it inside this item so the
  // panel Flickable does not clip it, and so its height stays with the calendar.
  implicitHeight: column.implicitHeight
  height: implicitHeight
  width: parent ? parent.width : implicitWidth

  function openPicker() {
    var year = root.calendar && root.calendar.year ? root.calendar.year : new Date().getFullYear()
    var start = Math.min(1900, year - 40)
    var end = Math.max(2200, year + 40)
    var list = []
    var y
    for (y = start; y <= end; y++) list.push(y)
    root.yearStart = start
    root.yearList = list
    root.chosenYear = year
    root.pickerMode = "years"
    root.yearPinned = false
    root.pickerOpen = true
    Qt.callLater(root.revealViewedYear)
  }

  function closePicker() {
    root.pickerOpen = false
    root.pickerMode = "years"
  }

  function togglePicker() {
    if (root.pickerOpen) root.closePicker()
    else root.openPicker()
  }

  function revealViewedYear() {
    if (root.yearPinned || !root.pickerOpen || root.pickerMode !== "years") return
    // Wait until the grid is taller than the view. An earlier pass clamps
    // contentY to 0 and would leave the viewed year off screen.
    if (yearFlick.height < 1 || yearFlick.contentHeight <= yearFlick.height) return
    var year = root.calendar && root.calendar.year ? root.calendar.year : 0
    if (year < root.yearStart) return
    var index = year - root.yearStart
    var pitch = root.pickerCell + yearGrid.rowSpacing
    var rowY = Math.floor(index / 4) * pitch
    if (rowY + root.pickerCell > yearFlick.contentHeight) return
    var maxY = Math.max(0, yearFlick.contentHeight - yearFlick.height)
    var next = Math.max(0, Math.min(maxY, rowY - (yearFlick.height - pitch) / 2))
    yearFlick.contentY = next
    if (Math.abs(yearFlick.contentY - next) < 2) root.yearPinned = true
  }

  function scrollYears(rows) {
    if (!root.pickerOpen || root.pickerMode !== "years") return
    var pitch = root.pickerCell + yearGrid.rowSpacing
    var maxY = Math.max(0, yearFlick.contentHeight - yearFlick.height)
    yearFlick.contentY = Math.max(0, Math.min(maxY, yearFlick.contentY + rows * pitch))
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.md

  // Prev is on the left edge and Next is on the right edge. The month button
  // fills the gap between them, with the label centered in that stretch.
  Item {
    id: monthNav
    width: parent.width
    implicitHeight: Math.max(prevMonth.implicitHeight, nextMonth.implicitHeight, monthButton.implicitHeight)
    height: implicitHeight

    TextButton {
      id: prevMonth
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      label: "Prev"
      onClicked: {
        root.closePicker()
        root.shiftMonth(-1)
      }
    }
    TextButton {
      id: nextMonth
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      label: "Next"
      onClicked: {
        root.closePicker()
        root.shiftMonth(1)
      }
    }
    TextButton {
      id: monthButton
      x: prevMonth.width + Style.spacing.sm
      width: Math.max(0, parent.width - prevMonth.width - nextMonth.width - Style.spacing.sm * 2)
      anchors.verticalCenter: parent.verticalCenter
      label: root.calendar ? root.calendar.label : ""
      accessibleName: "Choose year and month"
      onClicked: root.togglePicker()
    }
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
        // Gold already owns the wash and the outline. Today takes the
        // text-colored outline back, and the viewed Sabbath uses a stronger
        // wash plus a thicker border so the two states stay readable.
        readonly property color gold: "#e0b44c"
        readonly property bool sabbath: modelData.isSabbath
        readonly property bool today: modelData.isToday
        readonly property bool selected: modelData.isSelected
        readonly property bool hovered: dayMouse.containsMouse
        width: (dayGrid.width - dayGrid.columnSpacing * 6) / 7
        height: Style.space(54)
        radius: Style.space(5)
        opacity: modelData.inMonth || today || selected ? 1 : 0.38
        color: sabbath
          ? Util.alpha(gold, selected ? 0.52 : (hovered ? 0.34 : 0.2))
          : Util.alpha(Color.popups.text, selected ? 0.12 : (hovered ? 0.08 : 0.04))
        border.width: (sabbath && (today || selected)) ? 2 : ((sabbath || today || selected) ? 1 : 0)
        border.color: today ? Color.popups.text : (sabbath ? gold : Util.alpha(Color.popups.text, 0.45))

        MoonDisk {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(4)
          size: Style.space(18)
          phaseAngleDeg: cell.modelData.phaseAngleDeg
          sabbath: cell.sabbath
          litColor: Color.popups.text
          shadowColor: Color.popups.background
          rimColor: Util.alpha(Color.popups.text, 0.8)
        }
        Text {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottomMargin: Style.space(2)
          text: cell.modelData.day
          // Today keeps the theme-colored numeral, even on a Sabbath, so the
          // gold day number does not hide the today mark.
          color: cell.sabbath && !cell.today ? cell.gold : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: cell.today
        }
        MouseArea {
          id: dayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.pickDate(cell.modelData.iso)
        }
        Accessible.role: Accessible.Button
        Accessible.name: {
          var parts = []
          if (cell.sabbath) parts.push("Sabbath")
          if (cell.today) parts.push("today")
          if (cell.selected) parts.push("selected")
          parts.push(cell.modelData.iso)
          return parts.join(" ")
        }
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

  Item {
    id: picker
    visible: root.pickerOpen
    z: 2
    clip: true
    // monthNav lives in the column, so it is not a sibling and cannot be an anchor target.
    x: 0
    y: monthNav.y + monthNav.height
    width: parent.width
    height: Math.max(0, parent.height - y)

    Rectangle {
      anchors.fill: parent
      color: Color.popups.background
      radius: Style.space(6)
      border.width: 1
      border.color: Util.alpha(Color.popups.text, 0.2)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Item {
      id: pickerBody
      anchors.fill: parent
      anchors.margins: Style.space(8)

      Item {
        id: yearHost
        anchors.fill: parent
        visible: root.pickerMode === "years"

        Flickable {
          id: yearFlick
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: parent.width - Style.space(12)
          contentWidth: width
          contentHeight: yearGrid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height
          Controls.ScrollBar.vertical: yearBar
          onHeightChanged: Qt.callLater(root.revealViewedYear)
          onContentHeightChanged: Qt.callLater(root.revealViewedYear)

          Grid {
            id: yearGrid
            width: yearFlick.width
            columns: 4
            columnSpacing: Style.space(4)
            rowSpacing: Style.space(4)

            Repeater {
              model: root.yearList
              delegate: TextButton {
                required property var modelData
                width: (yearGrid.width - yearGrid.columnSpacing * 3) / 4
                height: root.pickerCell
                label: String(modelData)
                selected: root.calendar && Number(modelData) === root.calendar.year
                onClicked: {
                  root.chosenYear = Number(modelData)
                  root.pickerMode = "months"
                }
              }
            }
          }
        }

        Controls.ScrollBar {
          id: yearBar
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          policy: yearFlick.contentHeight > yearFlick.height + 0.5
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
        }
      }

      Column {
        width: parent.width
        spacing: Style.spacing.sm
        visible: root.pickerMode === "months"

        Item {
          width: parent.width
          height: yearsBack.implicitHeight

          TextButton {
            id: yearsBack
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            label: "Years"
            accessibleName: "Back to years"
            onClicked: root.pickerMode = "years"
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: root.chosenYear > 0 ? String(root.chosenYear) : ""
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }
        }

        Grid {
          id: monthGrid
          width: parent.width
          columns: 4
          columnSpacing: Style.space(4)
          rowSpacing: Style.space(4)

          Repeater {
            model: root.monthNames
            delegate: TextButton {
              required property var modelData
              required property int index
              width: (monthGrid.width - monthGrid.columnSpacing * 3) / 4
              height: root.pickerCell
              label: modelData
              selected: root.calendar
                && root.chosenYear === root.calendar.year
                && index + 1 === root.calendar.month
              onClicked: {
                root.showMonth(root.chosenYear, index + 1)
                root.closePicker()
              }
            }
          }
        }
      }
    }
  }
}
