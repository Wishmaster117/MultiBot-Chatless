if not MultiBot then return end

local ICONOS_LAYOUT_KEY = "IconosPoint"
local ICONOS_ICON_COLUMNS = 11
local ICONOS_ICON_ROWS = 13
local ICONOS_PAGE_SIZE = ICONOS_ICON_COLUMNS * ICONOS_ICON_ROWS
local ICONOS_ICON_SIZE = 32
local ICONOS_ICON_SPACING_X = 38
local ICONOS_ICON_SPACING_Y = 37
local ICONOS_ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"

local ICONOS_UI_DEFAULTS = {
    width = 470,
    height = 776,
    pointX = -860,
    pointY = -144,
    panelInset = 8,
    topPanelHeight = 108,
    pageButtonWidth = 26,
    pageButtonHeight = 22,
    previewPanelHeight = 50,
    previewIconSize = 36,
    recentButtonsCount = 6,
    recentButtonSize = 20,
    recentButtonSpacing = 24,
    pathBoxHeight = 22,
    pathPanelHeight = 34,
    gridPaddingX = 9,
    gridPaddingY = 10,
}

local function getIconosAceGUI()
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

local function hideEditBoxTemplateTextures(editBox)
    if not editBox or not editBox.GetRegions then
        return
    end

    local regions = { editBox:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end
end

local iconosEscapeIndex = 0
local function registerIconosEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    iconosEscapeIndex = iconosEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Iconos"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, iconosEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function persistIconosWindowPosition(frame)
    if not frame or not MultiBot.SetSavedLayoutValue or not MultiBot.toPoint then
        return
    end

    local offsetX, offsetY = MultiBot.toPoint(frame)
    MultiBot.SetSavedLayoutValue(ICONOS_LAYOUT_KEY, offsetX .. ", " .. offsetY)
end

local function bindIconosWindowPosition(window)
    if not window or not window.frame then
        return
    end

    local savedPoint = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(ICONOS_LAYOUT_KEY) or nil
    if type(savedPoint) == "string" and savedPoint ~= "" then
        local offsetX, offsetY = string.match(savedPoint, "^%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
        offsetX = tonumber(offsetX)
        offsetY = tonumber(offsetY)
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
        persistIconosWindowPosition(frame)
    end)
end

local function bindIconosMoveInteractions(window)
    if not window or not window.frame or not window.title or window.__mbMoveHooksBound then
        return
    end

    window.__mbMoveHooksBound = true
    window.frame:SetMovable(true)
    window.frame:SetClampedToScreen(true)

    window.title:HookScript("OnMouseDown", function(_, mouseButton)
        if mouseButton ~= "RightButton" then
            return
        end

        window.frame:StartMoving()
        window.frame.__mbRightDragging = true
    end)

    window.title:HookScript("OnMouseUp", function()
        if window.frame.__mbRightDragging then
            window.frame.__mbRightDragging = nil
            window.frame:StopMovingOrSizing()
        end

        persistIconosWindowPosition(window.frame)
    end)

    window.frame:HookScript("OnHide", function(frame)
        if frame.__mbRightDragging then
            frame.__mbRightDragging = nil
            frame:StopMovingOrSizing()
        end

        persistIconosWindowPosition(frame)
    end)

    window.frame:HookScript("OnMouseUp", function(frame)
        if frame.__mbRightDragging then
            frame.__mbRightDragging = nil
            frame:StopMovingOrSizing()
        end

        persistIconosWindowPosition(frame)
    end)

    window.title:HookScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(MultiBot.L("tips.move.iconos") or "Right-click to drag and move the Iconos window", 1, 1, 1, true)
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

local function hideIconosTooltip(window)
    if not window or not window.frame or not GameTooltip or not GameTooltip.GetOwner then
        return
    end

    local owner = GameTooltip:GetOwner()
    if owner and isFrameDescendant(owner, window.frame) and GameTooltip.Hide then
        GameTooltip:Hide()
    end
end

local function getIconosEntries()
    local dataProvider = MultiBot.GetIconosEntries
    local data = type(dataProvider) == "function" and dataProvider() or (MultiBot.data and MultiBot.data.iconos)
    if type(data) ~= "table" then
        return nil
    end
    return data
end

local function getIconosPageLabel(currentPage, maxPage)
    local current = tonumber(currentPage) or 0
    local maxValue = tonumber(maxPage) or 0
    return string.format("%d/%d", current, maxValue)
end

local function getIconosPathLabel(texturePath)
    return tostring(texturePath or "")
end

local function getIconosShortName(texturePath)
    local iconPath = tostring(texturePath or "")
    if string.len(iconPath) > 16 then
        return string.sub(iconPath, 17)
    end
    return iconPath
end

local function normalizeIconosSearchQuery(value)
    local text = tostring(value or ""):lower()
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function ensureIconosEntryCache(iconos)
    if not iconos then
        return
    end

    local entries = getIconosEntries()
    local entryCount = entries and #entries or 0

    if iconos.entrySource == entries and iconos.entrySourceCount == entryCount and iconos.entryCache then
        return
    end

    iconos.entrySource = entries
    iconos.entrySourceCount = entryCount
    iconos.entryCache = {}
    iconos.visibleEntryCache = nil
    iconos.visibleEntryCacheKey = nil
    iconos.invalidEntryCount = 0

    if not entries then
        return
    end

    for index, texturePath in ipairs(entries) do
        if type(texturePath) == "string" and texturePath ~= "" then
            local shortName = getIconosShortName(texturePath)
            iconos.entryCache[#iconos.entryCache + 1] = {
                originalIndex = index,
                texturePath = texturePath,
                shortName = shortName,
                shortNameLower = shortName:lower(),
                pathLower = tostring(texturePath):lower(),
            }
        else
            iconos.invalidEntryCount = (iconos.invalidEntryCount or 0) + 1
        end
    end
end

local function getIconosEntriesForView(iconos)
    ensureIconosEntryCache(iconos)

    if not iconos or not iconos.entryCache then
        return {}
    end

    return iconos.entryCache
end

local function getVisibleIconosEntries(iconos)
    if not iconos then
        return {}
    end

    local searchQuery = normalizeIconosSearchQuery(iconos.searchQuery)
    local searchMode = iconos.searchMode or "all"
    local cacheKey = searchMode .. "\031" .. searchQuery

    ensureIconosEntryCache(iconos)

    if iconos.visibleEntryCacheKey == cacheKey and iconos.visibleEntryCache then
        return iconos.visibleEntryCache
    end

    local visibleSourceEntries = getIconosEntriesForView(iconos)
    if searchQuery == "" then
        iconos.visibleEntryCache = visibleSourceEntries
        iconos.visibleEntryCacheKey = cacheKey
        return visibleSourceEntries
    end

    local filteredEntries = {}
    for _, entry in ipairs(visibleSourceEntries) do
        local isMatch
        if searchMode == "path" then
            isMatch = entry.pathLower:find(searchQuery, 1, true) ~= nil
        else
            isMatch = entry.shortNameLower:find(searchQuery, 1, true) ~= nil
                or entry.pathLower:find(searchQuery, 1, true) ~= nil
        end

        if isMatch then
            filteredEntries[#filteredEntries + 1] = entry
        end
    end

    iconos.visibleEntryCache = filteredEntries
    iconos.visibleEntryCacheKey = cacheKey
    return filteredEntries
end

local function setPathDisplay(iconos, texturePath)
    if not iconos then
        return
    end

    local normalizedPath = getIconosPathLabel(texturePath)
    local shortName = getIconosShortName(normalizedPath)
    local safeTexture = (normalizedPath ~= "" and MultiBot.SafeTexturePath(normalizedPath)) or ICONOS_ICON_FALLBACK

    iconos.selectedPath = normalizedPath
    iconos.selectedShortName = (normalizedPath ~= "" and shortName) or ""

    if iconos.pathBox then
        iconos.pathBox:SetText(iconos.selectedPath)
        iconos.pathBox:SetCursorPosition(0)
    end

    if iconos.previewIcon then
        iconos.previewIcon:SetTexture(safeTexture)
    end

    if iconos.previewNameLabel then
        iconos.previewNameLabel:SetText(iconos.selectedShortName)
    end
end

local function updateRecentButtons(iconos)
    if not iconos or not iconos.recentButtons then
        return
    end

    local recentPaths = iconos.recentPaths or {}
    for index, button in ipairs(iconos.recentButtons) do
        local texturePath = recentPaths[index]
        if texturePath then
            button.texturePath = texturePath
            button.shortName = getIconosShortName(texturePath)
            button.icon:SetTexture(MultiBot.SafeTexturePath(texturePath))
            button:Show()
        else
            button.texturePath = nil
            button.shortName = nil
            button.icon:SetTexture(ICONOS_ICON_FALLBACK)
            button:Hide()
        end
    end
end

local function pushRecentIcon(iconos, texturePath)
    if not iconos or type(texturePath) ~= "string" or texturePath == "" then
        return
    end

    local recentPaths = iconos.recentPaths or {}
    local deduped = { texturePath }
    for _, existingPath in ipairs(recentPaths) do
        if existingPath ~= texturePath then
            deduped[#deduped + 1] = existingPath
        end
        if #deduped >= (ICONOS_UI_DEFAULTS.recentButtonsCount or 6) then
            break
        end
    end

    iconos.recentPaths = deduped
    updateRecentButtons(iconos)
end

local function selectIconPath(iconos, texturePath, addToRecent)
    setPathDisplay(iconos, texturePath)
    if addToRecent then
        pushRecentIcon(iconos, texturePath)
    end
end

local function createPaginationButton(parent, text)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(ICONOS_UI_DEFAULTS.pageButtonWidth, ICONOS_UI_DEFAULTS.pageButtonHeight)
    button:SetText(text)
    button:GetFontString():SetFontObject(GameFontNormalSmall)
    return button
end

local function createIconButton(parent, iconos, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ICONOS_ICON_SIZE, ICONOS_ICON_SIZE)
    button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints(button)
    button.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    button.bg:SetVertexColor(0.03, 0.03, 0.04, 0.92)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.icon:SetTexture(ICONOS_ICON_FALLBACK)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    button.border:SetVertexColor(0.45, 0.45, 0.48, 0.95)

    local column = (index - 1) % ICONOS_ICON_COLUMNS
    local row = math.floor((index - 1) / ICONOS_ICON_COLUMNS)
    local offsetX = ICONOS_UI_DEFAULTS.gridPaddingX + (column * ICONOS_ICON_SPACING_X)
    local offsetY = -ICONOS_UI_DEFAULTS.gridPaddingY - (row * ICONOS_ICON_SPACING_Y)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, offsetY)

    button:SetScript("OnEnter", function(self)
        if not self.texturePath or not GameTooltip then
            return
        end

        setPathDisplay(iconos, self.texturePath)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.shortName or "", 1, 1, 1, true)
        GameTooltip:AddLine(self.texturePath or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", function(self)
        selectIconPath(iconos, self.texturePath, true)
        if iconos and iconos.pathBox then
            iconos.pathBox:SetFocus()
            iconos.pathBox:HighlightText()
        end
    end)

    return button
end

local function updateIconButton(button, texturePath)
    if not button then
        return
    end

    if type(texturePath) ~= "string" or texturePath == "" then
        button.texturePath = nil
        button.shortName = nil
        button.icon:SetTexture(ICONOS_ICON_FALLBACK)
        button:Hide()
        return
    end

    button.texturePath = texturePath
    button.shortName = getIconosShortName(texturePath)
    button.icon:SetTexture(MultiBot.SafeTexturePath(texturePath))
    button:Show()
end

local function getIconosResultsLabel(totalCount, fromIndex, toIndex)
    local total = tonumber(totalCount) or 0
    if total <= 0 or not fromIndex or not toIndex then
        return "0/0"
    end

    return string.format("%d-%d / %d", fromIndex, toIndex, total)
end

local function getIconosEmptyStateText(iconos, iconCount)
    if (tonumber(iconCount) or 0) > 0 then
        return nil
    end

    local searchQuery = normalizeIconosSearchQuery(iconos and iconos.searchQuery)
    if searchQuery ~= "" then
        return "No icons match the current filter."
    end

    if not getIconosEntries() then
        return "Icon data is unavailable."
    end

    if (iconos and iconos.invalidEntryCount or 0) > 0 and (iconos.entrySourceCount or 0) <= (iconos.invalidEntryCount or 0) then
        return "Icon data is present but contains no usable entries."
    end

    return "No icons available."
end

local function updateIconosNavigation(iconos, iconCount)
    if not iconos then
        return
    end

    local pageCount = 0
    if tonumber(iconCount) and iconCount > 0 then
        pageCount = math.ceil(iconCount / ICONOS_PAGE_SIZE)
    end

    iconos.max = math.max(pageCount, 1)
    iconos.now = math.min(math.max(tonumber(iconos.now) or 1, 1), iconos.max)

    if iconos.pageLabel then
        local pageMax = (iconCount > 0) and iconos.max or 0
        local pageNow = (iconCount > 0) and iconos.now or 0
        iconos.pageLabel:SetText(getIconosPageLabel(pageNow, pageMax))
    end

    if iconos.resultsLabel then
        iconos.resultsLabel:SetText(getIconosResultsLabel(iconCount))
    end

    if iconos.prevButton then
        if iconCount > 0 and iconos.now > 1 then
            iconos.prevButton:Show()
        else
            iconos.prevButton:Hide()
        end
    end

    if iconos.nextButton then
        if iconCount > 0 and iconos.now < iconos.max then
            iconos.nextButton:Show()
        else
            iconos.nextButton:Hide()
        end
    end


    if iconos.allSearchModeButton then
        if (iconos.searchMode or "all") == "all" then
            iconos.allSearchModeButton:Disable()
        else
            iconos.allSearchModeButton:Enable()
        end
    end

    if iconos.pathSearchModeButton then
        if (iconos.searchMode or "all") == "path" then
            iconos.pathSearchModeButton:Disable()
        else
            iconos.pathSearchModeButton:Enable()
        end
    end
end

local function refreshIconosPage(iconos, requestedPage)
    if not iconos then
        return
    end

    if requestedPage ~= nil then
        iconos.now = requestedPage
    end

    local visibleEntries = getVisibleIconosEntries(iconos)
    local iconCount = visibleEntries and #visibleEntries or 0
    updateIconosNavigation(iconos, iconCount)

    local fromIndex = ((iconos.now or 1) - 1) * ICONOS_PAGE_SIZE + 1
    local toIndex = math.min(fromIndex + ICONOS_PAGE_SIZE - 1, iconCount)
    local visibleIndex = 1

    if iconCount > 0 then
        for dataIndex = fromIndex, toIndex do
            local button = iconos.iconButtons[visibleIndex]
            local entry = visibleEntries[dataIndex]
            updateIconButton(button, entry and entry.texturePath or nil)
            visibleIndex = visibleIndex + 1
        end
    end

    while visibleIndex <= #iconos.iconButtons do
        updateIconButton(iconos.iconButtons[visibleIndex], nil)
        visibleIndex = visibleIndex + 1
    end

    if iconos.resultsLabel then
        iconos.resultsLabel:SetText(getIconosResultsLabel(iconCount, (iconCount > 0) and fromIndex or nil, (iconCount > 0) and toIndex or nil))
    end

    if iconos.emptyStateLabel then
        local emptyStateText = getIconosEmptyStateText(iconos, iconCount)
        if emptyStateText then
            iconos.emptyStateLabel:SetText(emptyStateText)
            iconos.emptyStateLabel:Show()
        else
            iconos.emptyStateLabel:SetText("")
            iconos.emptyStateLabel:Hide()
        end
    end

    if iconCount <= 0 then
        setPathDisplay(iconos, "")
    elseif not iconos.selectedPath or iconos.selectedPath == "" then
        local firstEntry = visibleEntries[fromIndex]
        setPathDisplay(iconos, firstEntry and firstEntry.texturePath or "")
    end
end

local function createIconosContent(window, iconos)
    local content = window.content
    local inset = ICONOS_UI_DEFAULTS.panelInset

    local headerPanel = CreateFrame("Frame", nil, content)
    headerPanel:SetPoint("TOPLEFT", content, "TOPLEFT", inset, -inset)
    headerPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -inset, -inset)
    headerPanel:SetHeight(ICONOS_UI_DEFAULTS.topPanelHeight)
    addSimpleBackdrop(headerPanel, 0.90)

    local descriptionLabel = headerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descriptionLabel:SetPoint("TOPLEFT", headerPanel, "TOPLEFT", 10, -9)
    descriptionLabel:SetPoint("TOPRIGHT", headerPanel, "TOPRIGHT", -10, -9)
    descriptionLabel:SetPoint("BOTTOMLEFT", headerPanel, "BOTTOMLEFT", 10, 42)
    descriptionLabel:SetPoint("BOTTOMRIGHT", headerPanel, "BOTTOMRIGHT", -10, 42)
    descriptionLabel:SetJustifyH("LEFT")
    descriptionLabel:SetJustifyV("TOP")
    descriptionLabel:SetTextColor(0.82, 0.82, 0.82)
    descriptionLabel:SetText(getLocalizedDescription("tips.game.iconos", "Shows every icon and its file path."))

    local searchLabel = headerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("BOTTOMLEFT", headerPanel, "BOTTOMLEFT", 12, 14)
    searchLabel:SetText(SEARCH or "Search")

    local searchBox = CreateFrame("EditBox", nil, headerPanel, "InputBoxTemplate")
    searchBox:SetAutoFocus(false)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
    searchBox:SetSize(88, ICONOS_UI_DEFAULTS.pathBoxHeight)
    searchBox:SetFontObject(GameFontHighlightSmall)
    searchBox:SetTextInsets(8, 8, 0, 0)
    searchBox:SetText("")
    searchBox:SetCursorPosition(0)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput or not iconos.SetSearchQuery then
            return
        end

        iconos:SetSearchQuery(self:GetText())
    end)

    local allSearchModeButton = createPaginationButton(headerPanel, "ALL")
    allSearchModeButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    allSearchModeButton:SetWidth(34)

    local pathSearchModeButton = createPaginationButton(headerPanel, "PATH")
    pathSearchModeButton:SetPoint("LEFT", allSearchModeButton, "RIGHT", 4, 0)
    pathSearchModeButton:SetWidth(42)

    local resultsLabel = headerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultsLabel:SetPoint("LEFT", pathSearchModeButton, "RIGHT", 10, 0)
    resultsLabel:SetJustifyH("RIGHT")
    resultsLabel:SetText("0/0")

    local prevButton = createPaginationButton(headerPanel, "<")
    prevButton:SetPoint("BOTTOMRIGHT", headerPanel, "BOTTOMRIGHT", -82, 14)

    local nextButton = createPaginationButton(headerPanel, ">")
    nextButton:SetPoint("BOTTOMRIGHT", headerPanel, "BOTTOMRIGHT", -10, 14)

    resultsLabel:ClearAllPoints()
    resultsLabel:SetPoint("LEFT", prevButton, "RIGHT", 6, 0)
    resultsLabel:SetPoint("RIGHT", nextButton, "LEFT", -6, 0)
    resultsLabel:SetJustifyH("CENTER")

    local pageLabel = headerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pageLabel:SetPoint("RIGHT", prevButton, "LEFT", -8, 0)
    pageLabel:SetWidth(52)
    pageLabel:SetJustifyH("RIGHT")
    pageLabel:SetText(getIconosPageLabel(0, 0))

    local pathPanel = CreateFrame("Frame", nil, content)
    pathPanel:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", inset, inset)
    pathPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -inset, inset)
    pathPanel:SetHeight(ICONOS_UI_DEFAULTS.pathPanelHeight)
    addSimpleBackdrop(pathPanel, 0.90)

    local previewPanel = CreateFrame("Frame", nil, content)
    previewPanel:SetPoint("BOTTOMLEFT", pathPanel, "TOPLEFT", 0, inset)
    previewPanel:SetPoint("BOTTOMRIGHT", pathPanel, "TOPRIGHT", 0, inset)
    previewPanel:SetHeight(ICONOS_UI_DEFAULTS.previewPanelHeight)
    addSimpleBackdrop(previewPanel, 0.90)

    local previewIconHolder = CreateFrame("Frame", nil, previewPanel)
    previewIconHolder:SetPoint("LEFT", previewPanel, "LEFT", 10, 0)
    previewIconHolder:SetSize(ICONOS_UI_DEFAULTS.previewIconSize + 4, ICONOS_UI_DEFAULTS.previewIconSize + 4)
    addSimpleBackdrop(previewIconHolder, 0.96)

    local previewIcon = previewIconHolder:CreateTexture(nil, "ARTWORK")
    previewIcon:SetPoint("TOPLEFT", previewIconHolder, "TOPLEFT", 2, -2)
    previewIcon:SetPoint("BOTTOMRIGHT", previewIconHolder, "BOTTOMRIGHT", -2, 2)
    previewIcon:SetTexture(ICONOS_ICON_FALLBACK)

    local previewNameLabel = previewPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    previewNameLabel:SetPoint("LEFT", previewIconHolder, "RIGHT", 10, 0)
    previewNameLabel:SetPoint("RIGHT", previewPanel, "RIGHT", -(10 + (ICONOS_UI_DEFAULTS.recentButtonSpacing * ICONOS_UI_DEFAULTS.recentButtonsCount)), 0)
    previewNameLabel:SetJustifyH("LEFT")
    previewNameLabel:SetJustifyV("MIDDLE")
    previewNameLabel:SetText("")

    local recentButtons = {}
    for index = 1, ICONOS_UI_DEFAULTS.recentButtonsCount do
        local recentButton = CreateFrame("Button", nil, previewPanel)
        recentButton:SetSize(ICONOS_UI_DEFAULTS.recentButtonSize, ICONOS_UI_DEFAULTS.recentButtonSize)
        recentButton:SetPoint("RIGHT", previewPanel, "RIGHT", -10 - ((ICONOS_UI_DEFAULTS.recentButtonsCount - index) * ICONOS_UI_DEFAULTS.recentButtonSpacing), 0)
        recentButton:RegisterForClicks("LeftButtonUp")
        recentButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        recentButton:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

        recentButton.bg = recentButton:CreateTexture(nil, "BACKGROUND")
        recentButton.bg:SetAllPoints(recentButton)
        recentButton.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        recentButton.bg:SetVertexColor(0.03, 0.03, 0.04, 0.92)

        recentButton.icon = recentButton:CreateTexture(nil, "ARTWORK")
        recentButton.icon:SetPoint("TOPLEFT", recentButton, "TOPLEFT", 1, -1)
        recentButton.icon:SetPoint("BOTTOMRIGHT", recentButton, "BOTTOMRIGHT", -1, 1)
        recentButton.icon:SetTexture(ICONOS_ICON_FALLBACK)

        recentButton.border = recentButton:CreateTexture(nil, "OVERLAY")
        recentButton.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
        recentButton.border:SetPoint("TOPLEFT", recentButton, "TOPLEFT", -2, 2)
        recentButton.border:SetPoint("BOTTOMRIGHT", recentButton, "BOTTOMRIGHT", 2, -2)
        recentButton.border:SetVertexColor(0.45, 0.45, 0.48, 0.95)

        recentButton:SetScript("OnEnter", function(self)
            if not self.texturePath or not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.shortName or "", 1, 1, 1, true)
            GameTooltip:AddLine(self.texturePath or "", 1, 1, 1, true)
            GameTooltip:Show()
        end)

        recentButton:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        recentButton:SetScript("OnClick", function(self)
            if iconos.JumpToTexturePath then
                iconos:JumpToTexturePath(self.texturePath)
            else
                selectIconPath(iconos, self.texturePath, true)
            end
        end)

        recentButton:Hide()
        recentButtons[index] = recentButton
    end

    local pathBox = CreateFrame("EditBox", nil, pathPanel, "InputBoxTemplate")
    pathBox:SetAutoFocus(false)
    pathBox:SetPoint("TOPLEFT", pathPanel, "TOPLEFT", 10, -7)
    pathBox:SetPoint("BOTTOMRIGHT", pathPanel, "BOTTOMRIGHT", -10, 7)
    pathBox:SetHeight(ICONOS_UI_DEFAULTS.pathBoxHeight)
    pathBox:SetFontObject(GameFontHighlightSmall)
    pathBox:SetTextInsets(8, 8, 0, 0)
    pathBox:SetText("")
    pathBox:SetCursorPosition(0)
    hideEditBoxTemplateTextures(pathBox)
    pathBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    pathBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    pathBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(iconos.selectedPath or "")
            self:HighlightText()
        end
    end)

    local gridPanel = CreateFrame("Frame", nil, content)
    gridPanel:SetPoint("TOPLEFT", headerPanel, "BOTTOMLEFT", 0, -inset)
    gridPanel:SetPoint("BOTTOMRIGHT", previewPanel, "TOPRIGHT", 0, inset)
    addSimpleBackdrop(gridPanel, 0.95)

    local emptyStateLabel = gridPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyStateLabel:SetPoint("CENTER", gridPanel, "CENTER", 0, 0)
    emptyStateLabel:SetPoint("LEFT", gridPanel, "LEFT", 18, 0)
    emptyStateLabel:SetPoint("RIGHT", gridPanel, "RIGHT", -18, 0)
    emptyStateLabel:SetJustifyH("CENTER")
    emptyStateLabel:SetJustifyV("MIDDLE")
    emptyStateLabel:SetTextColor(0.82, 0.82, 0.82)
    emptyStateLabel:SetText("")
    emptyStateLabel:Hide()

    iconos.pageLabel = pageLabel
    iconos.resultsLabel = resultsLabel
    iconos.prevButton = prevButton
    iconos.nextButton = nextButton
    iconos.searchBox = searchBox
    iconos.allSearchModeButton = allSearchModeButton
    iconos.pathSearchModeButton = pathSearchModeButton
    iconos.pathBox = pathBox
    iconos.previewIcon = previewIcon
    iconos.previewNameLabel = previewNameLabel
    iconos.recentButtons = recentButtons
    iconos.emptyStateLabel = emptyStateLabel
    iconos.iconButtons = {}

    updateRecentButtons(iconos)

    for index = 1, ICONOS_PAGE_SIZE do
        iconos.iconButtons[index] = createIconButton(gridPanel, iconos, index)
    end

    prevButton:SetScript("OnClick", function()
        if iconos.SetPage then
            iconos:SetPage((iconos.now or 1) - 1)
        end
    end)

    nextButton:SetScript("OnClick", function()
        if iconos.SetPage then
            iconos:SetPage((iconos.now or 1) + 1)
        end
    end)


    allSearchModeButton:SetScript("OnClick", function()
        if iconos.SetSearchMode then
            iconos:SetSearchMode("all")
        end
    end)

    pathSearchModeButton:SetScript("OnClick", function()
        if iconos.SetSearchMode then
            iconos:SetSearchMode("path")
        end
    end)
