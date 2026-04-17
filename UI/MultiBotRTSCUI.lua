if not MultiBot then return end

local RTSC_FRAME_NAME = "RTSC"
local RTSC_SELECTOR_NAME = "Selector"
local RTSC_FRAME_X = -2
local RTSC_FRAME_Y = -34
local RTSC_SELECTOR_Y = 2
local RTSC_SELECTOR_HEIGHT = 28
local RTSC_STORAGE_ICON = "achievement_bg_winwsg_3-0"

local RTSC_GROUP_BUTTONS = {
    { tag = "@group1", x = 30, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group1.blp", tip = "tips.rtsc.group1", hidden = true, disabled = true },
    { tag = "@group2", x = 60, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group2.blp", tip = "tips.rtsc.group2", hidden = true, disabled = true },
    { tag = "@group3", x = 90, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group3.blp", tip = "tips.rtsc.group3", hidden = true, disabled = true },
    { tag = "@group4", x = 120, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group4.blp", tip = "tips.rtsc.group4", hidden = true, disabled = true },
    { tag = "@group5", x = 150, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group5.blp", tip = "tips.rtsc.group5", hidden = true, disabled = true },
}

local RTSC_ROLE_BUTTONS = {
    { tag = "@tank", x = 30, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_tank.blp", tip = "tips.rtsc.tank", disabled = true },
    { tag = "@dps", x = 60, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_dps.blp", tip = "tips.rtsc.dps", disabled = true },
    { tag = "@healer", x = 90, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_healer.blp", tip = "tips.rtsc.healer", disabled = true },
    { tag = "@melee", x = 120, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_melee.blp", tip = "tips.rtsc.melee", disabled = true },
    { tag = "@ranged", x = 150, icon = "Interface\\AddOns\\MultiBot\\Icons\\rtsc_ranged.blp", tip = "tips.rtsc.ranged", disabled = true },
    { tag = "@meleedps", x = 180, icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_melee.blp", tip = "tips.rtsc.meleedps", disabled = true },
    { tag = "@rangeddps", x = 210, icon = "Interface\\AddOns\\MultiBot\\Icons\\attack_range.blp", tip = "tips.rtsc.rangeddps", disabled = true },
}

local RTSC_BROWSE_ROLES = { "@dps", "@tank", "@melee", "@healer", "@ranged" }
local RTSC_BROWSE_GROUPS = { "@group1", "@group2", "@group3", "@group4", "@group5" }

local function createSelectorButton(selectorFrame, definition)
    local button = selectorFrame
        .addButton(definition.tag, definition.x, 0, definition.icon, MultiBot.L(definition.tip), "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")

    if definition.hidden then
        button.doHide()
    end

    if definition.disabled then
        button.setDisable()
    end

    button.doRight = function(owner)
        MultiBot.ActionToGroup(definition.tag .. " rtsc select")
        owner.parent.doSelect(owner, definition.tag)
        owner.setEnable()
    end

    button.doLeft = function(owner)
        MultiBot.ActionToGroup(definition.tag .. " rtsc select")
        owner.parent.doReset(owner.parent)
    end

    return button
end

local function createStoragePair(selectorFrame, index)
    local macroName = "MACRO" .. index
    local rtscName = "RTSC" .. index
    local x = -304 + 30 * index

    selectorFrame
        .addButton(macroName, x, 0, RTSC_STORAGE_ICON, MultiBot.L("tips.rtsc.macro"), "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")
        .setDisable()
        .doLeft = function(button)
            MultiBot.ActionToGroup("rtsc save " .. index)
            button.parent.buttons[rtscName].doShow()
            button.doHide()
        end

    local rtscButton = selectorFrame
        .addButton(rtscName, x, 0, RTSC_STORAGE_ICON, MultiBot.L("tips.rtsc.spot"), "SecureActionButtonTemplate")
        .doHide()

    rtscButton.doRight = function(button)
        MultiBot.ActionToGroup("rtsc unsave " .. index)
        button.parent.buttons[macroName].doShow()
        button.doHide()
    end

    rtscButton.doLeft = function(button)
        button.parent.doExecute(button, "rtsc go " .. index)
    end

    return rtscButton
end

local function bindSelectorLogic(selectorFrame)
    selectorFrame.selector = ""

    selectorFrame.doExecute = function(button, action)
        if button.parent.selector == "" then
            return MultiBot.ActionToGroup(action)
        end

        local selected = MultiBot.doSplit(button.parent.selector, " ")
        local others = {}
        local groupIndexes = {}

        for _, tag in ipairs(selected) do
            local groupIndex = string.match(tag, "^@group(%d+)$")
            if groupIndex then
                table.insert(groupIndexes, tonumber(groupIndex))
            else
                table.insert(others, tag)
            end
        end

        for _, tag in ipairs(others) do
            MultiBot.ActionToGroup(tag .. " " .. action)
            if button.parent.buttons[tag] then
                button.parent.buttons[tag].setDisable()
            end
        end

        if #groupIndexes > 0 then
            table.sort(groupIndexes)

            local parts = {}
            local index = 1
            while index <= #groupIndexes do
                local rangeStart = groupIndexes[index]
                local endIndex = index

                while endIndex + 1 <= #groupIndexes and groupIndexes[endIndex + 1] == groupIndexes[endIndex] + 1 do
                    endIndex = endIndex + 1
                end

                local rangeEnd = groupIndexes[endIndex]
                table.insert(parts, rangeStart == rangeEnd and tostring(rangeStart) or (tostring(rangeStart) .. "-" .. tostring(rangeEnd)))
                index = endIndex + 1
            end

            local prefix = "@group" .. table.concat(parts, ",")
            MultiBot.ActionToGroup(prefix .. " " .. action)

            for _, groupIndex in ipairs(groupIndexes) do
                local key = "@group" .. tostring(groupIndex)
                if button.parent.buttons[key] then
                    button.parent.buttons[key].setDisable()
                end
            end
        end

        button.parent.selector = ""
    end

    selectorFrame.doSelect = function(button, selector)
        if button.parent.selector == "" then
            button.parent.selector = selector
            return
        end

        button.parent.selector = button.parent.selector .. " " .. selector
    end

    selectorFrame.doReset = function(frame)
        if frame.selector == "" then
            return
        end

        local groups = MultiBot.doSplit(frame.selector, " ")
        for _, tag in ipairs(groups) do
            frame.buttons[tag].setDisable()
        end
        frame.selector = ""
    end
end

local function createBrowseButton(selectorFrame)
    local browseButton = selectorFrame.addButton("Browse", 270, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_browse.blp", MultiBot.L("tips.rtsc.browse"))

    browseButton.doRight = function(button)
        MultiBot.ActionToGroup("rtsc cancel")
        button.parent.doReset(button.parent)
    end

    browseButton.doLeft = function(button)
        local frame = button.parent

        if button.state then
            for _, tag in ipairs(RTSC_BROWSE_ROLES) do
                frame.buttons[tag].doShow()
            end
            for _, tag in ipairs(RTSC_BROWSE_GROUPS) do
                frame.buttons[tag].doHide()
            end
            button.state = false
            return
        end

        for _, tag in ipairs(RTSC_BROWSE_ROLES) do
            frame.buttons[tag].doHide()
        end
        for _, tag in ipairs(RTSC_BROWSE_GROUPS) do
            frame.buttons[tag].doShow()
        end
        button.state = true
    end

    return browseButton
end

function MultiBot.InitializeRTSCUI(tMultiBar)
    if not tMultiBar or not tMultiBar.addFrame then
        return nil
    end

    local rtscFrame = tMultiBar.addFrame(RTSC_FRAME_NAME, RTSC_FRAME_X, RTSC_FRAME_Y, 32).doHide()

    local rootButton = rtscFrame
        .addButton("RTSC", 0, 0, "ability_hunter_markedfordeath", MultiBot.L("tips.rtsc.master"), "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")

    rootButton.doRight = function()
        MultiBot.ActionToGroup("co +rtsc,+guard,?")
        MultiBot.ActionToGroup("nc +rtsc,+guard,?")
    end

    rootButton.doLeft = function(button)
        local selectorFrame = button.parent.frames[RTSC_SELECTOR_NAME]
        selectorFrame.doReset(selectorFrame)
    end

    local selectorFrame = rtscFrame.addFrame(RTSC_SELECTOR_NAME, 0, RTSC_SELECTOR_Y, RTSC_SELECTOR_HEIGHT)
    bindSelectorLogic(selectorFrame)

    for index = 9, 1, -1 do
        createStoragePair(selectorFrame, index)
    end

    for _, definition in ipairs(RTSC_GROUP_BUTTONS) do
        createSelectorButton(selectorFrame, definition)
    end

    for _, definition in ipairs(RTSC_ROLE_BUTTONS) do
        createSelectorButton(selectorFrame, definition)
    end

    local allButton = selectorFrame
        .addButton("@all", 240, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc.blp", MultiBot.L("tips.rtsc.all"), "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")

    allButton.doRight = function(button)
        MultiBot.ActionToGroup("rtsc select")
        button.parent.doReset(button.parent)
    end

    allButton.doLeft = function(button)
        MultiBot.ActionToGroup("rtsc select")
        button.parent.doReset(button.parent)
    end

    local browseButton = createBrowseButton(selectorFrame)

    return {
        frame = rtscFrame,
        selectorFrame = selectorFrame,
        rootButton = rootButton,
        browseButton = browseButton,
        allButton = allButton,
    }
end