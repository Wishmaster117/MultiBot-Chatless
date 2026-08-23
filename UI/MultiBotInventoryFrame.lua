if not MultiBot then return end

local INVENTORY_WINDOW_DEFAULTS = {
    width = 520,
    height = 470,
    pointX = -700,
    pointY = -144,
    actionsWidth = 120,
    panelInset = 8,
    panelGap = 6,
    buttonSize = 32,
    buttonSpacing = 36,
    buttonOffsetX = 6,
    buttonStartOffsetY = 124,
    modeLabelHeight = 36,
    modeValueHeight = 20,
    instantActionsTopPadding = 18,
    instantActionColumns = 3,
    instantActionSpacingX = 36,
    instantActionSpacingY = 38,
    modeActionColumns = 2,
    modeActionSpacingX = 36,
    modeActionSpacingY = 36,
    summaryTopPadding = 10,
    summaryLineSpacing = 16,
    itemSize = 32,
    itemSpacingX = 38,
    itemSpacingY = 37,
    itemsPerRow = 8,
    itemsPanelPadding = 8,
    scrollBarAllowance = 28,
    minCanvasHeight = 260,
    containerBarHeight = 46,
    containerBarGap = 4,
    containerButtonSize = 32,
    containerButtonSpacing = 6,
    containerBarInset = 6,
    containerGroupHeaderHeight = 18,
    containerGroupPadding = 6,
    containerGroupGap = 8,
    containerGroupBackdropAlpha = 0.24,
}
local INVENTORY_LAYOUT_KEY = "InventoryPoint"

local ACTION_ORDER = { "Sell", "Equip", "Use", "Trade", "Bank", "GuildBank", "Buy", "Destroy" }
local ACTION_MODE_CONFIG = {
    Sell = { value = "s", cancelTradeOnActivate = true },
    Equip = { value = "e", cancelTradeOnActivate = true },
    Use = { value = "u", cancelTradeOnActivate = true },
    Trade = { value = "give", cancelTradeOnActivate = false },
    Bank = { value = "bank", cancelTradeOnActivate = true },
    GuildBank = { value = "gb", cancelTradeOnActivate = true },
    Buy = { value = "b", cancelTradeOnActivate = true },
    Destroy = { value = "destroy", cancelTradeOnActivate = true },
}

local TRADE_INVENTORY_DUMP_FILTER_TTL = 8

local function inventoryFrameNow()
    if GetTime then
        return GetTime()
    end

    return time and time() or 0
end

local function normalizeInventoryAuthorName(author)
    if type(author) ~= "string" then
        return ""
    end

    local name = author
    if Ambiguate then
        name = Ambiguate(author, "none") or author
    end

    name = string.match(name, "^[^-]+") or name
    return string.lower(name or "")
end

local function isTradeInventoryDumpStart(message)
    if type(message) ~= "string" then
        return false
    end

    return message == "=== Inventory ==="
        or message == "=== 背包 ==="
end

local function isKnownInventoryBotAuthor(author)
    local authorKey = normalizeInventoryAuthorName(author)
    if authorKey == "" then
        return false
    end

    local playerName = UnitName and UnitName("player") or nil
    if playerName and normalizeInventoryAuthorName(playerName) == authorKey then
        return false
    end

    local actives = MultiBot and MultiBot.index and MultiBot.index.actives or nil
    if type(actives) == "table" then
        for _, botName in pairs(actives) do
            if normalizeInventoryAuthorName(botName) == authorKey then
                return true
            end
        end
    end

    local units = MultiBot
        and MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]
    if units and type(units.frames) == "table" then
        for botName in pairs(units.frames) do
            if normalizeInventoryAuthorName(botName) == authorKey then
                return true
            end
        end
    end

    return false
end

local function isTradeInventoryDumpEnd(message)
    if type(message) ~= "string" then
        return false
    end

    return string.find(message, "Off with you", 1, true) ~= nil
        or string.find(message, "再见", 1, true) ~= nil
end

local function isTradeInventoryDumpBodyLine(message)
    if type(message) ~= "string" then
        return false
    end

    if string.find(message, "|Hitem:", 1, true) then
        return true
    end

    if string.find(message, "^%s*%-%-%-") then
        return true
    end

    if string.find(message, "%[.-%]") and (string.find(message, "x%d+") or string.find(message, "soulbound", 1, true)) then
        return true
    end

    return false
end

local function shouldSuppressTradeInventoryWhisper(message, author)
    local inventory = MultiBot and MultiBot.inventory or nil
    if not inventory then
        return false
    end

    local now = inventoryFrameNow()
    local authorKey = normalizeInventoryAuthorName(author)
    local state = inventory.tradeInventoryDumpFilter

    if type(state) == "table" and state.expiresAt and now > state.expiresAt then
        inventory.tradeInventoryDumpFilter = nil
        state = nil
    end

    if isTradeInventoryDumpStart(message) then
        if type(state) == "table" and authorKey == state.botKey then
            state.active = true
            return true
        end

        local tradePartner = UnitName and UnitName("NPC") or nil
        if isKnownInventoryBotAuthor(author)
            and tradePartner
            and authorKey == normalizeInventoryAuthorName(tradePartner)
            and TradeFrame
            and TradeFrame.IsShown
            and TradeFrame:IsShown()
        then
            inventory.tradeInventoryDumpFilter = {
                botKey = authorKey,
                expiresAt = now + TRADE_INVENTORY_DUMP_FILTER_TTL,
                active = true,
                autoDetected = true,
            }
            return true
        end

        return false
    end

    if type(state) ~= "table" or authorKey ~= state.botKey then
        return false
    end

    if not state.active then
        return false
    end

    if isTradeInventoryDumpEnd(message) then
        inventory.tradeInventoryDumpFilter = nil
        return true
    end

    if isTradeInventoryDumpBodyLine(message) then
        return true
    end

    return false
end

local function ensureTradeInventoryDumpFilter()
    if MultiBot._inventoryTradeDumpFilterInstalled then
        return true
    end

    if type(ChatFrame_AddMessageEventFilter) ~= "function" then
        return false
    end

    MultiBot._inventoryTradeDumpFilterInstalled = true
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, _, message, author, ...)
        if shouldSuppressTradeInventoryWhisper(message, author) then
            return true
        end

        return false
    end)

    return true
end

local function suppressNextTradeInventoryDump(botName)
    if not botName or botName == "" then
        return
    end

    if not (MultiBot.bridge and MultiBot.bridge.connected) then
        return
    end

    if not ensureTradeInventoryDumpFilter() then
        return
    end

    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    inventory.tradeInventoryDumpFilter = {
        botKey = normalizeInventoryAuthorName(botName),
        expiresAt = inventoryFrameNow() + TRADE_INVENTORY_DUMP_FILTER_TTL,
        active = false,
    }
end

MultiBot.SuppressNextTradeInventoryDump = suppressNextTradeInventoryDump

local function clearTradeInventoryDumpFilter()
    if MultiBot.inventory then
        MultiBot.inventory.tradeInventoryDumpFilter = nil
    end
end

local function getInventoryAceGUI()
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

local inventoryEscapeIndex = 0
local function registerInventoryEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    inventoryEscapeIndex = inventoryEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Inventory"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, inventoryEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function persistInventoryWindowPosition(frame)
    if not frame or not MultiBot.SetSavedLayoutValue or not MultiBot.toPoint then
        return
    end

    local offsetX, offsetY = MultiBot.toPoint(frame)
    MultiBot.SetSavedLayoutValue(INVENTORY_LAYOUT_KEY, offsetX .. ", " .. offsetY)
end

local function bindInventoryWindowPosition(window)
    if not window or not window.frame then
        return
    end

    local savedPoint = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(INVENTORY_LAYOUT_KEY) or nil
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
        persistInventoryWindowPosition(frame)
    end)
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

local function makeActionButton(parent, key, iconTexture, tooltipText, yOffset, xOffset)
    local size = INVENTORY_WINDOW_DEFAULTS.buttonSize
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset or INVENTORY_WINDOW_DEFAULTS.buttonOffsetX, yOffset)
    button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(MultiBot.SafeTexturePath(iconTexture))

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    button.border:Hide()

    button.state = false
    button.tip = tooltipText
    button.parent = parent.inventoryRef
    button.actionKey = key

    function button.setDisable(_)
        button.state = false
        if button.icon and button.icon.SetDesaturated then
            button.icon:SetDesaturated(true)
        end
        if button.border then
            button.border:Hide()
        end
        return button
    end

    function button.setEnable(_)
        button.state = true
        if button.icon and button.icon.SetDesaturated then
            button.icon:SetDesaturated(false)
        end
        if button.border then
            button.border:Show()
        end
        return button
    end

    function button.getButton(_, index)
        return button.parent and button.parent.getButton and button.parent.getButton(index) or nil
    end

    function button.getName()
        return MultiBot.inventory and MultiBot.inventory.name or nil
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

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and self.doLeft then
            self.doLeft(self)
            return
        end

        if mouseButton == "RightButton" and self.doRight then
            self.doRight(self)
        end
    end)

    return button
end

