if not MultiBot then return end

local HUNTER_QUICK_FRAME_KEY = "HunterQuick"
local BUTTON_SIZE = 25
local BUTTON_GAP = 4
local ROW_WIDTH = 320
local ROW_HEIGHT = (BUTTON_SIZE * 3) + (BUTTON_GAP * 2)
local HUNTER_QUICK_ROW_SPACING_DEFAULT = 26
local WINDOW_HEIGHT = ROW_HEIGHT
local WINDOW_PADDING_X = 0
local WINDOW_PADDING_Y = 0
local WINDOW_TITLE = "Quick Hunter"
local WINDOW_DEFAULT_POINT = { point = "TOP", relPoint = "TOP", x = -76.67194107900505, y = -29.34896683789212 }
local ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
local HANDLE_WIDTH = 12
local HANDLE_HEIGHT = 18
local HANDLE_ALPHA = 0.45
local HANDLE_HOVER_ALPHA = 0.85
--local HANDLE_ICON = "Interface\\AddOns\\MultiBot\\Icons\\class_hunter.blp"

local PET_STANCE_DEFINITIONS = {
    { key = "aggressive", icon = "ability_Racial_BloodRage", tip = "tips.hunter.pet.aggressive", persistent = true },
    { key = "passive",    icon = "Spell_Nature_Sleep",       tip = "tips.hunter.pet.passive",    persistent = true },
    { key = "defensive",  icon = "Ability_Defend",           tip = "tips.hunter.pet.defensive",  persistent = true },
    { key = "stance",     icon = "Temp",                     tip = "tips.hunter.pet.curstance" },
    { key = "attack",     icon = "Ability_GhoulFrenzy",      tip = "tips.hunter.pet.attack" },
    { key = "follow",     icon = "ability_tracking",         tip = "tips.hunter.pet.follow" },
    { key = "stay",       icon = "Spell_Nature_TimeStop",    tip = "tips.hunter.pet.stay" },
}

local PET_UTILITY_DEFINITIONS = {
    { label = "Name",    command = "tame name %s",   icon = "inv_scroll_11",         tip = "tips.hunter.pet.name",   action = "search" },
    { label = "Id",      command = "tame id %s",     icon = "inv_scroll_14",         tip = "tips.hunter.pet.id",     action = "prompt_id" },
    { label = "Family",  command = "tame family %s", icon = "inv_misc_enggizmos_03", tip = "tips.hunter.pet.family", action = "family" },
    { label = "Rename",  command = "tame rename %s", icon = "inv_scroll_01",         tip = "tips.hunter.pet.rename", action = "prompt_rename" },
    { label = "Abandon", command = "tame abandon",   icon = "spell_nature_spiritwolf", tip = "tips.hunter.pet.abandon", action = "direct" },
}

local function getAceGUI()
    if MultiBot.GetAceGUI then
        local ace = MultiBot.GetAceGUI()
        if type(ace) == "table" and type(ace.Create) == "function" then
            return ace
        end
    end

    if type(LibStub) == "table" then
        local ok, ace = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
        if ok and type(ace) == "table" and type(ace.Create) == "function" then
            return ace
        end
    end

    return nil
end

local function addPopupBackdrop(frame, bgAlpha)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    if frame.SetBackdropColor then
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or 0.92)
    end

    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

local function getPopupHost(title, width, height, missingDepMessage, persistenceKey)
    if type(MultiBot.CreateAceQuestPopupHost) == "function" then
        return MultiBot.CreateAceQuestPopupHost(title, width, height, missingDepMessage, persistenceKey)
    end

    local ace = getAceGUI()
    if not ace then
        return nil
    end

    local window = ace:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(title or "")
    window:SetWidth(width)
    window:SetHeight(height)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end
    window:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)
    window:Hide()

    local root = CreateFrame("Frame", nil, window.content)
    root:SetPoint("TOPLEFT", window.content, "TOPLEFT", 8, -8)
    root:SetPoint("BOTTOMRIGHT", window.content, "BOTTOMRIGHT", -8, 8)
    addPopupBackdrop(root, 0.92)

    local host = CreateFrame("Frame", nil, root)
    host:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -8)
    host:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, 8)
    host.window = window
    host.root = root
    host.Show = function(self)
        self.window:Show()
    end
    host.Hide = function(self)
        self.window:Hide()
    end
    host.IsShown = function(self)
        return self.window and self.window.frame and self.window.frame:IsShown()
    end

    return host
end

local function sanitizeName(name)
    return tostring(name or ""):gsub("[^%w_]", "_")
end

local function safeTexturePath(path)
    if MultiBot.SafeTexturePath then
        return MultiBot.SafeTexturePath(path or ICON_FALLBACK)
    end
    return path or ICON_FALLBACK
end

local function setTooltip(owner, text)
    if not owner or not GameTooltip or not text or text == "" then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(text, 1, 1, 1, true)
    GameTooltip:Show()
end