end

function MultiBot.InitializeIconosFrame()
    if MultiBot.iconos and MultiBot.iconos.window and MultiBot.iconos.window.frame then
        return MultiBot.iconos
    end

    local aceGUI = getIconosAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Iconos", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(getLocalizedHeadline("tips.game.iconos", "Iconos"))
    window:SetStatusText("")
    window:SetWidth(ICONOS_UI_DEFAULTS.width)
    window:SetHeight(ICONOS_UI_DEFAULTS.height)
    window:SetLayout("Fill")
    window:EnableResize(false)
    window.frame:ClearAllPoints()
    window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", ICONOS_UI_DEFAULTS.pointX, ICONOS_UI_DEFAULTS.pointY)
    window.frame:Hide()
    window.frame:SetClampedToScreen(true)

    local iconos = {
        window = window,
        frame = window.frame,
        content = window.content,
        name = "Iconos",
        now = 1,
        max = 1,
        searchMode = "all",
        searchQuery = "",
        selectedPath = "",
        }

    createIconosContent(window, iconos)
    registerIconosEscapeClose(window, "Iconos")
    bindIconosWindowPosition(window)
    bindIconosMoveInteractions(window)

    function iconos:Refresh(page)
        refreshIconosPage(self, page)
    end

    function iconos:SetPage(page)
        local requestedPage = tonumber(page) or 1
        self.now = requestedPage
        self:Refresh()
    end

    function iconos:SetSearchQuery(query)
        self.searchQuery = normalizeIconosSearchQuery(query)
        self.now = 1
        self:Refresh()
    end

    function iconos:SetSearchMode(mode)
        local nextMode = (mode == "path") and "path" or "all"
        if self.searchMode == nextMode then
            self:Refresh()
            return
        end

        self.searchMode = nextMode
        self.now = 1
        self:Refresh()
    end

    function iconos:JumpToTexturePath(texturePath)
        if type(texturePath) ~= "string" or texturePath == "" then
            return
        end

        local visibleEntries = getVisibleIconosEntries(self)
        local matchedIndex
        for index, entry in ipairs(visibleEntries) do
            if entry.texturePath == texturePath then
                matchedIndex = index
                break
            end
        end

        if matchedIndex then
            self.now = math.floor((matchedIndex - 1) / ICONOS_PAGE_SIZE) + 1
            self:Refresh()
        end

        selectIconPath(self, texturePath, true)
    end


    function iconos:ShowWindow(page)
        if page ~= nil then
            self.now = tonumber(page) or self.now or 1
        end

        self.window.frame:Show()
        self:Refresh()
    end

    function iconos.setPoint(pointX, pointY)
        if not iconos.window or not iconos.window.frame then
            return
        end

        local offsetX = tonumber(pointX)
        local offsetY = tonumber(pointY)
        if not offsetX or not offsetY then
            return
        end

        iconos.window.frame:ClearAllPoints()
        iconos.window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", offsetX, offsetY)
        persistIconosWindowPosition(iconos.window.frame)
    end

    function iconos:HideWindow()
        hideIconosTooltip(self.window)
        self.window.frame:Hide()
    end

    function iconos:Toggle()
        if self.window.frame:IsShown() then
            self:HideWindow()
            return
        end

        self:ShowWindow()
    end

    function iconos:Hide()
        self:HideWindow()
    end

    function iconos:IsShown()
        return self.window.frame:IsShown()
    end

    function iconos:addIcons(page)
        if page ~= nil then
            self.now = tonumber(page) or self.now or 1
        end

        self:Refresh()
    end

    window:SetCallback("OnClose", function()
        iconos:HideWindow()
    end)

    MultiBot.iconos = iconos
    if iconos.searchBox then
        iconos.searchBox:SetText(iconos.searchQuery or "")
    end
    iconos:Refresh()
    return iconos
end