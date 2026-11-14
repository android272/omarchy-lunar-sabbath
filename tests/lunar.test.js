const fs = require("fs")
const path = require("path")
const vm = require("vm")

const source = fs.readFileSync(path.join(__dirname, "..", "lunar.js"), "utf8")
  .replace(/^[\s\uFEFF]*\.pragma library;?\s*/, "")
const context = { console, Math, Date, Intl, Number, String, isFinite, isNaN }
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

function near(actual, expected, tol, name) {
  const delta = Math.abs(actual - expected)
  check(name, delta <= tol, "got " + actual + " expected " + expected + " ± " + tol)
  return delta
}

const tutorialJd = Date.UTC(1990, 3, 19, 0, 0, 0)
const tutorial = context.bodies(context.jdFromUnixMs(tutorialJd))
near(tutorial.sunLon, 28.6869, 0.03, "sun longitude 1990-04-19")
near(tutorial.sunR, 1.004323, 0.0002, "sun distance 1990-04-19")
near(tutorial.moonLon, 306.9484, 0.03, "moon longitude 1990-04-19")
near(tutorial.moonLat, -0.5856, 0.03, "moon latitude 1990-04-19")
near(tutorial.moonR, 60.6779, 0.05, "moon distance 1990-04-19")

const cases = [
  ["days-8-15-22-29", 1, 30, 0, false, "special"],
  ["days-8-15-22-29", 8, 30, 3, true, "sabbath"],
  ["days-8-15-22-29", 15, 29, 6, true, "sabbath"],
  ["days-8-15-22-29", 22, 30, 1, true, "sabbath"],
  ["days-8-15-22-29", 29, 30, 2, true, "sabbath"],
  ["days-8-15-22-29", 30, 30, 4, false, "transition"],
  ["days-8-15-22-29", 7, 30, 6, false, "ordinary"],
  ["days-7-14-21-28", 7, 30, 0, true, "sabbath"],
  ["days-7-14-21-28", 14, 29, 1, true, "sabbath"],
  ["days-7-14-21-28", 21, 30, 2, true, "sabbath"],
  ["days-7-14-21-28", 28, 30, 3, true, "sabbath"],
  ["days-7-14-21-28", 1, 30, 6, false, "ordinary"],
  ["days-7-14-21-28", 8, 30, 4, false, "ordinary"],
  ["days-7-14-21-28", 29, 29, 5, false, "ordinary"],
  ["week-saturday", 3, 30, 6, true, "sabbath"],
  ["week-saturday", 15, 30, 5, false, "ordinary"],
  ["week-saturday", 1, 29, 6, true, "sabbath"]
]
for (const item of cases) {
  const status = context.dayStatus(item[0], item[1], item[2], item[3])
  check(
    item[0] + " day " + item[1] + " weekday " + item[3],
    status.isSabbath === item[4] && status.kind === item[5],
    JSON.stringify(status)
  )
}

function minutesFrom(isoUtc, jd) {
  const expected = Date.parse(isoUtc)
  return (context.unixMsFromJd(jd) - expected) / 60000
}

const windowStart = context.jdFromUnixMs(Date.parse("2026-01-01T00:00:00Z"))
const events = context.eclipsesBetween(windowStart, windowStart + 280)
function findNear(iso, kind) {
  const target = Date.parse(iso)
  return events.find((event) => event.kind === kind && Math.abs(context.unixMsFromJd(event.jd) - target) < 36 * 3600000)
}

const solarAug = findNear("2026-08-12T17:46:00Z", "solar")
const lunarMar = findNear("2026-03-03T11:35:00Z", "lunar")
const lunarAug = findNear("2026-08-28T04:14:00Z", "lunar")
const solarFeb = findNear("2026-02-17T12:12:00Z", "solar")
check("found 2026-08-12 solar", !!solarAug, events.map((e) => e.kind + " " + new Date(context.unixMsFromJd(e.jd)).toISOString() + " " + e.type).join(" | "))
check("found 2026-03-03 lunar", !!lunarMar)
check("found 2026-08-28 lunar", !!lunarAug)
check("found 2026-02-17 solar", !!solarFeb)
if (solarAug) {
  near(minutesFrom("2026-08-12T17:45:54Z", solarAug.jd), 0, 20, "2026-08-12 greatest eclipse minutes")
  check("2026-08-12 total", solarAug.type.indexOf("Total") === 0, solarAug.type)
  check("2026-08-12 obscuration", solarAug.obscuration > 0.95, String(solarAug.obscuration))
}
if (lunarMar) {
  near(minutesFrom("2026-03-03T11:34:52Z", lunarMar.jd), 0, 20, "2026-03-03 greatest eclipse minutes")
  check("2026-03-03 total lunar", lunarMar.type.indexOf("Total") === 0, lunarMar.type)
}
if (lunarAug) {
  near(minutesFrom("2026-08-28T04:14:04Z", lunarAug.jd), 0, 25, "2026-08-28 greatest eclipse minutes")
  check("2026-08-28 partial lunar", lunarAug.type.indexOf("Partial") === 0, lunarAug.type)
}
if (solarFeb) {
  near(minutesFrom("2026-02-17T12:12:00Z", solarFeb.jd), 0, 25, "2026-02-17 greatest eclipse minutes")
  check("2026-02-17 annular", solarFeb.type.indexOf("Annular") === 0, solarFeb.type)
}

