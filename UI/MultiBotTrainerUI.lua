if not MultiBot then
    return
end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local TRAINER_WINDOW_WIDTH = 420
local TRAINER_WINDOW_HEIGHT = 420
local TRAINER_PAGE_SIZE = 10
local TRAINER_ROW_HEIGHT = 30
local TRAINER_REFRESH_DELAY = 0.45

local TrainerUI = MultiBot.TrainerUI or {}
MultiBot.TrainerUI = TrainerUI

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

local function formatMoney(copper)
    copper = tonumber(copper or 0) or 0
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100
    return tostring(gold) .. "g " .. tostring(silver) .. "s " .. tostring(copperOnly) .. "c"
end

local function getReasonText(reason)
    reason = tostring(reason or "")
    if reason == "" or reason == "OK" then
        return ""
    end

    return L("info.trainer.reason." .. reason, reason)
end

local function getWindowTitle(botName)
    local title = L("info.trainer.window_title", "Trainer")
    if type(botName) == "string" and botName ~= "" then
        return title .. " - " .. botName
    end

    return title
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

function TrainerUI:EnsureWindow()
    if self.frame then
        return self.frame
    end

    local frame
    local content

    if AceGUI then
        local window = AceGUI:Create("Window")
        window:SetTitle(getWindowTitle(self.botName))
        window:SetWidth(TRAINER_WINDOW_WIDTH)
        window:SetHeight(TRAINER_WINDOW_HEIGHT)
        window:EnableResize(false)
        window:SetLayout("Fill")
        frame = window.frame
        content = window.content
        frame._mbAceWindow = window

        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            frame:SetFrameStrata(strataLevel)
        end

        if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
        if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotTrainer") end
        if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_trainer_popup") end
    else
        frame = CreateFrame("Frame", "MultiBotTrainerFrame", UIParent)
        frame:SetSize(TRAINER_WINDOW_WIDTH, TRAINER_WINDOW_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER", -120, 20)
        frame:SetFrameStrata("DIALOG")
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
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

    frame.status = frame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -12)
    frame.status:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -12)
    frame.status:SetJustifyH("LEFT")
    frame.status:SetText("")

    frame.rows = {}
    for index = 1, TRAINER_PAGE_SIZE do
        local row = CreateFrame("Frame", nil, frame.content)
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -38 - ((index - 1) * TRAINER_ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -38 - ((index - 1) * TRAINER_ROW_HEIGHT))
        row:SetHeight(TRAINER_ROW_HEIGHT)

        row.icon = CreateFrame("Button", nil, row)
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon.texture = row.icon:CreateTexture(nil, "ARTWORK")
        row.icon.texture:SetAllPoints(row.icon)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetWidth(160)
        row.name:SetJustifyH("LEFT")

        row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.cost:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
        row.cost:SetWidth(78)
        row.cost:SetJustifyH("RIGHT")

        row.learn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.learn:SetSize(86, 22)
        row.learn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.learn:SetText(L("info.trainer.learn", "Learn"))
        row.learn:SetScript("OnClick", function(button)
            if button.spellId then
                TrainerUI:LearnSpell(button.spellId)
            end
        end)

        row.icon:SetScript("OnEnter", function(button)
            if button.spellId and GameTooltip then
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("spell:" .. tostring(button.spellId))
                GameTooltip:Show()
            end
        end)
        row.icon:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)

        frame.rows[index] = row
    end

    frame.prev = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.prev:SetSize(32, 22)
    frame.prev:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT", 10, 12)
    frame.prev:SetText("<")
    frame.prev:SetScript("OnClick", function()
        TrainerUI.page = math.max(1, (TrainerUI.page or 1) - 1)
        TrainerUI:Render()
    end)

    frame.pageText = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.pageText:SetPoint("LEFT", frame.prev, "RIGHT", 8, 0)
    frame.pageText:SetWidth(60)
    frame.pageText:SetJustifyH("CENTER")

    frame.next = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.next:SetSize(32, 22)
    frame.next:SetPoint("LEFT", frame.pageText, "RIGHT", 8, 0)
    frame.next:SetText(">")
    frame.next:SetScript("OnClick", function()
        local maxPage = TrainerUI:GetMaxPage()
        TrainerUI.page = math.min(maxPage, (TrainerUI.page or 1) + 1)
        TrainerUI:Render()
    end)

    frame.refresh = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.refresh:SetSize(90, 22)
    frame.refresh:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -112, 12)
    frame.refresh:SetText(L("info.trainer.refresh", "Refresh"))
    frame.refresh:SetScript("OnClick", function()
        TrainerUI:RequestList()
    end)

    frame.learnAll = CreateFrame("Button", nil, frame.content, "UIPanelButtonTemplate")
    frame.learnAll:SetSize(100, 22)
    frame.learnAll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -10, 12)
    frame.learnAll:SetText(L("info.trainer.learn_all", "Learn all"))
    frame.learnAll:SetScript("OnClick", function()
        TrainerUI:LearnAll()
    end)

    frame:HookScript("OnHide", function()
        if TrainerUI.sourceButton and TrainerUI.sourceButton.setDisable then
            TrainerUI.sourceButton.setDisable()
        end
    end)

    self.frame = frame
    self.entries = self.entries or {}
    self.page = self.page or 1
    return frame