local function createIconButton(parent, name, iconPath, tooltipText, size)
    local button = CreateFrame("Button", name, parent)
    local actualSize = size or BUTTON_SIZE

    button:SetSize(actualSize, actualSize)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture(safeTexturePath(iconPath))
    button.icon = icon

    local pushed = button:CreateTexture(nil, "OVERLAY")
    pushed:SetAllPoints(icon)
    pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    pushed:SetBlendMode("MOD")
    button:SetPushedTexture(pushed)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(icon)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    button.highlight = highlight

    local selectedGlow = button:CreateTexture(nil, "OVERLAY")
    selectedGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    selectedGlow:SetBlendMode("ADD")
    selectedGlow:SetPoint("CENTER", button, "CENTER", 0, 0)
    selectedGlow:SetSize(actualSize * 1.75, actualSize * 1.75)
    selectedGlow:Hide()
    button.selectedGlow = selectedGlow

    button.tooltipText = tooltipText
    button.__mbDisabled = false
    button.__mbSelected = false

    function button:SetIcon(path)
        self.icon:SetTexture(safeTexturePath(path))
        self.__mbIcon = path
    end

    function button:SetTooltipText(text)
        self.tooltipText = text
    end

    function button:SetButtonDisabled(disabled)
        self.__mbDisabled = disabled and true or false
        self:EnableMouse(not self.__mbDisabled)

        if self.icon and self.icon.SetDesaturated then
            self.icon:SetDesaturated(self.__mbDisabled)
        end

        if self.icon and self.icon.SetVertexColor then
            if self.__mbDisabled then
                self.icon:SetVertexColor(0.45, 0.45, 0.45, 0.9)
            else
                self.icon:SetVertexColor(1, 1, 1, 1)
            end
        end

        if self.SetAlpha then
            self:SetAlpha(self.__mbDisabled and 0.5 or 1)
        end
    end

    function button:SetButtonSelected(selected)
        self.__mbSelected = selected and true or false

        if self.selectedGlow then
            if self.__mbSelected then
                self.selectedGlow:Show()
            else
                self.selectedGlow:Hide()
            end
        end

        if self.SetAlpha and not self.__mbDisabled then
            self:SetAlpha(self.__mbSelected and 0.9 or 1)
        end
    end

    button:SetScript("OnEnter", function(self)
        setTooltip(self, self.tooltipText)
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    return button
end

local HunterQuick = MultiBot.HunterQuick or {}
MultiBot.HunterQuick = HunterQuick
HunterQuick.entries = HunterQuick.entries or {}
HunterQuick.SEARCH_FRAME = HunterQuick.SEARCH_FRAME or nil
HunterQuick.FAMILY_FRAME = HunterQuick.FAMILY_FRAME or nil

local function normalizeRowSpacing(value)
    local spacing = tonumber(value) or HUNTER_QUICK_ROW_SPACING_DEFAULT
    if spacing < BUTTON_SIZE then
        spacing = BUTTON_SIZE
    end
    return spacing
end

function HunterQuick:GetRowSpacing()
    self.rowSpacing = normalizeRowSpacing(self.rowSpacing)
    return self.rowSpacing
end

function HunterQuick:SetRowSpacing(value)
    local spacing = normalizeRowSpacing(value)
    if self.rowSpacing == spacing then
        return spacing
    end

    self.rowSpacing = spacing
    if self.Rebuild then
        self:Rebuild()
    end

    return spacing
end

MultiBot.GetHunterQuickSpacing = function()
    return HunterQuick:GetRowSpacing()
end

MultiBot.SetHunterQuickSpacing = function(value)
    return HunterQuick:SetRowSpacing(value)
end

local function stripWindowChrome(window)
    if not window or not window.frame then
        return
    end

    if window.closebutton and window.closebutton.Hide then
        window.closebutton:Hide()
    end
    if window.statusbg and window.statusbg.Hide then
        window.statusbg:Hide()
    end
    if window.statustext and window.statustext.Hide then
        window.statustext:Hide()
    end
    if window.title and window.title.Hide then
        window.title:Hide()
    end
    if window.titletext and window.titletext.Hide then
        window.titletext:Hide()
    end

    window:EnableResize(false)

    local frame = window.frame
    if frame and frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region.Hide then
                region:Hide()
            end
        end
    end
end

local function updateWindowTitle(service, count)
    if not service.window or not service.window.SetTitle then
        return
    end

    if count and count > 0 then
        service.window:SetTitle(string.format("%s (%d)", WINDOW_TITLE, count))
    else
        service.window:SetTitle(WINDOW_TITLE)
    end
end

local persistWindowPosition

local function createCollapseHandle(service)
    if not service.window or not service.window.frame or service.toggleHandle then
        return service.toggleHandle
    end

    local handle = CreateFrame("Button", nil, service.window.frame)
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        handle:SetFrameStrata(strataLevel)
    end
    handle:SetMovable(false)
    handle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    handle:RegisterForDrag("RightButton")

    handle:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    handle:SetBackdropColor(0.04, 0.04, 0.05, HANDLE_ALPHA)
    handle:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.85)

    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 0)
    label:SetText("×")
    label:SetTextColor(0.92, 0.92, 0.92, 0.95)
    handle.label = label

    handle:SetScript("OnEnter", function(self)
        self:SetAlpha(HANDLE_HOVER_ALPHA)
        if self.label and self.label.SetTextColor then
            self.label:SetTextColor(1, 1, 1, 1)
        end
        setTooltip(self, "Left click : Show / Hide Right Click :  Move Quick Hunter")
    end)
    handle:SetScript("OnLeave", function(self)
        self:SetAlpha(HANDLE_ALPHA)
        if self.label and self.label.SetTextColor then
            self.label:SetTextColor(0.92, 0.92, 0.92, 0.95)
        end
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
    handle:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" and service.ToggleManualVisibility then
            service:ToggleManualVisibility()
        end
    end)
    handle:SetScript("OnDragStart", function()
        local frame = service.window and service.window.frame
        if not frame then
            return
        end
        frame:StartMoving()
        frame.__mbRightDragging = true
    end)
    handle:SetScript("OnDragStop", function()
        local frame = service.window and service.window.frame
        if not frame then
            return
        end
        frame.__mbRightDragging = nil
        frame:StopMovingOrSizing()
        persistWindowPosition(frame)
    end)
    handle:SetAlpha(HANDLE_ALPHA)

    service.toggleHandle = handle
    return handle