const fullIllum = context.illuminationOf(lunarMar ? lunarMar.jd : context.jdFromUnixMs(Date.parse("2026-03-03T11:35:00Z")))
const newIllum = context.illuminationOf(solarAug ? solarAug.jd : context.jdFromUnixMs(Date.parse("2026-08-12T17:46:00Z")))
check("full moon illumination", fullIllum > 0.98, String(fullIllum))
check("new moon illumination", newIllum < 0.02, String(newIllum))

const reykjavik = solarAug ? context.localSolarSeparation(solarAug.jd, 64.1466, -21.9426) : null
const london = solarAug ? context.localSolarSeparation(solarAug.jd, 51.5074, -0.1278) : null
const sydney = solarAug ? context.localSolarSeparation(solarAug.jd, -33.8688, 151.2093) : null
if (reykjavik && london && sydney) {
  console.log("local sep Reykjavik " + reykjavik.separation.toFixed(3) + " sunUp " + reykjavik.sunUp
    + " London " + london.separation.toFixed(3) + " sunUp " + london.sunUp
    + " Sydney " + sydney.separation.toFixed(3) + " sunUp " + sydney.sunUp)
  check("Reykjavik closer than London", reykjavik.separation < london.separation)
  check("Reykjavik sun up and deep", reykjavik.sunUp && reykjavik.separation < 0.15, String(reykjavik.separation))
  check("Sydney misses totality", sydney.separation > reykjavik.separation)
}

const view = context.buildView({
  nowMs: Date.parse("2026-11-05T18:00:00Z"),
  ruleId: "days-8-15-22-29",
  basisId: "conjunction",
  locationConfigured: true,
  latitude: 31.7683,
  longitude: 35.2137,
  timeZone: "Asia/Jerusalem",
  locationLabel: "Jerusalem",
  weekStart: 0
})
check("view has phase", !!view.now.phaseName, JSON.stringify(view.now))
check("today heading", view.isToday && view.now.headingDate === "Thursday, Nov 5", view.now.headingDate)
check("calendar has 42 days", view.calendar.cells.length === 42)
check("sabbath list", view.sabbaths.length === 8, String(view.sabbaths.length))
const prevOfSecond = context.previousSabbathIso(view.sabbaths[1].iso, "Asia/Jerusalem", "days-8-15-22-29", "conjunction")
check("previous sabbath is the prior one", prevOfSecond === view.sabbaths[0].iso, prevOfSecond + " vs " + view.sabbaths[0].iso)
const prevOfFirst = context.previousSabbathIso(view.sabbaths[0].iso, "Asia/Jerusalem", "days-8-15-22-29", "conjunction")
const prevSnap = context.daySnapshot(prevOfFirst, "Asia/Jerusalem", "days-8-15-22-29", "conjunction", null, null, [])
check("previous sabbath is earlier and marked", prevOfFirst < view.sabbaths[0].iso && prevSnap.isSabbath, prevOfFirst)
check(
  "saturday previous is seven days back",
  context.previousSabbathIso("2026-11-08", "UTC", "week-saturday", "conjunction") === "2026-11-07"
    && context.previousSabbathIso("2026-11-07", "UTC", "week-saturday", "conjunction") === "2026-10-31"
)
check("eclipse cards", view.eclipses.length === 2, view.eclipses.map((e) => e.type).join(", "))
check("rule label", view.rule.short === "Rule: 1/8/15/22/29")
check(
  "tonight footer labels",
  context.basisById("conjunction").footer === "Calculated conjunction · midnight-to-midnight"
    && context.basisById("crescent-1").footer === "Crescent +1 day · midnight-to-midnight"
    && context.basisById("crescent-2").footer === "Crescent +2 days · midnight-to-midnight"
    && view.basis.footer === "Calculated conjunction · midnight-to-midnight"
)
const flagsOk = view.calendar.cells.every((cell) => {
  const status = context.dayStatus("days-8-15-22-29", cell.lunarDay, view.now.monthLength, context.weekdayOf(cell.iso, "Asia/Jerusalem"))
  return status.isSabbath === cell.isSabbath || cell.lunarDay !== status.lunarDay
})
// Month length can differ per cell. Recompute against that cell's own day.
let calendarConsistent = true
for (const cell of view.calendar.cells) {
  const snap = context.daySnapshot(cell.iso, "Asia/Jerusalem", "days-8-15-22-29", "conjunction", null, null, [])
  if (snap.isSabbath !== cell.isSabbath || snap.lunarDay !== cell.lunarDay) calendarConsistent = false
}
check("calendar matches day status", calendarConsistent)