local function makeItemsContainer(parent, scrollChild)
    local items = {
        host = parent,
        child = scrollChild,
        buttons = {},
        itemButtonPool = {},
        emptySlotButtonPool = {},
        index = 0,
        iconSize = INVENTORY_WINDOW_DEFAULTS.itemSize,
        spacingX = INVENTORY_WINDOW_DEFAULTS.itemSpacingX,
        spacingY = INVENTORY_WINDOW_DEFAULTS.itemSpacingY,
        itemsPerRow = INVENTORY_WINDOW_DEFAULTS.itemsPerRow,
        suspendLayout = false,
        visualGroups = {},
        visualGroupFrames = {},
        groupedContentHeight = nil,
    }

    function items:getName()
        return MultiBot.inventory and MultiBot.inventory.name or nil
    end

    function items:get()
        return MultiBot.inventory
    end

    function items.getButton(index)
        return MultiBot.inventory and MultiBot.inventory.getButton and MultiBot.inventory.getButton(index) or nil
    end

    function items:getAvailableWidth()
        local hostWidth = self.host and self.host.GetWidth and self.host:GetWidth() or 0
        local horizontalPadding = (INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding * 2) + INVENTORY_WINDOW_DEFAULTS.scrollBarAllowance
        return math.max(self.iconSize, hostWidth - horizontalPadding)
    end

    function items:refreshLayoutMetrics()
        local stepX = math.max(self.iconSize, self.spacingX or self.iconSize)
        local usableWidth = self:getAvailableWidth()
        local additionalSlots = math.floor(math.max(0, usableWidth - self.iconSize) / stepX)
        self.itemsPerRow = math.max(1, additionalSlots + 1)
        self.child:SetWidth(math.max(usableWidth, self.itemsPerRow * stepX))
    end

    function items:getSlotPosition(layoutIndex)
        self:refreshLayoutMetrics()
        local perRow = math.max(1, self.itemsPerRow or 1)
        local index = math.max(0, tonumber(layoutIndex or 0) or 0)
        local posX = (index % perRow) * (self.spacingX or 0)
        local posY = math.floor(index / perRow) * -(self.spacingY or 0)
        return posX, posY
    end

    function items:getNextSlotPosition()
        return self:getSlotPosition(self.index or 0)
    end

    function items:clearVisualGroups()
        for _, frame in pairs(self.visualGroupFrames or {}) do
            if frame and frame.Hide then
                frame:Hide()
            end
        end
        self.visualGroups = {}
        self.groupedContentHeight = nil
    end

    function items:getOrCreateVisualGroupFrame(groupKey)
        if not groupKey or groupKey == "" then
            return nil
        end

        self.visualGroupFrames = self.visualGroupFrames or {}
        local frame = self.visualGroupFrames[groupKey]
        if frame then
            return frame
        end

        frame = CreateFrame("Frame", nil, self.child)
        frame:EnableMouse(false)
        addSimpleBackdrop(frame, INVENTORY_WINDOW_DEFAULTS.containerGroupBackdropAlpha)
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.92)
        end
        if frame.SetFrameLevel and self.child and self.child.GetFrameLevel then
            frame:SetFrameLevel((self.child:GetFrameLevel() or 0) + 1)
        end

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
        frame.title:SetJustifyH("LEFT")
        frame.title:SetText("")

        self.visualGroupFrames[groupKey] = frame
        return frame
    end

    function items:setVisualGroups(groups)
        self:clearVisualGroups()
        self.visualGroups = groups or {}

        for _, group in ipairs(self.visualGroups) do
            if group.decorated ~= false and group.key then
                local frame = self:getOrCreateVisualGroupFrame(group.key)
                group.frame = frame
                if frame then
                    if frame.title then
                        frame.title:SetText(group.label or "")
                    end
                    frame:Show()
                end
            end
        end
    end

    function items:assignButtonToVisualGroup(button, groupKey, localIndex)
        if not button then
            return
        end
        button.__mbVisualGroupKey = groupKey
        button.__mbVisualGroupIndex = math.max(0, tonumber(localIndex or 0) or 0)
    end

    function items:addChatItem(itemInfo)
        if not itemInfo or itemInfo == "" or not MultiBot.InventoryAddItem then
            return nil
        end

        return MultiBot.InventoryAddItem(self, itemInfo)
    end

    function items:createItemButton()
        local button = CreateFrame("Button", nil, self.child)
        button.__mbInventoryButtonKind = "ITEM"
        button:SetSize(self.iconSize, self.iconSize)
        if button.SetFrameLevel and self.child and self.child.GetFrameLevel then
            button:SetFrameLevel((self.child:GetFrameLevel() or 0) + 2)
        end
        button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints(button)

        button.border = button:CreateTexture(nil, "OVERLAY")
        button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
        button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
        button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)

        function button.setAmount(pAmount)
            if not button.amount then
                button.amount = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                button.amount:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 1)
            end
            button.amount:SetText(pAmount)
            button.amount:Show()
            return button
        end

        function button.getButton(_, index)
            return button.parent and button.parent.getButton and button.parent.getButton(index) or nil
        end

        function button.getName()
            return items:getName()
        end

        button:SetScript("OnEnter", function(widget)
            if not widget.tip or not GameTooltip then return end
            GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
            if type(widget.tip) == "string" and string.sub(widget.tip, 1, 1) == "|" then
                GameTooltip:SetHyperlink(widget.tip)
            else
                GameTooltip:SetText(widget.tip, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        button:SetScript("OnClick", function(widget, mouseButton)
            if mouseButton == "LeftButton" and widget.__mbSuppressNextLeftClick then
                return
            end

            if mouseButton == "LeftButton" and widget.doLeft then
                widget.doLeft(widget)
                return
            end

            if mouseButton == "RightButton" and widget.doRight then
                widget.doRight(widget)
            end
        end)

        return button
    end

    function items:createEmptySlotButton()
        local button = CreateFrame("Button", nil, self.child)
        button.__mbInventoryButtonKind = "EMPTY"
        button:SetSize(self.iconSize, self.iconSize)
        if button.SetFrameLevel and self.child and self.child.GetFrameLevel then
            button:SetFrameLevel((self.child:GetFrameLevel() or 0) + 2)
        end
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        addSimpleBackdrop(button, 0.42)
        return button
    end

    function items:releaseButton(button)
        if not button then
            return
        end

        button:Hide()
        button:EnableMouse(false)
        button:SetScript("OnDragStart", nil)
        button:SetScript("OnDragStop", nil)
        if button.ClearAllPoints then
            button:ClearAllPoints()
        end
        if button.SetAlpha then
            button:SetAlpha(1.0)
        end
        if button.amount then
            button.amount:SetText("")
            button.amount:Hide()
        end

        button.parent = nil
        button.name = nil
        button.tip = nil
        button.texture = nil
        button.item = nil
        button.emptySlot = nil
        button.layoutIndex = nil
        button.x = nil
        button.y = nil
        button.doLeft = nil
        button.doRight = nil
        button.__mbExactSlot = nil
        button.__mbVisualGroupKey = nil
        button.__mbVisualGroupIndex = nil
        button.__mbSuppressNextLeftClick = nil

        if button.__mbInventoryButtonKind == "ITEM" then
            table.insert(self.itemButtonPool, button)
        elseif button.__mbInventoryButtonKind == "EMPTY" then
            table.insert(self.emptySlotButtonPool, button)
        end
    end

    function items:acquireItemButton()
        local button = table.remove(self.itemButtonPool)
        if not button then
            button = self:createItemButton()
        end

        button.__mbInventoryButtonKind = "ITEM"
        button.parent = self
        button:SetSize(self.iconSize, self.iconSize)
        button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        button:EnableMouse(true)
        button:SetScript("OnDragStart", nil)
        button:SetScript("OnDragStop", nil)
        if button.SetAlpha then
            button:SetAlpha(1.0)
        end
        if button.amount then
            button.amount:SetText("")
            button.amount:Hide()
        end
        if button.icon and button.icon.Show then
            button.icon:Show()
        end
        if button.border and button.border.Show then
            button.border:Show()
        end
        return button
    end

    function items:acquireEmptySlotButton()
        local button = table.remove(self.emptySlotButtonPool)
        if not button then
            button = self:createEmptySlotButton()
        end

        button.__mbInventoryButtonKind = "EMPTY"
        button:SetSize(self.iconSize, self.iconSize)
        button:SetScript("OnDragStart", nil)
        button:SetScript("OnDragStop", nil)
        if button.SetAlpha then
            button:SetAlpha(1.0)
        end
        return button
    end

    function items:clear()
        self:clearVisualGroups()
        for key, button in pairs(self.buttons) do
            self:releaseButton(button)
            self.buttons[key] = nil
        end
        self.index = 0
        self:updateCanvas()
    end

    function items:updateCanvas()
        self:refreshLayoutMetrics()

        if self.groupedContentHeight then
            self.child:SetHeight(math.max(INVENTORY_WINDOW_DEFAULTS.minCanvasHeight, self.groupedContentHeight))
            return
        end

        local count = math.max(self.index or 0, 0)
        if count == 0 then
            for _ in pairs(self.buttons) do
                count = count + 1
            end
        end

        local rows = math.max(1, math.ceil(count / math.max(1, self.itemsPerRow or 1)))
        local height = math.max(INVENTORY_WINDOW_DEFAULTS.minCanvasHeight, 20 + (rows * self.spacingY))
        self.child:SetHeight(height)
    end

    function items:updateLayout()
        self:refreshLayoutMetrics()

        local groups = self.visualGroups or {}
        if #groups > 0 then
            local perRow = math.max(1, self.itemsPerRow or 1)
            local spacingX = self.spacingX or self.iconSize
            local spacingY = self.spacingY or self.iconSize
            local padding = INVENTORY_WINDOW_DEFAULTS.containerGroupPadding
            local headerHeight = INVENTORY_WINDOW_DEFAULTS.containerGroupHeaderHeight
            local gap = INVENTORY_WINDOW_DEFAULTS.containerGroupGap
            local cursorY = 0
            local groupedButtons = {}

            for _, button in pairs(self.buttons) do
                if button and button.__mbVisualGroupKey then
                    local key = button.__mbVisualGroupKey
                    groupedButtons[key] = groupedButtons[key] or {}
                    table.insert(groupedButtons[key], button)
                end
            end

            for _, group in ipairs(groups) do
                local slotCount = math.max(0, tonumber(group.slotCount or 0) or 0)
                local decorated = group.decorated ~= false
                local groupHeaderHeight = decorated and headerHeight or 0
                local groupPadding = decorated and padding or 0
                local rows = slotCount > 0 and math.ceil(slotCount / perRow) or 0
                local itemAreaHeight = rows > 0 and (((rows - 1) * spacingY) + self.iconSize) or 0
                local groupHeight = groupHeaderHeight + groupPadding + itemAreaHeight + groupPadding
                local itemTopY = cursorY + groupHeaderHeight + groupPadding

                if group.frame then
                    group.frame:ClearAllPoints()
                    group.frame:SetPoint("TOPLEFT", self.child, "TOPLEFT", 0, -cursorY)
                    group.frame:SetWidth(self:getAvailableWidth())
                    group.frame:SetHeight(math.max(1, groupHeight))
                    group.frame:Show()
                end

                for _, button in ipairs(groupedButtons[group.key] or {}) do
                    if button and button.ClearAllPoints then
                        local localIndex = math.max(0, tonumber(button.__mbVisualGroupIndex or 0) or 0)
                        local posX = groupPadding + ((localIndex % perRow) * spacingX)
                        local posY = -(itemTopY + (math.floor(localIndex / perRow) * spacingY))
                        button:ClearAllPoints()
                        button:SetPoint("TOPLEFT", self.child, "TOPLEFT", posX, posY)
                        button.x = posX
                        button.y = posY
                    end
                end

                cursorY = cursorY + groupHeight + (decorated and gap or 0)
            end

            local ungroupedIndex = 0
            for _, button in pairs(self.buttons) do
                if button and not button.__mbVisualGroupKey and button.ClearAllPoints then
                    local posX = (ungroupedIndex % perRow) * spacingX
                    local posY = -(cursorY + (math.floor(ungroupedIndex / perRow) * spacingY))
                    button:ClearAllPoints()
                    button:SetPoint("TOPLEFT", self.child, "TOPLEFT", posX, posY)
                    button.x = posX
                    button.y = posY
                    ungroupedIndex = ungroupedIndex + 1
                end
            end

            if ungroupedIndex > 0 then
                local ungroupedRows = math.ceil(ungroupedIndex / perRow)
                cursorY = cursorY + (((ungroupedRows - 1) * spacingY) + self.iconSize)
            end

            self.groupedContentHeight = cursorY + 4
            self:updateCanvas()
            return
        end

        self.groupedContentHeight = nil
        for _, button in pairs(self.buttons) do
            if button and button.ClearAllPoints then
                local layoutIndex = button.layoutIndex or 0
                local posX = (layoutIndex % self.itemsPerRow) * (self.spacingX or 0)
                local posY = math.floor(layoutIndex / self.itemsPerRow) * -(self.spacingY or 0)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.child, "TOPLEFT", posX, posY)
                button.x = posX
                button.y = posY
            end
        end

        self:updateCanvas()
    end

    function items.addButton(pName, pX, pY, pTexture, pTip, pLayoutIndex)
        local button = items:acquireItemButton()
        local safeTexture = MultiBot.SafeTexturePath(pTexture)

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", items.child, "TOPLEFT", pX, pY)
        if button.SetFrameLevel and items.child and items.child.GetFrameLevel then
            button:SetFrameLevel((items.child:GetFrameLevel() or 0) + 2)
        end
        button.icon:SetTexture(safeTexture)

        button.parent = items
        button.name = pName
        button.tip = pTip
        button.texture = safeTexture
        button.size = items.iconSize
        button.layoutIndex = math.max(0, tonumber(pLayoutIndex or items.index or 0) or 0)
        button.x = pX
        button.y = pY
        button:Show()

        items.buttons[pName] = button
        if not items.suspendLayout then
            items:updateLayout()
        end
        return button
    end

    function items:addEmptySlot(layoutIndex, slotKey, exactSlot)
        local index = math.max(0, tonumber(layoutIndex or 0) or 0)
        local key = slotKey or ("Empty_" .. tostring(index))
        local posX, posY = self:getSlotPosition(index)
        local button = self:acquireEmptySlotButton()

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.child, "TOPLEFT", posX, posY)
        if button.SetFrameLevel and self.child and self.child.GetFrameLevel then
            button:SetFrameLevel((self.child:GetFrameLevel() or 0) + 2)
        end
        button.layoutIndex = index
        button.x = posX
        button.y = posY
        button.emptySlot = true
        button.__mbExactSlot = exactSlot

        local moveCapable = exactSlot and MultiBot.Comm and MultiBot.Comm.IsInventoryItemMoveCapable and
            MultiBot.Comm.IsInventoryItemMoveCapable()
        button:EnableMouse(moveCapable and true or false)
        button:Show()

        self.buttons[key] = button
        if not self.suspendLayout then
            self:updateLayout()
        end
        return button
    end

    return items
