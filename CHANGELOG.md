# Changelog

## 1.1.0 — 2026-08-17

- **NESW compass input** replaces the four colour buttons; raid marker icons show each quarter.
- **Echo replay:** tap during Sermon of Ula'tek; during Echo the addon calls each step with a turn arrow and an English word (Left / Right / Forward / Stay).
- Spoken cues are addon sound files, so they work in the fight without Combat Audio Alerts. The combat log is secret in Midnight — replay follows the boss channel, then his echo casts.
- **Settings panel** (`/kass`, AddOns category): marker picker, voice on/off, callout toggles, delve-only, lock, show.
- **Practice sim** (`/kass sim [3-7]`). `/kass echo` starts replay by hand if detection misses.
- **Rebind required:** old `KASS_RED`/`BLUE`/`YELLOW`/`PURPLE` keybinds do not carry over — use `KASS_NORTH` etc.

## 1.0.1 — 2026-08-13

- No changes to the addon itself. Housekeeping only: the working notes stay out
  of the repository, and the CurseForge artwork lives with the source.

## 1.0.0 — 2026-08-13

- **Holds the Simon-Says sequence on Azta'rec** so you do not have to.
- **Three ways to enter a colour:** key bindings, action-bar macros, or clicking
  the buttons.
- **Sequence and buttons live in separate windows,** each moved and scaled on
  its own.
- **A grip in each corner resizes**, and `/kass lock` freezes both windows
  against a stray drag in combat.
- **The sequence clears itself** at the start and end of an encounter.