const week = context.buildView({
  nowMs: Date.parse("2026-11-07T12:00:00Z"),
  ruleId: "week-saturday",
  basisId: "conjunction",
  locationConfigured: false,
  weekStart: 0,
  timeZone: "UTC"
})
check("saturday system rule uses local date", typeof week.now.isSabbath === "boolean")

const chicagoNoon = context.utcMsFromLocal(2026, 11, 5, 12, 0, "America/Chicago")
const chicagoParts = context.zoneParts(chicagoNoon, "America/Chicago")
check("timezone roundtrip", chicagoParts.hour === 12 && chicagoParts.day === 5, JSON.stringify(chicagoParts))

const invalid = context.validateLocation(120, 10, "Not/AZone")
const valid = context.validateLocation(31.7, 35.2, "Asia/Jerusalem")
check("reject bad latitude", !invalid.ok)
check("accept Jerusalem", valid.ok)

function altitudeAtClock(iso, clock) {
  const parts = context.parseIso(iso)
  const bits = clock.split(":")
  const ms = context.utcMsFromLocal(parts.year, parts.month, parts.day, Number(bits[0]), Number(bits[1]), "Asia/Jerusalem")
  return context.moonLimbAltitude(context.jdFromUnixMs(ms), 31.7683, 35.2137)
}

if (view.now.moonrise || view.now.moonset) {
  console.log("Jerusalem rise " + view.now.moonrise + " set " + view.now.moonset + " note " + view.now.riseSetNote)
  check("rise or set present", true)
  if (view.now.moonrise) near(altitudeAtClock(view.now.iso, view.now.moonrise), 0, 0.4, "moonrise limb altitude")
  if (view.now.moonset) near(altitudeAtClock(view.now.iso, view.now.moonset), 0, 0.4, "moonset limb altitude")
} else {
  check("polar-style note when no crossing", view.now.riseSetNote.length > 0, view.now.riseSetNote)
}

function expectHorizonLabel(alt) {
  const rounded = Math.round(alt)
  const magnitude = Math.abs(rounded)
  if (magnitude === 0) return "0°"
  return (rounded > 0 ? "above " : "below ") + magnitude + "°"
}

const nowAlt = context.moonLimbAltitude(
  context.jdFromUnixMs(Date.parse("2026-11-05T18:00:00Z")),
  31.7683,
  35.2137
)
check(
  "today horizon matches current limb altitude",
  view.now.hasLocation === true
    && view.now.horizonDegrees === Math.round(nowAlt)
    && view.now.horizonLabel === expectHorizonLabel(nowAlt),
  view.now.horizonLabel + " deg " + view.now.horizonDegrees + " alt " + nowAlt
)

const otherDay = context.buildView({
  nowMs: Date.parse("2026-11-05T18:00:00Z"),
  selectedIso: "2026-11-06",
  ruleId: "days-8-15-22-29",
  basisId: "conjunction",
  locationConfigured: true,
  latitude: 31.7683,
  longitude: 35.2137,
  timeZone: "Asia/Jerusalem",
  locationLabel: "Jerusalem",
  weekStart: 0
})
const nowClock = context.zoneParts(Date.parse("2026-11-05T18:00:00Z"), "Asia/Jerusalem")
const otherMs = context.utcMsFromLocal(2026, 11, 6, nowClock.hour, nowClock.minute, "Asia/Jerusalem")
const otherAlt = context.moonLimbAltitude(context.jdFromUnixMs(otherMs), 31.7683, 35.2137)
check(
  "other date horizon uses the same local clock",
  otherDay.selected.horizonLabel === expectHorizonLabel(otherAlt)
    && otherDay.selected.horizonDegrees === Math.round(otherAlt),
  otherDay.selected.horizonLabel + " vs " + expectHorizonLabel(otherAlt)
)
check(
  "today horizon stays on the current instant while browsing",
  otherDay.now.horizonLabel === view.now.horizonLabel,
  otherDay.now.horizonLabel
)