end

local function getInventoryContainerFallbackTexture(kind)
    if kind == "BACKPACK" then
        return "Interface\\Buttons\\Button-Backpack-Up"
    end

    if kind == "KEYRING" then
        return "Interface\\Buttons\\UI-Button-KeyRing"
    end

    return MultiBot.SafeTexturePath("inv_misc_bag_10")
end

local function configureInventoryContainerIcon(button, kind)
    if not button or not button.icon then
        return
    end

    button.icon:ClearAllPoints()

    if kind == "KEYRING" then
        button.icon:SetSize(13, 28)
        button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.icon:SetTexCoord(0, 0.5625, 0, 0.609375)
        return
    end

    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0, 1, 0, 1)
end

local function getInventoryContainerLabel(kind, bagIndex)
    if kind == "BACKPACK" then
        return (BACKPACK_TOOLTIP and tostring(BACKPACK_TOOLTIP))
            or MultiBot.L("inventory.container.backpack", "Backpack")
    end

    if kind == "KEYRING" then
        return (KEYRING and tostring(KEYRING))
            or MultiBot.L("inventory.container.keyring", "Keyring")
    end

    return string.format(MultiBot.L("inventory.container.bag", "Bag %d"), tonumber(bagIndex or 1) or 1)
end

local function buildInventoryContainerKey(entry)
    if type(entry) ~= "table" then
        return nil
    end

    return table.concat({
        tostring(entry.kind or ""),
        tostring(tonumber(entry.bag or 0) or 0),
        tostring(tonumber(entry.slotStart or 0) or 0),
    }, ":")
end

local function getInventoryContainerSnapshotLabel(inventory, entry)
    local containerKey = buildInventoryContainerKey(entry)
    for _, button in pairs(inventory and inventory.containerButtons or {}) do
        if button and button.containerKey == containerKey and button.definition and button.definition.label then
            return button.definition.label
        end
    end

    if entry and entry.kind == "BACKPACK" then
        return getInventoryContainerLabel("BACKPACK")
    end
    if entry and entry.kind == "KEYRING" then
        return getInventoryContainerLabel("KEYRING")
    end

    return string.format(
        MultiBot.L("inventory.container.bag", "Bag %d"),
        tonumber(entry and entry.bag or 0) or 0
    )
end

local function createInventoryContainerBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", INVENTORY_WINDOW_DEFAULTS.containerBarInset, INVENTORY_WINDOW_DEFAULTS.containerBarInset)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -INVENTORY_WINDOW_DEFAULTS.containerBarInset, INVENTORY_WINDOW_DEFAULTS.containerBarInset)
    bar:SetHeight(INVENTORY_WINDOW_DEFAULTS.containerBarHeight)
    addSimpleBackdrop(bar, 0.62)

    local buttonSize = INVENTORY_WINDOW_DEFAULTS.containerButtonSize
    local spacing = INVENTORY_WINDOW_DEFAULTS.containerButtonSpacing
    local totalWidth = (buttonSize * 6) + (spacing * 5)
    local buttons = {}
    local definitions = {
        { key = "Backpack", kind = "BACKPACK", label = getInventoryContainerLabel("BACKPACK") },
        { key = "Bag1", kind = "BAG", bagIndex = 1, label = getInventoryContainerLabel("BAG", 1) },
        { key = "Bag2", kind = "BAG", bagIndex = 2, label = getInventoryContainerLabel("BAG", 2) },
        { key = "Bag3", kind = "BAG", bagIndex = 3, label = getInventoryContainerLabel("BAG", 3) },
        { key = "Bag4", kind = "BAG", bagIndex = 4, label = getInventoryContainerLabel("BAG", 4) },
        { key = "Keyring", kind = "KEYRING", label = getInventoryContainerLabel("KEYRING") },
    }

    for index, definition in ipairs(definitions) do
        local button = CreateFrame("Button", nil, bar)
        button:SetSize(buttonSize, buttonSize)
        button:SetPoint(
            "LEFT",
            bar,
            "CENTER",
            -(totalWidth / 2) + ((index - 1) * (buttonSize + spacing)),
            0
        )
        button:RegisterForClicks("LeftButtonUp")
        if definition.kind ~= "KEYRING" then
            button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
            addSimpleBackdrop(button, 0.38)
        end

        button.icon = button:CreateTexture(nil, "ARTWORK")
        configureInventoryContainerIcon(button, definition.kind)

        button.selectedOverlay = button:CreateTexture(nil, "OVERLAY")
        if definition.kind == "KEYRING" then
            button.selectedOverlay:SetSize(13, 28)
            button.selectedOverlay:SetPoint("CENTER", button, "CENTER", 0, 0)
            button.selectedOverlay:SetTexture("Interface\\Buttons\\UI-Button-KeyRing")
            button.selectedOverlay:SetTexCoord(0, 0.5625, 0, 0.609375)
        else
            button.selectedOverlay:SetAllPoints(button)
            button.selectedOverlay:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        end
        button.selectedOverlay:SetBlendMode("ADD")
        button.selectedOverlay:SetAlpha(0.70)
        button.selectedOverlay:Hide()

        button.definition = definition
        button.containerKey = nil
        button.containerEntry = nil
        button.tip = definition.label

        local fallback = getInventoryContainerFallbackTexture(definition.kind)
        button.defaultTexture = fallback
        button.icon:SetTexture(fallback)
        button.icon:SetAlpha(0.30)
        button:Disable()

        button:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tip or self.definition.label or "", 1, 1, 1, true)
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        button:SetScript("OnClick", function(self)
            local inventory = MultiBot.inventory
            if inventory and inventory.toggleContainerFilter and self.containerKey then
                inventory:toggleContainerFilter(self.containerKey)
            end
        end)

        buttons[definition.key] = button
    end

    return bar, buttons
end

local function updateModeLabel()
    local inventory = MultiBot.inventory
    if not inventory or not inventory.modeLabel then
        return
    end

    local actionLabel = MultiBot.L("info.action", "Action")
    local actionValues = {
        [""] = "-",
        s = "Sell",
        e = "Equip",
        u = "Use",
        give = "Trade",
        bank = MultiBot.L("inventory.mode.bank", "Bank"),
        gb = MultiBot.L("inventory.mode.gbank", "Guild Bank"),
        b = MultiBot.L("inventory.mode.buy", "Buy"),
        destroy = "Destroy",
    }

    inventory.modeLabel:SetText(actionLabel .. ":")
    if inventory.modeValueLabel then
        inventory.modeValueLabel:SetText(actionValues[inventory.action or ""] or "-")
    end
end

local function formatMoneyLabel(gold, silver, copper)
    local g = tonumber(gold) or 0
    local moneyLabel = MultiBot.L("info.inventory.money_label", "Money")
    return string.format("|cffffff00%s:|r %d|cffffd700g|r", moneyLabel, g)
end

local function formatBagSlotsLabel(used, total)
    local usedSlots = tonumber(used)
    local totalSlots = tonumber(total)
    local bagSlotsLabel = MultiBot.L("info.inventory.bag_slots_label", "Bag Slots")
    if not usedSlots or not totalSlots then
        return string.format("|cffffff00%s:|r -/-", bagSlotsLabel)
    end

    return string.format("|cffffff00%s:|r %d/%d", bagSlotsLabel, usedSlots, totalSlots)
end

local function parseInventorySummaryLine(rawLine)
    local line = tostring(rawLine or "")
    if line == "" then
        return nil
    end

    local function escapeLuaPattern(value)
        return tostring(value or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    end

    local function resolveBagPair()
        local markerCandidates = {
            "Bag",
            MultiBot.L("info.shorts.bag", "Bag"),
            "背包",
        }
        local seen = {}

        for _, marker in ipairs(markerCandidates) do
            local token = tostring(marker or "")
            local lowered = string.lower(token)
            if token ~= "" and not seen[lowered] then
                seen[lowered] = true
                local usedToken, totalToken = string.match(line, escapeLuaPattern(token) .. "[^%d]*(%d+)%s*/%s*(%d+)")
                local usedValue = tonumber(usedToken)
                local totalValue = tonumber(totalToken)
                if usedValue and totalValue and usedValue <= totalValue then
                    return usedValue, totalValue
                end
            end
        end

        local bestUsed, bestTotal
        for usedToken, totalToken in string.gmatch(line, "(%d+)%s*/%s*(%d+)") do
            local usedValue = tonumber(usedToken)
            local totalValue = tonumber(totalToken)
            if usedValue and totalValue and usedValue <= totalValue then
                if not bestUsed or usedValue > bestUsed then
                    bestUsed, bestTotal = usedValue, totalValue
                end
            end
        end

        return bestUsed, bestTotal
    end

    local used, total = resolveBagPair()

    local gold = string.match(line, "(%d+)%s*[gG]%f[%A]")
        or string.match(string.lower(line), "(%d+)%s*gold%f[%A]")
        or string.match(line, "(%d+)%s*金")
    local silver = string.match(line, "(%d+)%s*[sS]%f[%A]")
        or string.match(string.lower(line), "(%d+)%s*silver%f[%A]")
        or string.match(line, "(%d+)%s*银")
    local copper = string.match(line, "(%d+)%s*[cC]%f[%A]")
        or string.match(string.lower(line), "(%d+)%s*copper%f[%A]")
        or string.match(line, "(%d+)%s*铜")

    if not used and not total and not gold and not silver and not copper then
        return nil
    end

    return {
        bagUsed = tonumber(used),
        bagTotal = tonumber(total),
        gold = tonumber(gold) or 0,
        silver = tonumber(silver) or 0,
        copper = tonumber(copper) or 0,
    }
end

local function updateInventorySummaryLabels(inventory)
    if not inventory then
        return
    end

    local summary = inventory.summary or {}

    if inventory.moneyLabel then
        inventory.moneyLabel:SetText(formatMoneyLabel(summary.gold, summary.silver, summary.copper))
    end

    if inventory.bagSlotsLabel then
        inventory.bagSlotsLabel:SetText(formatBagSlotsLabel(summary.bagUsed, summary.bagTotal))
    end
end

local function getInventoryWindowTitle(botName)
    local defaultTitle = MB_INVENTORY_LABEL or INVENTORY_TOOLTIP or BAGSLOT or "Inventory"
    if not botName or botName == "" then
        return defaultTitle
    end

    return MultiBot.doReplace(MultiBot.L("info.inventory", defaultTitle), "NAME", botName)
end

local function disableActionModes(exceptKey)
    local inventory = MultiBot.inventory
    if not inventory or not inventory.buttons then
        return
    end

    for _, key in ipairs(ACTION_ORDER) do
        if key ~= exceptKey then
            local button = inventory.buttons[key]
            if button and button.setDisable then
                button.setDisable()
            end
        end
    end
end

local function syncInventoryButtonState(enabled)
    local inventory = MultiBot.inventory
    if not inventory or not inventory.name then
        return
    end

    local units = MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]

    local unitFrame = units and units.frames and units.frames[inventory.name] or nil
    local sourceButton = unitFrame and unitFrame.getButton and unitFrame.getButton("Inventory") or nil
    if not sourceButton then
        return
    end

    if enabled then
        if sourceButton.setEnable then sourceButton.setEnable() end
    else
        if sourceButton.setDisable then sourceButton.setDisable() end
    end
