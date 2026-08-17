-- Board (NESW plus layout) and sequence tape. No Core logic.

KASS.HUD = KASS.HUD or {}

local HUD = KASS.HUD

local QUADRANT_ORDER = { "N", "W", "E", "S" }

local QUADRANT_TINT = {
	N = { 0.95, 0.82, 0.15 },
	E = { 0.62, 0.25, 0.85 },
	S = { 0.20, 0.45, 0.95 },
	W = { 0.85, 0.15, 0.15 },
}

local TILE = 32
local TILE_HIGHLIGHT = 40
local TILE_OUTLINE = 2
local GAP = 5
local PAD = 8
-- Fight max is 7 waves; keep one extra so a wrap never happens in this encounter.
local PER_ROW = 8
local WEDGE = 48
local RESET_WIDTH = 110
local COUNT_WIDTH = 24
local GRIP = 12
local CALLOUT_CURRENT = 96
local CALLOUT_NEXT = 40
local CALLOUT_GAP = 6

local MIN_SCALE, MAX_SCALE = 0.5, 3
local SCALE_PER_PIXEL = 1 / 200

local function TapeContentWidth(count)
	local tiles = math.max(1, math.min(count, PER_ROW))
	local row = tiles * TILE + (tiles - 1) * GAP
	return PAD + row + GAP + COUNT_WIDTH + GAP + RESET_WIDTH + PAD
end

local TAPE_MIN_HEIGHT = PAD + TILE + PAD + GRIP
local BOARD_WIDTH = PAD + WEDGE + GAP + WEDGE + GAP + WEDGE + PAD
local BOARD_HEIGHT = PAD + WEDGE + GAP + WEDGE + GAP + WEDGE + PAD + GRIP
local CALLOUT_WIDTH = CALLOUT_CURRENT + 2 * PAD
local CALLOUT_MIN_HEIGHT = PAD + CALLOUT_CURRENT + PAD + GRIP

local board
local tape
local callout
local tiles = {}
local wedges = {}
local calloutCurrent
local calloutNext

local function MarkerTexture(index)
	return ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(index)
end

local TURN_ATLAS = {
	left = "NPE_ArrowLeft",
	right = "NPE_ArrowRight",
	forward = "NPE_ArrowUp",
}
local TURN_ROTATION = {
	forward = 0,
	left = math.pi / 2,
	right = -math.pi / 2,
}

local function ApplyTint(texture, destQuadrant)
	local tint = destQuadrant and QUADRANT_TINT[destQuadrant]
	if tint then
		texture:SetVertexColor(tint[1], tint[2], tint[3])
	else
		texture:SetVertexColor(1, 1, 1)
	end
end

local function SetTurnIcon(texture, turn, destQuadrant)
	if not destQuadrant then
		texture:Hide()
		return
	end
	if turn and TURN_ATLAS[turn] then
		local usedAtlas = false
		if texture.SetAtlas then
			usedAtlas = pcall(texture.SetAtlas, texture, TURN_ATLAS[turn], false)
		end
		if usedAtlas then
			if texture.SetRotation then
				texture:SetRotation(0)
			end
		else
			texture:SetTexture("Interface\\Minimap\\MinimapArrow")
			if texture.SetRotation then
				texture:SetRotation(TURN_ROTATION[turn] or 0)
			end
		end
		texture:SetVertexColor(1, 0.85, 0.15)
	else
		texture:SetTexture(MarkerTexture(KASS.Marker(destQuadrant)))
		if texture.SetRotation then
			texture:SetRotation(0)
		end
		ApplyTint(texture, destQuadrant)
	end
	texture:Show()
end

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

local function AddResizeGrip(frame)
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(GRIP, GRIP)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)

	local texture = grip:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints()
	texture:SetColorTexture(1, 1, 1, 0.25)

	grip:SetScript("OnEnter", function() texture:SetAlpha(0.7) end)
	grip:SetScript("OnLeave", function() texture:SetAlpha(0.25) end)

	grip:SetScript("OnMouseDown", function(self)
		if KASSDB.locked then
			return
		end
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
		if not KASSDB.locked then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition(self)
	end)
	AddResizeGrip(frame)
	return frame
end

local function WedgeOrigin(quadrant)
	local x = PAD + WEDGE + GAP
	local y = -(PAD + WEDGE + GAP)
	if quadrant == "N" then
		return x, -PAD
	elseif quadrant == "W" then
		return PAD, y
	elseif quadrant == "E" then
		return PAD + 2 * (WEDGE + GAP), y
	end
	return x, -(PAD + 2 * (WEDGE + GAP))
end

local function CreateWedge(parent, quadrant)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(WEDGE, WEDGE)
	button.quadrant = quadrant

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	button.icon = icon

	button:SetScript("OnEnter", function(self)
		if KASS.Phase() ~= "replaying" then
			self.icon:SetAlpha(0.7)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if KASS.Phase() ~= "replaying" then
			self.icon:SetAlpha(1)
		else
			HUD.Refresh()
		end
	end)
	button:SetScript("OnClick", function(self)
		KASS.Press(self.quadrant)
	end)

	local ox, oy = WedgeOrigin(quadrant)
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, oy)
	wedges[quadrant] = button
	return button
