if not MultiBot then return end

local GroupActionsUI = MultiBot.GroupActionsUI or {}
MultiBot.GroupActionsUI = GroupActionsUI

local MENU_BUTTONS = {
    { name = "Drink", x = 0, y = 0, icon = "inv_drink_24_sealwhey", tip = "tips.drink.group", command = "drink" },
    { name = "Release", x = 0, y = 34, icon = "achievement_bg_xkills_avgraveyard", tip = "tips.release.group", command = "release" },
    { name = "Revive", x = 0, y = 68, icon = "spell_holy_guardianspirit", tip = "tips.revive.group", command = "revive" },
}

local SUMMON_BUTTON = {
    name = "Summon",
    x = 68,
    y = 0,
    icon = "ability_hunter_beastcall",
    tip = "tips.summon.group",
    command = "summon",
}

local function createGroupCommand(buttonHost, definition)
    local button = buttonHost.addButton(
        definition.name,
        definition.x,
        definition.y,
        definition.icon,
        MultiBot.L(definition.tip)
    )

    button.doLeft = function()
        MultiBot.ActionToGroup(definition.command)
    end

    return button
end

function MultiBot.InitializeGroupActionsUI(tRight)
    if GroupActionsUI.initialized then
        return GroupActionsUI
    end

    if not tRight or not tRight.addButton or not tRight.addFrame then
        return nil
    end

    local mainButton = tRight.addButton("GroupActions", 34, 0, "Spell_unused2", MultiBot.L("tips.group.group"))
    local menu = tRight.addFrame("GroupActionsMenu", 34, 34, 32, 96)
    menu:Hide()

    mainButton.doLeft = function(owner)
        local targetMenu = owner and owner.parent and owner.parent.frames and owner.parent.frames["GroupActionsMenu"]
        if not targetMenu then
            return
        end

        if targetMenu:IsShown() then
            targetMenu:Hide()
            return
        end

        targetMenu:Show()
    end

    for _, definition in ipairs(MENU_BUTTONS) do
        createGroupCommand(menu, definition)
    end

    local summonButton = createGroupCommand(tRight, SUMMON_BUTTON)

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tRight, "RightRoot", {
            { name = "GroupActions", frameName = "GroupActionsMenu" },
            { name = "Summon" },
        })
    end

    GroupActionsUI.initialized = true
    GroupActionsUI.mainButton = mainButton
    GroupActionsUI.menu = menu
    GroupActionsUI.summonButton = summonButton

    return GroupActionsUI
end