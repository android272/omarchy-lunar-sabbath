import QtQuick
import "../../LunarModel.qml"
import "../../TonightView.qml"
import "../../CalendarView.qml"
import "../../CycleView.qml"
import "../../SabbathsView.qml"
import "../../EclipsesView.qml"
import "../../SettingsView.qml"
import "../../HotkeysView.qml"

Item {
  id: root
  width: 480
  height: 720

  property string pickedIso: ""

  LunarModel { id: model }

  TonightView {
    width: 460
    day: model.view ? model.view.selected : null
    phases: model.view ? model.view.phases : []
    viewingToday: model.view ? model.view.isToday : true
    basisFooter: model.view && model.view.basis ? model.view.basis.footer : ""
  }

  CalendarView {
    width: 460
    calendar: model.view ? model.view.calendar : null
  }

  CycleView {
    id: cycleView
    width: 460
    cycle: model.view ? model.view.cycle : null
    onPickDate: function (iso) {
      root.pickedIso = iso
    }
  }

  SabbathsView {
    width: 460
    sabbaths: model.view ? model.view.sabbaths : []
    ruleShort: model.view && model.view.rule ? model.view.rule.short : ""
  }

  EclipsesView {
    width: 460
    eclipses: model.view ? model.view.eclipses : []
  }

  HotkeysView {
    width: 460
  }

  SettingsView {
    width: 460
    model: model
    ruleId: model.ruleId
    basisId: model.basisId
    explanation: model.view && model.view.rule ? model.view.rule.explanation : ""
    locationConfigured: model.locationConfigured
    locationLabel: model.locationLabel
    savedLocations: model.savedLocations
    message: model.locationMessage
  }

  Timer {
    interval: 4000
    running: true
    onTriggered: {
      var phase = model.view && model.view.now ? model.view.now.phaseName : ""
      var cells = model.view && model.view.calendar && model.view.calendar.cells
        ? model.view.calendar.cells.length : 0
      var strip = cycleView.phaseStripOk()
      var alignment = cycleView.phaseDatesOk()
      var cards = cycleView.phaseCardsOk()
      var dates = cycleView.phaseDates.length === 5
        && cycleView.phaseDates.every(function (mark) { return mark.dateLabel })
      var picked = false
      if (cycleView.phaseDates.length > 2) {
        var target = cycleView.phaseDates[2].iso
        cycleView.activatePhase(2)
        picked = root.pickedIso === target
      }
      if (model.ready && phase && cells === 42 && strip && alignment && cards && dates && picked)
        console.log("PartsSmoke: views loaded OK " + phase)
      else
        console.log("PartsSmoke: views failed ready " + model.ready + " cells " + cells
          + " strip " + strip + " alignment " + alignment + " cards " + cards
          + " dates " + dates + " picked " + picked)
      Qt.quit()
    }
  }
}