end

local function GetTile(index)
	local tile = tiles[index]
	if not tile then
		tile = {}
		tile.border = tape:CreateTexture(nil, "BACKGROUND")
		tile.border:Hide()
		tile.icon = tape:CreateTexture(nil, "ARTWORK")
		tile.icon:SetSize(TILE, TILE)
		tiles[index] = tile
	end
	return tile
end

local function BrightenTint(tint, factor)
	return
		math.min(tint[1] * factor, 1),
		math.min(tint[2] * factor, 1),
		math.min(tint[3] * factor, 1)
end

local function DimTint(tint, factor, alpha)
	return tint[1] * factor, tint[2] * factor, tint[3] * factor, alpha
end

local function RefreshBoard()
	local replaying = KASS.Phase() == "replaying"
	local current = replaying and KASS.Current() or nil
	local nextQuadrant = replaying and KASS.Next() or nil

	for _, quadrant in ipairs(QUADRANT_ORDER) do
		local wedge = wedges[quadrant]
		if wedge then
			local markerIndex = KASS.Marker(quadrant)
			local tint = QUADRANT_TINT[quadrant]
			wedge.icon:SetTexture(MarkerTexture(markerIndex))

			if quadrant == current then
				local r, g, b = BrightenTint(tint, 1.15)
				wedge.icon:SetVertexColor(r, g, b)
				wedge.icon:SetAlpha(1)
			elseif quadrant == nextQuadrant then
				wedge.icon:SetVertexColor(tint[1], tint[2], tint[3])
				wedge.icon:SetAlpha(0.75)
			elseif replaying then
				local r, g, b, a = DimTint(tint, 0.45, 0.35)
				wedge.icon:SetVertexColor(r, g, b)
				wedge.icon:SetAlpha(a)
			else
				wedge.icon:SetVertexColor(tint[1], tint[2], tint[3])
				wedge.icon:SetAlpha(1)
			end
		end
	end
end

local function RefreshTape()
	local sequence = KASS.Sequence()
	local count = #sequence
	local rows = math.max(1, math.ceil(count / PER_ROW))
	local replaying = KASS.Phase() == "replaying"
	local cursor = replaying and KASS.Cursor() or 0

	for i = 1, count do
		local tile = GetTile(i)
		local quadrant = sequence[i]
		local markerIndex = KASS.Marker(quadrant)
		local tint = QUADRANT_TINT[quadrant]
		local row = math.floor((i - 1) / PER_ROW)
		local col = (i - 1) % PER_ROW
		local cellX = PAD + col * (TILE + GAP) + TILE / 2
		local cellY = -(PAD + row * (TILE + GAP) + TILE / 2)
		local isCurrent = replaying and i == cursor
		local isNext = replaying and i == cursor + 1
		local size = isCurrent and TILE_HIGHLIGHT or TILE

		tile.icon:ClearAllPoints()
		tile.icon:SetSize(size, size)
		tile.icon:SetPoint("CENTER", tape, "TOPLEFT", cellX, cellY)
		tile.icon:SetTexture(MarkerTexture(markerIndex))

		if isCurrent then
			local r, g, b = BrightenTint(tint, 1.25)
			tile.icon:SetVertexColor(r, g, b)
			tile.icon:SetAlpha(1)
		else
			tile.icon:SetVertexColor(tint[1], tint[2], tint[3])
			tile.icon:SetAlpha(1)
		end

		if isNext then
			tile.border:ClearAllPoints()
			tile.border:SetSize(size + TILE_OUTLINE * 2, size + TILE_OUTLINE * 2)
			tile.border:SetPoint("CENTER", tile.icon, "CENTER")
			tile.border:SetColorTexture(tint[1], tint[2], tint[3], 0.5)
			tile.border:Show()
		else
			tile.border:Hide()
		end

		tile.icon:Show()
	end

	for i = count + 1, #tiles do
		tiles[i].icon:Hide()
		tiles[i].border:Hide()
	end

	tape:SetWidth(TapeContentWidth(count))
	tape:SetHeight(PAD + rows * TILE + (rows - 1) * GAP + PAD + GRIP)
	tape.count:SetText(count > 0 and tostring(count) or "")
end

local function RefreshCallout()
	if not callout then
		return
	end

	local visible = KASSDB.calloutEnabled
		and KASS.Phase() == "replaying"
		and HUD.ShouldShow()

	if not visible then
		callout:Hide()
		return
	end

	local current = KASS.Current()
	local nextQuadrant = KASSDB.nextEnabled and KASS.Next() or nil
	local showNext = nextQuadrant ~= nil
	local height = PAD + CALLOUT_CURRENT + PAD + GRIP
	if showNext then
		height = PAD + CALLOUT_CURRENT + CALLOUT_GAP + CALLOUT_NEXT + PAD + GRIP
	end
	callout:SetHeight(height)

	if current then
		SetTurnIcon(calloutCurrent, KASS.Turn(), current)
	else
		calloutCurrent:Hide()
	end

	if showNext then
		-- Next stays a raid marker so the symbol stays readable.
		SetTurnIcon(calloutNext, "stay", nextQuadrant)
	else
		calloutNext:Hide()
	end

	callout:Show()
