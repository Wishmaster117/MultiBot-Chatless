if not MultiBot then return end

local EMPTY_TABLE = {}
local Shared = MultiBot.QuestUIShared
if type(Shared) ~= "table" then
    Shared = {}
end

local QuestCompletedFrame = MultiBot.QuestCompletedFrame
if type(QuestCompletedFrame) ~= "table" then
    QuestCompletedFrame = {}
end
MultiBot.QuestCompletedFrame = QuestCompletedFrame

local function getBotQuestsCompletedStore()
    local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsCompleted")) or MultiBot.BotQuestsCompleted
    if not store and MultiBot.Store and MultiBot.Store.RecordReadMiss then
        MultiBot.Store.RecordReadMiss("QuestCompleted", "BotQuestsCompleted")
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

function MultiBot.BuildBotCompletedList(botName)
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local completedStore = getBotQuestsCompletedStore()
    local entries = Shared.SortQuestEntries(resolveBotQuestBucket(completedStore, botName))

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = botName and ("|cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.complist") or ""),
    })
end

function MultiBot.BuildAggregatedCompletedList()
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local entries = Shared.BuildAggregatedQuestEntries(getBotQuestsCompletedStore())

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = "",
    })
end

function QuestCompletedFrame:Show()
    if self.window then
        self.window:Show()
    end
end

function MultiBot.InitializeQuestCompletedFrame()
    if QuestCompletedFrame.window then
        return QuestCompletedFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_BotQuestCompPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_BotQuestCompPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_BotQuestCompPopup")

    window:SetTitle(MultiBot.L("tips.quests.complist"))
    window:SetWidth(380)
    window:SetHeight(420)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestCompleted") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_comp_popup") end

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
        local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsCompleted")) or MultiBot.BotQuestsCompleted
        if MultiBot.Store and MultiBot.Store.ClearTable then
            MultiBot.Store.ClearTable(store)
        end
        clearList(QuestCompletedFrame)
    end)

    QuestCompletedFrame.window = window
    QuestCompletedFrame.aceGUI = aceGUI
    QuestCompletedFrame.scroll = scroll
    QuestCompletedFrame.summary = summary

    MultiBot.tBotCompPopup = window
    return QuestCompletedFrame
end