end

local function getInventoryUnitsFrame()
    return MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]
        or nil
end

local function getInventorySourceButton(botName)
    if not botName or botName == "" then
        return nil
    end

    local units = getInventoryUnitsFrame()
    local unitFrame = units and units.frames and units.frames[botName] or nil
    return unitFrame and unitFrame.getButton and unitFrame.getButton("Inventory") or nil
end

local function getInventoryWaitButton(botName)
    if not botName or botName == "" then
        return nil
    end

    local units = getInventoryUnitsFrame()
    return units and units.buttons and units.buttons[botName] or nil
end

local function disableOtherInventoryButtons(activeBotName)
    local units = getInventoryUnitsFrame()
    if not units or not MultiBot.index or not MultiBot.index.actives then
        return
    end

    for _, botName in pairs(MultiBot.index.actives) do
        if botName ~= UnitName("player") then
            local button = units.frames
                and units.frames[botName]
                and units.frames[botName].getButton
                and units.frames[botName].getButton("Inventory")
                or nil

            if button and button.setDisable and botName ~= activeBotName then
                button.setDisable()
            end
        end
    end
end

local function setInventoryBotName(botName)
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    inventory.name = botName or ""

    if MultiBot.inventoryBuybackFrame and MultiBot.inventoryBuybackFrame.botName ~= "" and
        MultiBot.inventoryBuybackFrame.botName ~= inventory.name then
        MultiBot.inventoryBuybackFrame:Hide()
    end

    if inventory.window and inventory.window.SetTitle then
        inventory.window:SetTitle(getInventoryWindowTitle(inventory.name))
    end

end

local function resetInventoryViewState()
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    setInventoryBotName("")
    inventory.pendingLootBot = nil

    if inventory.resetExactViewState then
        inventory:resetExactViewState()
    elseif inventory.resetItems then
        inventory:resetItems()
    end
end

local function requestInventoryForBot(botName)
    if not botName or botName == "" or not MultiBot.RequestInventoryRefresh then
        return false
    end

    return MultiBot.RequestInventoryRefresh(botName)
end

MultiBot.RequestBotInventory = function(botName)
    if not botName or botName == "" then
        return false
    end

    local inventory = MultiBot.inventory
    if (not inventory or not inventory.requestBotInventory) and MultiBot.InitializeInventoryFrame then
        inventory = MultiBot.InitializeInventoryFrame()
    end

    if inventory and inventory.requestBotInventory then
        return inventory:requestBotInventory(botName)
    end

    return requestInventoryForBot(botName)
end

local function closeInventoryWindow()
    local inventory = MultiBot.inventory
    if not inventory then return end
    if inventory.window then
        inventory.window:Hide()
    end
    if MultiBot.inventoryBuybackFrame then
        MultiBot.inventoryBuybackFrame:Hide()
    end
    syncInventoryButtonState(false)
    resetInventoryViewState()
end

local function openInventoryWindow()
    local inventory = MultiBot.inventory
    if inventory and inventory.window then
        inventory.window:Show()
        syncInventoryButtonState(true)
    end
end

local function openInspectForInventoryBot(botName)
    if not botName or botName == "" then
        return false
    end

    if not MultiBot.toUnit then
        return false
    end

    local unit = MultiBot.toUnit(botName)
    if not unit or not UnitExists(unit) then
        return false
    end

    if not InspectFrame and LoadAddOn then
        pcall(LoadAddOn, "Blizzard_InspectUI")
    end

    if not InspectUnit then
        return false
    end

    InspectUnit(unit)

    if InspectFrame and ShowUIPanel and not InspectFrame:IsShown() then
        ShowUIPanel(InspectFrame)
    end

    return true
end

local function prepareInventoryForBot(botName)
    if not botName or botName == "" then
        return false
    end

    local inventory = MultiBot and MultiBot.inventory or nil
    local previousBotName = inventory and inventory.name or ""

    disableOtherInventoryButtons(botName)
    setInventoryBotName(botName)
    openInventoryWindow()
    openInspectForInventoryBot(botName)

    if inventory and previousBotName ~= botName then
        inventory.pendingLootBot = nil
        if inventory.resetExactViewState then
            inventory:resetExactViewState()
        elseif inventory.resetItems then
            inventory:resetItems()
        end
        inventory.summary = {
            bagUsed = nil,
            bagTotal = nil,
            gold = 0,
            silver = 0,
            copper = 0,
        }
        updateInventorySummaryLabels(inventory)
    end

    local sourceButton = getInventorySourceButton(botName)
    if sourceButton and sourceButton.setEnable then
        sourceButton.setEnable()
    end

    local requested = requestInventoryForBot(botName)
    if not requested then
        local waitButton = getInventoryWaitButton(botName)
        if waitButton and (waitButton.waitFor == "INVENTORY" or waitButton.waitFor == "ITEM" or waitButton.waitFor == "LOOT") then
            waitButton.waitFor = ""
        end
    end

    return requested
end

local function setInventoryActionState(buttonKey, options)
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    options = options or {}

    local nextState = buttonKey and ACTION_MODE_CONFIG[buttonKey] or nil
    local previousAction = inventory.action or ""
    local shouldCancelTrade = options.cancelTrade

    if shouldCancelTrade == nil then
        shouldCancelTrade = previousAction == ACTION_MODE_CONFIG.Trade.value
            and (not nextState or nextState.value ~= ACTION_MODE_CONFIG.Trade.value)
    end

    if shouldCancelTrade then
        CancelTrade()
    end

    inventory.action = nextState and nextState.value or ""
    disableActionModes(buttonKey)

    if nextState then
        local button = inventory.buttons and inventory.buttons[buttonKey] or nil
        if button and button.setEnable then
            button.setEnable()
        end
    end

    updateModeLabel()
end

local function toggleInventoryAction(buttonKey, button)
    local inventory = MultiBot.inventory
    local state = ACTION_MODE_CONFIG[buttonKey]
    if not inventory or not state or not button then
        return
    end

    if button.state then
        if state.value == ACTION_MODE_CONFIG.Trade.value then
            clearTradeInventoryDumpFilter()
        end

        setInventoryActionState(nil, {
            cancelTrade = state.value == ACTION_MODE_CONFIG.Trade.value,
        })
        return
    end

    if buttonKey == "Trade" then
        suppressNextTradeInventoryDump(button.getName())
        InitiateTrade(button.getName())
    else
        clearTradeInventoryDumpFilter()
    end

    setInventoryActionState(buttonKey, {
        cancelTrade = state.cancelTradeOnActivate,
    })
end

local function runInventoryInstantAction(botName, command, options)
    options = options or {}

    if not botName or botName == "" or not command or command == "" then
        return false
    end

    if options.requiresTarget and not MultiBot.isTarget() then
        return false
    end

    if options.clearActionState then
        CancelTrade()
        setInventoryActionState(nil, { cancelTrade = false })
    end

    local function isBulkSellCommand(cmd)
        return cmd == "s *" or cmd == "s vendor"
    end

    local function shouldSellButtonForBulk(button, cmd)
        local item = button and button.item
        if not item then
            return false
        end

        if MultiBot.InventoryIsProtectedSellItem and MultiBot.InventoryIsProtectedSellItem(item) then
            return false
        end

        if cmd == "s *" then
            return tonumber(item.rare or -1) == 0
        end

        return true
    end

    local function runFilteredBulkSell(cmd)
        local bridgeAction = nil
        if cmd == "s *" then
            bridgeAction = "SELL_GREY"
        elseif cmd == "s vendor" then
            bridgeAction = "SELL_VENDOR"
        end

        if bridgeAction
            and MultiBot.bridge and MultiBot.bridge.connected == true
            and MultiBot.bridge.inventoryCapable == true
            and MultiBot.bridge.inventoryBulkSellCapable == true then
            if not (MultiBot.Comm and MultiBot.Comm.RunInventoryItemAction) then
                return false
            end

            local token = MultiBot.Comm.RunInventoryItemAction(botName, bridgeAction, 0, 0)
            if token then
                return true
            end

            return false
        end

        if cmd == "s vendor" and MultiBot.allowLegacyChatFallback ~= true then
            return false
        end

        local inventory = MultiBot.inventory
        local itemsFrame = inventory and inventory.frames and inventory.frames.Items
        local itemButtons = itemsFrame and itemsFrame.buttons
        if type(itemButtons) ~= "table" then
            return false
        end

        local sellCount = 0
        local protectedFound = false
        for _, itemButton in pairs(itemButtons) do
            if itemButton and itemButton.item then
                if MultiBot.InventoryIsProtectedSellItem and MultiBot.InventoryIsProtectedSellItem(itemButton.item) then
                    protectedFound = true
                elseif shouldSellButtonForBulk(itemButton, cmd) then
                    SendChatMessage("s " .. itemButton.tip, "WHISPER", nil, botName)
                    if itemButton.Hide then
                        itemButton:Hide()
                    end
                    sellCount = sellCount + 1
                end
            end
        end

        if protectedFound then
            SendChatMessage(MultiBot.L("info.questitemsellalert", "I cannot sell quest items."), "SAY")
        end

        if sellCount < 1 and not protectedFound then
            return false
        end

        if options.refreshDelay ~= nil and MultiBot.RefreshInventory then
            MultiBot.RefreshInventory(options.refreshDelay)
        elseif options.refresh and MultiBot.RefreshInventory then
            MultiBot.RefreshInventory()
        end

        return true
    end

    if isBulkSellCommand(command) then
        return runFilteredBulkSell(command)
    end

    if command == "open items" then
        local bridge = MultiBot.bridge
        local canUseBridgeOpen = bridge
            and bridge.connected == true
            and bridge.inventoryCapable == true
            and bridge.inventoryOpenCapable == true

        if canUseBridgeOpen then
            if not (MultiBot.Comm and MultiBot.Comm.RunInventoryItemAction) then
                bridge.lastError = "INVENTORY_OPEN_API_UNAVAILABLE"
                return false
            end

            local token = MultiBot.Comm.RunInventoryItemAction(botName, "OPEN_ITEMS", 0, 0)
            if token then
                return true
            end

            bridge.lastError = "INVENTORY_OPEN_SEND_FAILED"
            return false
        end

        if MultiBot.allowLegacyChatFallback ~= true then
            if bridge then
                bridge.lastError = "INVENTORY_OPEN_CAPABILITY_UNAVAILABLE"
            end
            return false
        end
    end

    SendChatMessage(command, "WHISPER", nil, botName)

    if options.refreshDelay ~= nil and MultiBot.RefreshInventory then
        MultiBot.RefreshInventory(options.refreshDelay)
    elseif options.refresh and MultiBot.RefreshInventory then
        MultiBot.RefreshInventory()
    end

    return true
