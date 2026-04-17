if not MultiBot then return end

local GM_UI_BUTTONS = {
    {
        label = "Itemus",
        y = 68,
        icon = "inv_box_01",
        tip = "tips.game.itemus",
        click = function()
            local itemus = MultiBot.itemus or (MultiBot.InitializeItemusFrame and MultiBot.InitializeItemusFrame())
            if not itemus then
                return
            end

            if itemus.Toggle then
                itemus:Toggle()
                return
            end

            if MultiBot.ShowHideSwitch(itemus) and itemus.addItems then
                itemus.addItems()
            end
        end,
    },
    {
        label = "Iconos",
        y = 102,
        icon = "inv_mask_01",
        tip = "tips.game.iconos",
        click = function()
            local iconos = MultiBot.iconos or (MultiBot.InitializeIconosFrame and MultiBot.InitializeIconosFrame())
            if not iconos then
                return
            end

            if iconos.Toggle then
                iconos:Toggle()
                return
            end

            if MultiBot.ShowHideSwitch(iconos) and iconos.addIcons then
                iconos:addIcons()
            end
        end,
    },
    {
        label = "Summon",
        y = 136,
        icon = "spell_holy_prayerofspirit",
        tip = "tips.game.summon",
        click = function()
            MultiBot.doDotWithTarget(".summon")
        end,
    },
    {
        label = "Appear",
        y = 170,
        icon = "spell_holy_divinespirit",
        tip = "tips.game.appear",
        click = function()
            MultiBot.doDotWithTarget(".appear")
        end,
    },
}

local MEMORY_GEMS = {
    { label = "Red", x = 0, icon = "inv_jewelcrafting_gem_16" },
    { label = "Green", x = 30, icon = "inv_jewelcrafting_gem_13" },
    { label = "Blue", x = 60, icon = "inv_jewelcrafting_gem_17" },
}

local function ensureDeleteSavedVariablesDialog()
    StaticPopupDialogs["MULTIBOT_DELETE_SV"] = {
        text = MultiBot.L("tips.game.delsvwarning"),
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            if MultiBot.ClearGlobalBotStore then
                MultiBot.ClearGlobalBotStore()
            elseif wipe then
                wipe(MultiBotGlobalSave)
            else
                for key in pairs(MultiBotGlobalSave) do
                    MultiBotGlobalSave[key] = nil
                end
            end

            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

local function addMemoryGemButton(portalFrame, definition)
    local gem = portalFrame.addButton(
        definition.label,
        definition.x,
        0,
        definition.icon,
        MultiBot.doReplace(MultiBot.L("tips.game.memory"), "ABOUT", MultiBot.L("info.location"))
    )

    gem:setDisable()
    gem.goMap, gem.goX, gem.goY, gem.goZ = "", 0, 0, 0

    gem.doRight = function(button)
        if not button.state then
            SendChatMessage(MultiBot.L("info.itlocation"), "SAY")
            return
        end

        button.tip = MultiBot.doReplace(MultiBot.L("tips.game.memory"), "ABOUT", MultiBot.L("info.location"))
        button:setDisable()
    end

    gem.doLeft = function(button)
        local player = MultiBot.getBot(UnitName("player"))
        player.waitFor = player.waitFor or ""

        if player.waitFor ~= "" then
            SendChatMessage(MultiBot.L("info.saving"), "SAY")
            return
        end

        if button.state then
            SendChatMessage(".go xyz " .. button.goX .. " " .. button.goY .. " " .. button.goZ .. " " .. button.goMap, "SAY")
            return
        end

        player.memory = button
        player.waitFor = "COORDS"
        SendChatMessage(".gps", "SAY")
    end

    return gem
end

function MultiBot.ShowDeleteSVPrompt()
    if MultiBot.GM == false then
        SendChatMessage(MultiBot.L("info.rights"), "SAY")
        return
    end

    ensureDeleteSavedVariablesDialog()
    StaticPopup_Show("MULTIBOT_DELETE_SV")
end

function MultiBot.BuildGmUI(tMultiBar)
    if not tMultiBar or not tMultiBar.addButton or not tMultiBar.addFrame then
        return nil
    end

    local mainButton = tMultiBar.addButton("Masters", 38, 0, "mail_gmicon", MultiBot.L("tips.game.master"))
    mainButton:doHide()

    mainButton.doLeft = function(owner)
        MultiBot.ShowHideSwitch(owner.parent.frames["Masters"])
    end

    mainButton.doRight = function()
        MultiBot.doSlash("/MultiBot", "")
    end

    local mastersFrame = tMultiBar.addFrame("Masters", 36, 38)
    mastersFrame:Hide()

    local necroButton = mastersFrame.addButton(
        "NecroNet",
        0,
        0,
        "achievement_bg_xkills_avgraveyard",
        MultiBot.L("tips.game.necronet")
    )
    necroButton:setDisable()

    necroButton.doLeft = function(button)
        if button.state then
            MultiBot.necronet.state = false
            for _, value in pairs(MultiBot.necronet.buttons) do
                value:Hide()
            end
            button:setDisable()
            return
        end

        MultiBot.necronet.cont = 0
        MultiBot.necronet.area = 0
        MultiBot.necronet.zone = 0
        MultiBot.necronet.state = true
        button:setEnable()
    end

    local portalButton = mastersFrame.addButton("Portal", 0, 34, "inv_box_02", MultiBot.L("tips.game.portal"))
    local portalFrame = mastersFrame.addFrame("Portal", 30, 36)
    portalFrame:Hide()

    portalButton.doLeft = function()
        MultiBot.ShowHideSwitch(portalFrame)
    end

    for _, definition in ipairs(MEMORY_GEMS) do
        addMemoryGemButton(portalFrame, definition)
    end

    for _, definition in ipairs(GM_UI_BUTTONS) do
        mastersFrame.addButton(definition.label, 0, definition.y, definition.icon, MultiBot.L(definition.tip)).doLeft = definition.click
    end

    mastersFrame.addButton("DelSV", 0, 204, "ability_golemstormbolt", MultiBot.L("tips.game.delsv"), "ActionButtonTemplate")
        .doLeft = function()
            MultiBot.ShowDeleteSVPrompt()
        end

    MultiBot.RegisterCommandAliases("MULTIBOTDELSV", function()
        if MultiBot.ShowDeleteSVPrompt then
            MultiBot.ShowDeleteSVPrompt()
        end
    end, { "mbdelsv" })

    ensureDeleteSavedVariablesDialog()

    return {
        mainButton = mainButton,
        mastersFrame = mastersFrame,
        portalFrame = portalFrame,
        necroButton = necroButton,
    }
end