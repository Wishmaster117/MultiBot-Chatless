if not MultiBot then return end

local ITEMUS_LAYOUT_KEY = "ItemusPoint"
local ITEMUS_PAGE_SIZE = 162
local ITEMUS_ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
local ITEMUS_FILTER_FIELD_BY_KIND = {
    Level = "level",
    Rare = "rare",
    Slot = "slot",
    Type = "type",
}

local ITEMUS_UI_DEFAULTS = {
    width = 760,
    height = 700,
    pointX = -860,
    pointY = -144,
    filterPanelHeight = 190,
    panelInset = 8,
    panelGap = 8,
    levelColumns = 8,
    rareColumns = 8,
    slotColumns = 15,
    filterButtonSize = 28,
    filterButtonSpacing = 32,
    slotButtonSize = 26,
    typePanelHeight = 96,
    slotButtonSpacing = 30,
    itemButtonSize = 32,
    itemSpacingX = 38,
    itemSpacingY = 37,
    itemColumns = 8,
    minItemColumns = 8,
    itemMinGapX = 6,
    scrollBarAllowance = 28,
    itemsPanelPadding = 8,
    minCanvasHeight = 240,
}

local function stripTooltipFormatting(text)
    local value = tostring(text or "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("\r", "")
    return value
end

local function getLocalizedHeadline(localeKey, fallback)
    local raw = MultiBot.L and MultiBot.L(localeKey) or nil
    local text = stripTooltipFormatting(raw or fallback or "")
    local headline = text:match("^(.-)\n") or text
    headline = headline:gsub("^%s+", ""):gsub("%s+$", "")
    if headline == "" then
        return fallback or ""
    end
    return headline
end

local function getDefinitionHeadline(definitions, value, fallback)
    for _, definition in ipairs(definitions or {}) do
        if definition.value == value then
            return getLocalizedHeadline(definition.tipKey, definition.label or definition.value or fallback)
        end
    end
    return fallback or tostring(value or "")
end

local function getLocalizedDescription(localeKey, fallback)
    local raw = MultiBot.L and MultiBot.L(localeKey) or nil
    local textValue = stripTooltipFormatting(raw or fallback or "")
    local descriptionLines = {}
    local lineIndex = 0

    for line in string.gmatch(textValue, "([^\n]+)") do
        lineIndex = lineIndex + 1
        local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
        if lineIndex > 1 then
            if trimmed == "" then
                break
            end
            table.insert(descriptionLines, trimmed)
        end
    end

    if #descriptionLines == 0 then
        return fallback or ""
    end

    return table.concat(descriptionLines, " ")
end

local function getItemusEmptyStateMessage()
    local fallback = "No items found for this combination."
    local raw = MultiBot.L and MultiBot.L("info.combination") or nil
    local textValue = stripTooltipFormatting(raw or fallback)
    textValue = textValue:gsub("^%s+", ""):gsub("%s+$", "")

    local firstSentence = textValue:match("^(.-[%.%!%?])")
    if not firstSentence then
        local sentenceEndings = { "。", "！", "？" }
        for _, ending in ipairs(sentenceEndings) do
            local stopIndex = string.find(textValue, ending, 1, true)
            if stopIndex then
                firstSentence = string.sub(textValue, 1, stopIndex)
                break
            end
        end
    end

    firstSentence = (firstSentence or textValue or fallback):gsub("^%s+", ""):gsub("%s+$", "")
    if firstSentence == "" then
        return fallback
    end

    return firstSentence
end

local function getItemusCountLabel(total)
    local count = tonumber(total) or 0
    local label = ((count == 1) and (ITEM or nil)) or ITEMS or "items"
    return string.format("%d %s", count, tostring(label))
end

local function getItemusResultsLabel(total, fromIndex, toIndex)
    local count = tonumber(total) or 0
    if count <= 0 or not fromIndex or not toIndex then
        return getItemusCountLabel(count)
    end

    return string.format("%d-%d / %s", fromIndex, toIndex, getItemusCountLabel(count))
end

local function getItemusAceGUI()
    if MultiBot.GetAceGUI then
        local ace = MultiBot.GetAceGUI()
        if type(ace) == "table" and type(ace.Create) == "function" then
            return ace
        end
    end

    if type(LibStub) == "table" then
        local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
        if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
            return aceGUI
        end
    end

    return nil
end

local itemusEscapeIndex = 0
local function registerItemusEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    itemusEscapeIndex = itemusEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Itemus"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, itemusEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function persistItemusWindowPosition(frame)
    if not frame or not MultiBot.SetSavedLayoutValue or not MultiBot.toPoint then
        return
    end

    local offsetX, offsetY = MultiBot.toPoint(frame)
    MultiBot.SetSavedLayoutValue(ITEMUS_LAYOUT_KEY, offsetX .. ", " .. offsetY)
end

local function bindItemusWindowPosition(window)
    if not window or not window.frame then
        return
    end

    local savedPoint = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(ITEMUS_LAYOUT_KEY) or nil
    if type(savedPoint) == "string" and savedPoint ~= "" then
        local splitPoint = MultiBot.doSplit(savedPoint, ", ")
        local offsetX = tonumber(splitPoint[1])
        local offsetY = tonumber(splitPoint[2])
        if offsetX and offsetY then
            window.frame:ClearAllPoints()
            window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", offsetX, offsetY)
        end
    end

    if window.__mbPositionHooked then
        return
    end

    window.__mbPositionHooked = true
    window.frame:HookScript("OnDragStop", function(frame)
        persistItemusWindowPosition(frame)
    end)
end

local function bindItemusMoveTooltip(window)
    if not window or not window.title or window.__mbMoveTooltipHooked then
        return
    end

    window.__mbMoveTooltipHooked = true
    window.title:HookScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(MultiBot.L("tips.move.itemus") or "Right-click to drag and move the Itemus window", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    window.title:HookScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)
end

local function isFrameDescendant(frame, ancestor)
    local current = frame
    while current do
        if current == ancestor then
            return true
        end
        if not current.GetParent then
            return false
        end
        current = current:GetParent()
    end
    return false
end

local function hideItemusTooltip(window)
    if not window or not window.frame or not GameTooltip or not GameTooltip.GetOwner then
        return
    end

    local owner = GameTooltip:GetOwner()
    if owner and isFrameDescendant(owner, window.frame) and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end

local function addSimpleBackdrop(frame, bgAlpha)
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

local function addSectionTitle(parent, text)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    title:SetText(text or "")
    return title
end

local function createFilterButton(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    button.border:Hide()

    button.tip = nil
    button.value = nil
    button.filterKind = nil
    button.selected = false

    function button:setTexture(texturePath)
        self.texture = MultiBot.SafeTexturePath(texturePath)
        self.icon:SetTexture(self.texture)
    end

    function button:setSelected(state)
        self.selected = state and true or false
        if self.icon and self.icon.SetDesaturated then
            self.icon:SetDesaturated(not self.selected)
        end
        if self.border then
            if self.selected then self.border:Show() else self.border:Hide() end
        end
    end

    button:SetScript("OnEnter", function(self)
        if not self.tip or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    function button:setLabel(textValue)
        if not self.labelText then
            self.labelText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            self.labelText:SetPoint("BOTTOM", self, "BOTTOM", 0, 1)
        end
        self.labelText:SetText(textValue or "")
    end

    return button
end

local function createItemButton(parent, itemus)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ITEMUS_UI_DEFAULTS.itemButtonSize, ITEMUS_UI_DEFAULTS.itemButtonSize)
    button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(MultiBot.SafeTexturePath(ITEMUS_ICON_FALLBACK))

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)

    button.itemId = 0
    button.itemName = nil
    button.link = nil

    button:SetScript("OnClick", function(self)
        if self.itemId and self.itemId > 0 then
            MultiBot.doDotWithTarget(".additem", self.itemId .. " 1")
        end
    end)

    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.link then
            GameTooltip:SetHyperlink(self.link)
        end
        if self.itemName and self.itemName ~= "" and GameTooltip.NumLines and GameTooltip:NumLines() <= 0 then
            GameTooltip:SetText(self.itemName, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    return button
end

local function resetItemButton(button)
    if not button then
        return
    end

    button.itemId = 0
    button.itemName = nil
    button.link = nil

    if button.icon then
        button.icon:SetTexture(MultiBot.SafeTexturePath(ITEMUS_ICON_FALLBACK))
    end
end

local function clearItemButtonPool(itemus)
    if not itemus or not itemus.itemButtons then
        return
    end

    for _, button in ipairs(itemus.itemButtons) do
        resetItemButton(button)
        button:Hide()
    end
end

local function ensureButtonPool(itemus, count)
    if not itemus.itemButtons then
        itemus.itemButtons = {}
    end

    while #itemus.itemButtons < count do
        local button = createItemButton(itemus.scrollChild, itemus)
        button:Hide()
        table.insert(itemus.itemButtons, button)
    end
end

local function getItemusGridMetrics(itemus)
    local defaultColumns = ITEMUS_UI_DEFAULTS.itemColumns
    local minColumns = ITEMUS_UI_DEFAULTS.minItemColumns or defaultColumns
    local buttonSize = ITEMUS_UI_DEFAULTS.itemButtonSize
    local minStepX = buttonSize + (ITEMUS_UI_DEFAULTS.itemMinGapX or 0)
    local fallbackWidth = ((defaultColumns - 1) * ITEMUS_UI_DEFAULTS.itemSpacingX) + buttonSize + 8
    local availableWidth = fallbackWidth

    if itemus and itemus.scrollFrame and itemus.scrollFrame.GetWidth then
        local measuredWidth = tonumber(itemus.scrollFrame:GetWidth()) or 0
        if measuredWidth > buttonSize then
            availableWidth = measuredWidth
        elseif itemus.scrollChild and itemus.scrollChild.GetWidth then
            availableWidth = tonumber(itemus.scrollChild:GetWidth()) or fallbackWidth
        end
    end

    local columns = math.max(minColumns, math.floor((availableWidth + (ITEMUS_UI_DEFAULTS.itemMinGapX or 0)) / minStepX))
    if columns < 1 then
        columns = defaultColumns
    end

    local stepX = ITEMUS_UI_DEFAULTS.itemSpacingX
    if columns > 1 then
        stepX = math.max(minStepX, math.floor((availableWidth - buttonSize) / (columns - 1)))
    end

    local contentWidth = ((columns - 1) * stepX) + buttonSize + 8
    return {
        columns = columns,
        stepX = stepX,
        stepY = ITEMUS_UI_DEFAULTS.itemSpacingY,
        contentWidth = contentWidth,
    }
end

local function updateScrollCanvasHeight(itemus, visibleCount, gridMetrics)
    local metrics = gridMetrics or getItemusGridMetrics(itemus)
    local totalRows = math.max(1, math.ceil(math.max(visibleCount, 1) / metrics.columns))
    local height = (totalRows - 1) * metrics.stepY + ITEMUS_UI_DEFAULTS.itemButtonSize + 12
    itemus.scrollChild:SetWidth(metrics.contentWidth)
    itemus.scrollChild:SetHeight(math.max(height, ITEMUS_UI_DEFAULTS.minCanvasHeight))
    itemus.gridMetrics = metrics
end

local function resetItemusScroll(itemus)
    if itemus and itemus.scrollFrame and itemus.scrollFrame.SetVerticalScroll then
        itemus.scrollFrame:SetVerticalScroll(0)
    end
end

local function setPageLabel(itemus, label)
    if itemus.pageLabel then
        itemus.pageLabel:SetText(label or "")
    end
end

local function updateNavigation(itemus)
    if not itemus.prevButton or not itemus.nextButton then
        return
    end

    if itemus.max <= 0 then
        itemus.prevButton:Hide()
        itemus.nextButton:Hide()
        return
    end

    if itemus.now <= 1 then itemus.prevButton:Hide() else itemus.prevButton:Show() end
    if itemus.now >= itemus.max then itemus.nextButton:Hide() else itemus.nextButton:Show() end
end

local LEVEL_OPTIONS = {
    { value = "L10", icon = "achievement_level_10", tipKey = "tips.itemus.level.L10" },
    { value = "L20", icon = "achievement_level_20", tipKey = "tips.itemus.level.L20" },
    { value = "L30", icon = "achievement_level_30", tipKey = "tips.itemus.level.L30" },
    { value = "L40", icon = "achievement_level_40", tipKey = "tips.itemus.level.L40" },
    { value = "L50", icon = "achievement_level_50", tipKey = "tips.itemus.level.L50" },
    { value = "L60", icon = "achievement_level_60", tipKey = "tips.itemus.level.L60" },
    { value = "L70", icon = "achievement_level_70", tipKey = "tips.itemus.level.L70" },
    { value = "L80", icon = "achievement_level_80", tipKey = "tips.itemus.level.L80" },
}

local RARE_OPTIONS = {
    { value = "R00", icon = "achievement_quests_completed_01", tipKey = "tips.itemus.rare.R00", color = "cff9d9d9d" },
    { value = "R01", icon = "achievement_quests_completed_02", tipKey = "tips.itemus.rare.R01", color = "cffffffff" },
    { value = "R02", icon = "achievement_quests_completed_03", tipKey = "tips.itemus.rare.R02", color = "cff1eff00" },
    { value = "R03", icon = "achievement_quests_completed_04", tipKey = "tips.itemus.rare.R03", color = "cff0070dd" },
    { value = "R04", icon = "achievement_quests_completed_05", tipKey = "tips.itemus.rare.R04", color = "cffa335ee" },
    { value = "R05", icon = "achievement_quests_completed_06", tipKey = "tips.itemus.rare.R05", color = "cffff8000" },
    { value = "R06", icon = "achievement_quests_completed_07", tipKey = "tips.itemus.rare.R06", color = "cffff0000" },
    { value = "R07", icon = "achievement_quests_completed_08", tipKey = "tips.itemus.rare.R07", color = "cffe6cc80" },
}

local SLOT_OPTIONS = {
    { value = "S00", icon = "inv_drink_18", tipKey = "tips.itemus.slot.S00" },
    { value = "S01", icon = "inv_misc_desecrated_platehelm", tipKey = "tips.itemus.slot.S01" },
    { value = "S02", icon = "inv_jewelry_necklace_22", tipKey = "tips.itemus.slot.S02" },
    { value = "S03", icon = "inv_misc_desecrated_plateshoulder", tipKey = "tips.itemus.slot.S03" },
    { value = "S04", icon = "inv_shirt_grey_01", tipKey = "tips.itemus.slot.S04" },
    { value = "S05", icon = "inv_misc_desecrated_platechest", tipKey = "tips.itemus.slot.S05" },
    { value = "S06", icon = "inv_misc_desecrated_platebelt", tipKey = "tips.itemus.slot.S06" },
    { value = "S07", icon = "inv_misc_desecrated_platepants", tipKey = "tips.itemus.slot.S07" },
    { value = "S08", icon = "inv_misc_desecrated_plateboots", tipKey = "tips.itemus.slot.S08" },
    { value = "S09", icon = "inv_misc_desecrated_platebracer", tipKey = "tips.itemus.slot.S09" },
    { value = "S10", icon = "inv_misc_desecrated_plategloves", tipKey = "tips.itemus.slot.S10" },
    { value = "S11", icon = "inv_jewelry_ring_19", tipKey = "tips.itemus.slot.S11" },
    { value = "S12", icon = "inv_jewelry_ring_07", tipKey = "tips.itemus.slot.S12" },
    { value = "S13", icon = "inv_sword_23", tipKey = "tips.itemus.slot.S13" },
    { value = "S14", icon = "inv_shield_04", tipKey = "tips.itemus.slot.S14" },
    { value = "S15", icon = "inv_weapon_bow_05", tipKey = "tips.itemus.slot.S15" },
    { value = "S16", icon = "inv_misc_cape_20", tipKey = "tips.itemus.slot.S16" },
    { value = "S17", icon = "inv_axe_14", tipKey = "tips.itemus.slot.S17" },
    { value = "S18", icon = "inv_misc_bag_07_black", tipKey = "tips.itemus.slot.S18" },
    { value = "S19", icon = "inv_shirt_guildtabard_01", tipKey = "tips.itemus.slot.S19" },
    { value = "S20", icon = "inv_misc_desecrated_clothchest", tipKey = "tips.itemus.slot.S20" },
    { value = "S21", icon = "inv_hammer_07", tipKey = "tips.itemus.slot.S21" },
    { value = "S22", icon = "inv_sword_15", tipKey = "tips.itemus.slot.S22" },
    { value = "S23", icon = "inv_misc_book_09", tipKey = "tips.itemus.slot.S23" },
    { value = "S24", icon = "inv_misc_ammo_arrow_01", tipKey = "tips.itemus.slot.S24" },
    { value = "S25", icon = "inv_throwingknife_02", tipKey = "tips.itemus.slot.S25" },
    { value = "S26", icon = "inv_wand_07", tipKey = "tips.itemus.slot.S26" },
    { value = "S27", icon = "inv_misc_quiver_07", tipKey = "tips.itemus.slot.S27" },
    { value = "S28", icon = "inv_relics_idolofrejuvenation", tipKey = "tips.itemus.slot.S28" },
}

local TYPE_OPTIONS = {
    { value = "PC", icon = "inv_box_01", tipKey = "tips.itemus.type", label = "PC" },
    { value = "NPC", icon = "inv_misc_head_clockworkgnome_01", tipKey = "tips.itemus.type", label = "NPC" },
}

local function syncFilterSelectionButtons(itemus)
    local groups = itemus.filterButtons or {}
    for _, button in ipairs(groups.Level or {}) do
        button:setSelected(button.value == itemus.level)
    end
    for _, button in ipairs(groups.Rare or {}) do
        button:setSelected(button.value == itemus.rare)
    end
    for _, button in ipairs(groups.Slot or {}) do
        button:setSelected(button.value == itemus.slot)
    end
    for _, button in ipairs(groups.Type or {}) do
        button:setSelected(button.value == itemus.type)
    end

    if itemus.typeLabel then
        itemus.typeLabel:SetText(getLocalizedHeadline("tips.itemus.type", "Type") .. ": |cffffcc00" .. tostring(itemus.type or "PC") .. "|r")
    end
end

local function applyItemusFilterUpdates(itemus, updates)
    if not itemus or type(updates) ~= "table" then
        return
    end

    for kind, value in pairs(updates) do
        local field = ITEMUS_FILTER_FIELD_BY_KIND[kind]
        if field ~= nil and value ~= nil then
            itemus[field] = value
        end
    end

    if updates.RareColor ~= nil then
        itemus.color = updates.RareColor
    end

    syncFilterSelectionButtons(itemus)
end

local function createButtonGrid(parent, itemus, kind, definitions, config)
    local buttons = {}
    local startX = config.startX or 8
    local startY = config.startY or -26
    local columns = config.columns or 8
    local spacing = config.spacing or 32
    local size = config.size or 28

    for index, definition in ipairs(definitions) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        local button = createFilterButton(parent, size)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", startX + (column * spacing), startY - (row * spacing))
        button.value = definition.value
        button.filterKind = kind
        button.tip = MultiBot.L(definition.tipKey)
        button:setTexture(definition.icon)
        if definition.label then
            button:setLabel(definition.label)
        end
        button:SetScript("OnClick", function(self)
            if itemus and itemus.SetFilters then
                itemus:SetFilters({
                    [kind] = self.value,
                    RareColor = definition.color,
                }, {
                    page = 1,
                    refresh = true,
                })
            end
        end)
        table.insert(buttons, button)
    end

    return buttons
end

local function createItemusContent(window, itemus)
    local content = window.content
    content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -10, 10)

    local root = CreateFrame("Frame", nil, content)
    root:SetAllPoints(content)
    addSimpleBackdrop(root, 0.90)

    local filterPanel = CreateFrame("Frame", nil, root)
    filterPanel:SetPoint("TOPLEFT", root, "TOPLEFT", ITEMUS_UI_DEFAULTS.panelInset, -ITEMUS_UI_DEFAULTS.panelInset)
    filterPanel:SetPoint("TOPRIGHT", root, "TOPRIGHT", -ITEMUS_UI_DEFAULTS.panelInset, -ITEMUS_UI_DEFAULTS.panelInset)
    filterPanel:SetHeight(ITEMUS_UI_DEFAULTS.filterPanelHeight)
    addSimpleBackdrop(filterPanel, 0.55)

    local itemsPanel = CreateFrame("Frame", nil, root)
    itemsPanel:SetPoint("TOPLEFT", filterPanel, "BOTTOMLEFT", 0, -ITEMUS_UI_DEFAULTS.panelGap)
    itemsPanel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -ITEMUS_UI_DEFAULTS.panelInset, ITEMUS_UI_DEFAULTS.panelInset)
    addSimpleBackdrop(itemsPanel, 0.55)

    local levelPanel = CreateFrame("Frame", nil, filterPanel)
    levelPanel:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 8, -8)
    levelPanel:SetSize(324, 70)
    addSimpleBackdrop(levelPanel, 0.35)
    addSectionTitle(levelPanel, getLocalizedHeadline("tips.itemus.level.master", "Level"))

    local rarePanel = CreateFrame("Frame", nil, filterPanel)
    rarePanel:SetPoint("TOPRIGHT", filterPanel, "TOPRIGHT", -8, -8)
    rarePanel:SetSize(324, 70)
    addSimpleBackdrop(rarePanel, 0.35)
    addSectionTitle(rarePanel, getLocalizedHeadline("tips.itemus.rare.master", "Rare"))

    local typePanel = CreateFrame("Frame", nil, filterPanel)
    typePanel:SetPoint("TOPLEFT", levelPanel, "BOTTOMLEFT", 0, -8)
    typePanel:SetSize(150, ITEMUS_UI_DEFAULTS.typePanelHeight)
    addSimpleBackdrop(typePanel, 0.35)

    local typeLabel = typePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    typeLabel:SetPoint("TOPLEFT", typePanel, "TOPLEFT", 8, -8)
    typeLabel:SetPoint("TOPRIGHT", typePanel, "TOPRIGHT", -8, -8)
    typeLabel:SetJustifyH("LEFT")
    itemus.typeLabel = typeLabel

    local slotPanel = CreateFrame("Frame", nil, filterPanel)
    slotPanel:SetPoint("TOPLEFT", typePanel, "TOPRIGHT", 8, 0)
    slotPanel:SetPoint("BOTTOMRIGHT", filterPanel, "BOTTOMRIGHT", -8, 8)
    addSimpleBackdrop(slotPanel, 0.35)
    addSectionTitle(slotPanel, getLocalizedHeadline("tips.itemus.slot.master", "Slot"))

    itemus.filterButtons = {
        Level = createButtonGrid(levelPanel, itemus, "Level", LEVEL_OPTIONS, { startX = 8, startY = -34, columns = 8, spacing = ITEMUS_UI_DEFAULTS.filterButtonSpacing, size = ITEMUS_UI_DEFAULTS.filterButtonSize }),
        Rare = createButtonGrid(rarePanel, itemus, "Rare", RARE_OPTIONS, { startX = 8, startY = -34, columns = 8, spacing = ITEMUS_UI_DEFAULTS.filterButtonSpacing, size = ITEMUS_UI_DEFAULTS.filterButtonSize }),
        Type = createButtonGrid(typePanel, itemus, "Type", TYPE_OPTIONS, { startX = 8, startY = -34, columns = 2, spacing = 36, size = ITEMUS_UI_DEFAULTS.filterButtonSize }),
        Slot = createButtonGrid(slotPanel, itemus, "Slot", SLOT_OPTIONS, { startX = 8, startY = -30, columns = ITEMUS_UI_DEFAULTS.slotColumns, spacing = ITEMUS_UI_DEFAULTS.slotButtonSpacing, size = ITEMUS_UI_DEFAULTS.slotButtonSize }),
    }

    local pageLabel = itemsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageLabel:SetPoint("TOP", itemsPanel, "TOP", 0, -8)
    --pageLabel:SetText(MB_PAGE_DEFAULT)
    pageLabel:SetText(MultiBot.MB_PAGE_DEFAULT or "0/0")

    local resultsLabel = itemsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultsLabel:SetPoint("TOPRIGHT", itemsPanel, "TOPRIGHT", -12, -10)
    resultsLabel:SetJustifyH("RIGHT")
    resultsLabel:SetText(getItemusCountLabel(0))

    local summaryLabel = itemsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summaryLabel:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 12, -30)
    summaryLabel:SetPoint("TOPRIGHT", itemsPanel, "TOPRIGHT", -12, -30)
    summaryLabel:SetJustifyH("CENTER")
    summaryLabel:SetText("")

    local descriptionLabel = itemsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    descriptionLabel:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 12, -46)
    descriptionLabel:SetPoint("TOPRIGHT", itemsPanel, "TOPRIGHT", -12, -46)
    descriptionLabel:SetJustifyH("LEFT")
    descriptionLabel:SetJustifyV("TOP")
    if descriptionLabel.SetNonSpaceWrap then
        descriptionLabel:SetNonSpaceWrap(true)
    end
    descriptionLabel:SetText(getLocalizedDescription("tips.game.itemus", "Generate one item at a time on the current target while keeping the legacy filter flow."))

    local prevButton = CreateFrame("Button", nil, itemsPanel, "UIPanelButtonTemplate")
    prevButton:SetSize(26, 20)
    prevButton:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 8, -6)
    prevButton:SetText("<")

    local nextButton = CreateFrame("Button", nil, itemsPanel, "UIPanelButtonTemplate")
    nextButton:SetSize(26, 20)
    nextButton:SetPoint("LEFT", prevButton, "RIGHT", 6, 0)
    nextButton:SetText(">")

    local emptyLabel = itemsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", 16, -74)
    emptyLabel:SetPoint("TOPRIGHT", itemsPanel, "TOPRIGHT", -16, -74)
    emptyLabel:SetJustifyH("CENTER")
    emptyLabel:SetText(getItemusEmptyStateMessage())
    emptyLabel:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", "MultiBotItemusScrollFrame", itemsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", ITEMUS_UI_DEFAULTS.itemsPanelPadding, -76)
    scrollFrame:SetPoint("BOTTOMRIGHT", itemsPanel, "BOTTOMRIGHT", -ITEMUS_UI_DEFAULTS.scrollBarAllowance, ITEMUS_UI_DEFAULTS.itemsPanelPadding)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(((ITEMUS_UI_DEFAULTS.itemColumns - 1) * ITEMUS_UI_DEFAULTS.itemSpacingX) + ITEMUS_UI_DEFAULTS.itemButtonSize + 8)
    scrollChild:SetHeight(ITEMUS_UI_DEFAULTS.minCanvasHeight)
    scrollFrame:SetScrollChild(scrollChild)

    itemus.pageLabel = pageLabel
    itemus.resultsLabel = resultsLabel
    itemus.summaryLabel = summaryLabel
    itemus.descriptionLabel = descriptionLabel
    itemus.prevButton = prevButton
    itemus.nextButton = nextButton
    itemus.emptyLabel = emptyLabel
    itemus.scrollFrame = scrollFrame
    itemus.scrollChild = scrollChild

    return {
        root = root,
        filterPanel = filterPanel,
        itemsPanel = itemsPanel,
    }