end

-- MB_VENDOR_BUYBACK_V1_UI_BEGIN
local BUYBACK_MAX_ITEMS = 12
local BUYBACK_COLUMNS = 2
local BUYBACK_ROW_WIDTH = 238
local BUYBACK_ROW_HEIGHT = 48
local BUYBACK_COLUMN_GAP = 10
local BUYBACK_ROW_GAP = 6

local function formatInventoryBuybackMoney(copperValue)
    local total = math.max(0, tonumber(copperValue or 0) or 0)
    local gold = math.floor(total / 10000)
    local silver = math.floor((total % 10000) / 100)
    local copper = total % 100
    local parts = {}

    if gold > 0 then
        table.insert(parts, gold .. " |TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
    end
    if silver > 0 or gold > 0 then
        table.insert(parts, silver .. " |TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t")
    end
    if copper > 0 or #parts == 0 then
        table.insert(parts, copper .. " |TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t")
    end

    return table.concat(parts, " ")
end

local function getInventoryBuybackReasonText(reason)
    local code = tostring(reason or "UNKNOWN")
    if code == "" then
        code = "UNKNOWN"
    end
    return MultiBot.L("inventory.buyback.reason." .. code, code)
end

local function ensureInventoryBuybackFrame()
    if MultiBot.inventoryBuybackFrame then
        return MultiBot.inventoryBuybackFrame
    end

    local aceGUI = getInventoryAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Buyback", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(MultiBot.L("inventory.buyback.title", "Buyback - %s"):format("-"))
    window:SetLayout("Manual")
    window:SetWidth(520)
    window:SetHeight(410)
    window:EnableResize(false)
    window.frame:SetClampedToScreen(true)
    window.frame:ClearAllPoints()
    window.frame:SetPoint("CENTER", UIParent, "CENTER", 210, 0)

    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    else
        window.frame:SetFrameStrata("DIALOG")
    end

    window:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)
    registerInventoryEscapeClose(window, "Buyback")

    local frame = window
    local content = window.content
    content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -10, 10)

    frame.root = CreateFrame("Frame", nil, content)
    frame.root:SetAllPoints(content)
    addSimpleBackdrop(frame.root, 0.90)

    frame.status = frame.root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("BOTTOMLEFT", frame.root, "BOTTOMLEFT", 10, 9)
    frame.status:SetPoint("BOTTOMRIGHT", frame.root, "BOTTOM", 50, 9)
    frame.status:SetJustifyH("LEFT")
    frame.status:SetText("")

    frame.totalLabel = frame.root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.totalLabel:SetPoint("BOTTOMLEFT", frame.root, "BOTTOM", 50, 9)
    frame.totalLabel:SetPoint("BOTTOMRIGHT", frame.root, "BOTTOMRIGHT", -10, 9)
    frame.totalLabel:SetJustifyH("RIGHT")
    frame.totalLabel:SetText("")

    function frame:IsShown()
        return self.frame and self.frame.IsShown and self.frame:IsShown() or false
    end

    frame.rows = {}
    frame.buttons = frame.rows
    frame.botName = ""
    frame.pendingToken = nil
    frame.listToken = nil

    function frame:setBotName(botName)
        self.botName = botName or ""
        self:SetTitle(string.format(
            MultiBot.L("inventory.buyback.title", "Buyback - %s"),
            self.botName ~= "" and self.botName or "-"
        ))
    end

    function frame:setStatus(text)
        if self.status then
            self.status:SetText(text or "")
        end
    end

    function frame:clearItems()
        for _, row in ipairs(self.rows or {}) do
            row.entry = nil
            row:EnableMouse(false)
            if row.SetBackdropBorderColor then
                row:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.92)
            end
            if row.icon then
                row.icon:SetTexture(nil)
            end
            if row.countLabel then
                row.countLabel:SetText("")
            end
            if row.nameLabel then
                row.nameLabel:SetText("")
            end
            if row.priceLabel then
                row.priceLabel:SetText("")
            end
            row:Show()
        end
        if self.totalLabel then
            self.totalLabel:SetText("")
        end
    end

    for index = 1, BUYBACK_MAX_ITEMS do
        local column = (index - 1) % BUYBACK_COLUMNS
        local rowIndex = math.floor((index - 1) / BUYBACK_COLUMNS)
        local row = CreateFrame("Button", nil, frame.root)
        row:SetSize(BUYBACK_ROW_WIDTH, BUYBACK_ROW_HEIGHT)
        row:SetPoint(
            "TOPLEFT",
            frame.root,
            "TOPLEFT",
            7 + (column * (BUYBACK_ROW_WIDTH + BUYBACK_COLUMN_GAP)),
            -9 - (rowIndex * (BUYBACK_ROW_HEIGHT + BUYBACK_ROW_GAP))
        )
        row:RegisterForClicks("LeftButtonDown")
        row:EnableMouse(false)
        addSimpleBackdrop(row, 0.72)

        if row.SetBackdropBorderColor then
            row:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.92)
        end

        row.iconFrame = CreateFrame("Frame", nil, row)
        row.iconFrame:SetSize(40, 40)
        row.iconFrame:SetPoint("LEFT", row, "LEFT", 4, 0)
        addSimpleBackdrop(row.iconFrame, 0.96)

        row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("TOPLEFT", row.iconFrame, "TOPLEFT", 3, -3)
        row.icon:SetPoint("BOTTOMRIGHT", row.iconFrame, "BOTTOMRIGHT", -3, 3)
        row.icon:SetTexture(nil)

        row.countLabel = row.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        row.countLabel:SetPoint("BOTTOMRIGHT", row.iconFrame, "BOTTOMRIGHT", -1, 1)
        row.countLabel:SetText("")

        row.nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nameLabel:SetPoint("TOPLEFT", row.iconFrame, "TOPRIGHT", 7, -2)
        row.nameLabel:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -4)
        row.nameLabel:SetHeight(22)
        row.nameLabel:SetJustifyH("LEFT")
        row.nameLabel:SetJustifyV("TOP")
        row.nameLabel:SetText("")

        row.priceLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.priceLabel:SetPoint("BOTTOMLEFT", row.iconFrame, "BOTTOMRIGHT", 7, 3)
        row.priceLabel:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 3)
        row.priceLabel:SetJustifyH("LEFT")
        row.priceLabel:SetText("")

        row:SetScript("OnEnter", function(self)
            local entry = self.entry
            if not entry then
                return
            end

            if self.SetBackdropBorderColor then
                self:SetBackdropBorderColor(0.78, 0.67, 0.18, 1.00)
            end

            if not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local itemName, itemLink = GetItemInfo(entry.itemId)
            if itemLink then
                GameTooltip:SetHyperlink(itemLink)
            else
                GameTooltip:SetText(itemName or ("Item " .. tostring(entry.itemId)), 1, 1, 1, true)
            end
            GameTooltip:AddLine(
                MultiBot.L("inventory.buyback.price", "Price") .. ": " ..
                    formatInventoryBuybackMoney(entry.price),
                1, 0.82, 0, true
            )
            GameTooltip:Show()
        end)

        row:SetScript("OnLeave", function(self)
            if self.SetBackdropBorderColor then
                self:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.92)
            end
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        row:SetScript("OnClick", function(self)
            local entry = self.entry
            if not entry or frame.pendingToken then
                return
            end

            if not MultiBot.Comm or not MultiBot.Comm.RunInventoryBuyback then
                frame:setStatus(
                    MultiBot.L(
                        "inventory.buyback.unavailable",
                        "Buyback through the bridge is unavailable."
                    )
                )
                return
            end

            local token = MultiBot.Comm.RunInventoryBuyback(
                frame.botName,
                entry.slot,
                entry.itemId,
                entry.count,
                entry.price
            )
            if not token then
                frame:setStatus(
                    MultiBot.L(
                        "inventory.buyback.send_failed",
                        "The buyback request could not be sent."
                    )
                )
                return
            end

            frame.pendingToken = token
            frame:setStatus(MultiBot.L("inventory.buyback.pending", "Buyback requested..."))
        end)

        frame.rows[index] = row
        row:Show()
    end

    function frame:showLoading(botName)
        self:setBotName(botName)
        self.pendingToken = nil
        self:clearItems()
        self:setStatus(MultiBot.L("inventory.buyback.loading", "Loading buyback..."))
        self:Show()
    end

    function frame:render(botName, items)
        self:setBotName(botName)
        self.pendingToken = nil
        self:clearItems()

        local rendered = 0
        local totalPrice = 0
        for index, entry in ipairs(items or {}) do
            if index > BUYBACK_MAX_ITEMS then
                break
            end

            local row = self.rows[index]
            if row and type(entry) == "table" then
                row.entry = entry
                row:EnableMouse(true)

                local itemName = GetItemInfo(entry.itemId)
                local icon = GetItemIcon(entry.itemId)

                row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.countLabel:SetText(
                    (tonumber(entry.count or 1) or 1) > 1 and tostring(entry.count) or ""
                )
                row.nameLabel:SetText(itemName or ("Item " .. tostring(entry.itemId)))
                row.priceLabel:SetText(formatInventoryBuybackMoney(entry.price))
                row:Show()
                rendered = rendered + 1
                totalPrice = totalPrice + math.max(0, tonumber(entry.price or 0) or 0)
            end
        end

        if rendered == 0 then
            self:setStatus(
                MultiBot.L(
                    "inventory.buyback.empty",
                    "No items are available to buy back."
                )
            )
            self.totalLabel:SetText("")
        else
            self:setStatus("")
            self.totalLabel:SetText(formatInventoryBuybackMoney(totalPrice))
        end

        self:Show()
    end

    window.frame:HookScript("OnHide", function()
        frame.pendingToken = nil
        frame.listToken = nil
    end)

    frame:clearItems()
    frame:Hide()
    MultiBot.inventoryBuybackFrame = frame
    return frame
end

function MultiBot.CloseInventoryBuyback()
    if MultiBot.inventoryBuybackFrame then
        MultiBot.inventoryBuybackFrame:Hide()
    end
end

function MultiBot.OpenBotBuyback(botName)
    if not botName or botName == "" then
        return false
    end

    local frame = ensureInventoryBuybackFrame()
    if not frame then
        return false
    end

    frame:showLoading(botName)

    if not MultiBot.Comm or not MultiBot.Comm.IsInventoryBuybackCapable or
        not MultiBot.Comm.IsInventoryBuybackCapable() then
        frame:setStatus(
            MultiBot.L(
                "inventory.buyback.unavailable",
                "Buyback through the bridge is unavailable."
            )
        )
        return false
    end

    local token = MultiBot.Comm.RequestInventoryBuyback(botName)
    if not token then
        frame:setStatus(
            MultiBot.L(
                "inventory.buyback.send_failed",
                "The buyback request could not be sent."
            )
        )
        return false
    end

    frame.listToken = token
    return true
end

MultiBot.OnBridgeInventoryBuybackList = function(botName, items, result)
    local frame = MultiBot.inventoryBuybackFrame
    if not frame or not frame.IsShown or not frame:IsShown() or frame.botName ~= botName then
        return
    end

    frame.listToken = nil
    local status = result and result.status or "ERR"
    local reason = result and result.reason or "UNKNOWN"
    if status == "OK" then
        frame:render(botName, items or {})
    else
        frame:clearItems()
        frame:setStatus(string.format(
            MultiBot.L("inventory.buyback.error", "Buyback failed: %s"),
            getInventoryBuybackReasonText(reason)
        ))
    end
end

