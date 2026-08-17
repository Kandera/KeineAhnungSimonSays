-- Practice run: random sequence, auto-record, then replay with callout.

KASS.Sim = KASS.Sim or {}

local QUADRANTS = { "N", "E", "S", "W" }
local VALID_LENGTHS = { [3] = true, [4] = true, [5] = true, [6] = true, [7] = true }
-- Sermon has no TTS: 1s is enough to see the tape fill.
-- Echo speaks one German marker name per step; 1s races the voice and
-- drops calls (SpeakText overlap is off). 3s matches the live wave ticker.
local SERMON_INTERVAL = 1
local ECHO_INTERVAL = 3

local simTimers = {}
local savedSermonSeen

local function RefreshHUD()
	if KASS.HUD and KASS.HUD.Refresh then
		KASS.HUD.Refresh()
	end
end

local function TrackTimer(timer)
	simTimers[#simTimers + 1] = timer
	return timer
end

local function ScheduleAfter(delay, fn)
	return TrackTimer(C_Timer.After(delay, fn))
end

local function CancelTimers()
	for _, timer in ipairs(simTimers) do
		if timer and timer.Cancel then
			timer:Cancel()
		end
	end
	wipe(simTimers)
end

function KASS.Sim.BuildRun(n, rng)
	if not VALID_LENGTHS[n] then
		n = 5
	end

	rng = rng or math.random
	local seq = {}
	local last

	for i = 1, n do
		local quadrant
		repeat
			local index = math.floor(rng() * 4) + 1
			quadrant = QUADRANTS[index]
		until quadrant ~= last
		seq[i] = quadrant
		last = quadrant
	end

	return seq
end

local function FinishEchoPhase()
	KASS.OnEchoEnd()
	KASS.simActive = false
	RefreshHUD()
end

local function StartEchoPhase(length)
	KASS.OnEchoStart()
	RefreshHUD()

	local remaining = length - 1
	if remaining == 0 then
		ScheduleAfter(ECHO_INTERVAL, function()
			if not KASS.simActive then
				return
			end
			FinishEchoPhase()
		end)
		return
	end

	for tick = 1, remaining do
		ScheduleAfter(ECHO_INTERVAL * tick, function()
			if not KASS.simActive then
				return
			end
			KASS.OnEchoTick()
			RefreshHUD()
			if tick == remaining then
				ScheduleAfter(ECHO_INTERVAL, function()
					if not KASS.simActive then
						return
					end
					FinishEchoPhase()
				end)
			end
		end)
	end
end

function KASS.Sim.Stop()
	CancelTimers()
	KASS.simActive = false
	if savedSermonSeen ~= nil then
		KASS.sermonSeen = savedSermonSeen
		savedSermonSeen = nil
	end
	KASS.Reset()
	RefreshHUD()
end

function KASS.Sim.Start(n)
	KASS.Sim.Stop()

	n = tonumber(n) or 5
	if not VALID_LENGTHS[n] then
		print(("KASS: /kass sim <%s> — n must be 3–7"):format(tostring(n)))
		return
	end

	local seq = KASS.Sim.BuildRun(n)
	print(("KASS: Sim %s"):format(table.concat(seq, " ")))

	savedSermonSeen = KASS.sermonSeen
	KASS.simActive = true
	KASS.OnSermonStart()
	RefreshHUD()

	for i, quadrant in ipairs(seq) do
		ScheduleAfter(SERMON_INTERVAL * i, function()
			if not KASS.simActive then
				return
			end
			KASS.Press(quadrant)

			if i == #seq then
				ScheduleAfter(SERMON_INTERVAL, function()
					if not KASS.simActive then
						return
					end
					StartEchoPhase(#seq)
				end)
			end
		end)
	end
end