end

function HUD.ShouldShow()
	if KASSDB.hidden then
		return false
	end
	if not KASSDB.delveOnly then
		return true
	end
	if KASSDB.anywhere then
		return true
	end
	if KASS.simActive then
		return true
	end
	if KASS.encounterActive then
		return true
	end
	if C_Map and C_Map.GetBestMapForUnit and KASS.MAP_IDS then
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID and KASS.MAP_IDS[mapID] then
			return true
		end
	end
	return false
end

function HUD.ApplyVisibility()
	if not board or not tape then
		return
	end
	if HUD.ShouldShow() then
		board:Show()
		tape:Show()
	else
		board:Hide()
		tape:Hide()
		if callout then
			callout:Hide()
		end
	end
	HUD.Refresh()
end

function HUD.Recenter()
	for _, key in ipairs({ "display", "input", "callout" }) do
		if KASSDB[key] then
			KASSDB[key].pos = nil
		end
	end
	if board then
		RestorePosition(board, -200)
	end
	if tape then
		RestorePosition(tape, -100)
	end
	if callout then
		RestorePosition(callout, 0)
	end
	HUD.Refresh()
	print("KASS: Fenster zentriert.")
end

function HUD.Refresh()
	if not board or not tape then
		return
	end
	RefreshBoard()
	RefreshTape()
	RefreshCallout()
end

function HUD.Create()
	if board then
		return
	end

	board = CreateWindow("KASSBoard", "input", BOARD_WIDTH, BOARD_HEIGHT)
	for _, quadrant in ipairs(QUADRANT_ORDER) do
		CreateWedge(board, quadrant)
	end

	tape = CreateWindow("KASSTape", "display", TapeContentWidth(0), TAPE_MIN_HEIGHT)

	local reset = CreateFrame("Button", nil, tape, "UIPanelButtonTemplate")
	reset:SetSize(RESET_WIDTH, TILE)
	reset:SetPoint("TOPRIGHT", tape, "TOPRIGHT", -PAD, -PAD)
	reset:SetText("Zuruecksetzen")
	reset:SetScript("OnClick", function()
		KASS.Reset()
	end)

	tape.count = tape:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	tape.count:SetPoint("RIGHT", reset, "LEFT", -GAP, 0)

	callout = CreateWindow("KASSCallout", "callout", CALLOUT_WIDTH, CALLOUT_MIN_HEIGHT)
	callout:SetFrameStrata("HIGH")
	callout:SetFrameLevel(100)

	calloutCurrent = callout:CreateTexture(nil, "ARTWORK")
	calloutCurrent:SetSize(CALLOUT_CURRENT, CALLOUT_CURRENT)
	calloutCurrent:SetPoint("TOP", callout, "TOP", 0, -PAD)

	calloutNext = callout:CreateTexture(nil, "ARTWORK")
	calloutNext:SetSize(CALLOUT_NEXT, CALLOUT_NEXT)
	calloutNext:SetPoint("TOP", calloutCurrent, "BOTTOM", 0, -CALLOUT_GAP)

	RestorePosition(tape, -100)
	RestorePosition(board, -200)
	RestorePosition(callout, 0)

	board.grip:SetShown(not KASSDB.locked)
	tape.grip:SetShown(not KASSDB.locked)
	callout.grip:SetShown(not KASSDB.locked)
	HUD.ApplyVisibility()

	KASS.OnAnnounce = function()
		HUD.Refresh()
		if KASS.Speak then
			KASS.Speak()
		end
	end

	HUD.Refresh()
end

function HUD.Show()
	KASSDB.hidden = false
	HUD.ApplyVisibility()
end

function HUD.Hide()
	KASSDB.hidden = true
	HUD.ApplyVisibility()
end

function HUD.Toggle()
	if KASSDB.hidden then
		HUD.Show()
	else
		HUD.Hide()
	end
end

function HUD.SetLocked(locked)
	KASSDB.locked = locked
	if board then board.grip:SetShown(not locked) end
	if tape then tape.grip:SetShown(not locked) end
	if callout then callout.grip:SetShown(not locked) end
	if locked ~= nil then
		print("KASS: " .. (locked and "Fenster gesperrt." or "Fenster frei."))
	end
end

function HUD.SetScale(scale)
	if board then
		board:SetScale(scale)
		Store(board).scale = scale
	end
	if tape then
		tape:SetScale(scale)
		Store(tape).scale = scale
	end
	if callout then
		callout:SetScale(scale)
		Store(callout).scale = scale
	end
end

HUD.MIN_SCALE = MIN_SCALE
HUD.MAX_SCALE = MAX_SCALE
