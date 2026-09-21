if not MultiBot then return end

local FORMATION_FRAME_NAME = "Format"
local FORMATION_BUTTON_NAME = "Format"
local FORMATION_DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local FORMATION_FRAME_X = -2
local FORMATION_FRAME_Y = 34
local FORMATION_CELL_WIDTH = 40
local FORMATION_CELL_HEIGHT = 30

local latestFormationToken = nil
local latestFormationTooltipToken = nil
local formationRootButton = nil
local formationSyncGeneration = 0
local formationAuthoritativeToken = nil
local formationAuthoritativeGeneration = 0
local formationDesired = nil
local formationKnownBots = {}
local formationAutoApplyToken = nil

local FORMATION_BUTTONS = {
    { name = "Arrow", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_arrow.blp", value = "arrow" },
    { name = "Queue", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_queue.blp", value = "queue" },
    { name = "Near", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp", value = "near" },
    { name = "Melee", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_melee.blp", value = "melee" },
    { name = "Line", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_line.blp", value = "line" },
    { name = "Circle", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_circle.blp", value = "circle" },
    { name = "Chaos", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_chaos.blp", value = "chaos" },
    { name = "Shield", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_shield.blp", value = "shield" },
    { name = "Far", icon = "Interface\\Icons\\Spell_Nature_FarSight", value = "far" },
}

local function formationText(key)
    if MultiBot and type(MultiBot.L) == "function" then
        local value = MultiBot.L(key)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end

    return key
end

local function formationLabel(value)
    local normalized = string.lower(tostring(value or "?"))
    local key = "formation.name." .. normalized

    if normalized == "?" then
        key = "formation.name.unknown"
    end

    local label = formationText(key)
    if label == key then
        return normalized
    end

    return label
end

local function formationIcon(value)
    local normalized = string.lower(tostring(value or ""))

    for _, definition in ipairs(FORMATION_BUTTONS) do
        if definition.value == normalized then
            return definition.icon
        end
    end

    return nil
end

local function setFormationRootIcon(icon)
    if not formationRootButton or not formationRootButton.setTexture then
        return
    end

    formationRootButton.setTexture(icon or FORMATION_DEFAULT_ICON)
end

local function formationResultIcon(result)
    if type(result) ~= "table" or result.status ~= "ok" then
        return nil
    end

    local items = result.items or {}
    local count = #items
    local expected = tonumber(result.expected or 0) or 0
    local sent = tonumber(result.sent or 0) or 0

    if count == 0 or expected ~= count or sent ~= count then
        return FORMATION_DEFAULT_ICON
    end

    local commonFormation = string.lower(tostring(items[1] and items[1].formation or "?"))
    local icon = formationIcon(commonFormation)
    if not icon then
        return FORMATION_DEFAULT_ICON
    end

    for index = 2, count do
        if string.lower(tostring(items[index].formation or "?")) ~= commonFormation then
            return FORMATION_DEFAULT_ICON
        end
    end

    return icon
end

local function getFormationSnapshot(result)
    if type(result) ~= "table" or result.status ~= "ok" then
        return false, {}, nil, false
    end

    local items = result.items or {}
    local count = #items
    local expected = tonumber(result.expected or 0) or 0
    local sent = tonumber(result.sent or 0) or 0

    if expected ~= count or sent ~= count then
        return false, {}, nil, false
    end

    local commonFormation = nil
    local mixed = false

    for _, item in ipairs(items) do
        local botName = tostring(item.botName or "")
        local value = string.lower(tostring(item.formation or ""))

        if botName == "" or not formationIcon(value) then
            return false, {}, nil, false
        end

        if not commonFormation then
            commonFormation = value
        elseif value ~= commonFormation then
            mixed = true
        end
    end

    return true, items, commonFormation, mixed
end

local function hasPendingFormationCommand()
    local bridge = MultiBot.bridge
    if not bridge or type(bridge.formationCommands) ~= "table" then
        return false
    end

    for _, pending in pairs(bridge.formationCommands) do
        if type(pending) == "table" then
            return true
        end
    end

    return false
end

local function updateDesiredFormationFromSnapshot(result)
    local complete, items, commonFormation, mixed = getFormationSnapshot(result)
    if not complete then
        return
    end

    local previousKnownBots = formationKnownBots
    local currentKnownBots = {}
    local stableKnownBots = {}
    local newBotCount = 0
    local newBotMismatch = false
    local existingBotsMatchDesired = true

    for _, item in ipairs(items) do
        local botName = tostring(item.botName or "")
        local value = string.lower(tostring(item.formation or ""))
        currentKnownBots[botName] = true

        if previousKnownBots[botName] then
            stableKnownBots[botName] = true
            if formationDesired and value ~= formationDesired then
                existingBotsMatchDesired = false
            end
        else
            newBotCount = newBotCount + 1
            if formationDesired and value ~= formationDesired then
                newBotMismatch = true
            else
                stableKnownBots[botName] = true
            end
        end
    end

    if not formationDesired then
        formationKnownBots = currentKnownBots
        if commonFormation and not mixed then
            formationDesired = commonFormation
        end
        return
    end

    if not existingBotsMatchDesired or newBotCount == 0 or not newBotMismatch then
        formationKnownBots = currentKnownBots
        return
    end

    formationKnownBots = stableKnownBots

    if formationAutoApplyToken ~= nil
        or hasPendingFormationCommand()
        or not MultiBot.Comm
        or type(MultiBot.Comm.RunFormationCommand) ~= "function" then
        return
    end

    local token = MultiBot.Comm.RunFormationCommand("GROUP", "", formationDesired)
    if token then
        formationAutoApplyToken = token
    end
end

function MultiBot.InvalidateFormationUI(reason)
    formationSyncGeneration = formationSyncGeneration + 1
    formationAuthoritativeToken = nil
    formationAuthoritativeGeneration = 0

    if reason ~= "group-roster" then
        setFormationRootIcon(FORMATION_DEFAULT_ICON)
    end
end

function MultiBot.RefreshFormationAuthoritative(delay, callback)
    local bridge = MultiBot.bridge
    if not bridge or bridge.connected ~= true or bridge.formationCapable ~= true
        or not MultiBot.Comm or type(MultiBot.Comm.RequestFormations) ~= "function" then
        return false
    end

    formationSyncGeneration = formationSyncGeneration + 1
    local generation = formationSyncGeneration
    delay = tonumber(delay) or 0

    local function requestFormationState()
        if generation ~= formationSyncGeneration then
            return
        end

        local currentBridge = MultiBot.bridge
        if not currentBridge or currentBridge.connected ~= true or currentBridge.formationCapable ~= true
            or not MultiBot.Comm or type(MultiBot.Comm.RequestFormations) ~= "function" then
            return
        end

        if currentBridge.formationQueryActive ~= nil then
            if type(MultiBot.TimerAfter) == "function" then
                MultiBot.TimerAfter(0.25, requestFormationState)
            end
            return
        end

        local token
        token = MultiBot.Comm.RequestFormations(function(result)
            if generation ~= formationSyncGeneration then
                return
            end

            if type(callback) == "function" then
                callback(result)
            end
        end)

        if token then
            formationAuthoritativeToken = token
            formationAuthoritativeGeneration = generation
        elseif type(callback) == "function" then
            callback({ status = "unavailable" })
        end
    end

    if delay > 0 and type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delay, requestFormationState)
    else
        requestFormationState()
    end

    return true
end

function MultiBot.OnFormationQueryCompleted(result)
    if type(result) ~= "table"
        or result.token ~= formationAuthoritativeToken
        or formationAuthoritativeGeneration ~= formationSyncGeneration then
        return
    end

    formationAuthoritativeToken = nil
    formationAuthoritativeGeneration = 0

    local icon = formationResultIcon(result)
    if icon then
        setFormationRootIcon(icon)
    end

    updateDesiredFormationFromSnapshot(result)
end

function MultiBot.OnFormationCommandApplied(result)
    if type(result) ~= "table" then
        return
    end

    local success = tonumber(result.success or 0) or 0
    local failure = tonumber(result.failure or 0) or 0
    local wasAutoApply = formationAutoApplyToken ~= nil and result.token == formationAutoApplyToken

    if wasAutoApply then
        formationAutoApplyToken = nil
    end

    if success > 0 and failure == 0 then
        local appliedFormation = string.lower(tostring(result.formation or ""))
        if formationIcon(appliedFormation) then
            formationDesired = appliedFormation
        end

        formationSyncGeneration = formationSyncGeneration + 1
        formationAuthoritativeToken = nil
        formationAuthoritativeGeneration = 0
        setFormationRootIcon(formationIcon(result.formation) or FORMATION_DEFAULT_ICON)

        if wasAutoApply then
            MultiBot.RefreshFormationAuthoritative(0.20)
        end
        return
    end

    if success > 0 or failure > 0 then
        MultiBot.InvalidateFormationUI("command-partial")
        MultiBot.RefreshFormationAuthoritative(0.20)
    end
end

local function hideFormationTooltip(token, owner)
    if token ~= latestFormationTooltipToken then
        return
    end

    latestFormationTooltipToken = nil

    if not GameTooltip or not GameTooltip.GetOwner or not GameTooltip.Hide then
        return
    end

    if GameTooltip:GetOwner() ~= owner then
        return
    end

    GameTooltip:Hide()
end

local function showFormationTooltip(button, result)
    if not button or not GameTooltip then
        return
    end

    local token = result and result.token or tostring(GetTime and GetTime() or 0)
    latestFormationTooltipToken = token

    GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 0 - (button.size or 32), 2)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(formationText("formation.query.title"), 1, 0.82, 0)

    if not result or result.status == "unavailable" then
        GameTooltip:AddLine(formationText("formation.query.unavailable"), 1, 0.25, 0.25, true)
    elseif result.status == "timeout" then
        GameTooltip:AddLine(formationText("formation.query.timeout"), 1, 0.25, 0.25, true)
    else
        local items = result.items or {}
        local count = #items

        if count == 0 then
            GameTooltip:AddLine(formationText("formation.query.empty"), 0.8, 0.8, 0.8, true)
        else
            local commonFormation = items[1] and items[1].formation or "?"
            local mixed = false

            for index = 2, count do
                if items[index].formation ~= commonFormation then
                    mixed = true
                    break
                end
            end

            if mixed then
                GameTooltip:AddLine(formationText("formation.query.mixed"), 1, 0.65, 0.2)
            else
                GameTooltip:AddLine(
                    string.format(
                        formationText("formation.query.common"),
                        formationLabel(commonFormation),
                        count
                    ),
                    0.35,
                    1,
                    0.35
                )
            end

            GameTooltip:AddLine(" ")
            for _, item in ipairs(items) do
                GameTooltip:AddDoubleLine(
                    tostring(item.botName or "?"),
                    formationLabel(item.formation),
                    1,
                    1,
                    1,
                    0.5,
                    0.82,
                    1
                )
            end
        end
    end

    GameTooltip:Show()

    if MultiBot and type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(8.0, function()
            hideFormationTooltip(token, button)
        end)
    end
end

local function applyFormationSelection(parent, texture)
    if not parent or not parent.frames or not parent.buttons then
        return
    end

    local frame = parent.frames[FORMATION_FRAME_NAME]
    local button = parent.buttons[FORMATION_BUTTON_NAME]
    if not frame or not button then
        return
    end

    button.setTexture(texture)
    frame:Hide()
    if MultiBot.RequestClickBlockerUpdate then
        MultiBot.RequestClickBlockerUpdate(frame)
    end
end

local function addFormationButton(frame, definition, column, row)
    frame.addButton(
        definition.name,
        (column - 1) * FORMATION_CELL_WIDTH,
        (row - 1) * FORMATION_CELL_HEIGHT,
        definition.icon,
        MultiBot.L("tips.format." .. string.lower(definition.name))
    ).doLeft = function(button)
        if not MultiBot.Comm or not MultiBot.Comm.RunFormationCommand then
            return
        end

        local parent = button.parent and button.parent.parent
        local token
        token = MultiBot.Comm.RunFormationCommand("GROUP", "", definition.value, function(result)
            if not result or result.token ~= latestFormationToken then
                return
            end

            latestFormationToken = nil
            if result.success > 0
                and result.failure == 0
                and result.formation == definition.value
            then
                applyFormationSelection(parent, definition.icon)
            end
        end)

        if token then
            latestFormationToken = token
        end
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

    formationRootButton = formatButton
    MultiBot.InvalidateFormationUI("build")

    formatButton.doLeft = function(button)
        MultiBot.RefreshFormationAuthoritative(0)
        MultiBot.ShowHideSwitch(button.parent.frames[FORMATION_FRAME_NAME])
    end

    formatButton.doRight = function(button)
        if not MultiBot.RefreshFormationAuthoritative then
            showFormationTooltip(button, { status = "unavailable" })
            return
        end

        if not MultiBot.RefreshFormationAuthoritative(0, function(result)
            showFormationTooltip(button, result)
        end) then
            showFormationTooltip(button, { status = "unavailable" })
        end
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

    MultiBot.RefreshFormationAuthoritative(0)

    return {
        rootButton = formatButton,
        frame = formatFrame,
    }
end