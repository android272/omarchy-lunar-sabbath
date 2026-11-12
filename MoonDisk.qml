import QtQuick
import qs.Commons

// North-up moon diagram. Waxing light is on the right, waning light on the left.
// Qt sizes the canvas image for the screen pixel ratio and paints in item
// coordinates. Growing canvasSize or scaling the context again crops the disk
// to the top-left and turns on tiled rendering, which can show a torn frame.
Item {
  id: root

  property real phaseAngleDeg: 0
  property real size: 24
  property color litColor: Color.popups.text
  property color shadowColor: Color.popups.background
  property color rimColor: Color.popups.text
  property bool sabbath: false
  readonly property color gold: "#e0b44c"

  signal painted()

  implicitWidth: size
  implicitHeight: size
  Accessible.role: Accessible.Graphic
  Accessible.name: sabbath ? "Sabbath moon" : "Moon phase"

  onPhaseAngleDegChanged: canvas.requestPaint()
  onLitColorChanged: canvas.requestPaint()
  onShadowColorChanged: canvas.requestPaint()
  onRimColorChanged: canvas.requestPaint()
  onSabbathChanged: canvas.requestPaint()

  function normalizedAngle(angleDeg) {
    return ((angleDeg % 360) + 360) % 360
  }

  // New Moon in lunar.js is within 11 degrees of conjunction. The crescent
  // is still too thin to show the disk, so the rim is the empty moon.
  function isNewMoon(angleDeg) {
    var angle = normalizedAngle(angleDeg)
    return angle < 11 || angle >= 349
  }

  function sample(nx, ny) {
    var ctx = canvas.getContext("2d")
    if (!ctx || width < 2 || height < 2) return null
    // getImageData addresses the backing image in device pixels.
    var ratio = Screen.devicePixelRatio || 1
    var x = Math.round(nx * (width * ratio - 1))
    var y = Math.round(ny * (height * ratio - 1))
    var pixel = null
    try {
      pixel = ctx.getImageData(x, y, 1, 1).data
    } catch (e) {
      return null
    }
    if (!pixel) return null
    return { r: pixel[0], g: pixel[1], b: pixel[2], a: pixel[3] }
  }

  function traceLit(ctx, cx, cy, r, angleDeg) {
    if (isNewMoon(angleDeg)) return false
    var angle = normalizedAngle(angleDeg)
    if (Math.abs(angle - 180) <= 0.6) {
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.closePath()
      return true
    }
    var waxing = angle < 180
    var cosAngle = Math.cos(angle * Math.PI / 180)
    var tx = (waxing ? cosAngle : -cosAngle) * r
    var k = 0.5522847498
    ctx.beginPath()
    ctx.moveTo(cx, cy - r)
    ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, !waxing)
    ctx.bezierCurveTo(cx + k * tx, cy + r, cx + tx, cy + k * r, cx + tx, cy)
    ctx.bezierCurveTo(cx + tx, cy - k * r, cx + k * tx, cy - r, cx, cy - r)
    ctx.closePath()
    return true
  }

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
      var side = Math.min(width, height)
      if (side < 1) {
        root.painted()
        return
      }
      ctx.clearRect(0, 0, width, height)
      var r = side * 0.46
      var cx = width / 2
      var cy = height / 2
      var lit = root.sabbath ? root.gold : root.litColor
      var rim = root.sabbath ? root.gold : root.rimColor

      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.closePath()
      ctx.fillStyle = root.shadowColor
      ctx.fill()

      ctx.save()
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.clip()
      if (root.traceLit(ctx, cx, cy, r, root.phaseAngleDeg)) {
        ctx.fillStyle = lit
        ctx.fill()
      }
      ctx.restore()

      if (root.isNewMoon(root.phaseAngleDeg)) {
        // A 1px stroke disappears into the bar icon. Keep the ring inside the disk.
        var rimWidth = Math.max(1.8, side * 0.055)
        ctx.beginPath()
        ctx.arc(cx, cy, r - rimWidth / 2, 0, Math.PI * 2)
        ctx.lineWidth = rimWidth
        ctx.strokeStyle = rim
        ctx.stroke()
      }
      root.painted()
    }
  }
}
