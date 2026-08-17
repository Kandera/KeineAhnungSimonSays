# Changelog

[English](https://github.com/Kandera/KeineAhnungSimonSays/blob/main/CHANGELOG.md) | **Deutsch**

## [1.1.0] - 2026-08-17

### Hinzugefügt
- **Echo ruft die Sequenz zurück.** Im Sermon tippst du N/E/S/W. Im Echo kommt ein Pfeil plus englisches Wort: Left, Right, Forward, Stay.
- **Einstellungen unter `/kass`.** Marker, Stimme an/aus, Callout, nur in der Delve, Lock.
- **Übung ohne Boss.** `/kass sim [3-7]` spielt eine Runde durch. `/kass echo` startet das Replay von Hand, falls die Erkennung danebenliegt.

### Geändert
- **Eingabe ist NESW, nicht mehr die vier Farben.** Das Board zeigt Raid-Marker. Alte Binds (`KASS_RED` usw.) gelten nicht — einmal `KASS_NORTH` / `EAST` / `SOUTH` / `WEST` / `RESET` neu belegen.
- **Die Stimme braucht keine Kampfaudio-Alerts.** Das sind Sounddateien, nicht die Vorlesestimme. Zip von GitHub, Ordner muss `KeineAhnungSimonSays` heißen, Client danach neu starten.

## [1.0.1] - 2026-08-13

### Geändert
- **Nur Haushalt.** Die Arbeitsnotizen bleiben raus aus dem Repo, die CurseForge-Grafik liegt bei den Quellen. Am Addon selbst ändert sich nichts.

## [1.0.0] - 2026-08-13

### Hinzugefügt
- **Hält die Simon-Says-Sequenz auf Azta'rec**, damit du sie nicht im Kopf halten musst.
- **Drei Wege zur Farbe:** Tasten, Macros, Klick auf die Buttons.
- **Sequenz und Buttons in getrennten Fenstern**, jeweils verschieb- und skalierbar.
- **Griff zum Skalieren**, `/kass lock` friert die Fenster im Kampf ein.
- **Die Sequenz leert sich** am Start und Ende des Encounters.
