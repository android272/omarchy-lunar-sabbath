.pragma library

// Offline lunar calendar for the bar plugin.
// Sun and Moon positions follow Paul Schlyter's low-precision orbital
// elements (about 1–2 arcminutes). That is a few minutes of lunar motion.
// Eclipse contact windows derived from those positions are labeled approximate.

var GOLD = "#e0b44c"
var SYNODIC_DAYS = 29.530588853
var RAD = Math.PI / 180
var DEG = 180 / Math.PI
var MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
var MONTHS_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var WEEKDAYS_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

function pad2(n) {
  n = Math.floor(Math.abs(n))
  return (n < 10 ? "0" : "") + n
}

function clamp(n, lo, hi) {
  return Math.max(lo, Math.min(hi, n))
}

function wrap360(deg) {
  var x = deg % 360
  if (x < 0) x += 360
  return x
}

function wrap180(deg) {
  var x = wrap360(deg)
  if (x > 180) x -= 360
  return x
}

function sinD(deg) { return Math.sin(deg * RAD) }
function cosD(deg) { return Math.cos(deg * RAD) }
function atan2D(y, x) { return Math.atan2(y, x) * DEG }

function jdFromUnixMs(ms) {
  return ms / 86400000 + 2440587.5
}

function unixMsFromJd(jd) {
  return (jd - 2440587.5) * 86400000
}

function dayNumber(jd) {
  return jd - 2451543.5
}

function bodies(jd) {
  var d = dayNumber(jd)
  var sunW = 282.9404 + 4.70935e-5 * d
  var sunEcc = 0.016709 - 1.151e-9 * d
  var sunM = wrap360(356.0470 + 0.9856002585 * d)
  var sunE = sunM + DEG * sunEcc * sinD(sunM) * (1 + sunEcc * cosD(sunM))
  var sunXv = cosD(sunE) - sunEcc
  var sunYv = Math.sqrt(1 - sunEcc * sunEcc) * sinD(sunE)
  var sunV = atan2D(sunYv, sunXv)
  var sunR = Math.sqrt(sunXv * sunXv + sunYv * sunYv)
  var sunLon = wrap360(sunV + sunW)
  var sunMean = wrap360(sunM + sunW)

  var node = wrap360(125.1228 - 0.0529538083 * d)
  var incl = 5.1454
  var moonW = wrap360(318.0634 + 0.1643573223 * d)
  var moonA = 60.2666
  var moonEcc = 0.0549
  var moonM = wrap360(115.3654 + 13.0649929509 * d)
  var moonE = moonM + DEG * moonEcc * sinD(moonM) * (1 + moonEcc * cosD(moonM))
  var moonXv = moonA * (cosD(moonE) - moonEcc)
  var moonYv = moonA * Math.sqrt(1 - moonEcc * moonEcc) * sinD(moonE)
  var moonV = atan2D(moonYv, moonXv)
  var moonR = Math.sqrt(moonXv * moonXv + moonYv * moonYv)
  var vw = moonV + moonW
  var xe = moonR * (cosD(node) * cosD(vw) - sinD(node) * sinD(vw) * cosD(incl))
  var ye = moonR * (sinD(node) * cosD(vw) + cosD(node) * sinD(vw) * cosD(incl))
  var ze = moonR * sinD(vw) * sinD(incl)
  var moonLon = wrap360(atan2D(ye, xe))
  var moonLat = atan2D(ze, Math.sqrt(xe * xe + ye * ye))

  var lm = wrap360(moonM + moonW + node)
  var elong = wrap360(lm - sunMean)
  var argLat = wrap360(lm - node)
  moonLon = wrap360(moonLon
    - 1.274 * sinD(moonM - 2 * elong)
    + 0.658 * sinD(2 * elong)
    - 0.186 * sinD(sunM)
    - 0.059 * sinD(2 * moonM - 2 * elong)
    - 0.057 * sinD(moonM - 2 * elong + sunM)
    + 0.053 * sinD(moonM + 2 * elong)
    + 0.046 * sinD(2 * elong - sunM)
    + 0.041 * sinD(moonM - sunM)
    - 0.035 * sinD(elong)
    - 0.031 * sinD(moonM + sunM)
    - 0.015 * sinD(2 * argLat - 2 * elong)
    + 0.011 * sinD(moonM - 4 * elong))
  moonLat += -0.173 * sinD(argLat - 2 * elong)
    - 0.055 * sinD(moonM - argLat - 2 * elong)
    - 0.046 * sinD(moonM + argLat - 2 * elong)
    + 0.033 * sinD(argLat + 2 * elong)
    + 0.017 * sinD(2 * moonM + argLat)
  moonR += -0.58 * cosD(moonM - 2 * elong) - 0.46 * cosD(2 * elong)

  return {
    d: d,
    obliquity: 23.4393 - 3.563e-7 * d,
    sunLon: sunLon,
    sunLat: 0,
    sunR: sunR,
    sunMeanAnomaly: sunM,
    sunMeanLon: sunMean,
    moonLon: moonLon,
    moonLat: moonLat,
    moonR: moonR
  }
}

function eclipticSeparation(lon1, lat1, lon2, lat2) {
  var cos = sinD(lat1) * sinD(lat2) + cosD(lat1) * cosD(lat2) * cosD(lon1 - lon2)
  return Math.acos(clamp(cos, -1, 1)) * DEG
}

function equatorial(lon, lat, eps) {
  var x = cosD(lon) * cosD(lat)
  var y = sinD(lon) * cosD(lat)
  var z = sinD(lat)
  var ye = y * cosD(eps) - z * sinD(eps)
  var ze = y * sinD(eps) + z * cosD(eps)
  return {
    ra: wrap360(atan2D(ye, x)),
    dec: atan2D(ze, Math.sqrt(x * x + ye * ye))
  }
}

function angularSeparation(ra1, dec1, ra2, dec2) {
  var cos = sinD(dec1) * sinD(dec2) + cosD(dec1) * cosD(dec2) * cosD(ra1 - ra2)
  return Math.acos(clamp(cos, -1, 1)) * DEG
}

function gmstDegrees(jd) {
  return wrap360(280.46061837 + 360.98564736629 * (jd - 2451545.0))
}

function altitudeDegrees(jd, ra, dec, latitude, longitude) {
  var lst = wrap360(gmstDegrees(jd) + longitude)
  var ha = wrap180(lst - ra)
  var sine = sinD(dec) * sinD(latitude) + cosD(dec) * cosD(latitude) * cosD(ha)
  return Math.asin(clamp(sine, -1, 1)) * DEG
}

function disks(jd) {
  var b = bodies(jd)
  var sunSemi = Math.asin(clamp(0.00465047 / b.sunR, 0, 1)) * DEG
  var parallax = Math.asin(clamp(1 / b.moonR, 0, 1)) * DEG
  var moonSemi = Math.asin(clamp(0.2725076 / b.moonR, 0, 1)) * DEG
  return {
    bodies: b,
    sunSemi: sunSemi,
    moonSemi: moonSemi,
    parallax: parallax,
    // Danjon's 1.01 enlarges Earth's shadow for the atmosphere.
    umbra: 1.01 * parallax - sunSemi,
    penumbra: 1.01 * parallax + sunSemi
  }
}

function signedElongation(jd) {
  var b = bodies(jd)
  return wrap180(b.moonLon - b.sunLon)
}

function unsignedElongation(jd) {
  return wrap360(signedElongation(jd))
}

