-- Replay callouts: relative-turn tones. No Core logic.

KASS = KASS or {}

local MARKER_NAMES = {
	[1] = "Stern",
	[2] = "Kreis",
	[3] = "Diamant",
	[4] = "Dreieck",
	[5] = "Mond",
	[6] = "Quadrat",
	[7] = "Kreuz",
	[8] = "Totenkopf",
}

local MEDIA = "Interface\\AddOns\\KeineAhnungSimonSays\\media\\"
local TURN_FILES = {
	left = MEDIA .. "en-left.ogg",
	right = MEDIA .. "en-right.ogg",
	forward = MEDIA .. "en-forward.ogg",
	stay = MEDIA .. "en-stay.ogg",
}

function KASS.MarkerName(index)
	return MARKER_NAMES[index]
end

local function PlayTurn(turn)
	local file = TURN_FILES[turn]
	if not file or not PlaySoundFile then
		return false
	end
	local ok, willPlay = pcall(PlaySoundFile, file, "Master")
	return ok and willPlay ~= false
end

function KASS.Speak()
	local voice = KASSDB and KASSDB.voice
	if not voice or not voice.enabled then
		return
	end
	local turn = KASS.Turn and KASS.Turn()
	if not turn then
		return
	end
	PlayTurn(turn)
end

function KASS.TestSound()
	if not PlayTurn("left") then
		print("KASS: kein Ton.")
		return
	end
	print("KASS: Test Left / Right / Forward / Stay")
	if not (C_Timer and C_Timer.After) then
		return
	end
	C_Timer.After(0.70, function()
		PlayTurn("right")
	end)
	C_Timer.After(1.40, function()
		PlayTurn("forward")
	end)
	C_Timer.After(2.10, function()
		PlayTurn("stay")
	end)
end
