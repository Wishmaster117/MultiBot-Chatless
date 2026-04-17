if not MultiBot then return end

local OUTFIT_WINDOW_WIDTH = 590
local OUTFIT_WINDOW_HEIGHT = 430
local OUTFIT_PANEL_INSET = 8
local OUTFIT_PANEL_GAP = 6
local OUTFIT_LIST_WIDTH = 170
local OUTFIT_STATUS_HEIGHT = 30
local OUTFIT_BUTTON_HEIGHT = 22
local OUTFIT_LIST_BUTTON_HEIGHT = 20
local OUTFIT_BUTTON_TEXT_PADDING = 24
local OUTFIT_BUTTON_ROW_GAP = 6
local OUTFIT_LEFT_BUTTONS_AREA_HEIGHT = 60
local OUTFIT_ITEM_SIZE = 32
local OUTFIT_FAVORITE_ICON_SIZE = 10
local OUTFIT_FAVORITE_ICON_GAP = 4
local OUTFIT_FAVORITE_ICON_TEXTURE = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"
local OUTFIT_ITEM_SPACING_X = 38
local OUTFIT_ITEM_SPACING_Y = 38
local OUTFIT_ITEMS_PER_ROW = 6
local OUTFIT_UPDATE_REFRESH_DELAY  = 0.60
local OUTFIT_RESET_REFRESH_DELAY   = 0.60
local OUTFIT_EQUIP_REFRESH_DELAY   = 1.10
local OUTFIT_REPLACE_REFRESH_DELAY = 1.75
local OUTFIT_INSPECT_GAP = 12
local OUTFIT_PERSIST_FLUSH_DELAY = 0.25
local INV_SLOT_MAINHAND = INV_SLOT_MAINHAND or 16

local OUTFIT_LIST_SCROLL_NAME = "MultiBotOutfitListScrollFrame"
local OUTFIT_ITEMS_SCROLL_NAME = "MultiBotOutfitItemsScrollFrame"

local function outfitL(key, fallback)
    return MultiBot.L("info.outfits." .. key, fallback)
end

local function prepareTooltipAboveOutfits(owner, anchor)
    if not GameTooltip or not owner then
        return false
    end

    local outfitFrame =
        MultiBot.outfits
        and MultiBot.outfits.window
        and MultiBot.outfits.window.frame
        or nil

    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")

    if outfitFrame and outfitFrame.GetFrameStrata and GameTooltip.SetFrameStrata then
        local strata = outfitFrame:GetFrameStrata()
        if strata and strata ~= "" then
            GameTooltip:SetFrameStrata(strata)
        end
    elseif GameTooltip.SetFrameStrata then
        GameTooltip:SetFrameStrata("TOOLTIP")
    end

    if outfitFrame and outfitFrame.GetFrameLevel and GameTooltip.SetFrameLevel then
        GameTooltip:SetFrameLevel((outfitFrame:GetFrameLevel() or 0) + 64)
    end

    GameTooltip:Raise()
    return true
end

local function getWindowTitle(botName)
  local base = outfitL("window_title")
  if type(botName) == "string" and botName ~= "" then
    return base .. " - " .. botName
  end
  return base
end

local function outfitTip(key, fallback)
    return MultiBot.L("tips.outfits." .. key, fallback)
end

local function addBackdrop(frame, bgAlpha)
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

local function trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function getOutfitStore()
    local store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("outfits") or nil
    if type(store) ~= "table" then
        _G.MultiBotSave = _G.MultiBotSave or {}
        _G.MultiBotSave.outfits = _G.MultiBotSave.outfits or {}
        store = _G.MultiBotSave.outfits
    end

    store.favorites = store.favorites or {}
    store.lastSelected = store.lastSelected or {}
    store.lastUsed = store.lastUsed or {}
    return store
end

local function getBotFavorites(botName)
    local store = getOutfitStore()
    store.favorites[botName] = store.favorites[botName] or {}
    return store.favorites[botName]
end

local function isFavorite(botName, outfitName)
    local favorites = getBotFavorites(botName)
    return favorites[outfitName] and true or false
end

local function setFavorite(botName, outfitName, enabled)
    local favorites = getBotFavorites(botName)
    if enabled then
        favorites[outfitName] = true
    else
        favorites[outfitName] = nil
    end
end

local function toggleFavorite(botName, outfitName)
    local enabled = not isFavorite(botName, outfitName)
    setFavorite(botName, outfitName, enabled)
    return enabled
end

local function setLastSelected(botName, outfitName)
    local store = getOutfitStore()
    store.lastSelected[botName] = outfitName
end

local function getLastSelected(botName)
    local store = getOutfitStore()
    return store.lastSelected[botName]
end

local function setLastUsed(botName, outfitName)
    local store = getOutfitStore()
    store.lastUsed[botName] = outfitName
end

local function getLastUsed(botName)
    local store = getOutfitStore()
    return store.lastUsed[botName]
end

local function getUnitsRoot()
    return MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]
        or nil
end

local function getUnitFrame(botName)
    local units = getUnitsRoot()
    return units and units.frames and units.frames[botName] or nil
end

local function getUnitButton(botName, key)
    local unitFrame = getUnitFrame(botName)
    return unitFrame and unitFrame.getButton and unitFrame.getButton(key) or nil
end

local function syncOutfitButtonState(enabled, botName)
    local targetBot = botName
        or (MultiBot.outfits and MultiBot.outfits.name)
        or nil

    if type(targetBot) ~= "string" or targetBot == "" then
        return
    end

    local sourceButton = getUnitButton(targetBot, "Outfits")
    if not sourceButton then
        return
    end

    if enabled then
        if sourceButton.setEnable then
            sourceButton.setEnable()
        end
    else
        if sourceButton.setDisable then
            sourceButton.setDisable()
        end
    end
