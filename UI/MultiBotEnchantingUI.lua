if not MultiBot then
    return
end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local ENCHANT_WINDOW_WIDTH = 440
local ENCHANT_WINDOW_HEIGHT = 480
local ENCHANT_PAGE_SIZE = 9
local ENCHANT_ROW_HEIGHT = 34
local ENCHANT_REFRESH_DELAY = 0.60

local EnchantUI = MultiBot.EnchantingUI or {}
MultiBot.EnchantingUI = EnchantUI

local function L(key, fallback)
    if MultiBot and type(MultiBot.L) == "function" then
        return MultiBot.L(key, fallback)
    end
    return fallback or key
end

local function safeDelay(delaySeconds, callback)
    if type(callback) ~= "function" then
        return
    end
    if MultiBot and type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delaySeconds or 0, callback)
        return
    end
    callback()
end

local function sameBotName(left, right)
    return string.lower(tostring(left or "")) == string.lower(tostring(right or ""))
end

local function setButtonEnabled(button, enabled)
    if not button then
        return
    end
    if enabled then
        if button.Enable then button:Enable() end
        if button.SetAlpha then button:SetAlpha(1) end
    else
        if button.Disable then button:Disable() end
        if button.SetAlpha then button:SetAlpha(0.45) end
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
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or 0.94)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

local function getWindowTitle(botName)
    local title = L("lootmaster.profession.enchanting", "Enchanting")
    if type(botName) == "string" and botName ~= "" then
        return title .. " - " .. botName
    end
    return title
end

local function getSpellData(spellId)
    local resolvedSpellId = tonumber(spellId or 0) or 0
    local name, _, icon = GetSpellInfo(resolvedSpellId)
    return name or string.format(L("enchant.trade.spell_fallback", "Spell %d"), resolvedSpellId), icon
end

local function materialLabel(material)
    local itemId = tonumber(material and material.itemId or 0) or 0
    local name = nil
    if itemId > 0 and GetItemInfo then
        name = GetItemInfo(itemId)
    end
    if not name then
        name = string.format(L("enchant.trade.item_fallback", "Item %d"), itemId)
    end
    return name
end

