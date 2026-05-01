if not MultiBot then return end

local RTI_ATTACK_ICONS = {
    { key = "star",     id = 1, label = "Star",     labelKey = "rti.icon.star"     },
    { key = "circle",   id = 2, label = "Circle",   labelKey = "rti.icon.circle"   },
    { key = "diamond",  id = 3, label = "Diamond",  labelKey = "rti.icon.diamond"  },
    { key = "triangle", id = 4, label = "Triangle", labelKey = "rti.icon.triangle" },
    { key = "moon",     id = 5, label = "Moon",     labelKey = "rti.icon.moon"     },
    { key = "square",   id = 6, label = "Square",   labelKey = "rti.icon.square"   },
    { key = "cross",    id = 7, label = "Cross",    labelKey = "rti.icon.cross"    },
    { key = "skull",    id = 8, label = "Skull",    labelKey = "rti.icon.skull"    },
}

local function raidIconTexture(iconId)
    return "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_" .. tostring(iconId)
end

local function rtiSelectorTexture()
    return "Interface\\Icons\\Achievement_PVP_P_01"
end

local function showRTIMessage(message, r, g, b)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(message, r or 1, g or 0.82, b or 0, 1)
        return
    end

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

local function hasStoredBotRTISelections()
    for _, icon in pairs(MultiBot.RTIBotSelections or {}) do
        if icon and icon.key then
            return true
        end
    end

    return false
end

local function updateBotRTIActionButton()
    local button = MultiBot.RTIBotActionButton
    if not button then
        return
    end

    if hasStoredBotRTISelections() then
        button.doShow()
    else
        button.doHide()

        if MultiBot.RTIBotActionFrame then
            MultiBot.RTIBotActionFrame:Hide()
        end
    end
end

local function runRTI(scope, target, command)
    local comm = MultiBot.Comm

    if comm and comm.RunRtiCommand and comm.RunRtiCommand(scope, target or "", command) then
        return true
    end

    showRTIMessage(MultiBot.L("rti.bridge.required", "RTI commands require the MultiBot bridge."), 1, 0.2, 0.2)
    return false
end

local function makeTip(title, body)
    return title .. "\n" .. body
end

