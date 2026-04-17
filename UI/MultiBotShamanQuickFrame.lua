if not MultiBot then return end

local SHAMAN_QUICK_FRAME_KEY = "ShamanQuick"
local BUTTON_SIZE = 25
local BUTTON_GAP = 4
local ROW_WIDTH = 252
local ROW_HEIGHT = (BUTTON_SIZE * 5) + (BUTTON_GAP * 4)
local SHAMAN_QUICK_ROW_SPACING_DEFAULT = 26
local WINDOW_HEIGHT = ROW_HEIGHT
local WINDOW_PADDING_X = 0
local WINDOW_PADDING_Y = 0
local WINDOW_TITLE = "Quick Shaman"
local WINDOW_DEFAULT_POINT = { point = "TOP", relPoint = "TOP", x = -3.360398722124494, y = -28.94176284319217 }
local ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
local HANDLE_WIDTH = 12
local HANDLE_HEIGHT = 18
local HANDLE_ALPHA = 0.45
local HANDLE_HOVER_ALPHA = 0.85
--local HANDLE_ICON = "Interface\\AddOns\\MultiBot\\Icons\\class_shaman.blp"

local ELEMENT_DEFINITIONS = {
    {
        key = "earth",
        defaultIcon = "spell_nature_earthbindtotem",
        tip = "tips.shaman.ctotem.earthtot",
        spells = {
            { key = "strength_of_earth", icon = "spell_nature_earthbindtotem", tip = "tips.shaman.ctotem.stoe", spell = "strength of earth" },
            { key = "stoneskin",        icon = "spell_nature_stoneskintotem", tip = "tips.shaman.ctotem.stoskin", spell = "stoneskin" },
            { key = "tremor",           icon = "spell_nature_tremortotem", tip = "tips.shaman.ctotem.tremor", spell = "tremor" },
            { key = "earthbind",        icon = "spell_nature_strengthofearthtotem02", tip = "tips.shaman.ctotem.eabind", spell = "earthbind" },
        },
    },
    {
        key = "fire",
        defaultIcon = "spell_fire_searingtotem",
        tip = "tips.shaman.ctotem.firetot",
        spells = {
            { key = "searing",          icon = "spell_fire_searingtotem", tip = "tips.shaman.ctotem.searing", spell = "searing" },
            { key = "magma",            icon = "spell_fire_moltenblood", tip = "tips.shaman.ctotem.magma", spell = "magma" },
            { key = "flametongue",      icon = "spell_nature_guardianward", tip = "tips.shaman.ctotem.fltong", spell = "flametongue" },
            { key = "wrath",            icon = "spell_fire_totemofwrath", tip = "tips.shaman.ctotem.towrath", spell = "wrath" },
            { key = "frost_resistance", icon = "spell_frost_frostward", tip = "tips.shaman.ctotem.frostres", spell = "frost resistance" },
        },
    },
    {
        key = "water",
        defaultIcon = "spell_nature_manaregentotem",
        tip = "tips.shaman.ctotem.watertot",
        spells = {
            { key = "healing_stream",  icon = "spell_nature_healingwavelesser", tip = "tips.shaman.ctotem.healstream", spell = "healing stream" },
            { key = "mana_spring",     icon = "spell_nature_manaregentotem", tip = "tips.shaman.ctotem.manasprin", spell = "mana spring" },
            { key = "cleansing",       icon = "spell_nature_nullifydisease", tip = "tips.shaman.ctotem.cleansing", spell = "cleansing" },
            { key = "fire_resistance", icon = "spell_fire_firearmor", tip = "tips.shaman.ctotem.fireres", spell = "fire resistance" },
        },
    },
    {
        key = "air",
        defaultIcon = "spell_nature_windfury",
        tip = "tips.shaman.ctotem.airtot",
        spells = {
            { key = "wrath_of_air",     icon = "spell_nature_slowingtotem", tip = "tips.shaman.ctotem.wrhatair", spell = "wrath of air" },
            { key = "windfury",         icon = "spell_nature_windfury", tip = "tips.shaman.ctotem.windfury", spell = "windfury" },
            { key = "nature_resistance",icon = "spell_nature_natureresistancetotem", tip = "tips.shaman.ctotem.natres", spell = "nature resistance" },
            { key = "grounding",        icon = "spell_nature_groundingtotem", tip = "tips.shaman.ctotem.grounding", spell = "grounding" },
        },
    },
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

local ShamanQuick = MultiBot.ShamanQuick or {}
MultiBot.ShamanQuick = ShamanQuick
ShamanQuick.entries = ShamanQuick.entries or {}

local function normalizeRowSpacing(value)
    local spacing = tonumber(value) or SHAMAN_QUICK_ROW_SPACING_DEFAULT
    if spacing < BUTTON_SIZE then
        spacing = BUTTON_SIZE
    end
    return spacing
end

function ShamanQuick:GetRowSpacing()
    self.rowSpacing = normalizeRowSpacing(self.rowSpacing)
    return self.rowSpacing
end

function ShamanQuick:SetRowSpacing(value)
    local spacing = normalizeRowSpacing(value)
    if self.rowSpacing == spacing then
        return spacing
    end

    self.rowSpacing = spacing
    if self.RefreshFromGroup then
        self:RefreshFromGroup()
    end

    return spacing
end

MultiBot.GetShamanQuickSpacing = function()
    return ShamanQuick:GetRowSpacing()
end

MultiBot.SetShamanQuickSpacing = function(value)
    return ShamanQuick:SetRowSpacing(value)
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
        setTooltip(self, "Left click : Show / Hide Right Click :  Move Quick Shaman")
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
    MultiBot.SetQuickFramePosition(SHAMAN_QUICK_FRAME_KEY, point, relPoint, x, y)
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

function ShamanQuick:RestorePosition()
    if not self:EnsureWindow() then
        return
    end

    local frame = self.window and self.window.frame
    if not frame then
        return
    end

    local state = MultiBot.GetQuickFramePosition and MultiBot.GetQuickFramePosition(SHAMAN_QUICK_FRAME_KEY) or nil
    state = state or WINDOW_DEFAULT_POINT

    frame:ClearAllPoints()
    frame:SetPoint(state.point or "CENTER", UIParent, state.relPoint or "CENTER", state.x or 0, state.y or 0)
end

function ShamanQuick:CollectShamanBots()
    local names = {}

    local function considerUnit(unit)
        if not UnitExists(unit) then
            return
        end

        local name = GetUnitName(unit, true)
        local _, classToken = UnitClass(unit)
        if classToken == "SHAMAN" and name and (not MultiBot.IsBot or MultiBot.IsBot(name)) then
            table.insert(names, name)
        end
    end

    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, count do
            considerUnit("raid" .. index)
        end
    else
        considerUnit("player")
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, count do
            considerUnit("party" .. index)
        end
    end

    table.sort(names)
    return names
end

function ShamanQuick:IsManuallyVisible()
    if self.manualVisible == nil then
        if MultiBot.GetQuickFrameVisibleConfig then
            self.manualVisible = MultiBot.GetQuickFrameVisibleConfig(SHAMAN_QUICK_FRAME_KEY)
        else
            self.manualVisible = true
        end
    end

    return self.manualVisible ~= false
end

function ShamanQuick:SetManualVisibility(visible)
    self.manualVisible = visible ~= false
    if MultiBot.SetQuickFrameVisibleConfig then
        MultiBot.SetQuickFrameVisibleConfig(SHAMAN_QUICK_FRAME_KEY, self.manualVisible)
    end
end

function ShamanQuick:ApplyCollapsedState()
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

function ShamanQuick:GetVisibleContentWidth()
    local width = BUTTON_SIZE
    local spacing = self:GetRowSpacing()
    local orderedNames = self:CollectShamanBots()

    if #orderedNames == 0 then
        return width
    end

    for orderedIndex, name in ipairs(orderedNames) do
        local row = self.entries[name]
        local rowWidth = BUTTON_SIZE
        if row and row.groupFrames then
            for _, groupFrame in pairs(row.groupFrames) do
                if groupFrame and groupFrame.IsShown and groupFrame:IsShown() and groupFrame.GetWidth then
                    rowWidth = math.max(rowWidth, BUTTON_SIZE + BUTTON_GAP + groupFrame:GetWidth())
                end
            end
        end
        width = math.max(width, ((orderedIndex - 1) * spacing) + rowWidth)
    end

    return width
end

function ShamanQuick:UpdateToggleHandleLayout(collapsed)
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

function ShamanQuick:ApplyExpandedState(count)
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
end

function ShamanQuick:ToggleManualVisibility()
    local currentlyVisible = self:IsManuallyVisible()
    self:SetManualVisibility(not currentlyVisible)
    self:RefreshFromGroup()
end

function ShamanQuick:CloseAllExcept(keepRow)
    for _, row in pairs(self.entries or {}) do
        if row ~= keepRow then
            if row.menuFrame then row.menuFrame:Hide() end
            for _, groupFrame in pairs(row.groupFrames or {}) do
                groupFrame:Hide()
            end
            row.expanded = false
        end
    end
end

function ShamanQuick:ToggleRow(row)
    if not row then
        return
    end

    local shouldExpand = not row.expanded
    self:CloseAllExcept(row)

    row.expanded = shouldExpand
    if row.expanded then
        row.menuFrame:Show()
    else
        row.menuFrame:Hide()
        for _, groupFrame in pairs(row.groupFrames or {}) do
            groupFrame:Hide()
        end
    end

    if self:IsManuallyVisible() then
        self:UpdateToggleHandleLayout(false)
    end
end

function ShamanQuick:ToggleElementGroup(row, elementKey)
    if not row then
        return
    end

    local targetGroup = row.groupFrames and row.groupFrames[elementKey]
    if not targetGroup then
        return
    end

    self:CloseAllExcept(row)
    row.expanded = true
    row.menuFrame:Show()

    local shouldShow = not targetGroup:IsShown()
    for key, groupFrame in pairs(row.groupFrames or {}) do
        if key ~= elementKey then
            groupFrame:Hide()
        end
    end

    if shouldShow then
        targetGroup:Show()
    else
        targetGroup:Hide()
    end

    if self:IsManuallyVisible() then
        self:UpdateToggleHandleLayout(false)
    end
end

function ShamanQuick:SetElementIcon(row, elementKey, iconPath)
    local elementButton = row.elementButtons and row.elementButtons[elementKey]
    if elementButton and elementButton.SetIcon then
        elementButton:SetIcon(iconPath)
    end
end

function ShamanQuick:SetSelectedTotemButton(row, elementKey, selectedButton)
    row.selectedButtons = row.selectedButtons or {}
    local previous = row.selectedButtons[elementKey]
    if previous and previous ~= selectedButton and previous.SetButtonSelected then
        previous:SetButtonSelected(false)
    end

    row.selectedButtons[elementKey] = selectedButton
    if selectedButton and selectedButton.SetButtonSelected then
        selectedButton:SetButtonSelected(true)
    end
end

function ShamanQuick:ClearTotemSelection(row, elementKey, options)
    options = options or {}
    row.selectedIcons = row.selectedIcons or {}
    row.selectedButtons = row.selectedButtons or {}

    local selectedButton = row.selectedButtons[elementKey]
    if selectedButton and selectedButton.SetButtonSelected then
        selectedButton:SetButtonSelected(false)
    end

    row.selectedButtons[elementKey] = nil
    row.selectedIcons[elementKey] = nil
    self:SetElementIcon(row, elementKey, row.defaultIcons[elementKey])

    if not options.skipPersist and MultiBot.ClearShamanTotemChoice then
        MultiBot.ClearShamanTotemChoice(row.owner, elementKey)
    end
end

function ShamanQuick:ApplyPersistedChoice(row, elementKey, iconPath)
    if not iconPath then
        return
    end

    row.selectedIcons = row.selectedIcons or {}
    row.selectedIcons[elementKey] = iconPath
    self:SetElementIcon(row, elementKey, iconPath)

    local buttons = row.gridButtons and row.gridButtons[elementKey] or nil
    if not buttons then
        return
    end

    for _, button in ipairs(buttons) do
        if button.__mbIcon == iconPath then
            self:SetSelectedTotemButton(row, elementKey, button)
            break
        end
    end
end

function ShamanQuick:SelectTotem(row, elementKey, button, definition)
    if not row or not elementKey or not button or not definition then
        return
    end

    row.selectedIcons = row.selectedIcons or {}
    row.selectedButtons = row.selectedButtons or {}

    local currentButton = row.selectedButtons[elementKey]
    local currentIcon = row.selectedIcons[elementKey]
    local isSameSelection = currentButton == button or currentIcon == button.__mbIcon

    if isSameSelection then
        MultiBot.ActionToTarget("co -" .. definition.spell .. ",?", row.owner)
        self:ClearTotemSelection(row, elementKey)
        return
    end

    if currentButton and currentButton ~= button and currentButton.__mbSpell then
        MultiBot.ActionToTarget("co -" .. currentButton.__mbSpell .. ",?", row.owner)
        if currentButton.SetButtonSelected then
            currentButton:SetButtonSelected(false)
        end
    end

    MultiBot.ActionToTarget("co +" .. definition.spell .. ",?", row.owner)

    row.selectedIcons[elementKey] = button.__mbIcon
    self:SetSelectedTotemButton(row, elementKey, button)
    self:SetElementIcon(row, elementKey, button.__mbIcon)

    if MultiBot.SetShamanTotemChoice then
        MultiBot.SetShamanTotemChoice(row.owner, elementKey, button.__mbIcon)
    end
end

function ShamanQuick:CreateTotemButton(row, elementDefinition, groupFrame, spellDefinition, index)
    local button = createIconButton(groupFrame, string.format("MultiBotShamanTotem_%s_%s_%d", sanitizeName(row.owner), elementDefinition.key, index), spellDefinition.icon, MultiBot.L(spellDefinition.tip), BUTTON_SIZE)
    button:SetPoint("TOPLEFT", (index - 1) * (BUTTON_SIZE + BUTTON_GAP), 0)
    button.__mbIcon = spellDefinition.icon
    button.__mbSpell = spellDefinition.spell
    button:SetScript("OnClick", function()
        self:SelectTotem(row, elementDefinition.key, button, spellDefinition)
    end)
    return button
end

function ShamanQuick:CreateElementButton(row, elementDefinition, index)
    local button = createIconButton(row.menuFrame, string.format("MultiBotShamanElement_%s_%s", sanitizeName(row.owner), elementDefinition.key), elementDefinition.defaultIcon, MultiBot.L(elementDefinition.tip), BUTTON_SIZE)
    button:SetPoint("TOPLEFT", 0, -((index - 1) * (BUTTON_SIZE + BUTTON_GAP)))
    button:SetScript("OnClick", function()
        self:ToggleElementGroup(row, elementDefinition.key)
    end)
    row.elementButtons[elementDefinition.key] = button
    return button
end

function ShamanQuick:BuildRow(ownerName)
    if not self:EnsureWindow() then
        return nil
    end

    local row = CreateFrame("Frame", string.format("MultiBotShamanQuickRow_%s", sanitizeName(ownerName)), self.canvas)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    row.owner = ownerName
    row.expanded = false
    row.elementButtons = {}
    row.groupFrames = {}
    row.gridButtons = {}
    row.selectedButtons = {}
    row.selectedIcons = {}
    row.defaultIcons = {}

    local mainTooltip = (MultiBot.L("tips.shaman.ownbutton") or "Shaman: %s"):format(ownerName)
    local mainButton = createIconButton(row, string.format("MultiBotShamanQuickMain_%s", sanitizeName(ownerName)), "Interface\\AddOns\\MultiBot\\Icons\\class_shaman.blp", mainTooltip, BUTTON_SIZE)
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
            self:ToggleRow(row)
        end
    end)
    row.mainButton = mainButton

    local menuFrame = CreateFrame("Frame", nil, row)
    menuFrame:SetPoint("TOPLEFT", mainButton, "BOTTOMLEFT", 0, -BUTTON_GAP)
    menuFrame:SetSize(BUTTON_SIZE, (BUTTON_SIZE * #ELEMENT_DEFINITIONS) + (BUTTON_GAP * (#ELEMENT_DEFINITIONS - 1)))
    menuFrame:Hide()
    row.menuFrame = menuFrame

    for index, elementDefinition in ipairs(ELEMENT_DEFINITIONS) do
        row.defaultIcons[elementDefinition.key] = elementDefinition.defaultIcon
        self:CreateElementButton(row, elementDefinition, index)

        local groupFrame = CreateFrame("Frame", nil, row)
        groupFrame:SetPoint("TOPLEFT", row.elementButtons[elementDefinition.key], "TOPRIGHT", BUTTON_GAP, 0)
        groupFrame:SetSize((BUTTON_SIZE * #elementDefinition.spells) + (BUTTON_GAP * (#elementDefinition.spells - 1)), BUTTON_SIZE)
        groupFrame:Hide()
        row.groupFrames[elementDefinition.key] = groupFrame
        row.gridButtons[elementDefinition.key] = {}

        for spellIndex, spellDefinition in ipairs(elementDefinition.spells) do
            local button = self:CreateTotemButton(row, elementDefinition, groupFrame, spellDefinition, spellIndex)
            table.insert(row.gridButtons[elementDefinition.key], button)
        end
    end

    local persistedChoices = MultiBot.GetShamanTotemsForBot and MultiBot.GetShamanTotemsForBot(ownerName) or nil
    if persistedChoices then
        for elementKey, iconPath in pairs(persistedChoices) do
            self:ApplyPersistedChoice(row, elementKey, iconPath)
        end
    end

    self.entries[ownerName] = row
    return row
end

function ShamanQuick:UpdateWindowGeometry(count)
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

function ShamanQuick:EnsureWindow()
    if self.window and self.window.frame then
        return self.window
    end

    local aceGUI = getAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Shaman Quick", 1, 0.2, 0.2, 1)
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

function ShamanQuick:RefreshFromGroup()
    if not self:EnsureWindow() then
        return
    end

    local desiredNames = self:CollectShamanBots()
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

function MultiBot.InitShamanQuick()
    if ShamanQuick.__moduleReady then
        return ShamanQuick
    end

    ShamanQuick.__moduleReady = true
    ShamanQuick:EnsureWindow()

    MultiBot.TimerAfter(0.5, function()
        if MultiBot and MultiBot.ShamanQuick and MultiBot.ShamanQuick.RefreshFromGroup then
            MultiBot.ShamanQuick:RefreshFromGroup()
        end
    end)

    return ShamanQuick
end

MultiBot.InitShamanQuick()

if MultiBot.ShamanQuick and MultiBot.ShamanQuick.RestorePosition then
    MultiBot.ShamanQuick:RestorePosition()
end