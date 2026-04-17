if not MultiBot then return end

local EMPTY_TABLE = {}
local Shared = MultiBot.QuestUIShared
if type(Shared) ~= "table" then
    Shared = {}
end

local QuestIncompleteFrame = MultiBot.QuestIncompleteFrame
if type(QuestIncompleteFrame) ~= "table" then
    QuestIncompleteFrame = {}
end
MultiBot.QuestIncompleteFrame = QuestIncompleteFrame

local function getBotQuestsIncompletedStore()
    local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsIncompleted")) or MultiBot.BotQuestsIncompleted
    if not store and MultiBot.Store and MultiBot.Store.RecordReadMiss then
        MultiBot.Store.RecordReadMiss("QuestIncomplete", "BotQuestsIncompleted")
    end
    return store or EMPTY_TABLE
end

local function clearList(self)
    if self.scroll then
        self.scroll:ReleaseChildren()
    end
end

local function normalizeBotName(botName)
    if type(botName) ~= "string" then
        return nil
    end
    return botName:gsub("%-.+$", ""):lower()
end

local function resolveBotQuestBucket(store, botName)
    if type(store) ~= "table" or type(botName) ~= "string" then
        return EMPTY_TABLE
    end

    if type(store[botName]) == "table" then
        return store[botName]
    end

    local normalizedTarget = normalizeBotName(botName)
    for storedBotName, quests in pairs(store) do
        if type(storedBotName) == "string" and type(quests) == "table" then
            if storedBotName:lower() == botName:lower() or normalizeBotName(storedBotName) == normalizedTarget then
                return quests
            end
        end
    end

    return EMPTY_TABLE
end

function MultiBot.BuildBotQuestList(botName)
    local frame = MultiBot.InitializeQuestIncompleteFrame and MultiBot.InitializeQuestIncompleteFrame()
    if not frame then
        return
    end
    local incompletedStore = getBotQuestsIncompletedStore()
    local entries = Shared.SortQuestEntries(resolveBotQuestBucket(incompletedStore, botName))

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = botName and ("|cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.incomplist") or ""),
    })
end

function MultiBot.BuildAggregatedQuestList()
    local frame = MultiBot.InitializeQuestIncompleteFrame()
    local entries = Shared.BuildAggregatedQuestEntries(getBotQuestsIncompletedStore())

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = "",
    })
end

function QuestIncompleteFrame:Show()
    if self.window then
        self.window:Show()
    end
end

function MultiBot.InitializeQuestIncompleteFrame()
    if QuestIncompleteFrame.window then
        return QuestIncompleteFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_BotQuestPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_BotQuestPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_BotQuestPopup")

    window:SetTitle(MultiBot.L("tips.quests.incomplist"))
    window:SetWidth(380)
    window:SetHeight(420)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestIncomplete") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_popup") end

    local content = aceGUI:Create("SimpleGroup")
    content:SetFullWidth(true)
    content:SetFullHeight(true)
    content:SetLayout("List")
    window:AddChild(content)

    local summary = aceGUI:Create("Label")
    summary:SetFullWidth(true)
    summary:SetText("")
    content:AddChild(summary)

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")
    content:AddChild(scroll)

    window.frame:HookScript("OnHide", function()
        local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsIncompleted")) or MultiBot.BotQuestsIncompleted
        if MultiBot.Store and MultiBot.Store.ClearTable then
            MultiBot.Store.ClearTable(store)
        end
        clearList(QuestIncompleteFrame)
    end)

    QuestIncompleteFrame.window = window
    QuestIncompleteFrame.aceGUI = aceGUI
    QuestIncompleteFrame.scroll = scroll
    QuestIncompleteFrame.summary = summary

    MultiBot.tBotPopup = window
    return QuestIncompleteFrame
end