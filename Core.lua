-- Core fight logic: NESW sequence, input guards, raid marker mapping.
-- No frames; offline-testable via tests/run.lua.

KASS = KASS or {}

KASS.N = "N"
KASS.E = "E"
KASS.S = "S"
KASS.W = "W"

local QUADRANTS = { N = true, E = true, S = true, W = true }
local DEBOUNCE_SECONDS = 0.8

local DEFAULT_MARKERS = {
	N = 1,
	E = 3,
	S = 6,
	W = 7,
}

KASS.MARKERS = {
	N = DEFAULT_MARKERS.N,
	E = DEFAULT_MARKERS.E,
	S = DEFAULT_MARKERS.S,
	W = DEFAULT_MARKERS.W,
}

KASS.sermonSeen = false
KASS.simActive = false

local COLOR_ALIASES = {
	r = "W", red = "W", rot = "W",
	b = "S", blue = "S", blau = "S",
	y = "N", yellow = "N", gelb = "N", g = "N",
	p = "E", purple = "E", lila = "E",
}

local DIRECTION_ALIASES = {
	n = "N", nord = "N",
	e = "E", ost = "E",
	s = "S", sued = "S", ["süd"] = "S", sud = "S",
	w = "W", west = "W",
}

local sequence = {}
local lastPressAt = {}
local phase = "idle"
local cursor = 0

local function Announce()
	if type(KASS.OnAnnounce) == "function" then
		KASS.OnAnnounce(KASS.Current(), KASS.Next())
	end
end

local function NormalizeQuadrant(input)
	if type(input) ~= "string" then
		return nil
	end
	if QUADRANTS[input] then
		return input
	end
	return KASS.AliasToQuadrant(input)
end

function KASS.AliasToQuadrant(word)
	if type(word) ~= "string" then
		return nil
	end
	local key = word:lower()
	if QUADRANTS[key:upper()] and #key == 1 then
		return key:upper()
	end
	return COLOR_ALIASES[key] or DIRECTION_ALIASES[key]
end

function KASS.Sequence()
	local copy = {}
	for i = 1, #sequence do
		copy[i] = sequence[i]
	end
	return copy
end

function KASS.Reset()
	wipe(sequence)
	wipe(lastPressAt)
	phase = "idle"
	cursor = 0
end

function KASS.Phase()
	return phase
end

function KASS.Cursor()
	if phase == "replaying" then
		return cursor
	end
	return 0
end

function KASS.Current()
	if phase ~= "replaying" or cursor < 1 then
		return nil
	end
	local index = cursor
	if index > #sequence then
		index = #sequence
	end
	if index < 1 then
		return nil
	end
	return sequence[index]
end

function KASS.Next()
	if phase ~= "replaying" or cursor < 1 then
		return nil
	end
	if cursor >= #sequence then
		return nil
	end
	return sequence[cursor + 1]
end

-- Facing the room center: left = clockwise, right = counter, forward = opposite.
local CLOCKWISE = { N = "E", E = "S", S = "W", W = "N" }
local COUNTER = { N = "W", E = "N", S = "E", W = "S" }
local OPPOSITE = { N = "S", E = "W", S = "N", W = "E" }

function KASS.RelativeTurn(from, to)
	if not QUADRANTS[from] or not QUADRANTS[to] then
		return nil
	end
	if from == to then
		return "stay"
	end
	if CLOCKWISE[from] == to then
		return "left"
	end
	if COUNTER[from] == to then
		return "right"
	end
	if OPPOSITE[from] == to then
		return "forward"
	end
	return nil
end

local function TurnAt(index)
	if phase ~= "replaying" or index < 1 or index > #sequence then
		return nil
	end
	local to = sequence[index]
	local from
	if index == 1 then
		from = sequence[#sequence]
	else
		from = sequence[index - 1]
	end
	return KASS.RelativeTurn(from, to)
end

function KASS.Turn()
	return TurnAt(cursor)
end

function KASS.NextTurn()
	return TurnAt(cursor + 1)
end

function KASS.OnSermonStart()
	if not KASS.simActive then
		KASS.sermonSeen = true
	end
	wipe(sequence)
	wipe(lastPressAt)
	phase = "recording"
	cursor = 0
end

function KASS.OnEchoStart()
	phase = "replaying"
	cursor = 1
	Announce()
end

function KASS.OnEchoTick()
	if phase ~= "replaying" then
		return
	end
	if cursor < #sequence then
		cursor = cursor + 1
		Announce()
	end
end

function KASS.OnEchoEnd()
	phase = "idle"
	cursor = 0
end

function KASS.OnSermonEnd()
	phase = "idle"
	cursor = 0
end

function KASS.OnEncounter()
	wipe(sequence)
	wipe(lastPressAt)
	phase = "idle"
	cursor = 0
end

function KASS.Undo()
	sequence[#sequence] = nil
end

function KASS.Press(input)
	local quadrant = NormalizeQuadrant(input)
	if not quadrant then
		return
	end

	if phase == "replaying" then
		return
	end

	if phase == "idle" and KASS.sermonSeen and not KASS.simActive then
		return
	end

	local now = GetTime()
	local previousAt = lastPressAt[quadrant]
	if previousAt and (now - previousAt) < DEBOUNCE_SECONDS then
		return
	end

	local lastEntry = sequence[#sequence]
	if lastEntry == quadrant then
		print("KASS: Dieselbe Richtung zweimal hintereinander geht nicht.")
		return
	end

	sequence[#sequence + 1] = quadrant
	lastPressAt[quadrant] = now
end

function KASS.Marker(quadrant)
	return KASS.MARKERS[quadrant]
end

function KASS.SetMarker(quadrant, index)
	if not QUADRANTS[quadrant] then
		return
	end

	local markers = KASS.MARKERS
	local current = markers[quadrant]
	if current == index then
		return
	end

	local other
	for q, markerIndex in pairs(markers) do
		if markerIndex == index and q ~= quadrant then
			other = q
			break
		end
	end

	if other then
		markers[other] = current
	end
	markers[quadrant] = index
end
