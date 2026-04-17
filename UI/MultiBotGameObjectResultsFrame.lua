if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local ResultsFrame = MultiBot.GameObjectResultsFrame or {}
MultiBot.GameObjectResultsFrame = ResultsFrame

local function clearResults(frame)
    if frame and frame.scroll then
        frame.scroll:ReleaseChildren()
    end
end

local function addLabel(aceGUI, parent, text)
    local label = aceGUI:Create("Label")
    label:SetFullWidth(true)
    label:SetText(text or "")
    parent:AddChild(label)
    return label
end

local function renderGameObjectResults(frame)
    clearResults(frame)

    local aceGUI = frame.aceGUI
    local bots = Shared.CollectSortedGameObjectBots and Shared.CollectSortedGameObjectBots() or {}

    for _, bot in ipairs(bots) do
        addLabel(aceGUI, frame.scroll, "Bot: |cff80ff80" .. bot .. "|r")

        for _, textLine in ipairs(Shared.GetGameObjectEntries(bot) or {}) do
            if Shared.IsDashedSectionHeader(textLine) then
                addLabel(aceGUI, frame.scroll, "|cffffff66" .. textLine .. "|r")
            else
                addLabel(aceGUI, frame.scroll, "   " .. textLine)
            end
        end

        addLabel(aceGUI, frame.scroll, " ")
    end

    if #bots == 0 then
        addLabel(aceGUI, frame.scroll, MultiBot.L("tips.quests.gobnosearchdata") or "")
    end
end

function MultiBot.ShowGameObjectPopup()
    local frame = MultiBot.InitializeGameObjectResultsFrame()
    if not frame then
        return
    end

    renderGameObjectResults(frame)
    frame.window:Show()
end

function MultiBot.InitializeGameObjectResultsFrame()
    if ResultsFrame.window then
        return ResultsFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_GameObjPopup") or nil
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.L("tips.quests.gobsfound"))
    window:SetWidth(420)
    window:SetHeight(380)
    window:EnableResize(false)
    window:SetLayout("List")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "GameObjPopup") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "gameobject_popup") end

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetHeight(280)
    scroll:SetLayout("List")
    window:AddChild(scroll)

    local copyButton = aceGUI:Create("Button")
    copyButton:SetText(MultiBot.L("tips.quests.gobselectall"))
    copyButton:SetWidth(170)
    copyButton:SetCallback("OnClick", function()
        if MultiBot.ShowGameObjectCopyBox then
            MultiBot.ShowGameObjectCopyBox()
        end
    end)
    window:AddChild(copyButton)

    ResultsFrame.window = window
    ResultsFrame.scroll = scroll
    ResultsFrame.copyButton = copyButton
    ResultsFrame.aceGUI = aceGUI
    MultiBot.GameObjPopup = ResultsFrame
    return ResultsFrame
end