local function materialSummary(materials)
    local values = {}
    for _, material in ipairs(materials or {}) do
        values[#values + 1] = tostring(tonumber(material.available or 0) or 0) .. "/" .. tostring(tonumber(material.required or 0) or 0)
        if #values >= 3 then
            break
        end
    end
    if #values == 0 then
        return L("enchant.trade.no_reagents", "No reagents")
    end
    return table.concat(values, "  ")
end

function EnchantUI:HasMaterialItem(itemId)
    itemId = tonumber(itemId or 0) or 0
    if itemId <= 0 then
        return false
    end

    for _, entry in ipairs(self.entries or {}) do
        for _, material in ipairs(entry.materials or {}) do
            if tonumber(material.itemId or 0) == itemId then
                return true
            end
        end
    end

    return false
end

local function getReasonText(reason)
    reason = string.upper(tostring(reason or ""))
    if reason == "" or reason == "OK" then
        return ""
    elseif reason == "NO_TRADE" then
        return L("enchant.trade.reason.NO_TRADE", "Open a trade with this bot.")
    elseif reason == "WRONG_TRADER" then
        return L("enchant.trade.reason.WRONG_TRADER", "The open trade is not with this bot.")
    elseif reason == "NO_TRADE_ITEM" then
        return L("enchant.trade.reason.NO_TRADE_ITEM", "Place your item in the Will not be traded slot.")
    elseif reason == "NOT_ENCHANTER" then
        return L("enchant.trade.reason.NOT_ENCHANTER", "This bot is not an enchanter.")
    elseif reason == "UNKNOWN_ENCHANT" then
        return L("enchant.trade.reason.UNKNOWN_ENCHANT", "This bot does not know that enchantment.")
    elseif reason == "BAD_ENCHANT" then
        return L("enchant.trade.reason.BAD_ENCHANT", "This spell is not a valid enchanting service.")
    elseif reason == "ALREADY_ENCHANTED" then
        return L("enchant.trade.reason.ALREADY_ENCHANTED", "An enchantment is already pending in this trade.")
    elseif reason == "BAD_TARGET" or reason == "NOT_TRADEABLE" then
        return L("enchant.trade.reason.BAD_TARGET", "That item cannot receive this enchantment.")
    elseif reason == "IN_COMBAT" then
        return L("enchant.trade.reason.IN_COMBAT", "The bot cannot enchant while in combat.")
    elseif reason == "FORBIDDEN" then
        return L("enchant.trade.reason.FORBIDDEN", "You are not allowed to control this bot.")
    elseif reason == "NO_BOT" then
        return L("enchant.trade.reason.NO_BOT", "The bot is not available.")
    elseif reason == "RATE_LIMIT" then
        return L("enchant.trade.reason.RATE_LIMIT", "Too many enchanting requests. Try again shortly.")
    elseif reason == "TIMEOUT" then
        return L("enchant.trade.reason.TIMEOUT", "The enchanting request timed out.")
    elseif reason == "DISCONNECTED" then
        return L("enchant.trade.reason.DISCONNECTED", "The bridge disconnected.")
    elseif reason == "NO_SESSION" then
        return L("enchant.trade.reason.NO_SESSION", "The bot session is not available.")
    elseif reason == "LOST_CONTROL" then
        return L("enchant.trade.reason.LOST_CONTROL", "The bot cannot act right now.")
    elseif reason == "IN_FLIGHT" then
        return L("enchant.trade.reason.IN_FLIGHT", "The bot cannot enchant while in flight.")
    elseif reason == "CHANNELING" then
        return L("enchant.trade.reason.CHANNELING", "The bot is already channeling another spell.")
    elseif reason == "TRY_AGAIN" then
        return L("enchant.trade.reason.TRY_AGAIN", "The enchantment could not start. Try again.")
    elseif reason == "NO_MATERIALS" then
        return L("profession.recipes.craft.reason.NO_MATERIALS", "Missing reagents.")
    elseif reason == "MISSING_TOOLS" then
        return L("profession.recipes.craft.reason.MISSING_TOOLS", "A required enchanting tool is missing.")
    elseif reason == "MOVING" then
        return L("profession.recipes.craft.reason.MOVING", "The bot is moving.")
    elseif reason == "NOT_STANDING" then
        return L("profession.recipes.craft.reason.NOT_STANDING", "The bot must be standing.")
    elseif reason == "NOT_READY" then
        return L("profession.recipes.craft.reason.NOT_READY", "The spell is not ready.")
    elseif reason == "OUT_OF_RANGE" then
        return L("profession.recipes.craft.reason.OUT_OF_RANGE", "The target is out of range.")
    end
    return string.format(L("enchant.trade.reason.UNKNOWN", "Enchanting failed (%s)."), reason)
end
local function showEnchantTooltip(owner, entry)
    if not owner or not entry or not GameTooltip then
        return
    end
    EnchantUI.tooltipOwner = owner
    EnchantUI.tooltipEntry = entry
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("spell:" .. tostring(entry.spellId or 0))
    if entry.materials and #entry.materials > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L("enchant.trade.materials", "Reagents"), 1, 0.82, 0)
        for _, material in ipairs(entry.materials) do
            local required = tonumber(material.required or 0) or 0
            local available = tonumber(material.available or 0) or 0
            local enough = available >= required
            GameTooltip:AddDoubleLine(
                materialLabel(material),
                tostring(available) .. "/" .. tostring(required),
                1, 1, 1,
                enough and 0.2 or 1, enough and 1 or 0.25, enough and 0.2 or 0.25
            )
        end
    end
    if tonumber(entry.hasTools or 1) == 0 then
        GameTooltip:AddLine(L("profession.recipes.craft.reason.MISSING_TOOLS", "Required enchanting tool missing."), 1, 0.25, 0.25, true)
    end
    GameTooltip:Show()
end

local function hideEnchantTooltip()
    EnchantUI.tooltipOwner = nil
    EnchantUI.tooltipEntry = nil
    if GameTooltip then
        GameTooltip:Hide()
    end
end

function EnchantUI:GetFilteredEntries()
    local filtered = {}
    local search = string.lower(tostring(self.searchText or ""))
    for _, entry in ipairs(self.entries or {}) do
        local name = getSpellData(entry.spellId)
        if search == "" or string.find(string.lower(name), search, 1, true) then
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

function EnchantUI:GetMaxPage()
    local count = #self:GetFilteredEntries()
    return math.max(1, math.ceil(count / ENCHANT_PAGE_SIZE))
end

function EnchantUI:UpdateApplyButton()
    local frame = self.frame
    if not frame then
        return
    end
    local selected = self.selectedEntry
    local enabled = selected ~= nil and tonumber(selected.available or 0) ~= 0 and self.pendingToken == nil
    setButtonEnabled(frame.apply, enabled)
end

function EnchantUI:SelectEntry(entry)
    self.selectedEntry = entry
    self.selectedSpellId = entry and tonumber(entry.spellId or 0) or nil
    self:Render()
end

function EnchantUI:Render()
    local frame = self:EnsureWindow()
    local entries = self:GetFilteredEntries()
    local maxPage = math.max(1, math.ceil(#entries / ENCHANT_PAGE_SIZE))
    self.page = math.max(1, math.min(tonumber(self.page or 1) or 1, maxPage))

    local startIndex = ((self.page - 1) * ENCHANT_PAGE_SIZE) + 1
    for rowIndex = 1, ENCHANT_PAGE_SIZE do
        local row = frame.rows[rowIndex]
        local entry = entries[startIndex + rowIndex - 1]
        row.entry = entry
        row.icon.entry = entry
        row.hit.entry = entry
        if entry then
            local name, icon = getSpellData(entry.spellId)
            row.icon.texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(name)
            row.materials:SetText(materialSummary(entry.materials))
            if self.selectedSpellId ~= nil and tonumber(entry.spellId or 0) == tonumber(self.selectedSpellId or -1) then
                row.selection:Show()
            else
                row.selection:Hide()
            end
            if tonumber(entry.available or 0) ~= 0 then
                row.name:SetTextColor(0, 1, 0)
                row.materials:SetTextColor(0.8, 0.8, 0.8)
            else
                row.name:SetTextColor(0.55, 0.55, 0.55)
                row.materials:SetTextColor(1, 0.35, 0.35)
            end
            row:Show()
        else
            row:Hide()
        end
    end

    frame.pageText:SetText(tostring(self.page) .. "/" .. tostring(maxPage))
    setButtonEnabled(frame.prev, self.page > 1)
    setButtonEnabled(frame.next, self.page < maxPage)

    if self.selectedEntry then
        local selectedName = getSpellData(self.selectedEntry.spellId)
        frame.selected:SetText(L("enchant.trade.selected", "Selected") .. ": " .. selectedName)
    else
        frame.selected:SetText(L("enchant.trade.selected", "Selected") .. ": -")
    end
    self:UpdateApplyButton()
end

function EnchantUI:EnsureWindow()
    if self.frame then
        return self.frame
    end

    local frame
    local content
    if AceGUI then
        local window = AceGUI:Create("Window")
        window:SetTitle(getWindowTitle(self.botName))
        window:SetWidth(ENCHANT_WINDOW_WIDTH)
        window:SetHeight(ENCHANT_WINDOW_HEIGHT)
        window:EnableResize(false)
        window:SetLayout("Fill")
        frame = window.frame
        content = window.content
        frame._mbAceWindow = window
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then frame:SetFrameStrata(strataLevel) end
        if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
        if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotEnchanting") end
        if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_enchanting_popup") end
    else
        frame = CreateFrame("Frame", "MultiBotEnchantingFrame", UIParent)
        frame:SetSize(ENCHANT_WINDOW_WIDTH, ENCHANT_WINDOW_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER", -110, 20)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        if UISpecialFrames then
            table.insert(UISpecialFrames, "MultiBotEnchantingFrame")
        end
        addSimpleBackdrop(frame, 0.96)
        frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -7)
        content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    end

    frame:Hide()
    frame.content = content or frame
    addSimpleBackdrop(frame.content, 0.90)

    frame.itemInfoEventFrame = CreateFrame("Frame")
    pcall(frame.itemInfoEventFrame.RegisterEvent, frame.itemInfoEventFrame, "GET_ITEM_INFO_RECEIVED")
    frame.itemInfoEventFrame:SetScript("OnEvent", function(_, _, itemId)
        local receivedItemId = tonumber(itemId or arg1 or 0) or 0
        if frame:IsShown() and EnchantUI:HasMaterialItem(receivedItemId) then
            EnchantUI:Render()
            if EnchantUI.tooltipOwner and EnchantUI.tooltipEntry then
                showEnchantTooltip(EnchantUI.tooltipOwner, EnchantUI.tooltipEntry)
            end
        end
    end)

    frame.status = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -10)
    frame.status:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -10)
    frame.status:SetJustifyH("LEFT")
    frame.status:SetText("")

    frame.searchPanel = CreateFrame("Frame", nil, frame.content)
    frame.searchPanel:SetHeight(26)
    frame.searchPanel:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -31)
    frame.searchPanel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -31)
    addSimpleBackdrop(frame.searchPanel, 0.78)

    frame.searchLabel = frame.searchPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.searchLabel:SetPoint("LEFT", frame.searchPanel, "LEFT", 8, 0)
    frame.searchLabel:SetText(L("enchant.trade.search", "Search"))

    frame.search = CreateFrame("EditBox", nil, frame.searchPanel)
    frame.search:SetHeight(20)
    frame.search:SetPoint("LEFT", frame.searchLabel, "RIGHT", 8, 0)
    frame.search:SetPoint("RIGHT", frame.searchPanel, "RIGHT", -6, 0)
    frame.search:SetAutoFocus(false)
    frame.search:SetFontObject(GameFontHighlightSmall)
    frame.search:SetTextInsets(4, 4, 0, 0)
    frame.search:SetScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
    end)
    frame.search:SetScript("OnTextChanged", function(editBox)
        EnchantUI.searchText = editBox:GetText() or ""
        EnchantUI.page = 1
        EnchantUI:Render()
    end)

    frame.rows = {}
    for index = 1, ENCHANT_PAGE_SIZE do
        local row = CreateFrame("Frame", nil, frame.content)
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -64 - ((index - 1) * ENCHANT_ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -64 - ((index - 1) * ENCHANT_ROW_HEIGHT))
        row:SetHeight(ENCHANT_ROW_HEIGHT)

        row.selection = row:CreateTexture(nil, "BACKGROUND")
        row.selection:SetAllPoints(row)
        row.selection:SetTexture("Interface\\Buttons\\WHITE8x8")
        row.selection:SetVertexColor(0.18, 0.34, 0.55, 0.32)
        row.selection:Hide()

        row.icon = CreateFrame("Button", nil, row)
        row.icon:SetSize(26, 26)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon.texture = row.icon:CreateTexture(nil, "ARTWORK")
        row.icon.texture:SetAllPoints(row.icon)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 7)
        row.name:SetWidth(260)
        row.name:SetJustifyH("LEFT")

        row.materials = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.materials:SetPoint("LEFT", row.icon, "RIGHT", 8, -8)
        row.materials:SetWidth(260)
        row.materials:SetJustifyH("LEFT")

        row.hit = CreateFrame("Button", nil, row)
        row.hit:SetAllPoints(row)
        row.hit:RegisterForClicks("LeftButtonUp")
        row.hit:SetScript("OnClick", function(button)
            if button.entry then EnchantUI:SelectEntry(button.entry) end
        end)
        row.hit:SetScript("OnEnter", function(button)
            if button.entry then showEnchantTooltip(button, button.entry) end
        end)
        row.hit:SetScript("OnLeave", function()
            hideEnchantTooltip()
        end)
        row.icon:SetScript("OnEnter", function(button)
            if button.entry then showEnchantTooltip(button, button.entry) end
        end)
        row.icon:SetScript("OnLeave", function()
            hideEnchantTooltip()
        end)
        row.icon:SetScript("OnClick", function(button)
            if button.entry then EnchantUI:SelectEntry(button.entry) end
        end)

        frame.rows[index] = row
    end

    frame.prev = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.prev:SetSize(32, 22)
    frame.prev:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 10, 46)
    frame.prev:SetText("<")
    frame.prev:SetScript("OnClick", function()
        EnchantUI.page = math.max(1, (EnchantUI.page or 1) - 1)
        EnchantUI:Render()
    end)

    frame.pageText = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.pageText:SetPoint("LEFT", frame.prev, "RIGHT", 8, 0)
    frame.pageText:SetWidth(55)
    frame.pageText:SetJustifyH("CENTER")

    frame.next = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.next:SetSize(32, 22)
    frame.next:SetPoint("LEFT", frame.pageText, "RIGHT", 8, 0)
    frame.next:SetText(">")
    frame.next:SetScript("OnClick", function()
        EnchantUI.page = math.min(EnchantUI:GetMaxPage(), (EnchantUI.page or 1) + 1)
        EnchantUI:Render()
    end)

    frame.refresh = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.refresh:SetSize(86, 22)
    frame.refresh:SetPoint("LEFT", frame.next, "RIGHT", 12, 0)
    frame.refresh:SetText(L("lootmaster.refresh", "Refresh"))
    frame.refresh:SetScript("OnClick", function()
        EnchantUI:RequestList()
    end)

    frame.apply = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.apply:SetSize(130, 24)
    frame.apply:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -10, 12)
    frame.apply:SetText(L("enchant.trade.apply", "Enchant"))
    frame.apply:SetScript("OnClick", function()
        EnchantUI:ApplySelected()
    end)

    frame.selected = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.selected:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 10, 18)
    frame.selected:SetPoint("RIGHT", frame.apply, "LEFT", -10, 0)
    frame.selected:SetJustifyH("LEFT")

    self.frame = frame
    return frame
