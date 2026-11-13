import QtQuick
import qs.Ui as Ui
import "coordfield.js" as Coord

// Decimal degrees. The prefix and the trailing ° stay in the string and
// are put back if an edit removes them. The caret stays in the number.
Ui.TextField {
  id: root

  property string adornPrefix: "lat: "
  property string _stable: adornPrefix + "°"
  property int _bodyCursor: adornPrefix.length
  property bool _guard: false

  readonly property string body: Coord.bodyFrom(text)

  function publish(state) {
    _guard = true
    _stable = state.text
    text = state.text
    cursorPosition = state.cursor
    _bodyCursor = state.bodyCursor
    _guard = false
  }

  function currentState() {
    return {
      prefix: adornPrefix,
      text: _stable,
      cursor: cursorPosition,
      bodyCursor: _bodyCursor
    }
  }

  function setValue(value) {
    publish(Coord.stateFromValue(adornPrefix, value))
  }

  function applyUserText(edited, cursor) {
    if (_guard) return
    publish(Coord.editState(currentState(), edited, cursor))
  }

  function clampCaret() {
    var min = adornPrefix.length
    var max = Math.max(min, text.length - 1)
    var cursor = Math.max(min, Math.min(cursorPosition, max))
    if (cursor !== cursorPosition) {
      _guard = true
      cursorPosition = cursor
      _bodyCursor = cursor
      _guard = false
    } else {
      _bodyCursor = cursor
    }
    if (selectionStart >= min && selectionEnd <= max) return
    var start = Math.max(min, Math.min(selectionStart, max))
    var end = Math.max(min, Math.min(selectionEnd, max))
    _guard = true
    if (cursor === start)
      select(end, start)
    else
      select(start, end)
    if (cursorPosition !== cursor)
      cursorPosition = cursor
    _bodyCursor = cursorPosition
    _guard = false
  }

  text: _stable

  onAdornPrefixChanged: {
    if (_guard) return
    publish(Coord.stateFromValue(adornPrefix, Coord.bodyFrom(_stable)))
  }

  // textEdited() has no arguments on Qt 6. The property already holds the edit.
  onTextEdited: root.applyUserText(text, cursorPosition)

  onCursorPositionChanged: {
    if (root._guard) return
    if (root.text !== root._stable) return
    root.clampCaret()
  }
}