end

persistWindowPosition = function(frame)
    if not frame or not MultiBot.SetQuickFramePosition then
        return
    end

    local point, _, relPoint, x, y = frame:GetPoint()
    MultiBot.SetQuickFramePosition(HUNTER_QUICK_FRAME_KEY, point, relPoint, x, y)
end

local function bindWindowDrag(service)
    if not service.window or not service.window.frame or service.__dragBound then
        return
    end

    service.__dragBound = true

    local frame = service.window.frame
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local title = service.window.title
    if title then
        title:HookScript("OnMouseDown", function(_, mouseButton)
            if mouseButton ~= "RightButton" then
                return
            end
            frame:StartMoving()
            frame.__mbRightDragging = true
        end)

        title:HookScript("OnMouseUp", function()
            if not frame.__mbRightDragging then
                return
            end
            frame.__mbRightDragging = nil
            frame:StopMovingOrSizing()
            persistWindowPosition(frame)
        end)
    end

    frame:HookScript("OnHide", function(current)
        if current.__mbRightDragging then
            current.__mbRightDragging = nil
            current:StopMovingOrSizing()
        end
    end)

    frame:HookScript("OnMouseUp", function(current)
        if not current.__mbRightDragging then
            return
        end
        current.__mbRightDragging = nil
        current:StopMovingOrSizing()
        persistWindowPosition(current)
    end)

    frame:HookScript("OnDragStop", function(current)
        persistWindowPosition(current)
    end)
end

function HunterQuick:RestorePosition()
    if not self:EnsureWindow() then
        return
    end

    local frame = self.window and self.window.frame
    if not frame then
        return
    end

    local state = MultiBot.GetQuickFramePosition and MultiBot.GetQuickFramePosition(HUNTER_QUICK_FRAME_KEY) or nil
    state = state or WINDOW_DEFAULT_POINT

    frame:ClearAllPoints()
    frame:SetPoint(state.point or "CENTER", UIParent, state.relPoint or "CENTER", state.x or 0, state.y or 0)
end

function HunterQuick:ResolveUnitToken(name)
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for index = 1, GetNumRaidMembers() do
            local unit = "raid" .. index
            if UnitName(unit) == name then
                return unit, "raidpet" .. index
            end
        end
    end

    local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
    for index = 1, partyCount do
        local unit = "party" .. index
        if UnitName(unit) == name then
            return unit, "partypet" .. index
        end
    end

    if UnitName("player") == name then
        return "player", "pet"
    end

    return nil, nil
end

function HunterQuick:CollectHunterBots()
    local names = {}

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for index = 1, GetNumRaidMembers() do
            local unit = "raid" .. index
            local name = UnitName(unit)
            local _, classToken = UnitClass(unit)
            if name and classToken == "HUNTER" and (not MultiBot.IsBot or MultiBot.IsBot(name)) then
                table.insert(names, name)
            end
        end
    else
        local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
        for index = 1, partyCount do
            local unit = "party" .. index
            local name = UnitName(unit)
            local _, classToken = UnitClass(unit)
            if name and classToken == "HUNTER" and (not MultiBot.IsBot or MultiBot.IsBot(name)) then
                table.insert(names, name)
            end
        end
    end

    table.sort(names)
    return names
end

function HunterQuick:GetSavedStance(name)
    if MultiBot.GetHunterPetStance then
        return MultiBot.GetHunterPetStance(name)
    end
    return nil
end

function HunterQuick:SetSavedStance(name, stance)
    if MultiBot.SetHunterPetStance then
        MultiBot.SetHunterPetStance(name, stance)
    end
end

function HunterQuick:IsManuallyVisible()
    if self.manualVisible == nil then
        if MultiBot.GetQuickFrameVisibleConfig then
            self.manualVisible = MultiBot.GetQuickFrameVisibleConfig(HUNTER_QUICK_FRAME_KEY)
        else
            self.manualVisible = true
        end
    end

    return self.manualVisible ~= false
end

function HunterQuick:SetManualVisibility(visible)
    self.manualVisible = visible ~= false
    if MultiBot.SetQuickFrameVisibleConfig then
        MultiBot.SetQuickFrameVisibleConfig(HUNTER_QUICK_FRAME_KEY, self.manualVisible)
    end
