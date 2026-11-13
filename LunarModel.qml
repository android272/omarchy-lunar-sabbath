import QtQuick
import Quickshell
import Quickshell.Io
import "lunar.js" as Lunar

Item {
  id: root
  visible: false
  implicitWidth: 0
  implicitHeight: 0

  property var shellSettings: ({})
  property bool ready: false
  property bool suppress: false
  property string ruleId: "days-8-15-22-29"
  property string basisId: "conjunction"
  property string displayMode: "moon"
  property bool locationConfigured: false
  property string locationLabel: ""
  property var latitude: null
  property var longitude: null
  property string timeZone: ""
  property var savedLocations: []
  property string selectedIso: ""
  property string pendingView: ""
  property string locationMessage: ""
  property var view: ({})
  property bool preferShellSeed: true
  property string pendingZone: ""
  property bool zoneLoading: false

  readonly property string stateDir: {
    var base = Quickshell.env("XDG_STATE_HOME")
    if (!base) base = Quickshell.env("HOME") + "/.local/state"
    return base + "/lunar-sabbath"
  }
  readonly property string statePath: stateDir + "/settings.json"

  function weekStart() {
    var day = Qt.locale().firstDayOfWeek
    if (day === Qt.Sunday) return 0
    if (day >= Qt.Monday && day <= Qt.Saturday) return day
    return 0
  }

  function activeZone() {
    return root.locationConfigured ? root.timeZone : ""
  }

  function options() {
    return {
      nowMs: Date.now(),
      selectedIso: root.selectedIso,
      ruleId: root.ruleId,
      basisId: root.basisId,
      locationConfigured: root.locationConfigured,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      weekStart: root.weekStart()
    }
  }

  function zonePath(zone) {
    if (!zone || zone.indexOf("..") >= 0) return ""
    if (zone === "UTC" || zone === "Etc/UTC" || zone === "Etc/GMT") return "/usr/share/zoneinfo/" + zone
    if (!/^[A-Za-z0-9+\-]+(?:\/[A-Za-z0-9_+\-]+)+$/.test(zone)) return ""
    return "/usr/share/zoneinfo/" + zone
  }

  function refresh() {
    var zone = root.activeZone()
    if (!root.zoneLoading && Lunar.needsZoneFile(zone)) {
      var path = root.zonePath(zone)
      if (path) {
        root.pendingZone = zone
        root.zoneLoading = true
        zoneFile.path = path
        return
      }
    }
    if (root.zoneLoading) return
    root.view = Lunar.buildView(root.options())
  }

  function resolvedIso() {
    if (root.selectedIso && Lunar.parseIso(root.selectedIso)) return root.selectedIso
    return Lunar.todayIso(Date.now(), root.activeZone())
  }

  function pullSession() {
    var state = Lunar.sessionState()
    root.suppress = true
    root.ruleId = state.ruleId || root.ruleId
    root.basisId = state.basisId || root.basisId
    root.displayMode = state.displayMode || root.displayMode
    root.locationConfigured = !!state.locationConfigured
    root.locationLabel = state.locationLabel || ""
    root.latitude = state.locationConfigured ? state.latitude : null
    root.longitude = state.locationConfigured ? state.longitude : null
    root.timeZone = state.locationConfigured ? (state.timeZone || "") : ""
    root.savedLocations = state.savedLocations || []
    root.preferShellSeed = state.preferShellSeed !== false
    root.suppress = false
    if (root.ready) root.refresh()
  }

  function pushSession() {
    root.preferShellSeed = false
    var patch = root.snapshotFields()
    patch.preferShellSeed = false
    Lunar.remember(patch)
    Lunar.markSessionLoaded()
    root.save()
  }

  function knownId(listName, id) {
    var list = listName === "basis" ? Lunar.basisCatalog() : Lunar.ruleCatalog()
    var i
    for (i = 0; i < list.length; i++) if (list[i].id === id) return true
    return false
  }

  function knownMode(id) {
    var list = Lunar.displayModes()
    var i
    for (i = 0; i < list.length; i++) if (list[i].id === id) return true
    return false
  }

  function shellValue(key) {
    if (!root.shellSettings) return ""
    var value = root.shellSettings[key]
    if (value === undefined || value === null) return ""
    return String(value)
  }

  function applySeed() {
    var rule = root.shellValue("sabbathRule")
    var basis = root.shellValue("newMoonBasis")
    var mode = root.shellValue("displayMode")
    if (root.knownId("rule", rule)) root.ruleId = rule
    if (root.knownId("basis", basis)) root.basisId = basis
    if (root.knownMode(mode)) root.displayMode = mode
    if (root.shellSettings && root.shellSettings.latitude !== undefined && root.shellSettings.latitude !== null) {
      var check = Lunar.validateLocation(root.shellSettings.latitude, root.shellSettings.longitude, root.shellSettings.timeZone)
      if (check.ok) {
        root.locationConfigured = true
        root.latitude = check.latitude
        root.longitude = check.longitude
        root.timeZone = check.timeZone
        root.locationLabel = root.shellValue("locationLabel") || "Saved place"
      }
    }
  }

  function applyDocument(doc) {
    if (root.knownId("rule", doc.ruleId)) root.ruleId = doc.ruleId
    if (root.knownId("basis", doc.basisId)) root.basisId = doc.basisId
    if (root.knownMode(doc.displayMode)) root.displayMode = doc.displayMode
    root.savedLocations = root.cleanPlaces(doc.savedLocations)
    if (doc.locationConfigured) {
      var check = Lunar.validateLocation(doc.latitude, doc.longitude, doc.timeZone)
      if (check.ok) {
        root.locationConfigured = true
        root.latitude = check.latitude
        root.longitude = check.longitude
        root.timeZone = check.timeZone
        root.locationLabel = String(doc.locationLabel || "Saved place")
      }
    }
  }

  function cleanPlaces(list) {
    var out = []
    if (!list || !list.length) return out
    var i
    for (i = 0; i < list.length && out.length < 8; i++) {
      var item = list[i]
      if (!item) continue
      var check = Lunar.validateLocation(item.latitude, item.longitude, item.timeZone)
      if (!check.ok) continue
      out.push({
        locationLabel: String(item.locationLabel || "Saved place"),
        latitude: check.latitude,
        longitude: check.longitude,
        timeZone: check.timeZone
      })
    }
    return out
  }

  function snapshotFields() {
    return {
      ruleId: root.ruleId,
      basisId: root.basisId,
      displayMode: root.displayMode,
      locationConfigured: root.locationConfigured,
      locationLabel: root.locationLabel,
      latitude: root.latitude,
      longitude: root.longitude,
      timeZone: root.timeZone,
      savedLocations: root.savedLocations
    }
  }

  function hydrate(raw) {
    if (Lunar.sessionLoaded()) {
      root.pullSession()
      root.ready = true
      root.refresh()
      return
    }
    var parsed = null
    if (String(raw || "").trim() !== "") {
      try {
        var doc = JSON.parse(String(raw))
        if (doc && doc.version === 1) parsed = doc
      } catch (e) {
        parsed = null
      }
    }
    root.suppress = true
    root.ruleId = "days-8-15-22-29"
    root.basisId = "conjunction"
    root.displayMode = "moon"
    root.locationConfigured = false
    root.locationLabel = ""
    root.latitude = null
    root.longitude = null
    root.timeZone = ""
    root.savedLocations = []
    if (!parsed) root.applySeed()
    else root.applyDocument(parsed)
    root.preferShellSeed = !parsed
    root.suppress = false
    var patch = root.snapshotFields()
    patch.preferShellSeed = root.preferShellSeed
    Lunar.remember(patch)
    Lunar.markSessionLoaded()
    root.ready = true
    root.refresh()
  }

  // shell.json can arrive after the first empty-file load. Apply it once,
  // until a settings file or a user change owns the values.
  function considerShellSeed() {
    if (!root.ready || !root.preferShellSeed || root.suppress) return
    root.suppress = true
    root.applySeed()
    root.suppress = false
    var patch = root.snapshotFields()
    patch.preferShellSeed = true
    Lunar.remember(patch)
    root.refresh()
  }

  onShellSettingsChanged: root.considerShellSeed()

  function save() {
    if (!root.ready || root.suppress) return
    var data = root.snapshotFields()
    data.version = 1
    settingsFile.setText(JSON.stringify(data, null, 2) + "\n")
    permissionsTimer.restart()
  }

  function setRule(id) {
    if (!root.knownId("rule", id)) return
    root.ruleId = id
    root.locationMessage = ""
    root.pushSession()
    root.refresh()
  }

  function setBasis(id) {
    if (!root.knownId("basis", id)) return
    root.basisId = id
    root.locationMessage = ""
    root.pushSession()
    root.refresh()
  }

  function setDisplayMode(id) {
    if (!root.knownMode(id)) return
    root.displayMode = id
    root.pushSession()
    root.refresh()
  }

  function stepDate(days) {
    root.selectedIso = Lunar.addDays(root.resolvedIso(), days)
    root.refresh()
  }

  function stepMonth(delta) {
    root.selectedIso = Lunar.shiftMonth(root.resolvedIso(), delta)
    root.refresh()
  }

  function jumpToday() {
    root.selectedIso = ""
    root.refresh()
  }

  function selectDate(iso) {
    if (!Lunar.parseIso(iso)) return
    root.selectedIso = iso
    root.refresh()
  }

  function jumpToPhase(angle) {
    var iso = root.resolvedIso()
    var parts = Lunar.parseIso(iso)
    var start = Lunar.utcMsFromLocal(parts.year, parts.month, parts.day, 0, 0, root.activeZone())
    var event = Lunar.phaseAfter(start, angle, root.activeZone())
    if (event.iso === iso)
      event = Lunar.phaseAfter(start + 36 * 3600000, angle, root.activeZone())
    root.selectedIso = event.iso
    root.pendingView = "tonight"
    root.refresh()
  }

  function jumpToPreviousSabbath() {
    var iso = Lunar.previousSabbathIso(root.resolvedIso(), root.activeZone(), root.ruleId, root.basisId)
    if (iso) root.selectedIso = iso
    root.refresh()
  }

  function jumpToNextSabbath(showSabbaths) {
    root.refresh()
    var iso = root.resolvedIso()
    var list = root.view && root.view.sabbaths ? root.view.sabbaths : []
    var target = ""
    var i
    for (i = 0; i < list.length; i++) {
      if (list[i].iso > iso) {
        target = list[i].iso
        break
      }
    }
    if (!target && root.view && root.view.nextSabbathIso) target = root.view.nextSabbathIso
    if (target) root.selectedIso = target
    // The bottom button only moves the date. The B hotkey still asks the
    // next open to land on Sabbaths.
    if (showSabbaths !== false) root.pendingView = "sabbaths"
    root.refresh()
  }

  function focusNextSabbath() {
    root.refresh()
    if (root.view && root.view.nextSabbathIso) root.selectedIso = root.view.nextSabbathIso
    root.pendingView = "sabbaths"
    root.refresh()
  }

  function samePlace(a, b) {
    if (!a || !b) return false
    return Math.abs(Number(a.latitude) - Number(b.latitude)) < 0.01
      && Math.abs(Number(a.longitude) - Number(b.longitude)) < 0.01
      && String(a.timeZone) === String(b.timeZone)
  }

  function saveLocation(label, latitude, longitude, timeZone) {
    var check = Lunar.validateLocation(latitude, longitude, timeZone)
    if (!check.ok) {
      root.locationMessage = check.message
      return false
    }
    var record = {
      locationLabel: String(label || "").replace(/^\s+|\s+$/g, ""),
      latitude: check.latitude,
      longitude: check.longitude,
      timeZone: check.timeZone
    }
    if (!record.locationLabel)
      record.locationLabel = record.latitude.toFixed(2) + ", " + record.longitude.toFixed(2)
    var next = [record]
    var list = root.savedLocations || []
    var i
    for (i = 0; i < list.length && next.length < 8; i++) {
      if (!root.samePlace(list[i], record)) next.push(list[i])
    }
    root.locationConfigured = true
    root.locationLabel = record.locationLabel
    root.latitude = record.latitude
    root.longitude = record.longitude
    root.timeZone = record.timeZone
    root.savedLocations = next
    root.locationMessage = "Location saved."
    root.pushSession()
    root.refresh()
    return true
  }

  function clearLocation() {
    root.locationConfigured = false
    root.locationLabel = ""
    root.latitude = null
    root.longitude = null
    root.timeZone = ""
    root.locationMessage = "Using this computer's timezone. Saved places are kept."
    root.pushSession()
    root.refresh()
  }

  function activateSaved(record) {
    if (!record) return false
    return root.saveLocation(record.locationLabel, record.latitude, record.longitude, record.timeZone)
  }

  Timer {
    interval: 60000
    repeat: true
    running: root.ready
    onTriggered: root.refresh()
  }

  Process {
    id: ensureDir
    command: ["install", "-d", "-m", "700", root.stateDir]
  }

  FileView {
    id: zoneFile
    watchChanges: false
    printErrors: false
    onLoaded: {
      var bytes = null
      try { bytes = new Uint8Array(zoneFile.data()) } catch (e) { bytes = null }
      if (bytes && root.pendingZone) Lunar.loadZoneBytes(root.pendingZone, bytes)
      root.zoneLoading = false
      if (root.ready) root.refresh()
    }
    onLoadFailed: {
      if (root.pendingZone) Lunar.loadZoneBytes(root.pendingZone, null)
      root.zoneLoading = false
      if (root.ready) root.refresh()
    }
  }

  FileView {
    id: settingsFile
    path: root.statePath
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: root.hydrate(text())
    onLoadFailed: root.hydrate("")
  }

  Timer {
    id: permissionsTimer
    interval: 150
    repeat: false
    onTriggered: chmodProc.running = true
  }

  Process {
    id: chmodProc
    command: ["chmod", "600", root.statePath]
  }

  Component.onCompleted: ensureDir.running = true
}
