-- Keine Ahnung Simon Says
--
-- Records the colour sequence the player types along while the Delve boss
-- Azta'rec plays it, and draws it in a small movable window. The addon cannot
-- read the mechanic -- every colour here was entered by hand.
--
-- Two windows, moved and sized apart: the sequence goes where the player wants
-- to read it, the buttons go where the player wants to click.

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

local TILE = 32          -- edge length of one sequence square
local GAP = 5            -- space between squares
local PAD = 8            -- frame border padding
local PER_ROW = 10       -- squares before the row wraps
local BUTTON = 36        -- edge length of an input button
local RESET_WIDTH = 70
local GRIP = 12          -- resize grip, reserved at the bottom of each frame

local MIN_SCALE, MAX_SCALE = 0.5, 3
local SCALE_PER_PIXEL = 1 / 200  -- how far the grip must travel to double

local ROW_WIDTH = PER_ROW * TILE + (PER_ROW - 1) * GAP
local INPUT_WIDTH = #COLORS * BUTTON + (#COLORS - 1) * GAP + GAP * 4 + RESET_WIDTH

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
local display        -- the sequence window
local input          -- the button window

-- =====================================================================
-- Saved position and scale
-- =====================================================================

-- Every frame keeps its own entry in KASSDB under this key.
local function Store(frame)
	KASSDB[frame.dbKey] = KASSDB[frame.dbKey] or {}
	return KASSDB[frame.dbKey]
end

local function SavePosition(frame)
	local point, _, relPoint, x, y = frame:GetPoint()
	Store(frame).pos = { point = point, relPoint = relPoint, x = x, y = y }
end

local function RestorePosition(frame, defaultY)
	frame:ClearAllPoints()
	local pos = Store(frame).pos
	if pos then
		frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, defaultY)
	end
	frame:SetScale(Store(frame).scale or 1)
end

-- =====================================================================
-- Window plumbing shared by both frames
-- =====================================================================

local function AddResizeGrip(frame)
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(GRIP, GRIP)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)

	local texture = grip:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints()
	texture:SetColorTexture(1, 1, 1, 0.25)

	grip:SetScript("OnEnter", function() texture:SetAlpha(0.7) end)
	grip:SetScript("OnLeave", function() texture:SetAlpha(0.25) end)

	-- Dragging the grip changes scale, not size: the row is content-sized, so
	-- a wider frame would have nothing to fill the space with.
	grip:SetScript("OnMouseDown", function(self)
		if KASSDB.locked then return end
		self.startX = GetCursorPosition()
		self.startScale = frame:GetScale()
		self:SetScript("OnUpdate", function(this)
			local delta = GetCursorPosition() - this.startX
			local scale = this.startScale + delta * SCALE_PER_PIXEL
			frame:SetScale(math.max(MIN_SCALE, math.min(MAX_SCALE, scale)))
		end)
	end)

	grip:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
		Store(frame).scale = frame:GetScale()
	end)

	frame.grip = grip
end

local function CreateWindow(name, dbKey, width, height)
	local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	frame.dbKey = dbKey
	frame:SetSize(width, height)
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
	frame:SetScript("OnDragStart", function(self)
		if not KASSDB.locked then self:StartMoving() end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition(self)
	end)
	AddResizeGrip(frame)
	return frame
end

-- =====================================================================
-- Sequence window
-- =====================================================================

local function GetTile(index)
	local tile = tiles[index]
	if not tile then
		tile = display:CreateTexture(nil, "ARTWORK")
		tile:SetSize(TILE, TILE)
		tiles[index] = tile
	end
	return tile
end

-- Places every square and resizes the sequence window around them. An empty
-- sequence still reserves one row so the window does not jump on the first
-- press -- and stays findable when nothing has been entered yet.
local function Layout()
	local count = #sequence
	local rows = math.max(1, math.ceil(count / PER_ROW))

	for i = 1, count do
		local tile = GetTile(i)
		local row = math.floor((i - 1) / PER_ROW)
		local col = (i - 1) % PER_ROW
		tile:ClearAllPoints()
		tile:SetPoint("TOPLEFT", display, "TOPLEFT",
			PAD + col * (TILE + GAP),
			-(PAD + row * (TILE + GAP)))
		local color = COLORS[sequence[i]]
		tile:SetColorTexture(color.r, color.g, color.b)
		tile:Show()
	end

	for i = count + 1, #tiles do
		tiles[i]:Hide()
	end

	display:SetHeight(PAD + rows * TILE + (rows - 1) * GAP + PAD + GRIP)
	input.count:SetText(count > 0 and tostring(count) or "")
