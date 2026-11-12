import QtQuick
import Quickshell.Io
import "../../lunar.js" as Lunar

Item {
  width: 16
  height: 16

  FileView {
    id: zoneFile
    path: "/usr/share/zoneinfo/Asia/Jerusalem"
    watchChanges: false
    printErrors: true
    onLoaded: {
      var bytes = null
      try { bytes = new Uint8Array(zoneFile.data()) } catch (e) { bytes = null }
      if (!bytes || !Lunar.loadZoneBytes("Asia/Jerusalem", bytes)) {
        console.log("ZoneSmoke: parse failed")
        Qt.quit()
        return
      }
      var ms = Date.parse("2026-11-05T18:00:00Z")
      var parts = Lunar.tableZoneParts(ms, "Asia/Jerusalem")
      var label = parts ? (parts.year + "-" + parts.month + "-" + parts.day + " " + parts.hour + ":" + parts.minute) : "none"
      console.log("ZoneSmoke: " + label)
      if (parts && parts.year === 2026 && parts.month === 11 && parts.day === 5 && parts.hour === 20 && parts.minute === 0)
        console.log("ZoneSmoke: Jerusalem offset OK")
      else
        console.log("ZoneSmoke: unexpected offset")
      Qt.quit()
    }
    onLoadFailed: function (error) {
      console.log("ZoneSmoke: load failed " + error)
      Qt.quit()
    }
  }

  Timer {
    interval: 8000
    running: true
    onTriggered: {
      console.log("ZoneSmoke: timed out")
      Qt.quit()
    }
  }
}
