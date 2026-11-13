import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui

Ui.Panel {
  id: root

  moduleName: "lunar.sabbath"
  ipcTarget: "lunar.sabbath"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var model: null
  property string activeView: "tonight"
  property bool showingSettings: false
  property bool showingHotkeys: false
  readonly property bool showingOverlay: showingSettings || showingHotkeys
  readonly property var barIdentity: hostWidget || root

  function open() {
    root.showingSettings = false
    root.showingHotkeys = false
    if (root.model && root.model.pendingView) {
      root.activeView = root.model.pendingView
      root.model.pendingView = ""
    }
    root.controller.show()
    if (root.model) root.model.refresh()
    Qt.callLater(function () {
      if (root.opened) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.showingSettings = false
    root.showingHotkeys = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function refresh() {
    if (root.model) root.model.refresh()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function showView(name) {
    root.showingSettings = false
    root.showingHotkeys = false
    root.activeView = name
    mainFlick.contentY = 0
    if (root.opened) keyCatcher.forceActiveFocus()
  }

  function openSettings() {
    if (root.showingSettings) {
      root.showingSettings = false
      mainFlick.contentY = 0
      if (root.opened) keyCatcher.forceActiveFocus()
      return
    }
    root.showingHotkeys = false
    root.showingSettings = true
    settingsView.syncFields(true)
    mainFlick.contentY = 0
    if (root.opened) keyCatcher.forceActiveFocus()
  }

  function openHotkeys() {
    if (root.showingHotkeys) {
      root.showingHotkeys = false
      mainFlick.contentY = 0
      if (root.opened) keyCatcher.forceActiveFocus()
      return
    }
    root.showingSettings = false
    root.showingHotkeys = true
    mainFlick.contentY = 0
    hotkeysView.resetCursor()
    if (root.opened) keyCatcher.forceActiveFocus()
  }

  function runHotkey(id) {
    if (id === "hotkeys") {
      root.openHotkeys()
      return
    }
    if (id === "settings") {
      root.openSettings()
      return
    }
    if (id === "close") {
      if (root.showingOverlay) {
        root.showingHotkeys = false
        root.showingSettings = false
        mainFlick.contentY = 0
        if (root.opened) keyCatcher.forceActiveFocus()
      } else {
        root.close()
      }
      return
    }
    if (id === "panel-next" || id === "panel-prev") {
      root.switchPanel(id === "panel-next" ? 1 : -1)
      return
    }
    root.showingHotkeys = false
    root.showingSettings = false
    if (id === "tonight" || id === "calendar" || id === "cycle" || id === "sabbaths" || id === "eclipses") {
      root.showView(id)
      return
    }
    if (!root.model) return
    if (id === "prev-day") root.model.stepDate(-1)
    else if (id === "next-day") root.model.stepDate(1)
    else if (id === "prev-week") root.model.stepDate(-7)
    else if (id === "next-week") root.model.stepDate(7)
    else if (id === "today") root.model.jumpToday()
    else if (id === "new-moon") root.model.jumpToPhase(0)
    else if (id === "full-moon") root.model.jumpToPhase(180)
    else if (id === "next-sabbath") root.model.jumpToNextSabbath()
    mainFlick.contentY = 0
    if (root.opened) keyCatcher.forceActiveFocus()
  }

  function commitShared() {
    if (root.hostWidget && root.hostWidget.broadcast) root.hostWidget.broadcast("pullSession")
    else if (root.model) root.model.pullSession()
  }

  function viewingLabel() {
    var view = root.model && root.model.view ? root.model.view : null
    var selected = view && view.selected ? view.selected : null
    if (!selected || !selected.headingDate) return ""
    if (view.isToday) return "Tonight - " + selected.headingDate
    return selected.headingDate
  }

  Ui.KeyboardPanel {
    id: popup
    open: root.opened
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.barIdentity
    contentWidth: fittedContentWidth(Style.space(460), Style.space(520))
    // Day navigation is pinned to the card floor, outside the scrolling
    // column, so every tab keeps it in view. Count that row in the fitted
    // height or a short tab clips the buttons.
    contentHeight: fittedContentHeight(
      page.implicitHeight + (dayNav.visible ? dayNav.implicitHeight + Style.spacing.md : 0),
      Style.space(700))
    focusTarget: keyCatcher

    onOpenChanged: mainFlick.contentY = 0

    Ui.PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.showingSettings && settingsView.typing

      onCloseRequested: {
        if (root.showingOverlay) {
          root.showingSettings = false
          root.showingHotkeys = false
          mainFlick.contentY = 0
          if (root.opened) keyCatcher.forceActiveFocus()
        } else root.close()
      }

      onMoveRequested: function (dx, dy) {
        if (root.showingHotkeys) {
          if (dy !== 0) hotkeysView.moveCursor(dy)
          return
        }
        if (root.showingOverlay || !root.model) return
        if (dx !== 0) root.model.stepDate(dx)
        if (dy !== 0) root.model.stepDate(dy * 7)
      }

      onActivateRequested: {
        if (root.showingHotkeys) hotkeysView.activate()
      }

      onTabRequested: function (direction) {
        root.switchPanel(direction)
      }

      onTextKey: function (text) {
        if (root.showingSettings || root.showingHotkeys) {
          if (text === "g" || text === "G") root.openSettings()
          else if (text === "?") root.openHotkeys()
          return
        }
        var key = text.toLowerCase()
        if (key === "1") root.showView("tonight")
        else if (key === "2") root.showView("calendar")
        else if (key === "3") root.showView("cycle")
        else if (key === "4") root.showView("sabbaths")
        else if (key === "5") root.showView("eclipses")
        else if (key === "t") root.model.jumpToday()
        else if (key === "n") root.model.jumpToPhase(0)
        else if (key === "f") root.model.jumpToPhase(180)
        else if (key === "b") root.model.jumpToNextSabbath()
        else if (key === "g") root.openSettings()
        else if (text === "?") root.openHotkeys()
      }

      Item {
        id: scrollHost
        anchors.fill: parent

        // Updated after layout. Binding the gutter straight to content height
        // loops, because the gutter changes the width that changes that height.
        property real gutter: 0
        property int syncDepth: 0

        function syncGutter() {
          if (syncDepth > 2) return
          syncDepth++
          var bar = vScroll.implicitWidth
          if (bar < 1) bar = Style.space(8)
          var needed = mainFlick.contentHeight > mainFlick.height + 0.5
          var next = needed ? Math.ceil(bar) + Style.spacing.sm : 0
          if (Math.abs(gutter - next) > 0.5)
            gutter = next
          syncDepth--
        }

        Flickable {
          id: mainFlick
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.bottomMargin: dayNav.visible ? dayNav.implicitHeight + Style.spacing.md : 0
          width: parent.width - scrollHost.gutter
          clip: true
          contentWidth: width
          contentHeight: page.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height

          onContentHeightChanged: scrollHost.syncGutter()
          onHeightChanged: scrollHost.syncGutter()
          onWidthChanged: scrollHost.syncGutter()
          // Declared as a sibling below. Nesting it here makes Qt parent it to
          // the Flickable and paint it on top of the text.
          Controls.ScrollBar.vertical: vScroll

          Column {
            id: page
            width: mainFlick.width
            spacing: Style.spacing.md

            Row {
              id: titleRow
              width: parent.width
              spacing: Style.spacing.sm
              readonly property real hotkeysSlot: hotkeysButton.visible ? hotkeysButton.width : 0
              readonly property real settingsSlot: settingsButton.width
              readonly property int headerGaps: (hotkeysButton.visible ? 1 : 0) + 1

              Text {
                width: Math.max(0, titleRow.width - titleRow.hotkeysSlot - titleRow.settingsSlot - titleRow.spacing * titleRow.headerGaps)
                text: "Lunar Sabbath"
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
              }
              TextButton {
                id: hotkeysButton
                visible: !root.showingOverlay
                icon: "󰌌"
                accessibleName: "Hotkeys"
                onClicked: root.openHotkeys()
              }
              TextButton {
                id: settingsButton
                icon: root.showingOverlay ? "󰅖" : "󰒓"
                accessibleName: root.showingHotkeys ? "Close hotkeys" : (root.showingSettings ? "Close settings" : "Settings")
                onClicked: {
                  if (root.showingHotkeys) root.openHotkeys()
                  else root.openSettings()
                }
              }
            }

            Text {
              width: parent.width
              visible: !root.showingOverlay
              text: root.viewingLabel()
              color: Color.popups.text
              elide: Text.ElideRight
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            Row {
              width: parent.width
              visible: !root.showingOverlay
              spacing: Style.space(4)
              Repeater {
                // Nerd-font glyphs sit left of the label: full moon, calendar,
                // waxing crescent + full moon + waning crescent, fire, solar eclipse.
                model: [
                  { id: "tonight", label: "Tonight", icon: String.fromCodePoint(0xF0F62) },
                  { id: "calendar", label: "Calendar", icon: String.fromCodePoint(0xF00ED) },
                  { id: "cycle", label: "Cycle", icon: String.fromCodePoint(0xF0F67, 0xF0F62, 0xF0F65) },
                  { id: "sabbaths", label: "Sabbaths", icon: String.fromCodePoint(0xF0238) },
                  { id: "eclipses", label: "Eclipses", icon: String.fromCodePoint(0xE368) }
                ]
                delegate: TextButton {
                  required property var modelData
                  width: (parent.width - Style.space(4) * 4) / 5
                  label: modelData.label
                  icon: modelData.icon
                  selected: root.activeView === modelData.id
                  onClicked: root.showView(modelData.id)
                }
              }
            }

            TonightView {
              visible: !root.showingOverlay && root.activeView === "tonight"
              day: root.model && root.model.view ? root.model.view.selected : null
              phases: root.model && root.model.view ? root.model.view.phases : []
              viewingToday: root.model && root.model.view ? root.model.view.isToday : true
              basisLabel: root.model && root.model.view && root.model.view.basis ? root.model.view.basis.label : ""
            }

            CalendarView {
              visible: !root.showingOverlay && root.activeView === "calendar"
              calendar: root.model && root.model.view ? root.model.view.calendar : null
              onPickDate: function (iso) {
                if (!root.model) return
                root.model.selectDate(iso)
                root.showView("tonight")
              }
              onShiftMonth: function (delta) { if (root.model) root.model.stepMonth(delta) }
            }

            CycleView {
              visible: !root.showingOverlay && root.activeView === "cycle"
              cycle: root.model && root.model.view ? root.model.view.cycle : null
              day: root.model && root.model.view ? root.model.view.selected : null
              ruleShort: root.model && root.model.view && root.model.view.rule ? root.model.view.rule.short : ""
            }

            SabbathsView {
              visible: !root.showingOverlay && root.activeView === "sabbaths"
              sabbaths: root.model && root.model.view ? root.model.view.sabbaths : []
              ruleShort: root.model && root.model.view && root.model.view.rule ? root.model.view.rule.short : ""
              onPickDate: function (iso) { if (root.model) root.model.selectDate(iso) }
            }

            EclipsesView {
              visible: !root.showingOverlay && root.activeView === "eclipses"
              eclipses: root.model && root.model.view ? root.model.view.eclipses : []
            }

            HotkeysView {
              id: hotkeysView
              visible: root.showingHotkeys
              viewport: mainFlick
              onInvoked: function (id) { root.runHotkey(id) }
            }

            SettingsView {
              id: settingsView
              visible: root.showingSettings
              model: root.model
              ruleId: root.model ? root.model.ruleId : ""
              basisId: root.model ? root.model.basisId : ""
              explanation: root.model && root.model.view && root.model.view.rule ? root.model.view.rule.explanation : ""
              locationConfigured: root.model ? root.model.locationConfigured : false
              locationLabel: root.model ? root.model.locationLabel : ""
              savedLocations: root.model ? root.model.savedLocations : []
              message: root.model ? root.model.locationMessage : ""
              onRuleChosen: function (id) {
                if (!root.model) return
                root.model.setRule(id)
                root.commitShared()
              }
              onBasisChosen: function (id) {
                if (!root.model) return
                root.model.setBasis(id)
                root.commitShared()
              }
              onLocationSubmitted: function (label, latitude, longitude, zone) {
                if (!root.model) return
                if (root.model.saveLocation(label, latitude, longitude, zone)) {
                  settingsView.syncFields(true)
                  root.commitShared()
                }
              }
              onSavedActivated: function (place) {
                if (!root.model) return
                if (root.model.activateSaved(place)) {
                  settingsView.syncFields(true)
                  root.commitShared()
                }
              }
              onLocationCleared: {
                if (!root.model) return
                root.model.clearLocation()
                settingsView.syncFields(true)
                root.commitShared()
              }
            }
          }
        }

        Controls.ScrollBar {
          id: vScroll
          anchors.top: mainFlick.top
          anchors.bottom: mainFlick.bottom
          anchors.right: parent.right
          policy: scrollHost.gutter > 0
            ? Controls.ScrollBar.AlwaysOn : Controls.ScrollBar.AlwaysOff
          onImplicitWidthChanged: scrollHost.syncGutter()
        }

        Row {
          id: dayNav
          visible: !root.showingOverlay
          anchors.left: mainFlick.left
          anchors.right: mainFlick.right
          anchors.bottom: parent.bottom
          spacing: Style.spacing.sm

          // The arrow buttons stay as wide as their labels and sit on the
          // content edges. The five labeled buttons share the leftover width
          // in equal amounts, so the row fills the card inside its padding.
          function labeledWidth(index) {
            var labeled = [prevSabbath, prevPhase, todayButton, nextPhase, nextSabbath]
            var count = labeled.length
            var button = labeled[index]
            if (!button || !prevDay || !nextDay || width < 1) return button ? button.implicitWidth : 0
            var naturalSum = 0
            var i
            for (i = 0; i < count; i++) {
              if (!labeled[i]) return button.implicitWidth
              naturalSum += labeled[i].implicitWidth
            }
            var budget = width - spacing * (count + 1) - prevDay.implicitWidth - nextDay.implicitWidth
            if (budget < 1 || naturalSum < 1) return button.implicitWidth
            var extra = (budget - naturalSum) / count
            if (index < count - 1) return button.implicitWidth + extra
            var used = 0
            for (i = 0; i < count - 1; i++) used += labeled[i].implicitWidth + extra
            return budget - used
          }

          TextButton {
            id: prevDay
            label: "<"
            accessibleName: "Previous day"
            onClicked: if (root.model) root.model.stepDate(-1)
          }
          TextButton {
            id: prevSabbath
            width: dayNav.labeledWidth(0)
            label: "< Sabbath"
            accessibleName: "Previous Sabbath"
            gold: true
            onClicked: if (root.model) root.model.jumpToPreviousSabbath()
          }
          TextButton {
            id: prevPhase
            width: dayNav.labeledWidth(1)
            label: "< Phase"
            accessibleName: "Previous moon phase"
            onClicked: if (root.model) root.model.jumpPhaseBy(-1)
          }
          TextButton {
            id: todayButton
            width: dayNav.labeledWidth(2)
            label: "Today"
            onClicked: if (root.model) root.model.jumpToday()
          }
          TextButton {
            id: nextPhase
            width: dayNav.labeledWidth(3)
            label: "Phase >"
            accessibleName: "Next moon phase"
            onClicked: if (root.model) root.model.jumpPhaseBy(1)
          }
          TextButton {
            id: nextSabbath
            width: dayNav.labeledWidth(4)
            label: "Sabbath >"
            accessibleName: "Next Sabbath"
            gold: true
            onClicked: if (root.model) root.model.jumpToNextSabbath(false)
          }
          TextButton {
            id: nextDay
            label: ">"
            accessibleName: "Next day"
            onClicked: if (root.model) root.model.stepDate(1)
          }
        }

        Component.onCompleted: Qt.callLater(scrollHost.syncGutter)
      }
    }
  }
}
