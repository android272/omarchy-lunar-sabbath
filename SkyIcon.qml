import QtQuick

// Small horizon marks for the Tonight rise / set / altitude row.
// Drawn in a 24-unit grid, same shapes as the Moonshot observer icons.
Item {
  id: root

  property string name: ""
  property real size: 18
  property color color: "white"
  property real strokeWidth: 1.8

  implicitWidth: size
  implicitHeight: size

  onNameChanged: canvas.requestPaint()
  onColorChanged: canvas.requestPaint()
  onStrokeWidthChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate

    onPaint: {
      var ctx = getContext("2d")
      if (!ctx) return
      ctx.reset()
      if (width <= 0 || height <= 0) return

      var scale = Math.min(width, height) / 24.0
      ctx.save()
      ctx.translate((width - 24 * scale) / 2, (height - 24 * scale) / 2)
      ctx.scale(scale, scale)
      ctx.strokeStyle = root.color
      ctx.fillStyle = root.color
      ctx.lineWidth = root.strokeWidth
      ctx.lineCap = "round"
      ctx.lineJoin = "round"

      if (root.name === "rise" || root.name === "set") {
        ctx.beginPath()
        ctx.moveTo(4, 18.5)
        ctx.lineTo(20, 18.5)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(12, 18.5, 5.5, Math.PI, Math.PI * 2)
        ctx.stroke()
        ctx.beginPath()
        if (root.name === "rise") {
          ctx.moveTo(12, 14)
          ctx.lineTo(12, 4)
          ctx.moveTo(8.5, 7.5)
          ctx.lineTo(12, 4)
          ctx.lineTo(15.5, 7.5)
        } else {
          ctx.moveTo(12, 4)
          ctx.lineTo(12, 14)
          ctx.moveTo(8.5, 10.5)
          ctx.lineTo(12, 14)
          ctx.lineTo(15.5, 10.5)
        }
        ctx.stroke()
      } else if (root.name === "horizon") {
        ctx.beginPath()
        ctx.arc(12, 16.5, 6.5, Math.PI, Math.PI * 2)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(3, 18.5)
        ctx.lineTo(21, 18.5)
        ctx.stroke()
      }
      ctx.restore()
    }
  }
}
