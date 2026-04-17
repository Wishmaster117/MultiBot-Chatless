if not MultiBot then return end

local QuestsMenu = MultiBot.QuestsMenu or {}
MultiBot.QuestsMenu = QuestsMenu

local function ensureRuntimeTable(key)
    if MultiBot.Store and MultiBot.Store.EnsureRuntimeTable then
        return MultiBot.Store.EnsureRuntimeTable(key)
    end
    MultiBot[key] = type(MultiBot[key]) == "table" and MultiBot[key] or {}
    return MultiBot[key]
end

local function setRuntimeFlag(key, value)
    if MultiBot.Store and MultiBot.Store.SetRuntimeValue then
        MultiBot.Store.SetRuntimeValue(key, value)
        return
    end
    MultiBot[key] = value
end

local function clearTableInPlace(tbl)
    if type(tbl) ~= "table" then
        return
    end
    if MultiBot.Store and MultiBot.Store.ClearTable then
        MultiBot.Store.ClearTable(tbl)
        return
    end
    for key in pairs(tbl) do
        tbl[key] = nil
    end
end

local function resetQuestResultFrame(frame, loadingText)
    if type(frame) ~= "table" then
        return
    end

    if frame.scroll and frame.scroll.ReleaseChildren then
        frame.scroll:ReleaseChildren()
    end
    if frame.summary and frame.summary.SetText then
        frame.summary:SetText(loadingText or "")
    end
end

local function getTargetBotOrError()
    local botName = UnitName("target")
    if botName and UnitIsPlayer("target") then
        return botName
    end
    UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.questcomperror"), 1, 0.2, 0.2, 1)
    return nil
end

local function setSubButtonsVisible(buttonA, buttonB, visible)
    if visible then
        buttonA:doShow()
        buttonB:doShow()
        return
    end

    buttonA:doHide()
    buttonB:doHide()
end

local function shouldAutoCollapseQuestGroups()
    if MultiBot.GetDisableAutoCollapse then
        return not MultiBot.GetDisableAutoCollapse()
    end
    return true
end

local function collapseOtherQuestGroups(activeGroup)
    if not shouldAutoCollapseQuestGroups() then
        return
    end

    local groups = QuestsMenu.expandableGroups
    if type(groups) ~= "table" then
        return
    end

    for index = 1, #groups do
        local group = groups[index]
        if group ~= activeGroup then
            setSubButtonsVisible(group.buttonA, group.buttonB, false)
        end
    end
end

local function registerExpandableGroup(rootButton, buttonA, buttonB)
    QuestsMenu.expandableGroups = QuestsMenu.expandableGroups or {}
    local group = {
        root = rootButton,
        buttonA = buttonA,
        buttonB = buttonB,
    }
    table.insert(QuestsMenu.expandableGroups, group)

    rootButton.doLeft = function()
        local isOpen = buttonA:IsShown() or buttonB:IsShown()
        if isOpen then
            setSubButtonsVisible(buttonA, buttonB, false)
            return
        end

        collapseOtherQuestGroups(group)
        setSubButtonsVisible(buttonA, buttonB, true)
    end

    return group
end

local function sendIncomplete(method)
    setRuntimeFlag("_awaitingQuestsAll", false)
    MultiBot._lastIncMode = method

    local frame = MultiBot.InitializeQuestIncompleteFrame and MultiBot.InitializeQuestIncompleteFrame()
    if not frame then
        return
    end

    if method == "WHISPER" then
        local bot = getTargetBotOrError()
        if not bot then
            return
        end

        MultiBot._lastIncWhisperBot = bot
        ensureRuntimeTable("_awaitingQuestsIncompleted")[bot] = true
        ensureRuntimeTable("BotQuestsIncompleted")[bot] = {}
        resetQuestResultFrame(frame, MultiBot.L("tips.quests.incomplist") or "")
        MultiBot.ActionToTarget("quests incompleted", bot)
        frame:Show()
        MultiBot.TimerAfter(0.5, function()
            if MultiBot.BuildBotQuestList then
                MultiBot.BuildBotQuestList(bot)
            end
        end)
        return
    end

    clearTableInPlace(ensureRuntimeTable("BotQuestsIncompleted"))
    resetQuestResultFrame(frame, MultiBot.L("tips.quests.incomplist") or "")
    MultiBot.ActionToGroup("quests incompleted")
    frame:Show()
end

