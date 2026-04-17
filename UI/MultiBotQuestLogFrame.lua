if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestLogFrame = MultiBot.QuestLogFrame or {}
MultiBot.QuestLogFrame = QuestLogFrame

local function getMemberNamesOnQuest(questIndex)
    local names = {}

    local function addUnit(unit)
        if not UnitExists(unit) or not IsUnitOnQuest(questIndex, unit) then
            return
        end

        local name = UnitName(unit)
        if name then
            table.insert(names, name)
        end
    end

    if GetNumRaidMembers() > 0 then
        for index = 1, 40 do
            addUnit("raid" .. index)
        end
    elseif GetNumPartyMembers() > 0 then
        for index = 1, 4 do
            addUnit("party" .. index)
        end
    end

    table.sort(names)
    return names
end

local function showQuestTooltip(questIndex, questLink, owner)
    if not questIndex or not questLink then
        return
    end

    GameTooltip:SetOwner(owner or UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(questLink)

    local objectiveCount = GetNumQuestLeaderBoards(questIndex)
    if objectiveCount and objectiveCount > 0 then
        for objectiveIndex = 1, objectiveCount do
            local objectiveText, _, finished = GetQuestLogLeaderBoard(objectiveIndex, questIndex)
            if objectiveText then
                local tint = finished and 0.5 or 1
                GameTooltip:AddLine("• " .. objectiveText, tint, tint, tint)
            end
        end
    end

    local members = getMemberNamesOnQuest(questIndex)
    if #members > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Groupe :", 0.8, 0.8, 0.8)
        for _, name in ipairs(members) do
            GameTooltip:AddLine("- " .. name)
        end
    end

    GameTooltip:Show()
end

local function handleQuestClick(questID, button)
    if not questID then
        return
    end

    for questIndex = 1, GetNumQuestLogEntries() do
        local questLink = GetQuestLink(questIndex)
        local listedQuestID = tonumber(questLink and questLink:match("|Hquest:(%d+):"))
        if listedQuestID == questID then
            SelectQuestLogEntry(questIndex)

            if button == "RightButton" then
                if GetNumRaidMembers() > 0 then
                    SendChatMessage("drop " .. questLink, "RAID")
                elseif GetNumPartyMembers() > 0 then
                    SendChatMessage("drop " .. questLink, "PARTY")
                end
                SetAbandonQuest()
                AbandonQuest()
            else
                QuestLogPushQuest()
           end

            return
        end
    end
end

local function createQuestRow(self, aceGUI, questIndex, questID, questLink)
    local row = aceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local icon = aceGUI:Create("Icon")
    icon:SetImage(Shared.ICON_QUEST or "Interface\\Icons\\inv_misc_note_01")
    icon:SetImageSize(14, 14)
    icon:SetWidth(20)
    row:AddChild(icon)

    local label = aceGUI:Create("InteractiveLabel")
    label:SetText(questLink:gsub("%[", "|cff00ff00["):gsub("%]", "]|r"))
    label:SetWidth(320)
    label:SetCallback("OnEnter", function(widget)
        showQuestTooltip(questIndex, questLink, widget.frame)
    end)
    label:SetCallback("OnLeave", function()
        GameTooltip_Hide()
    end)
    label:SetCallback("OnClick", function(_, _, button)
        handleQuestClick(questID, button)
    end)
    row:AddChild(label)

    self.scroll:AddChild(row)
end

function QuestLogFrame:Refresh()
    if not self.scroll then
        return
    end

    self.scroll:ReleaseChildren()

    local visibleCount = 0
    for questIndex = 1, GetNumQuestLogEntries() do
        local questLink = GetQuestLink(questIndex)
        local _, _, _, _, isCollapsed = GetQuestLogTitle(questIndex)
        local questID = tonumber(questLink and questLink:match("|Hquest:(%d+):"))

        if questLink and questID and isCollapsed == nil then
            visibleCount = visibleCount + 1
            createQuestRow(self, self.aceGUI, questIndex, questID, questLink)
        end
    end

    if visibleCount == 0 then
        local noData = self.aceGUI:Create("Label")
        noData:SetFullWidth(true)
        noData:SetText(MultiBot.L("tips.quests.gobnosearchdata") or "No quests")
        self.scroll:AddChild(noData)
    end
end

function QuestLogFrame:Toggle()
    local window = self.window
    if not window then
        return
    end

    if window:IsShown() then
        window:Hide()
        return
    end

    window:Show()
    self:Refresh()
end

function QuestLogFrame:Hide()
    if self.window then
        self.window:Hide()
    end
end

function MultiBot.InitializeQuestLogFrame()
    if QuestLogFrame.window then
        return QuestLogFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_QuestPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_QuestPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_QuestPopup")

    window:SetTitle(QUEST_LOG)
    window:SetWidth(390)
    window:SetHeight(470)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "QuestLog") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "quest_popup") end

    local content = aceGUI:Create("SimpleGroup")
    content:SetFullWidth(true)
    content:SetFullHeight(true)
    content:SetLayout("List")
    window:AddChild(content)

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")
    content:AddChild(scroll)

    QuestLogFrame.window = window
    QuestLogFrame.scroll = scroll
    QuestLogFrame.aceGUI = aceGUI

    return QuestLogFrame
end