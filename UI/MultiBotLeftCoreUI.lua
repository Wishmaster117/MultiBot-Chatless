if not MultiBot then return end

local MODE_FRAME_NAME = "Mode"
local MODE_BUTTON_NAME = "Mode"
local MODE_BUTTON_ICON = "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp"
local MODE_FRAME_X = -104
local MODE_FRAME_Y = 34

local function bindModeToggleAction(modeButton, enableCommand, disableCommand)
    modeButton.setEnable().doLeft = function(button)
        if MultiBot.OnOffSwitch(button) then
            MultiBot.ActionToGroup(enableCommand)
        else
            MultiBot.ActionToGroup(disableCommand)
        end
    end
end

local function createModeUI(tLeft)
    local modeButton = tLeft.addButton(MODE_BUTTON_NAME, -102, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.master")).setDisable()

    modeButton.doRight = function(button)
        MultiBot.ShowHideSwitch(button.parent.frames[MODE_FRAME_NAME])
    end

    modeButton.doLeft = function(button)
        if MultiBot.OnOffSwitch(button) then
            MultiBot.ActionToGroup("co +passive,?")
        else
            MultiBot.ActionToGroup("co -passive,?")
        end
    end

    local modeFrame = tLeft.addFrame(MODE_FRAME_NAME, MODE_FRAME_X, MODE_FRAME_Y)
    modeFrame:Hide()

    modeFrame.addButton("Passive", 0, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.passive")).doLeft = function(button)
        if MultiBot.SelectToGroup(button.parent.parent, MODE_FRAME_NAME, button.texture, "co +passive,?") then
            bindModeToggleAction(button.parent.parent.buttons[MODE_BUTTON_NAME], "co +passive,?", "co -passive,?")
        end
    end

    modeFrame.addButton("Grind", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\mode_grind.blp", MultiBot.L("tips.mode.grind")).doLeft = function(button)
        if MultiBot.SelectToGroup(button.parent.parent, MODE_FRAME_NAME, button.texture, "grind") then
            bindModeToggleAction(button.parent.parent.buttons[MODE_BUTTON_NAME], "grind", "follow")
        end
    end
end

local function createStayFollowUI(tLeft)
    tLeft.addButton("Stay", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.L("tips.stallow.stay")).doLeft = function(button)
        if MultiBot.ActionToGroup("stay") then
            button.parent.buttons["Follow"].doShow()
            button.parent.buttons["ExpandFollow"].setDisable()
            button.parent.buttons["ExpandStay"].setEnable()
            button.doHide()
        end
    end

    tLeft.addButton("Follow", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.L("tips.stallow.follow")).doHide().doLeft = function(button)
        if MultiBot.ActionToGroup("follow") then
            button.parent.buttons["Stay"].doShow()
            button.parent.buttons["ExpandFollow"].setEnable()
            button.parent.buttons["ExpandStay"].setDisable()
            button.doHide()
        end
    end

    tLeft.addButton("ExpandStay", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.tips.expand.stay).doHide().setDisable().doLeft = function(button)
        MultiBot.ActionToGroup("stay")
        button.parent.buttons["ExpandFollow"].setDisable()
        button.setEnable()
    end

    tLeft.addButton("ExpandFollow", -102, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.expand.follow).doHide().doLeft = function(button)
        MultiBot.ActionToGroup("follow")
        button.parent.buttons["ExpandStay"].setDisable()
        button.setEnable()
    end
end

function MultiBot.InitializeLeftCoreUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    tLeft.addButton("Tanker", -170, 0, "ability_warrior_shieldbash", MultiBot.L("tips.tanker.master")).doLeft = function()
        if MultiBot.isTarget() then
            MultiBot.ActionToGroup("@tank do attack my target")
        end
    end

    createModeUI(tLeft)
    createStayFollowUI(tLeft)

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = "Tanker" },
            { name = "Mode", frameName = "Mode" },
            { name = "Stay" },
            { name = "Follow" },
        })
    end

    return tLeft
end