end

local function ensureInspectUI()
    if InspectFrame then
        return true
    end

    if LoadAddOn then
        pcall(LoadAddOn, "Blizzard_InspectUI")
    end

    return InspectFrame ~= nil
end

local function openInspectForBot(botName)
    if not botName or botName == "" or not MultiBot.toUnit then
        return
    end

    local unit = MultiBot.toUnit(botName)
    if not unit or not UnitExists(unit) then
        return
    end

    if not ensureInspectUI() then
        return
    end

    InspectUnit(unit)

    if InspectFrame and ShowUIPanel and not InspectFrame:IsShown() then
        ShowUIPanel(InspectFrame)
    end
end

local function closeInspectForBot(botName)
    if not botName or botName == "" or not InspectFrame or not InspectFrame:IsShown() then
        return
    end

    local inspectedName = nil
    if InspectFrame.unit and UnitExists(InspectFrame.unit) then
        inspectedName = UnitName(InspectFrame.unit)
    end

    if inspectedName and inspectedName ~= botName then
        return
    end

    if HideUIPanel then
        HideUIPanel(InspectFrame)
    else
        InspectFrame:Hide()
    end
end

local function placeOutfitsToRightOfInspect()
    local outfitFrame =
        MultiBot.outfits
        and MultiBot.outfits.window
        and MultiBot.outfits.window.frame
        or nil

    if not outfitFrame or not ensureInspectUI() or not InspectFrame then
        return
    end

    outfitFrame:ClearAllPoints()
    outfitFrame:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", OUTFIT_INSPECT_GAP, 0)
end

local function getUnitWaitButton(botName)
    local units = getUnitsRoot()
    return units and units.buttons and units.buttons[botName] or nil
end

local function getUnitFromBot(botName)
    if not botName or botName == "" or not MultiBot.toUnit then
        return nil
    end
    return MultiBot.toUnit(botName)
end

local function getEquipLinkForSlot(unit, slot)
    if not unit or unit == "" then
        return nil
    end
    local ok, link = pcall(GetInventoryItemLink, unit, slot)
    if not ok then
        return nil
    end
    return link
end

local function botHasTwoHandEquipped(botName)
    local unit = getUnitFromBot(botName)
    if not unit then
        return nil
    end

    if InspectUnit then
        pcall(InspectUnit, unit)
    else
        if LoadAddOn then pcall(LoadAddOn, "Blizzard_InspectUI") end
        if InspectUnit then pcall(InspectUnit, unit) end
    end

    local mainLink = getEquipLinkForSlot(unit, INV_SLOT_MAINHAND)
    if not mainLink then
        return nil
    end

    pcall(GetItemInfo, mainLink)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(mainLink)
    if equipLoc == "INVTYPE_2HWEAPON" then
        return true
    end
    return false
end

function MultiBot.SyncToolWindowButtons(activeBotName, activeKey)
    local units = getUnitsRoot()
    if not units or not MultiBot.index or not MultiBot.index.actives then
        return
    end

    local visible = {}
    local function markVisible(botName, key)
      if type(botName) ~= "string" or botName == "" or type(key) ~= "string" or key == "" then return end
      visible[botName] = visible[botName] or {}
      visible[botName][key] = true
    end
    if MultiBot.inventory and MultiBot.inventory.IsVisible and MultiBot.inventory:IsVisible() then
      markVisible(MultiBot.inventory.name, "Inventory")
    end
    if MultiBot.outfits and MultiBot.outfits.IsVisible and MultiBot.outfits:IsVisible() then
      markVisible(MultiBot.outfits.name, "Outfits")
    end
    markVisible(activeBotName, activeKey)

    for _, botName in pairs(MultiBot.index.actives) do
        if botName ~= UnitName("player") then
            local inventoryButton = getUnitButton(botName, "Inventory")
            local outfitButton = getUnitButton(botName, "Outfits")

            local botState = visible[botName] or {}

            if inventoryButton then
                if botState.Inventory and inventoryButton.setEnable then
                    inventoryButton.setEnable()
                elseif inventoryButton.setDisable then
                    inventoryButton.setDisable()
                end
            end
            if outfitButton then
                if botState.Outfits and outfitButton.setEnable then
                    outfitButton.setEnable()
                elseif outfitButton.setDisable then
                    outfitButton.setDisable()
                end
             end
         end
     end
 end

local OutfitUI = MultiBot.OutfitUI or {}
OutfitUI.entries = OutfitUI.entries or {}
OutfitUI.selectedName = OutfitUI.selectedName or nil
OutfitUI.pendingBot = OutfitUI.pendingBot or nil
OutfitUI.commandBusy = OutfitUI.commandBusy or false
OutfitUI.commandBusyBot = OutfitUI.commandBusyBot or nil
OutfitUI.commandBusyToken = OutfitUI.commandBusyToken or 0
OutfitUI.pendingRefresh = OutfitUI.pendingRefresh or false
OutfitUI.requestToken = OutfitUI.requestToken or 0
MultiBot.OutfitUI = OutfitUI

local function sortEntriesForBot(botName, entries)
    table.sort(entries, function(left, right)
        local leftFavorite = isFavorite(botName, left.name)
        local rightFavorite = isFavorite(botName, right.name)
        if leftFavorite ~= rightFavorite then
            return leftFavorite
        end

        return string.lower(left.name or "") < string.lower(right.name or "")
    end)