end

function EnchantUI:RequestList()
    if not self.botName or self.botName == "" or not MultiBot.Comm or not MultiBot.Comm.RequestEnchantTrade then
        return false
    end
    if self.listToken then
        return false
    end

    local frame = self:EnsureWindow()
    frame.status:SetText(L("profession.recipes.loading", "Loading..."))
    local token = MultiBot.Comm.RequestEnchantTrade(self.botName)
    if not token then
        setButtonEnabled(frame.refresh, true)
        frame.status:SetText(L("enchant.trade.status.service_unavailable", "Enchanting service is not available."))
        return false
    end

    self.listToken = token
    setButtonEnabled(frame.refresh, false)
    return true
end

function EnchantUI:ApplySelected()
    local frame = self:EnsureWindow()
    local entry = self.selectedEntry
    if not entry or tonumber(entry.spellId or 0) <= 0 then
        return false
    end
    if tonumber(entry.available or 0) == 0 then
        frame.status:SetText(getReasonText(tonumber(entry.hasTools or 1) == 0 and "MISSING_TOOLS" or "NO_MATERIALS"))
        return false
    end
    if not MultiBot.Comm or not MultiBot.Comm.RunEnchantTrade then
        return false
    end

    if TradeFrame and TradeFrame.IsShown and not TradeFrame:IsShown() and InitiateTrade then
        if MultiBot.SuppressNextTradeInventoryDump then
            MultiBot.SuppressNextTradeInventoryDump(self.botName)
        end
        InitiateTrade(self.botName)
        frame.status:SetText(L("enchant.trade.status.trade_requested", "Trade requested. Put your item in the Will not be traded slot, then click Enchant again."))
        return false
    end

    local token = MultiBot.Comm.RunEnchantTrade(self.botName, entry.spellId)
    if not token then
        frame.status:SetText(L("enchant.trade.status.send_failed", "Enchanting request could not be sent."))
        return false
    end
    self.pendingToken = token
    frame.status:SetText(L("enchant.trade.status.requested", "Enchanting requested..."))
    self:UpdateApplyButton()
    return true