function refineCrossing(fn, guess, span) {
  var left = guess - span
  var right = guess + span
  var found = false
  var fl = 0
  var fr = 0
  var shift
  for (shift = 0; shift < 24; shift++) {
    left = guess - span - shift * 0.75
    right = left + span * 2
    fl = fn(left)
    fr = fn(right)
    if (fl <= 0 && fr >= 0 && Math.abs(fl) < 140 && Math.abs(fr) < 140) {
      found = true
      break
    }
  }
  if (!found) return guess
  var i
  for (i = 0; i < 48; i++) {
    var mid = (left + right) / 2
    var fm = fn(mid)
    if (fm <= 0) {
      left = mid
      fl = fm
    } else {
      right = mid
      fr = fm
    }
  }
  return (left + right) / 2
}

function previousConjunction(jd) {
  var age = unsignedElongation(jd) / 360 * SYNODIC_DAYS
  var guess = jd - age
  var t = refineCrossing(signedElongation, guess, 2.5)
  if (t > jd + 0.0007) t = refineCrossing(signedElongation, t - SYNODIC_DAYS, 2.5)
  return t
}

function nextConjunction(jd) {
  return refineCrossing(signedElongation, jd + SYNODIC_DAYS * 0.92, 4)
}

function oppositionResidual(jd) {
  return wrap180(signedElongation(jd) - 180)
}

function previousOpposition(jd) {
  var elong = unsignedElongation(jd)
  var into = elong >= 180 ? (elong - 180) / 360 * SYNODIC_DAYS : (elong + 180) / 360 * SYNODIC_DAYS
  var t = refineCrossing(oppositionResidual, jd - into, 2.5)
  if (t > jd + 0.0007) t = refineCrossing(oppositionResidual, t - SYNODIC_DAYS, 2.5)
  return t
}

function nextOpposition(jd) {
  return refineCrossing(oppositionResidual, previousOpposition(jd) + SYNODIC_DAYS * 0.92, 4)
}

function phaseResidual(target) {
  return function (jd) {
    return wrap180(signedElongation(jd) - target)
  }
}

function nextPhaseJd(jd, targetDeg) {
  var elong = unsignedElongation(jd)
  var ahead = wrap360(targetDeg - elong)
  if (ahead < 0.2) ahead += 360
  return refineCrossing(phaseResidual(targetDeg), jd + ahead / 360 * SYNODIC_DAYS, 2.5)
}

function previousPhaseJd(jd, targetDeg) {
  var elong = unsignedElongation(jd)
  var behind = wrap360(elong - targetDeg)
  if (behind < 0.2) behind += 360
  return refineCrossing(phaseResidual(targetDeg), jd - behind / 360 * SYNODIC_DAYS, 2.5)
}

// New, first quarter, full, and last quarter. The buttons step between these
// instants. Crescent and gibbous are ranges, not a date to land on.
var PRINCIPAL_PHASES = [0, 90, 180, 270]

function neighboringPhase(iso, timeZone, direction) {
  var parts = parseIso(iso)
  if (!parts || (direction !== 1 && direction !== -1)) return { iso: "", angle: -1, utcMs: 0 }
  var start = utcMsFromLocal(parts.year, parts.month, parts.day, 0, 0, timeZone)
  var jd = jdFromUnixMs(start)
  var best = null
  var i
  for (i = 0; i < PRINCIPAL_PHASES.length; i++) {
    var when = direction < 0 ? previousPhaseJd(jd, PRINCIPAL_PHASES[i]) : nextPhaseJd(jd, PRINCIPAL_PHASES[i])
    var guard = 0
    var event = null
    // Midnight on a phase's own civil date still finds that phase. Step a
    // cycle so the button always leaves the day being viewed.
    while (guard < 3) {
      var ms = unixMsFromJd(when)
      var eventIso = localIso(ms, timeZone)
      var onOtherDay = direction < 0 ? eventIso < iso : eventIso > iso
      if (onOtherDay) {
        event = { iso: eventIso, angle: PRINCIPAL_PHASES[i], utcMs: ms }
        break
      }
      when = direction < 0 ? previousPhaseJd(when - 0.75, PRINCIPAL_PHASES[i]) : nextPhaseJd(when + 0.75, PRINCIPAL_PHASES[i])
      guard += 1
    }
    if (!event) continue
    if (!best || (direction < 0 ? event.utcMs > best.utcMs : event.utcMs < best.utcMs)) best = event
  }
  return best || { iso: "", angle: -1, utcMs: 0 }
}

function illuminationOf(jd) {
  var b = bodies(jd)
  var psi = eclipticSeparation(b.sunLon, b.sunLat, b.moonLon, b.moonLat)
  return (1 - Math.cos(psi * RAD)) / 2
}

function phaseName(angle) {
  var a = wrap360(angle)
  if (a < 11 || a >= 349) return "New Moon"
  if (a < 79) return "Waxing Crescent"
  if (a < 101) return "First Quarter"
  if (a < 169) return "Waxing Gibbous"
  if (a < 191) return "Full Moon"
  if (a < 259) return "Waning Gibbous"
  if (a < 281) return "Last Quarter"
  return "Waning Crescent"
}

function minimize(fn, center, halfWidth, step) {
  var bestT = center
  var best = fn(center)
  var t
  for (t = center - halfWidth; t <= center + halfWidth; t += step) {
    var value = fn(t)
    if (value < best) {
      best = value
      bestT = t
    }
  }
  var left = bestT - step
  var right = bestT + step
  var i
  for (i = 0; i < 36; i++) {
    var m1 = left + (right - left) / 3
    var m2 = right - (right - left) / 3
    if (fn(m1) < fn(m2)) right = m2
    else left = m1
  }
  var mid = (left + right) / 2
  return { jd: mid, value: fn(mid) }
}

function circleCoverage(targetR, coveringR, separation) {
  if (targetR <= 0) return 0
  if (separation >= targetR + coveringR) return 0
  if (separation <= coveringR - targetR) return 1
  if (separation <= targetR - coveringR) return (coveringR * coveringR) / (targetR * targetR)
  var d = Math.max(separation, 1e-8)
  var a = Math.acos(clamp((d * d + targetR * targetR - coveringR * coveringR) / (2 * d * targetR), -1, 1))
  var b = Math.acos(clamp((d * d + coveringR * coveringR - targetR * targetR) / (2 * d * coveringR), -1, 1))
  var area = targetR * targetR * a + coveringR * coveringR * b
    - 0.5 * Math.sqrt(Math.max(0, (-d + targetR + coveringR) * (d + targetR - coveringR) * (d - targetR + coveringR) * (d + targetR + coveringR)))
  return clamp(area / (Math.PI * targetR * targetR), 0, 1)
}

function lunarShadowSeparation(jd) {
  var b = bodies(jd)
  return eclipticSeparation(b.moonLon, b.moonLat, wrap360(b.sunLon + 180), 0)
}

function solarSeparation(jd) {
  var b = bodies(jd)
  return eclipticSeparation(b.moonLon, b.moonLat, b.sunLon, b.sunLat)
}

function alongTrackSpeed(jd) {
  var h = 0.02
  return Math.abs(wrap180(signedElongation(jd + h) - signedElongation(jd - h))) / (2 * h)
}

function halfDurationHours(radius, impact, jd) {
  var speed = alongTrackSpeed(jd) / 24
  if (speed < 0.01 || impact >= radius) return 0
  return Math.sqrt(radius * radius - impact * impact) / speed
}

function formatDuration(hours) {
  if (!hours || hours <= 0) return ""
  var total = Math.round(hours * 60)
  var h = Math.floor(total / 60)
  var m = total % 60
  if (h <= 0) return "about " + m + " min"
  return "about " + h + " h " + pad2(m).replace(/^0/, "") + " min"
}

function moonLimbAltitude(jd, latitude, longitude) {
  var pack = disks(jd)
  var eq = equatorial(pack.bodies.moonLon, pack.bodies.moonLat, pack.bodies.obliquity)
  var geo = altitudeDegrees(jd, eq.ra, eq.dec, latitude, longitude)
  var topo = geo - pack.parallax * cosD(geo)
  return topo + pack.moonSemi - 0.566
}

