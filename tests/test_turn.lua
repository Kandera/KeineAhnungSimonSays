-- Relative turns: facing the room center, left = clockwise.

T.eq(KASS.RelativeTurn("N", "E"), "left", "N facing center: east is left")
T.eq(KASS.RelativeTurn("N", "W"), "right", "N facing center: west is right")
T.eq(KASS.RelativeTurn("N", "S"), "forward", "N facing center: south is forward")
T.eq(KASS.RelativeTurn("W", "N"), "left", "W facing center: north is left")
T.eq(KASS.RelativeTurn("W", "S"), "right", "W facing center: south is right")
T.eq(KASS.RelativeTurn("W", "E"), "forward", "W facing center: east is forward")
T.eq(KASS.RelativeTurn("S", "W"), "left", "S facing center: west is left")
T.eq(KASS.RelativeTurn("E", "N"), "right", "E facing center: north is right")
T.eq(KASS.RelativeTurn("E", "E"), "stay", "same pad is stay")
T.eq(KASS.RelativeTurn(nil, "N"), nil, "missing from is nil")

KASS.Reset()
KASS.OnSermonStart()
KASSTEST.now = 100
KASS.Press("W")
KASSTEST.now = 102
KASS.Press("S")
KASSTEST.now = 104
KASS.Press("E")
KASS.OnEchoStart()
T.eq(KASS.Turn(), "forward", "echo 1: last pad E to first pad W is forward")
T.eq(KASS.NextTurn(), "right", "echo 1 next: W to S is right")
KASS.OnEchoTick()
T.eq(KASS.Turn(), "right", "echo 2: W to S is right")
T.eq(KASS.NextTurn(), "right", "echo 2 next: S to E is right")
KASS.OnEchoTick()
T.eq(KASS.Turn(), "right", "echo 3: S to E is right")
T.eq(KASS.NextTurn(), nil, "last wave has no next turn")
