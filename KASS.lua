-- Addon glue: SavedVariables, slash, events. Sequence logic lives in Core.lua.

local ADDON_NAME = ...

KASS = KASS or {}

-- Delve map IDs where HUD may show when delveOnly is on.
-- 2512 = Coiled Isle (Azta'rec), from Icy Veins /way — run /kass status in the boss room for the interior map ID.
KASS.MAP_IDS = {
	[2512] = true,
}

KASS.encounterActive = false

BINDING_HEADER_KASS = "Keine Ahnung Simon Says"
BINDING_NAME_KASS_NORTH = "Nord"
BINDING_NAME_KASS_EAST = "Ost"
BINDING_NAME_KASS_SOUTH = "Sued"
BINDING_NAME_KASS_WEST = "West"
BINDING_NAME_KASS_RESET = "Zuruecksetzen"

local DEFAULT_MARKERS = { N = 1, E = 3, S = 6, W = 7 }

local ECHO_SPELL_IDS = { 1288125 }

local echoIDs = {}
local echoNames = {}

local echoTicker = nil
local echoArmed = false
local channelUnit = nil
local channelStartAt = 0
local lastEchoCastAt = 0
local MIN_SERMON_SECONDS = 8
local ECHO_CAST_DEBOUNCE = 1
local AdvanceEcho

KASS.lastSpellId = nil
KASS.lastSpellName = nil

local corePress = KASS.Press
local coreReset = KASS.Reset
local coreUndo = KASS.Undo
local coreSetMarker = KASS.SetMarker

local function RefreshHUD()
	if KASS.HUD and KASS.HUD.ApplyVisibility then
		KASS.HUD.ApplyVisibility()
	elseif KASS.HUD and KASS.HUD.Refresh then
		KASS.HUD.Refresh()
	end
end

function KASS.Press(input)
	corePress(input)
	RefreshHUD()
end

function KASS.Reset()
	coreReset()
	RefreshHUD()
end

function KASS.Undo()
	coreUndo()
	RefreshHUD()
end

function KASS.SetMarker(quadrant, index)
	coreSetMarker(quadrant, index)
	if KASSDB and KASSDB.markers then
		for q, markerIndex in pairs(KASS.MARKERS) do
			KASSDB.markers[q] = markerIndex
		end
	end
	RefreshHUD()
end

local function ResolveSpellName(id)
	if not id then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(id)
		if type(info) == "table" and info.name then
			return info.name
		end
		if type(info) == "string" then
			return info
		end
	end
	if GetSpellInfo then
		return GetSpellInfo(id)
	end
end

local function BuildSpellSets()
	for _, id in ipairs(ECHO_SPELL_IDS) do
		echoIDs[id] = true
		local name = ResolveSpellName(id)
		if name and name ~= "" then
			echoNames[name] = true
		end
	end
end

BuildSpellSets()

local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) == true
end

local function PublicValue(value)
	if value == nil or IsSecret(value) then
		return nil
	end
	return value
end

local function NoteSpell(id, name)
	id = PublicValue(id)
	name = PublicValue(name)
	if id then
		KASS.lastSpellId = id
	end
	if name and name ~= "" then
		KASS.lastSpellName = name
	end
end

local function IsEchoSpell(id, name)
	if id and echoIDs[id] then
		return true
	end
	if name and echoNames[name] then
		return true
	end
	return false
end

local function IsBossUnit(unit)
	return type(unit) == "string" and unit:match("^boss%d$") ~= nil
end

local function IsFightCaster(unit)
	if IsBossUnit(unit) then
		return true
	end
	if not KASS.encounterActive or not unit then
		return false
	end
	if UnitExists and not UnitExists(unit) then
		return false
	end
	if UnitIsPlayer and UnitIsPlayer(unit) then
		return false
	end
	return true
end

local function SameChanneler(unit)
	return unit ~= nil and unit == channelUnit
end

local function CancelEchoTicker()
	if echoTicker then
		echoTicker:Cancel()
		echoTicker = nil
	end
end

local function OnSermonDetected()
	echoArmed = false
	lastEchoCastAt = 0
	CancelEchoTicker()
	if KASS.Phase() == "recording" then
		return
	end
	KASS.OnSermonStart()
	RefreshHUD()
end

local function StartEchoFallbackTicker()
	if echoTicker then
		echoTicker:Cancel()
	end
	echoTicker = C_Timer.NewTicker(3, function()
		if KASS.Phase() ~= "replaying" then
			return
		end
		AdvanceEcho()
	end)
end

local function OnEchoStartDetected()
	if KASS.Phase() == "replaying" then
		return
	end
	echoArmed = false
	CancelEchoTicker()
	lastEchoCastAt = GetTime()
	KASS.OnEchoStart()
	RefreshHUD()
	StartEchoFallbackTicker()