function sunLimbAltitude(jd, latitude, longitude) {
  var b = bodies(jd)
  var eq = equatorial(b.sunLon, 0, b.obliquity)
  return altitudeDegrees(jd, eq.ra, eq.dec, latitude, longitude) + 0.266
}

function moonTopocentric(jd, latitude, longitude) {
  var pack = disks(jd)
  var eq = equatorial(pack.bodies.moonLon, pack.bodies.moonLat, pack.bodies.obliquity)
  var lst = wrap360(gmstDegrees(jd) + longitude)
  var ha = wrap180(lst - eq.ra)
  var gclat = latitude - 0.1924 * sinD(2 * latitude)
  var rho = 0.99833 + 0.00167 * cosD(2 * latitude)
  var g
  if (Math.abs(cosD(ha)) < 1e-6) g = gclat >= 0 ? 90 : -90
  else g = Math.atan(Math.tan(gclat * RAD) / cosD(ha)) * DEG
  var decCos = cosD(eq.dec)
  var ra = eq.ra
  if (Math.abs(decCos) > 1e-6)
    ra = wrap360(eq.ra - pack.parallax * rho * cosD(gclat) * sinD(ha) / decCos)
  var dec
  if (Math.abs(sinD(g)) < 1e-4)
    dec = eq.dec - pack.parallax * rho * sinD(-eq.dec) * cosD(ha)
  else
    dec = eq.dec - pack.parallax * rho * sinD(gclat) * sinD(g - eq.dec) / sinD(g)
  return { ra: ra, dec: dec, sun: equatorial(pack.bodies.sunLon, 0, pack.bodies.obliquity), pack: pack }
}

function localSolarSeparation(jd, latitude, longitude) {
  var topo = moonTopocentric(jd, latitude, longitude)
  return {
    separation: angularSeparation(topo.ra, topo.dec, topo.sun.ra, topo.sun.dec),
    pack: topo.pack,
    sunUp: sunLimbAltitude(jd, latitude, longitude) > 0
  }
}

function classifyLunar(sep, pack) {
  var umbralMag = (pack.umbra + pack.moonSemi - sep) / (2 * pack.moonSemi)
  var penumbralMag = (pack.penumbra + pack.moonSemi - sep) / (2 * pack.moonSemi)
  if (umbralMag >= 1) return { kind: "lunar", type: "Total lunar eclipse", magnitude: umbralMag, penumbral: penumbralMag, radius: pack.umbra + pack.moonSemi }
  if (umbralMag > 0.01) return { kind: "lunar", type: "Partial lunar eclipse", magnitude: umbralMag, penumbral: penumbralMag, radius: pack.umbra + pack.moonSemi }
  if (penumbralMag > 0.02) return { kind: "lunar", type: "Penumbral lunar eclipse", magnitude: penumbralMag, penumbral: penumbralMag, radius: pack.penumbra + pack.moonSemi }
  return null
}

function classifySolar(sep, pack) {
  // An observer can shift the Moon by about one Earth-parallax, so an
  // eclipse can be central on Earth while the geocentric separation is
  // still a large fraction of a degree.
  var parallax = pack.parallax
  var sunSemi = pack.sunSemi
  var moonSemi = pack.moonSemi
  var closest = Math.max(0, sep - parallax)
  if (closest >= sunSemi + moonSemi) return null
  var central = sep + 0.015 < parallax
  var type = "Partial solar eclipse"
  if (central) type = moonSemi + 0.001 >= sunSemi ? "Total solar eclipse" : "Annular solar eclipse"
  var magnitude = (sunSemi + moonSemi - closest) / (2 * sunSemi)
  return {
    kind: "solar",
    type: type,
    magnitude: magnitude,
    central: central,
    closest: closest,
    radius: parallax + sunSemi + moonSemi
  }
}

function findLunarEclipse(oppositionJd) {
  var hit = minimize(lunarShadowSeparation, oppositionJd, 0.35, 2 / 1440)
  var pack = disks(hit.jd)
  var info = classifyLunar(hit.value, pack)
  if (!info) return null
  var obscuration
  if (info.type.indexOf("Penumbral") === 0)
    obscuration = circleCoverage(pack.moonSemi, pack.penumbra, hit.value)
  else
    obscuration = circleCoverage(pack.moonSemi, Math.max(pack.umbra, 0), hit.value)
  info.jd = hit.jd
  info.separation = hit.value
  info.obscuration = obscuration
  info.durationHours = 2 * halfDurationHours(info.radius, hit.value, hit.jd)
  return info
}

function findSolarEclipse(conjunctionJd) {
  var hit = minimize(solarSeparation, conjunctionJd, 0.35, 2 / 1440)
  var pack = disks(hit.jd)
  var info = classifySolar(hit.value, pack)
  if (!info) return null
  info.jd = hit.jd
  info.separation = hit.value
  info.obscuration = circleCoverage(pack.sunSemi, pack.moonSemi, info.closest)
  info.durationHours = 2 * halfDurationHours(pack.sunSemi + pack.moonSemi + pack.parallax, hit.value, hit.jd)
  return info
}

function eclipsesBetween(startJd, endJd) {
  var events = []
  var conj = previousConjunction(startJd - 2)
  var guard = 0
  while (conj < endJd + 2 && guard < 24) {
    if (conj >= startJd - 1) {
      var solar = findSolarEclipse(conj)
      if (solar && solar.jd >= startJd && solar.jd <= endJd) events.push(solar)
    }
    conj = nextConjunction(conj + 1)
    guard += 1
  }
  var opp = previousOpposition(startJd - 2)
  guard = 0
  while (opp < endJd + 2 && guard < 24) {
    if (opp >= startJd - 1) {
      var lunar = findLunarEclipse(opp)
      if (lunar && lunar.jd >= startJd && lunar.jd <= endJd) events.push(lunar)
    }
    opp = nextOpposition(opp + 1)
    guard += 1
  }
  events.sort(function (a, b) { return a.jd - b.jd })
  return events
}

function ruleCatalog() {
  return [
    {
      id: "days-8-15-22-29",
      label: "1 / 8 / 15 / 22 / 29",
      short: "Rule: 1/8/15/22/29",
      explanation: "Day 1 is the new moon, a special day; Sabbaths are days 8, 15, 22, and 29, and day 30 is only a transition."
    },
    {
      id: "days-7-14-21-28",
      label: "7 / 14 / 21 / 28",
      short: "Rule: 7/14/21/28",
      explanation: "Sabbaths fall on lunar days 7, 14, 21, and 28, counted from the chosen new-moon basis."
    },
    {
      id: "week-saturday",
      label: "Continuous week (Saturday)",
      short: "Rule: Saturday week",
      explanation: "An unbroken Saturday Sabbath, independent of the moon, for comparison with lunar counts."
    }
  ]
}

function basisCatalog() {
  return [
    {
      id: "conjunction",
      label: "Calculated conjunction",
      footer: "Calculated conjunction · midnight-to-midnight",
      detail: "Lunar day 1 is the local date of the astronomical new moon."
    },
    {
      id: "crescent-1",
      label: "First crescent, +1 day",
      footer: "Crescent +1 day · midnight-to-midnight",
      detail: "Lunar day 1 is the local day after the conjunction."
    },
    {
      id: "crescent-2",
      label: "First crescent, +2 days",
      footer: "Crescent +2 days · midnight-to-midnight",
      detail: "Lunar day 1 is two local days after the conjunction."
    }
  ]
}

