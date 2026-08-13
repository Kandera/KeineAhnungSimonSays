-- Keine Ahnung Simon Says
--
-- Records the colour sequence the player types along while the Delve boss
-- Azta'rec plays it, and draws it in a small movable window. The addon cannot
-- read the mechanic -- every colour here was entered by hand.

local ADDON_NAME = ...

KASS = {}

-- =====================================================================
-- Constants
-- =====================================================================

-- Order is fixed: the binding bodies in Bindings.xml pass these indices.
local COLORS = {
	{ key = "RED",    label = "Rot",  r = 0.85, g = 0.15, b = 0.15 },
	{ key = "BLUE",   label = "Blau", r = 0.20, g = 0.45, b = 0.95 },
	{ key = "YELLOW", label = "Gelb", r = 0.95, g = 0.82, b = 0.15 },
	{ key = "PURPLE", label = "Lila", r = 0.62, g = 0.25, b = 0.85 },
}

-- Short forms accepted by the slash command, so a macro stays one word.
local SLASH_COLORS = {
	r = 1, red = 1, rot = 1,
	b = 2, blue = 2, blau = 2,
	y = 3, yellow = 3, gelb = 3, g = 3,
	p = 4, purple = 4, lila = 4,
}

local TILE = 20          -- edge length of one sequence square
local GAP = 4            -- space between squares
local PAD = 8            -- frame border padding
local PER_ROW = 10       -- squares before the row wraps
local SECTION_GAP = 10   -- space between sequence area and input row
local BUTTON = 24        -- edge length of an input button
local RESET_WIDTH = 60

local ROW_WIDTH = PER_ROW * TILE + (PER_ROW - 1) * GAP
local FRAME_WIDTH = ROW_WIDTH + 2 * PAD

-- =====================================================================
-- Key binding labels
-- =====================================================================

BINDING_HEADER_KASS = "Keine Ahnung Simon Says"
BINDING_NAME_KASS_RED = "Rot"
BINDING_NAME_KASS_BLUE = "Blau"
BINDING_NAME_KASS_YELLOW = "Gelb"
BINDING_NAME_KASS_PURPLE = "Lila"
BINDING_NAME_KASS_RESET = "Zuruecksetzen"

-- =====================================================================
-- State
-- =====================================================================

local sequence = {}  -- entries 1..4, in the order they were pressed
local tiles = {}     -- textures, created on demand and reused
local frame

-- =====================================================================
-- Window
-- =====================================================================

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint()
	KASSDB.pos = { point = point, relPoint = relPoint, x = x, y = y }
end

local function RestorePosition()
	frame:ClearAllPoints()
	local pos = KASSDB.pos
	if pos then
		frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
	end
end

local function GetTile(index)
	local tile = tiles[index]
	if not tile then
		tile = frame:CreateTexture(nil, "ARTWORK")
		tile:SetSize(TILE, TILE)
		tiles[index] = tile
	end
	return tile
end

-- Places every square, moves the input row below them and resizes the frame.
-- An empty sequence still reserves one row so the window does not jump on the
-- first press.
local function Layout()
	local count = #sequence
	local rows = math.max(1, math.ceil(count / PER_ROW))
	local displayHeight = rows * TILE + (rows - 1) * GAP

	for i = 1, count do
		local tile = GetTile(i)
		local row = math.floor((i - 1) / PER_ROW)
		local col = (i - 1) % PER_ROW
		tile:ClearAllPoints()
		tile:SetPoint("TOPLEFT", frame, "TOPLEFT",
			PAD + col * (TILE + GAP),
			-(PAD + row * (TILE + GAP)))
		local color = COLORS[sequence[i]]
		tile:SetColorTexture(color.r, color.g, color.b)
		tile:Show()
	end

	for i = count + 1, #tiles do
		tiles[i]:Hide()
	end

	local inputY = -(PAD + displayHeight + SECTION_GAP)
	frame.inputRow:ClearAllPoints()
	frame.inputRow:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, inputY)

	frame:SetHeight(PAD + displayHeight + SECTION_GAP + BUTTON + PAD)
	frame.count:SetText(count > 0 and tostring(count) or "")