local function localized(key, fallback, ...)
    local text = MultiBot.L(key, fallback)
    if select("#", ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

local function localizedTip(titleKey, titleFallback, bodyKey, bodyFallback, ...)
    return makeTip(localized(titleKey, titleFallback, ...), localized(bodyKey, bodyFallback, ...))
end

local function iconLabel(icon)
    if not icon then
        return ""
    end
    return localized(icon.labelKey or "", icon.label or icon.key or "")
end

local function makeState()
    return {
        selectedAll = false,
        selectedGroups = {},
        selectedIcons = {},
        scopeButtons = {},
        menus = {},
    }
end

local function scopeKey(scope, target)
    return tostring(scope or "ALL") .. ":" .. tostring(target or "")
end

local function setButtonAmount(button, amount)
    if button and button.setAmount then
        button.setAmount(amount or "")
    end
end

local function setButtonTexture(button, texture)
    if not button or not texture then
        return
    end

    if button.SetNormalTexture then
        button:SetNormalTexture("")
    end

    local safe = texture
    if MultiBot.SafeTexturePath then
        safe = MultiBot.SafeTexturePath(texture)
    end

    if button.icon and button.icon.SetTexture then
        button.icon:SetTexture(safe)

        if button.icon.SetAllPoints then
            button.icon:SetAllPoints(button)
        end

        if button.icon.Show then
            button.icon:Show()
        end

        button.texture = safe
        return
    end

    if button.setTexture then
        button.setTexture(safe)
        return
    end

    button.texture = safe
end

local function rememberBotRTISelection(botName, button, icon)
    if not botName or botName == "" or not button or not icon or not icon.key or not icon.id then
        return
    end

    MultiBot.RTIBotSelections = MultiBot.RTIBotSelections or {}
    MultiBot.RTIBotSelections[botName] = {
        key = icon.key,
        id = icon.id,
        label = icon.label,
    }

    button._mbRtiSelectedIcon = MultiBot.RTIBotSelections[botName]
    setButtonTexture(button, raidIconTexture(icon.id))
end

local function clearBotRTISelection(botName, button, defaultTexture)
    if botName and botName ~= "" and MultiBot.RTIBotSelections then
        MultiBot.RTIBotSelections[botName] = nil
    end

    if button then
        button._mbRtiSelectedIcon = nil
        setButtonTexture(button, defaultTexture or rtiSelectorTexture())
    end
end

local function restoreBotRTISelection(botName, button, defaultTexture)
    local icon = botName and MultiBot.RTIBotSelections and MultiBot.RTIBotSelections[botName]

    if icon and icon.id and button then
        button._mbRtiSelectedIcon = icon
        setButtonTexture(button, raidIconTexture(icon.id))
        return
    end

    clearBotRTISelection(botName, button, defaultTexture)
end

local function hideDropdownMenu(menu, restoreCollapsedBars)
    if not menu or not menu.Hide then
        return
    end

    if restoreCollapsedBars and menu.IsShown and menu:IsShown() and MultiBot.ShowHideSwitch then
        MultiBot.ShowHideSwitch(menu)
        return
    end

    menu:Hide()
    if MultiBot.RequestClickBlockerUpdate then
        MultiBot.RequestClickBlockerUpdate(menu)
    end
end

local function hideAllMenus(state, restoreCollapsedBars)
    for _, menu in pairs(state.menus) do
        hideDropdownMenu(menu, restoreCollapsedBars)
    end
end

local function toggleMenu(state, menu)
    if not menu then
        return
    end

    local shown = menu:IsShown()
    hideAllMenus(state, true)

    if shown then
        return
    end

    if MultiBot.ShowHideSwitch then
        MultiBot.ShowHideSwitch(menu)
    else
        menu:Show()
        if MultiBot.RequestClickBlockerUpdate then
            MultiBot.RequestClickBlockerUpdate(menu)
        end
    end
end

local function updateScopeButtonVisual(state, scope, target, icon)
    local key = scopeKey(scope, target)
    local button = state.scopeButtons[key]

    if not button or not icon then
        return
    end

    setButtonTexture(button, raidIconTexture(icon.id))

    if scope == "ALL" then
        setButtonAmount(button, "A")
    elseif scope == "GROUP" then
        setButtonAmount(button, tostring(target or ""))
    end
end

local function resetScopeButtonVisual(state, scope, target, texture, amount)
    local key = scopeKey(scope, target)
    local button = state.scopeButtons[key]

    if not button then
        return
    end

    setButtonTexture(button, texture)
    setButtonAmount(button, amount)
end

local function clearScopeSelection(state, scope, target)
    local key = scopeKey(scope, target)

    state.selectedIcons[key] = nil

    if scope == "ALL" then
        state.selectedAll = false
    elseif scope == "GROUP" then
        state.selectedGroups[tostring(target or "")] = nil
    end
end

local function addDropdownIcon(menuFrame, state, scope, target, icon, x, y)
    local button = menuFrame.addButton(
        "RTIIcon" .. tostring(scope) .. tostring(target or "") .. icon.label,
        x,
        y,
        raidIconTexture(icon.id),
        localizedTip(
            "tips.rti.icon.title",
            "RTI attack icon: %s",
            "tips.rti.icon.body",
            "Assigns this RTI icon.",
            iconLabel(icon)
        )
    )

    button.doLeft = function()
        local key = scopeKey(scope, target)
        state.selectedIcons[key] = icon

        if scope == "ALL" then
            state.selectedAll = true
            state.selectedGroups = {}
        elseif scope == "GROUP" then
            state.selectedAll = false
            state.selectedGroups[tostring(target or "")] = true
        end

        updateScopeButtonVisual(state, scope, target, icon)
        hideDropdownMenu(menuFrame, true)
    end

    return button
end

local function addDropdownReset(menuFrame, state, scope, target, defaultTexture, defaultAmount, x, y)
    local button = menuFrame.addButton(
        "RTIReset" .. tostring(scope) .. tostring(target or ""),
        x,
        y,
        defaultTexture,
        localizedTip(
            "tips.rti.default.title",
            "Default",
            "tips.rti.default.body.scope",
            "Clear the stored RTI icon for this scope."
        )
    )

    setButtonAmount(button, defaultAmount)

    button.doLeft = function()
        clearScopeSelection(state, scope, target)
        resetScopeButtonVisual(state, scope, target, defaultTexture, defaultAmount)
        hideDropdownMenu(menuFrame, true)
    end

    return button
end

local function addScopeDropdown(parentFrame, state, scope, target, buttonX, buttonY, defaultTexture, defaultAmount)
    local key = scopeKey(scope, target)

    local menuFrame = parentFrame.addFrame(
        "RTIDropdown" .. tostring(scope) .. tostring(target or ""),
        buttonX,
        buttonY - 274,
        24,
        30,
        274
    )

    menuFrame:Hide()
    menuFrame._mbDropdownManaged = true
    state.menus[key] = menuFrame

    for index, icon in ipairs(RTI_ATTACK_ICONS) do
        addDropdownIcon(menuFrame, state, scope, target, icon, 0, (index - 1) * 30)
    end

    addDropdownReset(menuFrame, state, scope, target, defaultTexture, defaultAmount, 0, 240)

    return menuFrame
end

local function addScopeButton(parentFrame, state, scope, target, x, y, texture, tip, amount)
    local key = scopeKey(scope, target)

    local button = parentFrame.addButton(
        "RTIScope" .. tostring(scope) .. tostring(target or ""),
        x,
        y,
        texture,
        tip
    )

    setButtonAmount(button, amount)
    state.scopeButtons[key] = button

    local menu = addScopeDropdown(parentFrame, state, scope, target, x, y, texture, amount)

    button.doLeft = function()
        toggleMenu(state, menu)
    end

    return button
end

local function hasSelectedGroups(state)
    for groupIndex = 1, 8 do
        if state.selectedGroups[tostring(groupIndex)] then
            return true
        end
    end

    return false
end

local function runScopeWithStoredIcon(state, scope, target, command)
    local key = scopeKey(scope, target)
    local icon = state.selectedIcons[key]

    if icon then
        if not runRTI(scope, target, "rti " .. icon.key) then
            return false
        end
    end

    return runRTI(scope, target, command)
end

local function runSelectedScopes(state, command)
    local sent = false

    if hasSelectedGroups(state) then
        for groupIndex = 1, 8 do
            local groupKey = tostring(groupIndex)

            if state.selectedGroups[groupKey] then
                if runScopeWithStoredIcon(state, "GROUP", groupKey, command) then
                    sent = true
                end
            end
        end

        return sent
    end

    if runScopeWithStoredIcon(state, "ALL", "", command) then
        return true
    end

    return false
end

function MultiBot.RunRTIAttackTarget(scope, target)
    return runRTI(scope or "ALL", target or "", "attack rti target")
end

function MultiBot.RunRTIPullTarget(scope, target)
    return runRTI(scope or "ALL", target or "", "pull rti target")
end

function MultiBot.AssignRTIAttackIcon(scope, target, icon)
    return runRTI(scope or "ALL", target or "", "rti " .. tostring(icon or ""))
end

function MultiBot.AssignRTICCIcon(scope, target, icon)
    return runRTI(scope or "ALL", target or "", "rti cc " .. tostring(icon or ""))
end

function MultiBot.UpdateBotRTIActionButton()
    updateBotRTIActionButton()
end

function MultiBot.RunStoredBotRTISelections(command)
    command = tostring(command or "")

    if command ~= "attack rti target" and command ~= "pull rti target" then
        return false
    end

    local sent = 0

    for botName, icon in pairs(MultiBot.RTIBotSelections or {}) do
        if botName and botName ~= "" and icon and icon.key then
            if runRTI("BOT", botName, "rti " .. icon.key) then
                runRTI("BOT", botName, command)
                sent = sent + 1
            end
        end
    end

    if sent <= 0 then
        showRTIMessage(MultiBot.L("info.rti.no_bot_selection", "No bot-specific RTI icon selected."), 1, 0.2, 0.2)
        updateBotRTIActionButton()
        return false
    end

    return true
end

function MultiBot.BuildBotRTIActionUI(tLeft, x, y)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    local buttonX = x or -306
    local buttonY = y or 0

    local button = tLeft.addButton(
        "BotRTI",
        buttonX,
        buttonY,
        "achievement_pvp_p_01",
        localizedTip(
            "tips.rti.bot.action.title",
            "Bot RTI attack/pull",
            "tips.rti.bot.action.body",
            "Orders all bots with a stored personal RTI icon to attack or pull their RTI target."
        )
    ).doHide()

    local frame = tLeft.addFrame("BotRTIAction", buttonX - 4, buttonY + 34, 24, 30, 64)
    frame._mbDropdownManaged = true
    frame:Hide()

    frame.addButton(
        "Attack",
        0,
        0,
        "ability_warrior_offensivestance",
        localizedTip(
            "tips.rti.bot.action.attack.title",
            "Attack",
            "tips.rti.bot.action.attack.body",
            "All bots with a stored personal RTI icon attack their RTI target."
        )
    ).doLeft = function()
        MultiBot.RunStoredBotRTISelections("attack rti target")
    end

    frame.addButton(
        "Pull",
        0,
        30,
        "ability_hunter_markedfordeath",
        localizedTip(
            "tips.rti.bot.action.pull.title",
            "Pull",
            "tips.rti.bot.action.pull.body",
            "All bots with a stored personal RTI icon pull their RTI target."
        )
    ).doLeft = function()
        MultiBot.RunStoredBotRTISelections("pull rti target")
    end

    button.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames["BotRTIAction"])
    end

    button.doRight = button.doLeft

    MultiBot.RTIBotActionButton = button
    MultiBot.RTIBotActionFrame = frame
    updateBotRTIActionButton()

    return {
        mainButton = button,
        frame = frame,
    }