function displayModes() {
  return [
    { id: "moon", label: "Moon only" },
    { id: "illumination", label: "Moon + illumination" },
    { id: "letter", label: "Moon + S" },
    { id: "word", label: "Moon + Sabbath" }
  ]
}

function knownView(id) {
  return id === "tonight" || id === "calendar" || id === "cycle" || id === "sabbaths" || id === "eclipses"
}

function ruleById(id) {
  var list = ruleCatalog()
  var i
  for (i = 0; i < list.length; i++) if (list[i].id === id) return list[i]
  return list[0]
}

function basisById(id) {
  var list = basisCatalog()
  var i
  for (i = 0; i < list.length; i++) if (list[i].id === id) return list[i]
  return list[0]
}

function basisOffset(id) {
  if (id === "crescent-1") return 1
  if (id === "crescent-2") return 2
  return 0
}

function dayStatus(ruleId, lunarDay, monthLength, weekday) {
  if (ruleId === "week-saturday") {
    var sabbath = weekday === 6
    return {
      isSabbath: sabbath,
      isSpecial: false,
      isTransition: false,
      kind: sabbath ? "sabbath" : "ordinary",
      title: sabbath ? "Sabbath" : "Not a Sabbath",
      detail: sabbath
        ? "Saturday in the continuous week. This count does not restart at the new moon."
        : WEEKDAYS[weekday] + " in the continuous week. The Sabbath in this comparison rule is Saturday."
    }
  }
  if (ruleId === "days-7-14-21-28") {
    var hit = lunarDay === 7 || lunarDay === 14 || lunarDay === 21 || lunarDay === 28
    return {
      isSabbath: hit,
      isSpecial: false,
      isTransition: false,
      kind: hit ? "sabbath" : "ordinary",
      title: hit ? "Sabbath" : "Not a Sabbath",
      detail: hit
        ? "Lunar day " + lunarDay + " is a Sabbath under 7/14/21/28."
        : "Lunar day " + lunarDay + " is not a Sabbath under 7/14/21/28."
    }
  }
  var special = lunarDay === 1
  var transition = lunarDay === 30 && monthLength >= 30
  var marked = lunarDay === 8 || lunarDay === 15 || lunarDay === 22 || lunarDay === 29
  var kind = marked ? "sabbath" : (transition ? "transition" : (special ? "special" : "ordinary"))
  var title = marked ? "Sabbath" : (transition ? "Transition day" : (special ? "New moon" : "Not a Sabbath"))
  var detail
  if (marked) detail = "Lunar day " + lunarDay + " is a Sabbath under 1/8/15/22/29."
  else if (transition) detail = "Lunar day 30 is a transition day under this rule, not a Sabbath."
  else if (special) detail = "Lunar day 1 is the new moon, a special day, and not one of the Sabbaths."
  else detail = "Lunar day " + lunarDay + " is not a Sabbath under 1/8/15/22/29."
  return {
    isSabbath: marked,
    isSpecial: special,
    isTransition: transition,
    kind: kind,
    title: title,
    detail: detail
  }
}

function hasIntl() {
  return typeof Intl === "object" && Intl && Intl.DateTimeFormat
}

// Quickshell's JavaScript engine has no Intl. Offsets then come from the
// system zoneinfo files, loaded by the QML side and parsed here.
var zoneTables = {}

function u32be(bytes, offset) {
  return ((bytes[offset] * 16777216) + (bytes[offset + 1] * 65536) + (bytes[offset + 2] * 256) + bytes[offset + 3]) >>> 0
}

function i32be(bytes, offset) {
  var value = u32be(bytes, offset)
  if (value >= 2147483648) return value - 4294967296
  return value
}

function i64be(bytes, offset) {
  return i32be(bytes, offset) * 4294967296 + u32be(bytes, offset + 4)
}

function zoneAbbr(bytes, charStart, charCount, index) {
  var chars = []
  var i = charStart + index
  var end = charStart + charCount
  while (i < end && bytes[i] !== 0) {
    chars.push(String.fromCharCode(bytes[i]))
    i += 1
  }
  return chars.join("")
}

function readTzifSection(bytes, headerOffset, timeSize) {
  if (!bytes || headerOffset + 44 > bytes.length) return null
  if (bytes[headerOffset] !== 84 || bytes[headerOffset + 1] !== 90 || bytes[headerOffset + 2] !== 105 || bytes[headerOffset + 3] !== 102) return null
  var timecnt = u32be(bytes, headerOffset + 32)
  var typecnt = u32be(bytes, headerOffset + 36)
  var charcnt = u32be(bytes, headerOffset + 40)
  var leapcnt = u32be(bytes, headerOffset + 28)
  var stdcnt = u32be(bytes, headerOffset + 24)
  var utcnt = u32be(bytes, headerOffset + 20)
  var cursor = headerOffset + 44
  var times = []
  var i
  for (i = 0; i < timecnt; i++) {
    times.push(timeSize === 8 ? i64be(bytes, cursor) : i32be(bytes, cursor))
    cursor += timeSize
  }
  var indexes = []
  for (i = 0; i < timecnt; i++) {
    indexes.push(bytes[cursor])
    cursor += 1
  }
  var types = []
  for (i = 0; i < typecnt; i++) {
    types.push({ offset: i32be(bytes, cursor), isdst: bytes[cursor + 4], abbr: bytes[cursor + 5] })
    cursor += 6
  }
  var charStart = cursor
  cursor += charcnt + leapcnt * (timeSize + 4) + stdcnt + utcnt
  var initial = 0
  var initialAbbr = ""
  var foundStandard = false
  for (i = 0; i < types.length; i++) {
    if (!types[i].isdst) {
      initial = types[i].offset
      initialAbbr = zoneAbbr(bytes, charStart, charcnt, types[i].abbr)
      foundStandard = true
      break
    }
  }
  if (!foundStandard && types.length) {
    initial = types[0].offset
    initialAbbr = zoneAbbr(bytes, charStart, charcnt, types[0].abbr)
  }
  var transitions = []
  for (i = 0; i < times.length; i++) {
    var info = types[indexes[i]] || types[0]
    transitions.push({
      utc: times[i],
      offset: info ? info.offset : 0,
      abbr: info ? zoneAbbr(bytes, charStart, charcnt, info.abbr) : ""
    })
  }
  return {
    next: cursor,
    table: { initial: initial, initialAbbr: initialAbbr, transitions: transitions }
  }
}

function parseTzif(bytes) {
  var first = readTzifSection(bytes, 0, 4)
  if (!first) return null
  var version = String.fromCharCode(bytes[4])
  if (version === "2" || version === "3" || version === "4") {
    var second = readTzifSection(bytes, first.next, 8)
    if (second && second.table) return second.table
  }
  return first.table
}

function loadZoneBytes(timeZone, bytes) {
  var table = parseTzif(bytes)
  if (!table) {
    zoneTables[timeZone] = { initial: 0, initialAbbr: "", transitions: [], failed: true }
    return false
  }
  zoneTables[timeZone] = table
  return true
}

function needsZoneFile(timeZone) {
  if (!timeZone || hasIntl() || zoneTables[timeZone]) return false
  if (timeZone === "UTC" || timeZone === "Etc/UTC" || timeZone === "Etc/GMT") {
    zoneTables[timeZone] = { initial: 0, initialAbbr: "UTC", transitions: [] }
    return false
  }
  return true
}

function offsetAt(table, utcSeconds) {
  var offset = table.initial
  var i
  for (i = 0; i < table.transitions.length; i++) {
    if (table.transitions[i].utc > utcSeconds) break
    offset = table.transitions[i].offset
  }
  return offset
}

