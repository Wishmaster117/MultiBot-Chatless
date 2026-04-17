if not MultiBot then return end

local FILTERS = {
    { key = "DeathKnight", icon = "filter_deathknight" },
    { key = "Druid", icon = "filter_druid" },
    { key = "Hunter", icon = "filter_hunter" },
    { key = "Mage", icon = "filter_mage" },
    { key = "Paladin", icon = "filter_paladin" },
    { key = "Priest", icon = "filter_priest" },
    { key = "Rogue", icon = "filter_rogue" },
    { key = "Shaman", icon = "filter_shaman" },
    { key = "Warlock", icon = "filter_warlock" },
    { key = "Warrior", icon = "filter_warrior" },
    { key = "none", icon = "filter_none" },
}

local FILTER_FRAME_NAME = "Filter"
local FILTER_ROOT_ICON = "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp"
local FILTER_FRAME_X = -30
local FILTER_FRAME_Y = 2
local FILTER_STEP_X = -26

local function buildFilterTexture(icon)
    return "Interface\\AddOns\\MultiBot\\Icons\\" .. icon .. ".blp"
end

local function addFilterButton(filterFrame, definition, index)
    local texture = buildFilterTexture(definition.icon)
    local button = filterFrame.addButton(
        definition.key,
        FILTER_STEP_X * (index - 1),
        0,
        texture,
        MultiBot.L("tips.units." .. string.lower(definition.key))
    )

    button.doLeft = function(owner)
        local unitsButton = MultiBot.frames.MultiBar.buttons.Units
        MultiBot.Select(owner.parent.parent, FILTER_FRAME_NAME, owner.texture)
        unitsButton.doLeft(unitsButton, nil, definition.key)
    end

    return button
end

function MultiBot.BuildFilterUI(tControl)
    if not tControl or not tControl.addButton or not tControl.addFrame then
        return nil
    end

    local rootButton = tControl.addButton("Filter", 0, 0, FILTER_ROOT_ICON, MultiBot.L("tips.units.filter"))
    local filterFrame = tControl.addFrame(FILTER_FRAME_NAME, FILTER_FRAME_X, FILTER_FRAME_Y)
    filterFrame:Hide()
    filterFrame._mbSkipAutoCollapse = true

    rootButton.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames[FILTER_FRAME_NAME])
    end

    rootButton.doRight = function(owner)
        local unitsButton = MultiBot.frames.MultiBar.buttons.Units
        MultiBot.Select(owner.parent, FILTER_FRAME_NAME, FILTER_ROOT_ICON)
        unitsButton.doLeft(unitsButton, nil, "none")
    end

    for index, definition in ipairs(FILTERS) do
        addFilterButton(filterFrame, definition, index)
    end

    return {
        rootButton = rootButton,
        frame = filterFrame,
    }
end