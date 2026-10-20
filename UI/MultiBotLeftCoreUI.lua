if not MultiBot then return end

local MODE_FRAME_NAME = "Mode"
local MODE_BUTTON_NAME = "Mode"
local MODE_BUTTON_ICON = "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp"
local MODE_FRAME_X = -172
local MODE_FRAME_Y = 34

-- MB_P1A_MODE_BLOCKED_STATE_V1_START
local function modeActionApplied(result)
    return type(result) == "table"
        and result.status == "ok"
        and (tonumber(result.succeeded) or 0) > 0
end

local function dispatchModeToggleAction(button, enableCommand, disableCommand)
    local wasEnabled = button.state == true
    local command = wasEnabled and disableCommand or enableCommand

    local accepted = MultiBot.ActionToGroup(command, function(result)
        if not modeActionApplied(result) then return end

        if wasEnabled then
            button.setDisable()
        else
            button.setEnable()
        end
    end)

    return accepted == true
end

local function bindModeToggleAction(modeButton, modeName, enableCommand, disableCommand)
    modeButton._mbModeName = modeName
    modeButton.doLeft = function(button)
        dispatchModeToggleAction(button, enableCommand, disableCommand)
    end
    return modeButton
end

local function commitModeSelection(parent, texture, modeName, enableCommand, disableCommand, enabled)
    local modeButton = parent and parent.buttons and parent.buttons[MODE_BUTTON_NAME]
    if not modeButton then return false end

    MultiBot.Select(parent, MODE_FRAME_NAME, texture)
    bindModeToggleAction(modeButton, modeName, enableCommand, disableCommand)

    if enabled == true then
        modeButton.setEnable()
    else
        modeButton.setDisable()
    end

    return true
end

local function runModeAction(command, onSuccess)
    local accepted = MultiBot.ActionToGroup(command, function(result)
        if not modeActionApplied(result) then return end
        if type(onSuccess) == "function" then
            onSuccess(result)
        end
    end)

    return accepted == true
end
-- MB_P1A_MODE_BLOCKED_STATE_V1_END

-- MB_MODE_TRANSITION_ACK_V1_BEGIN
local function createModeUI(tLeft)
    local modeButton = tLeft.addButton(MODE_BUTTON_NAME, -170, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.master")).setDisable()
    bindModeToggleAction(modeButton, "PASSIVE", "co +passive,?", "co -passive,?")

    modeButton.doRight = function(button)
        MultiBot.ShowHideSwitch(button.parent.frames[MODE_FRAME_NAME])
    end

    local modeFrame = tLeft.addFrame(MODE_FRAME_NAME, MODE_FRAME_X, MODE_FRAME_Y)
    modeFrame:Hide()

    modeFrame.addButton("Passive", 0, 0, MODE_BUTTON_ICON, MultiBot.L("tips.mode.passive")).doLeft = function(button)
        local parent = button.parent.parent
        local currentModeButton = parent.buttons[MODE_BUTTON_NAME]

        local function activatePassive()
            return runModeAction("co +passive,?", function()
                commitModeSelection(parent, button.texture, "PASSIVE", "co +passive,?", "co -passive,?", true)
            end)
        end

        if currentModeButton
            and currentModeButton.state == true
            and currentModeButton._mbModeName == "GRIND" then
            runModeAction("follow", function()
                commitModeSelection(parent, button.texture, "PASSIVE", "co +passive,?", "co -passive,?", false)
                activatePassive()
            end)
            return
        end

        activatePassive()
    end

    modeFrame.addButton("Grind", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\mode_grind.blp", MultiBot.L("tips.mode.grind")).doLeft = function(button)
        local parent = button.parent.parent
        local currentModeButton = parent.buttons[MODE_BUTTON_NAME]

        local function activateGrind()
            return runModeAction("grind", function()
                commitModeSelection(parent, button.texture, "GRIND", "grind", "follow", true)
            end)
        end

        if currentModeButton
            and currentModeButton.state == true
            and currentModeButton._mbModeName == "PASSIVE" then
            runModeAction("co -passive,?", function()
                commitModeSelection(parent, button.texture, "GRIND", "grind", "follow", false)
                activateGrind()
            end)
            return
        end

        activateGrind()
    end
end
-- MB_MODE_TRANSITION_ACK_V1_END

local function createStayFollowUI(tLeft)
    local function orderApplied(result)
        return type(result) == "table" and result.status == "ok" and (tonumber(result.succeeded) or 0) > 0
    end

    tLeft.addButton("Stay", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.L("tips.stallow.stay")).doLeft = function(button)
        MultiBot.ActionToGroup("stay", function(result)
            if not orderApplied(result) then return end
            button.parent.buttons["Follow"].doShow()
            button.parent.buttons["ExpandFollow"].setDisable()
            button.parent.buttons["ExpandStay"].setEnable()
            button.doHide()
        end)
    end

    tLeft.addButton("Follow", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.L("tips.stallow.follow")).doHide().doLeft = function(button)
        MultiBot.ActionToGroup("follow", function(result)
            if not orderApplied(result) then return end
            button.parent.buttons["Stay"].doShow()
            button.parent.buttons["ExpandFollow"].setEnable()
            button.parent.buttons["ExpandStay"].setDisable()
            button.doHide()
        end)
    end

    tLeft.addButton("ExpandStay", -136, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.tips.expand.stay).doHide().setDisable().doLeft = function(button)
        MultiBot.ActionToGroup("stay", function(result)
            if not orderApplied(result) then return end
            button.parent.buttons["ExpandFollow"].setDisable()
            button.setEnable()
        end)
    end

    tLeft.addButton("ExpandFollow", -170, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.expand.follow).doHide().doLeft = function(button)
        MultiBot.ActionToGroup("follow", function(result)
            if not orderApplied(result) then return end
            button.parent.buttons["ExpandStay"].setDisable()
            button.setEnable()
        end)
    end
end

function MultiBot.InitializeLeftCoreUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    if MultiBot.BuildBotRTIActionUI then
        MultiBot.BuildBotRTIActionUI(tLeft, -306, 0)
    end

    if MultiBot.BuildDisperseUI then
        MultiBot.BuildDisperseUI(tLeft)
    end

    if MultiBot.BuildLootUI then
        MultiBot.BuildLootUI(tLeft)
    end

    tLeft.addButton("Tanker", -238, 0, "ability_warrior_shieldbash", MultiBot.L("tips.tanker.master")).doLeft = function()
        if MultiBot.isTarget() then
            MultiBot.ActionToGroup("@tank do attack my target")
        end
    end

    createModeUI(tLeft)
    createStayFollowUI(tLeft)

    if MultiBot.BindShiftRightSwapButtons then
        MultiBot.BindShiftRightSwapButtons(tLeft, "LeftRoot", {
            { name = "BotRTI", id = "BotRTIActionButton", frameName = "BotRTIAction" },
            { name = "Disperse", frameName = "DisperseMenu" },
            { name = "Loot", frameName = "LootMenu" },
            { name = "Tanker" },
            { name = "Mode", frameName = "Mode" },
            { name = "Stay" },
            { name = "Follow" },
        })
    end

    return tLeft
end