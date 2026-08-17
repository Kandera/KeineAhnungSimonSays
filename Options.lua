-- Settings panel under AddOns (12.1 Settings API). German labels.

local ADDON_NAME = ...

KASS.Options = KASS.Options or {}

local Options = KASS.Options
local category
local panel
local selectedQuadrant = "N"

local QUADRANTS = {
	{ key = "N", label = "Nord" },
	{ key = "E", label = "Ost" },
	{ key = "S", label = "Sued" },
	{ key = "W", label = "West" },
}

local quadrantButtons = {}
local markerPreview = {}

local showCheck
local delveCheck
local lockCheck
local voiceCheck
local calloutCheck
local nextCheck
local styleDropdown
local volumeSlider
local volumeLabel

local function MarkerTexture(index)
	return ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(index)
end

local function RefreshHUD()
	if KASS.HUD and KASS.HUD.ApplyVisibility then
		KASS.HUD.ApplyVisibility()
	elseif KASS.HUD and KASS.HUD.Refresh then
		KASS.HUD.Refresh()
	end
end

local function SyncMarkersFromDB()
	if not KASSDB or not KASSDB.markers then
		return
	end
	for quadrant, index in pairs(KASSDB.markers) do
		KASS.MARKERS[quadrant] = index
	end
end

local function RefreshMarkerPreview()
	for _, entry in ipairs(QUADRANTS) do
		local quadrant = entry.key
		local tex = markerPreview[quadrant]
		if tex then
			tex:SetTexture(MarkerTexture(KASS.Marker(quadrant)))
		end
		local button = quadrantButtons[quadrant]
		if button and button.highlight then
			if quadrant == selectedQuadrant then
				button.highlight:Show()
			else
				button.highlight:Hide()
			end
		end
	end
end

local function SetSelectedQuadrant(quadrant)
	selectedQuadrant = quadrant
	RefreshMarkerPreview()
end

local function RefreshStyleDropdown()
	if not styleDropdown then
		return
	end
	local voice = KASSDB.voice or {}
	if voice.style == "direction" then
		UIDropDownMenu_SetSelectedValue(styleDropdown, "direction")
		UIDropDownMenu_SetText(styleDropdown, "Richtung")
	else
		UIDropDownMenu_SetSelectedValue(styleDropdown, "marker")
		UIDropDownMenu_SetText(styleDropdown, "Markierung")
	end
end

local function RefreshVolumeLabel()
	if volumeLabel and volumeSlider then
		volumeLabel:SetText(("Lautstaerke: %d"):format(math.floor(volumeSlider:GetValue() + 0.5)))
	end
end

local function OnRefresh()
	if not KASSDB then
		return
	end

	showCheck:SetChecked(not KASSDB.hidden)
	delveCheck:SetChecked(KASSDB.delveOnly)
	lockCheck:SetChecked(KASSDB.locked)
	voiceCheck:SetChecked(KASSDB.voice and KASSDB.voice.enabled)
	calloutCheck:SetChecked(KASSDB.calloutEnabled)
	nextCheck:SetChecked(KASSDB.nextEnabled)

	if volumeSlider then
		volumeSlider:SetValue((KASSDB.voice and KASSDB.voice.volume) or 100)
	end
	RefreshVolumeLabel()
	RefreshStyleDropdown()
	SyncMarkersFromDB()
	RefreshMarkerPreview()
end

local function OnDefault()
	KASSDB.hidden = false
	KASSDB.delveOnly = true
	KASSDB.locked = false
	KASSDB.calloutEnabled = true
	KASSDB.nextEnabled = true
	KASSDB.voice = { enabled = true, style = "marker", volume = 100 }
	KASSDB.markers = { N = 1, E = 3, S = 6, W = 7 }
	SyncMarkersFromDB()
	if KASS.HUD then
		if KASS.HUD.SetLocked then
			KASS.HUD.SetLocked(false)
		end
		RefreshHUD()
	end
	if panel then
		OnRefresh()
	end
end

local function OnCommit()
	OnRefresh()
end

local function CreateCheckbox(parent, label, point, relPoint, x, y, onClick)
	local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint(point, parent, relPoint, x, y)
	check.Text:SetText(label)
	check:SetScript("OnClick", onClick)
	return check
end

local function CreateSectionTitle(parent, text, y)
	local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, y)
	title:SetText(text)
	return title
end