end

-- Cast start and the 3s fallback share this gate so two sources cannot
-- announce the next pad in the same beat.
AdvanceEcho = function()
	local now = GetTime()
	if lastEchoCastAt > 0 and (now - lastEchoCastAt) < ECHO_CAST_DEBOUNCE then
		return
	end
	lastEchoCastAt = now
	if KASS.Phase() ~= "replaying" then
		if not echoArmed and #KASS.Sequence() == 0 then
			return
		end
		OnEchoStartDetected()
		return
	end
	if echoTicker then
		echoTicker:Cancel()
		echoTicker = nil
	end
	KASS.OnEchoTick()
	RefreshHUD()
end

local function BossChannelInfo(unit)
	if not UnitChannelInfo then
		return nil, nil
	end
	local name, _, _, _, _, _, _, spellId = UnitChannelInfo(unit)
	return PublicValue(name), PublicValue(spellId)
end

-- Sermon is the long boss channel. Echo waves are later casts by the
-- same unit, not a second channel.
local function OnBossChannelStart(unit, eventSpellId)
	if not IsFightCaster(unit) then
		return
	end
	if KASS.Phase() == "recording" then
		if SameChanneler(unit) or IsBossUnit(unit) then
			channelUnit = unit
		end
		return
	end

	local name, channelSpellId = BossChannelInfo(unit)
	local spellId = PublicValue(eventSpellId) or channelSpellId
	NoteSpell(spellId, name)

	channelUnit = unit
	channelStartAt = GetTime()
	if IsEchoSpell(spellId, name) then
		OnEchoStartDetected()
		return
	end
	OnSermonDetected()
end

local function OnBossChannelStop(unit)
	if channelUnit and unit and not SameChanneler(unit) then
		return
	end
	if KASS.Phase() ~= "recording" then
		return
	end
	local elapsed = GetTime() - channelStartAt
	if elapsed < MIN_SERMON_SECONDS then
		echoArmed = false
		KASS.Reset()
		RefreshHUD()
		return
	end
	if #KASS.Sequence() > 0 then
		echoArmed = true
		KASS.OnSermonEnd()
		RefreshHUD()
	end
end

local function OnEchoCast(unit)
	if not echoArmed and KASS.Phase() ~= "replaying" then
		return
	end
	if not IsFightCaster(unit) then
		return
	end
	if channelUnit and not SameChanneler(unit) then
		return
	end
	if #KASS.Sequence() == 0 then
		return
	end
	AdvanceEcho()
end

function KASS.StartEcho()
	if #KASS.Sequence() == 0 then
		print("KASS: Nichts aufgenommen.")
		return
	end
	OnEchoStartDetected()
end

local function MigrateDB()
	local display = KASSDB.display
	local input = KASSDB.input
	local hidden = KASSDB.hidden
	local locked = KASSDB.locked
	local anywhere = KASSDB.anywhere

	if not KASSDB.schemaVersion or KASSDB.schemaVersion < 2 then
		KASSDB.schemaVersion = 2
		KASSDB.delveOnly = true
		KASSDB.markers = {
			N = DEFAULT_MARKERS.N,
			E = DEFAULT_MARKERS.E,
			S = DEFAULT_MARKERS.S,
			W = DEFAULT_MARKERS.W,
		}
		KASSDB.voice = { enabled = true, style = "marker", volume = 100 }
		KASSDB.calloutEnabled = true
		KASSDB.nextEnabled = true

		if display then
			KASSDB.display = display
		end
		if input then
			KASSDB.input = input
		end
		if hidden ~= nil then
			KASSDB.hidden = hidden
		end
		if locked ~= nil then
			KASSDB.locked = locked
		end
		if anywhere ~= nil then
			KASSDB.anywhere = anywhere
		end
	end

	KASSDB.hidden = KASSDB.hidden or false
	KASSDB.locked = KASSDB.locked or false
	KASSDB.delveOnly = KASSDB.delveOnly ~= false
	KASSDB.markers = KASSDB.markers or {
		N = DEFAULT_MARKERS.N,
		E = DEFAULT_MARKERS.E,
		S = DEFAULT_MARKERS.S,
		W = DEFAULT_MARKERS.W,
	}
	KASSDB.voice = KASSDB.voice or { enabled = true, style = "marker", volume = 100 }
	KASSDB.calloutEnabled = KASSDB.calloutEnabled ~= false
	KASSDB.nextEnabled = KASSDB.nextEnabled ~= false
	KASSDB.callout = KASSDB.callout or {}

	for quadrant, index in pairs(KASSDB.markers) do
		KASS.MARKERS[quadrant] = index
	end
end

