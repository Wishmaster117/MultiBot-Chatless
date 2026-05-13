if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
MultiBot.QuestUIShared = Shared

Shared.ROW_HEIGHT = 24
Shared.DETAIL_ROW_HEIGHT = 16
Shared.PANEL_ALPHA = 0.90
Shared.SUBPANEL_ALPHA = 0.72
Shared.DROP_BUTTON_WIDTH = 90
Shared.DROP_LABEL_WIDTH = 210
Shared.QUEST_ROW_LEFT_PADDING = 12
Shared.QUEST_SUMMARY_PREFIX = "   "
Shared.QUEST_TOP_PADDING = 16
Shared.ICON_QUEST = "Interface\\Icons\\inv_misc_note_01"
Shared.ICON_BOT_QUEST = "Interface\\Icons\\inv_misc_note_02"

function Shared.ApplyPanelStyle(frame, bgAlpha)
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
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or Shared.PANEL_ALPHA)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

function Shared.ApplyWindowContentStyle(window, bgAlpha)
    if window and window.content then
        Shared.ApplyPanelStyle(window.content, bgAlpha or Shared.PANEL_ALPHA)
    end
end

function Shared.AddTopPadding(aceGUI, parent, height)
    if not aceGUI or not parent or not parent.AddChild then
        return
    end

    local spacer = aceGUI:Create("SimpleGroup")
    spacer:SetFullWidth(true)
    spacer:SetHeight(height or Shared.QUEST_TOP_PADDING)
    spacer:SetLayout("Flow")
    parent:AddChild(spacer)
end