function abbrAt(table, utcSeconds) {
  var abbr = table.initialAbbr || ""
  var i
  for (i = 0; i < table.transitions.length; i++) {
    if (table.transitions[i].utc > utcSeconds) break
    if (table.transitions[i].abbr) abbr = table.transitions[i].abbr
  }
  return abbr
}

function tableZoneParts(utcMs, timeZone) {
  var table = zoneTables[timeZone]
  if (!table) return null
  var shifted = utcMs + offsetAt(table, Math.floor(utcMs / 1000)) * 1000
  var local = new Date(shifted)
  return {
    year: local.getUTCFullYear(),
    month: local.getUTCMonth() + 1,
    day: local.getUTCDate(),
    hour: local.getUTCHours(),
    minute: local.getUTCMinutes(),
    second: local.getUTCSeconds(),
    weekday: local.getUTCDay()
  }
}

function systemParts(utcMs) {
  var date = new Date(utcMs)
  return {
    year: date.getFullYear(),
    month: date.getMonth() + 1,
    day: date.getDate(),
    hour: date.getHours(),
    minute: date.getMinutes(),
    second: date.getSeconds(),
    weekday: date.getDay()
  }
}

function zoneParts(utcMs, timeZone) {
  if (!timeZone) return systemParts(utcMs)
  if (hasIntl()) {
    var fmt = new Intl.DateTimeFormat("en-US", {
      timeZone: timeZone,
      hourCycle: "h23",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      weekday: "short"
    })
    var parts = fmt.formatToParts(new Date(utcMs))
    var map = {}
    var i
    for (i = 0; i < parts.length; i++) map[parts[i].type] = parts[i].value
    var names = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 }
    var hour = Number(map.hour)
    if (hour === 24) hour = 0
    return {
      year: Number(map.year),
      month: Number(map.month),
      day: Number(map.day),
      hour: hour,
      minute: Number(map.minute),
      second: Number(map.second),
      weekday: names[map.weekday]
    }
  }
  if (zoneTables[timeZone] && !zoneTables[timeZone].failed) return tableZoneParts(utcMs, timeZone)
  return systemParts(utcMs)
}

function zoneAbbrev(utcMs, timeZone) {
  if (!timeZone) return "local"
  if (hasIntl()) {
    try {
      var parts = new Intl.DateTimeFormat("en-US", {
        timeZone: timeZone,
        hour: "2-digit",
        timeZoneName: "short"
      }).formatToParts(new Date(utcMs))
      var i
      for (i = 0; i < parts.length; i++) if (parts[i].type === "timeZoneName") return parts[i].value
    } catch (e) {
      return timeZone
    }
    return timeZone
  }
  if (zoneTables[timeZone]) return abbrAt(zoneTables[timeZone], Math.floor(utcMs / 1000)) || timeZone
  return timeZone
}

function utcMsFromLocal(year, month, day, hour, minute, timeZone) {
  if (!timeZone || (!hasIntl() && (!zoneTables[timeZone] || zoneTables[timeZone].failed))) return new Date(year, month - 1, day, hour, minute, 0, 0).getTime()
  var guess = Date.UTC(year, month - 1, day, hour, minute, 0, 0)
  var i
  for (i = 0; i < 4; i++) {
    var parts = hasIntl() ? zoneParts(guess, timeZone) : tableZoneParts(guess, timeZone)
    var got = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second)
    var want = Date.UTC(year, month - 1, day, hour, minute, 0)
    var delta = want - got
    guess += delta
    if (Math.abs(delta) < 1000) break
  }
  return guess
}

function localIso(utcMs, timeZone) {
  var p = zoneParts(utcMs, timeZone)
  return p.year + "-" + pad2(p.month) + "-" + pad2(p.day)
}

function parseIso(iso) {
  var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(iso || ""))
  if (!match) return null
  return { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) }
}

function isoFromParts(year, month, day) {
  return year + "-" + pad2(month) + "-" + pad2(day)
}

function addDays(iso, days) {
  var p = parseIso(iso)
  if (!p) return iso
  var t = new Date(Date.UTC(p.year, p.month - 1, p.day + days))
  return isoFromParts(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate())
}

function shiftMonth(iso, delta) {
  var parts = parseIso(iso)
  if (!parts) return iso
  var target = new Date(Date.UTC(parts.year, parts.month - 1 + delta, 1))
  var year = target.getUTCFullYear()
  var month = target.getUTCMonth()
  var last = new Date(Date.UTC(year, month + 1, 0)).getUTCDate()
  var day = Math.min(parts.day, last)
  return isoFromParts(year, month + 1, day)
}

// Keep the current day-of-month when jumping to another year and month.
// A 31st lands on the last day of a shorter month.
function setMonth(iso, year, month) {
  year = Math.floor(Number(year))
  month = Math.floor(Number(month))
  if (!isFinite(year) || year < 1000 || year > 9999) return iso || ""
  if (!isFinite(month) || month < 1 || month > 12) return iso || ""
  var parts = parseIso(iso)
  var day = parts ? parts.day : 1
  var last = new Date(Date.UTC(year, month, 0)).getUTCDate()
  if (!(day >= 1)) day = 1
  if (day > last) day = last
  return isoFromParts(year, month, day)
}

function daysBetween(startIso, endIso) {
  var a = parseIso(startIso)
  var b = parseIso(endIso)
  if (!a || !b) return 0
  var ta = Date.UTC(a.year, a.month - 1, a.day)
  var tb = Date.UTC(b.year, b.month - 1, b.day)
  return Math.round((tb - ta) / 86400000)
}

function todayIso(nowMs, timeZone) {
  return localIso(nowMs, timeZone)
}

function weekdayOf(iso, timeZone) {
  var p = parseIso(iso)
  if (!p) return 0
  var noon = utcMsFromLocal(p.year, p.month, p.day, 12, 0, timeZone)
  return zoneParts(noon, timeZone).weekday
}

function shortMonthDay(iso) {
  var p = parseIso(iso)
  if (!p) return ""
  return MONTHS_SHORT[p.month - 1] + " " + p.day
}

function formatIso(iso, timeZone) {
  var p = parseIso(iso)
  if (!p) return ""
  var weekday = weekdayOf(iso, timeZone)
  return WEEKDAYS_SHORT[weekday] + " " + p.day + " " + MONTHS_SHORT[p.month - 1] + " " + p.year
}

function formatClock(utcMs, timeZone) {
  var p = zoneParts(utcMs, timeZone)
  return pad2(p.hour) + ":" + pad2(p.minute)
}

function formatInstant(utcMs, timeZone) {
  return formatIso(localIso(utcMs, timeZone), timeZone) + " · " + formatClock(utcMs, timeZone) + " " + zoneAbbrev(utcMs, timeZone)
}

function countdownHours(utcMs, nowMs) {
  var delta = utcMs - nowMs
  if (delta < -3 * 3600000) return "passed"
  if (delta < -60000) return "in progress"
  if (Math.abs(delta) <= 60000) return "now"
  var minutes = Math.round(delta / 60000)
  if (minutes < 90) return "in " + minutes + " min"
  var hours = Math.round(delta / 3600000)
  if (hours < 48) return "in " + hours + " h"
  var days = Math.round(delta / 86400000)
  return "in " + days + " days"
}

function countdownDays(iso, today) {
  var days = daysBetween(today, iso)
  if (days < 0) return "past"
  if (days === 0) return "today"
  if (days === 1) return "tomorrow"
  return "in " + days + " days"
}

function timeZoneValid(timeZone) {
  var tz = String(timeZone || "").replace(/^\s+|\s+$/g, "")
  if (tz === "UTC" || tz === "Etc/UTC" || tz === "Etc/GMT") return true
  if (!/^[A-Za-z0-9+\-]+(?:\/[A-Za-z0-9_+\-]+)+$/.test(tz)) return false
  if (!hasIntl()) return true
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz })
    return true
  } catch (e) {
    return false
  }
}

