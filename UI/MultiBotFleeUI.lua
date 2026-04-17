if not MultiBot then return end

local FLEE_BUTTONS = {
    { name = "Flee", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee.blp", cmd = "flee", tip = "flee", scope = "group" },
    { name = "Ranged", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_ranged.blp", cmd = "@ranged flee", tip = "ranged", scope = "group" },
    { name = "Melee", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_melee.blp", cmd = "@melee flee", tip = "melee", scope = "group" },
    { name = "Healer", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_healer.blp", cmd = "@healer flee", tip = "healer", scope = "group" },
    { name = "Dps", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_dps.blp", cmd = "@dps flee", tip = "dps", scope = "group" },
    { name = "Tank", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_tank.blp", cmd = "@tank flee", tip = "tank", scope = "group" },
    { name = "Target", icon = "Interface\\AddOns\\MultiBot\\Icons\\flee_target.blp", cmd = "flee", tip = "target", scope = "target" },
}

local FLEE_ICON = "Interface\\AddOns\\MultiBot\\Icons\\flee.blp"
local FLEE_FRAME_NAME = "Flee"
local FLEE_MAIN_X = -34
local FLEE_FRAME_X = -36
local FLEE_FRAME_Y = 34
local FLEE_CELL_HEIGHT = 30

local function addFleeButton(frame, definition, index)
    local button = frame.addButton(
        definition.name,
        0,
        (index - 1) * FLEE_CELL_HEIGHT,
        definition.icon,
        MultiBot.L("tips.flee." .. definition.tip)
    )

    if definition.scope == "target" then
        button.doLeft = function()
            MultiBot.ActionToTarget(definition.cmd)
        end

        button.doRight = function(owner)
            MultiBot.SelectToTargetButton(owner.parent.parent, FLEE_FRAME_NAME, owner.texture, definition.cmd)
        end

        return button
    end

    button.doLeft = function()
        MultiBot.ActionToGroup(definition.cmd)
    end

    button.doRight = function(owner)
        MultiBot.SelectToGroupButton(owner.parent.parent, FLEE_FRAME_NAME, owner.texture, definition.cmd)
    end

    return button
end

function MultiBot.BuildFleeUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    local mainButton = tLeft.addButton("Flee", FLEE_MAIN_X, 0, FLEE_ICON, MultiBot.L("tips.flee.master"))
    local fleeFrame = tLeft.addFrame(FLEE_FRAME_NAME, FLEE_FRAME_X, FLEE_FRAME_Y)
    fleeFrame:Hide()

    mainButton.doLeft = function()
        MultiBot.ActionToGroup("flee")
    end

    mainButton.doRight = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames[FLEE_FRAME_NAME])
    end

    for index, definition in ipairs(FLEE_BUTTONS) do
        addFleeButton(fleeFrame, definition, index)
    end

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = "Flee", frameName = FLEE_FRAME_NAME },
        })
    end

    return {
        mainButton = mainButton,
        frame = fleeFrame,
    }
end