function Shared.ApplyEditBoxStyle(widget)
    if not widget or not widget.frame or not widget.editbox then
        return
    end

    Shared.ApplyPanelStyle(widget.frame, 0.92)

    local editBox = widget.editbox
    if editBox.GetRegions then
        for _, region in ipairs({ editBox:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.SetAlpha then
                region:SetAlpha(0)
            end
        end
    end

    editBox:ClearAllPoints()
    editBox:SetPoint("TOPLEFT", widget.frame, "TOPLEFT", 8, -4)
    editBox:SetPoint("BOTTOMRIGHT", widget.frame, "BOTTOMRIGHT", -8, 4)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextInsets(4, 4, 3, 3)

    widget:SetHeight(32)
    if widget.frame.SetHeight then
        widget.frame:SetHeight(32)
    end
end

function Shared.GetQuestDropButtonText()
    return MultiBot.L("tips.quests.drop", ABANDON_QUEST or "Abandon")
end

function Shared.SendDropQuest(botName, entry)
    if type(botName) ~= "string" or botName == "" or type(entry) ~= "table" then
        return false
    end

    local command = "drop " .. Shared.BuildQuestLink(entry.id, entry.originalName or entry.name)
    if MultiBot.ActionToTarget then
        return MultiBot.ActionToTarget(command, botName)
    end

    if SendChatMessage then
        SendChatMessage(command, "WHISPER", nil, botName)
        return true
    end

    return false
end

function Shared.RemoveQuestEntryFromBucket(bucket, entry)
    if type(bucket) ~= "table" or type(entry) ~= "table" then
        return
    end

    if entry.id ~= nil then
        bucket[entry.id] = nil
        bucket[tostring(entry.id)] = nil
    end

    local entryName = tostring(entry.originalName or entry.name or "")
    if entryName == "" then
        return
    end

    local removeKeys = {}
    for questID, questName in pairs(bucket) do
        local storedName = tostring(questName or "")
        if storedName == entryName or storedName == tostring(entry.name or "") then
            table.insert(removeKeys, questID)
        end
    end

    for _, questID in ipairs(removeKeys) do
        bucket[questID] = nil
    end
end

local function setQuestTooltip(widget, questID)
    if not questID then
        return
    end

    GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink("quest:" .. tostring(questID))
    GameTooltip:Show()
end

function Shared.CreateQuestEntryRow(self, entry, opts)
    if not self or not self.aceGUI or not self.scroll or type(entry) ~= "table" then
        return
    end

    opts = opts or {}
    local hasDropAction = type(opts.onDrop) == "function"

    local row = self.aceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local leftPadding = tonumber(opts.leftPadding or 0) or 0
    if leftPadding > 0 then
        local spacer = self.aceGUI:Create("Label")
        spacer:SetText("")
        spacer:SetWidth(leftPadding)
        row:AddChild(spacer)
    end

    local icon = self.aceGUI:Create("Icon")
    icon:SetImage(opts.iconPath or Shared.ICON_BOT_QUEST or "Interface\\Icons\\inv_misc_note_02")
    icon:SetImageSize(opts.iconSize or 14, opts.iconSize or 14)
    icon:SetWidth(opts.iconWidth or 20)
    row:AddChild(icon)

    local label = self.aceGUI:Create("InteractiveLabel")
    label:SetWidth(opts.labelWidth or (hasDropAction and Shared.DROP_LABEL_WIDTH) or 320)
    label:SetText(Shared.BuildQuestLink(entry.id, entry.name))
    label:SetCallback("OnEnter", function(widget)
        setQuestTooltip(widget, entry.id)
    end)
    label:SetCallback("OnLeave", GameTooltip_Hide)
    row:AddChild(label)

    if hasDropAction then
        local dropButton = self.aceGUI:Create("Button")
        dropButton:SetText(opts.dropButtonText or Shared.GetQuestDropButtonText())
        dropButton:SetWidth(opts.dropButtonWidth or Shared.DROP_BUTTON_WIDTH)
        if dropButton.SetHeight then
            dropButton:SetHeight(opts.dropButtonHeight or 20)
        end
        dropButton:SetCallback("OnClick", function(widget)
            opts.onDrop(entry, widget)
        end)
        row:AddChild(dropButton)
    end

    self.scroll:AddChild(row)

    if opts.showBots ~= false and entry.bots and #entry.bots > 0 then
        local botsLabel = self.aceGUI:Create("Label")
        botsLabel:SetFullWidth(true)
        botsLabel:SetText((opts.botsPrefix or "    ") .. Shared.FormatBotsLabel(entry.bots))
        self.scroll:AddChild(botsLabel)
    end
end

function Shared.RenderQuestEntries(self, entries, opts)
    if not self then
        return
    end

    if self.scroll then
        self.scroll:ReleaseChildren()
    end

    opts = opts or {}
    local questEntries = entries or {}

    for _, entry in ipairs(questEntries) do
        Shared.CreateQuestEntryRow(self, entry, opts.rowOptions)
    end

    if #questEntries == 0 and self.aceGUI and self.scroll then
        local noData = self.aceGUI:Create("Label")
        noData:SetFullWidth(true)
        noData:SetText(opts.emptyText or MultiBot.L("tips.quests.gobnosearchdata") or "No quests")
        self.scroll:AddChild(noData)
    end

    if self.summary then
        self.summary:SetText(opts.summaryText or "")
    end
end

function Shared.GetLocalizedQuestName(questID, fallback)
    if MultiBot.GetLocalizedQuestName then
        return MultiBot.GetLocalizedQuestName(questID) or fallback or tostring(questID)
    end

    return fallback or tostring(questID)
end

function Shared.BuildQuestLink(questID, questName)
    local localizedName = Shared.GetLocalizedQuestName(questID, questName)
    return ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(questID, localizedName)
end

function Shared.SortQuestEntries(questsById)
    local entries = {}
    for questID, questName in pairs(questsById or {}) do
        local numericID = tonumber(questID)
        table.insert(entries, {
            id = numericID or questID,
            sortID = numericID or 0,
            name = Shared.GetLocalizedQuestName(numericID, questName),
            originalName = questName,
        })
    end

    table.sort(entries, function(left, right)
        local leftName = string.lower(tostring(left.name or left.originalName or ""))
        local rightName = string.lower(tostring(right.name or right.originalName or ""))
        if leftName == rightName then
            return (left.sortID or 0) < (right.sortID or 0)
        end
        return leftName < rightName
    end)

    return entries
end

function Shared.AppendBotName(target, botName)
    if not target.bots then
        target.bots = {}
    end

    table.insert(target.bots, botName)
    table.sort(target.bots)
end

function Shared.FormatBotsLabel(bots)
    return (MultiBot.L("tips.quests.botsword") or "Bots: ") .. table.concat(bots or {}, ", ")
end

function Shared.BuildAggregatedQuestEntries(source)
    local questMap = {}

    for botName, quests in pairs(source or {}) do
        for questID, questName in pairs(quests or {}) do
            local numericID = tonumber(questID)
            if numericID then
                if not questMap[numericID] then
                    questMap[numericID] = {
                        id = numericID,
                        name = Shared.GetLocalizedQuestName(numericID, questName),
                        bots = {},
                    }
                end
                Shared.AppendBotName(questMap[numericID], botName)
            end
        end
    end

    local entries = {}
    for _, entry in pairs(questMap) do
        table.insert(entries, entry)
    end

    table.sort(entries, function(left, right)
        local leftName = string.lower(tostring(left.name or ""))
        local rightName = string.lower(tostring(right.name or ""))
        if leftName == rightName then
            return (left.id or 0) < (right.id or 0)
        end
        return leftName < rightName
    end)

    return entries
end

function Shared.GetGameObjectEntries(bot)
    local entries = MultiBot.LastGameObjectSearch and MultiBot.LastGameObjectSearch[bot]
    if type(entries) ~= "table" then
        return nil
    end

    return entries
end

function Shared.CollectSortedGameObjectBots()
    local bots = {}
    for bot in pairs(MultiBot.LastGameObjectSearch or {}) do
        local entries = Shared.GetGameObjectEntries(bot)
        if entries and #entries > 0 then
            table.insert(bots, bot)
        end
    end
    table.sort(bots)
    return bots
end

function Shared.IsDashedSectionHeader(text)
    return type(text) == "string" and text:find("^%s*%-+%s*.-%s*%-+%s*$") ~= nil
end

function Shared.BuildGameObjectCopyText(bots)
    local lines = {}

    for _, bot in ipairs(bots or {}) do
        local entries = Shared.GetGameObjectEntries(bot) or {}
        table.insert(lines, ("Bot: %s"):format(bot))
        for _, entry in ipairs(entries) do
            table.insert(lines, entry)
        end
        table.insert(lines, "")
    end

    if #lines == 0 then
        return MultiBot.L("tips.quests.gobnosearchdata")
    end

    return table.concat(lines, "\n")
end