function validateLocation(latitude, longitude, timeZone) {
  var lat = Number(latitude)
  var lon = Number(longitude)
  var tz = String(timeZone || "").replace(/^\s+|\s+$/g, "")
  if (!isFinite(lat) || lat < -90 || lat > 90) return { ok: false, message: "Latitude must be between -90 and 90." }
  if (!isFinite(lon) || lon < -180 || lon > 180) return { ok: false, message: "Longitude must be between -180 and 180." }
  if (!timeZoneValid(tz)) return { ok: false, message: "Enter an IANA timezone such as Asia/Jerusalem." }
  return { ok: true, latitude: lat, longitude: lon, timeZone: tz, message: "" }
}

function monthCache() {
  return []
}

function monthContaining(iso, timeZone, basisId, cache) {
  var i
  if (cache) {
    for (i = 0; i < cache.length; i++) {
      if (iso >= cache[i].start && iso < cache[i].nextStart) return cache[i]
    }
  }
  var parts = parseIso(iso)
  var offset = basisOffset(basisId)
  var noon = utcMsFromLocal(parts.year, parts.month, parts.day, 12, 0, timeZone)
  var conj = previousConjunction(jdFromUnixMs(noon))
  var start = addDays(localIso(unixMsFromJd(conj), timeZone), offset)
  if (start > iso) {
    conj = previousConjunction(conj - 2)
    start = addDays(localIso(unixMsFromJd(conj), timeZone), offset)
  }
  var next = nextConjunction(conj + 2)
  var nextStart = addDays(localIso(unixMsFromJd(next), timeZone), offset)
  if (nextStart <= start) nextStart = addDays(start, 30)
  var record = {
    start: start,
    nextStart: nextStart,
    length: daysBetween(start, nextStart),
    conjunctionJd: conj,
    nextConjunctionJd: next
  }
  if (cache) cache.push(record)
  return record
}

function lunarDayOf(iso, month) {
  return daysBetween(month.start, iso) + 1
}

function clockOnDate(iso, timeZone, utcMs) {
  var parts = parseIso(iso)
  var clock = zoneParts(utcMs, timeZone)
  return utcMsFromLocal(parts.year, parts.month, parts.day, clock.hour, clock.minute, timeZone)
}

function horizonReading(utcMs, latitude, longitude) {
  var alt = moonLimbAltitude(jdFromUnixMs(utcMs), latitude, longitude)
  var rounded = Math.round(alt)
  var magnitude = Math.abs(rounded)
  var label = "0°"
  if (magnitude !== 0) label = (rounded > 0 ? "above " : "below ") + magnitude + "°"
  return { degrees: rounded, above: alt >= 0, label: label }
}

function daySnapshot(iso, timeZone, ruleId, basisId, latitude, longitude, cache, atMs) {
  var parts = parseIso(iso)
  var noonMs = utcMsFromLocal(parts.year, parts.month, parts.day, 12, 0, timeZone)
  var jd = jdFromUnixMs(noonMs)
  var angle = unsignedElongation(jd)
  var month = monthContaining(iso, timeZone, basisId, cache)
  var lunarDay = lunarDayOf(iso, month)
  var weekday = weekdayOf(iso, timeZone)
  var status = dayStatus(ruleId, lunarDay, month.length, weekday)
  var age = jd - month.conjunctionJd
  var rise = ""
  var set = ""
  var note = ""
  var horizonLabel = ""
  var horizonDegrees = null
  var located = !(latitude === null || latitude === undefined || longitude === null || longitude === undefined)
  if (!located) {
    note = "Set a location to see moonrise, moonset, and the horizon."
  } else {
    var events = riseSet(iso, timeZone, latitude, longitude)
    rise = events.rise
    set = events.set
    note = events.note
    if (typeof atMs === "number") {
      var horizon = horizonReading(atMs, latitude, longitude)
      horizonLabel = horizon.label
      horizonDegrees = horizon.degrees
    }
  }
  return {
    iso: iso,
    dateLabel: formatIso(iso, timeZone),
    headingDate: WEEKDAYS[weekday] + ", " + MONTHS_SHORT[parts.month - 1] + " " + parts.day,
    weekdayName: WEEKDAYS[weekday],
    weekdayIndex: weekday,
    phaseName: phaseName(angle),
    phaseAngleDeg: angle,
    illumination: illuminationOf(jd),
    illuminationPercent: Math.round(illuminationOf(jd) * 1000) / 10,
    ageDays: Math.round(age * 10) / 10,
    lunarDay: lunarDay,
    monthLength: month.length,
    monthStart: month.start,
    nextMonthStart: month.nextStart,
    status: status,
    isSabbath: status.isSabbath,
    hasLocation: located,
    moonrise: rise,
    moonset: set,
    riseSetNote: note,
    horizonLabel: horizonLabel,
    horizonDegrees: horizonDegrees
  }
}

function riseSet(iso, timeZone, latitude, longitude) {
  var parts = parseIso(iso)
  var start = utcMsFromLocal(parts.year, parts.month, parts.day, 0, 0, timeZone)
  var end = utcMsFromLocal(parts.year, parts.month, parts.day, 24, 0, timeZone)
  var step = 10 * 60000
  var prevT = start
  var prevAlt = moonLimbAltitude(jdFromUnixMs(start), latitude, longitude)
  var riseMs = 0
  var setMs = 0
  var t
  for (t = start + step; t <= end; t += step) {
    var alt = moonLimbAltitude(jdFromUnixMs(t), latitude, longitude)
    if (prevAlt <= 0 && alt > 0 && !riseMs) riseMs = bisectLimb(prevT, t, latitude, longitude, true)
    if (prevAlt > 0 && alt <= 0 && !setMs) setMs = bisectLimb(prevT, t, latitude, longitude, false)
    prevT = t
    prevAlt = alt
  }
  var noonAlt = moonLimbAltitude(jdFromUnixMs(utcMsFromLocal(parts.year, parts.month, parts.day, 12, 0, timeZone)), latitude, longitude)
  var note = ""
  if (!riseMs && !setMs) {
    note = noonAlt > 0
      ? "The Moon stays above the horizon through this date."
      : "The Moon stays below the horizon through this date."
  }
  return {
    rise: riseMs ? formatClock(riseMs, timeZone) : "",
    set: setMs ? formatClock(setMs, timeZone) : "",
    note: note
  }
}

function bisectLimb(t0, t1, latitude, longitude, rising) {
  var lo = t0
  var hi = t1
  var i
  for (i = 0; i < 24; i++) {
    var mid = (lo + hi) / 2
    var alt = moonLimbAltitude(jdFromUnixMs(mid), latitude, longitude)
    if ((rising && alt < 0) || (!rising && alt >= 0)) lo = mid
    else hi = mid
  }
  return (lo + hi) / 2
}

function upcomingPhases(fromMs, timeZone) {
  var jd = jdFromUnixMs(fromMs)
  var targets = [
    { angle: 0, name: "New Moon" },
    { angle: 90, name: "First Quarter" },
    { angle: 180, name: "Full Moon" },
    { angle: 270, name: "Last Quarter" }
  ]
  var events = []
  var i
  for (i = 0; i < targets.length; i++) {
    var when = nextPhaseJd(jd, targets[i].angle)
    var ms = unixMsFromJd(when)
    events.push({
      name: targets[i].name,
      angle: targets[i].angle,
      utcMs: ms,
      iso: localIso(ms, timeZone),
      whenLabel: formatInstant(ms, timeZone),
      countdown: countdownHours(ms, fromMs)
    })
  }
  events.sort(function (a, b) { return a.utcMs - b.utcMs })
  return events
}

