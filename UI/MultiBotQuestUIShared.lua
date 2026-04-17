if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
MultiBot.QuestUIShared = Shared

Shared.ROW_HEIGHT = 24
Shared.DETAIL_ROW_HEIGHT = 16
Shared.PANEL_ALPHA = 0.90
Shared.SUBPANEL_ALPHA = 0.72
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

    local row = self.aceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local icon = self.aceGUI:Create("Icon")
    icon:SetImage(opts.iconPath or Shared.ICON_BOT_QUEST or "Interface\\Icons\\inv_misc_note_02")
    icon:SetImageSize(opts.iconSize or 14, opts.iconSize or 14)
    icon:SetWidth(opts.iconWidth or 20)
    row:AddChild(icon)

    local label = self.aceGUI:Create("InteractiveLabel")
    label:SetWidth(opts.labelWidth or 320)
    label:SetText(Shared.BuildQuestLink(entry.id, entry.name))
    label:SetCallback("OnEnter", function(widget)
        setQuestTooltip(widget, entry.id)
    end)
    label:SetCallback("OnLeave", GameTooltip_Hide)
    row:AddChild(label)

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