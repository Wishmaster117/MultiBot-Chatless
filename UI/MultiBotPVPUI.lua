-- MultiBot PvP UI with cache per bots
-- local ADDON = "MultiBot"

local function MBPVP_GetAceGUI()
    if type(LibStub) ~= "table" then
        return nil
    end
    return LibStub("AceGUI-3.0", true)
end

local function CreateStyledFrame()
    -- Main frame
    local f = CreateFrame("Frame", "MultiBotPVPFrame", UIParent)
    f:SetSize(420, 490)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:Hide()
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    if f.SetBackdropColor then f:SetBackdropColor(0, 0, 0, 0.8) end
    if f.SetBackdropBorderColor then f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end

    -- Header + title
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture(MultiBot.SafeTexturePath("Interface\\DialogFrame\\UI-DialogBox-Header"))
    titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -6)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -6)
    titleBg:SetHeight(48)
    f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.Title:SetPoint("TOP", titleBg, "TOP", 0, -10)
    f.Title:SetText(MultiBot.L("options.pvp.title"))

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 64)

    -- Thin inner border around displayed PvP data.
    local dataRoot = CreateFrame("Frame", nil, content)
    dataRoot:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    dataRoot:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    dataRoot:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    if dataRoot.SetBackdropColor then dataRoot:SetBackdropColor(0, 0, 0, 0.15) end
    if dataRoot.SetBackdropBorderColor then dataRoot:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9) end

    -- Column offsets
    local colOffsets = { -120, -80, -40 }

    -- Section factory
    local function CreateSection(parent, topOffset, height, title)
        local sec = CreateFrame("Frame", nil, parent)
        sec:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -topOffset)
        sec:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -topOffset)
        sec:SetHeight(height)
        sec.title = sec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sec.title:SetPoint("TOPLEFT", sec, "TOPLEFT", 0, 0)
        sec.title:SetText(title)
        return sec
    end

    local function AddRow(sec, index, label, col1, col2, col3)
        local lineHeight, startY = 18, -22
        local y = startY - (index - 1) * lineHeight
        local lbl = sec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", sec, "TOPLEFT", 4, y)
        lbl:SetText(label)
        local out = {}
        local vals = { col1 or "-", col2 or "-", col3 or "-" }
        for i = 1, 3 do
            local v = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            v:SetPoint("TOPRIGHT", sec, "TOPRIGHT", colOffsets[i], y)
            v:SetText(vals[i])
            out[i] = v
        end
        return out
    end

    -- Build layou
    local top = 58
    local spacing = 12

    local customHeader = dataRoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customHeader:SetPoint("TOPLEFT", dataRoot, "TOPLEFT", 8, -34)
    customHeader:SetText(MultiBot.L("tips.every.pvpcustom"))
    top = top + 18 + 6

    -- Bot selector (cache par bot) - alimenté par les réponses [PVP] reçues en whisper
    local botDropDown
    local AceGUI = MBPVP_GetAceGUI()
    if AceGUI then
        botDropDown = AceGUI:Create("Dropdown")
        botDropDown:SetLabel(MultiBot.L("ui.pvp.bot_selector"))
        botDropDown:SetWidth(220)
        botDropDown.frame:SetParent(dataRoot)
        botDropDown.frame:ClearAllPoints()
        botDropDown.frame:SetPoint("TOPRIGHT", dataRoot, "TOPRIGHT", -8, -4)
    else
        botDropDown = CreateFrame("Frame", "MultiBotPVPBotDropDown", content, "UIDropDownMenuTemplate")
        botDropDown:SetParent(dataRoot)
        botDropDown:ClearAllPoints()
        botDropDown:SetPoint("TOPRIGHT", dataRoot, "TOPRIGHT", 14, 8)
        UIDropDownMenu_SetWidth(botDropDown, 180)
        UIDropDownMenu_SetText(botDropDown, MultiBot.L("ui.pvp.bot_selector"))
    end

    -- HONNEUR section: only one row "Honneur"
    local honorHeight = 18 + 1 * 18 + 8
    local honor = CreateSection(dataRoot, top, honorHeight, MultiBot.L("ui.pvp.honor_section"))

    -- Column header labels for Honneur
    local hdr1 = honor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr1:SetPoint("TOPRIGHT", honor, "TOPRIGHT", colOffsets[1], -2)
   hdr1:SetText(MultiBot.L("tips.every.pvptotal"))

    -- separator
    local sepH = honor:CreateTexture(nil, "ARTWORK")
    sepH:SetHeight(1)
    sepH:SetPoint("TOPLEFT", honor, "TOPLEFT", 0, -18)
    sepH:SetPoint("TOPRIGHT", honor, "TOPRIGHT", 0, -18)
    sepH:SetTexture(0.5, 0.5, 0.5, 0.6)

    -- Only the Honneur row
    local honorRow = AddRow(honor, 1, MultiBot.L("ui.pvp.honor_row"), "-", "-", "-")
	if honorRow[2] then honorRow[2]:Hide() end
    if honorRow[3] then honorRow[3]:Hide() end
    -- honorRow[1] = Total column fontstring

    top = top + honorHeight + spacing

    -- ARENE section
    local arenaBlockHeight = 18 + 2 * 18 + 6 -- title + two lines (team + rating) approx
    local arena = CreateSection(dataRoot, top, arenaBlockHeight * 3 + spacing * 2, MultiBot.L("ui.pvp.arena_section"))

    -- separator
    local arenaSep = arena:CreateTexture(nil, "ARTWORK")
    arenaSep:SetHeight(1)
    arenaSep:SetPoint("TOPLEFT", arena, "TOPLEFT", 0, -18)
    arenaSep:SetPoint("TOPRIGHT", arena, "TOPRIGHT", 0, -18)
    arenaSep:SetTexture(0.5, 0.5, 0.5, 0.6)

    -- Points d'Arène (affiché à gauche de la section Arène)
    arena.pointsLabel = arena:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arena.pointsLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", 120, 0)
    arena.pointsLabel:SetText(MultiBot.L("tips.every.pvparenapoints"))

    arena.pointsValue = arena:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arena.pointsValue:SetPoint("LEFT", arena.pointsLabel, "RIGHT", 6, 0)
    arena.pointsValue:SetText("-")

    -- helper to create per-mode display inside arena
    local function CreateArenaModeRow(parent, idx, modeLabel, offsetY)
        -- mode title (e.g., "Mode: 2v2")
        local modeText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modeText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY -32)
         modeText:SetText(MultiBot.L("tips.every.pvparenamode") .. modeLabel)

        -- team name
        local teamText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        teamText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY - 50)
        --ratingText:SetText(MultiBot.L("tips.every.pvparenanoteamrank"))

        -- rating
        local ratingText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ratingText:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -offsetY - 34)

        -- Keep explicit local variables before SetText assignments
        -- to avoid accidental global lookups if this block is edited later.
        teamText:SetText(MultiBot.L("tips.every.pvparenanoteam"))
        ratingText:SetText(MultiBot.L("tips.every.pvparenanoteamrank"))

        return { mode = modeText, team = teamText, rating = ratingText }
    end

    -- create rows for 2v2, 3v3, 5v5
    local modes = { "2v2", "3v3", "5v5" }
    local arenaRows = {}
    for i = 1, 3 do
        -- local offset = 0 + (i-1) * (arenaBlockHeight + spacing)
        arenaRows[modes[i]] = CreateArenaModeRow(arena, i, modes[i], 0 + (i-1) * (arenaBlockHeight + 6))
    end

    --top = top + arenaBlockHeight * 3 + spacing * 2
    -- Dummy pane (shares content area)
    local dummy = CreateFrame("Frame", nil, f)
    dummy:SetPoint("TOPLEFT", dataRoot, "TOPLEFT")
    dummy:SetPoint("BOTTOMRIGHT", dataRoot, "BOTTOMRIGHT")
    dummy:Hide()
    dummy.text = dummy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dummy.text:SetPoint("TOPLEFT", dummy, "TOPLEFT", 4, -4)
    dummy.text:SetText(MultiBot.L("ui.pvp.tab.placeholder"))

    -- Tabs (bottom)
    if AceGUI then
        local tabGroup = AceGUI:Create("TabGroup")
        tabGroup.frame:SetParent(f)
        tabGroup.frame:ClearAllPoints()
        tabGroup.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 10)
        tabGroup.frame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 10)
        tabGroup:SetTabs({
            { text = MultiBot.L("ui.pvp.tab.pvp"), value = "pvp" },
            --{ text = MultiBot.L("ui.pvp.tab.placeholder"), value = "dummy", disabled = true },
        })
        tabGroup:SetCallback("OnGroupSelected", function(_, _, group)
            if group == "dummy" then
                content:Hide()
                dummy:Show()
            else
                content:Show()
                dummy:Hide()
            end
        end)
        tabGroup:SelectTab("pvp")
        f._tabGroup = tabGroup
    else
        local tabs = {}
        local tabNames = {
            { text = MultiBot.L("ui.pvp.tab.pvp"), disabled = false },
            --{ text = MultiBot.L("ui.pvp.tab.placeholder"), disabled = true },
        }

        for i, tabCfg in ipairs(tabNames) do
            local template = (_G["CharacterFrameTabButtonTemplate"] and
                "CharacterFrameTabButtonTemplate") or "UIPanelButtonTemplate"
            local tab = CreateFrame("Button", f:GetName() .. "Tab" .. i, f, template)
            tab:SetSize(90, 22)
            tab:SetText(tabCfg.text)
            tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12 + (i - 1) * 98, 12)
            tab.id = i
            if tabCfg.disabled then
                if tab.SetDisabled then
                    tab:SetDisabled(true)
                elseif tab.Disable then
                    tab:Disable()
                end
            end
            tabs[i] = tab
        end

        local function SelectTab(id)
            if id == 1 then content:Show(); dummy:Hide() else content:Hide(); dummy:Show() end
            for idx, t in ipairs(tabs) do
                if t.LockHighlight then
                    if idx == id then t:LockHighlight() else t:UnlockHighlight() end
                else
                    if idx == id and t.Disable then t:Disable() elseif t.Enable then t:Enable() end
                end
            end
        end

        for _, t in ipairs(tabs) do
            t:SetScript("OnClick", function(self) SelectTab(self.id) end)
        end

        SelectTab(1)
    end

    -- expose references for update from chat handler
	f._botDropDown = botDropDown
	f._arena = arena
    f._honorTotal = honorRow[1]
    f._arenaRows = arenaRows
    f._customHeader = customHeader

    return f
