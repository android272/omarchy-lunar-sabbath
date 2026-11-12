import QtQuick
import "../../MoonDisk.qml"

Item {
  id: root
  width: 500
  height: 120

  property bool quarterReady: false
  property bool sabbathReady: false
  property bool fullReady: false
  property bool newReady: false
  property bool crescentReady: false
  property bool checked: false

  function noteQuarter() {
    if (quarter.width < 40) return
    root.quarterReady = true
    root.maybeSample()
  }

  function noteSabbath() {
    if (sabbath.width < 40) return
    root.sabbathReady = true
    root.maybeSample()
  }

  function noteFull() {
    if (fullMoon.width < 40) return
    root.fullReady = true
    root.maybeSample()
  }

  function noteNew() {
    if (newMoon.width < 40) return
    root.newReady = true
    root.maybeSample()
  }

  function noteCrescent() {
    if (crescent.width < 40) return
    root.crescentReady = true
    root.maybeSample()
  }

  function maybeSample() {
    if (!root.quarterReady || !root.sabbathReady || !root.fullReady || !root.newReady
        || !root.crescentReady || root.checked)
      return
    root.checked = true
    sampleTimer.start()
  }

  function bright(px) {
    return px && px.a > 200 && px.r > 180 && px.g > 160
  }

  function dark(px) {
    return px && px.a > 200 && px.r < 70 && px.g < 80 && px.b < 90
  }

  function goldish(px) {
    return px && px.a > 200 && px.r > 180 && px.g > 120 && px.b < 140
  }

  function clear(px) {
    return px && px.a < 24
  }

  function expect(failures, name, ok) {
    if (!ok) failures.push(name)
  }

  function verify() {
    var right = quarter.sample(0.72, 0.5)
    var left = quarter.sample(0.28, 0.5)
    var limb = quarter.sample(0.04, 0.5)
    var gold = sabbath.sample(0.72, 0.5)
    var fullCenter = fullMoon.sample(0.5, 0.5)
    var fullRight = fullMoon.sample(0.82, 0.5)
    var fullBottom = fullMoon.sample(0.5, 0.82)
    var fullCorner = fullMoon.sample(0.02, 0.02)
    var newCenter = newMoon.sample(0.5, 0.5)
    var newLimb = newMoon.sample(0.062, 0.5)
    var newInside = newMoon.sample(0.28, 0.5)
    var crescentLimb = crescent.sample(0.062, 0.5)
    console.log("RenderSmoke: dpr " + Screen.devicePixelRatio
      + " right " + JSON.stringify(right)
      + " left " + JSON.stringify(left)
      + " limb " + JSON.stringify(limb)
      + " gold " + JSON.stringify(gold)
      + " full " + JSON.stringify(fullCenter)
      + " " + JSON.stringify(fullRight)
      + " " + JSON.stringify(fullBottom)
      + " corner " + JSON.stringify(fullCorner)
      + " new " + JSON.stringify(newCenter)
      + " " + JSON.stringify(newLimb)
      + " " + JSON.stringify(newInside)
      + " crescent limb " + JSON.stringify(crescentLimb))
    var failures = []
    root.expect(failures, "quarter right lit", root.bright(right))
    root.expect(failures, "quarter left dark", root.dark(left))
    root.expect(failures, "quarter has no ring", !root.bright(limb))
    root.expect(failures, "sabbath lit gold", root.goldish(gold))
    root.expect(failures, "full center", root.bright(fullCenter))
    root.expect(failures, "full right", root.bright(fullRight))
    root.expect(failures, "full bottom", root.bright(fullBottom))
    root.expect(failures, "full corner clear", root.clear(fullCorner))
    root.expect(failures, "new center dark", root.dark(newCenter))
    root.expect(failures, "new rim", root.bright(newLimb))
    root.expect(failures, "new interior dark", root.dark(newInside))
    root.expect(failures, "crescent has no ring", !root.bright(crescentLimb))
    if (failures.length === 0)
      console.log("RenderSmoke: quarter disk lit on the right OK")
    else
      console.log("RenderSmoke: pixel check failed: " + failures.join(", "))
    Qt.quit()
  }

  MoonDisk {
    id: quarter
    x: 8
    y: 16
    size: 80
    phaseAngleDeg: 90
    litColor: "#f4f1ea"
    shadowColor: "#14181c"
    rimColor: "#f4f1ea"
    onPainted: root.noteQuarter()
  }

  MoonDisk {
    id: sabbath
    x: 100
    y: 16
    size: 80
    phaseAngleDeg: 90
    sabbath: true
    litColor: "#f4f1ea"
    shadowColor: "#14181c"
    rimColor: "#f4f1ea"
    onPainted: root.noteSabbath()
  }

  MoonDisk {
    id: fullMoon
    x: 192
    y: 16
    size: 80
    phaseAngleDeg: 180
    litColor: "#f4f1ea"
    shadowColor: "#14181c"
    rimColor: "#f4f1ea"
    onPainted: root.noteFull()
  }

  MoonDisk {
    id: newMoon
    x: 284
    y: 16
    size: 80
    phaseAngleDeg: 7.2
    litColor: "#f4f1ea"
    shadowColor: "#14181c"
    rimColor: "#f4f1ea"
    onPainted: root.noteNew()
  }

  MoonDisk {
    id: crescent
    x: 376
    y: 16
    size: 80
    phaseAngleDeg: 20
    litColor: "#f4f1ea"
    shadowColor: "#14181c"
    rimColor: "#f4f1ea"
    onPainted: root.noteCrescent()
  }

  Timer {
    id: sampleTimer
    interval: 200
    repeat: false
    onTriggered: root.verify()
  }

  Timer {
    interval: 8000
    running: true
    onTriggered: {
      console.log("RenderSmoke: timed out")
      Qt.quit()
    }
  }
}
