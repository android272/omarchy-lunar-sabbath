# Lunar Sabbath

An offline Omarchy bar plugin for the Moon: phase, calendar, lunar cycle, eclipses, and local moonrise and moonset. Configurable Sabbath rules are part of the same widget, so one plugin covers both the astronomy and the counting systems.

The plugin does not decide which Sabbath count is correct. The active rule is labeled on the panel, and switching rules updates the gold highlighting and the Sabbath lists.

Vibecoded: built with AI assistance rather than typed by hand.

## Bar

The widget is separate from the clock. It draws the illuminated portion of the Moon, north up: waxing light is on the right. A new moon is a dark disk with a rim so the empty moon stays visible. Every other phase is only the lit shape, with no ring. The disk uses the bar color. On a Sabbath under the active rule it turns gold.

- Left click opens the panel on Tonight.
- Middle click opens the panel on the next Sabbath, counting today when today is one.
- Right click cycles the bar label: moon only, illumination percent, `S` on Sabbath days, and the word Sabbath on Sabbath days.
- The hover tooltip shows the phase, illumination, days until the next Sabbath, and the active rule.

Extra labels are hidden when the bar is vertical. The mode still cycles, and the tooltip names it.

## Panel

Tonight, Calendar, Cycle, Sabbaths, and Eclipses share one selected date. Settings open from the cog-style Settings button.

Keyboard, when the panel is open and a text field is not focused:

| Key | Action |
| --- | --- |
| 1–5 | Tonight, Calendar, Cycle, Sabbaths, Eclipses |
| Left / Right | Previous or next day |
| Up / Down | Previous or next week |
| T | Today |
| N | Next new moon |
| F | Next full moon |
| B | Next Sabbath |
| G | Settings |
| Esc | Close settings, then the panel |

Tab still moves between shell panels.

## Sabbath rules

Lunar days are local civil dates, midnight to midnight. A location is not required for the phase or the Sabbath count.

- **1 / 8 / 15 / 22 / 29.** Day 1 is the new moon, marked as a special day rather than a Sabbath. Sabbaths are days 8, 15, 22, and 29. Day 30, when the month has one, is only a transition.
- **7 / 14 / 21 / 28.** Sabbaths fall on those lunar days.
- **Continuous week (Saturday).** An unbroken Saturday Sabbath for comparison. It ignores the new-moon basis.

The new-moon basis shifts lunar day 1:

- Calculated conjunction: the local date of the astronomical new moon.
- First visible crescent, +1 day.
- First visible crescent, +2 days.

These offsets are a simple stand-in for first visibility, not a sighting model.

## Location

Moonrise, moonset, and local eclipse visibility use a latitude, longitude, and IANA timezone. Phase and Sabbaths work without them and follow the computer's timezone. The shell has no `Intl` timezone database, so a saved timezone is read from `/usr/share/zoneinfo`.

Settings can search a small built-in city list, save a place entered by hand, or clear the active location while keeping saved places. Times are 24-hour.

## Eclipses

The next lunar and solar eclipses are estimated offline from the same low-precision Sun and Moon used for the phase. The panel labels those times as approximate. Penumbral lunar eclipses are included and described as subtle. A solar eclipse's global type can differ from what is visible at the saved location.

## Install

From a git remote:

```bash
omarchy plugin add <git-url> --enable
```

From this repository directory:

```bash
omarchy plugin validate .
install_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/lunar.sabbath"
rm -rf "$install_dir"
mkdir -p "$install_dir"
cp -a "$PWD"/. "$install_dir"/
omarchy-shell shell rescanPlugins
omarchy plugin enable lunar.sabbath
```

Run that from the repository, not from your home directory. `cp -a .` from `~` tries to copy your home directory into the plugin folder. `enable` adds the widget to the bar. The manifest's default section is the right side. If enable says the plugin is not known, the rescan line above is the one to run; the command is `rescanPlugins`.

Settings are stored in `${XDG_STATE_HOME:-~/.local/state}/lunar-sabbath/settings.json`. The directory is mode `0700` and the file is mode `0600`. After the first save, that file wins over the `shell.json` seed (`displayMode`, `sabbathRule`, `newMoonBasis`).

## Checks

```bash
scripts/check.sh
```

That runs the calculation tests, `omarchy plugin validate`, `qmllint`, and headless Quickshell smokes for the astronomy library, the drawn moon, and settings persistence. The smokes use a temporary state directory and do not enable the plugin.
