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
    { key = "disenchant", command = "ll disenchant", icon = "inv_misc_book_07", tip = "tips.loot.disenchant", fallback = "Loot profile: Disenchant" },
    { key = "additem", action = "ADD", icon = "inv_misc_bag_10", tip = "loot.item.add", fallback = "Always loot: add item" },
    { key = "removeitem", action = "REMOVE", icon = "inv_misc_bag_07", tip = "loot.item.remove", fallback = "Always loot: remove item" },
}

local LOOT_PROFILE_ENTRIES = {
    all = LOOT_COMMANDS[3],
    normal = LOOT_COMMANDS[4],
    gray = LOOT_COMMANDS[5],
    disenchant = LOOT_COMMANDS[6],
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

-- MB_LOOT_RULE_ITEM_V1_UI_BEGIN
local function ShowLootItemMessage(message, ok)
    message = tostring(message or "")
    if message == "" then
        return
    end

    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        if ok then
            UIErrorsFrame:AddMessage(message, 0.2, 1.0, 0.2, 1.0)
        else
            UIErrorsFrame:AddMessage(message, 1.0, 0.2, 0.2, 1.0)
        end
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

local function ParseLootRuleItemId(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local itemId = tonumber(value)
    if not itemId then
        itemId = tonumber(value:match("|Hitem:(%d+):") or value:match("Hitem:(%d+):"))
    end

    if not itemId or itemId < 1 or itemId > 4294967295 or math.floor(itemId) ~= itemId then
        return nil
    end

    return itemId
end

local function LootRuleItemReasonText(reason)
    local normalized = tostring(reason or "FAILED")
    return L("loot.item.reason." .. normalized, normalized)
end

local function FormatLootRuleItemResult(itemText, status, reason, matched, changed)
    local ok = status == "OK"
    local matchedCount = tonumber(matched) or 0
    local changedCount = tonumber(changed) or 0

    if ok then
        if reason == "ADDED" then
            return string.format(L("loot.item.result.added", "%s - added to %d bot(s)."), itemText, changedCount), true
        elseif reason == "REMOVED" then
            return string.format(L("loot.item.result.removed", "%s - removed from %d bot(s)."), itemText, changedCount), true
        elseif reason == "ALREADY_PRESENT" then
            return string.format(L("loot.item.result.already_present", "%s - already present on %d bot(s)."), itemText, matchedCount), true
        elseif reason == "ALREADY_ABSENT" then
            return string.format(L("loot.item.result.already_absent", "%s - already absent on %d bot(s)."), itemText, matchedCount), true
        elseif reason == "PARTIAL" then
            return string.format(L("loot.item.result.partial", "%s - partially updated (%d/%d bot(s))."), itemText, changedCount, matchedCount), true
        end

        return string.format(
            L("loot.item.result.ok", "%s - %s (%d/%d bot(s))."),
            itemText,
            LootRuleItemReasonText(reason),
            changedCount,
            matchedCount
        ), true
    end

    return string.format(
        L("loot.item.result.failed", "%s - loot rule failed: %s."),
        itemText,
        LootRuleItemReasonText(reason)
    ), false
end

local function ShowLootRuleItemPrompt(action)
    if not MultiBot or not MultiBot.Comm
        or not MultiBot.Comm.IsLootRuleItemCapable
        or not MultiBot.Comm.RunLootRuleItem
        or not MultiBot.Comm.IsLootRuleItemCapable() then
        ShowLootItemMessage(L("loot.item.bridge.required", "Exact loot-item rules require LOOT_RULE_ITEM_V1."), false)
        return
    end

    if type(MultiBot.ShowPrompt) ~= "function" then
        ShowLootItemMessage(L("loot.item.prompt.required", "Item prompt is unavailable."), false)
        return
    end

    local title = action == "REMOVE"
        and L("loot.item.remove.prompt", "Remove always-loot item ID or link")
        or L("loot.item.add.prompt", "Add always-loot item ID or link")

    MultiBot.ShowPrompt(title, function(value)
        local itemId = ParseLootRuleItemId(value)
        if not itemId then
            ShowLootItemMessage(L("loot.item.invalid", "Invalid item ID or item link."), false)
            return
        end

        local token = MultiBot.Comm.RunLootRuleItem("ALL", "", action, itemId)
        if not token then
            ShowLootItemMessage(L("loot.item.send.failed", "Loot item rule request was not sent."), false)
        end
    end, "")
end

MultiBot.OnLootRuleItemResult = function(scope, target, action, itemId, status, reason, matched, changed)
    local itemName, itemLink = GetItemInfo(itemId)
    local itemText = itemLink or itemName or ("item:" .. tostring(itemId or 0))
    local message, ok = FormatLootRuleItemResult(itemText, status, reason, matched, changed)
    ShowLootItemMessage(message, ok)
end
-- MB_LOOT_RULE_ITEM_V1_UI_END

function MultiBot.BuildLootUI(tLeft)
    if not tLeft or MultiBot.frames.loot then
        return MultiBot.frames.loot
    end

    local button
    local menu = tLeft.addFrame("LootMenu", -73, 34, 24, 24, 218).doHide()
    local menuOpen = false
    local menuButtons = {}
    local menuButtonsByKey = {}
    menu._mbDropdownManaged = true
    menu:SetWidth(24)
    menu:SetHeight(218)

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

        if button then
            local profileEntry = lootVisualState.profile and LOOT_PROFILE_ENTRIES[lootVisualState.profile] or nil
            if profileEntry then
                button.setButton(profileEntry.icon, L(profileEntry.tip, profileEntry.fallback))
            else
                button.setButton("inv_misc_bag_10", L("tips.loot.main", "Loot rules"))
            end

            if lootVisualState.enabled == true then
                button.setEnable(false)
            else
                button.setDisable(false)
            end
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
        else
            local profile = command:match("^ll%s+([%w_%-]+)$")
            if profile and LOOT_PROFILE_ENTRIES[profile] then
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
            if entry.command then
                RunLootCommand(entry.command)
            elseif entry.action then
                ShowLootRuleItemPrompt(entry.action)
            end
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