local function sendCompleted(method)
    setRuntimeFlag("_awaitingQuestsAll", false)
    MultiBot._lastCompMode = method

    local frame = MultiBot.InitializeQuestCompletedFrame and MultiBot.InitializeQuestCompletedFrame()
    if not frame then
        return
    end

    if method == "WHISPER" then
        local bot = getTargetBotOrError()
        if not bot then
            return
        end

        MultiBot._lastCompWhisperBot = bot
        ensureRuntimeTable("_awaitingQuestsCompleted")[bot] = true
        ensureRuntimeTable("BotQuestsCompleted")[bot] = {}
        resetQuestResultFrame(frame, MultiBot.L("tips.quests.complist") or "")
        MultiBot.ActionToTarget("quests completed", bot)
        frame:Show()
        MultiBot.TimerAfter(0.5, function()
            if MultiBot.BuildBotCompletedList then
                MultiBot.BuildBotCompletedList(bot)
            end
        end)
        return
    end

    clearTableInPlace(ensureRuntimeTable("BotQuestsCompleted"))
    resetQuestResultFrame(frame, MultiBot.L("tips.quests.complist") or "")
    MultiBot.ActionToGroup("quests completed")
    frame:Show()
end

local function sendAll(method)
    local frame = MultiBot.InitializeQuestAllFrame and MultiBot.InitializeQuestAllFrame()
    if not frame then
        return
    end

    MultiBot._lastAllMode = method
    setRuntimeFlag("_awaitingQuestsAll", true)
    setRuntimeFlag("_blockOtherQuests", true)
    clearTableInPlace(ensureRuntimeTable("BotQuestsAll"))
    local awaitingBots = ensureRuntimeTable("_awaitingQuestsAllBots")
    clearTableInPlace(awaitingBots)

    if method == "GROUP" then
        for index = 1, GetNumPartyMembers() do
            local botName = UnitName("party" .. index)
            if botName then
                awaitingBots[botName] = false
            end
        end
        MultiBot.ActionToGroup("quests all")
    else
        local bot = getTargetBotOrError()
        if not bot then
            setRuntimeFlag("_awaitingQuestsAll", false)
            setRuntimeFlag("_blockOtherQuests", false)
            return
        end
        awaitingBots[bot] = false
        MultiBot.ActionToTarget("quests all", bot)
    end

    frame:Show()
    frame:SetLoading()
end

