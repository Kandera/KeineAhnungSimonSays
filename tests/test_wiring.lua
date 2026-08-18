-- Source guard: 12.x marks COMBAT_LOG_EVENT_UNFILTERED HasRestrictions.
-- RegisterEvent for it is ADDON_ACTION_FORBIDDEN. Detection is UNIT_SPELLCAST_*.

local file = assert(io.open("KASS.lua", "r"))
local source = file:read("*a")
file:close()

T.eq(
	source:find('RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")', 1, true),
	nil,
	"CLEU is not registered"
)
T.eq(
	source:find("CombatLogGetCurrentEventInfo", 1, true),
	nil,
	"CombatLogGetCurrentEventInfo is not used"
)
