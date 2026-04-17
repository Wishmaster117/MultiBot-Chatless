if not MultiBot then return end

local ATTACK_BUTTONS = {
    { name = "Attack", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack.blp", cmd = "do attack my target", tip = "attack" },
    { name = "Ranged", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_ranged.blp", cmd = "@ranged do attack my target", tip = "ranged" },
    { name = "Melee", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_melee.blp", cmd = "@melee do attack my target", tip = "melee" },
    { name = "Healer", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_healer.blp", cmd = "@healer do attack my target", tip = "healer" },
    { name = "Dps", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_dps.blp", cmd = "@dps do attack my target", tip = "dps" },
    { name = "Tank", icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_tank.blp", cmd = "@tank do attack my target", tip = "tank" },
}

local ATTACK_ICON = "Interface\\AddOns\\MultiBot\\Icons\\attack.blp"
local ATTACK_FRAME_NAME = "Attack"
local ATTACK_MAIN_X = -136
local ATTACK_FRAME_X = -138
local ATTACK_FRAME_Y = 34
local ATTACK_CELL_HEIGHT = 30

local function addAttackButton(frame, definition, index)
    local button = frame.addButton(
        definition.name,
        0,
        (index - 1) * ATTACK_CELL_HEIGHT,
        definition.icon,
        MultiBot.L("tips.attack." .. definition.tip)
    )

    button.doLeft = function()
        if MultiBot.isTarget() then
            MultiBot.ActionToGroup(definition.cmd)
        end
    end

    button.doRight = function(owner)
        MultiBot.SelectToGroupButtonWithTarget(owner.parent.parent, ATTACK_FRAME_NAME, owner.texture, definition.cmd)
    end

    return button
end

function MultiBot.BuildAttackUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    local mainButton = tLeft.addButton("Attack", ATTACK_MAIN_X, 0, ATTACK_ICON, MultiBot.L("tips.attack.master"))
    local attackFrame = tLeft.addFrame(ATTACK_FRAME_NAME, ATTACK_FRAME_X, ATTACK_FRAME_Y)
    attackFrame:Hide()

    mainButton.doLeft = function()
        if MultiBot.isTarget() then
            MultiBot.ActionToGroup("do attack my target")
        end
    end

    mainButton.doRight = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames[ATTACK_FRAME_NAME])
    end

    for index, definition in ipairs(ATTACK_BUTTONS) do
        addAttackButton(attackFrame, definition, index)
    end

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = "Attack", frameName = ATTACK_FRAME_NAME },
        })
    end

    return {
        mainButton = mainButton,
        frame = attackFrame,
    }
end