MultiBot.OnBridgeInventoryBuybackResult = function(
    botName,
    status,
    reason,
    _slot,
    _itemId,
    _count,
    _price,
    command
)
    local frame = MultiBot.inventoryBuybackFrame
    if frame and command and frame.pendingToken == command.token then
        frame.pendingToken = nil
    end

    if status == "OK" then
        local refreshed = MultiBot.RequestInventoryRefresh
            and MultiBot.RequestInventoryRefresh(botName, 0.30)
        if not refreshed and MultiBot.Comm and MultiBot.Comm.RequestInventoryExact then
            MultiBot.Comm.RequestInventoryExact(botName)
        end

        if frame and frame.IsShown and frame:IsShown() and frame.botName == botName then
            MultiBot.OpenBotBuyback(botName)
        end
        return
    end

    if reason == "TIMEOUT" or reason == "BAD_RESPONSE" or reason == "RESPONSE_MISMATCH" then
        local refreshed = MultiBot.RequestInventoryRefresh
            and MultiBot.RequestInventoryRefresh(botName, 0.30)
        if not refreshed and MultiBot.Comm and MultiBot.Comm.RequestInventoryExact then
            MultiBot.Comm.RequestInventoryExact(botName)
        end
    end

    if frame and frame.IsShown and frame:IsShown() and frame.botName == botName then
        frame:setStatus(string.format(
            MultiBot.L("inventory.buyback.error", "Buyback failed: %s"),
            getInventoryBuybackReasonText(reason)
        ))
    end
end
-- MB_VENDOR_BUYBACK_V1_UI_END