end

function EnchantUI:Open(botName)
    botName = tostring(botName or "")
    if botName == "" then
        return false
    end
    if not MultiBot.IsBotEnchantingServiceAvailable or not MultiBot.IsBotEnchantingServiceAvailable(botName) then
        return false
    end

    self.botName = botName
    self.entries = {}
    self.selectedEntry = nil
    self.selectedSpellId = nil
    self.pendingToken = nil
    self.listToken = nil
    self.tooltipOwner = nil
    self.tooltipEntry = nil
    self.page = 1
    self.searchText = ""

    local frame = self:EnsureWindow()
    if frame._mbAceWindow and frame._mbAceWindow.SetTitle then
        frame._mbAceWindow:SetTitle(getWindowTitle(botName))
    elseif frame.title then
        frame.title:SetText(getWindowTitle(botName))
    end
    if frame.search then frame.search:SetText("") end
    frame:Show()
    self:Render()
    setButtonEnabled(frame.refresh, true)

    if TradeFrame and TradeFrame.IsShown and not TradeFrame:IsShown() and InitiateTrade then
        if MultiBot.SuppressNextTradeInventoryDump then
            MultiBot.SuppressNextTradeInventoryDump(botName)
        end
        InitiateTrade(botName)
    end
    self:RequestList()
    return true
