import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string label: ""
  property string icon: ""
  property bool selected: false
  property bool gold: false
  property bool fillWidth: false
  property string accessibleName: ""
  signal clicked()

  readonly property bool hasIcon: icon !== ""
  readonly property bool hasLabel: label !== ""
  // A row of moon glyphs paints about 0.26em past each advance and fuses.
  // Tracking of 5 scaled px separates waxing, full, and waning.
  readonly property int iconCount: {
    if (!hasIcon) return 0
    var count = 0
    for (var i = 0; i < icon.length; ) {
      var cp = icon.codePointAt(i)
      count++
      i += cp > 0xFFFF ? 2 : 1
    }
    return count
  }
  readonly property real iconTracking: iconCount > 1 ? Style.space(5) : 0
  readonly property real labelGap: (hasIcon && hasLabel) ? Style.spacing.xs : 0
  readonly property real iconInkLeft: {
    if (!hasIcon) return 0
    return Math.min(0, iconMetrics.tightBoundingRect.x)
  }
  readonly property real iconInkRight: {
    if (!hasIcon) return 0
    var rect = iconMetrics.tightBoundingRect
    var right = rect.x + rect.width
    if (right - iconInkLeft < 1) return Math.max(iconMetrics.width, 1)
    return right
  }
  readonly property real iconSlotWidth: iconInkRight - iconInkLeft
  readonly property real iconDrawX: hasIcon ? -iconInkLeft : 0
  readonly property real labelBudget: {
    var pad = Style.space(12)
    var iconSpace = hasIcon ? iconSlotWidth + labelGap : 0
    return Math.max(0, width - pad - iconSpace)
  }

  implicitHeight: {
    var textH = hasLabel ? labelText.implicitHeight : 0
    var iconH = hasIcon ? iconText.implicitHeight : 0
    return Math.max(Style.space(28), Math.max(textH, iconH) + Style.space(10))
  }
  implicitWidth: {
    if (hasIcon && !hasLabel)
      return Math.max(implicitHeight, iconMetrics.width + Style.space(14))
    var core = hasLabel ? labelText.implicitWidth : 0
    if (hasIcon) core += iconSlotWidth + labelGap
    return core + Style.space(18)
  }
  width: fillWidth ? (parent ? parent.width : implicitWidth) : implicitWidth
  radius: Style.space(5)
  color: mouse.containsMouse || selected
    ? Util.alpha(edge, selected ? 0.22 : 0.1)
    : Util.alpha(Color.popups.text, 0.05)
  border.width: 1
  border.color: selected ? edge : Util.alpha(Color.popups.text, 0.2)

  readonly property color edge: gold ? "#e0b44c" : Color.popups.text

  TextMetrics {
    id: iconMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.icon
    font.letterSpacing: root.iconTracking
    text: root.icon
  }

  Item {
    id: content
    anchors.centerIn: parent
    readonly property real iconH: root.hasIcon ? iconText.implicitHeight : 0
    readonly property real labelH: root.hasLabel ? labelText.implicitHeight : 0
    width: iconBox.width + root.labelGap + (root.hasLabel ? labelText.width : 0)
    height: Math.max(iconH, labelH)

    Item {
      id: iconBox
      width: root.hasIcon ? root.iconSlotWidth : 0
      height: content.iconH
      y: (content.height - height) / 2
      visible: root.hasIcon

      Text {
        id: iconText
        x: root.iconDrawX
        visible: root.hasIcon
        textFormat: Text.PlainText
        text: root.icon
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.icon
        font.letterSpacing: root.iconTracking
        renderType: Text.NativeRendering
      }
    }

    Text {
      id: labelText
      x: iconBox.width + root.labelGap
      y: (content.height - height) / 2
      visible: root.hasLabel
      width: Math.min(implicitWidth, root.labelBudget)
      text: root.label
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: root.selected
      horizontalAlignment: root.hasIcon ? Text.AlignLeft : Text.AlignHCenter
      elide: Text.ElideRight
    }
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