end

function HunterQuick:ApplyCollapsedState()
    if not self.window or not self.window.frame then
        return
    end

    if self.canvas then
        self.canvas:Hide()
    end

    for _, row in pairs(self.entries or {}) do
        row:Hide()
    end

    self.window:SetWidth(HANDLE_WIDTH)
    self.window:SetHeight(HANDLE_HEIGHT)
    self:UpdateToggleHandleLayout(true)

    self.window:Show()
    self:RestorePosition()
end

function HunterQuick:GetVisibleContentWidth()
    local width = BUTTON_SIZE
    local spacing = self:GetRowSpacing()
    local index = 0

    for _ in pairs(self.entries or {}) do
        index = index + 1
    end

    if index == 0 then
        return width
    end

    local orderedNames = self:CollectHunterBots()
    for orderedIndex, name in ipairs(orderedNames) do
        local row = self.entries[name]
        local rowWidth = BUTTON_SIZE
        if row then
            if row.modesStrip and row.modesStrip:IsShown() and row.modesStrip.GetWidth then
                rowWidth = math.max(rowWidth, BUTTON_SIZE + BUTTON_GAP + row.modesStrip:GetWidth())
            end
            if row.utilsStrip and row.utilsStrip:IsShown() and row.utilsStrip.GetWidth then
                rowWidth = math.max(rowWidth, BUTTON_SIZE + BUTTON_GAP + row.utilsStrip:GetWidth())
            end
        end
        width = math.max(width, ((orderedIndex - 1) * spacing) + rowWidth)
    end

    return width
end

function HunterQuick:UpdateToggleHandleLayout(collapsed)
    local handle = createCollapseHandle(self)
    if not handle or not self.window or not self.window.frame then
        return
    end

    handle:ClearAllPoints()
    if collapsed then
        handle:SetPoint("TOPLEFT", self.window.frame, "TOPLEFT", 0, 0)
        handle:SetPoint("BOTTOMRIGHT", self.window.frame, "BOTTOMRIGHT", 0, 0)
    else
        local visibleWidth = self:GetVisibleContentWidth()
        handle:SetPoint("TOPLEFT", self.window.frame, "TOPLEFT", visibleWidth + BUTTON_GAP, 0)
        handle:SetSize(HANDLE_WIDTH, HANDLE_HEIGHT)
    end

    handle:Show()
    handle:SetAlpha(HANDLE_ALPHA)
end

function HunterQuick:ApplyExpandedState(count)
    if not self.window or not self.window.frame then
        return
    end

    self:UpdateWindowGeometry(count)

    if self.canvas then
        self.canvas:Show()
    end

    self:UpdateToggleHandleLayout(false)

    self.window:Show()
    self:RestorePosition()
    self:UpdateAllPetPresence()
end

function HunterQuick:ToggleManualVisibility()
    local currentlyVisible = self:IsManuallyVisible()
    self:SetManualVisibility(not currentlyVisible)
    self:Rebuild()
end

function HunterQuick:ApplyStanceVisual(row, stance)
    row.stanceButtons = row.stanceButtons or {}
    for _, button in pairs(row.stanceButtons) do
        if button and button.SetButtonSelected then
            button:SetButtonSelected(false)
        end
    end

    if stance and row.stanceButtons[stance] and row.stanceButtons[stance].SetButtonSelected then
        row.stanceButtons[stance]:SetButtonSelected(true)
    end

    row.activeStance = stance
end

function HunterQuick:UpdatePetPresence(row)
    if not row then
        return
    end

    local unit, petUnit = self:ResolveUnitToken(row.owner)
    row.unit = unit
    row.petUnit = petUnit

    local hasPet = petUnit and UnitExists(petUnit) and not UnitIsDead(petUnit)
    row.hasPet = hasPet and true or false

    if row.modesButton and row.modesButton.SetButtonDisabled then
        row.modesButton:SetButtonDisabled(not row.hasPet)
    end

    if not row.hasPet and row.modesStrip and row.modesStrip:IsShown() then
        row.modesStrip:Hide()
    end
end

function HunterQuick:UpdateAllPetPresence()
    for _, row in pairs(self.entries or {}) do
        self:UpdatePetPresence(row)
    end
end

function HunterQuick:CloseAllExcept(keepRow)
    for _, row in pairs(self.entries or {}) do
        if row ~= keepRow then
            if row.menuFrame then row.menuFrame:Hide() end
            if row.modesButton then row.modesButton:Hide() end
            if row.utilsButton then row.utilsButton:Hide() end
            if row.modesStrip then row.modesStrip:Hide() end
            if row.utilsStrip then row.utilsStrip:Hide() end
            row.expanded = false
        end
    end
end

function HunterQuick:ToggleRow(row)
    if not row then
        return
    end

    self:CloseAllExcept(row)

    row.expanded = not row.expanded
    if row.expanded then
        row.menuFrame:Show()
        row.modesButton:Show()
        row.utilsButton:Show()
    else
        row.menuFrame:Hide()
        row.modesButton:Hide()
        row.utilsButton:Hide()
        row.modesStrip:Hide()
        row.utilsStrip:Hide()
    end

    if self:IsManuallyVisible() then
        self:UpdateToggleHandleLayout(false)
    end
