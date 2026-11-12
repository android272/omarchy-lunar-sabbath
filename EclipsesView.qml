import QtQuick
import qs.Commons

Column {
  id: root

  property var eclipses: []
  spacing: Style.spacing.md
  width: parent ? parent.width : implicitWidth

  Text {
    width: parent.width
    visible: !root.eclipses || root.eclipses.length === 0
    text: "No eclipse found in the next year of this offline calculation."
    color: Color.popups.text
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Repeater {
    model: root.eclipses
    delegate: Rectangle {
      id: card
      required property var modelData
      width: root.width
      implicitHeight: body.implicitHeight + Style.space(18)
      radius: Style.space(6)
      color: Util.alpha(Color.popups.text, 0.05)
      border.width: 1
      border.color: Util.alpha(Color.popups.text, 0.16)

      Column {
        id: body
        width: parent.width - Style.space(20)
        anchors.centerIn: parent
        spacing: Style.space(3)

        Text {
          width: parent.width
          text: card.modelData.type
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          text: card.modelData.whenLabel
          color: Color.popups.text
          opacity: 0.85
          wrapMode: Text.WordWrap
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          text: card.modelData.countdown
            + " · " + card.modelData.magnitudeLabel
            + (card.modelData.durationLabel ? " · " + card.modelData.durationLabel : "")
          color: Color.popups.text
          opacity: 0.75
          wrapMode: Text.WordWrap
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
        Text {
          width: parent.width
          text: "Obscuration " + card.modelData.obscurationLabel
          color: Color.popups.text
          wrapMode: Text.WordWrap
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          text: card.modelData.visibility
          color: Color.popups.text
          opacity: 0.85
          wrapMode: Text.WordWrap
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          text: card.modelData.note
          color: Color.popups.text
          opacity: 0.55
          wrapMode: Text.WordWrap
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  Text {
    width: parent.width
    text: "Times are an offline approximation, usually within a few minutes. A solar eclipse's total or annular path is much narrower than the partial region."
    color: Color.popups.text
    opacity: 0.55
    wrapMode: Text.WordWrap
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
