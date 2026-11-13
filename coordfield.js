.pragma library

// Editable decimal degrees with a locked prefix and a trailing degree sign.
// The field text is always "<prefix><body>°". The body allows a leading
// minus, up to three integer digits, and up to six decimal places.

var DEGREE = "°"
var MAX_INT = 3
var MAX_FRAC = 6

function sanitizeBody(raw) {
  var s = String(raw == null ? "" : raw)
  var out = ""
  var seenDot = false
  var intDigits = 0
  var fracDigits = 0
  var i
  for (i = 0; i < s.length; i++) {
    var c = s.charAt(i)
    if (c === "-" && out === "") {
      out = "-"
    } else if (c >= "0" && c <= "9") {
      if (!seenDot) {
        if (intDigits >= MAX_INT) continue
        out += c
        intDigits++
      } else if (fracDigits < MAX_FRAC) {
        out += c
        fracDigits++
      }
    } else if (c === "." && !seenDot) {
      out += "."
      seenDot = true
    }
  }
  return out
}

function bodyFrom(text) {
  return sanitizeBody(String(text == null ? "" : text).split(DEGREE).join(""))
}

function formatBody(value) {
  if (value === null || value === undefined || value === "") return ""
  var n = Number(value)
  if (!isFinite(n)) return sanitizeBody(String(value))
  var sign = n < 0 ? "-" : ""
  var abs = Math.abs(n).toFixed(MAX_FRAC)
  if (abs.indexOf(".") >= 0)
    abs = abs.replace(/0+$/, "").replace(/\.$/, "")
  return sign + abs
}

function display(prefix, value) {
  return String(prefix || "") + formatBody(value) + DEGREE
}

function applyEdit(prefix, edited, cursor) {
  var body = bodyFrom(edited)
  var cut = Math.max(0, Number(cursor) || 0)
  var before = String(edited == null ? "" : edited).slice(0, cut)
  var lead = bodyFrom(before)
  if (body.indexOf(lead) !== 0)
    lead = body.slice(0, Math.min(lead.length, body.length))
  var pos = String(prefix || "").length + lead.length
  var text = String(prefix || "") + body + DEGREE
  var max = String(prefix || "").length + body.length
  if (pos > max) pos = max
  if (pos < String(prefix || "").length) pos = String(prefix || "").length
  return { text: text, cursor: pos, body: body }
}

function initialState(prefix) {
  var text = String(prefix || "") + DEGREE
  return {
    prefix: String(prefix || ""),
    text: text,
    cursor: String(prefix || "").length,
    bodyCursor: String(prefix || "").length
  }
}

function stateFromValue(prefix, value) {
  var text = display(prefix, value)
  var pos = String(prefix || "").length
  return { prefix: String(prefix || ""), text: text, cursor: pos, bodyCursor: pos }
}

// `state.text` is the last accepted field text. `edited` is the text after
// the user's change, which may have lost the prefix or the degree sign.
function editState(state, edited, cursor) {
  var next = applyEdit(state.prefix, edited, cursor)
  if (next.body === bodyFrom(state.text)) {
    return {
      prefix: state.prefix,
      text: state.text,
      cursor: state.bodyCursor,
      bodyCursor: state.bodyCursor
    }
  }
  return {
    prefix: state.prefix,
    text: next.text,
    cursor: next.cursor,
    bodyCursor: next.cursor
  }
}

function clampCursor(state, cursor) {
  var min = state.prefix.length
  var max = Math.max(min, state.text.length - DEGREE.length)
  var c = Number(cursor) || 0
  if (c < min) c = min
  if (c > max) c = max
  return { prefix: state.prefix, text: state.text, cursor: c, bodyCursor: c }
}
