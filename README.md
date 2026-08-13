# Keine Ahnung Simon Says

A memory aid for the Simon-Says mechanic of the Delve boss **Azta'rec** (WoW 12.1).

The boss plays a colour sequence — red, blue, yellow, purple — and the player
repeats it by clicking areas in the world. Every round is a fresh sequence, one
step longer than the last. This addon holds the sequence on screen so the player
does not have to hold it in their head.

## What it does not do

It cannot read the mechanic. The client exposes nothing an addon could hook, so
**every colour is entered by hand** while the boss plays it. The addon draws what
was typed, nothing more.

## Input

Three ways, all live at the same time — use whichever feels right:

- **Key bindings.** Five entries under "Keine Ahnung Simon Says" in the
  key-bindings menu. No default keys; bind them yourself.
- **Macros.** `/kass r`, `/kass b`, `/kass y`, `/kass p`, `/kass reset`.
- **Clicking.** The four squares in the window's bottom row.

Other commands: `/kass toggle` hides and shows the window, `/kass scale 1.5`
resizes it. Drag the window with the left mouse button; its position is saved.

## Automatic reset

The sequence clears at `ENCOUNTER_START` and `ENCOUNTER_END`. Round boundaries
inside a fight are not visible to the addon — clear those yourself with the reset
key or button.

## Install

Copy the folder to `World of Warcraft\_retail_\Interface\AddOns\`. The folder
must keep the name `KeineAhnungSimonSays`.

## Test checklist

Not covered by an automated suite. Tick these off in game:

1. All five bindings appear in the key-bindings menu and can be bound
2. Four colours appear in press order
3. 15+ inputs wrap cleanly onto further rows
4. Reset clears the row and the frame shrinks
5. Move the frame, `/reload`, position holds
6. `/kass r b y p` on an action-bar macro appends the same as the bindings
7. Clicking the input squares appends the same as the bindings
8. At the real Azta'rec: all three input paths register inside the encounter

Item 8 is the one that decides. During the encounter the client reports the
`Map`, `Combat`, `Encounter` and `Chat` addon restrictions as active — those gate
protected functions, which this addon never calls. A probe macro confirmed that
unprotected Lua still runs on every keypress inside the fight.