local function createInventoryContent(window)
    local content = window.content
    content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -10, 10)

    local panelInset = INVENTORY_WINDOW_DEFAULTS.panelInset
    local panelGap = INVENTORY_WINDOW_DEFAULTS.panelGap

    local root = CreateFrame("Frame", nil, content)
    root:SetAllPoints(content)
    addSimpleBackdrop(root, 0.90)

    local leftPanel = CreateFrame("Frame", nil, root)
    leftPanel:SetPoint("TOPLEFT", root, "TOPLEFT", panelInset, -panelInset)
    leftPanel:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", panelInset, panelInset)
    leftPanel:SetWidth(INVENTORY_WINDOW_DEFAULTS.actionsWidth)
    addSimpleBackdrop(leftPanel, 0.55)

    local itemsPanel = CreateFrame("Frame", nil, root)
    itemsPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", panelGap, 0)
    itemsPanel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -panelInset, panelInset)
    addSimpleBackdrop(itemsPanel, 0.55)

    local modeLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 10, -14)
    modeLabel:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -8, -14)
    modeLabel:SetJustifyH("LEFT")
    modeLabel:SetJustifyV("TOP")
    modeLabel:SetHeight(INVENTORY_WINDOW_DEFAULTS.modeLabelHeight)
    if modeLabel.SetNonSpaceWrap then
        modeLabel:SetNonSpaceWrap(true)
    end
    if modeLabel.SetWordWrap then
        modeLabel:SetWordWrap(true)
    end
    modeLabel:SetText(MultiBot.L("info.action", "Action") .. ":")

    local modeValueLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    modeValueLabel:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -2)
    modeValueLabel:SetPoint("TOPRIGHT", modeLabel, "BOTTOMRIGHT", 0, -2)
    modeValueLabel:SetJustifyH("LEFT")
    modeValueLabel:SetJustifyV("TOP")
    modeValueLabel:SetHeight(INVENTORY_WINDOW_DEFAULTS.modeValueHeight)
    modeValueLabel:SetText(MultiBot.L("inventory.mode.sell"))

    local containerBar, containerButtons = createInventoryContainerBar(itemsPanel)

    local scrollFrame = CreateFrame("ScrollFrame", "MultiBotInventoryScrollFrame", itemsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding, -INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding)
    scrollFrame:SetPoint(
        "BOTTOMRIGHT",
        itemsPanel,
        "BOTTOMRIGHT",
        -INVENTORY_WINDOW_DEFAULTS.scrollBarAllowance,
        INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding
            + INVENTORY_WINDOW_DEFAULTS.containerBarHeight
            + INVENTORY_WINDOW_DEFAULTS.containerBarGap
    )

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(1)
    scrollChild:SetHeight(INVENTORY_WINDOW_DEFAULTS.minCanvasHeight)
    scrollFrame:SetScrollChild(scrollChild)

    local actionHost = { inventoryRef = nil }
    local buttons = {}
    local modeButtonDefs = {
        { key = "Sell", texture = "inv_misc_coin_16", tip = MultiBot.L("tips.inventory.sell") },
        { key = "Equip", texture = "inv_helmet_22", tip = MultiBot.L("tips.inventory.equip") },
        { key = "Use", texture = "inv_gauntlets_25", tip = MultiBot.L("tips.inventory.use") },
        { key = "Trade", texture = "achievement_reputation_01", tip = MultiBot.L("tips.inventory.trade") },
        { key = "Bank", texture = "inv_misc_bag_10", tip = MultiBot.L("tips.inventory.bank.deposit", "Deposit to bank") },
        { key = "GuildBank", texture = "inv_misc_bag_15", tip = MultiBot.L("tips.inventory.gbank.deposit", "Deposit to guild bank") },
        { key = "Buy", texture = "inv_misc_coin_05", tip = MultiBot.L("tips.inventory.buy", "Buy this item from a nearby vendor") },
        { key = "Destroy", texture = "inv_hammer_15", tip = MultiBot.L("tips.inventory.drop") },
    }
    local instantButtonDefs = {
        { key = "SellGrey", texture = "inv_misc_coin_03", tip = MultiBot.L("tips.inventory.sellgrey") },
        { key = "SellVendor", texture = "inv_misc_coin_04", tip = MultiBot.L("tips.inventory.sellvendor") },
        { key = "Open", texture = "inv_misc_gift_05", tip = MultiBot.L("tips.inventory.open") },
        { key = "BankOpen", texture = "inv_misc_bag_10", tip = MultiBot.L("tips.inventory.bank.open", "Open bot bank") },
        { key = "GuildBankOpen", texture = "inv_misc_bag_15", tip = MultiBot.L("tips.inventory.gbank.open", "Open bot guild bank") },
        { key = "Buyback", texture = "inv_misc_coin_05", tip = MultiBot.L("tips.inventory.buyback", "Buy back recently sold items") },
    }

    for index, definition in ipairs(modeButtonDefs) do
        local columns = math.max(1, INVENTORY_WINDOW_DEFAULTS.modeActionColumns or 1)
        local spacingX = INVENTORY_WINDOW_DEFAULTS.modeActionSpacingX or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
        local spacingY = INVENTORY_WINDOW_DEFAULTS.modeActionSpacingY or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
        local groupWidth = INVENTORY_WINDOW_DEFAULTS.buttonSize + ((columns - 1) * spacingX)
        local startX = math.floor((INVENTORY_WINDOW_DEFAULTS.actionsWidth - groupWidth) / 2)
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local xOffset = startX + (column * spacingX)
        local yOffset = -INVENTORY_WINDOW_DEFAULTS.buttonStartOffsetY - (row * spacingY)
        buttons[definition.key] = makeActionButton(leftPanel, definition.key, definition.texture, definition.tip, yOffset, xOffset)
    end

    local instantStartY = -INVENTORY_WINDOW_DEFAULTS.buttonStartOffsetY
        - (math.ceil(#modeButtonDefs / math.max(1, INVENTORY_WINDOW_DEFAULTS.modeActionColumns or 1)) * (INVENTORY_WINDOW_DEFAULTS.modeActionSpacingY or INVENTORY_WINDOW_DEFAULTS.buttonSpacing))
        - INVENTORY_WINDOW_DEFAULTS.instantActionsTopPadding
    local instantColumns = math.max(1, INVENTORY_WINDOW_DEFAULTS.instantActionColumns or 1)
    local instantSpacingX = INVENTORY_WINDOW_DEFAULTS.instantActionSpacingX or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
    local instantSpacingY = INVENTORY_WINDOW_DEFAULTS.instantActionSpacingY or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
    local instantGroupWidth = INVENTORY_WINDOW_DEFAULTS.buttonSize + ((instantColumns - 1) * instantSpacingX)
    local instantStartX = math.floor((INVENTORY_WINDOW_DEFAULTS.actionsWidth - instantGroupWidth) / 2)
    for index, definition in ipairs(instantButtonDefs) do
        local column = (index - 1) % instantColumns
        local row = math.floor((index - 1) / instantColumns)
        local xOffset = instantStartX + (column * instantSpacingX)
        local yOffset = instantStartY - (row * instantSpacingY)
        buttons[definition.key] = makeActionButton(leftPanel, definition.key, definition.texture, definition.tip, yOffset, xOffset)
    end

    local summaryAnchorY = instantStartY
        - (math.ceil(#instantButtonDefs / instantColumns) * instantSpacingY)
        - INVENTORY_WINDOW_DEFAULTS.summaryTopPadding

    local moneyLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    moneyLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, summaryAnchorY)
    moneyLabel:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -6, summaryAnchorY)
    moneyLabel:SetJustifyH("LEFT")
    moneyLabel:SetText(formatMoneyLabel(0, 0, 0))

    local bagSlotsLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bagSlotsLabel:SetPoint("TOPLEFT", moneyLabel, "BOTTOMLEFT", 0, -INVENTORY_WINDOW_DEFAULTS.summaryLineSpacing)
    bagSlotsLabel:SetPoint("TOPRIGHT", moneyLabel, "BOTTOMRIGHT", 0, -INVENTORY_WINDOW_DEFAULTS.summaryLineSpacing)
    bagSlotsLabel:SetJustifyH("LEFT")
    bagSlotsLabel:SetText(formatBagSlotsLabel(nil, nil))

    local items = makeItemsContainer(itemsPanel, scrollChild)
    items:updateLayout()

    itemsPanel:SetScript("OnSizeChanged", function()
        items:updateLayout()
    end)

    return {
        root = root,
        leftPanel = leftPanel,
        itemsPanel = itemsPanel,
        items = items,
        containerBar = containerBar,
        containerButtons = containerButtons,
        modeLabel = modeLabel,
        modeValueLabel = modeValueLabel,
        moneyLabel = moneyLabel,
        bagSlotsLabel = bagSlotsLabel,
        actionHost = actionHost,
        buttons = buttons,
    }
end

function MultiBot.InitializeInventoryFrame()
    if MultiBot.inventory and MultiBot.inventory.__aceInitialized then
        return MultiBot.inventory
    end

    local aceGUI = getInventoryAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Inventory", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(getInventoryWindowTitle(nil))
    window:SetLayout("Manual")
    window:SetWidth(INVENTORY_WINDOW_DEFAULTS.width)
    window:SetHeight(INVENTORY_WINDOW_DEFAULTS.height)
    window:EnableResize(false)
    window.frame:SetClampedToScreen(true)
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end
    window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", INVENTORY_WINDOW_DEFAULTS.pointX, INVENTORY_WINDOW_DEFAULTS.pointY)
    window:SetCallback("OnClose", function(widget)
        closeInventoryWindow()
        widget:Hide()
    end)
    window:Hide()
    window.frame:HookScript("OnHide", function()
        syncInventoryButtonState(false)
        local current = MultiBot.inventory
        if current and current.clearItemMoveDrag then
            current:clearItemMoveDrag()
        end
    end)

    registerInventoryEscapeClose(window, "Inventory")
    bindInventoryWindowPosition(window)

    local content = createInventoryContent(window)

    local inventory = {
        __aceInitialized = true,
        window = window,
        root = content.root,
        buttons = content.buttons,
        frames = { Items = content.items },
        texts = { Title = content.modeLabel },
        modeLabel = content.modeLabel,
        modeValueLabel = content.modeValueLabel,
        moneyLabel = content.moneyLabel,
        bagSlotsLabel = content.bagSlotsLabel,
        containerBar = content.containerBar,
        containerButtons = content.containerButtons,
        name = "",
        action = "s",
        pendingLootBot = nil,
        itemMoveDrag = nil,
        itemMoveDragGhost = nil,
        itemMovePendingToken = nil,
        containerFilter = nil,
        exactSnapshot = nil,
        legacyItemMetadataById = {},
        summary = {
            bagUsed = nil,
            bagTotal = nil,
            gold = 0,
            silver = 0,
            copper = 0,
        },
    }

    MultiBot.inventory = inventory
    ensureTradeInventoryDumpFilter()

    content.actionHost.inventoryRef = inventory
    for _, button in pairs(content.buttons) do
        button.parent = inventory
    end

    function inventory.setText(key, value)
        if key == "Title" then
            if inventory.window and inventory.window.SetTitle then
                inventory.window:SetTitle(value or getInventoryWindowTitle(inventory.name))
            end
            return inventory
        end

        if key == "Mode" and inventory.modeValueLabel then
            inventory.modeValueLabel:SetText(value or "")
        end
        return inventory
    end

    function inventory.getButton(index)
        return inventory.buttons and inventory.buttons[index] or nil
    end

    function inventory.getFrame(index)
        return inventory.frames and inventory.frames[index] or nil
    end

    function inventory:Show()
        openInventoryWindow()
    end

    function inventory:Hide()
        closeInventoryWindow()
    end

    function inventory:IsVisible()
        return self.window and self.window.frame and self.window.frame:IsShown() or false
    end

    function inventory:GetRight()
        return self.window and self.window.frame and self.window.frame:GetRight() or 0
    end

    function inventory:GetBottom()
        return self.window and self.window.frame and self.window.frame:GetBottom() or 0
    end

    function inventory.setPoint(x, y)
        if type(x) ~= "number" or type(y) ~= "number" then return end
        window.frame:ClearAllPoints()
        window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        persistInventoryWindowPosition(window.frame)
    end

    local function updateItemMoveDragGhostPosition(ghost)
        if not ghost or type(GetCursorPosition) ~= "function" or not UIParent or
            type(UIParent.GetEffectiveScale) ~= "function" then
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if not cursorX or not cursorY or not scale or scale <= 0 then
            return
        end

        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
    end

    function inventory:ensureItemMoveDragGhost()
        if self.itemMoveDragGhost then
            return self.itemMoveDragGhost
        end

        local ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetSize(INVENTORY_WINDOW_DEFAULTS.itemSize, INVENTORY_WINDOW_DEFAULTS.itemSize)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:EnableMouse(false)

        ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
        ghost.icon:SetAllPoints(ghost)
        ghost:SetScript("OnUpdate", function(ghostFrame)
            updateItemMoveDragGhostPosition(ghostFrame)
        end)
        ghost:Hide()

        self.itemMoveDragGhost = ghost
        return ghost
    end

    function inventory:clearItemMoveDrag()
        local drag = self.itemMoveDrag
        if drag and drag.sourceButton and drag.sourceButton.SetAlpha then
            drag.sourceButton:SetAlpha(drag.sourceAlpha or 1.0)
        end

        local ghost = self.itemMoveDragGhost
        if ghost then
            ghost:Hide()
            ghost:ClearAllPoints()
        end

        self.itemMoveDrag = nil
    end

    function inventory:findExactDropTarget(frame)
        local current = frame
        for _ = 1, 8 do
            if not current then
                break
            end
            if current.__mbExactSlot then
                return current
            end
            if type(current.GetParent) ~= "function" then
                break
            end
            current = current:GetParent()
        end
        return nil
    end

    function inventory:beginItemMoveDrag(button)
        if self.itemMovePendingToken or not button or type(button.__mbExactSlot) ~= "table" then
            return false
        end
        if not MultiBot.Comm or not MultiBot.Comm.IsInventoryItemMoveCapable or
            not MultiBot.Comm.IsInventoryItemMoveCapable() then
            return false
        end
        if type(self.exactSnapshot) ~= "table" or self.name == "" then
            return false
        end

        local source = button.__mbExactSlot
        if source.botName ~= self.name then
            return false
        end

        local positionKey = tostring(source.bag) .. ":" .. tostring(source.slot)
        local location = self.exactSnapshot.itemsByPosition and self.exactSnapshot.itemsByPosition[positionKey] or nil
        if not location or tonumber(location.itemId or 0) ~= tonumber(source.itemId or 0) or
            tonumber(location.count or 0) ~= tonumber(source.count or 0) then
            return false
        end

        self:clearItemMoveDrag()
        self.itemMoveDrag = {
            botName = self.name,
            srcBag = tonumber(source.bag or 0) or 0,
            srcSlot = tonumber(source.slot or 0) or 0,
            srcItemId = tonumber(source.itemId or 0) or 0,
            srcCount = tonumber(source.count or 0) or 0,
            sourceButton = button,
            sourceAlpha = button.GetAlpha and button:GetAlpha() or 1.0,
        }

        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
        if button.SetAlpha then
            button:SetAlpha(0.45)
        end

        local ghost = self:ensureItemMoveDragGhost()
        if ghost and ghost.icon and button.texture then
            ghost.icon:SetTexture(button.texture)
            updateItemMoveDragGhostPosition(ghost)
            ghost:Show()
        end
        return true
    end

    function inventory:finishItemMoveDrag(button)
        local drag = self.itemMoveDrag
        local mouseFocus = type(GetMouseFocus) == "function" and GetMouseFocus() or nil
        local targetButton = self:findExactDropTarget(mouseFocus)
        self:clearItemMoveDrag()

        if not drag or drag.sourceButton ~= button or self.itemMovePendingToken then
            return false
        end
        if drag.botName ~= self.name or type(self.exactSnapshot) ~= "table" then
            return false
        end
        if not targetButton or type(targetButton.__mbExactSlot) ~= "table" then
            return false
        end

        local target = targetButton.__mbExactSlot
        if target.botName ~= drag.botName then
            return false
        end

        local dstBag = tonumber(target.bag or 0) or 0
        local dstSlot = tonumber(target.slot or 0) or 0
        if drag.srcBag == dstBag and drag.srcSlot == dstSlot then
            return false
        end

        local sourceKey = tostring(drag.srcBag) .. ":" .. tostring(drag.srcSlot)
        local currentSource = self.exactSnapshot.itemsByPosition and self.exactSnapshot.itemsByPosition[sourceKey] or nil
        if not currentSource or tonumber(currentSource.itemId or 0) ~= drag.srcItemId or
            tonumber(currentSource.count or 0) ~= drag.srcCount then
            return false
        end

        local targetKey = tostring(dstBag) .. ":" .. tostring(dstSlot)
        local currentTarget = self.exactSnapshot.itemsByPosition and self.exactSnapshot.itemsByPosition[targetKey] or nil
        local dstItemId = currentTarget and (tonumber(currentTarget.itemId or 0) or 0) or 0
        local dstCount = currentTarget and (tonumber(currentTarget.count or 0) or 0) or 0
        if dstItemId ~= (tonumber(target.itemId or 0) or 0) or dstCount ~= (tonumber(target.count or 0) or 0) then
            return false
        end

        if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemMove then
            return false
        end

        local token = MultiBot.Comm.RunInventoryItemMove(
            drag.botName, drag.srcBag, drag.srcSlot, drag.srcItemId, drag.srcCount,
            dstBag, dstSlot, dstItemId, dstCount
        )
        if not token then
            return false
        end

        self.itemMovePendingToken = token
        return true
    end

    function inventory:configureExactItemButton(button, item)
        if not button or type(item) ~= "table" or item.exactLocation ~= true then
            return false
        end

        button.__mbExactSlot = {
            botName = self.name,
            bag = tonumber(item.bag or 0) or 0,
            slot = tonumber(item.slot or 0) or 0,
            itemId = tonumber(item.id or 0) or 0,
            count = tonumber(item._serverCount or item.count or 1) or 1,
        }

        if not MultiBot.Comm or not MultiBot.Comm.IsInventoryItemMoveCapable or
            not MultiBot.Comm.IsInventoryItemMoveCapable() then
            return true
        end

        button:RegisterForClicks("LeftButtonUp", "RightButtonDown")
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function(dragButton)
            dragButton.__mbSuppressNextLeftClick = true
            inventory:beginItemMoveDrag(dragButton)
        end)
        button:SetScript("OnDragStop", function(dragButton)
            inventory:finishItemMoveDrag(dragButton)
            if MultiBot.TimerAfter then
                MultiBot.TimerAfter(0.01, function()
                    dragButton.__mbSuppressNextLeftClick = nil
                end)
            else
                dragButton.__mbSuppressNextLeftClick = nil
            end
        end)
        return true
    end

    function inventory:resetItems()
        self:clearItemMoveDrag()
        local items = self.frames and self.frames.Items
        if items and items.clear then
            items:clear()
        end
        if items then
            items.index = 0
        end
    end

    function inventory:captureLegacyItemMetadata()
        local metadata = {}
        local items = self.frames and self.frames.Items
        if items and type(items.buttons) == "table" then
            for _, button in pairs(items.buttons) do
                local item = button and button.item or nil
                local itemId = item and tostring(item.id or "") or ""
                if itemId ~= "" and not metadata[itemId] then
                    metadata[itemId] = item
                end
            end
        end

        self.legacyItemMetadataById = metadata
        return metadata
    end

    function inventory:updateContainerBar(snapshot)
        local buttons = self.containerButtons or {}
        local bagEntries = {}
        local backpackEntry = nil
        local keyringEntry = nil

        if type(snapshot) == "table" and type(snapshot.bags) == "table" then
            for _, entry in ipairs(snapshot.bags) do
                if type(entry) == "table" then
                    if entry.kind == "BACKPACK" then
                        backpackEntry = entry
                    elseif entry.kind == "KEYRING" then
                        keyringEntry = entry
                    elseif entry.kind == "BAG" then
                        table.insert(bagEntries, entry)
                    end
                end
            end
        end

        table.sort(bagEntries, function(left, right)
            return (tonumber(left and left.bag or 0) or 0) < (tonumber(right and right.bag or 0) or 0)
        end)

        local entries = {
            Backpack = backpackEntry,
            Bag1 = bagEntries[1],
            Bag2 = bagEntries[2],
            Bag3 = bagEntries[3],
            Bag4 = bagEntries[4],
            Keyring = keyringEntry,
        }

        local availableFilters = {}
        for key, button in pairs(buttons) do
            local entry = entries[key]
            local slotCount = tonumber(entry and entry.slotCount or 0) or 0
            local itemId = tonumber(entry and entry.itemId or 0) or 0
            local enabled = entry ~= nil and slotCount > 0
            if entry and entry.kind == "BAG" and itemId <= 0 then
                enabled = false
            end

            button.containerEntry = entry
            button.containerKey = entry and buildInventoryContainerKey(entry) or nil

            local texture = button.defaultTexture
            if entry and entry.kind == "BAG" and itemId > 0 and GetItemIcon then
                texture = GetItemIcon(itemId) or texture
            end
            button.icon:SetTexture(texture)

            local baseLabel = button.definition and button.definition.label or ""
            if entry then
                button.tip = string.format("%s (%d)", baseLabel, slotCount)
            else
                button.tip = baseLabel
            end

            if enabled and button.containerKey then
                button:Enable()
                button.icon:SetAlpha(1.0)
                availableFilters[button.containerKey] = true
            else
                button:Disable()
                button.icon:SetAlpha(0.30)
            end
        end

        if self.containerFilter and not availableFilters[self.containerFilter] then
            self.containerFilter = nil
        end

        for _, button in pairs(buttons) do
            if button.selectedOverlay then
                if self.containerFilter and button.containerKey == self.containerFilter then
                    button.selectedOverlay:Show()
                else
                    button.selectedOverlay:Hide()
                end
            end
        end
    end

    function inventory:resetExactViewState()
        self:clearItemMoveDrag()
        self.itemMovePendingToken = nil
        self.containerFilter = nil
        self.exactSnapshot = nil
        self.legacyItemMetadataById = {}
        self:updateContainerBar(nil)
        self:resetItems()
    end

    function inventory:renderExactSnapshot(snapshot)
        self:clearItemMoveDrag()
        if type(snapshot) ~= "table" or snapshot.botName ~= self.name then
            return false
        end

        local items = self.frames and self.frames.Items
        if not items then
            return false
        end

        self.exactSnapshot = snapshot
        self:updateContainerBar(snapshot)

        local containers = {}
        for _, entry in ipairs(snapshot.bags or {}) do
            if type(entry) == "table" then
                local key = buildInventoryContainerKey(entry)
                if not self.containerFilter or key == self.containerFilter then
                    table.insert(containers, entry)
                end
            end
        end

        items:clear()
        items.suspendLayout = true
        items.index = 0

        local useVisualGroups = self.containerFilter == nil
        local visualGroups = {}
        local layoutIndex = 0
        local renderedPositions = {}

        for _, entry in ipairs(containers) do
            local slotStart = tonumber(entry.slotStart or 0) or 0
            local slotCount = math.max(0, tonumber(entry.slotCount or 0) or 0)
            local bag = tonumber(entry.bag or 0) or 0
            local groupKey = buildInventoryContainerKey(entry)
            local group = nil

            if useVisualGroups and groupKey and slotCount > 0 then
                local label = getInventoryContainerSnapshotLabel(self, entry)
                group = {
                    key = groupKey,
                    label = string.format("%s (%d)", label or "", slotCount),
                    slotCount = slotCount,
                    decorated = true,
                }
                table.insert(visualGroups, group)
            end

            for offset = 0, slotCount - 1 do
                local slot = slotStart + offset
                local positionKey = tostring(bag) .. ":" .. tostring(slot)
                local location = snapshot.itemsByPosition and snapshot.itemsByPosition[positionKey] or nil
                renderedPositions[positionKey] = true

                local button
                if location and MultiBot.InventoryAddExactItem then
                    local metadata = self.legacyItemMetadataById and self.legacyItemMetadataById[tostring(location.itemId)] or nil
                    button = MultiBot.InventoryAddExactItem(items, metadata, location, layoutIndex)
                else
                    button = items:addEmptySlot(layoutIndex, "Slot_" .. positionKey, {
                        botName = self.name,
                        bag = bag,
                        slot = slot,
                        itemId = 0,
                        count = 0,
                    })
                end

                if useVisualGroups and group and button then
                    items:assignButtonToVisualGroup(button, group.key, offset)
                end

                layoutIndex = layoutIndex + 1
            end
        end

        local orphanGroup = nil
        local orphanCount = 0
        if not self.containerFilter then
            for _, location in ipairs(snapshot.items or {}) do
                local positionKey = tostring(location.bag or 0) .. ":" .. tostring(location.slot or 0)
                if not renderedPositions[positionKey] then
                    local button
                    if MultiBot.InventoryAddExactItem then
                        local metadata = self.legacyItemMetadataById and self.legacyItemMetadataById[tostring(location.itemId)] or nil
                        button = MultiBot.InventoryAddExactItem(items, metadata, location, layoutIndex)
                    else
                        button = items:addEmptySlot(layoutIndex, "Orphan_" .. positionKey)
                    end

                    if button then
                        if not orphanGroup then
                            orphanGroup = {
                                key = "__ORPHAN__",
                                label = "",
                                slotCount = 0,
                                decorated = false,
                            }
                            table.insert(visualGroups, orphanGroup)
                        end
                        items:assignButtonToVisualGroup(button, orphanGroup.key, orphanCount)
                        orphanCount = orphanCount + 1
                        orphanGroup.slotCount = orphanCount
                    end

                    layoutIndex = layoutIndex + 1
                end
            end
        end

        if useVisualGroups then
            items:setVisualGroups(visualGroups)
        else
            items:setVisualGroups({})
        end

        items.index = layoutIndex
        items.suspendLayout = false
        items:updateLayout()
        return true
    end
    function inventory:toggleContainerFilter(containerKey)
        if not containerKey or containerKey == "" or type(self.exactSnapshot) ~= "table" then
            return false
        end

        if self.containerFilter == containerKey then
            self.containerFilter = nil
        else
            self.containerFilter = containerKey
        end

        self:updateContainerBar(self.exactSnapshot)
        return self:renderExactSnapshot(self.exactSnapshot)
    end

    function inventory:endPayload(botName)
        local targetBotName = botName or self.name
        if targetBotName ~= self.name or not self:IsVisible() then
            return false
        end

        self:captureLegacyItemMetadata()

        if MultiBot.Comm and MultiBot.Comm.RequestInventoryExact then
            return MultiBot.Comm.RequestInventoryExact(targetBotName) and true or false
        end

        return false
    end

    function inventory:setBotName(botName)
        setInventoryBotName(botName)
        return inventory
    end

    function inventory:requestBotInventory(botName)
        return prepareInventoryForBot(botName)
    end

    function inventory:refresh(delay, botName)
        local targetBotName = botName or self.name
        if not targetBotName or targetBotName == "" or not self:IsVisible() then
            return false
        end

        local function doRefresh()
            if not self:IsVisible() then
                return false
            end

            local activeBotName = tostring(self.name or "")
            if activeBotName ~= "" and string.lower(activeBotName) ~= string.lower(tostring(targetBotName)) then
                return false
            end

            return prepareInventoryForBot(targetBotName)
        end

        if type(delay) == "number" and delay > 0 then
            MultiBot.TimerAfter(delay, doRefresh)
            return true
        end

        return doRefresh()
    end

    function inventory:markLootPending(botName)
        local targetBotName = botName or self.name
        if not targetBotName or targetBotName == "" then
            return false
        end

        self.pendingLootBot = targetBotName
        return true
    end

    function inventory:handleLootReceived(botName)
        local targetBotName = botName or self.pendingLootBot
        if not targetBotName or targetBotName == "" then
            return false
        end

        if self.pendingLootBot and self.pendingLootBot ~= targetBotName then
            return false
        end

        self.pendingLootBot = nil
        return self:refresh(nil, targetBotName)
    end

    function inventory:beginPayload(botName)
        setInventoryBotName(botName or "")
        self.pendingLootBot = nil
        self:resetItems()
        self.summary = {
            bagUsed = nil,
            bagTotal = nil,
            gold = 0,
            silver = 0,
            copper = 0,
        }
        updateInventorySummaryLabels(self)
        return self
    end

    function inventory:applySummaryLine(line)
        local parsed = parseInventorySummaryLine(line)
        if not parsed then
            return false
        end

        self.summary = self.summary or {}
        self.summary.bagUsed = parsed.bagUsed or self.summary.bagUsed
        self.summary.bagTotal = parsed.bagTotal or self.summary.bagTotal
        self.summary.gold = parsed.gold or 0
        self.summary.silver = parsed.silver or 0
        self.summary.copper = parsed.copper or 0
        updateInventorySummaryLabels(self)
        return true
    end

    function inventory:applySummaryData(summaryData)
        if type(summaryData) ~= "table" then
            return false
        end

        self.summary = self.summary or {}
        self.summary.bagUsed = tonumber(summaryData.bagUsed or self.summary.bagUsed or 0) or 0
        self.summary.bagTotal = tonumber(summaryData.bagTotal or self.summary.bagTotal or 0) or 0
        self.summary.gold = tonumber(summaryData.gold or self.summary.gold or 0) or 0
        self.summary.silver = tonumber(summaryData.silver or self.summary.silver or 0) or 0
        self.summary.copper = tonumber(summaryData.copper or self.summary.copper or 0) or 0
        updateInventorySummaryLabels(self)
        return true
    end

    function inventory:appendItem(itemInfo)
        local items = self.frames and self.frames.Items
        if items and items.addChatItem then
            return items:addChatItem(itemInfo)
        end

        if MultiBot.addItem and items then
            return MultiBot.addItem(items, itemInfo)
        end

        return nil
    end

    for _, key in ipairs(ACTION_ORDER) do
        inventory.buttons[key].doLeft = function(pButton)
            toggleInventoryAction(key, pButton)
        end
    end

    inventory.buttons.SellGrey.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "s *", {
            requiresTarget = true,
            clearActionState = true,
            refreshDelay = 0.5,
        })
    end

    inventory.buttons.SellVendor.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "s vendor", {
            requiresTarget = true,
            clearActionState = true,
            refresh = true,
        })
    end

    inventory.buttons.Open.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "open items")
    end

    inventory.buttons.BankOpen.doLeft = function(pButton)
        local botName = pButton.getName and pButton.getName() or nil
        if MultiBot.OpenBotBank then
            MultiBot.OpenBotBank(botName)
        end
    end

    inventory.buttons.GuildBankOpen.doLeft = function(pButton)
        local botName = pButton.getName and pButton.getName() or nil
        if MultiBot.OpenBotGuildBank then
            MultiBot.OpenBotGuildBank(botName)
        end
    end

    inventory.buttons.Buyback.doLeft = function(pButton)
        local botName = pButton.getName and pButton.getName() or nil
        if MultiBot.OpenBotBuyback then
            MultiBot.OpenBotBuyback(botName)
        end
    end

    setInventoryActionState("Sell", { cancelTrade = false })
    resetInventoryViewState()
    updateInventorySummaryLabels(inventory)

    return inventory
