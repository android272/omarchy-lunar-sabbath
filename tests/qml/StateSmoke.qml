import QtQuick
import "../../LunarModel.qml"

Item {
  id: root
  width: 20
  height: 20

  property bool started: false

  LunarModel {
    id: model
    onReadyChanged: {
      if (!model.ready || root.started) return
      root.started = true
      startTimer.start()
    }
  }

  Timer {
    id: startTimer
    interval: 300
    repeat: false
    onTriggered: root.exercise()
  }

  function exercise() {
    model.shellSettings = {
      sabbathRule: "week-saturday",
      displayMode: "letter",
      newMoonBasis: "crescent-1"
    }
    model.considerShellSeed()
    if (model.ruleId !== "week-saturday" || model.displayMode !== "letter" || model.basisId !== "crescent-1") {
      console.log("StateSmoke: seed was not applied " + model.ruleId + " " + model.displayMode + " " + model.basisId)
      Qt.quit()
      return
    }
    if (!model.preferShellSeed) {
      console.log("StateSmoke: seed locked too early")
      Qt.quit()
      return
    }
    model.setRule("days-7-14-21-28")
    model.shellSettings = {
      sabbathRule: "week-saturday",
      displayMode: "moon",
      newMoonBasis: "conjunction"
    }
    model.considerShellSeed()
    if (model.ruleId !== "days-7-14-21-28" || model.preferShellSeed) {
      console.log("StateSmoke: user rule was overwritten " + model.ruleId)
      Qt.quit()
      return
    }
    var saved = model.saveLocation("Runtime Test", "41.88", "-87.63", "America/Chicago")
    if (!saved || !model.locationConfigured || model.timeZone !== "America/Chicago") {
      console.log("StateSmoke: location rejected " + model.locationMessage)
      Qt.quit()
      return
    }
    console.log("StateSmoke: settings persisted OK")
    finishTimer.start()
  }

  Timer {
    id: finishTimer
    interval: 800
    repeat: false
    onTriggered: Qt.quit()
  }

  Timer {
    interval: 12000
    running: true
    onTriggered: {
      console.log("StateSmoke: timed out ready " + model.ready)
      Qt.quit()
    }
  }
}