end

function MultiBot.IsBotEnchantingServiceAvailable(botName)
    return MultiBot.Comm
        and MultiBot.Comm.IsEnchantTradeCapable
        and MultiBot.Comm.IsEnchantTradeCapable()
        and MultiBot.Comm.IsBotEnchanter
        and MultiBot.Comm.IsBotEnchanter(botName)
        or false
end

function MultiBot.RefreshEnchantingEveryButton(botName)
    local main = MultiBot.frames and MultiBot.frames["MultiBar"] or nil
    local units = main and main.frames and main.frames["Units"] or nil
    if not units or not units.frames then
        return
    end

    for name, unitFrame in pairs(units.frames) do
        if type(name) == "string"
            and name ~= ""
            and unitFrame
            and (not botName or sameBotName(name, botName)) then
            local button = unitFrame.getButton and unitFrame.getButton("Enchant") or nil
            if button then
                if MultiBot.IsBotEnchantingServiceAvailable(name) then
                    button.setEnable()
                    button.doShow()
                else
                    button.doHide()
                    button.setDisable()
                end
            end
        end
    end
end

function MultiBot.RefreshEnchantingEveryButtons()
    MultiBot.RefreshEnchantingEveryButton(nil)
end

function MultiBot.ApplyBridgeBotProfession(botName, _professions)
    MultiBot.RefreshEnchantingEveryButton(botName)
