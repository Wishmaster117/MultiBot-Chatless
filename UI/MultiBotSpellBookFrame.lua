local SPELLBOOK_PAGE_SIZE = 18

-- Réglages UI SpellBook (ACE3) : modifier ces valeurs pour ajuster rapidement le layout.
local SPELLBOOK_UI_DEFAULTS = {
	-- Taille des icônes de sorts (largeur/hauteur du bouton icon).
	ICON_SIZE = 40,
	-- Niveau de frame des icônes/boutons de sorts (base parent + boost).
	ICON_FRAMELEVEL_BOOST = 5,
	-- Taille des checkboxes "ignore" associées aux sorts.
	CHECKBOX_SIZE = 16,
	-- Surélévation du FrameLevel des checkboxes pour capter les clics au-dessus des icônes.
	CHECKBOX_FRAMELEVEL_BOOST = 30,
	-- Décalage de la checkbox par rapport à l'icône de sort.
	CHECKBOX_OFFSET_X = 24,
	CHECKBOX_OFFSET_Y = -25,

	-- Position du bloc overlay dans le contenu de la fenêtre ACE3.
	OVERLAY_LEFT_X = 18,
	OVERLAY_TOP_Y = -42,
	OVERLAY_RIGHT_X = -18,
	OVERLAY_BOTTOM_Y = 18,

	-- Position du texte de pagination (ex: 1/6).
	PAGE_TEXT_X = 0,
	PAGE_TEXT_Y = -272,
	-- Couleur du texte de pagination au format hex WoW (sans préfixe |cff).
	PAGE_TEXT_COLOR_HEX = "ffffff",

	-- Position des boutons précédent/suivant.
	PREV_BUTTON_X = 115,
	PREV_BUTTON_Y = -270,
	NEXT_BUTTON_X = 170,
	NEXT_BUTTON_Y = -270,
	NAV_BUTTON_WIDTH = 18,
	NAV_BUTTON_HEIGHT = 18,

	-- Positions X des colonnes (icône, titre, rang) en layout 3 colonnes.
	LEFT_ICON_X = 2,
	MIDDLE_ICON_X = 112,
	RIGHT_ICON_X = 222,
	LEFT_TITLE_X = 34,
	MIDDLE_TITLE_X = 144,
	RIGHT_TITLE_X = 254,
	LEFT_RANK_X = 44,
	MIDDLE_RANK_X = 154,
	RIGHT_RANK_X = 264,

	-- Réglages Y des lignes (base + espacement vertical).
	ROW_SPACING_Y = 46,
	ICON_BASE_Y = 10,
	TITLE_BASE_Y = -28,
	RANK_BASE_Y = -16,

    -- Couleur des rangs au format hex WoW (sans préfixe |cff).
    RANK_TEXT_COLOR_HEX = "ffcc00",
    -- Surélévation du FrameLevel pour les textes (rang/titre) afin de rester visibles au-dessus des icônes.
    TEXT_FRAMELEVEL_BOOST = 60,
    -- Strata du layer texte (laisser DIALOG pour rester au-dessus de la zone SpellBook).
    TEXT_FRAMESTRATA = nil,
    -- Sous-couche de rendu pour les textes (FontString draw layer sublevel, 0..7).
    TEXT_DRAW_SUBLEVEL = 5,
}

local function ensureSpellBookUIStore()
	if MultiBot.Store and MultiBot.Store.EnsureRuntimeTable then
		return MultiBot.Store.EnsureRuntimeTable("SpellBookUISettings")
	end

	if type(MultiBot.SpellBookUISettings) ~= "table" then
		MultiBot.SpellBookUISettings = {}
	end
	return MultiBot.SpellBookUISettings
end

MultiBot.SpellBookUISettings = ensureSpellBookUIStore()
for tKey, tValue in pairs(SPELLBOOK_UI_DEFAULTS) do
	if(MultiBot.SpellBookUISettings[tKey] == nil) then
		MultiBot.SpellBookUISettings[tKey] = tValue
	end
end

local function getSpellBookUI()
	local store = MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("SpellBookUISettings")
	if type(store) == "table" then
		return store
	end

	if type(MultiBot.SpellBookUISettings) == "table" then
		return MultiBot.SpellBookUISettings
	end

	return SPELLBOOK_UI_DEFAULTS
end