end

function MultiBot.BuildRTIControlUI(controlFrame)
    if not controlFrame or not controlFrame.addButton or not controlFrame.addFrame then
        return nil
    end

    local mainButton = controlFrame.addButton(
        "RTI",
        0,
        150,
        "Spell_ChargePositive",
        MultiBot.L("tips.units.rti", "RTI / Pull control")
    )

    local rtiFrame = controlFrame.addFrame("RTIControl", 0, 152, 24, 336, 64)
    rtiFrame:Hide()
    rtiFrame._mbSkipAutoCollapse = true

    local state = makeState()

    addScopeButton(
        rtiFrame,
        state,
        "ALL",
        "",
        -30,
        0,
        "achievement_bg_winsoa",
        localizedTip(
            "tips.rti.all.title",
            "All bots",
            "tips.rti.all.body",
            "Click to choose an RTI icon for all bots."
        ),
        "A"
    )

    for groupIndex = 1, 8 do
        local groupKey = tostring(groupIndex)

        addScopeButton(
            rtiFrame,
            state,
            "GROUP",
            groupKey,
            groupIndex * 30,
            0,
            "achievement_pvp_p_01",
            localizedTip(
                "tips.rti.group.title",
                "Raid group %s",
                "tips.rti.group.body",
                "Click to choose an RTI icon for raid group %s.",
                groupKey
            ),
            groupKey
        )
    end

    local attackButton = rtiFrame.addButton(
        "AttackSelectedRTITargets",
        270,
        0,
        "ability_warrior_offensivestance",
        localizedTip(
            "tips.rti.attack.target.title",
            "Attack RTI target",
            "tips.rti.attack.target.body",
            "Orders configured groups, or all bots if no group is selected, to attack their RTI target."
        )
    )
    attackButton.doLeft = function()
        runSelectedScopes(state, "attack rti target")
    end

    local pullButton = rtiFrame.addButton(
        "PullSelectedRTITargets",
        300,
        0,
        "ability_hunter_markedfordeath",
        localizedTip(
            "tips.rti.pull.target.title",
            "Pull RTI target",
            "tips.rti.pull.target.body",
            "Orders configured groups, or all bots if no group is selected, to pull their RTI target."
        )
    )
    pullButton.doLeft = function()
        runSelectedScopes(state, "pull rti target")
    end

    mainButton.doLeft = function()
        MultiBot.ShowHideSwitch(rtiFrame)
    end

    return {
        rootButton = mainButton,
        frame = rtiFrame,
    }