end

function TrainerUI:SetStatus(message)
    self:EnsureWindow()
    self.frame.status:SetText(message or "")
end

function TrainerUI:GetMaxPage()
    local count = #(self.entries or {})
    local maxPage = math.ceil(count / TRAINER_PAGE_SIZE)
    if maxPage < 1 then
        maxPage = 1
    end
    return maxPage
end

function TrainerUI:Render()
    local frame = self:EnsureWindow()
    local entries = self.entries or {}
    local maxPage = self:GetMaxPage()
    self.page = math.min(math.max(1, self.page or 1), maxPage)

    local startIndex = ((self.page - 1) * TRAINER_PAGE_SIZE) + 1
    for rowIndex = 1, TRAINER_PAGE_SIZE do
        local row = frame.rows[rowIndex]
        local entry = entries[startIndex + rowIndex - 1]

        if entry then
            local spellName, spellRank, icon = GetSpellInfo(entry.spellId)
            row.icon.spellId = entry.spellId
            row.icon.texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText((spellName or ("spell:" .. tostring(entry.spellId))) .. (spellRank and spellRank ~= "" and (" (" .. spellRank .. ")") or ""))
            row.cost:SetText(formatMoney(entry.cost))
            row.learn.spellId = entry.spellId
            row.learn:SetText(L("info.trainer.learn", "Learn"))
            setButtonEnabled(row.learn, not self.pending and entry.canAfford)
            row:Show()
        else
            row.icon.spellId = nil
            row.learn.spellId = nil
            row:Hide()
        end
    end

    frame.pageText:SetText(tostring(self.page) .. "/" .. tostring(maxPage))
    setButtonEnabled(frame.prev, self.page > 1)
    setButtonEnabled(frame.next, self.page < maxPage)
    setButtonEnabled(frame.refresh, not self.pending)
    setButtonEnabled(frame.learnAll, not self.pending and #entries > 0)
end

function TrainerUI:RequestList()
    if not self.botName or self.botName == "" then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RequestTrainer then
        self:SetStatus(L("info.trainer.bridge_required", "Bridge support is required for trainer actions."))
        return false
    end

    self.pending = nil
    self.entries = {}
    self.page = 1
    self.error = nil
    self.trainerEntry = 0
    self.trainerName = ""
    self:SetStatus(L("info.trainer.loading", "Loading trainer spells..."))
    self:Render()

    if not MultiBot.Comm.RequestTrainer(self.botName) then
        self:SetStatus(L("info.trainer.bridge_required", "Bridge support is required for trainer actions."))
        self:Render()
        return false
    end

    return true
end

function TrainerUI:LearnSpell(spellId)
    if self.pending or not self.trainerEntry or self.trainerEntry <= 0 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunTrainerLearn then
        return false
    end

    self.pending = spellId
    self:SetStatus(L("info.trainer.learning", "Learning..."))
    self:Render()
    if not MultiBot.Comm.RunTrainerLearn(self.botName, self.trainerEntry, spellId) then
        self.pending = nil
        self:SetStatus(L("info.trainer.failed", "Trainer action failed."))
        self:Render()
        return false
    end

    return true
end

function TrainerUI:LearnAll()
    if self.pending or not self.trainerEntry or self.trainerEntry <= 0 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunTrainerLearn then
        return false
    end

    self.pending = "ALL"
    self:SetStatus(L("info.trainer.learning", "Learning..."))
    self:Render()
    if not MultiBot.Comm.RunTrainerLearn(self.botName, self.trainerEntry, "ALL") then
        self.pending = nil
        self:SetStatus(L("info.trainer.failed", "Trainer action failed."))
        self:Render()
        return false
    end

    return true
end

function TrainerUI:HandleBridgeBegin(botName, token, trainerEntry, trainerName)
    if not sameBotName(botName, self.botName) then
        return
    end

    self.requestToken = token
    self.trainerEntry = tonumber(trainerEntry or 0) or 0
    self.trainerName = trainerName or ""
    self.entries = {}
    self.error = nil
    self.page = 1
    self:SetStatus(self.trainerName ~= "" and self.trainerName or L("info.trainer.loading", "Loading trainer spells..."))
    self:Render()
end

function TrainerUI:HandleBridgeLine(botName, token, entry)
    if not sameBotName(botName, self.botName) or (self.requestToken and token ~= self.requestToken) then
        return
    end

    self.entries = self.entries or {}
    self.entries[#self.entries + 1] = entry
    self:Render()
end

function TrainerUI:HandleBridgeError(botName, token, reason, trainerEntry)
    if not sameBotName(botName, self.botName) or (self.requestToken and token ~= self.requestToken) then
        return
    end

    self.trainerEntry = tonumber(trainerEntry or self.trainerEntry or 0) or 0
    self.error = reason
    self:SetStatus(getReasonText(reason))
    self:Render()
end

function TrainerUI:HandleBridgeEnd(botName, token, trainerEntry, trainerName, entries, errorReason)
    if not sameBotName(botName, self.botName) or (self.requestToken and token ~= self.requestToken) then
        return
    end

    self.trainerEntry = tonumber(trainerEntry or self.trainerEntry or 0) or 0
    self.trainerName = (type(trainerName) == "string" and trainerName ~= "") and trainerName or self.trainerName
    self.entries = entries or self.entries or {}
    self.error = errorReason
    self.pending = nil

    if self.error and self.error ~= "" then
        self:SetStatus(getReasonText(self.error))
    elseif #(self.entries or {}) == 0 then
        self:SetStatus(L("info.trainer.no_spells", "No learnable spells."))
    else
        self:SetStatus(self.trainerName ~= "" and self.trainerName or L("info.trainer.loaded", "Trainer spells loaded."))
    end

    self:Render()
end

function TrainerUI:HandleBridgeLearnResult(botName, token, trainerEntry, spellId, result, reason, learnedCount, spent)
    if not sameBotName(botName, self.botName) then
        return
    end

    self.pending = nil
    self.trainerEntry = tonumber(trainerEntry or self.trainerEntry or 0) or 0

    if result == "OK" then
        self:SetStatus(string.format(L("info.trainer.learned", "Learned %d spell(s)."), tonumber(learnedCount or 0) or 0))
        safeDelay(TRAINER_REFRESH_DELAY, function()
            if TrainerUI.frame and TrainerUI.frame:IsShown() and sameBotName(TrainerUI.botName, botName) then
                TrainerUI:RequestList()
            end
        end)
    else
        local detail = getReasonText(reason)
        if detail == "" then
            detail = L("info.trainer.failed", "Trainer action failed.")
        end
        self:SetStatus(detail)
        self:Render()
    end
end

function MultiBot.OpenBotTrainer(botName, sourceButton)
    botName = tostring(botName or "")
    if botName == "" then
        return false
    end

    if TrainerUI.sourceButton and TrainerUI.sourceButton ~= sourceButton and TrainerUI.sourceButton.setDisable then
        TrainerUI.sourceButton.setDisable()
    end

    TrainerUI.botName = botName
    TrainerUI.sourceButton = sourceButton
    TrainerUI:EnsureWindow()
    if TrainerUI.frame._mbAceWindow then
        TrainerUI.frame._mbAceWindow:SetTitle(getWindowTitle(botName))
        TrainerUI.frame._mbAceWindow:Show()
    else
        TrainerUI.frame.title:SetText(getWindowTitle(botName))
        TrainerUI.frame:Show()
    end

    if sourceButton and sourceButton.setEnable then
        sourceButton.setEnable()
    end

    return TrainerUI:RequestList()
end