end

-- =====================================================================
-- Button window
-- =====================================================================

local function CreateInputButton(parent, index)
	local color = COLORS[index]
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(BUTTON, BUTTON)

	local background = button:CreateTexture(nil, "ARTWORK")
	background:SetAllPoints()
	background:SetColorTexture(color.r, color.g, color.b)

	-- No shared highlight texture: an alpha change needs no art asset and so
	-- cannot break on a patch that moves one.
	button:SetScript("OnEnter", function() background:SetAlpha(0.6) end)
	button:SetScript("OnLeave", function() background:SetAlpha(1) end)
	button:SetScript("OnClick", function() KASS.Press(index) end)

	return button
end

local function BuildInputWindow()
	local previous
	for i = 1, #COLORS do
		local button = CreateInputButton(input, i)
		if previous then
			button:SetPoint("LEFT", previous, "RIGHT", GAP, 0)
		else
			button:SetPoint("TOPLEFT", input, "TOPLEFT", PAD, -PAD)
		end
		previous = button
	end

	local reset = CreateFrame("Button", nil, input, "UIPanelButtonTemplate")
	reset:SetSize(RESET_WIDTH, BUTTON)
	reset:SetPoint("TOPRIGHT", input, "TOPRIGHT", -PAD, -PAD)
	reset:SetText("Reset")
	reset:SetScript("OnClick", function() KASS.Reset() end)

	-- Length of the sequence, so a long row can be checked at a glance.
	input.count = input:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	input.count:SetPoint("RIGHT", reset, "LEFT", -GAP, 0)
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

function KASS.Show()
	KASSDB.hidden = false
	display:Show()
	input:Show()
end

function KASS.Hide()
	KASSDB.hidden = true
	display:Hide()
	input:Hide()
end

function KASS.Toggle()
	if KASSDB.hidden then KASS.Show() else KASS.Hide() end
end

function KASS.SetLocked(locked)
	KASSDB.locked = locked
	display.grip:SetShown(not locked)
	input.grip:SetShown(not locked)
	print("KASS: " .. (locked and "Fenster gesperrt." or "Fenster frei."))
end

function KASS.SetScale(scale)
	display:SetScale(scale)
	input:SetScale(scale)
	Store(display).scale = scale
	Store(input).scale = scale
end

-- =====================================================================
-- Slash command
-- =====================================================================

SLASH_KASS1 = "/kass"
SlashCmdList["KASS"] = function(message)
	local command, argument = message:lower():match("^%s*(%S*)%s*(%S*)")

	if SLASH_COLORS[command] then
		KASS.Press(SLASH_COLORS[command])
	elseif command == "reset" or command == "clear" then
		KASS.Reset()
	elseif command == "on" or command == "show" then
		KASS.Show()
	elseif command == "off" or command == "hide" then
		KASS.Hide()
	elseif command == "toggle" or command == "" then
		KASS.Toggle()
	elseif command == "lock" then
		KASS.SetLocked(true)
	elseif command == "unlock" then
		KASS.SetLocked(false)
	elseif command == "scale" then
		local scale = tonumber(argument)
		if scale and scale >= MIN_SCALE and scale <= MAX_SCALE then
			KASS.SetScale(scale)
		else
			print(("KASS: /kass scale <%s - %s>"):format(MIN_SCALE, MAX_SCALE))
		end
	else
		print("KASS: /kass r | b | y | p | reset | on | off | lock | unlock | scale <n>")
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

		display = CreateWindow("KASSDisplay", "display",
			ROW_WIDTH + 2 * PAD, PAD + TILE + PAD + GRIP)
		input = CreateWindow("KASSInput", "input",
			INPUT_WIDTH + 2 * PAD, PAD + BUTTON + PAD + GRIP)
		BuildInputWindow()

		RestorePosition(display, -100)
		RestorePosition(input, -200)

		display.grip:SetShown(not KASSDB.locked)
		input.grip:SetShown(not KASSDB.locked)
		if KASSDB.hidden then
			display:Hide()
			input:Hide()
		end
		Layout()
	else
		-- Round boundaries inside the fight are the player's reset key; the
		-- addon only clears at the edges of the encounter, which it can see.
		KASS.Reset()
	end
end)