end

local function setActionButtonText(button, text)
    if not button then
        return
    end

    button:SetText(text or "")

    local fontString = (button.GetFontString and button:GetFontString()) or button.Text
    local textWidth = 0
    if fontString and fontString.GetStringWidth then
        textWidth = fontString:GetStringWidth() or 0
    end

    local minWidth = button.minAutoWidth or 0
    local padding = button.autoWidthPadding or OUTFIT_BUTTON_TEXT_PADDING
    button:SetWidth(math.max(minWidth, math.ceil(textWidth + padding)))
end

local function createActionButton(parent, minWidth, text, anchor, relativeTo, relativePoint, offsetX, offsetY, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button.minAutoWidth = minWidth or 0
    button.autoWidthPadding = OUTFIT_BUTTON_TEXT_PADDING
    button:SetHeight(OUTFIT_BUTTON_HEIGHT)
    button:SetPoint(anchor, relativeTo, relativePoint, offsetX, offsetY)
    setActionButtonText(button, text)
    button:SetScript("OnClick", onClick)
    return button
end

local function layoutButtonRowCentered(container, buttons, gap)
    if not container or type(buttons) ~= "table" or #buttons == 0 then
        return
    end

    local spacing = gap or 0
    local totalWidth = 0

    for index, button in ipairs(buttons) do
        if button then
            totalWidth = totalWidth + (button:GetWidth() or 0)
            if index > 1 then
                totalWidth = totalWidth + spacing
            end
        end
    end

    container:SetWidth(totalWidth)
    container:SetHeight(OUTFIT_BUTTON_HEIGHT)

    local previous = nil
    for _, button in ipairs(buttons) do
        button:ClearAllPoints()
        if not previous then
            button:SetPoint("LEFT", container, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
        end
        previous = button
    end
end

local function createOutfitEntryButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(OUTFIT_LIST_BUTTON_HEIGHT)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    local selected = button:CreateTexture(nil, "BACKGROUND")
    selected:SetTexture("Interface\\Buttons\\WHITE8x8")
    selected:SetAllPoints(button)
    selected:SetVertexColor(0.18, 0.24, 0.34, 0.55)
    selected:Hide()
    button.selectedTexture = selected

    local favoriteIcon = button:CreateTexture(nil, "OVERLAY")
    favoriteIcon:SetTexture(OUTFIT_FAVORITE_ICON_TEXTURE)
    favoriteIcon:SetWidth(OUTFIT_FAVORITE_ICON_SIZE)
    favoriteIcon:SetHeight(OUTFIT_FAVORITE_ICON_SIZE)
    favoriteIcon:SetPoint("LEFT", button, "LEFT", 4, 0)
    favoriteIcon:Hide()
    button.favoriteIcon = favoriteIcon

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", button, "LEFT", 4 + OUTFIT_FAVORITE_ICON_SIZE + OUTFIT_FAVORITE_ICON_GAP, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    button.text = text

    return button
end

local function createItemButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(OUTFIT_ITEM_SIZE)
    button:SetHeight(OUTFIT_ITEM_SIZE)
    button:RegisterForClicks("LeftButtonUp")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetAllPoints(button)
    button.border = border

    button:SetScript("OnEnter", function(self)
        if not self.link or not GameTooltip then
            return
        end

        if not prepareTooltipAboveOutfits(self, "ANCHOR_RIGHT") then
            return
        end

        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", function(self)
        if self.link and HandleModifiedItemClick then
            HandleModifiedItemClick(self.link)
        end
    end)

    return button
end

local function extractItemLinks(text)
    local links = {}
    if type(text) ~= "string" then
        return links
    end

    for link in string.gmatch(text, "|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r") do
        table.insert(links, link)
    end

    return links
end

local function parseOutfitLine(rawLine)
    if type(rawLine) ~= "string" or rawLine == "" then
        return nil
    end

    local lowerLine = string.lower(rawLine)
    if string.find(lowerLine, "outfit <name>", 1, true) then
        return nil
    end

    local name, payload = string.match(rawLine, "^%s*([^:]+):%s*(.*)$")
    if not name then
        return nil
    end

    name = trim(name)
    if name == "" then
        return nil
    end

    return {
        name = name,
        items = extractItemLinks(payload),
        raw = rawLine,
    }
end

function OutfitUI:IsVisible()
    return self.frame and self.frame.IsVisible and self.frame:IsVisible() or false
end

local function getItemEquipLoc(link)
    if not link or link == "" then
        return nil
    end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
    return equipLoc
end

local function isTwoHandEquipLoc(equipLoc)
    return equipLoc == "INVTYPE_2HWEAPON"
end

local function isGenericWeaponEquipLoc(equipLoc)
    return equipLoc == "INVTYPE_WEAPON"
end

local function isMainHandWeaponEquipLoc(equipLoc)
    return equipLoc == "INVTYPE_WEAPONMAINHAND"
        or equipLoc == "INVTYPE_WEAPON"
        or equipLoc == "INVTYPE_2HWEAPON"
end

local function isOffHandEquipLoc(equipLoc)
    return equipLoc == "INVTYPE_WEAPONOFFHAND"
        or equipLoc == "INVTYPE_HOLDABLE"
        or equipLoc == "INVTYPE_SHIELD"
end

local function buildTargetWeaponProfile(itemLinks)
    local profile = {
        hasWeapons        = false,
        usesTwoHand       = false,
        needsOffhand      = false,
        genericWeaponCount = 0,
    }

    for _, link in ipairs(itemLinks or {}) do
        local equipLoc = getItemEquipLoc(link)

        if isMainHandWeaponEquipLoc(equipLoc) or isOffHandEquipLoc(equipLoc) then
            profile.hasWeapons = true
        end

        if isTwoHandEquipLoc(equipLoc) then
            profile.usesTwoHand = true
        end

        if isOffHandEquipLoc(equipLoc) then
            profile.needsOffhand = true
        end

        if isGenericWeaponEquipLoc(equipLoc) then
            profile.genericWeaponCount = profile.genericWeaponCount + 1
        end
    end

    if profile.genericWeaponCount >= 2 then
        profile.needsOffhand = true
    end

    return profile
end

local function prewarmItemCache(items)
    if type(items) ~= "table" then return end
    for _, link in ipairs(items) do
        GetItemInfo(link)
    end
end

local function shouldForceReplaceForWeaponSwap(entry)
    if not entry or not entry.items then
        return false
    end

    local targetProfile = buildTargetWeaponProfile(entry.items)
    if targetProfile.usesTwoHand then return true end
    if targetProfile.needsOffhand then return true end
    if targetProfile.hasWeapons then
        for _, link in ipairs(entry.items) do
            if getItemEquipLoc(link) == nil then
                return true
            end
        end
    end

    return false
end

function OutfitUI:SetStatus(message)
    if self.statusText then
        self.statusText:SetText(message or "")
    end
end

function OutfitUI:FindEntry(name)
    if not name or name == "" then
        return nil
    end

    for _, entry in ipairs(self.entries or {}) do
        if entry.name == name then
            return entry
        end
    end

    return nil
end

function OutfitUI:GetSelectedEntry()
    return self:FindEntry(self.selectedName)
end

function OutfitUI:IsCommandBusy(botName)
    if not self.commandBusy then
        return false
    end

    if not botName or botName == "" then
        return true
    end

    return self.commandBusyBot == botName
end

function OutfitUI:BeginCommandLock(botName)
    self.commandBusy      = true
    self.commandBusyBot   = botName
    self.pendingRefresh   = false
    self.commandBusyToken = (self.commandBusyToken or 0) + 1
    self:RenderSelectedOutfit()
    return self.commandBusyToken
end

function OutfitUI:EndCommandLock(botName, token, refreshAfter)
    if not self.commandBusy then
        return
    end

    if botName and self.commandBusyBot and botName ~= self.commandBusyBot then
        return
    end

    if token and token ~= self.commandBusyToken then
        return
    end

    local refreshBot   = self.commandBusyBot or botName or self.botName
    local shouldRefresh = refreshAfter or self.pendingRefresh

    self.commandBusy    = false
    self.commandBusyBot = nil
    self.pendingRefresh = false
    self:RenderSelectedOutfit()

    if shouldRefresh
        and refreshBot and refreshBot ~= ""
        and MultiBot.inventory
        and MultiBot.inventory:IsVisible()
    then
        self:RequestList(refreshBot)
    end
end

function OutfitUI:RenderEntryList()
    self.listButtons = self.listButtons or {}
    self.entries = self.entries or {}

    if not self.listChild then
        return
    end

    local entries = self.entries or {}
    local height = math.max(#entries * OUTFIT_LIST_BUTTON_HEIGHT, OUTFIT_LIST_BUTTON_HEIGHT)
    self.listChild:SetHeight(height)

    for index, entry in ipairs(entries) do
        local button = self.listButtons[index]
        if not button then
            button = createOutfitEntryButton(self.listChild)
            self.listButtons[index] = button
        end

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.listChild, "TOPLEFT", 0, -((index - 1) * OUTFIT_LIST_BUTTON_HEIGHT))
        button:SetPoint("TOPRIGHT", self.listChild, "TOPRIGHT", 0, -((index - 1) * OUTFIT_LIST_BUTTON_HEIGHT))
        button.entry = entry

        local favorite = isFavorite(self.botName or "", entry.name)
        if button.favoriteIcon then
            if favorite then button.favoriteIcon:Show() else button.favoriteIcon:Hide() end
        end

        button.text:SetText(entry.name)
        if entry.name == self.selectedName then
            button.selectedTexture:Show()
        else
            button.selectedTexture:Hide()
        end

        button:SetScript("OnClick", function(clicked, mouseButton)
            if mouseButton == "RightButton" then
                local enabled = toggleFavorite(self.botName or "", clicked.entry.name)
                if enabled then
                    self:SetStatus(outfitL("pinned"))
                else
                    self:SetStatus(outfitL("unpinned"))
                end
                sortEntriesForBot(self.botName or "", self.entries)
                self:RenderEntryList()
                self:RenderSelectedOutfit()
                return
            end

            self.selectedName = clicked.entry.name
            setLastSelected(self.botName or "", self.selectedName)
            self:RenderEntryList()
            self:RenderSelectedOutfit()
        end)

        button:Show()
    end

    for index = #entries + 1, #self.listButtons do
        self.listButtons[index]:Hide()
    end
end

function OutfitUI:RenderSelectedOutfit()
    self.itemButtons = self.itemButtons or {}

    local selected = self:GetSelectedEntry()

    if self.selectedNameText then
        if selected then
            local favorite = isFavorite(self.botName or "", selected.name)
            if self.selectedFavoriteIcon then
                if favorite then
                    self.selectedFavoriteIcon:Show()
                else
                    self.selectedFavoriteIcon:Hide()
                end
            end
            self.selectedNameText:SetText(selected.name)
        else
            if self.selectedFavoriteIcon then self.selectedFavoriteIcon:Hide() end
            self.selectedNameText:SetText(outfitL("none_selected"))
        end
    end

    local items = selected and selected.items or {}
    local child = self.itemsChild
    if child then
        local rows = math.max(1, math.ceil(math.max(1, #items) / OUTFIT_ITEMS_PER_ROW))
        child:SetHeight(rows * OUTFIT_ITEM_SPACING_Y)
    end

    for index, link in ipairs(items) do
        local button = self.itemButtons[index]
        if not button then
            button = createItemButton(self.itemsChild)
            self.itemButtons[index] = button
        end

        local column = (index - 1) % OUTFIT_ITEMS_PER_ROW
        local row = math.floor((index - 1) / OUTFIT_ITEMS_PER_ROW)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.itemsChild, "TOPLEFT", column * OUTFIT_ITEM_SPACING_X, -(row * OUTFIT_ITEM_SPACING_Y))
        button.link = link
        local texture = GetItemIcon(link)
        if not texture then
            local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(link)
            texture = itemTexture or GetItemIcon(itemLink or itemName or "")
        end
        button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        button:Show()
    end

    for index = #items + 1, #self.itemButtons do
        self.itemButtons[index]:Hide()
    end

    if self.emptyItemsText then
        if selected and #items == 0 then
            self.emptyItemsText:SetText(outfitL("empty"))
            self.emptyItemsText:Show()
        elseif not selected then
            self.emptyItemsText:SetText(outfitL("select_left"))
            self.emptyItemsText:Show()
        else
            self.emptyItemsText:Hide()
        end
    end

    local hasBot = type(self.botName) == "string" and self.botName ~= ""
    local hasSelection = selected ~= nil
    if self.pinButton then
        if hasSelection then
            self.pinButton:Enable()
            setActionButtonText(self.pinButton, isFavorite(self.botName or "", selected.name) and outfitL("unpin") or outfitL("pin"))
        else
            self.pinButton:Disable()
            setActionButtonText(self.pinButton, outfitL("pin"))
        end
    end

    local isBusy = self:IsCommandBusy(self.botName)

    if self.refreshButton then
        if hasBot and not isBusy then self.refreshButton:Enable() else self.refreshButton:Disable() end
    end

    if self.newButton then
        if hasBot and not isBusy then self.newButton:Enable() else self.newButton:Disable() end
    end

    if self.pinButton then
        if hasSelection and not isBusy then self.pinButton:Enable() else self.pinButton:Disable() end
    end

    local actionButtons = { self.equipButton, self.replaceButton, self.updateButton, self.resetButton }
    for _, button in ipairs(actionButtons) do
        if button then
            if hasSelection and not isBusy then button:Enable() else button:Disable() end
        end
    end
end

function OutfitUI:SelectBestEntry()
    local desired = getLastSelected(self.botName or "") or getLastUsed(self.botName or "")
    if desired and self:FindEntry(desired) then
        self.selectedName = desired
        return
    end

    self.selectedName = self.entries[1] and self.entries[1].name or nil
end

function OutfitUI:FinishList(botName)
    if botName and botName ~= "" then
        self.botName = botName
        if self.frame and self.frame.setBotName then
            self.frame:setBotName(botName)
        end
    end

    self.pendingBot = nil
    sortEntriesForBot(self.botName or "", self.entries)
    self:SelectBestEntry()

    for _, entry in ipairs(self.entries) do
        prewarmItemCache(entry.items)
    end

    self:RenderEntryList()
    self:RenderSelectedOutfit()

    if #self.entries == 0 then
        self:SetStatus(outfitL("no_outfits"))
    else
        self:SetStatus(outfitL("loaded"))
    end
end

function OutfitUI:RequestList(botName)
    if not botName or botName == "" then
        return false
    end

    if self:IsCommandBusy(botName) then
        self.pendingRefresh = true
        self:SetStatus(outfitL("busy_wait"))
        return false
    end

    self.listButtons = self.listButtons or {}
    self.itemButtons = self.itemButtons or {}

    self.botName = botName
    if self.frame and self.frame.setBotName then
        self.frame:setBotName(botName)
    end

    self.entries = {}
    self.selectedName = nil
    self.pendingBot = botName
    self:RenderEntryList()
    self:RenderSelectedOutfit()
    self:SetStatus(outfitL("loading"))

    local waitButton = getUnitWaitButton(botName)
    if waitButton then
        waitButton.waitFor = "OUTFITS"
    end

    self.requestToken = (self.requestToken or 0) + 1
    local token = self.requestToken
    if MultiBot.TimerAfter then
        MultiBot.TimerAfter(0.8, function()
            if self.pendingBot == botName and token == self.requestToken then
                self:FinishList(botName)
                local refreshWaitButton = getUnitWaitButton(botName)
                if refreshWaitButton and refreshWaitButton.waitFor == "OUTFITS" then
                    refreshWaitButton.waitFor = ""
                end
            end
        end)
    end

    SendChatMessage("outfit ?", "WHISPER", nil, botName)
    return true
end

function MultiBot.HandleOutfitChatLine(tButton, line, botName)
    if not OutfitUI.pendingBot or OutfitUI.pendingBot ~= botName then
        return false
    end

    if type(line) ~= "string" then
        return false
    end

    local lowerLine = string.lower(line)
    if string.find(lowerLine, "outfit <name>", 1, true) then
        OutfitUI:FinishList(botName)
        if tButton then
            tButton.waitFor = ""
        end
        return true
    end

    local entry = parseOutfitLine(line)
    if entry then
        table.insert(OutfitUI.entries, entry)
        return true
    end

    if line == "" or string.sub(line, 1, 3) == "---" then
        return true
    end

    return false
end

function OutfitUI:RunCommand(commandSuffix, statusText, refreshDelay, persistDelay)
    local botName = self.botName or (self.frame and self.frame.name) or nil
    if not botName or botName == "" then
        return false
    end

    local isEquipCmd = false
    if type(commandSuffix) == "string" and string.match(commandSuffix, "%s+equip%s*$") then
        isEquipCmd = true
    end

    if isEquipCmd then
        local twoHand = botHasTwoHandEquipped(botName)
        if twoHand == true or twoHand == nil then
            commandSuffix = string.gsub(commandSuffix, "%s*equip%s*$", " replace")
            statusText = outfitL("equip_auto_replace")
            if not refreshDelay or refreshDelay <= 0 then
                refreshDelay = OUTFIT_REPLACE_REFRESH_DELAY
            end
            -- print("OutfitUI DEBUG: forced replace, commandSuffix='" .. tostring(commandSuffix) .. "'")
        end
    end

    if type(commandSuffix) == "string" then
        commandSuffix = string.gsub(commandSuffix, "%s+", " ")
        commandSuffix = trim(commandSuffix)
    end

    -- print("OutfitUI DEBUG: sending -> 'outfit " .. tostring(commandSuffix) .. "' to " .. tostring(botName))
    SendChatMessage("outfit " .. commandSuffix, "WHISPER", nil, botName)
    self:SetStatus(statusText)

    if self:IsCommandBusy(botName) then
        self.pendingRefresh = true
        self:SetStatus(outfitL("busy_wait"))
        return false
    end

    local commandToken = nil
    if type(refreshDelay) == "number" and refreshDelay > 0 then
        commandToken = self:BeginCommandLock(botName)
    end

    if type(persistDelay) == "number" and persistDelay >= 0 then
        local flushBotName = botName
        if MultiBot.TimerAfter then
            MultiBot.TimerAfter(persistDelay, function()
                SendChatMessage("nc +chat", "WHISPER", nil, flushBotName)
            end)
        else
            SendChatMessage("nc +chat", "WHISPER", nil, flushBotName)
        end
    end

    if type(refreshDelay) == "number" and refreshDelay > 0 and MultiBot.TimerAfter then
        MultiBot.TimerAfter(refreshDelay, function()
            if commandToken then
                self:EndCommandLock(botName, commandToken, true)
            elseif MultiBot.inventory and MultiBot.inventory:IsVisible() then
                self:RequestList(botName)
            end
        end)
    elseif commandToken then
        self:EndCommandLock(botName, commandToken, true)
    end

    return true
end

function OutfitUI:CreateFromCurrent()
    if type(MultiBot.ShowPrompt) ~= "function" then
        UIErrorsFrame:AddMessage(outfitL("prompt_missing"), 1, 0.2, 0.2, 1)
        return
    end

    local anchorFrame = nil
    if MultiBot.outfits and MultiBot.outfits.window and MultiBot.outfits.window.frame then
        anchorFrame = MultiBot.outfits.window.frame
    end

    MultiBot.ShowPrompt(outfitL("new_title"), function(value)
        local outfitName = trim(value)
        if outfitName == "" then
            return
        end

        self.selectedName = outfitName
        setLastSelected(self.botName or "", outfitName)
        self:RunCommand(outfitName .. " update", outfitL("created"), 0.35, OUTFIT_PERSIST_FLUSH_DELAY)
    end, "", anchorFrame)
end

function OutfitUI:PinSelected()
    local selected = self:GetSelectedEntry()
    if not selected then
        return
    end

    local enabled = toggleFavorite(self.botName or "", selected.name)
    if enabled then
        self:SetStatus(outfitL("pinned"))
    else
        self:SetStatus(outfitL("unpinned"))
    end
    sortEntriesForBot(self.botName or "", self.entries)
    self:RenderEntryList()
    self:RenderSelectedOutfit()
end

function OutfitUI:EquipSelected(replaceCurrent)
    local selected = self:GetSelectedEntry()
    if not selected then
        return
    end

    setLastSelected(self.botName or "", selected.name)
    setLastUsed(self.botName or "", selected.name)

    local forceReplace = false
    if not replaceCurrent then
        forceReplace = shouldForceReplaceForWeaponSwap(selected)
    end

    if replaceCurrent or forceReplace then
        if forceReplace then
            self:SetStatus(outfitL("equip_auto_replace"))
        end

        self:RunCommand(selected.name .. " replace", outfitL("replace_sent"), OUTFIT_REPLACE_REFRESH_DELAY)
    else
        self:RunCommand(selected.name .. " equip", outfitL("equip_sent"), OUTFIT_EQUIP_REFRESH_DELAY)
    end
end

function OutfitUI:UpdateSelected()
    local selected = self:GetSelectedEntry()
    if not selected then
        return
    end

    setLastSelected(self.botName or "", selected.name)
    self:RunCommand(selected.name .. " update", outfitL("updated"), OUTFIT_UPDATE_REFRESH_DELAY)
end

function OutfitUI:ResetSelected()
    local selected = self:GetSelectedEntry()
    if not selected then
        return
    end

    self:RunCommand(selected.name .. " reset", outfitL("reset_sent"), OUTFIT_RESET_REFRESH_DELAY)
end

function MultiBot.InitializeOutfitFrame()
    if MultiBot.outfits and MultiBot.outfits.__aceInitialized then
        return MultiBot.outfits
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI(outfitL("acegui_required")) or nil
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(getWindowTitle(nil))
    window:SetLayout("Manual")
    window:SetWidth(OUTFIT_WINDOW_WIDTH)
    window:SetHeight(OUTFIT_WINDOW_HEIGHT)
    window:EnableResize(false)
    window.frame:SetClampedToScreen(true)
    window.frame:SetMovable(true)
    window.frame:EnableMouse(true)

    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotOutfits") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_outfits_popup") end

    window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -754, 238)
    window:Hide()

    window.frame:HookScript("OnShow", function()
        syncOutfitButtonState(true)
        MultiBot.SyncToolWindowButtons(MultiBot.outfits and MultiBot.outfits.name or nil, "Outfits")
    end)

    window.frame:HookScript("OnHide", function()
        syncOutfitButtonState(false)
        closeInspectForBot(MultiBot.outfits and MultiBot.outfits.name or nil)
        MultiBot.SyncToolWindowButtons(nil, nil)
    end)

    local content = window.content
    content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 12, -30)
    content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -12, 12)

    local root = CreateFrame("Frame", nil, content)
    root:SetAllPoints(content)

    local leftPanel = CreateFrame("Frame", nil, root)
    leftPanel:SetPoint("TOPLEFT", root, "TOPLEFT", OUTFIT_PANEL_INSET, -OUTFIT_PANEL_INSET)
    leftPanel:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", OUTFIT_PANEL_INSET, OUTFIT_PANEL_INSET + OUTFIT_STATUS_HEIGHT)
    leftPanel:SetWidth(OUTFIT_LIST_WIDTH)
    addBackdrop(leftPanel)

    local rightPanel = CreateFrame("Frame", nil, root)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", OUTFIT_PANEL_GAP, 0)
    rightPanel:SetPoint("TOPRIGHT", root, "TOPRIGHT", -OUTFIT_PANEL_INSET, -OUTFIT_PANEL_INSET)
    rightPanel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -OUTFIT_PANEL_INSET, OUTFIT_PANEL_INSET + OUTFIT_STATUS_HEIGHT)
    addBackdrop(rightPanel)

    local statusText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", OUTFIT_PANEL_INSET + 2, OUTFIT_PANEL_INSET + 12)
    statusText:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -OUTFIT_PANEL_INSET - 2, OUTFIT_PANEL_INSET + 12)
    statusText:SetJustifyH("LEFT")
    statusText:SetText(outfitL("idle"))

    local hintText = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hintText:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", OUTFIT_PANEL_INSET + 2, OUTFIT_PANEL_INSET)
    hintText:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -OUTFIT_PANEL_INSET - 2, OUTFIT_PANEL_INSET)
    hintText:SetJustifyH("LEFT")
    hintText:SetText(outfitL("replace_warning"))

    local leftTitle = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftTitle:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -8)
    leftTitle:SetText(outfitL("list"))

    local listScroll = CreateFrame("ScrollFrame", OUTFIT_LIST_SCROLL_NAME, leftPanel, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 8, -26)
    listScroll:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -26, OUTFIT_LEFT_BUTTONS_AREA_HEIGHT)

    local listChild = CreateFrame("Frame", "MultiBotOutfitListScrollChild", listScroll)
    listChild:SetWidth(OUTFIT_LIST_WIDTH - 34)
    listChild:SetHeight(OUTFIT_LIST_BUTTON_HEIGHT)
    listScroll:SetScrollChild(listChild)

    local refreshButton = createActionButton(leftPanel, 0, outfitL("refresh"), "BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 8, 8, function()
        if OutfitUI.botName then
            OutfitUI:RequestList(OutfitUI.botName)
        end
    end)

    local newButton = createActionButton(leftPanel, 0, outfitL("new"), "LEFT", refreshButton, "RIGHT", OUTFIT_BUTTON_ROW_GAP, 0, function()
        OutfitUI:CreateFromCurrent()
    end)

    local pinButton = createActionButton(leftPanel, 0, outfitL("pin"), "BOTTOM", leftPanel, "BOTTOM", 0, 8, function()
        OutfitUI:PinSelected()
    end)

    do
        local topRowWidth = refreshButton:GetWidth() + OUTFIT_BUTTON_ROW_GAP + newButton:GetWidth()
        local topRowOffsetX = math.floor((OUTFIT_LIST_WIDTH - topRowWidth) / 2)

        refreshButton:ClearAllPoints()
        refreshButton:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", topRowOffsetX, 8 + OUTFIT_BUTTON_HEIGHT + 4)

        newButton:ClearAllPoints()
        newButton:SetPoint("LEFT", refreshButton, "RIGHT", OUTFIT_BUTTON_ROW_GAP, 0)
    end

    local rightButtonsRow = CreateFrame("Frame", nil, rightPanel)

    local selectedNameText = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedNameText:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10, -10)
    selectedNameText:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, -10)
    selectedNameText:SetJustifyH("LEFT")
    selectedNameText:SetText(outfitL("none_selected"))

    local selectedFavoriteIcon = rightPanel:CreateTexture(nil, "OVERLAY")
    selectedFavoriteIcon:SetTexture(OUTFIT_FAVORITE_ICON_TEXTURE)
    selectedFavoriteIcon:SetWidth(OUTFIT_FAVORITE_ICON_SIZE)
    selectedFavoriteIcon:SetHeight(OUTFIT_FAVORITE_ICON_SIZE)
    selectedFavoriteIcon:SetPoint("LEFT", rightPanel, "TOPLEFT", 10, -18)
    selectedFavoriteIcon:Hide()

    selectedNameText:ClearAllPoints()
    selectedNameText:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 10 + OUTFIT_FAVORITE_ICON_SIZE + OUTFIT_FAVORITE_ICON_GAP, -10)
    selectedNameText:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -10, -10)

    rightButtonsRow:SetPoint("TOP", selectedNameText, "BOTTOM", 0, -10)

    local equipButton = createActionButton(rightButtonsRow, 0, outfitL("equip"), "LEFT", rightButtonsRow, "LEFT", 0, 0, function()
        OutfitUI:EquipSelected(false)
    end)
    equipButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    equipButton:SetScript("OnClick", function(_, mouseButton)
        OutfitUI:EquipSelected(mouseButton == "RightButton")
    end)
    equipButton:SetScript("OnEnter", function(self)
        if not prepareTooltipAboveOutfits(self, "ANCHOR_RIGHT") then
            return
        end

        GameTooltip:SetText(outfitTip("equip"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    equipButton:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)

    local replaceButton = createActionButton(rightButtonsRow, 0, outfitL("replace"), "LEFT", equipButton, "RIGHT", OUTFIT_BUTTON_ROW_GAP, 0, function()
        OutfitUI:EquipSelected(true)
    end)

    local updateButton = createActionButton(rightButtonsRow, 0, outfitL("update"), "LEFT", replaceButton, "RIGHT", OUTFIT_BUTTON_ROW_GAP, 0, function()
        OutfitUI:UpdateSelected()
    end)

    local resetButton = createActionButton(rightButtonsRow, 0, outfitL("reset"), "LEFT", updateButton, "RIGHT", OUTFIT_BUTTON_ROW_GAP, 0, function()
        OutfitUI:ResetSelected()
    end)

    layoutButtonRowCentered(rightButtonsRow, { equipButton, replaceButton, updateButton, resetButton }, OUTFIT_BUTTON_ROW_GAP)

    local itemsScroll = CreateFrame("ScrollFrame", OUTFIT_ITEMS_SCROLL_NAME, rightPanel, "UIPanelScrollFrameTemplate")
    itemsScroll:SetPoint("TOPLEFT", equipButton, "BOTTOMLEFT", 0, -12)
    itemsScroll:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -26, 10)

    local itemsChild = CreateFrame("Frame", "MultiBotOutfitItemsScrollChild", itemsScroll)
    itemsChild:SetWidth(240)
    itemsChild:SetHeight(OUTFIT_ITEM_SPACING_Y)
    itemsScroll:SetScrollChild(itemsChild)

    local emptyItemsText = itemsChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    emptyItemsText:SetPoint("TOPLEFT", itemsChild, "TOPLEFT", 2, -4)
    emptyItemsText:SetPoint("TOPRIGHT", itemsChild, "TOPRIGHT", -2, -4)
    emptyItemsText:SetJustifyH("LEFT")
    emptyItemsText:SetText(outfitL("select_left"))

    local outfits = {
        __aceInitialized = true,
        window = window,
        root = root,
        name = "",
    }

    function outfits:Show()
        self.window:Show()
    end

    function outfits:Hide()
        self.window:Hide()
    end

    function outfits:IsVisible()
        return self.window and self.window.frame and self.window.frame:IsShown() or false
    end

    function outfits:GetRight()
        return self.window and self.window.frame and self.window.frame:GetRight() or 0
    end

    function outfits:GetBottom()
        return self.window and self.window.frame and self.window.frame:GetBottom() or 0
    end

    function outfits:setBotName(botName)
        self.name = botName or ""
        if self.window and self.window.SetTitle then
            self.window:SetTitle(getWindowTitle(self.name))
        end
        return self
    end

    MultiBot.outfits = outfits
    OutfitUI.frame = outfits
    OutfitUI.botName = nil
    OutfitUI.statusText = statusText
    OutfitUI.hintText = hintText
    OutfitUI.listChild = listChild
    OutfitUI.listButtons = OutfitUI.listButtons or {}
    OutfitUI.itemButtons = OutfitUI.itemButtons or {}
    OutfitUI.itemsChild = itemsChild
    OutfitUI.selectedNameText = selectedNameText
    OutfitUI.emptyItemsText = emptyItemsText
    OutfitUI.selectedFavoriteIcon = selectedFavoriteIcon
    OutfitUI.refreshButton = refreshButton
    OutfitUI.newButton = newButton
    OutfitUI.pinButton = pinButton
    OutfitUI.equipButton = equipButton
    OutfitUI.replaceButton = replaceButton
    OutfitUI.updateButton = updateButton
    OutfitUI.resetButton = resetButton

    OutfitUI:RenderEntryList()
    OutfitUI:RenderSelectedOutfit()
    return outfits
end

function MultiBot.OpenBotOutfits(botName, sourceButton)
    if not botName or botName == "" then
        return false
    end

    local outfits = MultiBot.outfits
    if (not outfits or not outfits.__aceInitialized) and MultiBot.InitializeOutfitFrame then
        outfits = MultiBot.InitializeOutfitFrame()
    end
    if not outfits then
        return false
    end

    if outfits:IsVisible() and outfits.name == botName then
        closeInspectForBot(botName)
        outfits:Hide()
        return true
    end

    openInspectForBot(botName)
    outfits:setBotName(botName)
    outfits:Show()
    placeOutfitsToRightOfInspect()

    if sourceButton and sourceButton.setEnable then
        sourceButton.setEnable()
    end

    OutfitUI:RequestList(botName)
    return true
end