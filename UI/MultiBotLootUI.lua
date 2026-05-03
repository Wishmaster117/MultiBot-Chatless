local function L(key, fallback)
    if MultiBot and MultiBot.L then
        return MultiBot.L(key, fallback)
    end

    return fallback or key
end

local LOOT_COMMANDS = {
    { key = "enable", command = "nc +loot", icon = "inv_misc_bag_08", tip = "tips.loot.enable", fallback = "Enable loot" },
    { key = "disable", command = "nc -loot", icon = "inv_misc_bag_07", tip = "tips.loot.disable", fallback = "Disable loot" },
    { key = "all", command = "ll all", icon = "inv_misc_bag_10", tip = "tips.loot.all", fallback = "Loot profile: All" },
    { key = "normal", command = "ll normal", icon = "inv_misc_bag_11", tip = "tips.loot.normal", fallback = "Loot profile: Normal" },
    { key = "gray", command = "ll gray", icon = "inv_misc_coin_01", tip = "tips.loot.gray", fallback = "Loot profile: Gray" },
    { key = "quest", command = "ll quest", icon = "inv_misc_note_05", tip = "tips.loot.quest", fallback = "Loot profile: Quest" },
    { key = "skill", command = "ll skill", icon = "inv_misc_book_07", tip = "tips.loot.skill", fallback = "Loot profile: Skill" },
}

local LOOT_PROFILE_KEYS = {
    all = true,
    normal = true,
    gray = true,
    quest = true,
    skill = true,
}

local lootVisualState = {
    enabled = nil,
    profile = nil,
}

local function NormalizeLootCommand(command)
    return string.lower((command or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function RunLootCommand(command)
    if not MultiBot or not MultiBot.Comm or not MultiBot.Comm.RunLootCommand then
        DEFAULT_CHAT_FRAME:AddMessage(L("loot.bridge.required", "Loot bridge is not connected."))
        return false
    end

    local ok = MultiBot.Comm.RunLootCommand("ALL", "", command)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage(L("loot.bridge.required", "Loot bridge is not connected."))
    end

    return ok
end

function MultiBot.BuildLootUI(tLeft)
    if not tLeft or MultiBot.frames.loot then
        return MultiBot.frames.loot
    end

    local button
    local menu = tLeft.addFrame("LootMenu", -73, 34, 24, 24, 170).doHide()
    local menuOpen = false
    local menuButtons = {}
    local menuButtonsByKey = {}
    menu._mbDropdownManaged = true
    menu:SetWidth(24)
    menu:SetHeight(170)

    local function updateClickBlocker()
        if MultiBot.RequestClickBlockerUpdate then
            MultiBot.RequestClickBlockerUpdate(menu)
        end
    end

    local function applyLootVisualState()
        for _, menuButton in pairs(menuButtonsByKey) do
            if menuButton and menuButton.setDisable then
                menuButton.setDisable()
            end
        end

        if lootVisualState.enabled == true and menuButtonsByKey.enable then
            menuButtonsByKey.enable.setEnable()
        elseif lootVisualState.enabled == false and menuButtonsByKey.disable then
            menuButtonsByKey.disable.setEnable()
        end

        if lootVisualState.profile and menuButtonsByKey[lootVisualState.profile] then
            menuButtonsByKey[lootVisualState.profile].setEnable()
        end
    end

    MultiBot.OnLootCommandApplied = function(command, executed)
        local applied = tonumber(executed) or 0
        if applied <= 0 then
            return
        end

        command = NormalizeLootCommand(command)

        if command == "nc +loot" then
            lootVisualState.enabled = true
        elseif command == "nc -loot" then
            lootVisualState.enabled = false
            lootVisualState.profile = nil
        else
            local profile = command:match("^ll%s+([%w_%-]+)$")
            if profile and LOOT_PROFILE_KEYS[profile] then
                lootVisualState.profile = profile
            end
        end

        applyLootVisualState()
    end

    local function setLootMenuChildrenShown(shown)
        for _, menuButton in ipairs(menuButtons) do
            if shown then
                menuButton:doShow()
            else
                menuButton:doHide()
            end
        end

        if button then
            if shown then
                button.setEnable()
            else
                button.setDisable()
            end
        end

        updateClickBlocker()
    end

    local function hideLootMenu()
        menuOpen = false
        menu:Hide()
        setLootMenuChildrenShown(false)
    end

    local function showLootMenu()
        menuOpen = true
        menu:Show()
        setLootMenuChildrenShown(true)
    end

    menu:HookScript("OnHide", function()
        menuOpen = false
        setLootMenuChildrenShown(false)
    end)

    for index, entry in ipairs(LOOT_COMMANDS) do
        local menuButton = menu.addButton("Loot" .. entry.key, 0, (index - 1) * 24, entry.icon, L(entry.tip, entry.fallback))
        menuButton.doLeft = function()
            RunLootCommand(entry.command)
        end

        menuButtons[index] = menuButton
        menuButtonsByKey[entry.key] = menuButton
    end
    applyLootVisualState()

    MultiBot.frames.lootMenu = menu

    button = tLeft.addButton("Loot", -68, 0, "inv_misc_bag_10", L("tips.loot.main", "Loot rules")).setDisable().doHide()
    button.doLeft = function()
        if menuOpen then
            hideLootMenu()
        else
            showLootMenu()
        end
    end

    button.doRight = function()
        hideLootMenu()
        RunLootCommand("nc -loot")
    end

    hideLootMenu()

    MultiBot.frames.loot = button
    return button
end

function MultiBot.InitializeLootUI()
    if not MultiBot.frames or not MultiBot.frames.tLeft then
        return nil
    end

    return MultiBot.BuildLootUI(MultiBot.frames.tLeft)
end