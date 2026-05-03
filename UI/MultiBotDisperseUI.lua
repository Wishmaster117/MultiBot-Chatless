local function L(key, fallback)
    if MultiBot and MultiBot.L then
        return MultiBot.L(key, fallback)
    end

    return fallback or key
end

local function TrimText(value)
    if type(value) ~= "string" then
        return ""
    end

    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizeDistance(value)
    local distance = tonumber(TrimText(value))
    if not distance or distance <= 0 then
        return nil
    end

    if distance > 100 then
        return nil
    end

    distance = math.floor(distance * 10 + 0.5) / 10
    if distance == math.floor(distance) then
        return tostring(math.floor(distance))
    end

    return tostring(distance)
end

local function RunDisperseCommand(command)
    if not MultiBot or not MultiBot.Comm or not MultiBot.Comm.RunPositionCommand then
        DEFAULT_CHAT_FRAME:AddMessage(L("disperse.bridge.required", "Position bridge is not connected."))
        return false
    end

    local ok = MultiBot.Comm.RunPositionCommand("ALL", "", command)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage(L("disperse.bridge.required", "Position bridge is not connected."))
    end

    return ok
end

function MultiBot.BuildDisperseUI(tLeft)
    if not tLeft or MultiBot.frames.disperse then
        return MultiBot.frames.disperse
    end

    local lastDistance = "10"
    local button
    local menu = tLeft.addFrame("DisperseMenu", -34, 34, 24, 56, 96).doHide()
    local menuOpen = false
    menu._mbDropdownManaged = true
    menu:SetWidth(56)
    menu:SetHeight(96)

    local input = CreateFrame("EditBox", "MultiBotDisperseDistanceEditBox", menu, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetMaxLetters(3)
    input:SetWidth(40)
    input:SetHeight(20)
    input:SetPoint("TOPLEFT", menu, "TOPLEFT", 23, -23)
    input:SetText(lastDistance)
    input:SetFrameLevel(menu:GetFrameLevel() + 3)
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    local function setDistance()
        local distance = NormalizeDistance(input:GetText())
        if not distance then
            DEFAULT_CHAT_FRAME:AddMessage(L("disperse.invalid_distance", "Enter a distance between 1 and 100 yards."))
            return
        end

        lastDistance = distance
        input:SetText(distance)
        input:ClearFocus()
        RunDisperseCommand("disperse set " .. distance)
    end

    input:SetScript("OnEnterPressed", function()
        setDistance()
    end)

    local setButton = menu.addButton("Set", -3.5, 1, "spell_nature_wispsplode", L("tips.disperse.set", "Set disperse distance"))
    setButton.doLeft = setDistance

    local disableButton = menu.addButton("Disable", -3.5, 27, "spell_nature_sleep", L("tips.disperse.disable", "Disable disperse"))
    disableButton.doLeft = function()
        input:ClearFocus()
        RunDisperseCommand("disperse disable")
    end

    local function updateClickBlocker()
        if MultiBot.RequestClickBlockerUpdate then
            MultiBot.RequestClickBlockerUpdate(menu)
        end
    end

    local function setDisperseMenuChildrenShown(shown)
        if shown then
            input:Show()
            setButton:doShow()
            disableButton:doShow()

            if button then
                button.setEnable()
            end
        else
            input:Hide()
            setButton:doHide()
            disableButton:doHide()

            if button then
                button.setDisable()
            end
       end

        updateClickBlocker()
    end

    local function hideDisperseMenu()
        input:ClearFocus()
        menuOpen = false
        menu:Hide()
        setDisperseMenuChildrenShown(false)
    end

    local function showDisperseMenu()
        menuOpen = true
        input:SetText(lastDistance)
        menu:Show()
        setDisperseMenuChildrenShown(true)
    end

    menu:HookScript("OnHide", function()
        menuOpen = false
        setDisperseMenuChildrenShown(false)
    end)

    MultiBot.frames.disperseMenu = menu

    button = tLeft.addButton("Disperse", -34, 0, "spell_nature_wispsplode", L("tips.disperse.main", "Disperse")).setDisable().doHide()
    button.doLeft = function()
        if menuOpen then
            hideDisperseMenu()
        else
            showDisperseMenu()
        end
    end

    button.doRight = function()
        hideDisperseMenu()
        RunDisperseCommand("disperse disable")
    end

    hideDisperseMenu()

    MultiBot.frames.disperse = button
    return button
end

function MultiBot.InitializeDisperseUI()
    if not MultiBot.frames or not MultiBot.frames.tLeft then
        return nil
    end

    return MultiBot.BuildDisperseUI(MultiBot.frames.tLeft)
end