end

-- ==========================
-- PvP cache par bot (whispers)
-- ==========================

local function MBPVP_NormalizeSenderName(sender)
    if not sender or sender == "" then
        return ""
    end

    local simpleName = sender:match("([^%-]+)") or sender
    simpleName = simpleName:match("([^%.%-]+)") or simpleName
    return simpleName
end

local function MBPVP_Trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function MBPVP_ExtractFirstTwoNumbers(line)
    local a, b
    for n in tostring(line):gmatch("(%d+)") do
        if not a then
            a = n
        else
            b = n
            break
        end
    end
    return a, b
end

-- Extrait un rating quel que soit le mot localisé:
-- "(rating 1234)" "(cote 1234)" "(Wertung 1234)" "(评分 1234)" "(평점 1234)" etc.
local function MBPVP_ExtractTeamRating(line)
    return tostring(line):match("%(%s*[^%d]*(%d+)%s*%)")
end

local function MBPVP_PrefixFromTemplate(s, fallback)
    if type(s) ~= "string" then
        return fallback or ""
    end

    local p = s:match("^(.-:%s*)")
    return p or (fallback or "")
end

local function MBPVP_EnsureCache(frame)
    if not frame._botCache then
        frame._botCache = {}
    end
end

local function MBPVP_GetState(frame, botName)
    MBPVP_EnsureCache(frame)

    if not frame._botCache[botName] then
        frame._botCache[botName] = {
            honorPoints = nil,
            arenaPoints = nil,
            teams = {
                ["2v2"] = { team = nil, rating = nil, noTeam = true },
                ["3v3"] = { team = nil, rating = nil, noTeam = true },
                ["5v5"] = { team = nil, rating = nil, noTeam = true },
            },
            lastUpdate = 0,
        }
    end

    return frame._botCache[botName]