end

function MultiBot.BuildBotRTIUI(parentFrame, botName, x, y)
    if not parentFrame or not parentFrame.addButton or not parentFrame.addFrame or not botName or botName == "" then
        return nil
    end

    local buttonX = x or 394
    local buttonY = y or 0
    local defaultTexture = rtiSelectorTexture()

    MultiBot.RTIBotSelections = MultiBot.RTIBotSelections or {}

    local rootButton = parentFrame.addButton(
        "RTI",
        buttonX,
        buttonY,
        defaultTexture,
        localizedTip(
            "tips.rti.bot.button.title",
            "RTI",
            "tips.rti.bot.button.body",
            "Click to choose the RTI icon assigned to %s.",
            botName
        )
    )

    local menuFrame = parentFrame.addFrame("RTIMenu", buttonX, buttonY - 274, 24, 30, 274)
    menuFrame:Hide()
    menuFrame._mbDropdownManaged = true

    restoreBotRTISelection(botName, rootButton, defaultTexture)

    for index, icon in ipairs(RTI_ATTACK_ICONS) do
        local button = menuFrame.addButton(
            "AttackBOT" .. botName .. icon.label,
            0,
            (index - 1) * 30,
            raidIconTexture(icon.id),
            makeTip(
                localized("tips.rti.bot.icon.title", "RTI: %s", iconLabel(icon)),
                localized("tips.rti.bot.icon.body", "Stores this RTI icon for %s.", botName)
            )
        )

        button.doLeft = function()
            rememberBotRTISelection(botName, rootButton, icon)
            updateBotRTIActionButton()
            hideDropdownMenu(menuFrame, true)
        end
    end

    local resetButton = menuFrame.addButton(
        "ResetBOT" .. botName,
        0,
        240,
        defaultTexture,
        localizedTip(
            "tips.rti.default.title",
            "Default",
            "tips.rti.bot.default.body",
            "Clear the stored RTI icon for %s.",
            botName
        )
    )

    resetButton.doLeft = function()
        clearBotRTISelection(botName, rootButton, defaultTexture)
        updateBotRTIActionButton()
        hideDropdownMenu(menuFrame, true)
    end

    rootButton.doLeft = function()
        if MultiBot.ShowHideSwitch then
            MultiBot.ShowHideSwitch(menuFrame)
        elseif menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end

    return {
        rootButton = rootButton,
        frame = menuFrame,
    }
end