local function getSpellBookDefaultPageLabel()
	--local tDefault = MB_PAGE_DEFAULT
	local tDefault = MultiBot.MB_PAGE_DEFAULT
	if(type(tDefault) ~= "string" or tDefault == "") then
		return "1/1"
	end
	return tDefault
end

local function getSafeTextDrawSubLevel()
	local level = tonumber(getSpellBookUI().TEXT_DRAW_SUBLEVEL or 5) or 5
	if(level < 0) then return 0 end
	if(level > 7) then return 7 end
	return math.floor(level)
end

local function getSpellBookAceGUI()
	if(MultiBot.GetAceGUI) then
		local tAce = MultiBot.GetAceGUI()
		if(type(tAce) == "table" and type(tAce.Create) == "function") then
			return tAce
		end
	end

	if(type(LibStub) == "table") then
		local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
		if(ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function") then
			return aceGUI
		end
	end

	return nil
end

local function createSpellSlotButton(parent, x, y)
	local button = CreateFrame("Button", nil, parent)
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	button:SetWidth(getSpellBookUI().ICON_SIZE or 22)
	button:SetHeight(getSpellBookUI().ICON_SIZE or 22)
	button:SetFrameStrata(parent:GetFrameStrata())
	button:SetFrameLevel((parent:GetFrameLevel() or 0) + (getSpellBookUI().ICON_FRAMELEVEL_BOOST or 5))

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints(button)
	button.icon:SetTexture(MultiBot.SafeTexturePath("Interface\\Icons\\INV_Misc_QuestionMark"))

	button.spell = 0
	button.texture = "Interface\\Icons\\INV_Misc_QuestionMark"
	button.link = ""

	button.doShow = function(self)
		(self or button):Show()
	end

	button.doHide = function(self)
		(self or button):Hide()
	end

	button.getName = function(_)
		return MultiBot.spellbook and MultiBot.spellbook.name or ""
	end

	button:SetScript("OnClick", function(self, pMouseButton)
		if(pMouseButton == "LeftButton" and self.doLeft) then
			self.doLeft(self)
			return
		end

		if(pMouseButton == "RightButton" and self.doRight) then
			self.doRight(self)
		end
	end)

	button:SetScript("OnEnter", function(self)
		if(not GameTooltip) then return end
		if(not self.spell or self.spell == 0) then return end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		local tLink = MultiBot.IF(type(self.link) == "string", self.link, "")
		local tSpellLink = "spell:" .. tostring(self.spell)
		local tHasWoWLink = (tLink ~= "" and string.find(tLink, "|H", 1, true) ~= nil)

		local ok = false
		if(tHasWoWLink) then
			ok = pcall(GameTooltip.SetHyperlink, GameTooltip, tLink)
		end

		if(not ok) then
			pcall(GameTooltip.SetHyperlink, GameTooltip, tSpellLink)
		end
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function(_)
		if(GameTooltip and GameTooltip.Hide) then
			GameTooltip:Hide()
		end
	end)

	return button
end

local function createSpellIgnoreCheck(parent, x, y)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	check:SetWidth(getSpellBookUI().CHECKBOX_SIZE or 16)
	check:SetHeight(getSpellBookUI().CHECKBOX_SIZE or 16)
	check:SetFrameStrata(parent:GetFrameStrata())
	check:SetFrameLevel((parent:GetFrameLevel() or 0) + (getSpellBookUI().CHECKBOX_FRAMELEVEL_BOOST or 30))
	check:EnableMouse(true)
	check.spell = 0

	check.doShow = function(self)
		(self or check):Show()
	end

	check.doHide = function(self)
		(self or check):Hide()
	end

	check.getName = function(_)
		return MultiBot.spellbook and MultiBot.spellbook.name or ""
	end

	check:SetScript("OnClick", function(self)
		if(self.doClick) then
			self.doClick(self)
		end
	end)

	return check
end

local function getUnitsRootFrame()
	local frames = MultiBot.frames
	local multiBar = frames and frames["MultiBar"]
	return multiBar and multiBar.frames and multiBar.frames["Units"]
end

local function setSpellbookButtonEnabled(botName, isEnabled)
	if(type(botName) ~= "string" or botName == "") then
		return
	end

	local unitsRoot = getUnitsRootFrame()
	local unitFrame = unitsRoot and unitsRoot.frames and unitsRoot.frames[botName]
	if(not unitFrame or not unitFrame.getButton) then
		return
	end

	local button = unitFrame.getButton("Spellbook")
	if(not button) then
		return
	end

	if(isEnabled and button.setEnable) then
		button.setEnable()
		return
	end

	if(button.setDisable) then
		button.setDisable()
	end
end

local function syncSpellbookButtonStateOnHide()
	local spellbook = MultiBot.spellbook
	if(not spellbook) then
		return
	end

	setSpellbookButtonEnabled(spellbook.name, false)
end

local function createSpellbookContent(window)
	local root = CreateFrame("Frame", nil, window.content)
	root:SetAllPoints(window.content)

	root:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	if(root.SetBackdropColor) then root:SetBackdropColor(0.07, 0.07, 0.07, 0.92) end
	if(root.SetBackdropBorderColor) then root:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95) end

	local tOverlay = CreateFrame("Frame", nil, root)
	tOverlay:SetPoint("TOPLEFT", root, "TOPLEFT", getSpellBookUI().OVERLAY_LEFT_X or 18, getSpellBookUI().OVERLAY_TOP_Y or -42)
	tOverlay:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", getSpellBookUI().OVERLAY_RIGHT_X or -18, getSpellBookUI().OVERLAY_BOTTOM_Y or 18)

	tOverlay.texts = {}
	tOverlay.buttons = {}

	local textLayer = CreateFrame("Frame", nil, tOverlay)
	textLayer:SetAllPoints(tOverlay)
	textLayer:SetFrameStrata(getSpellBookUI().TEXT_FRAMESTRATA or tOverlay:GetFrameStrata())
	textLayer:SetFrameLevel((tOverlay:GetFrameLevel() or 0) + (getSpellBookUI().TEXT_FRAMELEVEL_BOOST or 60))
	textLayer:EnableMouse(false)

	tOverlay.setText = function(pKey, pText)
		local text = tOverlay.texts[pKey]
		if(text) then
			text:SetText(pText or "")
		end
	end

	tOverlay.setButton = function(pKey, pTexture, pLink)
		local button = tOverlay.buttons[pKey]
		if(not button) then
			return
		end

		button.texture = pTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
		button.link = pLink or ""
		if(button.icon) then
			local texturePath = button.texture
			if(type(texturePath) == "string" and not string.find(texturePath, "[/\\]") and not string.find(texturePath, "^Interface")) then
				texturePath = "Interface\\Icons\\" .. texturePath
			end
			button.icon:SetTexture(MultiBot.SafeTexturePath(texturePath))
		end
	end

	local pages = textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pages:SetPoint("TOP", textLayer, "TOP", getSpellBookUI().PAGE_TEXT_X or 14, getSpellBookUI().PAGE_TEXT_Y or 13)
	pages:SetDrawLayer("OVERLAY", getSafeTextDrawSubLevel())
	pages:SetText("|cff" .. (getSpellBookUI().PAGE_TEXT_COLOR_HEX or "ffffff") .. getSpellBookDefaultPageLabel() .. "|r")
	tOverlay.texts["Pages"] = pages

	local prevButton = CreateFrame("Button", nil, tOverlay, "UIPanelButtonTemplate")
	prevButton:SetPoint("TOPLEFT", tOverlay, "TOPLEFT", getSpellBookUI().PREV_BUTTON_X or 35, getSpellBookUI().PREV_BUTTON_Y or 2)
	prevButton:SetWidth(getSpellBookUI().NAV_BUTTON_WIDTH or 18)
	prevButton:SetHeight(getSpellBookUI().NAV_BUTTON_HEIGHT or 18)
	prevButton:SetText("<")
	prevButton.doShow = function(self) (self or prevButton):Show() end
	prevButton.doHide = function(self) (self or prevButton):Hide() end
	prevButton.getName = function(_) return MultiBot.spellbook and MultiBot.spellbook.name or "" end
	tOverlay.buttons["<"] = prevButton

	local nextButton = CreateFrame("Button", nil, tOverlay, "UIPanelButtonTemplate")
	nextButton:SetPoint("TOPLEFT", tOverlay, "TOPLEFT", getSpellBookUI().NEXT_BUTTON_X or 135, getSpellBookUI().NEXT_BUTTON_Y or 2)
	nextButton:SetWidth(getSpellBookUI().NAV_BUTTON_WIDTH or 18)
	nextButton:SetHeight(getSpellBookUI().NAV_BUTTON_HEIGHT or 18)
	nextButton:SetText(">")
	nextButton.doShow = function(self) (self or nextButton):Show() end
	nextButton.doHide = function(self) (self or nextButton):Hide() end
	nextButton.getName = function(_) return MultiBot.spellbook and MultiBot.spellbook.name or "" end
	tOverlay.buttons[">"] = nextButton

	local function onSpellSlotLeftClick(pButton)
		SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
	end

	local function onSpellSlotRightClick(pButton)
		MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
	end

	for i = 1, SPELLBOOK_PAGE_SIZE do
		local tIndex = MultiBot.IF(i < 10, "0", "") .. i
		local tCol = (i - 1) % 3
		local tRow = math.floor((i - 1) / 3)
		local tBaseX = MultiBot.IF(tCol == 0, (getSpellBookUI().LEFT_ICON_X or 2), MultiBot.IF(tCol == 1, (getSpellBookUI().MIDDLE_ICON_X or 112), (getSpellBookUI().RIGHT_ICON_X or 222)))
		local tTitleX = MultiBot.IF(tCol == 0, (getSpellBookUI().LEFT_TITLE_X or 34), MultiBot.IF(tCol == 1, (getSpellBookUI().MIDDLE_TITLE_X or 144), (getSpellBookUI().RIGHT_TITLE_X or 254)))
		local tRankX = MultiBot.IF(tCol == 0, (getSpellBookUI().LEFT_RANK_X or 34), MultiBot.IF(tCol == 1, (getSpellBookUI().MIDDLE_RANK_X or 144), (getSpellBookUI().RIGHT_RANK_X or 254)))
		local tY = (getSpellBookUI().ICON_BASE_Y or -26) - ((getSpellBookUI().ROW_SPACING_Y or 36) * tRow)
		local tTextY = (getSpellBookUI().TITLE_BASE_Y or -28) - ((getSpellBookUI().ROW_SPACING_Y or 36) * tRow)
		local tRankY = (getSpellBookUI().RANK_BASE_Y or -38) - ((getSpellBookUI().ROW_SPACING_Y or 36) * tRow)

		local rank = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		rank:SetPoint("TOPLEFT", textLayer, "TOPLEFT", tRankX, tRankY)
		rank:SetDrawLayer("OVERLAY", getSafeTextDrawSubLevel())
		rank:SetText("|cff" .. (getSpellBookUI().RANK_TEXT_COLOR_HEX or "ffcc00") .. MultiBot.L("spellbook.rank") .. "|r")
		tOverlay.texts["R" .. tIndex] = rank

		local titleText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		titleText:SetPoint("TOPLEFT", textLayer, "TOPLEFT", tTitleX, tTextY)
		titleText:SetDrawLayer("OVERLAY", getSafeTextDrawSubLevel())
		titleText:SetText("|cffffcc00" .. MultiBot.L("spellbook.title") .. "|r")
		titleText:Hide()
		tOverlay.texts["T" .. tIndex] = titleText

		local slotButton = createSpellSlotButton(tOverlay, tBaseX, tY)
		slotButton.doLeft = onSpellSlotLeftClick
		slotButton.doRight = onSpellSlotRightClick
		tOverlay.buttons["S" .. tIndex] = slotButton

		local check = createSpellIgnoreCheck(tOverlay, tBaseX + (getSpellBookUI().CHECKBOX_OFFSET_X or 16), tY + (getSpellBookUI().CHECKBOX_OFFSET_Y or -2))
		tOverlay.buttons["C" .. tIndex] = check
	end

	return root, tOverlay
