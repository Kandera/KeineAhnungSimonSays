## Where this repo lives

Source: `omarchy-lenovo:~/Projects/KeineAhnungSimonSays` (since 2026-11-18). Edit, commit and push there.

Windows test copy: `E:\Projects\KeineAhnungSimonSays` on the desktop `kanderapc`, no `.git`. Never edit it; the next sync overwrites it. To test on Windows, run `pc-sync KeineAhnungSimonSays` on `omarchy-lenovo`, then test on the desktop. `hc exec --on kanderapc '<cmd>'` runs a command there. Windows paths in this repo (`C:\Users\max\...`, `E:\...`) are on the desktop; reach them with `ssh kanderapc`. Details: `machine-setup` README section Repos.

WoW loads the addon through the junction `E:\World of Warcraft\_retail_\Interface\AddOns\KeineAhnungSimonSays` pointing at the test copy. After `pc-sync`, `/reload` in game; new files need a client restart.
