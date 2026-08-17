# Keine Ahnung Simon Says

A memory aid for the Simon-Says mechanic on the Delve boss **Azta'rec** in World
of Warcraft 12.1.

During **Sermon of Ula'tek** you tap the sequence by hand. During **Echo of
Ula'tek** the addon calls each step back: a turn arrow on screen and an English
word in your headphones (Left, Right, Forward, Stay). Facing is the room
centre, from the pad the previous wave left you on.

## What it does not do

It cannot see which quarter is safe. You still press N/E/S/W during the Sermon.
The addon records what you pressed and plays it back during the Echo.

It also does not click for you and does not place world markers. Nothing here
touches a protected function.

## Install

1. Download `KeineAhnungSimonSays.zip` from the
   [latest release](https://github.com/Kandera/KeineAhnungSimonSays/releases/latest).
2. Extract it into `World of Warcraft\_retail_\Interface\AddOns\`.
3. Restart the game client. A `/reload` is not enough for a new addon.

The folder must be called exactly `KeineAhnungSimonSays`. Do not use GitHub's
green "Download ZIP" button — it names the folder `KeineAhnungSimonSays-main`
and the game will not find the addon.

## Setting up

Open **Game Menu → Options → AddOns → Keine Ahnung Simon Says**, or type
`/kass` with no arguments. Bind keys under **Key Bindings → Keine Ahnung Simon
Says**.

**Rebind once after upgrading from 1.0.x.** Key names changed from colour binds
(`KASS_RED`, etc.) to compass binds (`KASS_NORTH`, `KASS_EAST`, `KASS_SOUTH`,
`KASS_WEST`, `KASS_RESET`). Old binds do not carry over.

Four keys within reach of your movement hand work best. Pick whatever mirrors
how the quarters are laid out in front of you.

Spoken cues do **not** need Combat Audio Alerts. `/kass sound` plays Left /
Right / Forward / Stay. After replacing sound files, restart the client —
`/reload` keeps the old clips cached.

## Using it

While the boss channels the Sermon, press one key per safe quarter. The tape
fills in the order you pressed. When the Echo casts begin, the callout shows a
gold turn arrow (current) and the next raid marker underneath, and the matching
word plays. The next Sermon clears the tape; use reset only if you need to start
that round over.

Three ways to enter a direction, all live at the same time:

- **Key bindings** — fastest; leaves your action bars alone.
- **Macros** — `/kass n`, `/kass e`, `/kass s`, `/kass w`, `/kass reset` (old
  colour words like `r`/`rot` still map to the default compass slots).
- **Clicking** — the NESW board or slash commands.

If a round records on the tape but never calls, `/kass echo` starts replay by
hand.

## The three windows

1. **Board** — north-up plus layout (N top, W left, E right, S bottom). Click a
   wedge to record a direction.
2. **Tape** — sequence row with reset button.
3. **Callout** — large turn arrow and smaller next marker during Echo replay.

Each window moves and scales on its own. `/kass lock` freezes all three.
`/kass recenter` clears saved positions and restores defaults.

By default **delve-only** hides the windows outside the Azta'rec delve (unless
you are in combat with the boss, running a sim, or use `/kass anywhere`).

## Practice

`/kass sim [3-7]` runs a random practice sequence: auto-records during a fake
Sermon, then replays with real callout and voice. `/kass sim stop` cancels.

## Commands

| Command | Effect |
| --- | --- |
| `/kass` or `/kass options` | open the settings panel |
| `/kass n` `e` `s` `w` | append north, east, south or west |
| `/kass undo` | remove the last recorded direction |
| `/kass reset` | clear the sequence |
| `/kass on` / `/kass off` / `/kass toggle` | show, hide or flip windows |
| `/kass lock` / `/kass unlock` | freeze or release moving and resizing |
| `/kass scale <n>` | set all windows to a scale between 0.5 and 3 |
| `/kass recenter` | reset window positions to defaults |
| `/kass sound` | test Left / Right / Forward / Stay |
| `/kass echo` | start Echo replay from the tape |
| `/kass status` | debug: phase, sequence, map ID |
| `/kass anywhere` | show HUD outside the delve |
| `/kass sim [n]` / `/kass sim stop` | practice run |

German direction words work: `nord`, `ost`, `sued`, `west`. Legacy colour
aliases (`rot`, `blau`, `gelb`, `lila`) map to the default marker slots.

## Automatic reset

The sequence clears at `ENCOUNTER_START` and `ENCOUNTER_END`. A new Sermon also
wipes the previous sequence.

## Compatibility

Built for Interface 120100 (World of Warcraft 12.1, Midnight). Retail only. No
library dependencies, no other addons required.

## Licence

MIT. See [LICENSE](LICENSE).
