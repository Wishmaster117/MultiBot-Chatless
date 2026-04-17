if not MultiBot then return end

local ROSTER_MODES = {
    { id = "friends", icon = "roster_friends", invite = true, tip = "friends" },
    { id = "members", icon = "roster_members", invite = true, tip = "members" },
    { id = "players", icon = "roster_players", invite = true, tip = "players" },
    { id = "actives", icon = "roster_actives", invite = false, tip = "actives" },
    { id = "favorites", texture = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1", invite = false, tip = "favorites" },
}

local ROSTER_FRAME_NAME = "Roster"
local ROSTER_ROOT_ICON = "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp"
local ROSTER_DEFAULT_ID = "players"
local ROSTER_DEFAULT_TEXTURE = "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp"
local ROSTER_FRAME_X = -30
local ROSTER_FRAME_Y = 32
local ROSTER_STEP_X = -26

local function resolveRosterTexture(definition)
    return definition.texture or ("Interface\\AddOns\\MultiBot\\Icons\\" .. definition.icon .. ".blp")
end

local function scheduleDefaultRosterSelection(tControl)
    MultiBot.TimerAfter(0.05, function()
        local unitsButton = MultiBot.frames
            and MultiBot.frames.MultiBar
            and MultiBot.frames.MultiBar.buttons
            and MultiBot.frames.MultiBar.buttons.Units

        if not unitsButton or not tControl or not tControl.buttons or not tControl.buttons.Roster then
            return
        end

        local rosterButton = tControl.buttons.Roster
        local texture = (rosterButton and rosterButton.texture) or ROSTER_DEFAULT_TEXTURE
        MultiBot.Select(tControl, ROSTER_FRAME_NAME, texture)
        unitsButton.doLeft(unitsButton, ROSTER_DEFAULT_ID)
    end)
end

local function addRosterButton(rosterFrame, definition, index)
    local button = rosterFrame.addButton(
        definition.id:gsub("^%l", string.upper),
        ROSTER_STEP_X * (index - 1),
        0,
        resolveRosterTexture(definition),
        MultiBot.L("tips.units." .. definition.tip)
    )

    button.doLeft = function(owner)
        local unitsButton = MultiBot.frames.MultiBar.buttons.Units
        MultiBot.Select(owner.parent.parent, ROSTER_FRAME_NAME, owner.texture)

        if definition.invite then
            owner.parent.parent.buttons.Invite.setEnable()
        else
            owner.parent.parent.buttons.Invite.setDisable()
        end

        owner.parent.parent.frames.Invite:Hide()
        unitsButton.doLeft(unitsButton, definition.id)
    end

    return button
end

function MultiBot.BuildRosterUI(tControl)
    if not tControl or not tControl.addButton or not tControl.addFrame then
        return nil
    end

    local rootButton = tControl.addButton("Roster", 0, 30, ROSTER_ROOT_ICON, MultiBot.L("tips.units.roster"))
    local rosterFrame = tControl.addFrame(ROSTER_FRAME_NAME, ROSTER_FRAME_X, ROSTER_FRAME_Y)
    rosterFrame:Hide()
    rosterFrame._mbSkipAutoCollapse = true

    rootButton.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames[ROSTER_FRAME_NAME])
    end

    rootButton.doRight = function(owner)
        local unitsButton = MultiBot.frames.MultiBar.buttons.Units
        MultiBot.Select(owner.parent, ROSTER_FRAME_NAME, "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1")
        unitsButton.doLeft(unitsButton, "favorites")
    end

    for index, definition in ipairs(ROSTER_MODES) do
        addRosterButton(rosterFrame, definition, index)
    end

    scheduleDefaultRosterSelection(tControl)

    return {
        rootButton = rootButton,
        frame = rosterFrame,
    }
end