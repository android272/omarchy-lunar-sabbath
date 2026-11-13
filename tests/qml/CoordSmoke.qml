import QtQuick
import "../../CoordField.qml"

Item {
  id: root
  width: 480
  height: 80

  CoordField {
    id: lat
    width: 220
    adornPrefix: "lat: "
  }

  CoordField {
    id: lon
    width: 220
    adornPrefix: "long: "
  }

  Timer {
    interval: 200
    running: true
    onTriggered: root.exercise()
  }

  function fail(detail) {
    console.log("CoordSmoke: " + detail)
    Qt.quit()
  }

  function exercise() {
    if (lat.text !== "lat: °" || lon.text !== "long: °")
      return fail("initial affixes " + lat.text + " | " + lon.text)
    lat.setValue(39.9843)
    lon.setValue(-118.2437)
    if (lat.text !== "lat: 39.9843°" || lat.body !== "39.9843")
      return fail("latitude display " + lat.text + " body " + lat.body)
    if (lon.text !== "long: -118.2437°" || lon.body !== "-118.2437")
      return fail("longitude display " + lon.text + " body " + lon.body)
    lat.setValue("")
    if (lat.text !== "lat: °" || lat.body !== "")
      return fail("cleared latitude " + lat.text)
    // insert() emits textEdited(), which is what a real keystroke does.
    var typed = "39.9843"
    var i
    for (i = 0; i < typed.length; i++)
      lat.insert(lat.cursorPosition, typed.charAt(i))
    if (lat.text !== "lat: 39.9843°" || lat.body !== "39.9843")
      return fail("typed decimal " + lat.text + " body " + lat.body)
    lat.insert(lat.cursorPosition, "a")
    if (lat.text !== "lat: 39.9843°")
      return fail("letter was kept " + lat.text)
    var caret = lat.cursorPosition
    lat.applyUserText("39.9843", 7)
    if (lat.text !== "lat: 39.9843°")
      return fail("bare paste " + lat.text)
    lat.applyUserText(lat.text.slice(0, lat.text.length - 1), lat.text.length - 1)
    if (lat.text !== "lat: 39.9843°")
      return fail("degree was deleted " + lat.text)
    lat.cursorPosition = 0
    if (lat.cursorPosition !== "lat: ".length)
      return fail("caret entered the prefix at " + lat.cursorPosition)
    lat.cursorPosition = lat.text.length
    if (lat.cursorPosition !== lat.text.length - 1)
      return fail("caret passed the degree at " + lat.cursorPosition)
    if (caret < "lat: ".length)
      return fail("edit left the caret in the prefix")
    console.log("CoordSmoke: affixes locked OK")
    Qt.quit()
  }
}
