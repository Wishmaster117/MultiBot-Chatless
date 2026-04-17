if not MultiBot then return end

local EMPTY_TABLE = {}
local Shared = MultiBot.QuestUIShared
if type(Shared) ~= "table" then
    Shared = {}
end

local QuestAllFrame = MultiBot.QuestAllFrame
if type(QuestAllFrame) ~= "table" then
    QuestAllFrame = {}
end
MultiBot.QuestAllFrame = QuestAllFrame

local function getBotQuestsAllStore()
    local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsAll")) or MultiBot.BotQuestsAll
    if not store and MultiBot.Store and MultiBot.Store.RecordReadMiss then
        MultiBot.Store.RecordReadMiss("QuestAll", "BotQuestsAll")
    end
    return store or EMPTY_TABLE
end

local function getBotQuestsCompletedStore()
    local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsCompleted")) or MultiBot.BotQuestsCompleted
    if not store and MultiBot.Store and MultiBot.Store.RecordReadMiss then
        MultiBot.Store.RecordReadMiss("QuestAll", "BotQuestsCompleted")
    end
    return store or EMPTY_TABLE
end

local function getBotQuestsIncompletedStore()
    local store = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsIncompleted")) or MultiBot.BotQuestsIncompleted
    if not store and MultiBot.Store and MultiBot.Store.RecordReadMiss then
        MultiBot.Store.RecordReadMiss("QuestAll", "BotQuestsIncompleted")
    end
    return store or EMPTY_TABLE
end

local function clearList(self)
    if self.scroll then
        self.scroll:ReleaseChildren()
    end
end

function MultiBot.ClearAllContent()
    local frame = MultiBot.InitializeQuestAllFrame()
    clearList(frame)
end

local function createQuestLabel(self, questID, text)
    local label = self.aceGUI:Create("InteractiveLabel")
    label:SetWidth(340)
    label:SetText(text)

    if questID then
        label:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink("quest:" .. tostring(questID))
            GameTooltip:Show()
        end)
    end

    label:SetCallback("OnLeave", function()
        GameTooltip_Hide()
    end)

    return label
end

local function createQuestRow(self, questID, text)
    local row = self.aceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local icon = self.aceGUI:Create("Icon")
    icon:SetImage(Shared.ICON_BOT_QUEST or "Interface\\Icons\\inv_misc_note_02")
    icon:SetImageSize(12, 12)
    icon:SetWidth(20)
    row:AddChild(icon)

    row:AddChild(createQuestLabel(self, questID, text))
    self.scroll:AddChild(row)
end

local function createQuestRowWithBots(self, entry)
    createQuestRow(self, entry.id, Shared.BuildQuestLink(entry.id, entry.name))

    if entry.bots and #entry.bots > 0 then
        local botsLine = self.aceGUI:Create("Label")
        botsLine:SetFullWidth(true)
        botsLine:SetText("    " .. Shared.FormatBotsLabel(entry.bots))
        self.scroll:AddChild(botsLine)
    end
end

local function createSectionHeader(self, text)
    local heading = self.aceGUI:Create("Heading")
    heading:SetFullWidth(true)
    heading:SetText(text or "")
    self.scroll:AddChild(heading)
end

local function createEmptySectionHint(self, text)
    local hint = self.aceGUI:Create("Label")
    hint:SetFullWidth(true)
    hint:SetText("    " .. (text or MultiBot.L("tips.quests.gobnosearchdata") or MultiBot.L("quests.none")))
    self.scroll:AddChild(hint)
end

function MultiBot.BuildBotAllList(botName)
    local frame = MultiBot.InitializeQuestAllFrame()
    clearList(frame)

    local questsStore = getBotQuestsAllStore()
    local quests = (questsStore and questsStore[botName]) or EMPTY_TABLE
    for _, link in ipairs(quests) do
        local questID = tonumber(link:match("|Hquest:(%d+):"))
        local localizedName = questID and Shared.GetLocalizedQuestName(questID, link) or link
        local displayLink = link:gsub("%[[^%]]+%]", "|cff00ff00[" .. localizedName .. "]|r")

        createQuestRow(frame, questID, displayLink)
    end

    if #quests == 0 then
        createEmptySectionHint(frame)
    end

    if frame.summary then
        frame.summary:SetText(botName and ((MultiBot.L("tips.quests.alllist") or "All Quests") .. ": |cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.alllist") or ""))
    end
end

function MultiBot.BuildAggregatedAllList()
    local frame = MultiBot.InitializeQuestAllFrame()
    clearList(frame)

    local completeEntries = Shared.BuildAggregatedQuestEntries(getBotQuestsCompletedStore())
    local incompleteEntries = Shared.BuildAggregatedQuestEntries(getBotQuestsIncompletedStore())

    createSectionHeader(frame, MultiBot.L("tips.quests.compheader"))
    if #completeEntries == 0 then
        createEmptySectionHint(frame)
    else
        for _, entry in ipairs(completeEntries) do
            createQuestRowWithBots(frame, entry)
        end
    end

    createSectionHeader(frame, MultiBot.L("tips.quests.incompheader"))
    if #incompleteEntries == 0 then
        createEmptySectionHint(frame)
    else
        for _, entry in ipairs(incompleteEntries) do
            createQuestRowWithBots(frame, entry)
        end
    end

    if frame.summary then
        frame.summary:SetText("")
    end
end

function QuestAllFrame:SetLoading()
    clearList(self)

    local loading = self.aceGUI:Create("Label")
    loading:SetFullWidth(true)
    loading:SetText(LOADING or "Loading...")
    self.scroll:AddChild(loading)

    if self.summary then
        self.summary:SetText("")
    end
end

function QuestAllFrame:Show()
    if self.window then
        self.window:Show()
    end
end

function MultiBot.InitializeQuestAllFrame()
    if QuestAllFrame.window then
        return QuestAllFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_BotQuestAllPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_BotQuestAllPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_BotQuestAllPopup")

    window:SetTitle(MultiBot.L("tips.quests.alllist"))
    window:SetWidth(420)
    window:SetHeight(460)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestAll") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_all_popup") end

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
        local allStore = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsAll")) or MultiBot.BotQuestsAll
        local completedStore = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsCompleted")) or MultiBot.BotQuestsCompleted
        local incompletedStore = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("BotQuestsIncompleted")) or MultiBot.BotQuestsIncompleted

        if MultiBot.Store and MultiBot.Store.ClearTable then
            MultiBot.Store.ClearTable(allStore)
            MultiBot.Store.ClearTable(completedStore)
            MultiBot.Store.ClearTable(incompletedStore)
        end
        clearList(QuestAllFrame)
    end)

    QuestAllFrame.window = window
    QuestAllFrame.aceGUI = aceGUI
    QuestAllFrame.scroll = scroll
    QuestAllFrame.summary = summary

    MultiBot.tBotAllPopup = window
    return QuestAllFrame
end