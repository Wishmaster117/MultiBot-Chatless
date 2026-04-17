if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local CopyFrame = MultiBot.GameObjectCopyFrame or {}
MultiBot.GameObjectCopyFrame = CopyFrame

local function focusAndSelect(editor)
    local editBox = editor and editor.editBox
    if editBox and editBox.SetFocus then
        editBox:SetFocus()
    end
    if editBox and editBox.HighlightText then
        editBox:HighlightText()
    end
end

function MultiBot.ShowGameObjectCopyBox()
    local frame = MultiBot.InitializeGameObjectCopyFrame()
    if not frame then
        return
    end

    if MultiBot.GameObjPopup and MultiBot.GameObjPopup.window and MultiBot.GameObjPopup.window:IsShown() then
        MultiBot.GameObjPopup.window:Hide()
    end

    local bots = Shared.CollectSortedGameObjectBots and Shared.CollectSortedGameObjectBots() or {}
    local text = Shared.BuildGameObjectCopyText and Shared.BuildGameObjectCopyText(bots) or ""
    frame.editor:SetText(text)
    frame.window:Show()
    focusAndSelect(frame.editor)
end

function MultiBot.InitializeGameObjectCopyFrame()
    if CopyFrame.window then
        return CopyFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_GameObjCopyBox") or nil
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.L("tips.quests.gobctrlctocopy"))
    window:SetWidth(420)
    window:SetHeight(300)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "GameObjCopy") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "gameobject_copy") end

    local editor = aceGUI:Create("MultiLineEditBox")
    editor:SetLabel("")
    editor:SetNumLines(14)
    editor:DisableButton(true)
    window:AddChild(editor)

    if editor.editBox and editor.editBox.SetFontObject then
        editor.editBox:SetFontObject(ChatFontNormal)
    end
    if editor.editBox and editor.editBox.SetTextInsets then
        editor.editBox:SetTextInsets(6, 6, 6, 6)
    end

    CopyFrame.window = window
    CopyFrame.editor = editor
    CopyFrame.aceGUI = aceGUI
    MultiBot.GameObjCopyBox = CopyFrame
    return CopyFrame
end