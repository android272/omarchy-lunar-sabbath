import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property bool selected: false
  property bool gold: false
  property bool fillWidth: false
  property string accessibleName: ""
  signal clicked()

  implicitHeight: Math.max(Style.space(28), labelText.implicitHeight + Style.space(10))
  implicitWidth: labelText.implicitWidth + Style.space(18)
  width: fillWidth ? (parent ? parent.width : implicitWidth) : implicitWidth
  radius: Style.space(5)
  color: mouse.containsMouse || selected
    ? Util.alpha(edge, selected ? 0.22 : 0.1)
    : Util.alpha(Color.popups.text, 0.05)
  border.width: 1
  border.color: selected ? edge : Util.alpha(Color.popups.text, 0.2)

  readonly property color edge: gold ? "#e0b44c" : Color.popups.text

  Text {
    id: labelText
    anchors.centerIn: parent
    width: Math.max(0, root.width - Style.space(12))
    text: root.label
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    font.bold: root.selected
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName !== "" ? accessibleName : label
  Accessible.onPressAction: root.clicked()
}