const unlocated = context.daySnapshot("2026-11-05", "Asia/Jerusalem", "days-8-15-22-29", "conjunction", null, null, [])
check(
  "horizon hidden without a location",
  unlocated.hasLocation === false && unlocated.horizonLabel === "" && unlocated.horizonDegrees === null,
  unlocated.riseSetNote
)

const solarCard = view.eclipses.find((event) => event.kind === "solar")
check(
  "next solar from Nov 2026 is annular",
  !!solarCard && solarCard.type.indexOf("Annular") === 0 && solarCard.whenLabel.indexOf("2027") >= 0,
  solarCard ? solarCard.type + " " + solarCard.whenLabel : "missing"
)

check("shift month clamps short months", context.shiftMonth("2026-01-31", 1) === "2026-02-28")
check("shift month keeps the day", context.shiftMonth("2026-01-15", -1) === "2025-12-15")

const citiesSource = fs.readFileSync(path.join(__dirname, "..", "cities.js"), "utf8")
  .replace(/^[\s\uFEFF]*\.pragma library;?\s*/, "")
const cities = { console, Math, Date, String }
vm.createContext(cities)
vm.runInContext(citiesSource, cities)
const jeru = cities.search("jeru")
check("search Jerusalem", jeru.length > 0 && jeru[0].name === "Jerusalem" && jeru[0].timeZone === "Asia/Jerusalem")
check("empty city query", cities.search("   ").length === 0)
check("city search cap", cities.search("a").length > 0 && cities.search("a").length <= 8)

function sameParts(zone, iso) {
  const ms = Date.parse(iso)
  const table = context.tableZoneParts(ms, zone)
  const intlParts = context.zoneParts(ms, zone)
  check(
    zone + " " + iso,
    !!table && table.year === intlParts.year && table.month === intlParts.month && table.day === intlParts.day
      && table.hour === intlParts.hour && table.minute === intlParts.minute && table.weekday === intlParts.weekday,
    JSON.stringify(table) + " vs " + JSON.stringify(intlParts)
  )
}

check("parse Chicago zoneinfo", context.loadZoneBytes("America/Chicago", fs.readFileSync("/usr/share/zoneinfo/America/Chicago")))
check("parse Jerusalem zoneinfo", context.loadZoneBytes("Asia/Jerusalem", fs.readFileSync("/usr/share/zoneinfo/Asia/Jerusalem")))
check("parse Auckland zoneinfo", context.loadZoneBytes("Pacific/Auckland", fs.readFileSync("/usr/share/zoneinfo/Pacific/Auckland")))
sameParts("America/Chicago", "2026-01-15T18:00:00Z")
sameParts("America/Chicago", "2026-07-15T17:00:00Z")
sameParts("America/Chicago", "2026-03-08T07:30:00Z")
sameParts("America/Chicago", "2026-03-08T08:30:00Z")
sameParts("America/Chicago", "2026-11-01T06:30:00Z")
sameParts("America/Chicago", "2026-11-01T07:30:00Z")
sameParts("America/Chicago", "2040-01-15T18:00:00Z")
sameParts("Asia/Jerusalem", "2026-11-05T18:00:00Z")
sameParts("Pacific/Auckland", "2026-01-15T00:00:00Z")
sameParts("Pacific/Auckland", "2026-07-15T00:00:00Z")
const chicagoNoonTable = (() => {
  const guessStart = Date.UTC(2026, 10, 5, 12, 0, 0, 0)
  let guess = guessStart
  for (let i = 0; i < 4; i++) {
    const parts = context.tableZoneParts(guess, "America/Chicago")
    const got = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second)
    const want = Date.UTC(2026, 10, 5, 12, 0, 0)
    guess += want - got
    if (Math.abs(want - got) < 1000) break
  }
  return guess
})()
check("zoneinfo roundtrip matches Intl", Math.abs(chicagoNoonTable - chicagoNoon) < 1000, String(chicagoNoonTable - chicagoNoon))

