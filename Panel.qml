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
  readonly property var barIdentity: hostWidget || root

  function open() {
    root.showingSettings = false
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
    root.activeView = name
    mainFlick.contentY = 0
    if (root.opened) keyCatcher.forceActiveFocus()
  }

  function commitShared() {
    if (root.hostWidget && root.hostWidget.broadcast) root.hostWidget.broadcast("pullSession")
    else if (root.model) root.model.pullSession()
  }

  Ui.KeyboardPanel {
    id: popup
    open: root.opened
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.barIdentity
    contentWidth: fittedContentWidth(Style.space(460), Style.space(520))
    contentHeight: fittedContentHeight(page.implicitHeight, Style.space(700))
    focusTarget: keyCatcher

    onOpenChanged: mainFlick.contentY = 0

    Ui.PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.showingSettings && settingsView.typing

      onCloseRequested: {
        if (root.showingSettings) root.showingSettings = false
        else root.close()
      }

      onMoveRequested: function (dx, dy) {
        if (root.showingSettings || !root.model) return
        if (dx !== 0) root.model.stepDate(dx)
        if (dy !== 0) root.model.stepDate(dy * 7)
      }

      onTabRequested: function (direction) {
        root.switchPanel(direction)
      }

      onTextKey: function (text) {
        if (root.showingSettings) {
          if (text === "g" || text === "G") root.showingSettings = false
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
        else if (key === "g") {
          root.showingSettings = true
          settingsView.syncFields(true)
          mainFlick.contentY = 0
        }
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
              width: parent.width
              spacing: Style.spacing.sm
              Text {
                width: parent.width - settingsButton.width - parent.spacing
                text: "Lunar Sabbath"
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
              }
              TextButton {
                id: settingsButton
                icon: root.showingSettings ? "󰅖" : "󰒓"
                accessibleName: root.showingSettings ? "Close settings" : "Settings"
                onClicked: {
                  root.showingSettings = !root.showingSettings
                  if (root.showingSettings) settingsView.syncFields(true)
                  mainFlick.contentY = 0
                }
              }
            }

            Text {
              width: parent.width
              visible: !root.showingSettings
              text: (root.model && root.model.view && root.model.view.rule ? root.model.view.rule.short : "Rule")
                + (root.model && root.model.view && root.model.view.basis ? "  ·  " + root.model.view.basis.label : "")
              color: Color.popups.text
              opacity: 0.8
              wrapMode: Text.WordWrap
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Row {
              width: parent.width
              visible: !root.showingSettings
              spacing: Style.spacing.sm
              TextButton {
                label: "<"
                accessibleName: "Previous day"
                onClicked: if (root.model) root.model.stepDate(-1)
              }
              Text {
                width: parent.width - Style.space(150)
                anchors.verticalCenter: parent.verticalCenter
                text: root.model && root.model.view && root.model.view.selected
                  ? root.model.view.selected.dateLabel : ""
                color: Color.popups.text
                horizontalAlignment: Text.AlignHCenter
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }
              TextButton {
                label: ">"
                accessibleName: "Next day"
                onClicked: if (root.model) root.model.stepDate(1)
              }
              TextButton { label: "Today"; onClicked: if (root.model) root.model.jumpToday() }
            }

            Row {
              width: parent.width
              visible: !root.showingSettings
              spacing: Style.space(4)
              Repeater {
                model: [
                  { id: "tonight", label: "Tonight", key: "1" },
                  { id: "calendar", label: "Calendar", key: "2" },
                  { id: "cycle", label: "Cycle", key: "3" },
                  { id: "sabbaths", label: "Sabbaths", key: "4" },
                  { id: "eclipses", label: "Eclipses", key: "5" }
                ]
                delegate: TextButton {
                  required property var modelData
                  width: (parent.width - Style.space(4) * 4) / 5
                  label: modelData.label
                  selected: root.activeView === modelData.id
                  onClicked: root.showView(modelData.id)
                }
              }
            }

            TonightView {
              visible: !root.showingSettings && root.activeView === "tonight"
              day: root.model && root.model.view ? root.model.view.selected : null
              phases: root.model && root.model.view ? root.model.view.phases : []
              viewingToday: root.model && root.model.view ? root.model.view.isToday : true
              basisLabel: root.model && root.model.view && root.model.view.basis ? root.model.view.basis.label : ""
              onJumpPhase: function (angle) { if (root.model) root.model.jumpToPhase(angle) }
              onJumpSabbath: {
                if (!root.model) return
                root.model.jumpToNextSabbath()
                root.showView("sabbaths")
              }
            }

            CalendarView {
              visible: !root.showingSettings && root.activeView === "calendar"
              calendar: root.model && root.model.view ? root.model.view.calendar : null
              onPickDate: function (iso) {
                if (!root.model) return
                root.model.selectDate(iso)
                root.showView("tonight")
              }
              onShiftMonth: function (delta) { if (root.model) root.model.stepMonth(delta) }
            }

            CycleView {
              visible: !root.showingSettings && root.activeView === "cycle"
              cycle: root.model && root.model.view ? root.model.view.cycle : null
              day: root.model && root.model.view ? root.model.view.selected : null
              ruleShort: root.model && root.model.view && root.model.view.rule ? root.model.view.rule.short : ""
            }

            SabbathsView {
              visible: !root.showingSettings && root.activeView === "sabbaths"
              sabbaths: root.model && root.model.view ? root.model.view.sabbaths : []
              ruleShort: root.model && root.model.view && root.model.view.rule ? root.model.view.rule.short : ""
              onPickDate: function (iso) { if (root.model) root.model.selectDate(iso) }
            }

            EclipsesView {
              visible: !root.showingSettings && root.activeView === "eclipses"
              eclipses: root.model && root.model.view ? root.model.view.eclipses : []
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
              onCloseRequested: root.showingSettings = false
            }

            Text {
              width: parent.width
              visible: !root.showingSettings
              text: "1–5 tabs · arrows move the date · T today · N new · F full · B sabbath · G settings · Esc closes"
              color: Color.popups.text
              opacity: 0.45
              wrapMode: Text.WordWrap
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
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

        Component.onCompleted: Qt.callLater(scrollHost.syncGutter)
      }
    }
  }
}
