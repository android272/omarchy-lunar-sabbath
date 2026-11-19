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
    var opts = {
      nowMs: nowMs,
      ruleId: "days-8-15-22-29",
      basisId: "conjunction",
      locationConfigured: true,
      latitude: 31.7683,
      longitude: 35.2137,
      timeZone: "Asia/Jerusalem",
      locationLabel: "Jerusalem",
      weekStart: 0
    }
    var view = Lunar.buildView(opts)
    opts.selectedIso = "2027-01-08"
    var later = Lunar.buildView(opts)
    opts.selectedIso = "2026-10-01"
    var earlier = Lunar.buildView(opts)
    opts.selectedIso = "2026-01-01"
    var beforeMarch = Lunar.buildView(opts)
    opts.selectedIso = "2027-03-01"
    var afterFebruary = Lunar.buildView(opts)
    var phase = view && view.now ? view.now.phaseName : ""
    var cells = view && view.calendar && view.calendar.cells ? view.calendar.cells.length : 0
    var sabbaths = view && view.sabbaths ? view.sabbaths.length : 0
    var rule = view && view.rule ? view.rule.short : ""
    var lunarDay = view && view.now ? view.now.lunarDay : "?"
    var hasPast = false
    var i
    for (i = 0; earlier.sabbaths && i < earlier.sabbaths.length; i++) {
      if (earlier.sabbaths[i].countdown === "past") hasPast = true
    }
    var marchLunar = false
    var febGone = true
    var augLunar = false
    for (i = 0; beforeMarch.eclipses && i < beforeMarch.eclipses.length; i++) {
      if (beforeMarch.eclipses[i].kind === "lunar"
        && beforeMarch.eclipses[i].whenLabel.indexOf("3 Mar 2026") >= 0) marchLunar = true
    }
    for (i = 0; afterFebruary.eclipses && i < afterFebruary.eclipses.length; i++) {
      if (afterFebruary.eclipses[i].whenLabel.indexOf("Feb 2027") >= 0) febGone = false
      if (afterFebruary.eclipses[i].kind === "lunar"
        && afterFebruary.eclipses[i].whenLabel.indexOf("17 Aug 2027") >= 0) augLunar = true
    }
    var eclipsesMoved = marchLunar && febGone && augLunar
    var moved = later && later.sabbaths && later.sabbaths.length === 8
      && later.sabbaths[0].iso >= "2027-01-08"
      && later.sabbaths[0].iso !== (view.sabbaths ? view.sabbaths[0].iso : "")
      && later.sabbaths[0].countdown !== "today"
      && hasPast
      && eclipsesMoved
    console.log("CalcSmoke: " + phase + " day " + lunarDay + " " + rule)
    if (phase && rule === "Rule: 1/8/15/22/29" && cells === 42 && sabbaths === 8 && moved)
      console.log("CalcSmoke: buildView OK")
    else
      console.log("CalcSmoke: buildView failed cells " + cells + " sabbaths " + sabbaths
        + " moved " + moved + " eclipses " + eclipsesMoved)
    Qt.quit()
  }
}