end

local function updateItemusSummary(itemus, total, fromIndex, toIndex)
    if itemus.resultsLabel then
        itemus.resultsLabel:SetText(getItemusResultsLabel(total, fromIndex, toIndex))
    end

    if itemus.summaryLabel then
        local levelText = getDefinitionHeadline(LEVEL_OPTIONS, itemus.level, itemus.level)
        local rareText = getDefinitionHeadline(RARE_OPTIONS, itemus.rare, itemus.rare)
        local slotText = getDefinitionHeadline(SLOT_OPTIONS, itemus.slot, itemus.slot)
        local typeText = tostring(itemus.type or "PC")
        local rareColor = tostring(itemus.color or "cffffffff")
        itemus.summaryLabel:SetText(levelText .. "  •  |" .. rareColor .. rareText .. "|r  •  " .. slotText .. "  •  " .. typeText)
    end
end

local function renderItemButtonAtIndex(itemus, button, itemData, buttonIndex)
    local itemId = itemData and itemData[1] or 0
    local itemName = itemData and itemData[2] or ""
    local icon = GetItemIcon(itemId)
    if not icon then
        icon = ITEMUS_ICON_FALLBACK
    end

    local metrics = itemus.gridMetrics or getItemusGridMetrics(itemus)
    local column = (buttonIndex - 1) % metrics.columns
    local row = math.floor((buttonIndex - 1) / metrics.columns)
    local xOffset = column * metrics.stepX
    local yOffset = -(row * metrics.stepY)

    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", itemus.scrollChild, "TOPLEFT", xOffset, yOffset)
    button.itemId = itemId
    button.itemName = itemName
    button.link = "item:" .. tostring(itemId)
    button.icon:SetTexture(MultiBot.SafeTexturePath(icon))
    button:Show()
