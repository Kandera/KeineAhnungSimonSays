KASS.sermonSeen = false
KASS.Reset()
KASS.Press("N")
T.deep_eq(KASS.Sequence(), { "N" }, "idle no sermon: press works")

KASS.OnSermonStart()
KASS.Press("E")
KASS.Press("S")
T.deep_eq(KASS.Sequence(), { "E", "S" }, "recording after sermon: press works")

KASS.OnEchoStart()
KASS.Press("W")
T.deep_eq(KASS.Sequence(), { "E", "S" }, "replaying: press ignored")

KASS.OnEchoEnd()
T.eq(KASS.Phase(), "idle", "echo end idle")
KASS.Press("N")
T.deep_eq(KASS.Sequence(), { "E", "S" }, "idle after sermon seen: press ignored")

KASS.OnSermonStart()
KASS.Press("N")
T.deep_eq(KASS.Sequence(), { "N" }, "next sermon: press works")