end

local function CreateInputButton(parent, index)
	local color = COLORS[index]
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(BUTTON, BUTTON)

	local bg = button:CreateTexture(nil, "ARTWORK")
	bg:SetAllPoints()
	bg:SetColorTexture(color.r, color.g, color.b)

	-- No shared highlight texture: an alpha change needs no art asset and so
	-- cannot break on a patch that moves one.
	button:SetScript("OnEnter", function() bg:SetAlpha(0.6) end)
	button:SetScript("OnLeave", function() bg:SetAlpha(1) end)
	button:SetScript("OnClick", function() KASS.Press(index) end)

	return button
end

local function CreateWindow()
	frame = CreateFrame("Frame", "KASSFrame", UIParent, "BackdropTemplate")
	frame:SetWidth(FRAME_WIDTH)
	frame:SetHeight(PAD + TILE + SECTION_GAP + BUTTON + PAD)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0, 0, 0, 0.6)
	frame:SetBackdropBorderColor(0, 0, 0, 0.9)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)

	frame.inputRow = CreateFrame("Frame", nil, frame)
	frame.inputRow:SetSize(ROW_WIDTH, BUTTON)

	local previous
	for i = 1, #COLORS do
		local button = CreateInputButton(frame.inputRow, i)
		if previous then
			button:SetPoint("LEFT", previous, "RIGHT", GAP, 0)
		else
			button:SetPoint("LEFT", frame.inputRow, "LEFT", 0, 0)
		end
		previous = button
	end

	local reset = CreateFrame("Button", nil, frame.inputRow, "UIPanelButtonTemplate")
	reset:SetSize(RESET_WIDTH, BUTTON)
	reset:SetPoint("RIGHT", frame.inputRow, "RIGHT", 0, 0)
	reset:SetText("Reset")
	reset:SetScript("OnClick", function() KASS.Reset() end)

	-- Length of the sequence, so a long row can be checked at a glance.
	frame.count = frame.inputRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.count:SetPoint("RIGHT", reset, "LEFT", -GAP, 0)
end

-- =====================================================================
-- Input
-- =====================================================================

function KASS.Press(index)
	if not COLORS[index] then return end
	sequence[#sequence + 1] = index
	Layout()
end

function KASS.Reset()
	wipe(sequence)
	Layout()
end

function KASS.Toggle()
	if frame:IsShown() then
		frame:Hide()
		KASSDB.hidden = true
	else
		frame:Show()
		KASSDB.hidden = false
	end
end

-- =====================================================================
-- Slash command
-- =====================================================================

SLASH_KASS1 = "/kass"
SlashCmdList["KASS"] = function(msg)
	local command, argument = msg:lower():match("^%s*(%S*)%s*(%S*)")

	if SLASH_COLORS[command] then
		KASS.Press(SLASH_COLORS[command])
	elseif command == "reset" or command == "clear" then
		KASS.Reset()
	elseif command == "toggle" or command == "" then
		KASS.Toggle()
	elseif command == "scale" then
		local scale = tonumber(argument)
		if scale and scale >= 0.5 and scale <= 3 then
			KASSDB.scale = scale
			frame:SetScale(scale)
		else
			print("KASS: /kass scale <0.5 - 3>")
		end
	else
		print("KASS: /kass r | b | y | p | reset | toggle | scale <n>")
	end
end

-- =====================================================================
-- Events
-- =====================================================================

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("ENCOUNTER_START")
events:RegisterEvent("ENCOUNTER_END")
events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON_NAME then return end
		KASSDB = KASSDB or {}
		CreateWindow()
		RestorePosition()
		frame:SetScale(KASSDB.scale or 1)
		if KASSDB.hidden then frame:Hide() end
		Layout()
	else
		-- Round boundaries inside the fight are the player's reset key; the
		-- addon only clears at the edges of the encounter, which it can see.
		KASS.Reset()
	end
end)