function MultiBot.InitializeQuestsMenu(tRight)
    if QuestsMenu.initialized then
        return QuestsMenu
    end

    if not tRight or not tRight.addButton or not tRight.addFrame then
        return nil
    end

    local questLogFrame = MultiBot.InitializeQuestLogFrame and MultiBot.InitializeQuestLogFrame()
    MultiBot.InitializeQuestIncompleteFrame()
    MultiBot.InitializeQuestCompletedFrame()
    MultiBot.InitializeQuestAllFrame()
    --if MultiBot.InitializeGameObjectResultsFrame then MultiBot.InitializeGameObjectResultsFrame() end
    --if MultiBot.InitializeGameObjectCopyFrame then MultiBot.InitializeGameObjectCopyFrame() end

    local button = tRight.addButton("Quests Menu", 0, 0, "achievement_quests_completed_06", MultiBot.L("tips.quests.main"))
    local menu = tRight.addFrame("QuestMenu", -2, 64)
    menu:Hide()
    QuestsMenu.expandableGroups = {}

    button.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames["QuestMenu"])
    end
    button.doRight = button.doLeft

    menu.addButton("AcceptAll", 0, 30, "inv_misc_note_02", MultiBot.L("tips.quests.accept")).doLeft = function()
        MultiBot.ActionToGroup("accept *")
    end

    local listButton = menu.addButton("Quests", 0, -30, "inv_misc_book_07", MultiBot.L("tips.quests.master"))
    listButton.doRight = function()
        if questLogFrame then
            questLogFrame:Refresh()
        end
    end
    listButton.doLeft = function()
        if questLogFrame then
            questLogFrame:Toggle()
        end
    end
    tRight.buttons["Quests"] = listButton

    local incompButton = menu.addButton("BotQuestsIncomp", 0, 90, "Interface\\Icons\\INV_Misc_Bag_22", MultiBot.L("tips.quests.incompleted"))
    local incompGroup = menu.addButton("BotQuestsIncompGroup", 31, 90, "Interface\\Icons\\INV_Crate_08", MultiBot.L("tips.quests.sendpartyraid"))
    local incompWhisper = menu.addButton("BotQuestsIncompWhisper", 61, 90, "Interface\\Icons\\INV_Crate_08", MultiBot.L("tips.quests.sendwhisp"))
    incompGroup:doHide()
    incompWhisper:doHide()
    registerExpandableGroup(incompButton, incompGroup, incompWhisper)
    incompGroup.doLeft = function() sendIncomplete("GROUP") end
    incompWhisper.doLeft = function() sendIncomplete("WHISPER") end
    tRight.buttons["BotQuestsIncomp"] = incompButton
    tRight.buttons["BotQuestsIncompGroup"] = incompGroup
    tRight.buttons["BotQuestsIncompWhisper"] = incompWhisper

    local completedButton = menu.addButton("BotQuestsComp", 0, 60, "Interface\\Icons\\INV_Misc_Bag_20", MultiBot.L("tips.quests.completed"))
    local completedGroup = menu.addButton("BotQuestsCompGroup", 31, 60, "Interface\\Icons\\INV_Crate_09", MultiBot.L("tips.quests.sendpartyraid"))
    local completedWhisper = menu.addButton("BotQuestsCompWhisper", 61, 60, "Interface\\Icons\\INV_Crate_09", MultiBot.L("tips.quests.sendwhisp"))
    completedGroup:doHide()
    completedWhisper:doHide()
    registerExpandableGroup(completedButton, completedGroup, completedWhisper)
    completedGroup.doLeft = function() sendCompleted("GROUP") end
    completedWhisper.doLeft = function() sendCompleted("WHISPER") end
    tRight.buttons["BotQuestsComp"] = completedButton
    tRight.buttons["BotQuestsCompGroup"] = completedGroup
    tRight.buttons["BotQuestsCompWhisper"] = completedWhisper

    local talkButton = menu.addButton("BotQuestsTalk", 0, 0, "Interface\\Icons\\ability_hunter_pet_devilsaur", MultiBot.L("tips.quests.talk"))
    talkButton.doLeft = function()
        if not UnitExists("target") or UnitIsPlayer("target") then
            UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.talkerror"), 1, 0.2, 0.2, 1)
            return
        end
        MultiBot.ActionToGroup("talk")
    end
    tRight.buttons["BotQuestsTalk"] = talkButton

    local allButton = menu.addButton("BotQuestsAll", 0, 120, "Interface\\Icons\\INV_Misc_Book_09", MultiBot.L("tips.quests.allcompleted"))
    local allGroup = menu.addButton("BotQuestsAllGroup", 31, 120, "Interface\\Icons\\INV_Misc_Book_09", MultiBot.L("tips.quests.sendpartyraid"))
    local allWhisper = menu.addButton("BotQuestsAllWhisper", 61, 120, "Interface\\Icons\\INV_Misc_Book_09", MultiBot.L("tips.quests.sendwhisp"))
    allGroup:doHide()
    allWhisper:doHide()
    registerExpandableGroup(allButton, allGroup, allWhisper)
    allGroup.doLeft = function() sendAll("GROUP") end
    allWhisper.doLeft = function() sendAll("WHISPER") end
    tRight.buttons["BotQuestsAll"] = allButton
    tRight.buttons["BotQuestsAllGroup"] = allGroup
    tRight.buttons["BotQuestsAllWhisper"] = allWhisper

    local gobButton = menu.addButton("BotUseGOB", 0, 150, "Interface\\Icons\\inv_misc_spyglass_01", MultiBot.L("tips.quests.gobsmaster"))
    local gobNameButton = menu.addButton("BotUseGOBName", 31, 150, "Interface\\Icons\\inv_misc_note_05", MultiBot.L("tips.quests.gobenter"))
    local gobSearchButton = menu.addButton("BotUseGOBSearch", 61, 150, "Interface\\Icons\\inv_misc_spyglass_02", MultiBot.L("tips.quests.gobsearch"))
    gobNameButton:doHide()
    gobSearchButton:doHide()
    registerExpandableGroup(gobButton, gobNameButton, gobSearchButton)
    gobNameButton.doLeft = function()
        if not ShowPrompt then
            return
        end
        ShowPrompt(MultiBot.L("tips.quests.gobpromptname"), function(gobName)
            local normalized = tostring(gobName or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if normalized == "" then
                UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.goberrorname"), 1, 0.2, 0.2, 1)
                return
            end
            local bot = UnitName("target")
            if not bot or not UnitIsPlayer("target") then
                UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.gobselectboterror"), 1, 0.2, 0.2, 1)
                return
            end
            SendChatMessage("u " .. normalized, "WHISPER", nil, bot)
        end)
    end
    gobSearchButton.doLeft = function()
        MultiBot.ActionToGroup("los")
    end
    tRight.buttons["BotUseGOB"] = gobButton
    tRight.buttons["BotUseGOBName"] = gobNameButton
    tRight.buttons["BotUseGOBSearch"] = gobSearchButton

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tRight, "RightRoot", {
            { name = "Quests Menu", frameName = "QuestMenu" },
        })
    end

    QuestsMenu.initialized = true
    QuestsMenu.button = button
    QuestsMenu.menu = menu
    QuestsMenu.questLogFrame = questLogFrame
    return QuestsMenu
end