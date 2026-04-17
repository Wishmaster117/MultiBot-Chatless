if not MultiBot then return end

local MAIN_FRAME_NAME = "Main"
local MAIN_BUTTON_NAME = "Main"
local MAIN_BUTTON_ICON = "inv_gizmo_02"
local MAIN_FRAME_X = -2
local MAIN_FRAME_Y = 38
local MULTIBAR_LAYOUT_KEY = "MultiBarPoint"
local MAINBAR_BUTTON_ORDER_LAYOUT_KEY = "MainBarButtonsOrder"
local MAINBAR_BUTTON_STEP_Y = 34
local LEFT_LAYOUT_SHIFT = 34
local MAINBAR_AUTOHIDE_HOTSPOT_SIZE = 42
local MAINBAR_AUTOHIDE_UPDATE_INTERVAL = 0.2

local LEFT_LAYOUT_NAMES = {
    "Tanker",
    "Attack",
    "Mode",
    "Stay",
    "Follow",
    "ExpandStay",
    "ExpandFollow",
    "Flee",
    "Format",
    "Beast",
}

local leftLayoutBase = nil

local function withLeftRoot(callback)
    local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local leftRoot = multibar and multibar.frames and multibar.frames["Left"]
    if not leftRoot then
        return
    end

    callback(leftRoot, multibar)
end

local function getMainToggleState(name)
    local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local mainFrame = multibar and multibar.frames and multibar.frames["Main"]
    local button = mainFrame and mainFrame.buttons and mainFrame.buttons[name]
    return button and button.state == true
end

local function captureLeftLayoutBase(leftRoot)
    if leftLayoutBase then
        return
    end

    leftLayoutBase = {
        buttons = {},
        frames = {},
    }

    for _, name in ipairs(LEFT_LAYOUT_NAMES) do
        local button = leftRoot.buttons and leftRoot.buttons[name]
        if button then
            leftLayoutBase.buttons[name] = { x = button.x, y = button.y }
        end

        local frame = leftRoot.frames and leftRoot.frames[name]
        if frame then
            leftLayoutBase.frames[name] = { x = frame.x, y = frame.y }
        end
    end
end

local function setLeftElementX(leftRoot, name, x)
    local button = leftRoot.buttons and leftRoot.buttons[name]
    if button then
        button.setPoint(x, button.y)
    end

    local frame = leftRoot.frames and leftRoot.frames[name]
    if frame then
        local baseButton = leftLayoutBase and leftLayoutBase.buttons and leftLayoutBase.buttons[name]
        local baseFrame = leftLayoutBase and leftLayoutBase.frames and leftLayoutBase.frames[name]
        local frameOffset = -2
        if baseButton and baseFrame then
            frameOffset = baseFrame.x - baseButton.x
        end
        frame.setPoint(x + frameOffset, frame.y)
    end
end

local function getLeftBaseX(leftRoot, name)
    local baseButton = leftLayoutBase and leftLayoutBase.buttons and leftLayoutBase.buttons[name]
    if baseButton then
        return baseButton.x
    end

    local button = leftRoot.buttons and leftRoot.buttons[name]
    if button then
        return button.x
    end

    return 0
end