end

MultiBot.OnBridgeInventoryExactSnapshot = function(botName, snapshot)
    local inventory = MultiBot.inventory
    if not inventory or not inventory.IsVisible or not inventory:IsVisible() then
        return
    end

    if botName ~= inventory.name or type(snapshot) ~= "table" then
        return
    end

    if inventory.renderExactSnapshot then
        inventory:renderExactSnapshot(snapshot)
    end
end

MultiBot.OnBridgeInventoryItemMoveResult = function(botName, status, reason, srcBag, srcSlot, dstBag, dstSlot, command)
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    if command and inventory.itemMovePendingToken == command.token then
        inventory.itemMovePendingToken = nil
    end
    if inventory.clearItemMoveDrag then
        inventory:clearItemMoveDrag()
    end

    if not inventory.IsVisible or not inventory:IsVisible() or botName ~= inventory.name then
        return
    end
    if status == "OK" or reason == "TIMEOUT" or reason == "POSTCONDITION_FAILED" then
        local refreshed = MultiBot.RequestInventoryRefresh
            and MultiBot.RequestInventoryRefresh(botName, 0.30)
        if not refreshed and MultiBot.Comm and MultiBot.Comm.RequestInventoryExact then
            MultiBot.Comm.RequestInventoryExact(botName)
        end
    elseif MultiBot.Comm and MultiBot.Comm.RequestInventoryExact then
        MultiBot.Comm.RequestInventoryExact(botName)
    end
end