end

function MultiBot.OpenBotEnchanting(botName, _sourceButton)
    return EnchantUI:Open(botName)
end

function MultiBot.OnBridgeEnchantTradeList(botName, entries, meta)
    local token = meta and tostring(meta.token or "") or ""
    if not EnchantUI.botName or not sameBotName(EnchantUI.botName, botName) then
        return
    end
    if not EnchantUI.listToken or token == "" or tostring(EnchantUI.listToken) ~= token then
        return
    end

    EnchantUI.listToken = nil

    local frame = EnchantUI:EnsureWindow()
    setButtonEnabled(frame.refresh, true)
    local status = meta and tostring(meta.status or "") or ""
    local reason = meta and tostring(meta.reason or "") or ""
    if status ~= "OK" then
        frame.status:SetText(getReasonText(reason ~= "" and reason or status))
    else
        EnchantUI.entries = type(entries) == "table" and entries or {}
        EnchantUI.page = 1
        EnchantUI.selectedEntry = nil
        EnchantUI.selectedSpellId = nil

        local skillValue = tonumber(meta and meta.skillValue or 0) or 0
        local maxSkill = tonumber(meta and meta.maxSkill or 0) or 0
        frame.status:SetText(string.format(L("enchant.trade.count", "Enchantments: %d - Skill: %d/%d"), #EnchantUI.entries, skillValue, maxSkill))
    end
    EnchantUI:Render()
end

function MultiBot.OnBridgeEnchantTradeResult(botName, _spellId, status, reason, command)
    local commandToken = command and tostring(command.token or "") or ""
    if not EnchantUI.pendingToken or commandToken == "" or tostring(EnchantUI.pendingToken) ~= commandToken then
        return
    end
    if not EnchantUI.botName or not sameBotName(EnchantUI.botName, botName) then
        return
    end

    EnchantUI.pendingToken = nil
    local frame = EnchantUI:EnsureWindow()
    EnchantUI:UpdateApplyButton()
    if tostring(status or "") == "OK" then
        frame.status:SetText(L("enchant.trade.status.started", "Enchanting started. Complete the trade normally."))
        safeDelay(ENCHANT_REFRESH_DELAY, function()
            if EnchantUI.botName and sameBotName(EnchantUI.botName, botName) then
                EnchantUI:RequestList()
            end
        end)
    else
        frame.status:SetText(getReasonText(reason))
    end
end
