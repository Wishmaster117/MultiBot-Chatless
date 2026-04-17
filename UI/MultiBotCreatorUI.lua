if not MultiBot then return end

local GENDER_BUTTONS = {
    { label = "Male", gender = "male", icon = "Interface\\Icons\\INV_Misc_Toy_02", tip = "tips.creator.gendermale" },
    { label = "Femelle", gender = "female", icon = "Interface\\Icons\\INV_Misc_Toy_04", tip = "tips.creator.genderfemale" },
    { label = "Aléatoire", gender = nil, icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", tip = "tips.creator.genderrandom" },
}

local CLASS_BUTTONS = {
    { name = "Warrior", y = 0, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_warrior.blp", cmd = "warrior" },
    { name = "Warlock", y = 30, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_warlock.blp", cmd = "warlock" },
    { name = "Shaman", y = 60, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_shaman.blp", cmd = "shaman" },
    { name = "Rogue", y = 90, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_rogue.blp", cmd = "rogue" },
    { name = "Priest", y = 120, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_priest.blp", cmd = "priest" },
    { name = "Paladin", y = 150, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_paladin.blp", cmd = "paladin" },
    { name = "Mage", y = 180, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_mage.blp", cmd = "mage" },
    { name = "Hunter", y = 210, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_hunter.blp", cmd = "hunter" },
    { name = "Druid", y = 240, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_druid.blp", cmd = "druid" },
    { name = "DeathKnight", y = 270, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_deathknight.blp", cmd = "dk" },
}

local CREATOR_FRAME_NAME = "Creator"
local CREATOR_ROOT_ICON = "inv_helmet_145a"
local CREATOR_FRAME_X = -2
local CREATOR_FRAME_Y = 34
local GENDER_BUTTON_X = 30
local GENDER_BUTTON_STEP = 30

local function hideGenderButtons(buttons)
    for _, button in ipairs(buttons or {}) do
        if button.genderButtons then
            for _, genderButton in ipairs(button.genderButtons) do
                genderButton:Hide()
            end
        end
    end
end

local function addClassButton(creatorFrame, definition)
    local classButton = creatorFrame.addButton(
        definition.name,
        0,
        definition.y,
        definition.icon,
        MultiBot.L("tips.creator." .. string.lower(definition.name))
    )

    classButton.genderButtons = {}

    for index, genderDefinition in ipairs(GENDER_BUTTONS) do
        local genderButton = creatorFrame.addButton(
            genderDefinition.label,
            GENDER_BUTTON_X + (index - 1) * GENDER_BUTTON_STEP,
            definition.y,
            genderDefinition.icon,
            MultiBot.L(genderDefinition.tip)
        )

        genderButton:Hide()
        genderButton.doLeft = function()
            MultiBot.AddClassToTarget(definition.cmd, genderDefinition.gender)
        end

        table.insert(classButton.genderButtons, genderButton)
    end

    classButton.doLeft = function(owner)
        local shouldShow = not owner.genderButtons[1]:IsShown()

        hideGenderButtons(creatorFrame.classButtons)

        for _, genderButton in ipairs(owner.genderButtons) do
            if shouldShow then
                genderButton:Show()
            else
                genderButton:Hide()
            end
        end
    end

    creatorFrame.classButtons = creatorFrame.classButtons or {}
    table.insert(creatorFrame.classButtons, classButton)

    return classButton
end

local function initializeTarget()
    if not UnitExists("target") or not UnitIsPlayer("target") then
        SendChatMessage(MultiBot.L("info.target"), "SAY")
        return
    end

    local name = UnitName("target")
    if MultiBot.isRoster("players", name) then
        SendChatMessage(MultiBot.L("info.players"), "SAY")
        return
    end

    if MultiBot.isRoster("members", name) then
        SendChatMessage(MultiBot.L("info.members"), "SAY")
        return
    end

    MultiBot.InitAuto(name)
end

local function initializeGroup()
    local function iterate(unitPrefix, count)
        for index = 1, count do
            local name = UnitName(unitPrefix .. index)
            if name and name ~= UnitName("player") then
                if MultiBot.isRoster("players", name) then
                    SendChatMessage(MultiBot.doReplace(MultiBot.L("info.player"), "NAME", name), "SAY")
                elseif MultiBot.isRoster("members", name) then
                    SendChatMessage(MultiBot.doReplace(MultiBot.L("info.member"), "NAME", name), "SAY")
                else
                    MultiBot.InitAuto(name)
                end
            end
        end
    end

    if IsInRaid() then
        iterate("raid", GetNumGroupMembers())
        return
    end

    if IsInGroup() then
        iterate("party", GetNumSubgroupMembers())
        return
    end

    SendChatMessage(MultiBot.L("info.group"), "SAY")
end

function MultiBot.InitializeCreatorUI(tLeft)
    if not tLeft or not tLeft.addButton or not tLeft.addFrame then
        return nil
    end

    local rootButton = tLeft.addButton("Creator", 0, 0, CREATOR_ROOT_ICON, MultiBot.L("tips.creator.master")).doHide()
    local creatorFrame = tLeft.addFrame(CREATOR_FRAME_NAME, CREATOR_FRAME_X, CREATOR_FRAME_Y)
    creatorFrame:Hide()

    rootButton.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames[CREATOR_FRAME_NAME])
        MultiBot.frames["MultiBar"].frames["Units"]:Hide()
    end

    creatorFrame:HookScript("OnHide", function(self)
        hideGenderButtons(self.classButtons)
    end)

    for _, definition in ipairs(CLASS_BUTTONS) do
        addClassButton(creatorFrame, definition)
    end

    creatorFrame.addButton("Inspect", 0, 300, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", MultiBot.L("tips.creator.inspect"))
        .doLeft = function()
            if UnitExists("target") and UnitIsPlayer("target") then
                InspectUnit("target")
                return
            end

            SendChatMessage(MultiBot.L("tips.creator.notarget"), "SAY")
        end

    local initButton = creatorFrame.addButton("Init", 0, 330, "inv_misc_enggizmos_27", MultiBot.L("tips.creator.init"))
    initButton.doLeft = initializeTarget
    initButton.doRight = initializeGroup

    return {
        rootButton = rootButton,
        frame = creatorFrame,
    }
end