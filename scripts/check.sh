#!/usr/bin/env bash
# Calculation, manifest, qmllint, and headless Quickshell checks.
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root_dir"

echo "node: lunar.test.js"
node tests/lunar.test.js
echo "node: coordfield.test.js"
node tests/coordfield.test.js

echo "validate: manifest"
omarchy plugin validate "$root_dir"

omarchy_root="${OMARCHY_PATH:-/usr/share/omarchy}"
qml_lint="${QMLLINT:-}"
if [[ -z "$qml_lint" ]]; then
  qml_lint="$(command -v qmllint || true)"
fi
if [[ -z "$qml_lint" && -x /usr/lib/qt6/bin/qmllint ]]; then
  qml_lint="/usr/lib/qt6/bin/qmllint"
fi
if [[ -z "$qml_lint" ]]; then
  echo "qmllint was not found" >&2
  exit 1
fi

qml_files=(
  MoonDisk.qml
  SkyIcon.qml
  TextButton.qml
  TonightView.qml
  CalendarView.qml
  CycleView.qml
  SabbathsView.qml
  EclipsesView.qml
  HotkeysView.qml
  SettingsView.qml
  CoordField.qml
  LunarModel.qml
  Panel.qml
  BarWidget.qml
)

qml_imports=()
if [[ -f "$omarchy_root/shell/Ui/qmldir" && -f "$omarchy_root/shell/Commons/qmldir" ]]; then
  qml_imports=(
    -i "$omarchy_root/shell/Commons/qmldir"
    -i "$omarchy_root/shell/Ui/qmldir"
  )
fi

echo "qmllint"
"$qml_lint" -W 0 \
  --signal-handler-parameters disable \
  --missing-property disable \
  --unqualified disable \
  --unused-imports warning \
  --block-scope-var-declaration disable \
  "${qml_imports[@]}" "${qml_files[@]}"

quickshell_bin=$(command -v qs || command -v quickshell || true)
if [[ -z "$quickshell_bin" ]]; then
  echo "quickshell was not found" >&2
  exit 1
fi

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/lunar-sabbath-qml.XXXXXX")
cleanup() {
  rm -rf "$stage_dir"
}
trap cleanup EXIT

mkdir -p "$stage_dir/repo" "$stage_dir/runtime" "$stage_dir/state" \
  "$stage_dir/cache" "$stage_dir/config" "$stage_dir/home"
chmod 700 "$stage_dir/runtime" "$stage_dir/state"
cp -a "$root_dir/." "$stage_dir/repo/"
cp -a "$omarchy_root/shell/Commons" "$stage_dir/repo/Commons"
cp -a "$omarchy_root/shell/Ui" "$stage_dir/repo/Ui"

run_scene() {
  local scene=$1
  local marker=$2
  local scale=${3:-1}
  local log_file="$stage_dir/$(basename "$scene")-s${scale}.log"
  local staged_scene="$stage_dir/repo/shell.qml"

  cp "$stage_dir/repo/$scene" "$staged_scene"
  sed -i -e 's#import "../../#import "./#g' "$staged_scene"

  if ! timeout 30s env -u DISPLAY -u WAYLAND_DISPLAY \
    XDG_CONFIG_HOME="$stage_dir/config" \
    XDG_STATE_HOME="$stage_dir/state" \
    XDG_CACHE_HOME="$stage_dir/cache" \
    XDG_RUNTIME_DIR="$stage_dir/runtime" \
    HOME="$stage_dir/home" \
    QT_QPA_PLATFORM=minimal \
    QT_QUICK_BACKEND=software \
    QT_SCALE_FACTOR="$scale" \
    QT_QPA_PLATFORMTHEME= \
    "$quickshell_bin" --no-color -p "$staged_scene" >"$log_file" 2>&1; then
    sed -n '1,240p' "$log_file" >&2
    echo "quickshell: $scene failed" >&2
    exit 1
  fi

  if ! grep -Fq "$marker" "$log_file"; then
    sed -n '1,240p' "$log_file" >&2
    echo "quickshell: $scene did not reach $marker" >&2
    exit 1
  fi
  # Headless Quickshell does not initialize the Omarchy Color singleton, so
  # theme-token lookups warn. Load failures and bad assignments still fail.
  if grep -E -q "Cannot assign|Failed to load|is not a type" "$log_file"; then
    sed -n '1,240p' "$log_file" >&2
    echo "quickshell: $scene reported an error" >&2
    exit 1
  fi
  grep -E "Intl |quarter disk|settings persisted|views loaded" "$log_file" || true
  echo "quickshell: $scene OK"
}

run_scene tests/qml/CalcSmoke.qml "CalcSmoke: buildView OK"
run_scene tests/qml/ZoneSmoke.qml "ZoneSmoke: Jerusalem offset OK"
run_scene tests/qml/RenderSmoke.qml "RenderSmoke: quarter disk lit on the right OK"
run_scene tests/qml/RenderSmoke.qml "RenderSmoke: quarter disk lit on the right OK" 2
run_scene tests/qml/PartsSmoke.qml "PartsSmoke: views loaded OK"
run_scene tests/qml/CoordSmoke.qml "CoordSmoke: affixes locked OK"
run_scene tests/qml/StateSmoke.qml "StateSmoke: settings persisted OK"

python3 - "$stage_dir/state/lunar-sabbath/settings.json" <<'PY'
from pathlib import Path
import json
import stat
import sys

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit("state smoke did not create settings.json")
doc = json.loads(path.read_text(encoding="utf-8"))
if doc.get("version") != 1:
    raise SystemExit("persisted state has no version 1")
if doc.get("ruleId") != "days-7-14-21-28":
    raise SystemExit("persisted rule was overwritten or not saved")
if doc.get("basisId") != "crescent-1" or doc.get("displayMode") != "letter":
    raise SystemExit("persisted basis or display mode does not match the seed")
if doc.get("locationConfigured") is not True or doc.get("timeZone") != "America/Chicago":
    raise SystemExit("persisted location was not saved")
if doc.get("locationLabel") != "Runtime Test":
    raise SystemExit("persisted location label was not saved")
if abs(float(doc.get("latitude")) - 41.88) > 0.001 or abs(float(doc.get("longitude")) + 87.63) > 0.001:
    raise SystemExit("persisted coordinates were not saved")
saved = doc.get("savedLocations")
if not isinstance(saved, list) or len(saved) != 1 or saved[0].get("locationLabel") != "Runtime Test":
    raise SystemExit("saved-place list was not persisted")
if stat.S_IMODE(path.stat().st_mode) != 0o600:
    raise SystemExit("persisted state is not mode 0600")
if stat.S_IMODE(path.parent.stat().st_mode) != 0o700:
    raise SystemExit("state directory is not mode 0700")
PY

echo "check: OK"