end

function HunterQuick:ToggleStrip(row, stripKey)
    if not row then
        return
    end

    self:CloseAllExcept(row)
    row.expanded = true
    row.menuFrame:Show()
    row.modesButton:Show()
    row.utilsButton:Show()

    local showModes = stripKey == "modes"
    if row.modesStrip then
        if showModes and row.hasPet then row.modesStrip:Show() else row.modesStrip:Hide() end
    end
    if row.utilsStrip then
        if showModes then row.utilsStrip:Hide() else row.utilsStrip:Show() end
    end

    if showModes then
        self:ApplyStanceVisual(row, row.activeStance)
    end

    if self:IsManuallyVisible() then
        self:UpdateToggleHandleLayout(false)
    end
end

function HunterQuick:ShowPrompt(formatString, targetName, title)
    if type(ShowPrompt) ~= "function" then
        return
    end

    ShowPrompt(title or MultiBot.L("info.hunterpeteditentervalue"), function(text)
        if text and text ~= "" and targetName then
            SendChatMessage(string.format(formatString, text), "WHISPER", nil, targetName)
        end
    end, MultiBot.L("info.hunterpetentersomething"))
end

function HunterQuick:EnsureSearchFrame()
    if self.SEARCH_FRAME then
        return self.SEARCH_FRAME
    end

    local host = getPopupHost(MultiBot.L("info.hunterpetcreaturelist"), 360, 360, "AceGUI-3.0 is required for MBHunterPetSearch", "hunter_pet_search")
    assert(host, "AceGUI-3.0 is required for MBHunterPetSearch")

    self.SEARCH_FRAME = host

    local searchBar = CreateFrame("Frame", nil, host)
    searchBar:SetPoint("TOP", host, "TOP", 0, -18)
    searchBar:SetSize(248, 26)
    addPopupBackdrop(searchBar, 0.92)
    host.SearchBar = searchBar

    local editBox = CreateFrame("EditBox", nil, searchBar)
    editBox:SetAutoFocus(true)
    editBox:SetPoint("TOPLEFT", searchBar, "TOPLEFT", 6, -5)
    editBox:SetPoint("BOTTOMRIGHT", searchBar, "BOTTOMRIGHT", -6, 5)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextInsets(4, 4, 0, 0)
    editBox:SetScript("OnEscapePressed", function(editWidget)
        editWidget:ClearFocus()
    end)
    host.EditBox = editBox

    local previewWidth, previewHeight = 180, 260
    local previewScale = 0.6
    local previewFacing = -math.pi / 12
    local currentEntry = nil

    local function getPreviewFrame()
        if MBHunterPetPreview then
            return MBHunterPetPreview
        end

        local preview = CreateFrame("PlayerModel", "MBHunterPetPreview", UIParent)
        preview:SetSize(previewWidth, previewHeight)
        preview:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        preview:SetBackdropColor(0, 0, 0, 0.85)
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            preview:SetFrameStrata(strataLevel)
        end
        preview:SetMovable(true)
        preview:EnableMouse(true)
        preview:RegisterForDrag("LeftButton")
        preview:SetScript("OnDragStart", preview.StartMoving)
        preview:SetScript("OnDragStop", preview.StopMovingOrSizing)
        CreateFrame("Button", nil, preview, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -5, -5)
        preview:ClearAllPoints()
        preview:SetPoint("LEFT", UIParent, "CENTER", 180, 20)
        return preview
    end

    local function hidePreviewFrame()
        if MBHunterPetPreview and MBHunterPetPreview:IsShown() then
            MBHunterPetPreview:Hide()
        end
        currentEntry = nil
    end

    if host.window and host.window.frame and host.window.frame.HookScript then
        host.window.frame:HookScript("OnHide", hidePreviewFrame)
    end

    local function loadCreaturePreview(entryId, displayId)
        local preview = getPreviewFrame()
        if preview:IsShown() and currentEntry == entryId then
            preview:Hide()
            currentEntry = nil
            return
        end

        currentEntry = entryId
        preview:SetUnit("none")
        preview:ClearModel()
        preview:Show()
        MultiBot.TimerAfter(0, function()
            if not preview:IsShown() or currentEntry ~= entryId then
                return
            end

            preview:SetModelScale(previewScale)
            preview:SetFacing(previewFacing)

            local displayNumber = tonumber(displayId)
            if displayNumber and displayNumber > 0 and type(preview.SetDisplayInfo) == "function" then
                preview:SetDisplayInfo(displayNumber)
            else
                preview:SetCreature(entryId)
            end
        end)
    end

    local rowHeight = 18
    local visibleRows = 17
    local offset = 0
    local results = {}
    local familyLocalization = MultiBot.PET_FAMILY_L10N and MultiBot.PET_FAMILY_L10N[GetLocale()] or nil

    local function getFamilyLabel(familyId)
        if familyLocalization and familyLocalization[familyId] then
            return familyLocalization[familyId]
        end

        return MultiBot.PET_FAMILY[familyId] or "?"
    end

    local resultsPanel = CreateFrame("Frame", nil, host)
    resultsPanel:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -56)
    resultsPanel:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    addPopupBackdrop(resultsPanel, 0.95)

    local scrollFrame = CreateFrame("ScrollFrame", "MBHunterPetScroll", resultsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", resultsPanel, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", resultsPanel, "BOTTOMRIGHT", -32, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    host.Rows = {}
    for index = 1, visibleRows do
        local row = CreateFrame("Button", nil, content)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:SetHeight(rowHeight)
        row:SetWidth(content:GetWidth())
        row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)

        row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        row.text:SetPoint("LEFT", 2, 0)

        local previewButton = CreateFrame("Button", nil, row)
        previewButton:SetSize(16, 16)
        previewButton:SetPoint("RIGHT", -32, 0)
        previewButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        previewButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
        previewButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        row.previewButton = previewButton

        host.Rows[index] = row
    end

    local function localeField()
        local locale = GetLocale():lower()
        if locale == "frfr" then return "name_fr" end
        if locale == "dede" then return "name_de" end
        if locale == "eses" then return "name_es" end
        if locale == "esmx" then return "name_esmx" end
        if locale == "kokr" then return "name_ko" end
        if locale == "zhtw" then return "name_zhtw" end
        if locale == "zhcn" then return "name_zhcn" end
        if locale == "ruru" then return "name_ru" end
        return "name_en"
    end

    function host.RefreshRows(hostFrame)
        local listWidth = 320
        for index = 1, visibleRows do
            local dataIndex = index + offset
            local data = results[dataIndex]
            local row = hostFrame.Rows[index]

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -((index - 1 + offset) * rowHeight))
            row:SetWidth(listWidth)

            if data then
                row.text:SetText(string.format("|cffffd200%-24s|r |cff888888[%s]|r", data.name, getFamilyLabel(data.family)))
                row:SetScript("OnClick", function()
                    if host.TargetName then
                        SendChatMessage(("tame id %d"):format(data.id), "WHISPER", nil, host.TargetName)
                    end
                    host:Hide()
                end)
                row.previewButton:SetScript("OnClick", function()
                    loadCreaturePreview(data.id, data.display)
                end)
                row:Show()
            else
                row:Hide()
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function(_, delta)
        local newOffset = math.floor(scrollFrame:GetVerticalScroll() / rowHeight + 0.5)
        if newOffset ~= offset then
            offset = newOffset
            host:RefreshRows()
        end
    end)

    function host.Refresh(hostFrame)
        wipe(results)
        local filter = (editBox:GetText() or ""):lower()
        local field = localeField()

        for creatureId, info in pairs(MultiBot.PET_DATA) do
            local localizedName = info[field] or info.name_en
            if localizedName:lower():find(filter, 1, true) then
                results[#results + 1] = { id = creatureId, name = localizedName, family = info.family, display = info.display }
            end
        end

        table.sort(results, function(left, right)
            return left.name < right.name
        end)

        content:SetHeight(#results * rowHeight)
        offset = 0
        scrollFrame:SetVerticalScroll(0)
        hostFrame:RefreshRows()
    end

    editBox:SetScript("OnTextChanged", function()
        host:Refresh()
    end)

    return host
end

function HunterQuick:ShowFamilyFrame(targetName)
    local frame = self.FAMILY_FRAME
    if frame then
        frame.TargetName = targetName
        frame:Show()
        return
    end

    frame = getPopupHost(MultiBot.L("info.hunterpetrandomfamily"), 260, 340, "AceGUI-3.0 is required for MBHunterPetFamily", "hunter_pet_family")
    assert(frame, "AceGUI-3.0 is required for MBHunterPetFamily")
    self.FAMILY_FRAME = frame
    frame.TargetName = targetName

    local listPanel = CreateFrame("Frame", nil, frame)
    listPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    listPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    addPopupBackdrop(listPanel, 0.95)

    local scrollFrame = CreateFrame("ScrollFrame", "MBHunterFamilyScroll", listPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listPanel, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -32, 8)

    local listWidth = 320
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(listWidth, 1)
    scrollFrame:SetScrollChild(content)
    frame.Content = content
    frame.Rows = {}

    local rowHeight = 18
    local locale = GetLocale()
    local localization = MultiBot.PET_FAMILY_L10N and MultiBot.PET_FAMILY_L10N[locale]
    local families = {}

    for familyId, englishName in pairs(MultiBot.PET_FAMILY) do
        local localized = (localization and localization[familyId]) or englishName
        table.insert(families, { id = familyId, eng = englishName, txt = localized })
    end

    table.sort(families, function(left, right)
        return left.txt < right.txt
    end)

    for index, data in ipairs(families) do
        local row = CreateFrame("Button", nil, content)
        row:EnableMouse(true)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
        row:SetWidth(content:GetWidth())
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        row.text:SetPoint("LEFT")
        row.text:SetText("|cffffd200" .. data.txt .. "|r")
        row:SetScript("OnClick", function()
            local currentTargetName = frame.TargetName
            if currentTargetName then
                SendChatMessage(("tame family %s"):format(data.eng), "WHISPER", nil, currentTargetName)
            end
            frame:Hide()
        end)
    end

    frame:Show()
end

function HunterQuick:BuildUtilityAction(row, definition, index)
    local button = createIconButton(row.utilsStrip, string.format("MultiBotHunterQuickUtil_%s_%d", sanitizeName(row.owner), index), definition.icon, MultiBot.L(definition.tip), BUTTON_SIZE)
    button:SetPoint("TOPLEFT", (index - 1) * (BUTTON_SIZE + BUTTON_GAP), 0)

    button:SetScript("OnClick", function()
        if definition.action == "prompt_rename" then
            self:ShowPrompt(definition.command, row.owner, MultiBot.L("info.hunterpetnewname"))
            row.utilsStrip:Hide()
        elseif definition.action == "prompt_id" then
            self:ShowPrompt(definition.command, row.owner, MultiBot.L("info.hunterpetid"))
            row.utilsStrip:Hide()
        elseif definition.action == "family" then
            self:ShowFamilyFrame(row.owner)
            row.utilsStrip:Hide()
        elseif definition.action == "direct" then
            SendChatMessage(definition.command, "WHISPER", nil, row.owner)
            row.utilsStrip:Hide()
        else
            local searchFrame = self:EnsureSearchFrame()
            searchFrame.TargetName = row.owner
            searchFrame:Show()
            searchFrame.EditBox:SetText("")
            searchFrame.EditBox:SetFocus()
            searchFrame:Refresh()
            row.utilsStrip:Hide()
        end
    end)

    return button
end

function HunterQuick:BuildStanceAction(row, definition, index)
    local button = createIconButton(row.modesStrip, string.format("MultiBotHunterQuickMode_%s_%d", sanitizeName(row.owner), index), definition.icon, MultiBot.L(definition.tip), BUTTON_SIZE)
    button:SetPoint("TOPLEFT", (index - 1) * (BUTTON_SIZE + BUTTON_GAP), 0)

    if definition.persistent then
        row.stanceButtons[definition.key] = button
    end

    button:SetScript("OnClick", function()
        if button.__mbDisabled then
            return
        end

        SendChatMessage("pet " .. definition.key, "WHISPER", nil, row.owner)
        if definition.persistent then
            self:ApplyStanceVisual(row, definition.key)
            self:SetSavedStance(row.owner, definition.key)
        end
    end)

    return button
end

function HunterQuick:BuildRow(ownerName)
    if not self:EnsureWindow() then
        return nil
    end

    local root = CreateFrame("Frame", string.format("MultiBotHunterQuickRow_%s", sanitizeName(ownerName)), self.canvas)
    root:SetSize(ROW_WIDTH, ROW_HEIGHT)
    root.owner = ownerName
    root.expanded = false
    root.stanceButtons = {}

    local tooltipText = (MultiBot.L("tips.hunter.ownbutton") or "Hunter: %s"):format(ownerName)
    local mainButton = createIconButton(root, string.format("MultiBotHunterQuickMain_%s", sanitizeName(ownerName)), "Interface\\AddOns\\MultiBot\\Icons\\class_hunter.blp", tooltipText, BUTTON_SIZE)
    mainButton:SetPoint("TOPLEFT", 0, 0)
    mainButton:RegisterForDrag("RightButton")
    mainButton:SetScript("OnDragStart", function()
        if self.window and self.window.frame then
            self.window.frame:StartMoving()
            self.window.frame.__mbRightDragging = true
        end
    end)
    mainButton:SetScript("OnDragStop", function()
        local frame = self.window and self.window.frame
        if not frame then
            return
        end
        frame.__mbRightDragging = nil
        frame:StopMovingOrSizing()
        persistWindowPosition(frame)
    end)
    mainButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            self:ToggleRow(root)
        end
    end)
    root.mainButton = mainButton

    local menuFrame = CreateFrame("Frame", nil, root)
    menuFrame:SetPoint("TOPLEFT", mainButton, "BOTTOMLEFT", 0, -BUTTON_GAP)
    menuFrame:SetSize(BUTTON_SIZE, (BUTTON_SIZE * 2) + BUTTON_GAP)
    menuFrame:Hide()
    root.menuFrame = menuFrame

    local modesButton = createIconButton(menuFrame, string.format("MultiBotHunterQuickModes_%s", sanitizeName(ownerName)), "ability_hunter_beasttaming", MultiBot.L("tips.hunter.pet.stances"), BUTTON_SIZE)
    modesButton:SetPoint("TOPLEFT", 0, 0)
    modesButton:Hide()
    modesButton:SetScript("OnClick", function()
        if not root.hasPet then
            return
        end
        self:ToggleStrip(root, "modes")
    end)
    root.modesButton = modesButton

    local utilsButton = createIconButton(menuFrame, string.format("MultiBotHunterQuickUtils_%s", sanitizeName(ownerName)), "trade_engineering", MultiBot.L("tips.hunter.pet.master"), BUTTON_SIZE)
    utilsButton:SetPoint("TOPLEFT", 0, -(BUTTON_SIZE + BUTTON_GAP))
    utilsButton:Hide()
    utilsButton:SetScript("OnClick", function()
        self:ToggleStrip(root, "utils")
    end)
    root.utilsButton = utilsButton

    local modesStrip = CreateFrame("Frame", nil, root)
    modesStrip:SetPoint("TOPLEFT", modesButton, "TOPRIGHT", BUTTON_GAP, 0)
    modesStrip:SetSize((BUTTON_SIZE * #PET_STANCE_DEFINITIONS) + (BUTTON_GAP * (#PET_STANCE_DEFINITIONS - 1)), BUTTON_SIZE)
    modesStrip:Hide()
    root.modesStrip = modesStrip

    local utilsStrip = CreateFrame("Frame", nil, root)
    utilsStrip:SetPoint("TOPLEFT", utilsButton, "TOPRIGHT", BUTTON_GAP, 0)
    utilsStrip:SetSize((BUTTON_SIZE * #PET_UTILITY_DEFINITIONS) + (BUTTON_GAP * (#PET_UTILITY_DEFINITIONS - 1)), BUTTON_SIZE)
    utilsStrip:Hide()
    root.utilsStrip = utilsStrip

    for index, definition in ipairs(PET_STANCE_DEFINITIONS) do
        self:BuildStanceAction(root, definition, index)
    end
    for index, definition in ipairs(PET_UTILITY_DEFINITIONS) do
        self:BuildUtilityAction(root, definition, index)
    end

    self:ApplyStanceVisual(root, self:GetSavedStance(ownerName))
    self:UpdatePetPresence(root)

    self.entries[ownerName] = root
    return root
end

function HunterQuick:UpdateWindowGeometry(count)
    if not self:EnsureWindow() then
        return
    end

    count = math.max(tonumber(count) or 0, 1)
    local width = (WINDOW_PADDING_X * 2) + ROW_WIDTH + ((count - 1) * self:GetRowSpacing())

    self.window:SetWidth(width)
    self.window:SetHeight(WINDOW_HEIGHT)
    self.canvas:SetWidth(width - (WINDOW_PADDING_X * 2))
    self.canvas:SetHeight(WINDOW_HEIGHT - (WINDOW_PADDING_Y * 2))
    updateWindowTitle(self, count)
end

function HunterQuick:EnsureWindow()
    if self.window and self.window.frame then
        return self.window
    end

    local aceGUI = getAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Hunter Quick", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(WINDOW_TITLE)
    window:SetLayout("Manual")
    window:SetWidth((WINDOW_PADDING_X * 2) + ROW_WIDTH)
    window:SetHeight(WINDOW_HEIGHT)
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end
    window.frame:SetClampedToScreen(true)
    window.frame:SetPoint(WINDOW_DEFAULT_POINT.point, UIParent, WINDOW_DEFAULT_POINT.relPoint, WINDOW_DEFAULT_POINT.x, WINDOW_DEFAULT_POINT.y)
    window:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)
    window:Hide()

    stripWindowChrome(window)

    if window.content then
        window.content:ClearAllPoints()
        window.content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 0, 0)
        window.content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", 0, 0)
    end

    local canvas = CreateFrame("Frame", nil, window.content)
    canvas:SetPoint("TOPLEFT", window.content, "TOPLEFT", WINDOW_PADDING_X, -WINDOW_PADDING_Y)
    canvas:SetPoint("BOTTOMRIGHT", window.content, "BOTTOMRIGHT", -WINDOW_PADDING_X, WINDOW_PADDING_Y)

    self.window = window
    self.frame = window.frame
    self.canvas = canvas
    self.__aceInitialized = true

    createCollapseHandle(self)
    bindWindowDrag(self)
    self:RestorePosition()

    return window
end

function HunterQuick:Rebuild()
    if not self:EnsureWindow() then
        return
    end

    local desiredNames = self:CollectHunterBots()
    local desiredLookup = {}
    for _, name in ipairs(desiredNames) do
        desiredLookup[name] = true
    end

    for name, row in pairs(self.entries) do
        if not desiredLookup[name] then
            row:Hide()
            row:SetParent(nil)
            self.entries[name] = nil
        end
    end

    for _, name in ipairs(desiredNames) do
        if not self.entries[name] then
            self:BuildRow(name)
        end
    end

    local manuallyVisible = self:IsManuallyVisible()
    for index, name in ipairs(desiredNames) do
        local row = self.entries[name]
        if row then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", (index - 1) * self:GetRowSpacing(), 0)
            row:SetFrameLevel((self.window.frame:GetFrameLevel() or 0) + 2)
            if manuallyVisible then
                row:Show()
            else
                row:Hide()
            end
        end
    end

    if #desiredNames > 0 then
        if manuallyVisible then
            self:ApplyExpandedState(#desiredNames)
        else
            self:ApplyCollapsedState()
        end
    elseif self.window then
        updateWindowTitle(self, 0)
        self.window:Hide()
    end
end

function MultiBot.InitHunterQuick()
    if HunterQuick.__moduleReady then
        return HunterQuick
    end

    HunterQuick.__moduleReady = true
    HunterQuick:EnsureWindow()

    MultiBot.TimerAfter(0.5, function()
        if MultiBot and MultiBot.HunterQuick and MultiBot.HunterQuick.Rebuild then
            MultiBot.HunterQuick:Rebuild()
        end
    end)

    return HunterQuick
end

MultiBot.InitHunterQuick()

if MultiBot.HunterQuick and MultiBot.HunterQuick.RestorePosition then
    MultiBot.HunterQuick:RestorePosition()
end