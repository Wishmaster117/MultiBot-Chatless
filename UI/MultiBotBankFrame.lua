if not MultiBot then
    return
end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local BANK_FRAME_WIDTH = 340
local BANK_FRAME_HEIGHT = 420
local BANK_FRAME_X = -360
local BANK_ROW_WIDTH = 300
local BANK_TEXT_WIDTH = 210
local BANK_WITHDRAW_BUTTON_WIDTH = 70
local BANK_REFRESH_DELAY = 0.65

local function L(key, fallback)
    if MultiBot and type(MultiBot.L) == "function" then
        return MultiBot.L(key, fallback)
    end

    return fallback or key
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

local function createWindow(name, title, width, height, pointX)
    if AceGUI then
        local widget = AceGUI:Create("Window")
        widget:SetTitle(title)
        widget:SetLayout("Fill")
        widget:SetWidth(width)
        widget:SetHeight(height)
        widget.frame:SetPoint("CENTER", UIParent, "CENTER", pointX or 0, 0)
        widget.frame:SetFrameStrata("DIALOG")
        widget:EnableResize(false)
        return widget
    end

    local frame = CreateFrame("Frame", name, UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", pointX or 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -7)
    frame.title:SetText(title)
    return {
        frame = frame,
        content = frame,
        SetTitle = function(self, value) self.frame.title:SetText(value) end,
        Show = function(self) self.frame:Show() end,
        Hide = function(self) self.frame:Hide() end,
        IsShown = function(self) return self.frame:IsShown() end,
    }
end

local function getFrameContent(window)
    if window and window.content then
        return window.content
    end

    return window and window.frame or nil
end

local function setWindowTitle(window, title)
    if not window then
        return
    end

    if window.SetTitle then
        window:SetTitle(title)
    elseif window.title then
        window.title:SetText(title)
    end
end

local function createText(parent, font, point, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint(point, parent, point, x, y)
    text:SetJustifyH("LEFT")
    return text
end

local function systemMessage(message)
    message = tostring(message or "")
    if message == "" then
        return
    end

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    elseif print then
        print(message)
    end
end

local function parseBankItemLine(line)
    line = tostring(line or "")
    local itemId = tonumber(string.match(line, "item:(%d+)") or "0") or 0
    if itemId <= 0 then
        return nil
    end

    local name, link, _, _, _, _, _, _, _, icon = GetItemInfo(itemId)
    if not icon and GetItemIcon then
        icon = GetItemIcon(itemId)
    end

    local count = tonumber(string.match(line, "rx(%d+)") or string.match(line, "x(%d+)") or "1") or 1
    if count < 1 then
        count = 1
    end

    return {
        itemId = itemId,
        name = name or ("item:" .. itemId),
        link = link or line,
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        count = count,
        line = line,
    }
end

local function getBankReasonText(reason)
    reason = tostring(reason or "")
    if reason == "" or reason == "OK" then
        return ""
    end

    return L("info.inventory.item_action.reason." .. reason, reason)
end

local function getBankModeTitle(mode)
    if mode == "gbank" then
        return L("inventory.gbank.title", "Guild Bank")
    end

    return L("inventory.bank.title", "Bot Bank")
end

local function getBankModeLoadingText(mode)
    if mode == "gbank" then
        return L("inventory.gbank.loading", "Loading guild bank...")
    end

    return L("inventory.bank.loading", "Loading bank...")
end

local function getBankModeCountText(mode)
    if mode == "gbank" then
        return L("inventory.gbank.count", "guild bank item(s)")
    end

    return L("inventory.bank.count", "bank item(s)")
end

local function getBankModeBridgeRequiredText(mode)
    if mode == "gbank" then
        return L("inventory.gbank.bridge.required", "Guild bank bridge is not connected.")
    end

    return L("inventory.bank.bridge.required", "Bank bridge is not connected.")
end

local function canWithdrawFromMode(mode)
    return mode ~= "gbank"
end

local function ensureBankFrame()
    if MultiBot.bankFrame then
        return MultiBot.bankFrame
    end

    local frame = createWindow("MultiBotBankFrame", L("inventory.bank.title", "Bot Bank"), BANK_FRAME_WIDTH, BANK_FRAME_HEIGHT, BANK_FRAME_X)
    if not frame then
        return nil
    end

    local content = getFrameContent(frame)
    frame.status = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, -10)
    frame.rows = {}
    frame.items = {}
    frame.page = 1
    frame.pageSize = 12

    for i = 1, frame.pageSize do
        local row = CreateFrame("Button", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -32 - ((i - 1) * 27))
        row:SetWidth(BANK_ROW_WIDTH)
        row:SetHeight(24)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetWidth(22)
        row.icon:SetHeight(22)

        row.text = createText(row, "GameFontHighlightSmall", "LEFT", 28, 0)
        row.text:SetWidth(BANK_TEXT_WIDTH)
        row.text:SetHeight(22)

        row.withdrawButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.withdrawButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.withdrawButton:SetWidth(BANK_WITHDRAW_BUTTON_WIDTH)
        row.withdrawButton:SetHeight(20)
        row.withdrawButton:SetText(L("inventory.bank.withdraw", "Withdraw"))
        row.withdrawButton:SetScript("OnClick", function()
            local item = row.item
            if not item or not frame.botName or not canWithdrawFromMode(frame.mode) then
                return
            end

            if MultiBot.Comm and MultiBot.Comm.RunInventoryItemAction then
                local token = MultiBot.Comm.RunInventoryItemAction(frame.botName, "BANK_WITHDRAW", item.itemId, 0)
                if token then
                    frame.status:SetText(L("inventory.bank.withdraw.pending", "Withdraw requested..."))
                    setButtonEnabled(row.withdrawButton, false)
                    return
                end
            end

            frame.status:SetText(L("inventory.bank.withdraw.failed", "Withdraw request failed."))
        end)

        row:SetScript("OnEnter", function(self)
            if not self.item or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.item.link and string.sub(self.item.link, 1, 1) == "|" then
                GameTooltip:SetHyperlink(self.item.link)
            else
                GameTooltip:SetText(self.item.name or "")
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)

        frame.rows[i] = row
    end

    frame.prev = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    frame.prev:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 18, 8)
    frame.prev:SetWidth(48)
    frame.prev:SetHeight(20)
    frame.prev:SetText("<")

    frame.pageText = createText(content, "GameFontNormalSmall", "BOTTOM", 0, 12)

    frame.next = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    frame.next:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -18, 8)
    frame.next:SetWidth(48)
    frame.next:SetHeight(20)
    frame.next:SetText(">")

    frame.render = function(self)
        local maxPage = math.max(1, math.ceil(#self.items / self.pageSize))
        if self.page > maxPage then self.page = maxPage end
        if self.page < 1 then self.page = 1 end

        self.pageText:SetText(self.page .. "/" .. maxPage)
        setButtonEnabled(self.prev, self.page > 1)
        setButtonEnabled(self.next, self.page < maxPage)

        local from = ((self.page - 1) * self.pageSize) + 1
        for i = 1, self.pageSize do
            local row = self.rows[i]
            local item = self.items[from + i - 1]
            row.item = item
            if item then
                row.icon:SetTexture(MultiBot.SafeTexturePath(item.icon))
                row.text:SetText((item.name or ("item:" .. item.itemId)) .. " |cff999999x" .. tostring(item.count or 1) .. "|r")
                if canWithdrawFromMode(self.mode) then
                    row.withdrawButton:SetText(L("inventory.bank.withdraw", "Withdraw"))
                    setButtonEnabled(row.withdrawButton, true)
                    row.withdrawButton:Show()
                else
                    row.withdrawButton:Hide()
                end
                row:Show()
            else
                row.withdrawButton:Hide()
                row:Hide()
            end
        end
    end

    frame.prev:SetScript("OnClick", function()
        frame.page = frame.page - 1
        frame:render()
    end)

    frame.next:SetScript("OnClick", function()
        frame.page = frame.page + 1
        frame:render()
    end)

    frame.setItems = function(self, botName, lines, errorReason, mode)
        self.botName = botName
        self.mode = mode or self.mode or "bank"
        self.items = {}
        self.page = 1
        setWindowTitle(self, getBankModeTitle(self.mode) .. " - " .. tostring(botName or ""))

        if errorReason and errorReason ~= "" then
            self.status:SetText(getBankReasonText(errorReason))
        else
            for _, line in ipairs(lines or {}) do
                local item = parseBankItemLine(line)
                if item then
                    table.insert(self.items, item)
                end
            end
            self.status:SetText(#self.items .. " " .. getBankModeCountText(self.mode))
        end

        self:render()
        self:Show()
    end

    frame:Hide()
    MultiBot.bankFrame = frame
    return frame
end

function MultiBot.OpenBotBank(botName)
    botName = tostring(botName or "")
    if botName == "" then
        return false
    end

    local frame = ensureBankFrame()
    frame.botName = botName
    frame.mode = "bank"
    frame.items = {}
    frame.page = 1
    setWindowTitle(frame, getBankModeTitle(frame.mode) .. " - " .. botName)
    frame.status:SetText(getBankModeLoadingText(frame.mode))
    frame:render()
    frame:Show()

    if MultiBot.Comm and MultiBot.Comm.RequestBank then
        return MultiBot.Comm.RequestBank(botName)
    end

    systemMessage(getBankModeBridgeRequiredText(frame.mode))
    return false
end

function MultiBot.OpenBotGuildBank(botName)
    botName = tostring(botName or "")
    if botName == "" then
        return false
    end

    local frame = ensureBankFrame()
    frame.botName = botName
    frame.mode = "gbank"
    frame.items = {}
    frame.page = 1
    setWindowTitle(frame, getBankModeTitle(frame.mode) .. " - " .. botName)
    frame.status:SetText(getBankModeLoadingText(frame.mode))
    frame:render()
    frame:Show()

    if MultiBot.Comm and MultiBot.Comm.RequestGuildBank then
        return MultiBot.Comm.RequestGuildBank(botName)
    end

    systemMessage(getBankModeBridgeRequiredText(frame.mode))
    return false
end

function MultiBot.RefreshBotBank(botName, delay)
    local frame = MultiBot.bankFrame
    botName = tostring(botName or (frame and frame.botName) or "")
    if botName == "" or not frame or frame.mode == "gbank" or not frame.IsShown or not frame:IsShown() then
        return false
    end

    local function refresh()
        if frame and frame.IsShown and frame:IsShown() and MultiBot.Comm and MultiBot.Comm.RequestBank then
            MultiBot.Comm.RequestBank(botName)
        end
    end

    if type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delay or BANK_REFRESH_DELAY, refresh)
    else
        refresh()
    end

    return true
end

function MultiBot.RefreshBotGuildBank(botName, delay)
    local frame = MultiBot.bankFrame
    botName = tostring(botName or (frame and frame.botName) or "")
    if botName == "" or not frame or frame.mode ~= "gbank" or not frame.IsShown or not frame:IsShown() then
        return false
    end

    local function refresh()
        if frame and frame.IsShown and frame:IsShown() and MultiBot.Comm and MultiBot.Comm.RequestGuildBank then
            MultiBot.Comm.RequestGuildBank(botName)
        end
    end

    if type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delay or BANK_REFRESH_DELAY, refresh)
    else
        refresh()
    end

    return true
end

function MultiBot.OnBridgeBankItems(botName, lines, errorReason)
    ensureBankFrame():setItems(botName, lines or {}, errorReason, "bank")
end

function MultiBot.OnBridgeGuildBankItems(botName, lines, errorReason)
    ensureBankFrame():setItems(botName, lines or {}, errorReason, "gbank")
end

function MultiBot.InitializeBankFrame()
    ensureBankFrame()
end