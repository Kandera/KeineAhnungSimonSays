dofile("Sim.lua")

C_Timer = C_Timer or {}
function C_Timer.After(_, fn)
	return { Cancel = function() end }
end

KASS.sermonSeen = false
KASS.Sim.Start(5)
KASS.Sim.Stop()
KASS.Press("N")
T.deep_eq(KASS.Sequence(), { "N" }, "after sim stop: idle press works when sermonSeen was false")

KASS.sermonSeen = true
KASS.Sim.Start(5)
KASS.Sim.Stop()
KASS.Press("E")
T.deep_eq(KASS.Sequence(), {}, "after sim stop: idle press blocked when sermonSeen was true")

local function noConsecutiveDuplicates(seq)
	for i = 2, #seq do
		if seq[i] == seq[i - 1] then
			return false
		end
	end
	return true
end

local function seededRng(seed)
	local state = seed
	return function()
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

for _, n in ipairs({ 3, 4, 5, 6, 7 }) do
	for seed = 1, 5 do
		local seq = KASS.Sim.BuildRun(n, seededRng(seed * 100 + n))
		T.eq(#seq, n, ("build run length n=%d seed=%d"):format(n, seed))
		T.eq(noConsecutiveDuplicates(seq), true, ("no consecutive dupes n=%d seed=%d"):format(n, seed))
	end
end
