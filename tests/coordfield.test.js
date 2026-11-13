const fs = require("fs")
const path = require("path")
const vm = require("vm")

const source = fs.readFileSync(path.join(__dirname, "..", "coordfield.js"), "utf8")
  .replace(/^[\s\uFEFF]*\.pragma library;?\s*/, "")
const context = { console, Math, Date, Number, String, isFinite, isNaN }
vm.createContext(context)
vm.runInContext(source, context)

let failed = 0
function check(name, cond, detail) {
  if (cond) {
    console.log("ok  " + name)
    return
  }
  failed += 1
  console.error("FAIL " + name + (detail ? " — " + detail : ""))
}

function typeChar(state, ch) {
  const at = state.bodyCursor
  const edited = state.text.slice(0, at) + ch + state.text.slice(at)
  return context.editState(state, edited, at + ch.length)
}

function typeString(state, s) {
  let next = state
  for (const ch of s) next = typeChar(next, ch)
  return next
}

function backspace(state) {
  const at = state.bodyCursor
  if (at <= 0) return state
  const edited = state.text.slice(0, at - 1) + state.text.slice(at)
  return context.editState(state, edited, at - 1)
}

function deleteForward(state) {
  const at = state.bodyCursor
  if (at >= state.text.length) return state
  const edited = state.text.slice(0, at) + state.text.slice(at + 1)
  return context.editState(state, edited, at)
}

check("empty latitude", context.display("lat: ", "") === "lat: °")
check("empty longitude", context.display("long: ", null) === "long: °")
check("decimal latitude", context.display("lat: ", 39.9843) === "lat: 39.9843°")
check("decimal longitude", context.display("long: ", -118.2437) === "long: -118.2437°")
check("west of Greenwich", context.display("long: ", -0.1278) === "long: -0.1278°")
check("integer trims zeros", context.display("lat: ", 32) === "lat: 32°")
check("jerusalem", context.display("lat: ", 31.7683) === "lat: 31.7683°")
check("honolulu", context.display("long: ", -157.8583) === "long: -157.8583°")

const samples = [39.9843, -118.2437, -0.1278, 31.7683, 35.2137, -157.8583, 51.5074, 0, -90, 180]
for (const n of samples) {
  check("round trip " + n, Number(context.formatBody(n)) === n, context.formatBody(n))
}

let lat = context.initialState("lat: ")
check("initial caret", lat.text === "lat: °" && lat.cursor === 5)
lat = typeString(lat, "39.9843")
check("typed decimal", lat.text === "lat: 39.9843°" && lat.cursor === "lat: 39.9843".length, lat.text + " @" + lat.cursor)

lat = typeString(lat, "12")
check("six decimal places", lat.text === "lat: 39.984312°", lat.text)
lat = typeChar(lat, "9")
check("seventh decimal rejected", lat.text === "lat: 39.984312°" && lat.cursor === "lat: 39.984312".length)

lat = context.stateFromValue("lat: ", 39.9843)
lat = typeChar(lat, "a")
check("letter rejected", lat.text === "lat: 39.9843°")

lat = context.clampCursor(lat, 0)
check("home stays out of prefix", lat.cursor === 5 && lat.text === "lat: 39.9843°")
lat = backspace(lat)
check("backspace does not eat prefix", lat.text === "lat: 39.9843°" && lat.cursor === 5)

lat = context.clampCursor(lat, lat.text.length)
check("end sits before degree", lat.cursor === lat.text.length - 1)
const end = lat.cursor
lat = deleteForward(lat)
check("delete does not eat degree", lat.text === "lat: 39.9843°" && lat.cursor === end)

lat = typeString(context.initialState("lat: "), "39.98")
lat = typeChar(lat, ".")
check("second point rejected", lat.text === "lat: 39.98°", lat.text)

lat = typeString(context.initialState("lat: "), "-33.9249")
check("leading minus", lat.text === "lat: -33.9249°", lat.text)

let lon = typeString(context.initialState("long: "), "116")
lon = typeChar(lon, "4")
check("fourth integer digit rejected", lon.text === "long: 116°", lon.text)

lon = context.editState(lon, "", 0)
check("clearing the field keeps the affixes", lon.text === "long: °" && lon.cursor === 6, lon.text)

lon = context.editState(context.stateFromValue("long: ", -118.2437), "long: -118.2437", 16)
check("degree is restored when deleted", lon.text === "long: -118.2437°", lon.text)

lon = context.editState(context.initialState("lat: "), "39.9843", 7)
check("paste of a bare decimal keeps the prefix", lon.text === "lat: 39.9843°" && lon.cursor === "lat: 39.9843".length, lon.text + " @" + lon.cursor)

lon = context.editState(context.initialState("lat: "), "lat: 39.9843°", "lat: 39.9843°".length)
check("paste of a decorated decimal", lon.text === "lat: 39.9843°", lon.text)

const midway = typeString(context.initialState("lat: "), "3943")
check("four digits cap at three", midway.text === "lat: 394°", midway.text)

if (failed) {
  console.error(failed + " failed")
  process.exit(1)
}
console.log("coordfield: OK")