local function refreshLeftLayout()
    withLeftRoot(function(leftRoot)
        captureLeftLayoutBase(leftRoot)

        if not leftLayoutBase then
            return
        end

        local creatorEnabled = getMainToggleState("Creator")
        local beastEnabled = getMainToggleState("Beast")
        local expandEnabled = getMainToggleState("Expand")

        local commonShift = 0
        if creatorEnabled then
            commonShift = commonShift - LEFT_LAYOUT_SHIFT
        end
        if beastEnabled then
            commonShift = commonShift - LEFT_LAYOUT_SHIFT
        end

        local heavyShift = commonShift
        if expandEnabled then
            heavyShift = heavyShift - LEFT_LAYOUT_SHIFT
        end

        setLeftElementX(leftRoot, "Tanker", getLeftBaseX(leftRoot, "Tanker") + heavyShift)
        setLeftElementX(leftRoot, "Attack", getLeftBaseX(leftRoot, "Attack") + heavyShift)
        setLeftElementX(leftRoot, "Mode", getLeftBaseX(leftRoot, "Mode") + heavyShift)

        setLeftElementX(leftRoot, "Stay", getLeftBaseX(leftRoot, "Stay") + commonShift)
        setLeftElementX(leftRoot, "Follow", getLeftBaseX(leftRoot, "Follow") + commonShift)
        setLeftElementX(leftRoot, "ExpandStay", getLeftBaseX(leftRoot, "ExpandStay") + commonShift)
        setLeftElementX(leftRoot, "ExpandFollow", getLeftBaseX(leftRoot, "ExpandFollow") + commonShift)
        setLeftElementX(leftRoot, "Flee", getLeftBaseX(leftRoot, "Flee") + commonShift)
        setLeftElementX(leftRoot, "Format", getLeftBaseX(leftRoot, "Format") + commonShift)

        setLeftElementX(leftRoot, "Beast", getLeftBaseX(leftRoot, "Beast") + (creatorEnabled and -LEFT_LAYOUT_SHIFT or 0))

        if expandEnabled then
            leftRoot.buttons["ExpandFollow"]:Show()
            leftRoot.buttons["ExpandStay"]:Show()
            leftRoot.buttons["Follow"]:Hide()
            leftRoot.buttons["Stay"]:Hide()
        else
            leftRoot.buttons["ExpandFollow"]:Hide()
            leftRoot.buttons["ExpandStay"]:Hide()

            local followButton = leftRoot.buttons["Follow"]
            local stayButton = leftRoot.buttons["Stay"]
            local followShown = followButton and followButton:IsShown()
            local stayShown = stayButton and stayButton:IsShown()

            -- Garder Follow/Stay mutuellement exclusifs en layout collapsed.
            -- On préserve l'état courant; en cas d'état ambigu, on retombe sur Stay visible.
            if followShown and not stayShown then
                followButton:Show()
                stayButton:Hide()
            else
                stayButton:Show()
                followButton:Hide()
            end
        end
    end)
end

local function resetDefaultWindowPositions()
    MultiBot.frames["MultiBar"].setPoint(-303, 144)
    MultiBot.inventory.setPoint(-700, -144)
    MultiBot.spellbook.setPoint(-802, 302)
    MultiBot.talent.setPoint(-104, -276)
    MultiBot.reward.setPoint(-754, 238)
    MultiBot.itemus.setPoint(-860, -144)
    MultiBot.iconos.setPoint(-860, -144)
    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if statsFrame and statsFrame.setPoint then
        statsFrame.setPoint(-60, 560)
    end
end

local function toggleMasters(button)
    if MultiBot.GM == false then
        SendChatMessage(MultiBot.L("info.rights"), "SAY")
        return
    end

    if MultiBot.OnOffSwitch(button) then
        MultiBot.doRepos("Right", 38)
        MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
        MultiBot.frames["MultiBar"].buttons["Masters"]:Show()
        return
    end

    MultiBot.doRepos("Right", -38)
    MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
    MultiBot.frames["MultiBar"].buttons["Masters"]:Hide()
end

local function toggleRTSC(button)
    if MultiBot.OnOffSwitch(button) then
        MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y + 34)
        MultiBot.frames["MultiBar"].frames["RTSC"]:Show()
        MultiBot.ActionToGroup("rtsc")
        return
    end

    MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y - 34)
    MultiBot.frames["MultiBar"].frames["RTSC"]:Hide()
    MultiBot.ActionToGroup("rtsc reset")
end

local function toggleRaidus(button)
    if MultiBot.OnOffSwitch(button) then
        MultiBot.raidus.setRaidus()
        MultiBot.raidus:Show()
        return
    end

    MultiBot.raidus:Hide()
