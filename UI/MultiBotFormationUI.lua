if not MultiBot then return end

local FORMATION_FRAME_NAME = "Format"
local FORMATION_BUTTON_NAME = "Format"
local FORMATION_DEFAULT_ICON = "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp"
local FORMATION_FRAME_X = -2
local FORMATION_FRAME_Y = 34
local FORMATION_CELL_WIDTH = 40
local FORMATION_CELL_HEIGHT = 30

local FORMATION_BUTTONS = {
    { name = "Arrow", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_arrow.blp", cmd = "formation arrow" },
    { name = "Queue", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_queue.blp", cmd = "formation queue" },
    { name = "Near", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp", cmd = "formation near" },
    { name = "Melee", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_melee.blp", cmd = "formation melee" },
    { name = "Line", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_line.blp", cmd = "formation line" },
    { name = "Circle", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_circle.blp", cmd = "formation circle" },
    { name = "Chaos", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_chaos.blp", cmd = "formation chaos" },
    { name = "Shield", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_shield.blp", cmd = "formation shield" },
}

local function addFormationButton(frame, definition, column, row)
    frame.addButton(
        definition.name,
        (column - 1) * FORMATION_CELL_WIDTH,
        (row - 1) * FORMATION_CELL_HEIGHT,
        definition.icon,
        MultiBot.L("tips.format." .. string.lower(definition.name))
    ).doLeft = function(button)
        MultiBot.SelectToGroup(button.parent.parent, FORMATION_FRAME_NAME, button.texture, definition.cmd)
    end
end

function MultiBot.BuildFormationUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    local formatButton = tLeft.addButton(
        FORMATION_BUTTON_NAME,
        0,
        0,
        FORMATION_DEFAULT_ICON,
        MultiBot.L("tips.format.master")
    )

    formatButton.doLeft = function(button)
        MultiBot.ShowHideSwitch(button.parent.frames[FORMATION_FRAME_NAME])
    end

    formatButton.doRight = function()
        MultiBot.ActionToGroup("formation")
    end

    local formatFrame = tLeft.addFrame(FORMATION_FRAME_NAME, FORMATION_FRAME_X, FORMATION_FRAME_Y)
    formatFrame:Hide()

    for index, definition in ipairs(FORMATION_BUTTONS) do
        addFormationButton(formatFrame, definition, 1, index)
    end

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = FORMATION_BUTTON_NAME, frameName = FORMATION_FRAME_NAME },
        })
    end

    return {
        rootButton = formatButton,
        frame = formatFrame,
    }
end