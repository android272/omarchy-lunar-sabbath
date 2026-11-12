import QtQuick
import "../../lunar.js" as Lunar

Item {
  id: root
  width: 16
  height: 16

  Component.onCompleted: Qt.callLater(root.run)

  function run() {
    var intl = (typeof Intl === "object") && Intl && (typeof Intl.DateTimeFormat === "function")
    console.log("CalcSmoke: Intl " + (intl ? "present" : "missing"))
    var nowMs = Date.parse("2026-11-05T18:00:00Z")
    if (!nowMs || nowMs !== nowMs) {
      console.log("CalcSmoke: Date.parse failed")
      Qt.quit()
      return
    }
    var view = Lunar.buildView({
      nowMs: nowMs,
      ruleId: "days-8-15-22-29",
      basisId: "conjunction",
      locationConfigured: true,
      latitude: 31.7683,
      longitude: 35.2137,
      timeZone: "Asia/Jerusalem",
      locationLabel: "Jerusalem",
      weekStart: 0
    })
    var phase = view && view.now ? view.now.phaseName : ""
    var cells = view && view.calendar && view.calendar.cells ? view.calendar.cells.length : 0
    var sabbaths = view && view.sabbaths ? view.sabbaths.length : 0
    var rule = view && view.rule ? view.rule.short : ""
    var lunarDay = view && view.now ? view.now.lunarDay : "?"
    console.log("CalcSmoke: " + phase + " day " + lunarDay + " " + rule)
    if (phase && rule === "Rule: 1/8/15/22/29" && cells === 42 && sabbaths === 8)
      console.log("CalcSmoke: buildView OK")
    else
      console.log("CalcSmoke: buildView failed cells " + cells + " sabbaths " + sabbaths)
    Qt.quit()
  }
}
