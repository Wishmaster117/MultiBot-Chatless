if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local PROMPT
local PROMPT_WINDOW_WIDTH = 280
local PROMPT_WINDOW_HEIGHT = 108
local PROMPT_OK_BUTTON_WIDTH = 100
local PROMPT_ANCHOR_GAP = 12

local function PositionPromptBesideFrame(anchorFrame)
    if not PROMPT or not PROMPT.window or not PROMPT.window.frame or not anchorFrame then
        return
    end

    local promptFrame = PROMPT.window.frame
    if not promptFrame.ClearAllPoints or not promptFrame.SetPoint then
        return
    end

    promptFrame:ClearAllPoints()

    local parentWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
    local anchorRight = anchorFrame.GetRight and anchorFrame:GetRight() or nil
    local promptWidth = promptFrame.GetWidth and promptFrame:GetWidth() or PROMPT_WINDOW_WIDTH

    local placeLeft = false
    if parentWidth and parentWidth > 0 and anchorRight then
        if (anchorRight + PROMPT_ANCHOR_GAP + promptWidth) > (parentWidth - 8) then
            placeLeft = true
        end
    end

    if placeLeft then
        promptFrame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -PROMPT_ANCHOR_GAP, 0)
    else
        promptFrame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", PROMPT_ANCHOR_GAP, 0)
    end
end

function ShowPrompt(title, onOk, defaultText, anchorFrame)
    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MBUniversalPrompt") or nil
    if not aceGUI then
        return
    end

    if not PROMPT then
        local window = aceGUI:Create("Window")
        if not window then
            return
        end

        window:SetTitle(title or "Enter Value")
        window:SetWidth(PROMPT_WINDOW_WIDTH)
        window:SetHeight(PROMPT_WINDOW_HEIGHT)
        window:EnableResize(false)
        window:SetLayout("Flow")
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            window.frame:SetFrameStrata(strataLevel)
        end
        if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
        if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "UniversalPrompt") end
        if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "universal_prompt") end
        window.frame:SetClampedToScreen(true)

        local edit = aceGUI:Create("EditBox")
        edit:SetLabel("")
        edit:SetFullWidth(true)
        edit:DisableButton(true)
        if Shared.ApplyEditBoxStyle then
            Shared.ApplyEditBoxStyle(edit)
        end
        window:AddChild(edit)

        local okButton = aceGUI:Create("Button")
        okButton:SetText(OKAY)
        okButton:SetWidth(PROMPT_OK_BUTTON_WIDTH)
        window:AddChild(okButton)

        PROMPT = {
            window = window,
            edit = edit,
            okButton = okButton,
        }
    end

    PROMPT.window:SetTitle(title or "Enter Value")
    PROMPT.window:Show()

    if anchorFrame then
        PositionPromptBesideFrame(anchorFrame)
    end
    PROMPT.edit:SetText(defaultText or "")

    local editBox = PROMPT.edit and PROMPT.edit.editbox
    if editBox and editBox.SetFocus then
        editBox:SetFocus()
    end

    PROMPT.okButton:SetCallback("OnClick", function()
        local value = PROMPT.edit:GetText()
        if not value or value == "" then
            UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.gobsnameerror"), 1, 0.2, 0.2, 1)
            return
        end

        onOk(value)
        PROMPT.window:Hide()
    end)

    PROMPT.edit:SetCallback("OnEnterPressed", function()
        local button = PROMPT.okButton and PROMPT.okButton.button
        if button and button.Click then
            button:Click()
        end
    end)
end

MultiBot.ShowPrompt = ShowPrompt