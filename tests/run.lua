-- KART-style offline test runner for KASS Core.lua.

local pass, fail = 0, 0

T = {}

local function table_eq(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

function T.eq(actual, expected, message)
	if actual == expected then
		pass = pass + 1
	else
		fail = fail + 1
		io.write(string.format(
			"FAIL: %s (expected %s, got %s)\n",
			message or "?",
			tostring(expected),
			tostring(actual)
		))
	end
end

function T.deep_eq(actual, expected, message)
	if table_eq(actual, expected) then
		pass = pass + 1
	else
		fail = fail + 1
		io.write(string.format("FAIL: %s\n", message or "?"))
	end
end

dofile("tests/wow_stubs.lua")

KASSTEST = { now = 0 }

dofile("Core.lua")

dofile("tests/test_sequence.lua")
dofile("tests/test_turn.lua")
dofile("tests/test_detector.lua")
dofile("tests/test_press_gate.lua")
dofile("tests/test_announce.lua")
dofile("tests/test_sim.lua")

io.write(string.format("%d passed, %d failed\n", pass, fail))
os.exit(fail > 0 and 1 or 0)