function phaseAfter(fromMs, angle, timeZone) {
  var when = nextPhaseJd(jdFromUnixMs(fromMs), angle)
  var ms = unixMsFromJd(when)
  return { utcMs: ms, iso: localIso(ms, timeZone), whenLabel: formatInstant(ms, timeZone) }
}

// Lists count Sabbaths from fromIso, inclusive. Countdowns and the isToday
// marker both use todayRef, the real current date, so scrubbing to another date
// moves the window without relabeling those Sabbaths as "today" or counting
// down to ones already past. Callers that omit it keep the single-anchor behavior.
function sabbathsFrom(fromIso, timeZone, ruleId, basisId, count, todayRef) {
  var cache = monthCache()
  var list = []
  var iso = fromIso
  var guard = 0
  var reference = todayRef === undefined ? fromIso : todayRef
  while (list.length < count && guard < 200) {
    var month = monthContaining(iso, timeZone, basisId, cache)
    var lunarDay = lunarDayOf(iso, month)
    var status = dayStatus(ruleId, lunarDay, month.length, weekdayOf(iso, timeZone))
    if (status.isSabbath) {
      list.push({
        iso: iso,
        dateLabel: formatIso(iso, timeZone),
        weekdayName: WEEKDAYS[weekdayOf(iso, timeZone)],
        lunarDay: ruleId === "week-saturday" ? lunarDay : lunarDay,
        countdown: countdownDays(iso, reference),
        isToday: iso === reference
      })
    }
    iso = addDays(iso, 1)
    guard += 1
  }
  return list
}

function previousSabbathIso(iso, timeZone, ruleId, basisId) {
  return sabbathStep(iso, timeZone, ruleId, basisId, -1)
}

function nextSabbathIso(iso, timeZone, ruleId, basisId) {
  return sabbathStep(iso, timeZone, ruleId, basisId, 1)
}

// The Sabbaths tab lists eight Sabbaths from the selected date. Stepping has to
// start at that date, not at the displayed list, which stops after eight.
function sabbathStep(iso, timeZone, ruleId, basisId, direction) {
  if (!parseIso(iso) || (direction !== 1 && direction !== -1)) return ""
  var cache = monthCache()
  var cursor = addDays(iso, direction)
  var guard = 0
  // Sabbaths are at most about ten days apart. Forty days is a hard stop.
  while (guard < 40) {
    var month = monthContaining(cursor, timeZone, basisId, cache)
    var status = dayStatus(ruleId, lunarDayOf(cursor, month), month.length, weekdayOf(cursor, timeZone))
    if (status.isSabbath) return cursor
    cursor = addDays(cursor, direction)
    guard += 1
  }
  return ""
}

function calendarMonth(iso, today, selected, timeZone, ruleId, basisId, weekStart) {
  var parts = parseIso(iso)
  var first = isoFromParts(parts.year, parts.month, 1)
  var firstWeekday = weekdayOf(first, timeZone)
  var lead = (firstWeekday - weekStart + 7) % 7
  var start = addDays(first, -lead)
  var cache = monthCache()
  var cells = []
  var i
  for (i = 0; i < 42; i++) {
    var day = addDays(start, i)
    var dayParts = parseIso(day)
    var snap = daySnapshot(day, timeZone, ruleId, basisId, null, null, cache)
    cells.push({
      iso: day,
      day: dayParts.day,
      inMonth: dayParts.month === parts.month,
      isToday: day === today,
      isSelected: day === selected,
      isSabbath: snap.isSabbath,
      lunarDay: snap.lunarDay,
      phaseAngleDeg: snap.phaseAngleDeg,
      phaseName: snap.phaseName
    })
  }
  return {
    label: MONTHS[parts.month - 1] + " " + parts.year,
    year: parts.year,
    month: parts.month,
    weekdays: rotatedWeekdays(weekStart),
    cells: cells
  }
}

function rotatedWeekdays(weekStart) {
  var names = []
  var i
  for (i = 0; i < 7; i++) names.push(WEEKDAYS_SHORT[(weekStart + i) % 7])
  return names
}

// The cycle bar is new moon to new moon. Each phase marker sits at the same
// fraction as the lunar day it falls on, so the moon strip, the progress fill,
// and the date labels share one timeline.
var CYCLE_PHASE_POINTS = [
  { angle: 0, name: "New Moon", cardName: "New Moon", showDate: true, endpoint: "start" },
  { angle: 45, name: "Waxing Crescent", showDate: false },
  { angle: 90, name: "First Quarter", cardName: "First Quarter", showDate: true },
  { angle: 135, name: "Waxing Gibbous", showDate: false },
  { angle: 180, name: "Full Moon", cardName: "Full Moon", showDate: true },
  { angle: 225, name: "Waning Gibbous", showDate: false },
  { angle: 270, name: "Last Quarter", cardName: "Last Quarter", showDate: true },
  { angle: 315, name: "Waning Crescent", showDate: false },
  { angle: 0, name: "Next New Moon", cardName: "New Moon", showDate: true, endpoint: "end" }
]

function cycleFor(snap, timeZone) {
  var startParts = parseIso(snap.monthStart)
  var startMs = utcMsFromLocal(startParts.year, startParts.month, startParts.day, 0, 0, timeZone)
  var startJd = jdFromUnixMs(startMs)
  var phaseMarkers = []
  var i
  for (i = 0; i < CYCLE_PHASE_POINTS.length; i++) {
    var point = CYCLE_PHASE_POINTS[i]
    var iso = snap.monthStart
    var fraction = 0
    if (point.endpoint === "end") {
      iso = snap.nextMonthStart
      fraction = 1
    } else if (point.endpoint !== "start") {
      iso = localIso(unixMsFromJd(nextPhaseJd(startJd, point.angle)), timeZone)
      fraction = (daysBetween(snap.monthStart, iso) + 0.5) / snap.monthLength
    }
    phaseMarkers.push({
      angle: point.angle,
      name: point.name,
      cardName: point.cardName || point.name,
      showDate: point.showDate,
      fraction: fraction,
      iso: iso,
      dateLabel: shortMonthDay(iso)
    })
  }
  var progress = (snap.lunarDay - 0.5) / snap.monthLength
  return {
    progress: clamp(progress, 0.02, 0.98),
    lunarDay: snap.lunarDay,
    monthLength: snap.monthLength,
    daysRemaining: Math.max(0, snap.monthLength - snap.lunarDay),
    startDate: shortMonthDay(snap.monthStart),
    endDate: shortMonthDay(snap.nextMonthStart),
    phaseMarkers: phaseMarkers
  }
}

function localEclipseView(event, latitude, longitude, timeZone) {
  if (latitude === null || latitude === undefined) {
    return "Set a location to see whether it is visible here."
  }
  if (event.kind === "lunar") {
    var alt = moonLimbAltitude(event.jd, latitude, longitude)
    if (alt > 0) return "Visible here. The Moon is " + Math.round(alt) + "° above the horizon at mid-eclipse."
    return "Not visible here. The Moon is below the horizon at mid-eclipse."
  }
  var hit = minimize(function (jd) {
    var sample = localSolarSeparation(jd, latitude, longitude)
    if (!sample.sunUp) return 100
    return sample.separation
  }, event.jd, 0.25, 2 / 1440)
  if (hit.value >= 90) return "Not visible here. The Sun is below the horizon around mid-eclipse."
  var sample = localSolarSeparation(hit.jd, latitude, longitude)
  var covered = circleCoverage(sample.pack.sunSemi, sample.pack.moonSemi, sample.separation)
  if (covered <= 0.004) return "Not visible here. The Moon's shadow misses this location."
  var localType = "partial"
  if (sample.separation <= Math.abs(sample.pack.moonSemi - sample.pack.sunSemi))
    localType = sample.pack.moonSemi >= sample.pack.sunSemi ? "total" : "annular"
  var pct = Math.round(covered * 100)
  if (localType === "partial") return "Partial here. About " + pct + "% of the Sun's disk is covered. The path of totality or annularity is narrower."
  return "Visible here as a " + localType + " eclipse. About " + pct + "% of the Sun's disk is covered."
}

