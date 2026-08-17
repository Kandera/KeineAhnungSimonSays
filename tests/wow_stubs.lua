-- Minimal WoW API stubs for offline Core.lua tests.

function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

function GetTime()
	return KASSTEST and KASSTEST.now or 0
end

strmatch = string.match