end

function MultiBot.InitializeSpellBookFrame()
	local aceGUI = getSpellBookAceGUI()
	if(not aceGUI) then
		UIErrorsFrame:AddMessage("AceGUI-3.0 is required for SpellBook", 1, 0.2, 0.2, 1)
		return
	end

	local window = aceGUI:Create("Window")
	window:SetTitle(SPELLBOOK)
	window:SetWidth(360)
	window:SetHeight(390)
	window:EnableResize(false)
	window:SetLayout("Fill")
	window.frame:SetClampedToScreen(true)
	local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
	if strataLevel then
		window.frame:SetFrameStrata(strataLevel)
	end
	window:SetCallback("OnClose", function(widget)
		widget:Hide()
	end)
	window:Hide()
	window.frame:HookScript("OnHide", syncSpellbookButtonStateOnHide)

	local root, overlay = createSpellbookContent(window)

	MultiBot.spellbook = {
		window = window,
		root = root,
		frames = { Overlay = overlay },
		spells = {},
		icons = {},
		max = 1,
		now = 1,
		from = 1,
		to = SPELLBOOK_PAGE_SIZE,
		name = "",
		index = 0,
	}

	MultiBot.spellbook.setTitle = function(self, pTitle)
		if(self.window and self.window.SetTitle) then
			self.window:SetTitle(pTitle or SPELLBOOK)
		end
	end

	MultiBot.spellbook.Show = function(self)
		if(self.window) then
			self.window:Show()
		end
	end

	MultiBot.spellbook.Hide = function(self)
		if(self.window) then
			self.window:Hide()
		end
	end

	MultiBot.spellbook.IsVisible = function(self)
		return self.window and self.window.frame and self.window.frame:IsShown() or false
	end

	MultiBot.spellbook.setPoint = function(x, y)
		if(type(x) ~= "number" or type(y) ~= "number") then return end
		window.frame:ClearAllPoints()
		window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
	end

	MultiBot.spellbook.GetRight = function(self)
		return self.window and self.window.frame and self.window.frame:GetRight() or 0
	end

	MultiBot.spellbook.GetBottom = function(self)
		return self.window and self.window.frame and self.window.frame:GetBottom() or 0
	end

	MultiBot.spellbook.beginPayload = function(self, botName)
		if(MultiBot.beginSpellbookCollection) then
			MultiBot.beginSpellbookCollection(botName or "")
		end
		return self
	end

	MultiBot.spellbook.appendSpellId = function(self, spellId, botName)
		if(MultiBot.addSpellById) then
			return MultiBot.addSpellById(spellId, botName or self.name or "")
		end

		return false
	end

	MultiBot.spellbook.finishPayload = function(self)
		if(MultiBot.finishSpellbookCollection) then
			MultiBot.finishSpellbookCollection()
		end
		return self
	end

	for i = 1, GetNumMacroIcons() do MultiBot.spellbook.icons[GetMacroIconInfo(i)] = i end

	-- Default baseline position (legacy parity), can be overridden by saved layout restore.
	MultiBot.spellbook.setPoint(-802, 302)

	overlay.buttons["<"].doLeft = function(pButton)
		local tSpellbook = MultiBot.spellbook
		tSpellbook.to = tSpellbook.to - SPELLBOOK_PAGE_SIZE
		tSpellbook.now = tSpellbook.now - 1
		tSpellbook.from = tSpellbook.from - SPELLBOOK_PAGE_SIZE
		tSpellbook.frames["Overlay"].setText("Pages", tSpellbook.now .. "/" .. tSpellbook.max)
		tSpellbook.frames["Overlay"].buttons[">"]:doShow()

		if(tSpellbook.now == 1) then pButton:doHide() end
		local tIndex = 1
		for i = tSpellbook.from, tSpellbook.to do
			MultiBot.setSpell(tIndex, tSpellbook.spells[i], pButton:getName())
			tIndex = tIndex + 1
		end
	end

	overlay.buttons["<"]:SetScript("OnClick", function(self)
		if(self.doLeft) then self.doLeft(self) end
	end)

	overlay.buttons[">"].doLeft = function(pButton)
		local tSpellbook = MultiBot.spellbook
		tSpellbook.to = tSpellbook.to + SPELLBOOK_PAGE_SIZE
		tSpellbook.now = tSpellbook.now + 1
		tSpellbook.from = tSpellbook.from + SPELLBOOK_PAGE_SIZE
		tSpellbook.frames["Overlay"].setText("Pages", tSpellbook.now .. "/" .. tSpellbook.max)
		tSpellbook.frames["Overlay"].buttons["<"]:doShow()

		if(tSpellbook.now == tSpellbook.max) then pButton:doHide() end
		local tIndex = 1
		for i = tSpellbook.from, tSpellbook.to do
			MultiBot.setSpell(tIndex, tSpellbook.spells[i], pButton:getName())
			tIndex = tIndex + 1
		end
	end

	overlay.buttons[">"]:SetScript("OnClick", function(self)
		if(self.doLeft) then self.doLeft(self) end
	end)

end