end

local function toggleCreator(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            leftRoot.frames["Creator"]:Hide()
            leftRoot.buttons["Creator"]:Show()
        else
            leftRoot.frames["Creator"]:Hide()
            leftRoot.buttons["Creator"]:Hide()
        end

        refreshLeftLayout()
    end)
end

local function toggleBeast(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            leftRoot.frames["Beast"]:Hide()
            leftRoot.buttons["Beast"]:Show()
        else
            leftRoot.frames["Beast"]:Hide()
            leftRoot.buttons["Beast"]:Hide()
        end

        refreshLeftLayout()
    end)
end

local function toggleExpand(button)
    MultiBot.OnOffSwitch(button)
    refreshLeftLayout()
end

local function toggleRelease(button)
    MultiBot.auto.release = MultiBot.OnOffSwitch(button) and true or false
end

local function toggleStats(button)
    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if not statsFrame then
        return
    end

    if GetNumRaidMembers() > 0 then
        SendChatMessage(MultiBot.L("info.stats"), "SAY")
        return
    end

    if MultiBot.OnOffSwitch(button) then
        MultiBot.auto.stats = true
        for index = 1, GetNumPartyMembers() do
            SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. index))
        end
        statsFrame:Show()
        return
    end

    MultiBot.auto.stats = false
    for _, value in pairs(statsFrame.frames) do
        value:Hide()
    end
    statsFrame:Hide()
end

local function createRewardButton(mainFrame)
    local rewardButton = mainFrame.addButton(
        "Reward",
        0,
        306,
        "Interface\\AddOns\\MultiBot\\Icons\\reward.blp",
        MultiBot.L("tips.main.reward")
    ):setDisable()

    rewardButton.doRight = function()
        MultiBot.rewardReopenIfAvailable()
    end

    rewardButton.doLeft = function(button)
        local wasSavedEnabled = MultiBot.GetSavedMainBarValue and MultiBot.GetSavedMainBarValue("Reward") == "true"
        local isEnabled = MultiBot.OnOffSwitch(button)

        MultiBot.rewardSetEnabled(isEnabled)

        if MultiBot.SetSavedMainBarValue then
            MultiBot.SetSavedMainBarValue("Reward", MultiBot.IF(isEnabled, "true", "false"))
        end

        if isEnabled and not wasSavedEnabled and MultiBot.rewardShowConfigPopup then
            MultiBot.rewardShowConfigPopup()
        end
    end

    return rewardButton
end

local function createMainActionButton(mainFrame, definition)
    local button = mainFrame.addButton(definition.name, 0, definition.y, definition.icon, MultiBot.L(definition.tip))

    if definition.disabled then
        button:setDisable()
    end

    button.doLeft = definition.doLeft

    if definition.doRight then
        button.doRight = definition.doRight
    end

    return button
end

local function saveMultiBarPosition()
    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    if not multiBar or not MultiBot.SetSavedLayoutValue or not MultiBot.toPoint then
        return
    end

    local offsetX, offsetY = MultiBot.toPoint(multiBar)
    multiBar.x = offsetX
    multiBar.y = offsetY
    MultiBot.SetSavedLayoutValue(MULTIBAR_LAYOUT_KEY, offsetX .. ", " .. offsetY)
    if MultiBot.RefreshMainBarAutoHideState then
        MultiBot.RefreshMainBarAutoHideState()
    end
end

local function isMouseOverFrameNode(node)
    if not node or (node.IsShown and not node:IsShown()) then
        return false
    end

    if node.IsMouseOver and node:IsMouseOver() then
        return true
    end

    local buttons = node.buttons
    if type(buttons) == "table" then
        for _, button in pairs(buttons) do
            if button and button.IsShown and button:IsShown() and button.IsMouseOver and button:IsMouseOver() then
                return true
            end
        end
    end

    local children = node.frames
    if type(children) == "table" then
        for _, child in pairs(children) do
            if isMouseOverFrameNode(child) then
                return true
            end
        end
    end

    return false