local function BuildPanel()
	panel = CreateFrame("Frame", "KASSOptionsPanel")
	panel.name = "Keine Ahnung Simon Says"
	panel.OnRefresh = OnRefresh
	panel.OnDefault = OnDefault
	panel.OnCommit = OnCommit

	local y = -16
	CreateSectionTitle(panel, "Anzeige", y)
	y = y - 28

	showCheck = CreateCheckbox(panel, "Fenster anzeigen", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		if self:GetChecked() then
			KASSDB.hidden = false
			RefreshHUD()
		else
			if KASS.HUD and KASS.HUD.Hide then
				KASS.HUD.Hide()
			else
				KASSDB.hidden = true
			end
		end
	end)
	y = y - 28

	delveCheck = CreateCheckbox(panel, "Nur im Delve anzeigen", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		KASSDB.delveOnly = self:GetChecked()
		RefreshHUD()
	end)
	y = y - 28

	lockCheck = CreateCheckbox(panel, "Fenster sperren", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		if KASS.HUD and KASS.HUD.SetLocked then
			KASS.HUD.SetLocked(self:GetChecked())
		else
			KASSDB.locked = self:GetChecked()
		end
	end)
	y = y - 40

	CreateSectionTitle(panel, "Markierungen", y)
	y = y - 28

	local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", 16, y)
	hint:SetWidth(420)
	hint:SetJustifyH("LEFT")
	hint:SetText("Richtung waehlen, dann ein Raidzeichen zuweisen. Belegte Zeichen tauschen.")
	y = y - 36

	for i, entry in ipairs(QUADRANTS) do
		local quadrant = entry.key
		local button = CreateFrame("Button", nil, panel)
		button:SetSize(72, 40)
		button:SetPoint("TOPLEFT", 16 + (i - 1) * 78, y)

		local highlight = button:CreateTexture(nil, "BACKGROUND")
		highlight:SetAllPoints()
		highlight:SetColorTexture(1, 0.82, 0, 0.35)
		highlight:Hide()
		button.highlight = highlight

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(24, 24)
		icon:SetPoint("LEFT", 4, 0)
		markerPreview[quadrant] = icon

		local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
		label:SetText(entry.label)

		button:SetScript("OnClick", function()
			SetSelectedQuadrant(quadrant)
		end)
		quadrantButtons[quadrant] = button
	end
	y = y - 48

	for index = 1, 8 do
		local button = CreateFrame("Button", nil, panel)
		button:SetSize(32, 32)
		local col = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		button:SetPoint("TOPLEFT", 16 + col * 36, y - row * 36)

		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexture(MarkerTexture(index))

		button:SetScript("OnClick", function()
			KASS.SetMarker(selectedQuadrant, index)
			RefreshMarkerPreview()
		end)
	end
	y = y - 88

	CreateSectionTitle(panel, "Sprache", y)
	y = y - 28

	voiceCheck = CreateCheckbox(panel, "Sprachausgabe aktivieren", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		KASSDB.voice = KASSDB.voice or {}
		KASSDB.voice.enabled = self:GetChecked()
	end)
	y = y - 28

	local styleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	styleLabel:SetPoint("TOPLEFT", 16, y)
	styleLabel:SetText("Stil:")

	styleDropdown = CreateFrame("Frame", "KASSOptionsStyleDropdown", panel, "UIDropDownMenuTemplate")
	styleDropdown:SetPoint("TOPLEFT", styleLabel, "TOPRIGHT", -8, 12)
	UIDropDownMenu_SetWidth(styleDropdown, 140)
	UIDropDownMenu_Initialize(styleDropdown, function(_, level)
		local info = UIDropDownMenu_CreateInfo()
		info.func = function(_, value)
			KASSDB.voice = KASSDB.voice or {}
			KASSDB.voice.style = value
			RefreshStyleDropdown()
		end
		info.text = "Markierung"
		info.value = "marker"
		info.checked = (KASSDB.voice and KASSDB.voice.style) ~= "direction"
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.func = function(_, value)
			KASSDB.voice = KASSDB.voice or {}
			KASSDB.voice.style = value
			RefreshStyleDropdown()
		end
		info.text = "Richtung"
		info.value = "direction"
		info.checked = KASSDB.voice and KASSDB.voice.style == "direction"
		UIDropDownMenu_AddButton(info, level)
	end)
	y = y - 40

	volumeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	volumeLabel:SetPoint("TOPLEFT", 16, y)
	volumeLabel:SetText("Lautstaerke: 100")

	volumeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
	volumeSlider:SetPoint("TOPLEFT", volumeLabel, "BOTTOMLEFT", 0, -12)
	volumeSlider:SetMinMaxValues(0, 100)
	volumeSlider:SetValueStep(5)
	volumeSlider:SetObeyStepOnDrag(true)
	volumeSlider:SetWidth(220)
	volumeSlider:SetScript("OnValueChanged", function(self)
		KASSDB.voice = KASSDB.voice or {}
		KASSDB.voice.volume = math.floor(self:GetValue() + 0.5)
		RefreshVolumeLabel()
	end)
	y = y - 56

	CreateSectionTitle(panel, "Callout", y)
	y = y - 28

	calloutCheck = CreateCheckbox(panel, "Callout anzeigen", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		KASSDB.calloutEnabled = self:GetChecked()
		RefreshHUD()
	end)
	y = y - 28

	nextCheck = CreateCheckbox(panel, "Naechste Richtung anzeigen", "TOPLEFT", "TOPLEFT", 16, y, function(self)
		KASSDB.nextEnabled = self:GetChecked()
		RefreshHUD()
	end)

	panel:SetScript("OnShow", function()
		OnRefresh()
	end)
end

local function RegisterSettings()
	BuildPanel()
	category = Settings.RegisterCanvasLayoutCategory(panel, "Keine Ahnung Simon Says")
	Settings.RegisterAddOnCategory(category)
end

function Options.Open()
	if category then
		Settings.OpenToCategory(category:GetID())
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == ADDON_NAME then
		RegisterSettings()
		loader:UnregisterEvent("ADDON_LOADED")
	end
end)