end

local function MBPVP_GetSortedBotList(frame)
    MBPVP_EnsureCache(frame)

    local list = {}
    for name, st in pairs(frame._botCache) do
        list[#list + 1] = { name = name, ts = st.lastUpdate or 0 }
    end

    table.sort(list, function(a, b)
        if a.ts == b.ts then
            return a.name < b.name
        end
        return a.ts > b.ts
    end)

    local out = {}
    for _, v in ipairs(list) do
        out[#out + 1] = v.name
    end
    return out
end

local function MBPVP_ApplyStateToUi(frame, botName)
    if not frame or not botName or botName == "" then
        return
    end

    MBPVP_EnsureCache(frame)

    local st = frame._botCache[botName]
    if not st then
        return
    end

    -- Header
    if frame._customHeader then
        frame._customHeader:SetText(MultiBot.L("tips.every.pvparenadata") .. botName)
    end

    -- Currency
    if frame._honorTotal then
        frame._honorTotal:SetText(st.honorPoints or "-")
    end

    if frame._arena and frame._arena.pointsValue then
        frame._arena.pointsValue:SetText(st.arenaPoints or "-")
    end

    -- Rows
    if frame._arenaRows then
        local teamPrefix = MBPVP_PrefixFromTemplate(MultiBot.L("tips.every.pvparenanoteam"), MultiBot.L("ui.pvp.prefix.team"))
        local rankPrefix = MBPVP_PrefixFromTemplate(MultiBot.L("tips.every.pvparenanoteamrank"), MultiBot.L("ui.pvp.prefix.rating"))

        for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
            local row = frame._arenaRows[mode]
            local mt = st.teams and st.teams[mode]
            if row then
                row.mode:SetText(MultiBot.L("tips.every.pvparenamode") .. mode)

                if mt and mt.team then
                    row.team:SetText(teamPrefix .. mt.team)
                else
                    row.team:SetText(MultiBot.L("tips.every.pvparenanoteam"))
                end

                if mt and mt.rating then
                    row.rating:SetText(rankPrefix .. mt.rating)
                else
                    row.rating:SetText(MultiBot.L("tips.every.pvparenanoteamrank"))
                end
            end
        end
    end
end

local function MBPVP_SetCurrentBot(frame, botName)
    if not frame then
        return
    end

    frame._currentBot = botName

    if frame._botDropDown then
        if frame._botDropDown.type == "Dropdown" then
            if botName and botName ~= "" then
                frame._botDropDown:SetValue(botName)
                frame._botDropDown:SetText(botName)
            else
                frame._botDropDown:SetValue(nil)
                frame._botDropDown:SetText(MultiBot.L("ui.pvp.bot_selector"))
            end
        else
            UIDropDownMenu_SetSelectedValue(frame._botDropDown, botName)
            UIDropDownMenu_SetText(frame._botDropDown, botName ~= "" and botName or MultiBot.L("ui.pvp.bot_selector"))
        end
    end

    MBPVP_ApplyStateToUi(frame, botName)
end

local function MBPVP_InitBotDropDown(frame)
        if not frame or not frame._botDropDown then
        return
    end

    if frame._botDropDown.type == "Dropdown" then
        local dropdown = frame._botDropDown

        if not dropdown._mbInit then
            dropdown._mbInit = true
            dropdown:SetLabel(MultiBot.L("ui.pvp.bot_selector"))
            dropdown:SetCallback("OnValueChanged", function(_, _, value)
                MBPVP_SetCurrentBot(frame, value)
                if not frame:IsShown() then
                    frame:Show()
                end
            end)
        end

        local bots = MBPVP_GetSortedBotList(frame)
        local list = {}
        for _, name in ipairs(bots) do
            list[name] = name
        end
        dropdown:SetList(list)

        if frame._currentBot and frame._currentBot ~= "" and list[frame._currentBot] then
            dropdown:SetValue(frame._currentBot)
            dropdown:SetText(frame._currentBot)
        else
            dropdown:SetValue(nil)
            dropdown:SetText(MultiBot.L("ui.pvp.bot_selector"))
        end

        return
    end

    if frame._botDropDown._mbInit then
        return
    end

    frame._botDropDown._mbInit = true

    UIDropDownMenu_Initialize(frame._botDropDown, function(self, level)
        local bots = MBPVP_GetSortedBotList(frame)
        for _, name in ipairs(bots) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = function()
                MBPVP_SetCurrentBot(frame, name)
                if not frame:IsShown() then
                    frame:Show()
                end
            end
            info.checked = (frame._currentBot == name)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(frame._botDropDown, MultiBot.L("ui.pvp.bot_selector"))
end

local function MBPVP_IsNoTeamMessage(msg)
    if type(msg) ~= "string" then
        return false
    end

    local lower = msg:lower()

    -- EN + locales DB (text_loc1..8) de ton extract
    if lower:find("i have no arena team", 1, true) or lower:find("no arena team", 1, true) then
        return true
    end
    if msg:find("투기장 팀이 없습니다", 1, true) then return true end
    if msg:find("Je n'ai aucune équipe d'arène", 1, true) then return true end
    if msg:find("Ich habe kein Arenateam", 1, true) then return true end
    if msg:find("我没有竞技场战队", 1, true) then return true end
    if msg:find("我沒有競技場隊伍", 1, true) then return true end
    if msg:find("No tengo equipo de arena", 1, true) then return true end
    if msg:find("У меня нет команды арены", 1, true) then return true end

    return false
end

-- Frame init is lifecycle-safe and idempotent.
local function EnsurePvpUiInitialized()
    if not MultiBotPVPFrame then
        MultiBotPVPFrame = CreateStyledFrame()
    end

    MBPVP_EnsureCache(MultiBotPVPFrame)
    MBPVP_InitBotDropDown(MultiBotPVPFrame)
end

local function ResetPvpUi(frame)
    if not frame then return end

    if frame._honorTotal then
        frame._honorTotal:SetText("-")
    end
    if frame._arena and frame._arena.pointsValue then
        frame._arena.pointsValue:SetText("-")
    end

    if frame._arenaRows then
        for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
            local row = frame._arenaRows[mode]
            if row then
                row.mode:SetText(MultiBot.L("tips.every.pvparenamode") .. mode)
                row.team:SetText(MultiBot.L("tips.every.pvparenanoteam"))
                row.rating:SetText(MultiBot.L("tips.every.pvparenanoteamrank"))
            end
        end
    end
end

function MultiBot.ApplyBridgePvpStats(stats)
    if type(stats) ~= "table" or not stats.name or stats.name == "" then
        return false
    end

    EnsurePvpUiInitialized()

    local botName = MBPVP_NormalizeSenderName(stats.name)
    if botName == "" then
        return false
    end

    local frame = MultiBotPVPFrame
    local st = MBPVP_GetState(frame, botName)

    st.lastUpdate = time()
    st.arenaPoints = tostring(stats.arenaPoints or 0)
    st.honorPoints = tostring(stats.honorPoints or 0)
    st.teams = st.teams or {}

    for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
        local incoming = stats.teams and stats.teams[mode] or nil
        st.teams[mode] = st.teams[mode] or {}

        local teamName = MBPVP_Trim(incoming and incoming.team or "")
        local rating = tonumber(incoming and incoming.rating or 0) or 0

        if teamName ~= "" then
            st.teams[mode].team = teamName
            st.teams[mode].rating = tostring(rating)
            st.teams[mode].noTeam = false
        else
            st.teams[mode].team = nil
            st.teams[mode].rating = nil
            st.teams[mode].noTeam = true
        end
    end

    if not frame:IsShown() then
        frame:Show()
    end

    MBPVP_InitBotDropDown(frame)

    if not frame._currentBot or frame._currentBot == "" then
        MBPVP_SetCurrentBot(frame, botName)
    elseif frame._currentBot == botName then
        MBPVP_ApplyStateToUi(frame, botName)
    end

    return true
end

function MultiBot.HandlePvpWhisper(msg, sender)
    if type(msg) ~= "string" then return end

    -- Only process PvP answers from playerbots module.
    if not msg:find("%[PVP%]") then
        return
    end

    EnsurePvpUiInitialized()

    local simpleName = MBPVP_NormalizeSenderName(sender)

    -- Reset display when switching sender to avoid mixed data.
    if MultiBotPVPFrame._currentSender ~= simpleName then
        MultiBotPVPFrame._currentSender = simpleName
        ResetPvpUi(MultiBotPVPFrame)
    end

    -- Open frame as soon as a bot replies.
    if not MultiBotPVPFrame:IsShown() then
        MultiBotPVPFrame:Show()
    end

    MBPVP_InitBotDropDown(MultiBotPVPFrame)

    local botName = MBPVP_NormalizeSenderName(sender)
    if botName == "" then
        return
    end

    local st = MBPVP_GetState(MultiBotPVPFrame, botName)
    st.lastUpdate = time()

    -- 1) Currency line: always has a "|" and two numbers in order.
    if msg:find("|", 1, true) then
        local arenaPoints, honorPoints = MBPVP_ExtractFirstTwoNumbers(msg)
        if arenaPoints then st.arenaPoints = arenaPoints end
        if honorPoints then st.honorPoints = honorPoints end
    else
        local bracket = msg:match("([235]v[235])")

        -- 2) Global "no arena team" message (EN + localized DB).
        if MBPVP_IsNoTeamMessage(msg) then
            for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
                st.teams[mode] = st.teams[mode] or {}
                st.teams[mode].team = nil
                st.teams[mode].rating = nil
            end
        -- 3) Per-bracket line: "[PVP] 5v5 : <TeamName> (localizedWord 1047)"
        elseif bracket then
            st.teams[bracket] = st.teams[bracket] or {}

            local team = msg:match("<([^>]+)>")
            local rating = MBPVP_ExtractTeamRating(msg)

            if team then
                st.teams[bracket].team = team
                st.teams[bracket].rating = rating
            else
                -- Bracket present but no team name: reset this bracket.
                st.teams[bracket].team = nil
                st.teams[bracket].rating = nil
            end
        end
    end

    if not MultiBotPVPFrame:IsShown() then
        MultiBotPVPFrame:Show()
    end

    -- Auto-select behavior:
    -- - if no current selection, select the replying bot
    -- - otherwise do not overwrite current display unless it is the same bot
    if not MultiBotPVPFrame._currentBot or MultiBotPVPFrame._currentBot == "" then
        MBPVP_SetCurrentBot(MultiBotPVPFrame, botName)
    elseif MultiBotPVPFrame._currentBot == botName then
        MBPVP_ApplyStateToUi(MultiBotPVPFrame, botName)
    end
end

EnsurePvpUiInitialized()

-- Expose helper to recreate if needed
_G.MultiBotPVP_Ensure = CreateStyledFrame
