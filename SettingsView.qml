import QtQuick
import qs.Commons
import qs.Ui as Ui
import "cities.js" as Cities

Column {
  id: root

  property var model: null
  property string ruleId: ""
  property string basisId: ""
  property string explanation: ""
  property bool locationConfigured: false
  property string locationLabel: ""
  property var savedLocations: []
  property string message: ""
  readonly property bool typing: labelField.activeFocus || latField.activeFocus
    || lonField.activeFocus || zoneField.activeFocus || cityField.activeFocus

  signal ruleChosen(string id)
  signal basisChosen(string id)
  signal locationSubmitted(string label, string latitude, string longitude, string zone)
  signal savedActivated(var place)
  signal locationCleared()
  signal closeRequested()

  function syncFields(force) {
    if (!root.model || (root.typing && !force)) return
    labelField.text = root.locationConfigured ? root.locationLabel : ""
    latField.text = root.model.latitude === null || root.model.latitude === undefined || !root.locationConfigured
      ? "" : String(root.model.latitude)
    lonField.text = root.model.longitude === null || root.model.longitude === undefined || !root.locationConfigured
      ? "" : String(root.model.longitude)
    zoneField.text = root.locationConfigured ? root.model.timeZone : ""
    cityField.text = ""
  }

  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  Row {
    width: parent.width
    TextButton { label: "Back"; onClicked: root.closeRequested() }
  }

  Text {
    width: parent.width
    text: "Sabbath rule"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }

  Repeater {
    model: [
      { id: "days-8-15-22-29", label: "New moon day 1, Sabbaths 8 / 15 / 22 / 29" },
      { id: "days-7-14-21-28", label: "Sabbaths 7 / 14 / 21 / 28" },
      { id: "week-saturday", label: "Continuous week (Saturday)" }
    ]
    delegate: TextButton {
      required property var modelData
      fillWidth: true
      label: modelData.label
      selected: root.ruleId === modelData.id
      gold: root.ruleId === modelData.id
      onClicked: root.ruleChosen(modelData.id)
    }
  }

  Text {
    width: parent.width
    text: root.explanation
    color: Color.popups.text
    opacity: 0.8
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Text {
    width: parent.width
    visible: root.ruleId === "week-saturday"
    text: "This comparison rule uses Saturday and ignores the new-moon basis."
    color: Color.popups.text
    opacity: 0.65
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    width: parent.width
    text: "New moon basis"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }

  Repeater {
    model: [
      { id: "conjunction", label: "Calculated conjunction" },
      { id: "crescent-1", label: "First visible crescent, +1 day" },
      { id: "crescent-2", label: "First visible crescent, +2 days" }
    ]
    delegate: TextButton {
      required property var modelData
      fillWidth: true
      label: modelData.label
      selected: root.basisId === modelData.id
      onClicked: root.basisChosen(modelData.id)
    }
  }

  Text {
    width: parent.width
    text: "Lunar day 1 is a local calendar date. Days change at midnight, not at sunset, so the count works without a location."
    color: Color.popups.text
    opacity: 0.6
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    width: parent.width
    text: "Location"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
  }

  Text {
    width: parent.width
    text: root.locationConfigured
      ? ("Active: " + root.locationLabel)
      : "No active location. Phase and Sabbath use this computer's timezone."
    color: Color.popups.text
    opacity: 0.75
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Ui.TextField {
    id: cityField
    width: parent.width
    placeholderText: "Search cities"
    foreground: Color.popups.text
    placeholderTextColor: Util.alpha(Color.popups.text, 0.45)
  }

  Repeater {
    model: Cities.search(cityField.text)
    delegate: TextButton {
      required property var modelData
      fillWidth: true
      label: modelData.name + ", " + modelData.region
      onClicked: root.locationSubmitted(modelData.name, String(modelData.latitude), String(modelData.longitude), modelData.timeZone)
    }
  }

  Ui.TextField {
    id: labelField
    width: parent.width
    placeholderText: "Place name"
    foreground: Color.popups.text
    placeholderTextColor: Util.alpha(Color.popups.text, 0.45)
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm
    Ui.TextField {
      id: latField
      width: (parent.width - parent.spacing) / 2
      placeholderText: "Latitude"
      foreground: Color.popups.text
      placeholderTextColor: Util.alpha(Color.popups.text, 0.45)
    }
    Ui.TextField {
      id: lonField
      width: (parent.width - parent.spacing) / 2
      placeholderText: "Longitude"
      foreground: Color.popups.text
      placeholderTextColor: Util.alpha(Color.popups.text, 0.45)
    }
  }

  Ui.TextField {
    id: zoneField
    width: parent.width
    placeholderText: "IANA timezone, such as Asia/Jerusalem"
    foreground: Color.popups.text
    placeholderTextColor: Util.alpha(Color.popups.text, 0.45)
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm
    TextButton {
      label: "Save location"
      onClicked: root.locationSubmitted(labelField.text, latField.text, lonField.text, zoneField.text)
    }
    TextButton {
      label: "Clear active"
      onClicked: root.locationCleared()
    }
  }

  Text {
    width: parent.width
    visible: root.message !== ""
    text: root.message
    color: Color.popups.text
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    width: parent.width
    visible: root.savedLocations && root.savedLocations.length > 0
    text: "Saved places"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    font.bold: true
  }

  Repeater {
    model: root.savedLocations
    delegate: TextButton {
      required property var modelData
      fillWidth: true
      label: modelData.locationLabel + " · " + modelData.timeZone
      onClicked: root.savedActivated(modelData)
    }
  }
}