end

local function applyItemusPagePayload(itemus, pageData)
    local payload = pageData or {}
    itemus.max = payload.maxPage or 0
    itemus.now = payload.currentPage or 0

    if itemus.max > 0 then
        setPageLabel(itemus, itemus.now .. "/" .. itemus.max)
    else
        setPageLabel(itemus, "0/0")
    end

    updateNavigation(itemus)
end

function MultiBot.InitializeItemusFrame()
    if MultiBot.itemus and MultiBot.itemus.__aceInitialized then
        return MultiBot.itemus
    end

    local aceGUI = getItemusAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Itemus", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(getLocalizedHeadline("tips.game.itemus", "Itemus"))
    window:SetLayout("Manual")
    window:SetWidth(ITEMUS_UI_DEFAULTS.width)
    window:SetHeight(ITEMUS_UI_DEFAULTS.height)
    window:EnableResize(false)
    window.frame:SetClampedToScreen(true)
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end
    window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", ITEMUS_UI_DEFAULTS.pointX, ITEMUS_UI_DEFAULTS.pointY)
    window:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)
    window:Hide()
    window.frame:HookScript("OnHide", function()
        hideItemusTooltip(window)
    end)

    registerItemusEscapeClose(window, "Itemus")
    bindItemusWindowPosition(window)
    bindItemusMoveTooltip(window)

    local itemus = MultiBot.itemus or {}
    itemus.__aceInitialized = true
    itemus.window = window
    itemus.name = itemus.name or UnitName("player") or ""
    itemus.index = itemus.index or {}
    if itemus.applyStateDefaults then
        itemus:applyStateDefaults()
    else
        itemus.color = itemus.color or "cff9d9d9d"
        itemus.level = itemus.level or "L10"
        itemus.rare = itemus.rare or "R00"
        itemus.slot = itemus.slot or "S00"
        itemus.type = itemus.type or "PC"
        itemus.max = itemus.max or 1
        itemus.now = itemus.now or 1
    end

    local content = createItemusContent(window, itemus)
    itemus.root = content.root
    itemus.content = content

    function itemus:Show()
        if self.window then
            self.window:Show()
        end
    end

    function itemus:Hide()
        if self.window then
            self.window:Hide()
        end
    end

    function itemus:IsVisible()
        return self.window and self.window.frame and self.window.frame:IsShown() or false
    end

    function itemus:GetRight()
        return self.window and self.window.frame and self.window.frame:GetRight() or 0
    end

    function itemus:GetBottom()
        return self.window and self.window.frame and self.window.frame:GetBottom() or 0
    end

    function itemus.setPoint(x, y)
        if type(x) ~= "number" or type(y) ~= "number" then return end
        window.frame:ClearAllPoints()
        window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        persistItemusWindowPosition(window.frame)
    end

    function itemus:GetFilterState()
        return {
            level = self.level,
            rare = self.rare,
            slot = self.slot,
            type = self.type,
            color = self.color,
        }
    end

    function itemus:Open(page)
        self:Show()
        return self:Refresh(page)
    end

    function itemus:Toggle()
        if self:IsVisible() then
            self:Hide()
            return false
        end

        self:Open(self.now)
        return true
    end

    function itemus:SetFilters(updates, options)
        local nextUpdates = updates or {}
        applyItemusFilterUpdates(self, nextUpdates)

        if self.setFilterState then
            self:setFilterState({
                level = self.level,
                rare = self.rare,
                slot = self.slot,
                type = self.type,
                color = self.color,
            })
        end

        local config = options or {}
        if config.page ~= nil then
            self.now = config.page
        end

        if config.refresh == false then
            return self
        end

        self:Refresh(config.page)
        return self
    end

    function itemus:SetPage(page, options)
        if self.setPageState then
            self:setPageState(page, ITEMUS_PAGE_SIZE)
        elseif type(page) == "number" then
            self.now = page
        end

        local config = options or {}
        if config.refresh == false then
            return self
        end

        self:Refresh(self.now)
        return self
    end

    function itemus:Refresh(page)
        local targetPage = page
        if targetPage == nil then
            targetPage = self.now
        end

        if self.getRenderPayload then
            return self:renderItems(self:getRenderPayload(targetPage, ITEMUS_PAGE_SIZE))
         end

        if self.addItems then
            return self.addItems(targetPage)
        end

        return nil
    end

    function itemus:renderItems(pageData)
        local payload = pageData or {
            visibleItems = {},
            total = 0,
            maxPage = 0,
            currentPage = 0,
            fromIndex = 0,
            toIndex = 0,
        }
        applyItemusPagePayload(self, payload)

        if (payload.total or 0) == 0 then
            updateItemusSummary(self, 0, payload.fromIndex, payload.toIndex)
            self.emptyLabel:Show()
            ensureButtonPool(self, 0)
            clearItemButtonPool(self)
            updateScrollCanvasHeight(self, 1)
            resetItemusScroll(self)
            --SendChatMessage(MultiBot.L("info.combination"), "SAY")
            return
        end

        updateItemusSummary(self, payload.total, payload.fromIndex, payload.toIndex)
        self.emptyLabel:Hide()

        local visibleCount = #(payload.visibleItems or {})
        local gridMetrics = getItemusGridMetrics(self)
        ensureButtonPool(self, visibleCount)
        updateScrollCanvasHeight(self, visibleCount, gridMetrics)
        resetItemusScroll(self)

        local buttonIndex = 1
        for _, itemData in ipairs(payload.visibleItems or {}) do
            local button = self.itemButtons[buttonIndex]
            renderItemButtonAtIndex(self, button, itemData, buttonIndex)
            buttonIndex = buttonIndex + 1
        end

        for hiddenIndex = buttonIndex, #(self.itemButtons or {}) do
            resetItemButton(self.itemButtons[hiddenIndex])
            self.itemButtons[hiddenIndex]:Hide()
        end
    end

    local prevButton = itemus.prevButton
    local nextButton = itemus.nextButton
    prevButton:SetScript("OnClick", function()
        if itemus.now <= 1 then return end
        itemus:SetPage(itemus.now - 1)
    end)

    nextButton:SetScript("OnClick", function()
        if itemus.now >= itemus.max then return end
        itemus:SetPage(itemus.now + 1)
    end)

    MultiBot.itemus = itemus
    syncFilterSelectionButtons(itemus)
    updateNavigation(itemus)
    updateItemusSummary(itemus, 0)
    return itemus
end