function phaseNameOn(iso, zone) {
  return context.daySnapshot(iso, zone, "days-8-15-22-29", "conjunction", null, null, []).phaseName
}

const quarterNames = ["New Moon", "First Quarter", "Full Moon", "Last Quarter"]
function checkPhaseWalk(zone, startIso) {
  let cursor = startIso
  const seen = [cursor]
  for (let step = 0; step < 8; step++) {
    const event = context.neighboringPhase(cursor, zone, 1)
    const gap = context.daysBetween(cursor, event.iso)
    check(
      zone + " next phase leaves " + cursor,
      event.iso > cursor && gap >= 5 && gap <= 10 && quarterNames.indexOf(phaseNameOn(event.iso, zone)) >= 0,
      event.iso + " gap " + gap + " " + phaseNameOn(event.iso, zone)
    )
    const back = context.neighboringPhase(event.iso, zone, -1)
    check(zone + " previous phase undoes " + event.iso, back.iso === cursor, back.iso + " vs " + cursor)
    cursor = event.iso
    seen.push(cursor)
  }
  const names = seen.map((iso) => phaseNameOn(iso, zone))
  let ordered = true
  for (let i = 1; i < names.length; i++) {
    const prev = quarterNames.indexOf(names[i - 1])
    const next = quarterNames.indexOf(names[i])
    if (next !== (prev + 1) % 4) ordered = false
  }
  check(zone + " phases cycle new, quarter, full, quarter", ordered, names.join(" → "))
}

if (solarAug) {
  const solarMs = context.unixMsFromJd(solarAug.jd)
  const solarUtc = context.localIso(solarMs, "UTC")
  const solarAuck = context.localIso(solarMs, "Pacific/Auckland")
  check("utc new moon day is the eclipse date", solarUtc === "2026-08-12", solarUtc)
  check(
    "utc next phase leaves the new moon",
    context.neighboringPhase(solarUtc, "UTC", 1).iso > solarUtc
  )
  check(
    "utc previous phase of the next day is the new moon",
    context.neighboringPhase(context.addDays(solarUtc, 1), "UTC", -1).iso === solarUtc
  )
  check(
    "Auckland previous phase of the next day is the new moon",
    context.neighboringPhase(context.addDays(solarAuck, 1), "Pacific/Auckland", -1).iso === solarAuck,
    solarAuck
  )
  checkPhaseWalk("UTC", solarUtc)
  checkPhaseWalk("Pacific/Auckland", solarAuck)
  checkPhaseWalk("Asia/Jerusalem", context.localIso(solarMs, "Asia/Jerusalem"))
}
if (lunarMar) {
  const fullIso = context.localIso(context.unixMsFromJd(lunarMar.jd), "UTC")
  check("utc full moon day is the eclipse date", fullIso === "2026-03-03", fullIso)
  check(
    "standing on the full moon, next is later and previous is earlier",
    context.neighboringPhase(fullIso, "UTC", 1).iso > fullIso
      && context.neighboringPhase(fullIso, "UTC", -1).iso < fullIso
  )
}
check("tonight is a panel tab", context.knownView("tonight"))
check("calendar is a panel tab", context.knownView("calendar"))
check("cycle is a panel tab", context.knownView("cycle"))
check("sabbaths is a panel tab", context.knownView("sabbaths"))
check("eclipses is a panel tab", context.knownView("eclipses"))
check("settings is not a panel tab", context.knownView("settings") === false)
check("empty view is not a panel tab", context.knownView("") === false)
context.remember({ lastView: "calendar", preferShellSeed: true })
check("session keeps the selected tab", context.sessionState().lastView === "calendar")
context.remember({ lastView: "nope" })
check("session ignores an unknown tab", context.sessionState().lastView === "calendar")
check("bad phase step is empty", context.neighboringPhase("nope", "UTC", 1).iso === "")
check("zero phase direction is empty", context.neighboringPhase("2026-08-12", "UTC", 0).iso === "")

console.log("phase " + view.now.phaseName + " " + view.now.illuminationPercent + "% day " + view.now.lunarDay
  + " status " + view.now.status.title)
console.log("eclipses " + view.eclipses.map((e) => e.type + " " + e.whenLabel + " " + e.countdown).join(" || "))

if (failed) {
  console.error(failed + " failed")
  process.exit(1)
}
console.log("all checks passed")
