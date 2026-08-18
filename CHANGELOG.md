# Changelog

**English** | [Deutsch](https://github.com/Kandera/KeineAhnungSimonSays/blob/main/CHANGELOG-de.md)

## [1.1.1] - 2026-08-18

### Fixed
- **No BugGrabber error on load.** 12.x forbids the combat log; Sermon and Echo still follow the boss's casts.

## [1.1.0] - 2026-08-17

### Added
- **Echo calls the sequence back.** Tap N/E/S/W during the Sermon. During Echo you get a turn arrow plus an English word: Left, Right, Forward, Stay.
- **Settings under `/kass`.** Markers, voice on/off, callout, delve-only, lock.
- **Practice without the boss.** `/kass sim [3-7]` runs a round. `/kass echo` starts replay by hand if detection misses.

### Changed
- **Input is NESW, not the four colours.** The board shows raid markers. Old binds (`KASS_RED` etc.) do not carry over — rebind `KASS_NORTH` / `EAST` / `SOUTH` / `WEST` / `RESET` once.
- **Voice does not need Combat Audio Alerts.** These are sound files, not the narrator. Use the GitHub zip; the folder must be named `KeineAhnungSimonSays`; restart the client after install.

## [1.0.1] - 2026-08-13

### Changed
- **Housekeeping only.** Working notes stay out of the repository; CurseForge artwork lives with the source. Nothing in the addon itself.

## [1.0.0] - 2026-08-13

### Added
- **Holds the Simon-Says sequence on Azta'rec** so you do not have to.
- **Three ways to enter a colour:** key bindings, action-bar macros, or clicking the buttons.
- **Sequence and buttons live in separate windows,** each moved and scaled on its own.
- **A grip in each corner resizes**, and `/kass lock` freezes both windows against a stray drag in combat.
- **The sequence clears itself** at the start and end of an encounter.