function eclipseCards(fromMs, timeZone, latitude, longitude) {
  var start = jdFromUnixMs(fromMs) - 0.2
  var events = eclipsesBetween(start, start + 420)
  var nextLunar = null
  var nextSolar = null
  var i
  for (i = 0; i < events.length; i++) {
    if (unixMsFromJd(events[i].jd) < fromMs - 2 * 3600000) continue
    if (events[i].kind === "lunar" && !nextLunar) nextLunar = events[i]
    if (events[i].kind === "solar" && !nextSolar) nextSolar = events[i]
  }
  var cards = []
  if (nextLunar) cards.push(eclipseCard(nextLunar, fromMs, timeZone, latitude, longitude))
  if (nextSolar) cards.push(eclipseCard(nextSolar, fromMs, timeZone, latitude, longitude))
  cards.sort(function (a, b) { return a.utcMs - b.utcMs })
  return cards
}

function eclipseCard(event, fromMs, timeZone, latitude, longitude) {
  var ms = unixMsFromJd(event.jd)
  var shadow = event.type.indexOf("Penumbral") === 0 ? "of the Moon in the penumbra" : (event.kind === "lunar" ? "of the Moon in Earth's umbra" : "of the Sun's disk")
  var duration = formatDuration(event.durationHours)
  return {
    kind: event.kind,
    type: event.type,
    utcMs: ms,
    whenLabel: formatInstant(ms, timeZone),
    countdown: countdownHours(ms, fromMs),
    obscuration: Math.round(event.obscuration * 100),
    obscurationLabel: Math.round(event.obscuration * 100) + "% " + shadow,
    magnitudeLabel: "Magnitude " + (Math.round(event.magnitude * 100) / 100).toFixed(2),
    durationLabel: duration ? ("Duration " + duration) : "",
    visibility: localEclipseView(event, latitude, longitude, timeZone),
    note: event.kind === "lunar" && event.type.indexOf("Penumbral") === 0
      ? "A penumbral eclipse only dims the Moon a little."
      : "Greatest eclipse is the global peak. Local timing can differ."
  }
}

function daysUntilSabbath(today, timeZone, ruleId, basisId) {
  var list = sabbathsFrom(today, timeZone, ruleId, basisId, 1)
  if (!list.length) return { label: "No Sabbath found", days: -1, iso: "" }
  var days = daysBetween(today, list[0].iso)
  var label = days <= 0 ? "Sabbath today" : (days === 1 ? "Sabbath tomorrow" : "Sabbath in " + days + " days")
  return { label: label, days: days, iso: list[0].iso }
}

function buildView(opts) {
  opts = opts || {}
  var nowMs = typeof opts.nowMs === "number" ? opts.nowMs : Date.now()
  var timeZone = opts.locationConfigured ? String(opts.timeZone || "") : ""
  var rule = ruleById(opts.ruleId)
  var basis = basisById(opts.basisId)
  var lat = opts.locationConfigured ? Number(opts.latitude) : null
  var lon = opts.locationConfigured ? Number(opts.longitude) : null
  if (lat !== null && !isFinite(lat)) lat = null
  if (lon !== null && !isFinite(lon)) lon = null
  var today = todayIso(nowMs, timeZone)
  var selected = parseIso(opts.selectedIso) ? opts.selectedIso : today
  var weekStart = typeof opts.weekStart === "number" ? opts.weekStart : 0
  var cache = monthCache()
  var nowSnap = daySnapshot(today, timeZone, rule.id, basis.id, lat, lon, cache, nowMs)
  var selectedSnap = selected === today
    ? nowSnap
    : daySnapshot(selected, timeZone, rule.id, basis.id, lat, lon, cache, clockOnDate(selected, timeZone, nowMs))
  var until = daysUntilSabbath(today, timeZone, rule.id, basis.id)
  var selectedParts = parseIso(selected)
  var fromMs = selected === today ? nowMs : utcMsFromLocal(selectedParts.year, selectedParts.month, selectedParts.day, 12, 0, timeZone)
  // Start at local midnight so an eclipse earlier on the viewed day is still
  // listed. Countdowns use the same anchor, as on the Sabbaths tab.
  var eclipseFromMs = selected === today
    ? nowMs
    : utcMsFromLocal(selectedParts.year, selectedParts.month, selectedParts.day, 0, 0, timeZone)
  return {
    gold: GOLD,
    todayIso: today,
    selectedIso: selected,
    isToday: selected === today,
    timeZoneLabel: opts.locationConfigured ? (opts.timeZone || "local") : "System timezone",
    locationConfigured: !!opts.locationConfigured,
    locationLabel: opts.locationConfigured ? String(opts.locationLabel || "Saved place") : "",
    rule: rule,
    basis: basis,
    now: nowSnap,
    selected: selectedSnap,
    sabbathCountdown: until.label,
    daysUntilSabbath: until.days,
    nextSabbathIso: until.iso,
    phases: upcomingPhases(fromMs, timeZone),
    sabbaths: sabbathsFrom(selected, timeZone, rule.id, basis.id, 8, today),
    calendar: calendarMonth(selected, today, selected, timeZone, rule.id, basis.id, weekStart),
    cycle: cycleFor(selectedSnap, timeZone),
    eclipses: eclipseCards(eclipseFromMs, timeZone, lat, lon)
  }
}

var session = {
  loaded: false,
  ruleId: "days-8-15-22-29",
  basisId: "conjunction",
  displayMode: "moon",
  locationConfigured: false,
  locationLabel: "",
  latitude: null,
  longitude: null,
  timeZone: "",
  savedLocations: [],
  lastView: "tonight",
  // True until an explicit user change owns the settings. A remembered tab does not.
  preferShellSeed: true
}

function copyLocations(list) {
  var out = []
  if (!list || !list.length) return out
  var i
  for (i = 0; i < list.length; i++) {
    var item = list[i]
    if (!item) continue
    out.push({
      locationLabel: String(item.locationLabel || ""),
      latitude: Number(item.latitude),
      longitude: Number(item.longitude),
      timeZone: String(item.timeZone || "")
    })
  }
  return out
}

function sessionLoaded() {
  return session.loaded
}

function markSessionLoaded() {
  session.loaded = true
}

function remember(patch) {
  if (!patch) return
  var keys = ["ruleId", "basisId", "displayMode", "locationConfigured", "locationLabel", "latitude", "longitude", "timeZone", "preferShellSeed"]
  var i
  for (i = 0; i < keys.length; i++) {
    if (patch[keys[i]] !== undefined) session[keys[i]] = patch[keys[i]]
  }
  if (patch.savedLocations !== undefined) session.savedLocations = copyLocations(patch.savedLocations)
  if (patch.lastView !== undefined && knownView(patch.lastView)) session.lastView = patch.lastView
}

function sessionState() {
  return {
    loaded: session.loaded,
    ruleId: session.ruleId,
    basisId: session.basisId,
    displayMode: session.displayMode,
    locationConfigured: !!session.locationConfigured,
    locationLabel: session.locationLabel || "",
    latitude: session.latitude,
    longitude: session.longitude,
    timeZone: session.timeZone || "",
    savedLocations: copyLocations(session.savedLocations),
    lastView: knownView(session.lastView) ? session.lastView : "tonight",
    preferShellSeed: session.preferShellSeed !== false
  }
}
