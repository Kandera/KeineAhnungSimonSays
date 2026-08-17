-- Loaded after Core.lua. GetTime is stubbed; tests may set KASSTEST.now.
T.eq(KASS.AliasToQuadrant("r"), "W", "rot aliases default west")
T.eq(KASS.AliasToQuadrant("gelb"), "N", "gelb aliases default north")
T.eq(KASS.AliasToQuadrant("n"), "N", "n is north")

KASS.Reset()
KASS.Press("N")
KASS.Press("E")
T.deep_eq(KASS.Sequence(), { "N", "E" }, "press appends quadrants")

KASS.Undo()
T.deep_eq(KASS.Sequence(), { "N" }, "undo pops last")

KASS.Reset()
KASSTEST.now = 10
KASS.Press("S")
KASSTEST.now = 10.4
KASS.Press("S")
T.deep_eq(KASS.Sequence(), { "S" }, "debounce drops same quadrant inside 0.8s")

KASS.Reset()
KASSTEST.now = 20
KASS.Press("W")
KASSTEST.now = 21
KASS.Press("W")
T.deep_eq(KASS.Sequence(), { "W" }, "consecutive duplicate refused")

KASS.SetMarker("N", 6) -- square, default south
T.eq(KASS.Marker("N"), 6, "north took square")
T.eq(KASS.Marker("S"), 1, "south received north's star by swap")