end

local syncMainBarDetectorPosition

local function hideMainBarForAutoHide(state)
    if state.hidden then
        return
    end

    local multiBar = state.multiBar
    if not multiBar then
        return
    end

    if syncMainBarDetectorPosition then
        syncMainBarDetectorPosition(state)
    end

    multiBar:Hide()
    state.hidden = true
    if state.detector then
        state.detector:Show()
    end
end

local function showMainBarFromAutoHide(state)
    local multiBar = state.multiBar
    if not multiBar then
        return
    end

    if state.hidden then
        multiBar:Show()
        state.hidden = false
    end

    if state.detector then
        state.detector:Hide()
    end
end

local function markMainBarInteraction(state)
    state.lastInteraction = GetTime()
    showMainBarFromAutoHide(state)
end

syncMainBarDetectorPosition = function(state)
    local detector = state and state.detector
    local multiBar = state and state.multiBar
    if not detector or not multiBar then
        return
    end

    detector:ClearAllPoints()
    detector:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", multiBar.x or 0, multiBar.y or 0)
    state.syncedX = multiBar.x or 0
    state.syncedY = multiBar.y or 0
end

local function splitCsv(value)
    if type(value) ~= "string" or value == "" then
        return {}
    end

    local result = {}
    for token in string.gmatch(value, "([^,]+)") do
        local trimmed = string.gsub(token, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then
            table.insert(result, trimmed)
        end
    end
    return result
end

local function findOrderIndex(order, name)
    for index, value in ipairs(order) do
        if value == name then
            return index
        end
    end
    return nil
end

local function buildResolvedOrder(defaultOrder, savedOrder)
    local resolved = {}
    local seen = {}

    for _, name in ipairs(savedOrder) do
        if findOrderIndex(defaultOrder, name) and not seen[name] then
            table.insert(resolved, name)
            seen[name] = true
        end
    end

    for _, name in ipairs(defaultOrder) do
        if not seen[name] then
            table.insert(resolved, name)
        end
    end

    return resolved
end

local function applyMainButtonOrder(mainFrame, order)
    if not mainFrame or not mainFrame.buttons then
        return
    end

    for index, name in ipairs(order) do
        local button = mainFrame.buttons[name]
        if button and button.setPoint then
            button.setPoint(0, (index - 1) * MAINBAR_BUTTON_STEP_Y)
        end
    end
end

local function saveMainButtonOrder(order)
    if not MultiBot.SetSavedLayoutValue then
        return
    end

    MultiBot.SetSavedLayoutValue(MAINBAR_BUTTON_ORDER_LAYOUT_KEY, table.concat(order, ","))
end

function MultiBot.InitializeMainUI(tMultiBar)
    if not tMultiBar or not tMultiBar.addButton or not tMultiBar.addFrame then
        return nil
    end

    local mainButton = tMultiBar.addButton(MAIN_BUTTON_NAME, 0, 0, MAIN_BUTTON_ICON, MultiBot.L("tips.main.master"))
    mainButton:RegisterForDrag("RightButton")
    local autoHideState = {
        multiBar = MultiBot.frames and MultiBot.frames["MultiBar"],
        hidden = false,
        enabled = false,
        delay = 60,
        elapsed = 0,
        lastInteraction = GetTime(),
        syncedX = nil,
        syncedY = nil,
    }

    local detector = CreateFrame("Frame", "MultiBotMainBarAutoHideDetector", UIParent)
    detector:SetFrameStrata("TOOLTIP")
    detector:SetSize(MAINBAR_AUTOHIDE_HOTSPOT_SIZE, MAINBAR_AUTOHIDE_HOTSPOT_SIZE)
    detector:EnableMouse(true)
    detector:Hide()
    autoHideState.detector = detector

    -- Resync hotspot on every programmatic bar move (layout restore, RTSC restore, reset coords, etc.).
    if autoHideState.multiBar
        and type(autoHideState.multiBar.setPoint) == "function"
        and not autoHideState.multiBar.__mbAutoHideSetPointHooked
    then
        local originalSetPoint = autoHideState.multiBar.setPoint
        autoHideState.multiBar.setPoint = function(...)
            originalSetPoint(...)
            syncMainBarDetectorPosition(autoHideState)
            markMainBarInteraction(autoHideState)
        end
        autoHideState.multiBar.__mbAutoHideSetPointHooked = true
    end

    -- If hidden/shown by external paths, keep detector aligned.
    if autoHideState.multiBar
        and autoHideState.multiBar.HookScript
        and not autoHideState.multiBar.__mbAutoHideOnHideHooked
    then
        autoHideState.multiBar:HookScript("OnHide", function()
            syncMainBarDetectorPosition(autoHideState)
        end)
        autoHideState.multiBar.__mbAutoHideOnHideHooked = true
    end

    detector:SetScript("OnEnter", function()
        markMainBarInteraction(autoHideState)
    end)

    local function applyMoveLockState(moveLocked)
        local locked = moveLocked
        if locked == nil and MultiBot.GetMainBarMoveLocked then
            locked = MultiBot.GetMainBarMoveLocked()
        end
        if locked == nil then
            locked = true
        end
        mainButton.__mbMoveLocked = locked and true or false
    end

    MultiBot.ApplyMainBarMoveLockState = applyMoveLockState
    applyMoveLockState()

    mainButton:SetScript("OnDragStart", function()
        markMainBarInteraction(autoHideState)
        local moveLocked = mainButton.__mbMoveLocked
        if moveLocked and not IsControlKeyDown() then
            if UIErrorsFrame then
                UIErrorsFrame:AddMessage(MultiBot.L("mainbar.swap.locked"), 1, 0.25, 0.25, 1)
            end
            return
        end

        MultiBot.frames["MultiBar"]:StartMoving()
    end)
    mainButton:SetScript("OnDragStop", function()
        MultiBot.frames["MultiBar"]:StopMovingOrSizing()
        saveMultiBarPosition()
        syncMainBarDetectorPosition(autoHideState)
        markMainBarInteraction(autoHideState)
    end)
    mainButton.doLeft = function(button)
        markMainBarInteraction(autoHideState)
        MultiBot.ShowHideSwitch(button.parent.frames[MAIN_FRAME_NAME])
    end

    local mainFrame = tMultiBar.addFrame(MAIN_FRAME_NAME, MAIN_FRAME_X, MAIN_FRAME_Y)
    mainFrame:Hide()
    mainFrame:HookScript("OnShow", function()
        markMainBarInteraction(autoHideState)
    end)
    mainFrame:HookScript("OnHide", function()
        markMainBarInteraction(autoHideState)
    end)

    function MultiBot.MainBarAutoHide_NotifyInteraction()
        markMainBarInteraction(autoHideState)
    end

    function MultiBot.RefreshMainBarAutoHideState()
        autoHideState.enabled = MultiBot.GetMainBarAutoHideEnabled and MultiBot.GetMainBarAutoHideEnabled() or false
        autoHideState.delay = MultiBot.GetMainBarAutoHideDelay and MultiBot.GetMainBarAutoHideDelay() or 60
        syncMainBarDetectorPosition(autoHideState)
        if not autoHideState.enabled then
            showMainBarFromAutoHide(autoHideState)
            autoHideState.lastInteraction = GetTime()
        end
    end

    if autoHideState.multiBar and autoHideState.multiBar.HookScript then
        autoHideState.multiBar:HookScript("OnShow", function()
            if autoHideState.enabled and autoHideState.hidden then
                return
            end
            autoHideState.hidden = false
            if autoHideState.detector then
                autoHideState.detector:Hide()
            end
        end)
    end

    mainButton:HookScript("PostClick", function()
        markMainBarInteraction(autoHideState)
    end)

    if autoHideState.multiBar and autoHideState.multiBar.HookScript then
        -- M11 ownership: keep this OnUpdate local for autohide.
        -- Reason: hover/mouse interaction needs near real-time polling to preserve UX.
        autoHideState.multiBar:HookScript("OnUpdate", function(_, elapsed)
            autoHideState.elapsed = autoHideState.elapsed + elapsed
            if autoHideState.elapsed < MAINBAR_AUTOHIDE_UPDATE_INTERVAL then
                return
            end
            autoHideState.elapsed = 0

            local configuredEnabled = MultiBot.GetMainBarAutoHideEnabled and MultiBot.GetMainBarAutoHideEnabled() or false
            local configuredDelay = MultiBot.GetMainBarAutoHideDelay and MultiBot.GetMainBarAutoHideDelay() or autoHideState.delay
            if configuredEnabled ~= autoHideState.enabled then
                autoHideState.enabled = configuredEnabled and true or false
                autoHideState.delay = configuredDelay
                if autoHideState.enabled then
                    autoHideState.lastInteraction = GetTime()
                else
                    showMainBarFromAutoHide(autoHideState)
                    autoHideState.lastInteraction = GetTime()
                end
            else
                autoHideState.delay = configuredDelay
            end

            local currentX = autoHideState.multiBar.x or 0
            local currentY = autoHideState.multiBar.y or 0
            if currentX ~= autoHideState.syncedX or currentY ~= autoHideState.syncedY then
                syncMainBarDetectorPosition(autoHideState)
            end

            if not autoHideState.enabled or autoHideState.hidden then
                return
            end

            if isMouseOverFrameNode(autoHideState.multiBar) then
                autoHideState.lastInteraction = GetTime()
                return
            end

            if (GetTime() - autoHideState.lastInteraction) >= autoHideState.delay then
                hideMainBarForAutoHide(autoHideState)
            end
        end)
    end

    MultiBot.RefreshMainBarAutoHideState()

    local defaultMainButtonOrder = {
        "Coords",
        "Masters",
        "RTSC",
        "Raidus",
        "Creator",
        "Beast",
        "Expand",
        "Release",
        "Stats",
        "Reward",
        "Reset",
        "Actions",
    }
    local savedOrderValue = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(MAINBAR_BUTTON_ORDER_LAYOUT_KEY) or nil
    local currentMainButtonOrder = buildResolvedOrder(defaultMainButtonOrder, splitCsv(savedOrderValue))
    local selectedSwapButtonName = nil

    local function swapMainButtons(buttonName)
        if not buttonName then
            return
        end

        if not selectedSwapButtonName then
            selectedSwapButtonName = buttonName
            UIErrorsFrame:AddMessage(MultiBot.L("mainbar.swap.source_prefix") .. buttonName, 1, 0.82, 0, 1)
            return
        end

        if selectedSwapButtonName == buttonName then
            selectedSwapButtonName = nil
            UIErrorsFrame:AddMessage(MultiBot.L("mainbar.swap.cancelled"), 1, 0.25, 0.25, 1)
            return
        end

        local fromIndex = findOrderIndex(currentMainButtonOrder, selectedSwapButtonName)
        local toIndex = findOrderIndex(currentMainButtonOrder, buttonName)
        if not fromIndex or not toIndex then
            selectedSwapButtonName = nil
            return
        end

        currentMainButtonOrder[fromIndex], currentMainButtonOrder[toIndex] =
            currentMainButtonOrder[toIndex], currentMainButtonOrder[fromIndex]

        applyMainButtonOrder(mainFrame, currentMainButtonOrder)
        saveMainButtonOrder(currentMainButtonOrder)

        UIErrorsFrame:AddMessage(MultiBot.L("mainbar.swap.preview_prefix") .. selectedSwapButtonName .. " <-> " .. buttonName, 0.25, 1, 0.25, 1)
        selectedSwapButtonName = nil
    end

    local function wireShiftRightSwap(button, buttonName)
        if not button or not buttonName then
            return
        end

        local originalDoRight = button.doRight
        button.doRight = function(btn)
            if IsShiftKeyDown() then
                swapMainButtons(buttonName)
                return
            end

            if originalDoRight then
                originalDoRight(btn)
            end
        end
    end

    createMainActionButton(mainFrame, {
        name = "Coords",
        y = 0,
        icon = "inv_gizmo_03",
        tip = "tips.main.coords",
        doLeft = function()
            resetDefaultWindowPositions()
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Coords"], "Coords")

    createMainActionButton(mainFrame, {
        name = "Masters",
        y = 34,
        icon = "mail_gmicon",
        tip = "tips.main.masters",
        disabled = true,
        doLeft = function(button)
            toggleMasters(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Masters"], "Masters")

    createMainActionButton(mainFrame, {
        name = "RTSC",
        y = 68,
        icon = "ability_hunter_markedfordeath",
        tip = "tips.main.rtsc",
        disabled = true,
        doLeft = function(button)
            toggleRTSC(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["RTSC"], "RTSC")

    createMainActionButton(mainFrame, {
        name = "Raidus",
        y = 102,
        icon = "inv_misc_head_dragon_01",
        tip = "tips.main.raidus",
        disabled = true,
        doLeft = function(button)
            toggleRaidus(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Raidus"], "Raidus")

    createMainActionButton(mainFrame, {
        name = "Creator",
        y = 136,
        icon = "inv_helmet_145a",
        tip = "tips.main.creator",
        disabled = true,
        doLeft = function(button)
            toggleCreator(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Creator"], "Creator")

    createMainActionButton(mainFrame, {
        name = "Beast",
        y = 170,
        icon = "ability_mount_swiftredwindrider",
        tip = "tips.main.beast",
        disabled = true,
        doLeft = function(button)
            toggleBeast(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Beast"], "Beast")

    createMainActionButton(mainFrame, {
        name = "Expand",
        y = 204,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp",
        tip = "tips.main.expand",
        disabled = true,
        doLeft = function(button)
            toggleExpand(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Expand"], "Expand")

    createMainActionButton(mainFrame, {
        name = "Release",
        y = 238,
        icon = "achievement_bg_xkills_avgraveyard",
        tip = "tips.main.release",
        disabled = true,
        doLeft = function(button)
            toggleRelease(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Release"], "Release")

    createMainActionButton(mainFrame, {
        name = "Stats",
        y = 272,
        icon = "inv_scroll_08",
        tip = "tips.main.stats",
        disabled = true,
        doLeft = function(button)
            toggleStats(button)
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Stats"], "Stats")

    local rewardButton = createRewardButton(mainFrame)
    wireShiftRightSwap(rewardButton, "Reward")

    refreshLeftLayout()

    createMainActionButton(mainFrame, {
        name = "Reset",
        y = 340,
        icon = "inv_misc_tournaments_symbol_gnome",
        tip = "tips.main.reset",
        doLeft = function()
            MultiBot.ActionToTargetOrGroup("reset botAI")
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Reset"], "Reset")

    createMainActionButton(mainFrame, {
        name = "Actions",
        y = 374,
        icon = "inv_helmet_02",
        tip = "tips.main.action",
        doLeft = function()
            MultiBot.ActionToTargetOrGroup("reset")
        end,
    })
    wireShiftRightSwap(mainFrame.buttons["Actions"], "Actions")

    applyMainButtonOrder(mainFrame, currentMainButtonOrder)

    return {
        mainButton = mainButton,
        frame = mainFrame,
        rewardButton = rewardButton,
    }
end