local function FormatSequence()
	local seq = KASS.Sequence()
	if #seq == 0 then
		return "(empty)"
	end
	return table.concat(seq, " ")
end

local function StatusVoiceID()
	if C_TTSSettings and C_TTSSettings.GetVoiceOptionID and Enum and Enum.TtsVoiceType then
		local voiceID = C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
		if voiceID ~= nil then
			return tostring(voiceID)
		end
	end
	return "n/a"
end

local function StatusMapID()
	if C_Map and C_Map.GetBestMapForUnit then
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID then
			return tostring(mapID)
		end
	end
	return "n/a"
end

SLASH_KASS1 = "/kass"
SlashCmdList["KASS"] = function(message)
	local command, argument = strmatch(message:lower(), "^%s*(%S*)%s*(%S*)")

	local quadrant = KASS.AliasToQuadrant(command)
	if quadrant then
		KASS.Press(quadrant)
	elseif command == "undo" then
		KASS.Undo()
	elseif command == "reset" or command == "clear" then
		KASS.Reset()
	elseif command == "on" or command == "show" then
		KASS.HUD.Show()
	elseif command == "off" or command == "hide" then
		KASS.HUD.Hide()
	elseif command == "toggle" then
		KASS.HUD.Toggle()
	elseif command == "" or command == "options" then
		if KASS.Options and KASS.Options.Open then
			KASS.Options.Open()
		else
			print("KASS: Optionen noch nicht geladen.")
		end
	elseif command == "recenter" then
		if KASS.HUD and KASS.HUD.Recenter then
			KASS.HUD.Recenter()
		end
	elseif command == "lock" then
		KASS.HUD.SetLocked(true)
	elseif command == "unlock" then
		KASS.HUD.SetLocked(false)
	elseif command == "scale" then
		local scale = tonumber(argument)
		if scale and scale >= KASS.HUD.MIN_SCALE and scale <= KASS.HUD.MAX_SCALE then
			KASS.HUD.SetScale(scale)
		else
			print(("KASS: /kass scale <%s - %s>"):format(
				KASS.HUD.MIN_SCALE, KASS.HUD.MAX_SCALE))
		end
	elseif command == "sound" then
		KASS.TestSound()
	elseif command == "status" then
		print(("KASS: phase=%s sequence=%s cursor=%d lastSpell=%s (%s) map=%s voice=%s anywhere=%s"):format(
			KASS.Phase(),
			FormatSequence(),
			KASS.Cursor(),
			tostring(KASS.lastSpellId or "none"),
			tostring(KASS.lastSpellName or "none"),
			StatusMapID(),
			StatusVoiceID(),
			tostring(KASSDB.anywhere)))
	elseif command == "anywhere" then
		KASSDB.anywhere = not KASSDB.anywhere
		print(("KASS: anywhere=%s"):format(tostring(KASSDB.anywhere)))
		RefreshHUD()
	elseif command == "echo" or command == "play" then
		KASS.StartEcho()
	elseif command == "sim" then
		if argument == "stop" then
			KASS.Sim.Stop()
		else
			KASS.Sim.Start(argument ~= "" and argument or nil)
		end
	else
		print("KASS: /kass n | e | s | w | undo | reset | on | off | toggle | lock | unlock | scale <n>")
		print("KASS:   sound | status | anywhere | options | recenter | echo | sim [3-7] | sim stop")
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("ENCOUNTER_START")
events:RegisterEvent("ENCOUNTER_END")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
events:RegisterEvent("UNIT_SPELLCAST_START")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON_NAME then
			return
		end
		KASSDB = KASSDB or {}
		MigrateDB()
		KASS.sermonSeen = false
		KASS.lastSpellId = nil
		KASS.lastSpellName = nil
		KASS.encounterActive = false
		KASS.HUD.Create()
		RefreshHUD()
	elseif event == "ENCOUNTER_START" then
		if KASS.Sim and KASS.Sim.Stop then
			KASS.Sim.Stop()
		end
		KASS.encounterActive = true
		echoArmed = false
		channelUnit = nil
		CancelEchoTicker()
		KASS.OnEncounter()
		RefreshHUD()
	elseif event == "ENCOUNTER_END" then
		if KASS.Sim and KASS.Sim.Stop then
			KASS.Sim.Stop()
		end
		KASS.encounterActive = false
		echoArmed = false
		channelUnit = nil
		CancelEchoTicker()
		KASS.OnEncounter()
		RefreshHUD()
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
		RefreshHUD()
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local unit, _, spellId = arg1, arg2, arg3
		OnBossChannelStart(unit, spellId)
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		OnBossChannelStop(arg1)
	elseif event == "UNIT_SPELLCAST_START" then
		OnEchoCast(arg1)
	end
end)
