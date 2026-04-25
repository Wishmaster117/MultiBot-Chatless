-- Talents/Glyphs frame module extracted from Core/MultiBotInit.lua

if not MultiBot then return end

local function getTalentFrameAceGUI()
    if MultiBot.GetAceGUI then
        local ace = MultiBot.GetAceGUI()
        if type(ace) == "table" and type(ace.Create) == "function" then
            return ace
        end
    end

    if type(LibStub) == "table" then
        local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
        if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
            return aceGUI
        end
    end

    return nil
end

local function resolveTalentFrameAceGUI(missingDepMessage)
    local aceGUI = getTalentFrameAceGUI()
    if not aceGUI and missingDepMessage and UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(missingDepMessage, 1, 0.2, 0.2, 1)
    end

    return aceGUI
end

local _talentAceEscapeIndex = 0
local function registerTalentFrameEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    _talentAceEscapeIndex = _talentAceEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Popup"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, _talentAceEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function bindTalentFramePosition(window, persistenceKey)
    if not window or not window.frame or not persistenceKey then
        return
    end

    local positions = nil
    if MultiBot.Store and MultiBot.Store.GetUIChildStore then
        positions = MultiBot.Store.GetUIChildStore("popupPositions")
    end

    if not positions then
        local profile = MultiBot.db and MultiBot.db.profile
        if not profile then
            return
        end

        positions = profile.ui and profile.ui.popupPositions
    end

    local saved = positions and positions[persistenceKey]
    if saved and saved.point then
        window.frame:ClearAllPoints()
        window.frame:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
    end

    if window.__mbPositionHooked then
        return
    end

    window.__mbPositionHooked = true
    window.frame:HookScript("OnDragStop", function(frame)
        local point, _, _, x, y = frame:GetPoint(1)
        if point then
            local writablePositions = nil
            if MultiBot.Store and MultiBot.Store.EnsureUIChildStore then
                writablePositions = MultiBot.Store.EnsureUIChildStore("popupPositions")
            else
                local profile = MultiBot.db and MultiBot.db.profile
                if profile then
                    profile.ui = profile.ui or {}
                    profile.ui.popupPositions = profile.ui.popupPositions or {}
                    writablePositions = profile.ui.popupPositions
                end
            end
            if writablePositions then
                writablePositions[persistenceKey] = { point = point, x = x or 0, y = y or 0 }
            end
        end
    end)
end

local function setTalentFrameCloseToHide(window)
    if window and window.SetCallback then
        window:SetCallback("OnClose", function(widget)
            widget:Hide()
        end)
    end
end

local function setTalentButtonEnabled(botName, isEnabled)
    if type(botName) ~= "string" or botName == "" then
        return
    end

    local unitsRoot = MultiBot
        and MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]
    local unitFrame = unitsRoot and unitsRoot.frames and unitsRoot.frames[botName]
    if not unitFrame or not unitFrame.getButton then
        return
    end

    local button = unitFrame.getButton("Talent")
    if not button then
        return
    end

    if isEnabled and button.setEnable then
        button.setEnable()
        return
    end

    if button.setDisable then
        button.setDisable()
    end
end

local function syncTalentButtonStateOnHide()
    local talentFrame = MultiBot and MultiBot.talent
    if not talentFrame then
        return
    end

    setTalentButtonEnabled(talentFrame.name, false)
end

-- TODO = Mettre une variable pour deplacer l'icone fallback dans le cadre
local DEFAULT_TALENT_HOST_CONTENT_LAYOUT = {
    CONTENT_TUNE_X = 0, -- Décalage horizontal global de tout le contenu dans la fenêtre host ACE.
    CONTENT_TUNE_Y = 0, -- Décalage vertical global de tout le contenu dans la fenêtre host ACE.
    POINTS_TEXT_TUNE_X = -20, -- Ajuste horizontalement le texte "Points" (points talents restants).
    POINTS_TEXT_TUNE_Y = 90, -- Ajuste verticalement le texte "Points" (points talents restants).
    TITLE_TEXT_TUNE_X = 0, -- Ajuste horizontalement le titre Talents/Glyphes affiché dans le contenu.
    TITLE_TEXT_TUNE_Y = 0, -- Ajuste verticalement le titre Talents/Glyphes affiché dans le contenu.
    TALENT_TREES_TUNE_X = -24, -- Décalage horizontal appliqué aux 3 arbres de talents (Talents + Custom Talents).
    TALENT_TREES_TUNE_Y = 85, -- Décalage vertical appliqué aux 3 arbres de talents (Talents + Custom Talents).
    GLYPH_OVERVIEW_TUNE_X = -25, -- Décalage horizontal du panneau principal de l'onglet Glyphes.
    GLYPH_OVERVIEW_TUNE_Y = 75, -- Décalage vertical du panneau principal de l'onglet Glyphes.
    GLYPH_SOCKETS_TUNE_X = 0, -- Décalage horizontal de toutes les sockets dans le panneau Glyphes.
    GLYPH_SOCKETS_TUNE_Y = 0, -- Décalage vertical de toutes les sockets dans le panneau Glyphes.
    GLYPH_ICON_TUNE_X = -9, -- Décalage horizontal de l'icône affichée dans une socket de glyphe.
    GLYPH_ICON_TUNE_Y = 8, -- Décalage vertical de l'icône affichée dans une socket de glyphe.
    GLYPH_ICON_SIZE_SCALE = 0.60, -- Échelle de taille des icônes glyphes (item/spell normal) relative à la socket.
    GLYPH_FALLBACK_ICON_SIZE_SCALE = 0.66, -- Échelle spécifique de l'icône fallback UI-GlyphFrame-Glow.blp relative à la socket.
}

function MultiBot.InitializeTalentFrameModule()
    if MultiBot.talent and MultiBot.talent.__moduleInitialized then
        return
    end

    if not MultiBot.talent or type(MultiBot.talent.addFrame) ~= "function" then
        MultiBot.TalentHostContentLayout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local layout = MultiBot.TalentHostContentLayout

        MultiBot.talent = MultiBot.newFrame(MultiBot, -104, -276, 28, 1024, 1024)
        MultiBot.talent.addText("Points", MultiBot.L("info.talent.Points"), "CENTER", -228 + (layout.POINTS_TEXT_TUNE_X or 0), -8 + (layout.POINTS_TEXT_TUNE_Y or 0), 13)
        MultiBot.talent.addText("Title", MultiBot.L("info.talent.Title"), "CENTER", -228 + (layout.TITLE_TEXT_TUNE_X or 0), 491 + (layout.TITLE_TEXT_TUNE_Y or 0), 13)
        MultiBot.talent:SetMovable(true)
        MultiBot.talent:Hide()
        MultiBot.talent.movButton("Move", -960, 960, 64, MultiBot.L("tips.move.talent"))
    end

    MultiBot.TalentHostContentLayout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT

    MultiBot.talent.tabTextures = MultiBot.talent.tabTextures or {}
    MultiBot.TalentFrameKeys = MultiBot.TalentFrameKeys or {
        TALENT_TREE_1 = "TALENT_TREE_1",
        TALENT_TREE_2 = "TALENT_TREE_2",
        TALENT_TREE_3 = "TALENT_TREE_3",
        GLYPH_OVERVIEW = "GLYPH_OVERVIEW",
        TALENTS = "BOTTOM_TAB_TALENTS",
        GLYPHS = "BOTTOM_TAB_GLYPHS",
        CUSTOM_TALENTS = "BOTTOM_TAB_CUSTOM_TALENTS",
        CUSTOM_GLYPHS = "BOTTOM_TAB_CUSTOM_GLYPHS",
        COPY = "BOTTOM_TAB_COPY",
        APPLY = "BOTTOM_TAB_APPLY",
    }
    MultiBot.TalentTabKeys = MultiBot.TalentTabKeys or {
        TALENTS = MultiBot.TalentFrameKeys.TALENTS,
        GLYPHS = MultiBot.TalentFrameKeys.GLYPHS,
        CUSTOM_TALENTS = MultiBot.TalentFrameKeys.CUSTOM_TALENTS,
        CUSTOM_GLYPHS = MultiBot.TalentFrameKeys.CUSTOM_GLYPHS,
        COPY = MultiBot.TalentFrameKeys.COPY,
        APPLY = MultiBot.TalentFrameKeys.APPLY,
    }
    MultiBot.TalentTabGroups = MultiBot.TalentTabGroups or {
        ALL = {
            MultiBot.TalentFrameKeys.TALENT_TREE_1,
            MultiBot.TalentFrameKeys.TALENT_TREE_2,
            MultiBot.TalentFrameKeys.TALENT_TREE_3,
            MultiBot.TalentFrameKeys.GLYPH_OVERVIEW,
            MultiBot.TalentFrameKeys.TALENTS,
            MultiBot.TalentFrameKeys.GLYPHS,
            MultiBot.TalentFrameKeys.CUSTOM_TALENTS,
            MultiBot.TalentFrameKeys.CUSTOM_GLYPHS,
            MultiBot.TalentFrameKeys.COPY,
            MultiBot.TalentFrameKeys.APPLY,
        },
        CHROME = {
            MultiBot.TalentFrameKeys.TALENTS,
            MultiBot.TalentFrameKeys.GLYPHS,
            MultiBot.TalentFrameKeys.CUSTOM_TALENTS,
            MultiBot.TalentFrameKeys.CUSTOM_GLYPHS,
            MultiBot.TalentFrameKeys.COPY,
            MultiBot.TalentFrameKeys.APPLY,
        },
        BOTTOM = {
            MultiBot.TalentFrameKeys.TALENTS,
            MultiBot.TalentFrameKeys.GLYPHS,
            MultiBot.TalentFrameKeys.CUSTOM_TALENTS,
            MultiBot.TalentFrameKeys.CUSTOM_GLYPHS,
            MultiBot.TalentFrameKeys.COPY,
            MultiBot.TalentFrameKeys.APPLY,
        },
        INACTIVE_DEFAULT = {
            MultiBot.TalentFrameKeys.GLYPHS,
            MultiBot.TalentFrameKeys.CUSTOM_TALENTS,
            MultiBot.TalentFrameKeys.CUSTOM_GLYPHS,
            MultiBot.TalentFrameKeys.COPY,
            MultiBot.TalentFrameKeys.APPLY,
        },
        TALENT_TREES = {
            MultiBot.TalentFrameKeys.TALENT_TREE_1,
            MultiBot.TalentFrameKeys.TALENT_TREE_2,
            MultiBot.TalentFrameKeys.TALENT_TREE_3,
        },
        GLYPH = MultiBot.TalentFrameKeys.GLYPH_OVERVIEW,
    }
    MultiBot.TalentTabDefaults = MultiBot.TalentTabDefaults or { ACTIVE = MultiBot.TalentFrameKeys.TALENTS, ACTIVE_LABEL = "Talents" }
    MultiBot.TalentTabLabels = MultiBot.TalentTabLabels or { GLYPHS = "Glyphs", CUSTOM_TALENTS = "Custom Talents", CUSTOM_GLYPHS = "Custom Glyphs", COPY = MultiBot.L("info.talent.Copy"), APPLY = MultiBot.L("info.talent.Apply") }
    MultiBot.TalentTabStates = MultiBot.TalentTabStates or { TALENTS = "talents", GLYPHS = "glyphs", CUSTOM_TALENTS = "custom_talents", CUSTOM_GLYPHS = "custom_glyphs" }
    MultiBot.TalentTabContextProfiles = MultiBot.TalentTabContextProfiles or {
        [MultiBot.TalentTabStates.TALENTS] = { pointsVisible = true, showTalentTrees = true, copyVisible = true, copyActive = true, refreshApply = true },
        [MultiBot.TalentTabStates.GLYPHS] = { titleKey = "info.glyphsglyphsfor", pointsVisible = false, showTalentTrees = false, copyVisible = false, copyActive = false, hideApply = true },
        [MultiBot.TalentTabStates.CUSTOM_TALENTS] = { titleKey = "info.talentscustomtalentsfor", pointsVisible = true, showTalentTrees = true, copyVisible = false, copyActive = false, refreshApply = true },
        [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = { titleKey = "info.glyphscustomglyphsfor", pointsVisible = false, showTalentTrees = false, copyVisible = false, copyActive = false, refreshApply = true },
    }
    MultiBot.TalentApplyActionSpecs = MultiBot.TalentApplyActionSpecs or {
        [MultiBot.TalentTabStates.TALENTS] = { hasSelection = "hasTalentsApplySelection", applySelection = "applyCustomTalents" },
        [MultiBot.TalentTabStates.CUSTOM_TALENTS] = { hasSelection = "hasCustomTalentSelection", applySelection = "applyCustomTalents" },
        [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = { hasSelection = "hasCustomGlyphSelection", applySelection = "applyCustomGlyphs" },
    }
    MultiBot.TalentTabOffsets = MultiBot.TalentTabOffsets or { TALENTS = -630, GLYPHS = -530, CUSTOM_TALENTS = -430, CUSTOM_GLYPHS = -330, COPY = -230, APPLY = -230 }
    MultiBot.TalentTabLimits = MultiBot.TalentTabLimits or { TREE_COUNT = 3, GLYPH_SOCKET_COUNT = 6, SOCKET_REQUIREMENTS = { 15, 15, 30, 50, 70, 80 } }
    MultiBot.TalentTabHost = MultiBot.TalentTabHost or {
        BUTTONS = {
            [MultiBot.TalentTabStates.TALENTS] = { key = MultiBot.TalentTabDefaults.ACTIVE, label = MultiBot.TalentTabDefaults.ACTIVE_LABEL },
            [MultiBot.TalentTabStates.GLYPHS] = { key = MultiBot.TalentTabKeys.GLYPHS, label = MultiBot.TalentTabLabels.GLYPHS },
            [MultiBot.TalentTabStates.CUSTOM_TALENTS] = { key = MultiBot.TalentTabKeys.CUSTOM_TALENTS, label = MultiBot.TalentTabLabels.CUSTOM_TALENTS },
            [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = { key = MultiBot.TalentTabKeys.CUSTOM_GLYPHS, label = MultiBot.TalentTabLabels.CUSTOM_GLYPHS },
        },
        TITLE_KEYS = {
            [MultiBot.TalentTabStates.GLYPHS] = "info.glyphsglyphsfor",
            [MultiBot.TalentTabStates.CUSTOM_TALENTS] = "info.talentscustomtalentsfor",
            [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = "info.glyphscustomglyphsfor",
        },
        TITLE_DEFAULT = "Talents & Glyphs",
        SIZE = {
            WIDTH = 540,
            HEIGHT = 480,
        },
        OFFSETS = {
            HOST_TUNE_X = 220,
            NATIVE_BASE_Y = -35,
            NATIVE_TUNE_Y = -0.9,
        },
    }
    MultiBot.TalentTabColors = MultiBot.TalentTabColors or { ACTIVE = { 1, 0.82, 0, 1 }, INACTIVE = { 0.5, 0.5, 0.5, 1 } }
    MultiBot.TalentTabChrome = MultiBot.TalentTabChrome or {
        STYLE = "CHATFRAME_LEGACY",
        CHATFRAME_TEXTURES = {
            LEFT = "Interface\\ChatFrame\\ChatFrameTab-BGLeft",
            MID = "Interface\\ChatFrame\\ChatFrameTab-BGMid",
            RIGHT = "Interface\\ChatFrame\\ChatFrameTab-BGRight",
        },
    }

    function MultiBot.talent.applyBottomTabChrome(tabFrame)
        local chrome = MultiBot.TalentTabChrome or {}
        if chrome.STYLE ~= "CHATFRAME_LEGACY" then
            chrome = {
                STYLE = "CHATFRAME_LEGACY",
                CHATFRAME_TEXTURES = MultiBot.TalentTabChrome and MultiBot.TalentTabChrome.CHATFRAME_TEXTURES,
            }
        end

        local textures = chrome.CHATFRAME_TEXTURES or {}
        local leftTexture = textures.LEFT or "Interface\\ChatFrame\\ChatFrameTab-BGLeft"
        local midTexture = textures.MID or "Interface\\ChatFrame\\ChatFrameTab-BGMid"
        local rightTexture = textures.RIGHT or "Interface\\ChatFrame\\ChatFrameTab-BGRight"

        local bgLeft = tabFrame:CreateTexture(nil, "BACKGROUND")
        bgLeft:SetTexture(leftTexture)
        bgLeft:SetTexCoord(0, 1, 1, 0)
        bgLeft:SetWidth(16)
        bgLeft:SetHeight(32)
        bgLeft:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 0, -4)

        local bgMid = tabFrame:CreateTexture(nil, "BACKGROUND")
        bgMid:SetTexture(midTexture)
        bgMid:SetTexCoord(0, 1, 1, 0)
        bgMid:SetHeight(32)
        bgMid:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 16, -4)
        bgMid:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -16, -4)

        local bgRight = tabFrame:CreateTexture(nil, "BACKGROUND")
        bgRight:SetTexture(rightTexture)
        bgRight:SetTexCoord(0, 1, 1, 0)
        bgRight:SetWidth(16)
        bgRight:SetHeight(32)
        bgRight:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", 0, -4)

        return bgLeft, bgMid, bgRight
    end

    function MultiBot.talent.setBottomTabVisualState(tabKey, isActive, labelOverride)
        local tab = MultiBot.talent.tabTextures[tabKey]
        if not tab then
            return
        end

        local color = isActive and MultiBot.TalentTabColors.ACTIVE or MultiBot.TalentTabColors.INACTIVE
        if tab.left and tab.mid and tab.right then
            tab.left:SetVertexColor(color[1], color[2], color[3], color[4])
            tab.mid:SetVertexColor(color[1], color[2], color[3], color[4])
            tab.right:SetVertexColor(color[1], color[2], color[3], color[4])
        else
            for _, texture in ipairs(tab.textures or {}) do
                if texture and texture.SetVertexColor then
                    texture:SetVertexColor(color[1], color[2], color[3], color[4])
                end
            end
        end

        if tab.btn and tab.btn.text then
            local label = labelOverride or tab.btn.label
            if label then
                local textColor = isActive and "|cffffcc00" or "|cffaaaaaa"
                tab.btn.text:SetText(textColor .. label .. "|r")
            end
        end
    end

    function MultiBot.talent.resetBottomTabVisuals(activeTabKey, activeLabel)
        local activeKey = activeTabKey or MultiBot.TalentTabDefaults.ACTIVE
        local activeText = activeLabel or MultiBot.TalentTabDefaults.ACTIVE_LABEL

        for _, key in ipairs(MultiBot.TalentTabGroups.BOTTOM) do
            MultiBot.talent.setBottomTabVisualState(key, key == activeKey)
        end

        MultiBot.talent.setBottomTabVisualState(activeKey, true, activeText)
    end

    function MultiBot.talent.setTalentContentVisibility(showTalentTrees)
        for _, tabKey in ipairs(MultiBot.TalentTabGroups.TALENT_TREES) do
            local frame = MultiBot.talent.frames and MultiBot.talent.frames[tabKey]
            if frame then
                if showTalentTrees then
                    frame:Show()
                else
                    frame:Hide()
                end
            end
        end

        local glyphFrame = MultiBot.talent.frames and MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH]
        if glyphFrame then
            if showTalentTrees then
                glyphFrame:Hide()
            else
                glyphFrame:Show()
            end
        end
    end

    function MultiBot.talent.setCopyTabMode(visible, active)
        local copyFrame = MultiBot.talent.frames and MultiBot.talent.frames[MultiBot.TalentTabKeys.COPY]
        if copyFrame then
            if visible then
                copyFrame:Show()
            else
                copyFrame:Hide()
            end
        end

        if visible then
            MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.COPY, active == true, MultiBot.TalentTabLabels.COPY)
        end
    end

    function MultiBot.talent.setActiveTabContext(state, opts)
        opts = opts or {}

        if state then
            MultiBot.talent.__activeTab = state
        end

        if opts.titleKey then
            MultiBot.talent.setTalentTitleByKey(opts.titleKey)
        elseif opts.titleText then
            MultiBot.talent.setText("Title", opts.titleText)
        end

        if opts.pointsVisible ~= nil then
            MultiBot.talent.setPointsVisibility(opts.pointsVisible)
        end

        if opts.showTalentTrees ~= nil then
            MultiBot.talent.setTalentContentVisibility(opts.showTalentTrees)
        end

        if opts.copyVisible ~= nil then
            MultiBot.talent.setCopyTabMode(opts.copyVisible, opts.copyActive == true)
        end

        if opts.hideApply then
            MultiBot.talent.hideApplyTab()
        elseif opts.refreshApply then
            MultiBot.talent.refreshApplyTabVisibility()
        end

        MultiBot.talent.syncHostWindowTitle(state, opts)
    end

    function MultiBot.talent.syncHostWindowTitle(state, opts)
        local host = MultiBot.talentAceHost
        local window = host and host.window
        if not (window and window.SetTitle) then
            return
        end

        local botName = MultiBot.talent and MultiBot.talent.name or "NAME"
        local titleText = opts and opts.titleText
        local titleKey = opts and opts.titleKey

        if titleText and titleText ~= "" then
            window:SetTitle(titleText)
            return
        end

        if titleKey then
            window:SetTitle((MultiBot.L(titleKey) or "") .. " " .. botName)
            return
        end

        local resolvedState = state or MultiBot.talent.__activeTab
        local hostTitleKey = MultiBot.TalentTabHost and MultiBot.TalentTabHost.TITLE_KEYS and MultiBot.TalentTabHost.TITLE_KEYS[resolvedState]
        if hostTitleKey then
            window:SetTitle((MultiBot.L(hostTitleKey) or "") .. " " .. botName)
            return
        end

        window:SetTitle(MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME", botName) or MultiBot.TalentTabHost.TITLE_DEFAULT)
    end

    function MultiBot.talent.copyOptionsTable(values)
        if type(values) ~= "table" then
            return {}
        end

        local copy = {}
        for key, value in pairs(values) do
            copy[key] = value
        end

        return copy
    end

    function MultiBot.talent.getTabContextProfile(state)
        local profiles = MultiBot.TalentTabContextProfiles or {}
        local profile = profiles[state]
        if not profile then
            return nil
        end

        return MultiBot.talent.copyOptionsTable(profile)
    end

    function MultiBot.talent.buildTabContextOptions(state, overrides)
        local options = MultiBot.talent.getTabContextProfile(state) or {}
        if type(overrides) == "table" then
            for key, value in pairs(overrides) do
                options[key] = value
            end
        end

        return options
    end

    function MultiBot.talent.applyTabContextProfile(state, overrides)
        return MultiBot.talent.activateTabState(state, overrides)
    end

    function MultiBot.talent.activateTabState(state, overrides, afterActivate)
        local options = MultiBot.talent.buildTabContextOptions(state, overrides)
        MultiBot.talent.setActiveTabContext(state, options)

        if type(afterActivate) == "function" then
            afterActivate(options)
        end

        if options.refreshApply then
            MultiBot.talent.refreshApplyTabVisibility()
        end

        return options
    end

    function MultiBot.talent.hideApplyTab()
        if MultiBot.talent.applyTabBtn then
            MultiBot.talent.applyTabBtn.doHide()
        end
    end

    function MultiBot.talent.setPointsVisibility(show)
        local pointsText = MultiBot.talent.texts and MultiBot.talent.texts["Points"]
        if not pointsText then
            return
        end

        if show then
            pointsText:Show()
        else
            pointsText:Hide()
        end
    end

    function MultiBot.talent.setTalentTitleByKey(localizationKey)
        MultiBot.talent.setText("Title", "|cffffff00" .. MultiBot.L(localizationKey) .. " |r" .. (MultiBot.talent.name or "?"))
    end

    function MultiBot.talent.getTalentBotUnit()
        return MultiBot.toUnit(MultiBot.talent and MultiBot.talent.name)
    end

    function MultiBot.talent.getTalentBotLevel(fallbackUnit)
        local unit = MultiBot.talent.getTalentBotUnit()
        local resolvedLevel = UnitLevel(unit or fallbackUnit or "player")
        if type(resolvedLevel) == "number" and resolvedLevel > 0 then
            MultiBot.talent.__cachedBotLevel = resolvedLevel
            return resolvedLevel
        end

        return MultiBot.talent.__cachedBotLevel
    end

    function MultiBot.talent.getTalentBotClassKey(fallbackUnit)
        local unit = MultiBot.talent.getTalentBotUnit()
        local _, classFile = UnitClass(unit or fallbackUnit or "player")
        if not classFile then
            return MultiBot.talent.__cachedBotClassKey
        end

        local classKey
        if classFile == "DEATHKNIGHT" then
            classKey = "DeathKnight"
        else
            classKey = classFile:sub(1,1)..classFile:sub(2):lower()
        end

        MultiBot.talent.__cachedBotClassKey = classKey
        return classKey
    end

    function MultiBot.talent.getTalentTreeFrame(treeIndex)
        local key = MultiBot.TalentTabGroups.TALENT_TREES[treeIndex]
        return key and MultiBot.talent.frames and MultiBot.talent.frames[key]
    end

    function MultiBot.talent.getGlyphSocket(socketIndex)
        local glyphFrame = MultiBot.talent.frames and MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH]
        return glyphFrame and glyphFrame.frames and glyphFrame.frames["Socket" .. socketIndex]
    end

    -- Playerbots/legacy glyph wire order is not the same as this frame's visual order.
    -- Wire/apply order:
    -- 1 = top major, 2 = bottom-center minor, 3 = right-middle minor,
    -- 4 = bottom-left major, 5 = left-middle minor, 6 = bottom-right major.
    local GLYPH_WIRE_TO_VISUAL_SOCKET = { 1, 2, 5, 6, 4, 3 }

    function MultiBot.talent.mapGlyphWireSlotToVisualSocket(slotIndex)
        slotIndex = tonumber(slotIndex) or 0
        return GLYPH_WIRE_TO_VISUAL_SOCKET[slotIndex] or slotIndex
    end

    function MultiBot.talent.forEachTalentTree(callback)
        if type(callback) ~= "function" then
            return
        end

        for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
            local tree = MultiBot.talent.getTalentTreeFrame(i)
            local result = callback(i, tree)
            if result ~= nil then
                return result
            end
        end

        return nil
    end

    function MultiBot.talent.forEachGlyphSocket(callback)
        if type(callback) ~= "function" then
            return
        end

        for i = 1, MultiBot.TalentTabLimits.GLYPH_SOCKET_COUNT do
            local socket = MultiBot.talent.getGlyphSocket(i)
            local result = callback(i, socket)
            if result ~= nil then
                return result
            end
        end

        return nil
    end

    function MultiBot.talent.hasCustomTalentSelection()
        return MultiBot.talent.forEachTalentTree(function(_, tTab)
            local tButtons = tTab and tTab.buttons
            if tButtons then
                for j = 1, #tButtons do
                    if (tButtons[j].value or 0) > 0 then
                        return true
                    end
                end
            end

            return nil
        end) == true
    end

    function MultiBot.talent.hasCustomGlyphSelection()
        return MultiBot.talent.forEachGlyphSocket(function(_, socket)
            if (socket and socket.item or 0) > 0 then
                return true
            end

            return nil
        end) == true
    end

    function MultiBot.talent.hasUnspentTalentPoints()
        return (tonumber(MultiBot.talent.points) or 0) > 0
    end

    function MultiBot.talent.hasPendingTalentsApplyChange()
        return MultiBot.talent.__talentsApplyPending == true
    end

    function MultiBot.talent.hasTalentsApplySelection()
        return MultiBot.talent.getActiveTabState() == MultiBot.TalentTabStates.TALENTS
            and (
                MultiBot.talent.hasUnspentTalentPoints()
                or MultiBot.talent.hasPendingTalentsApplyChange()
            )
    end

    function MultiBot.talent.isTalentEditingEnabledForCurrentTab()
        local activeTab = MultiBot.talent.getActiveTabState()
        if activeTab == MultiBot.TalentTabStates.CUSTOM_TALENTS then
            return true
        end

        return activeTab == MultiBot.TalentTabStates.TALENTS
            and MultiBot.talent.hasUnspentTalentPoints()
    end

    function MultiBot.talent.getActiveTabState()
        return MultiBot.talent and MultiBot.talent.__activeTab
    end

    function MultiBot.talent.resolveTalentHandler(handlerOrName)
        if type(handlerOrName) == "function" then
            return handlerOrName
        end

        if type(handlerOrName) == "string" then
            local resolved = MultiBot.talent and MultiBot.talent[handlerOrName]
            if type(resolved) == "function" then
                return resolved
            end
        end

        return nil
    end

    function MultiBot.talent.getApplyActionSpecByState(state)
        local specs = MultiBot.TalentApplyActionSpecs or {}
        local spec = specs[state]
        if not spec then
            return nil
        end

        return MultiBot.talent.copyOptionsTable(spec)
    end

    function MultiBot.talent.resolveApplyActionHandlers(spec)
        if type(spec) ~= "table" then
            return nil, nil
        end

        local hasSelection = MultiBot.talent.resolveTalentHandler(spec.hasSelection)
        local applySelection = MultiBot.talent.resolveTalentHandler(spec.applySelection)
        return hasSelection, applySelection
    end

    function MultiBot.talent.canApplySelectionForState(state)
        local spec = MultiBot.talent.getApplyActionSpecByState(state)
        if not spec then
            return false
        end

        local hasSelection = MultiBot.talent.resolveApplyActionHandlers(spec)
        return type(hasSelection) == "function" and hasSelection() == true
    end

    function MultiBot.talent.applySelectionForState(state)
        local spec = MultiBot.talent.getApplyActionSpecByState(state)
        if not spec then
            return false
        end

        local hasSelection, applySelection = MultiBot.talent.resolveApplyActionHandlers(spec)
        if type(hasSelection) ~= "function" or type(applySelection) ~= "function" then
            return false
        end

        if not hasSelection() then
            return false
        end

        applySelection()
        return true
    end

    function MultiBot.talent.refreshApplyTabVisibility()
        if not MultiBot.talent.applyTabBtn then
            return
        end

        local activeState = MultiBot.talent.getActiveTabState()
        if activeState == MultiBot.TalentTabStates.TALENTS then
            if MultiBot.talent.__talentsTabApplyMode == nil then
                MultiBot.talent.__talentsTabApplyMode = MultiBot.talent.hasUnspentTalentPoints() and "apply" or "copy"
            end

            if MultiBot.talent.__talentsTabApplyMode == "apply" then
                MultiBot.talent.setCopyTabMode(false, false)
                MultiBot.talent.applyTabBtn.doShow()
                MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.APPLY, true, MultiBot.TalentTabLabels.APPLY)
            else
                MultiBot.talent.setCopyTabMode(true, true)
                MultiBot.talent.applyTabBtn.doHide()
            end
            return
        end

        local shouldShow = MultiBot.talent.canApplySelectionForState(activeState)
        if shouldShow then
            MultiBot.talent.applyTabBtn.doShow()
            MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.APPLY, true, MultiBot.TalentTabLabels.APPLY)
        else
            MultiBot.talent.applyTabBtn.doHide()
        end
    end

    function MultiBot.talent.updateTabChromeForHost(host)
        if not host then
            return
        end

        local offsets = MultiBot.TalentTabHost and MultiBot.TalentTabHost.OFFSETS or {}
        local yOffset = (offsets.NATIVE_BASE_Y or -35) + (offsets.NATIVE_TUNE_Y or -5)
        local tuneX = offsets.HOST_TUNE_X or 0
        local hostStrata = host:GetFrameStrata() or "DIALOG"
        local hostLevel = host:GetFrameLevel() or 0

        for _, frameName in ipairs(MultiBot.TalentTabGroups.CHROME) do
            local tabFrame = MultiBot.talent.frames and MultiBot.talent.frames[frameName]
            if tabFrame and tabFrame.SetPoint and tabFrame.ClearAllPoints then
                local xOffset = tabFrame.mbXOffset or 0
                tabFrame:ClearAllPoints()
                tabFrame:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", xOffset + tuneX, yOffset)
                tabFrame:SetFrameStrata(hostStrata)
                tabFrame:SetFrameLevel(hostLevel + 2)
            end

            local visible = frameName ~= MultiBot.TalentTabKeys.APPLY
            if tabFrame then
                if visible then
                    tabFrame:Show()
                else
                    tabFrame:Hide()
                end

                local buttonSet = tabFrame.buttons
                if buttonSet then
                    for _, button in pairs(buttonSet) do
                        if button and button.Show then
                            if visible then
                                button:Show()
                            else
                                button:Hide()
                            end
                        end
                    end
                end
            end
        end
    end

    function MultiBot.talent.updateTalentTreeLayeringForHost(host)
        if not host then
            return
        end

        local hostStrata = host:GetFrameStrata() or "DIALOG"
        local hostLevel = host:GetFrameLevel() or 0

        MultiBot.talent.forEachTalentTree(function(_, treeFrame)
            if treeFrame and treeFrame.SetFrameStrata and treeFrame.SetFrameLevel then
                treeFrame:SetFrameStrata(hostStrata)
                treeFrame:SetFrameLevel(hostLevel + 1)
            end

            MultiBot.talent.syncTalentTreeLayering(treeFrame)
            return nil
        end)
    end

    function MultiBot.talent.activateHostTab(host, window, value)
        local hostTab = MultiBot.TalentTabHost and MultiBot.TalentTabHost.BUTTONS and MultiBot.TalentTabHost.BUTTONS[value]
        local tab = hostTab and MultiBot.talent.tabTextures and MultiBot.talent.tabTextures[hostTab.key]
        local tabButton = tab and tab.btn
        local action = tabButton and tabButton.doLeft
        if action then
            action()
        end

        MultiBot.talent.updateTabChromeForHost(host)
        MultiBot.talent.updateTalentTreeLayeringForHost(host)
        MultiBot.talent.refreshApplyTabVisibility()
        if MultiBot.talent.texts and MultiBot.talent.texts["Title"] then
            MultiBot.talent.texts["Title"]:Hide()
        end

        if window and window.SetTitle then
            local botName = MultiBot.talent and MultiBot.talent.name or "NAME"
            local titleKey = MultiBot.TalentTabHost.TITLE_KEYS[value]
            if titleKey then
                window:SetTitle(MultiBot.L(titleKey) .. " " .. botName)
            else
                window:SetTitle(MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME", botName) or MultiBot.TalentTabHost.TITLE_DEFAULT)
            end
        end
    end

    function MultiBot.talent.applyHostLayout(hostFrame)
        local host = hostFrame
        if not host then
            return nil
        end

        MultiBot.talent:SetParent(host)
        MultiBot.talent:ClearAllPoints()
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        MultiBot.talent:SetPoint("TOPLEFT", host, "TOPLEFT", layout.CONTENT_TUNE_X or 0, layout.CONTENT_TUNE_Y or 0)

        if MultiBot.talent.texture then
            MultiBot.talent.texture:Hide()
        end

        local moveButton = MultiBot.talent.buttons and MultiBot.talent.buttons["Move"]
        if moveButton then
            moveButton:Hide()
        end

        for _, frameName in ipairs(MultiBot.TalentTabGroups.ALL) do
            local child = MultiBot.talent.frames and MultiBot.talent.frames[frameName]
            if child and child.SetParent then
                child:SetParent(host)
            end
        end

        local pointsText = MultiBot.talent.texts and MultiBot.talent.texts["Points"]
        if pointsText and pointsText.SetParent then
            pointsText:SetParent(host)
        end

        if MultiBot.talent.texts and MultiBot.talent.texts["Title"] then
            MultiBot.talent.texts["Title"]:Hide()
        end

        MultiBot.talent.updateTabChromeForHost(host)
        MultiBot.talent.updateTalentTreeLayeringForHost(host)
        MultiBot.talent.refreshApplyTabVisibility()
        return host
    end

    function MultiBot.talent.ensureAceHost(createIfMissing)
        if MultiBot.talentAceHost then
            return MultiBot.talentAceHost
        end

        if createIfMissing == false then
            return nil
        end

        local aceGUI = resolveTalentFrameAceGUI("AceGUI-3.0 is required for MB_TalentGlyphHost")
        if not aceGUI then
            return nil
        end

        local window = aceGUI:Create("Window")
        if not window then
            return nil
        end

        window:SetTitle(MultiBot.TalentTabHost.TITLE_DEFAULT)
        local hostSize = MultiBot.TalentTabHost and MultiBot.TalentTabHost.SIZE or {}
        local hostDefaultWidth = hostSize.WIDTH or 620
        local hostDefaultHeight = hostSize.HEIGHT or 570
        window:SetWidth(hostDefaultWidth)
        window:SetHeight(hostDefaultHeight)
        window:EnableResize(false)
        window:SetLayout("Fill")
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            window.frame:SetFrameStrata(strataLevel)
        end
        registerTalentFrameEscapeClose(window, "TalentGlyphHost")
        bindTalentFramePosition(window, "talent_glyph_host")
        setTalentFrameCloseToHide(window)
        window.frame:HookScript("OnHide", syncTalentButtonStateOnHide)

        local host = CreateFrame("Frame", nil, window.content)
        if not host then
            return nil
        end

        host:SetPoint("TOPLEFT", window.content, "TOPLEFT", 0, 0)
        host:SetPoint("TOPRIGHT", window.content, "TOPRIGHT", 0, 0)
        host:SetPoint("BOTTOM", window.content, "BOTTOM", 0, 0)
        if host.SetClipsChildren then
            host:SetClipsChildren(false)
        end

        MultiBot.talent.applyHostLayout(host)
        MultiBot.talent.activateHostTab(host, window, MultiBot.TalentTabStates.TALENTS)

        -- Keep Talents tab active by default and all other bottom tabs inactive.
        MultiBot.talent.resetBottomTabVisuals(MultiBot.TalentTabDefaults.ACTIVE, MultiBot.TalentTabDefaults.ACTIVE_LABEL)

        MultiBot.talentAceHost = {
            window = window,
            host = host,
        }

        return MultiBot.talentAceHost
    end

    MultiBot.talent.Show = function(self)
        local host = MultiBot.talent.ensureAceHost(true)
        if host and host.host then
            MultiBot.talent.applyHostLayout(host.host)
        end

        local window = host and host.window
        if window then
            window:Show()
        end

        return self
    end

    MultiBot.talent.Hide = function(self)
        local host = MultiBot.talent.ensureAceHost(false)
        local window = host and host.window
        if window then
            window:Hide()
        end

        return self
    end

    MultiBot.talent.IsShown = function(_)
        local host = MultiBot.talent.ensureAceHost(false)
        local window = host and host.window
        if window and window.frame then
            return window.frame:IsShown()
        end

        return false
    end

    function MultiBot.talent.buildTalentApplyValues()
	local tValues = ""

	MultiBot.talent.forEachTalentTree(function(i, tTab)
		for j = 1, #tTab.buttons do
			tValues = tValues .. tTab.buttons[j].value
		end
		if i < MultiBot.TalentTabLimits.TREE_COUNT then tValues = tValues .. "-" end
	end)

	return tValues
    end

    function MultiBot.talent.applyCustomTalents()
	SendChatMessage("talents apply " .. MultiBot.talent.buildTalentApplyValues(), "WHISPER", nil, MultiBot.talent.name)
    end

    function MultiBot.talent.copyCustomTalentsToTarget()
	local tName = UnitName("target")
	if(tName == nil or tName == "Unknown Entity") then return SendChatMessage(MultiBot.L("info.target"), "SAY") end

	local _, tClass = UnitClass("target")
	if(MultiBot.talent.class ~= MultiBot.toClass(tClass)) then return SendChatMessage("The Classes do not match.", "SAY") end

	local tUnit = MultiBot.toUnit(MultiBot.talent.name)
	if(UnitLevel(tUnit) ~= UnitLevel("target")) then return SendChatMessage("The Levels do not match.", "SAY") end

	SendChatMessage("talents apply " .. MultiBot.talent.buildTalentApplyValues(), "WHISPER", nil, tName)
    end

    -- Talent trees frame initialization in scoped blocks
    do
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local tTab = MultiBot.talent.addFrame(MultiBot.TalentFrameKeys.TALENT_TREE_1, -830 + (layout.TALENT_TREES_TUNE_X or 0), 518 + (layout.TALENT_TREES_TUNE_Y or 0), 28, 170, 408)
        tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
        tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
        tTab.arrows = {}
        tTab.value = 0
        tTab.id = 1
    end

    do
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local tTab = MultiBot.talent.addFrame(MultiBot.TalentFrameKeys.TALENT_TREE_2, -656 + (layout.TALENT_TREES_TUNE_X or 0), 518 + (layout.TALENT_TREES_TUNE_Y or 0), 28, 170, 408)
        tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
        tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
        tTab.arrows = {}
        tTab.value = 0
        tTab.id = 2
    end

    do
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local tTab = MultiBot.talent.addFrame(MultiBot.TalentFrameKeys.TALENT_TREE_3, -482 + (layout.TALENT_TREES_TUNE_X or 0), 518 + (layout.TALENT_TREES_TUNE_Y or 0), 28, 170, 408)
        tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
        tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
        tTab.arrows = {}
        tTab.value = 0
        tTab.id = 3
    end

    -- ACTUAL GLYPHES START --

    -- Minimum level for each socket (in order 1→6) is centralized in TalentTabLimits.SOCKET_REQUIREMENTS.

    function MultiBot.talent.showGlyphTooltip(self)
        if not self then return end

        local itemId = tonumber(self.itemID or self.item or 0) or 0
        local spellId = tonumber(self.spellID or 0) or 0

        if itemId == 0 and spellId == 0 then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        if itemId > 0 then
            GameTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
        elseif spellId > 0 then
            if GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(spellId)
            else
                GameTooltip:SetHyperlink("spell:" .. spellId)
            end
        end

        GameTooltip:Show()
    end

    function MultiBot.talent.getGlyphSocketClassColor(botName)
        local unit = MultiBot.toUnit and MultiBot.toUnit(botName or MultiBot.talent.name)
        local _, classFile = unit and UnitClass(unit)
        local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]

        if color then
            return color.r or 1, color.g or 1, color.b or 1
        end

        return 1, 1, 1
    end

    function MultiBot.talent.applyGlyphSocketClassColor(socketFrame, botName)
        if not (socketFrame and socketFrame.frames) then
            return
        end

        local r, g, b = MultiBot.talent.getGlyphSocketClassColor(botName)
        local frames = socketFrame.frames
        local glowTexture = frames.Glow and (frames.Glow.texture or frames.Glow)
        local runeTexture = frames.Rune and (frames.Rune.texture or frames.Rune)
        local overlayTexture = frames.Overlay and frames.Overlay.texture

        if glowTexture and glowTexture.SetVertexColor then
            glowTexture:SetVertexColor(r, g, b, 1)
        end
        if runeTexture and runeTexture.SetVertexColor then
            runeTexture:SetVertexColor(r, g, b, 1)
        end
        if overlayTexture and overlayTexture.SetVertexColor then
            overlayTexture:SetVertexColor(r, g, b, 1)
        end
    end

    function MultiBot.talent.hideGlyphTooltip()
        GameTooltip:Hide()
    end

    function MultiBot.talent.applyGlyphSocketIconLayout(button, socketFrame, isFallback)
        if not (button and button.icon and socketFrame) then
            return
        end

        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local iconTuneX = layout.GLYPH_ICON_TUNE_X or -9
        local iconTuneY = layout.GLYPH_ICON_TUNE_Y or 8
        local sizeScale = isFallback and
            (layout.GLYPH_FALLBACK_ICON_SIZE_SCALE or layout.GLYPH_ICON_SIZE_SCALE or 0.66) or
            (layout.GLYPH_ICON_SIZE_SCALE or 0.66)

        button.icon:ClearAllPoints()
        button.icon:SetPoint("CENTER", button, "CENTER", iconTuneX, iconTuneY)
        button.icon:SetSize(socketFrame:GetWidth() * sizeScale, socketFrame:GetHeight() * sizeScale)
    end

    function MultiBot.FillDefaultGlyphs()
        local botName = MultiBot.talent.name
        local unit    = MultiBot.toUnit(botName)
        if not unit then return end

        local rec = MultiBot.receivedGlyphs and MultiBot.receivedGlyphs[botName]
        if not rec then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MultiBot]|r " .. MultiBot.L("talent.glyphs.waiting"))
            return
        end

        local _, classFile = UnitClass(unit)
        local classKey = (classFile == "DEATHKNIGHT" and "DeathKnight")
                       or (classFile:sub(1,1) .. classFile:sub(2):lower())
        local glyphDB = MultiBot.data.talent.glyphs[classKey] or {}

        for i, entry in ipairs(rec) do
            local wireSlotIndex = tonumber(entry and (entry.index or entry.slot) or i) or i
            local socketIndex = MultiBot.talent.mapGlyphWireSlotToVisualSocket(wireSlotIndex)
            local f = MultiBot.talent.getGlyphSocket(socketIndex)
            if f and f.frames then

                local itemId = tonumber(entry.itemId or entry.id or 0) or 0
                local glyphId = tonumber(entry.glyphId or 0) or 0
                local spellId = tonumber(entry.spellId or 0) or 0
                local displayId = itemId
                if displayId == 0 then
                    displayId = spellId
                end

                local typ = entry.type
                if not typ or typ == "" then
                    if itemId > 0 and glyphDB.Major and glyphDB.Major[itemId] then
                        typ = "Major"
                    elseif itemId > 0 and glyphDB.Minor and glyphDB.Minor[itemId] then
                        typ = "Minor"
                    else
                        typ = f.socketType or f.type
                    end
                end

                f.glyphType = typ
                f.item = itemId
                f.itemID = itemId
                f.glyphID = glyphId
                f.spellID = spellId

                local gFrame = f.frames.Glow
                if gFrame then
                    local glowTex = gFrame.texture or gFrame
                    if glowTex and glowTex.SetTexture then
                        glowTex:SetTexture(MultiBot.SafeTexturePath(
                            (typ == "Major") and "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp"
                                             or "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp"))
                    end
                    gFrame:Show()
                end

                local raw = glyphDB[typ] and (glyphDB[typ][itemId] or glyphDB[typ][displayId]) or ""
                local _, runeIdx = string.match(raw, "^(.-),%s*(%d+)$")
                runeIdx = runeIdx or "1"
                local rFrame = f.frames.Rune
                if rFrame then
                    rFrame:Hide()
                    local runeTex = rFrame.texture or rFrame
                    runeTex:SetTexture(MultiBot.SafeTexturePath("Interface\\Spellbook\\UI-Glyph-Rune-" .. runeIdx))
                end

                local itemName, _, _, _, _, _, _, _, _, itemTexture
                if itemId > 0 then
                    itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    if not itemTexture and type(GetItemIcon) == "function" then
                        itemTexture = GetItemIcon(itemId)
                    end
                end

                local spellName, _, spellTexture
                if spellId > 0 then
                    spellName, _, spellTexture = GetSpellInfo(spellId)
                    if not spellTexture and type(GetSpellTexture) == "function" then
                        spellTexture = GetSpellTexture(spellId)
                    end
                end

                local tex = itemTexture or spellTexture
                local isFallback = tex == nil
                tex = tex or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
                local btn = f.frames.IconBtn
                if not btn then
                    btn = MultiBot.talent.createGlyphSocketIconButton(f)
                    f.frames.IconBtn = btn
                else
                    MultiBot.talent.bindGlyphSocketIconButtonHandlers(btn)
                end

                btn.glyphID = glyphId
                btn.itemID = itemId
                btn.item = itemId
                btn.spellID = spellId
                btn.name = itemName or spellName or (displayId > 0 and ("ID " .. tostring(displayId))) or "Glyph"
                btn.type = typ
                MultiBot.talent.applyGlyphSocketIconLayout(btn, f, isFallback)
                btn.icon:SetTexture(MultiBot.SafeTexturePath(tex))
                btn.icon:Show()
                if btn.bg and itemId > 0 then
                    btn.bg:Hide()
                end
                btn:Show()

                local ov = f.frames.Overlay
                if ov and not ov.texture then
                    ov.texture = ov:CreateTexture(nil, "BORDER")
                    ov.texture:SetAllPoints(ov)
                    local base = "Interface\\AddOns\\MultiBot\\Textures\\"
                    ov.texture:SetTexture(
                        base .. (typ == "Major"
                                and "gliph_majeur_layout.blp"
                                or "gliph_mineur_layout.blp"))
                end
                if ov then ov:Show() end
                MultiBot.talent.applyGlyphSocketClassColor(f, botName)
            end
        end
    end

    function MultiBot.ApplyBridgeGlyphs(botName, glyphs, token)
        if not botName or not glyphs then
            return
        end

        MultiBot.receivedGlyphs = MultiBot.receivedGlyphs or {}
        MultiBot.receivedGlyphs[botName] = glyphs

        if MultiBot.talent and MultiBot.talent.name == botName then
            MultiBot.FillDefaultGlyphs()
        end
    end

    function MultiBot.talent.OnBridgeGlyphs(botName, token, glyphs)
        MultiBot.ApplyBridgeGlyphs(botName, glyphs, token)
    end

    -- Glyph overview frame initialization in a scoped block
    do
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local tTab = MultiBot.talent.addFrame(MultiBot.TalentFrameKeys.GLYPH_OVERVIEW, -513 + (layout.GLYPH_OVERVIEW_TUNE_X or 0), 518 + (layout.GLYPH_OVERVIEW_TUNE_Y or 0), 28, 456, 430)
        tTab.addFrame("Glow", 0, 0, 28, 456, 430).setAlpha(0.5).doHide()
        tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Background-GlyphFrame.blp")
        tTab:Hide()
    end

    -- Apply tab is the only entry point for glyph equipment actions.
    function MultiBot.talent.applyCustomGlyphs()
        local ids = {}
        for wireSlot = 1, MultiBot.TalentTabLimits.GLYPH_SOCKET_COUNT do
            local socketIndex = MultiBot.talent.mapGlyphWireSlotToVisualSocket(wireSlot)
            local socket = MultiBot.talent.getGlyphSocket(socketIndex)
            ids[wireSlot] = tonumber(socket and (socket.item or socket.itemID or socket.glyphID)) or 0
        end
        local payload = "glyph equip " .. table.concat(ids, " ")
        --DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DBG]|r " .. MultiBot.L("talent.glyphs.debug_prefix") ..
            --(MultiBot.talent.name or "?") .. " : " .. payload)
        SendChatMessage(payload, "WHISPER", nil, MultiBot.talent.name)
    end


    -- Define glyph sockets from a compact descriptor list to limit local declarations.
    local glyphSocketDefinitions = {
        { name = "Socket1", x = -176.5, y = 310,   size = 102, glow = "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
        { name = "Socket2", x = -187,   y = 18.5,  size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
        { name = "Socket3", x = -18.5,  y = 50.5,  size = 102, glow = "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
        { name = "Socket4", x = -302.5, y = 218,   size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
        { name = "Socket5", x = -72.5,  y = 218,   size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
        { name = "Socket6", x = -336,   y = 50.5,  size = 102, glow = "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
    }

    for socketIndex, def in ipairs(glyphSocketDefinitions) do
        local layout = MultiBot.TalentHostContentLayout or DEFAULT_TALENT_HOST_CONTENT_LAYOUT
        local tGlyph = MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH].addFrame(def.name, def.x + (layout.GLYPH_SOCKETS_TUNE_X or 0), def.y + (layout.GLYPH_SOCKETS_TUNE_Y or 0), def.size)
        tGlyph.addFrame("Glow", 0, 0, def.size).setLevel(7).doHide().addTexture(def.glow)
        tGlyph.addFrame("Rune", def.runeX, def.runeY, def.runeSize).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
        tGlyph.frames = tGlyph.frames or {}
        if tGlyph.SetID then
            tGlyph:SetID(socketIndex)
        end
        tGlyph.type = def.socketType
        tGlyph.socketType = def.socketType
        tGlyph.item = 0
        tGlyph.addFrame("Overlay", def.overlayX, def.overlayY, def.overlaySize).setLevel(9).doHide()
    end

    function MultiBot.talent.addBottomTab(frameKey, buttonLabel, xOffset)
        local offsets = MultiBot.TalentTabHost and MultiBot.TalentTabHost.OFFSETS or {}
        local yOffset = (offsets.NATIVE_BASE_Y or -35) + (offsets.NATIVE_TUNE_Y or -5)
        local tabFrame = MultiBot.talent.addFrame(frameKey, xOffset, yOffset, 28, 96, 24)
        tabFrame.mbXOffset = xOffset
        tabFrame.buttons = tabFrame.buttons or {}

        local tabTextures = MultiBot.talent.applyBottomTabChrome(tabFrame)
        tabFrame.tabTextures = tabTextures

        tabFrame.texLeft  = tabTextures[1]
        tabFrame.texMid   = tabTextures[2]
        tabFrame.texRight = tabTextures[3]

        local tabButton = CreateFrame("Button", "MBTab_"..frameKey, tabFrame)
        tabButton:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 0, -4)
        tabButton:SetSize(96, 32)
        tabButton:SetFrameLevel(tabFrame:GetFrameLevel() + 1)
        tabButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        tabButton:EnableMouse(true)
        tabButton.parent = tabFrame
        tabButton.state  = true

        tabButton.text = tabButton:CreateFontString(nil, "ARTWORK")
        tabButton.text:SetFont("Fonts\\ARIALN.ttf", 11, "OUTLINE")
        tabButton.text:SetPoint("CENTER", 0, 8)
        tabButton.text:SetText("|cffffcc00" .. buttonLabel .. "|r")

        tabButton.text:Show()

        tabButton.doHide = function()
            tabFrame:Hide()
            tabButton:Hide()
            if MultiBot.RequestClickBlockerUpdate then MultiBot.RequestClickBlockerUpdate(tabFrame) end
            return tabButton
        end

        tabButton.doShow = function()
            tabFrame:Show()
            tabButton:Show()
            if MultiBot.RequestClickBlockerUpdate then MultiBot.RequestClickBlockerUpdate(tabFrame) end
            return tabButton
        end

        tabButton:SetScript("OnLeave", function()
            tabButton.text:SetPoint("CENTER", 0, 8)
        end)

        MultiBot.talent.tabTextures[frameKey] = { textures = tabTextures, btn = tabButton }

        tabButton:SetScript("OnClick", function(_, mouseButton)
            tabButton.text:SetPoint("CENTER", -1, 7)

            MultiBot.talent.resetBottomTabVisuals(frameKey, buttonLabel)

            if mouseButton == "RightButton" and tabButton.doRight then tabButton.doRight(tabButton) end
            if mouseButton == "LeftButton"  and tabButton.doLeft  then tabButton.doLeft(tabButton)  end
        end)

        tabButton.label = buttonLabel
        return tabButton
    end

    function MultiBot.talent.setBottomTabAction(tabKey, action)
        local tab = MultiBot.talent.tabTextures and MultiBot.talent.tabTextures[tabKey]
        local button = tab and tab.btn
        if button then
            button.doLeft = action
        end

        return button
    end

    function MultiBot.talent.registerBottomTab(tabKey, label, offset, action, fieldName)
        local button = MultiBot.talent.addBottomTab(tabKey, label, offset)
        if action then
            MultiBot.talent.setBottomTabAction(tabKey, action)
        end

        if fieldName then
            MultiBot.talent[fieldName] = button
        end

        return button
    end

    function MultiBot.talent.bindBottomTabHandler(tabKey, handlerName)
        return MultiBot.talent.setBottomTabAction(tabKey, function(...)
            local handler = MultiBot.talent and MultiBot.talent[handlerName]
            if type(handler) == "function" then
                return handler(...)
            end

            return nil
        end)
    end

    function MultiBot.talent.registerBottomTabHandler(tabKey, label, offset, handlerName, fieldName)
        local button = MultiBot.talent.registerBottomTab(tabKey, label, offset, nil, fieldName)
        MultiBot.talent.bindBottomTabHandler(tabKey, handlerName)
        return button
    end

    function MultiBot.talent.initApplyTabButton(button)
        if button and button.doHide then
            button.doHide()
        end
    end

    function MultiBot.talent.resolveBottomTabHook(hook)
        if type(hook) == "function" then
            return hook
        end

        if type(hook) == "string" then
            local resolved = MultiBot.talent and MultiBot.talent[hook]
            if type(resolved) == "function" then
                return resolved
            end
        end

        return nil
    end

    function MultiBot.talent.registerBottomTabFromSpec(spec)
        if type(spec) ~= "table" then
            return nil
        end

        local button = MultiBot.talent.registerBottomTabHandler(
            spec.key,
            spec.label,
            spec.offset,
            spec.handler,
            spec.field
        )

        local postRegister = MultiBot.talent.resolveBottomTabHook(spec.postRegister)
        if postRegister then
            postRegister(button, spec)
        end

        return button
    end

    MultiBot.TalentBottomTabSpecs = MultiBot.TalentBottomTabSpecs or {
        { field = "talentsTabBtn", key = MultiBot.TalentTabDefaults.ACTIVE, label = MultiBot.TalentTabDefaults.ACTIVE_LABEL, offset = MultiBot.TalentTabOffsets.TALENTS, handler = "openTalentsTab" },
        { field = "glyphsTabBtn", key = MultiBot.TalentTabKeys.GLYPHS, label = MultiBot.TalentTabLabels.GLYPHS, offset = MultiBot.TalentTabOffsets.GLYPHS, handler = "openGlyphsTab" },
        { field = "customTalentsTabBtn", key = MultiBot.TalentTabKeys.CUSTOM_TALENTS, label = MultiBot.TalentTabLabels.CUSTOM_TALENTS, offset = MultiBot.TalentTabOffsets.CUSTOM_TALENTS, handler = "setTalentsCustom" },
        { field = "customGlyphsTabBtn", key = MultiBot.TalentTabKeys.CUSTOM_GLYPHS, label = MultiBot.TalentTabLabels.CUSTOM_GLYPHS, offset = MultiBot.TalentTabOffsets.CUSTOM_GLYPHS, handler = "showCustomGlyphs" },
        { field = "copyTabBtn", key = MultiBot.TalentTabKeys.COPY, label = MultiBot.TalentTabLabels.COPY, offset = MultiBot.TalentTabOffsets.COPY, handler = "onCopyTabClick" },
        { field = "applyTabBtn", key = MultiBot.TalentTabKeys.APPLY, label = MultiBot.TalentTabLabels.APPLY, offset = MultiBot.TalentTabOffsets.APPLY, handler = "onApplyTabClick", postRegister = "initApplyTabButton" },
    }

    function MultiBot.talent.registerAllBottomTabs()
        for _, spec in ipairs(MultiBot.TalentBottomTabSpecs or {}) do
            MultiBot.talent[spec.field] = MultiBot.talent.registerBottomTabFromSpec(spec)
        end
    end

    MultiBot.talent.registerAllBottomTabs()

    -- TAB TALENTS --
    function MultiBot.talent.getTalentTitleText()
        return MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME", MultiBot.talent.name)
    end

    function MultiBot.talent.activateTalentsTabContext()
        return MultiBot.talent.activateTabState(MultiBot.TalentTabStates.TALENTS, {
            titleText = MultiBot.talent.getTalentTitleText(),
        })
    end

    function MultiBot.talent.openTalentsTab()
	if MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_TALENTS then
		MultiBot.talent.setTalents()
		return
	end

        MultiBot.talent.activateTalentsTabContext()
    end

    -- TAB GLYPHS --
    function MultiBot.talent.requestGlyphsForTarget(targetName)
        if MultiBot.Comm and MultiBot.Comm.RequestGlyphs then
            local token = MultiBot.Comm.RequestGlyphs(targetName)
            if token then
                MultiBot.awaitGlyphs = nil
                return token
            end
        end

        MultiBot.awaitGlyphs = targetName
        SendChatMessage("glyphs", "WHISPER", nil, targetName)
        return nil
    end

    function MultiBot.talent.openGlyphsTab()
	MultiBot.talent.activateTabState(MultiBot.TalentTabStates.GLYPHS)
        MultiBot.talent.requestGlyphsForTarget(MultiBot.talent.name)
    end

    -- GLYPHES END --

    MultiBot.talent.setGrid = function(pTab)
	pTab.grid = {}
	pTab.grid.icons = {}
	pTab.grid.icons.size = pTab.size + 8
	pTab.grid.icons.x = pTab.width / 2 + pTab.grid.icons.size * 2 + 4
	pTab.grid.icons.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 + 4
	pTab.grid.arrows = {}
	pTab.grid.arrows.size = pTab.grid.icons.size + 8
	pTab.grid.arrows.x = pTab.width / 2 + pTab.grid.icons.size * 2 - 4
	pTab.grid.arrows.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 - 4
	pTab.grid.values = {}
	pTab.grid.values.x = pTab.width / 2 + pTab.grid.icons.size * 2
	pTab.grid.values.y = pTab.height / 2 + pTab.grid.icons.size * 5.5
	return pTab
    end

    function MultiBot.talent.getTalentTreeLayerLevel(treeFrame, offset)
        local baseLevel = (treeFrame and treeFrame.GetFrameLevel and treeFrame:GetFrameLevel()) or 0
        return baseLevel + (offset or 0)
    end

    function MultiBot.talent.syncTalentTreeLayering(treeFrame)
        if not treeFrame then
            return
        end

        local arrowLevel = MultiBot.talent.getTalentTreeLayerLevel(treeFrame, 1)
        local talentLevel = MultiBot.talent.getTalentTreeLayerLevel(treeFrame, 2)
        local valueLevel = MultiBot.talent.getTalentTreeLayerLevel(treeFrame, 3)

        if treeFrame.arrows then
            for _, arrowFrame in ipairs(treeFrame.arrows) do
                if arrowFrame and arrowFrame.SetFrameLevel then
                    arrowFrame:SetFrameLevel(arrowLevel)
                end
            end
        end

        if treeFrame.buttons then
            for _, talentButton in pairs(treeFrame.buttons) do
                if talentButton and talentButton.SetFrameLevel then
                    talentButton:SetFrameLevel(talentLevel)
                end
            end
        end

        if treeFrame.frames then
            for _, valueFrame in pairs(treeFrame.frames) do
                if valueFrame and valueFrame.SetFrameLevel then
                    valueFrame:SetFrameLevel(valueLevel)
                end
            end
        end
    end

    function MultiBot.talent.syncAllTalentTreeLayering()
        MultiBot.talent.forEachTalentTree(function(_, treeFrame)
            MultiBot.talent.syncTalentTreeLayering(treeFrame)
            return nil
        end)
    end

    MultiBot.talent.addArrow = function(pTab, pID, pNeeds, piX, piY, pTexture)
	local tArrow = pTab.addFrame("Arrow" .. pID, piX * pTab.grid.icons.size - pTab.grid.arrows.x, pTab.grid.arrows.y - piY * pTab.grid.icons.size, pTab.grid.arrows.size)
	tArrow.inactive = "Interface\\AddOns\\MultiBot\\Textures\\Talent_Silver_" .. pTexture .. ".blp"
	tArrow.addTexture(tArrow.inactive)
	tArrow.active = "Interface\\AddOns\\MultiBot\\Textures\\Talent_Gold_" .. pTexture .. ".blp"
	tArrow.needs = pNeeds
	tArrow:SetFrameLevel(MultiBot.talent.getTalentTreeLayerLevel(pTab, 1))
	return tArrow
    end

    function MultiBot.talent.getTalentRankColor(pValue, pMax, allowZeroWhite)
	if allowZeroWhite and pValue == 0 then
		return "|cffffffff"
	end

	if pValue < pMax then
		return "|cff4db24d"
	end

	return "|cffffcc00"
    end

    function MultiBot.talent.updateTalentPoints(delta)
	MultiBot.talent.points = MultiBot.talent.points + delta
	MultiBot.talent.setText("Points", MultiBot.L("info.talent.Points") .. MultiBot.talent.points)
    end

    function MultiBot.talent.updateTalentTreeTitle(pButton, pTab)
	pTab.setText("Title", MultiBot.L("info.talent." .. pButton.getClass() .. pTab.id) .. " ("  .. pTab.value .. ")")
    end

    function MultiBot.talent.updateTalentValueFrame(pButton, tValue, allowZeroWhite)
	local color = MultiBot.talent.getTalentRankColor(pButton.value, pButton.max, allowZeroWhite)
	tValue.setText("Value", color .. pButton.value .. "/" .. pButton.max .. "|r")
    end

    function MultiBot.talent.getTalentButtonState(tTab, tTalent)
	if(MultiBot.talent.points == 0) then
		if(tTalent.value == 0) then
			return false, false
		end
		return true, true
	end

	if(tTab.value < tTalent.points) then
		return false, false
	end

	return true, true
    end

    function MultiBot.talent.setTalentValueVisibility(tValue, shouldShow)
	if shouldShow then
		tValue:Show()
	else
		tValue:Hide()
	end
    end

    function MultiBot.talent.applyTalentButtonState(tTalent, tValue, shouldEnable, shouldShow)
	if shouldEnable then
		tTalent.setEnable(false)
	else
		tTalent.setDisable(false)
	end

	MultiBot.talent.setTalentValueVisibility(tValue, shouldShow)
    end

    function MultiBot.talent.forEachIndexedEntry(entries, callback)
        if type(entries) ~= "table" or type(callback) ~= "function" then
            return nil
        end

        for i = 1, #entries do
            local result = callback(i, entries[i], entries)
            if result ~= nil then
                return result
            end
        end

        return nil
    end

    function MultiBot.talent.refreshTalentDependencyState(tButtons, tTab)
        MultiBot.talent.forEachIndexedEntry(tButtons, function(i, button, buttons)
            if button.points > tTab.value then
                button.setDisable()
                return nil
            end

            if button.needs > 0 then
                if buttons[button.needs] and buttons[button.needs].value > 0 then
                    button.setEnable()
                end
                return nil
            end

            button.setEnable()
            return nil
        end)
    end

    function MultiBot.talent.getTalentButtonContext(pButton)
        local tab = pButton and pButton.parent
        if not tab then
            return nil
        end

        local buttons = tab.buttons
        local valueFrame = tab.frames and tab.frames[pButton.id]
        return tab, buttons, valueFrame
    end

    function MultiBot.talent.canIncreaseTalent(pButton, tButtons)
        if MultiBot.talent.points == 0 then
            return false
        end

        if pButton.state == false or pButton.value == pButton.max then
            return false
        end

        if pButton.needs > 0 and (not tButtons[pButton.needs] or tButtons[pButton.needs].value == 0) then
            return false
        end

        return true
    end

    function MultiBot.talent.canDecreaseTalent(pButton)
        return (pButton and pButton.value or 0) > 0
    end

    function MultiBot.talent.applyTalentRankDelta(pButton, tTab, delta)
        pButton.value = pButton.value + delta
        pButton.tip = pButton.tips[pButton.value + 1]
        tTab.value = tTab.value + delta
        MultiBot.talent.updateTalentTreeTitle(pButton, tTab)
    end

    function MultiBot.talent.onTalentLeftClick(pButton)
        if not MultiBot.talent.isTalentEditingEnabledForCurrentTab() then
            return
        end

        local tTab, tButtons, tValue = MultiBot.talent.getTalentButtonContext(pButton)
        if not tTab or not MultiBot.talent.canIncreaseTalent(pButton, tButtons) then
            return
        end

        MultiBot.talent.updateTalentPoints(-1)
        MultiBot.talent.applyTalentRankDelta(pButton, tTab, 1)

        if MultiBot.talent.getActiveTabState() == MultiBot.TalentTabStates.TALENTS then
            MultiBot.talent.__talentsApplyPending = true
        end
        MultiBot.talent.updateTalentValueFrame(pButton, tValue, false)
        MultiBot.talent.setTalentValueVisibility(tValue, true)

        MultiBot.talent.refreshTalentDependencyState(tButtons, tTab)
        MultiBot.talent.refreshApplyTabVisibility()
        MultiBot.talent.doState()
    end

    function MultiBot.talent.onTalentRightClick(pButton)
        if not MultiBot.talent.isTalentEditingEnabledForCurrentTab() then
            return
        end

        if not MultiBot.talent.canDecreaseTalent(pButton) then
            return
        end

        local tTab, _, tValue = MultiBot.talent.getTalentButtonContext(pButton)
        if not tTab then
            return
        end

        MultiBot.talent.updateTalentPoints(1)
        MultiBot.talent.applyTalentRankDelta(pButton, tTab, -1)

        if MultiBot.talent.getActiveTabState() == MultiBot.TalentTabStates.TALENTS then
            MultiBot.talent.__talentsApplyPending = true
        end
        MultiBot.talent.updateTalentValueFrame(pButton, tValue, true)
        local shouldShowValue = not (MultiBot.talent.points == 0 and pButton.value == 0)
        MultiBot.talent.setTalentValueVisibility(tValue, shouldShowValue)

        MultiBot.talent.doState()
        MultiBot.talent.refreshApplyTabVisibility()
    end

    MultiBot.talent.addTalent = function(pTab, pID, pNeeds, pValue, pMax, piX, piY, pTexture, pTips)
	local tTalent = pTab.addButton(pID, piX * pTab.grid.icons.size - pTab.grid.icons.x, pTab.grid.icons.y - piY * pTab.grid.icons.size, pTexture, pTips[pValue + 1])
        tTalent:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	tTalent.points = piY * 5 - 5
	tTalent.needs = pNeeds
	tTalent.value = pValue
	tTalent.tips = pTips
	tTalent.max = pMax
	tTalent.id = pID
	tTalent.doLeft = MultiBot.talent.onTalentLeftClick
	tTalent.doRight = MultiBot.talent.onTalentRightClick
	tTalent:SetFrameLevel(MultiBot.talent.getTalentTreeLayerLevel(pTab, 2))
	return tTalent
    end

    MultiBot.talent.addValue = function(pTab, pID, piX, piY, pRank, pMax)
	local tColor = MultiBot.IF(pRank > 0, MultiBot.IF(pRank < pMax, "|cff4db24d", "|cffffcc00"), "|cffffffff")
	local tValue = pTab.addFrame(pID, piX * pTab.grid.icons.size - pTab.grid.values.x, pTab.grid.values.y - piY * pTab.grid.icons.size, 24, 18, 12)
	tValue.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Black.blp")
	tValue.addText("Value", tColor .. pRank .. "/" .. pMax .. "|r", "CENTER", -0.5, 1, 10)
	if(MultiBot.talent.points == 0 and pRank == 0) then tValue:Hide() end
	tValue:SetFrameLevel(MultiBot.talent.getTalentTreeLayerLevel(pTab, 3))
	return tValue
    end

    function MultiBot.talent.extractTalentIdFromLink(link)
        local data = link and MultiBot.doSplit(link, "|")
        local talentData = data and data[3]
        if not talentData then
            return "0"
        end

        local parts = MultiBot.doSplit(talentData, ":")
        return parts and parts[2] or "0"
    end

    function MultiBot.talent.buildTalentTips(talentId, talentName, talentData)
        local tips = {
            "|cff4e96f7|Htalent:" .. talentId .. ":-1|h[" .. talentName .. "]|h|r",
        }

        for k = 5, #talentData do
            table.insert(tips, "|cff4e96f7|Htalent:" .. talentId .. ":" .. (k - 5) .. "|h[" .. talentName .. "]|h|r")
        end

        return tips
    end

    function MultiBot.talent.buildTalentTreeFromData(treeIndex, classRows, arrowRows, resolveTalent)
        local marker = MultiBot.talent.class .. treeIndex
        local tTab = MultiBot.talent.setGrid(MultiBot.talent.getTalentTreeFrame(treeIndex))
        tTab.setTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_" .. marker .. ".blp")
        tTab.value, tTab.id = 0, treeIndex

        for j = 1, #arrowRows do
            local arrowData = MultiBot.doSplit(arrowRows[j], ", ")
            local need = tonumber(arrowData[1])
            tTab.arrows[j] = MultiBot.talent.addArrow(tTab, j, need, arrowData[2], arrowData[3], arrowData[4])
        end

        for j = 1, #classRows do
            local talentData = MultiBot.doSplit(classRows[j], ", ")
            local resolved = resolveTalent(treeIndex, j, talentData)
            if not resolved then
                return nil
            end

            local rank = tonumber(resolved.rank or 0) or 0
            local max = #talentData - 4
            local need = tonumber(talentData[1])
            local talentId = tostring(resolved.talentId or "0")
            local talentName = resolved.name or "?"
            local tips = MultiBot.talent.buildTalentTips(talentId, talentName, talentData)

            tTab.value = tTab.value + rank
            MultiBot.talent.addTalent(tTab, j, need, rank, max, talentData[2], talentData[3], talentData[4], tips)
            MultiBot.talent.addValue(tTab, j, talentData[2], talentData[3], rank, max)
        end

        tTab.setText("Title", MultiBot.L("info.talent." .. marker) .. " (" .. tTab.value .. ")")
        return tTab
    end

    function MultiBot.talent.getTalentClassData(classKey)
        local talentsByClass = MultiBot.data and MultiBot.data.talent and MultiBot.data.talent.talents
        local arrowsByClass = MultiBot.data and MultiBot.data.talent and MultiBot.data.talent.arrows

        local tClass = talentsByClass and talentsByClass[classKey]
        if not tClass then
            print("|cffff0000[MultiBot] No build found for class " .. tostring(classKey) .. "!|r")
            return nil, nil
        end

        local tArrow = arrowsByClass and arrowsByClass[classKey]
        if not tArrow then
            print("|cffff0000[MultiBot] No arrow schem found for class " .. tostring(classKey) .. "!|r")
            return nil, nil
        end

        return tClass, tArrow
    end

    function MultiBot.talent.buildAllTalentTrees(tClass, tArrow, resolveTalent)
        return MultiBot.talent.forEachTalentTree(function(i)
            local classRows = tClass and tClass[i]
            local arrowRows = tArrow and tArrow[i]
            if not (classRows and arrowRows) then
                return true
            end

            local treeBuilt = MultiBot.talent.buildTalentTreeFromData(i, classRows, arrowRows, resolveTalent)
            if not treeBuilt then
                return true
            end

            return nil
        end) == true
    end

    function MultiBot.talent.applyTalentHeader(points, titleText, titleKey)
        MultiBot.talent.points = math.max(tonumber(points) or 0, 0)
        MultiBot.talent.setText("Points", MultiBot.L("info.talent.Points") .. MultiBot.talent.points)

        if titleText then
            MultiBot.talent.setText("Title", titleText)
        elseif titleKey then
            MultiBot.talent.setTalentTitleByKey(titleKey)
        end
    end

    function MultiBot.talent.isTalentApiReady()
        return GetTalentInfo(1, 1, true) and true or false
    end

    function MultiBot.talent.scheduleTalentBuildRetry(options)
        if type(options) ~= "table" then
            return false
        end

        if options.retryAfter and options.retryAction then
            MultiBot.TimerAfter(options.retryAfter, options.retryAction)
            return true
        end

        return false
    end

    function MultiBot.talent.resolveTalentBuildClassData()
        return MultiBot.talent.getTalentClassData(MultiBot.talent.class)
    end

    function MultiBot.talent.applyTalentBuildHeaderFromOptions(options)
        local points = options.getPoints and options.getPoints() or MultiBot.talent.points
        MultiBot.talent.applyTalentHeader(points, options.titleText, options.titleKey)
    end

    function MultiBot.talent.finalizeTalentBuild(options)
        MultiBot.talent.doState()
        MultiBot.talent:Show()

        if type(options.onSuccess) == "function" then
            options.onSuccess()
        end

        return true
    end

    function MultiBot.talent.renderTalentBuild(options)
        options = options or {}

        if options.requiresTalentApi ~= false and not MultiBot.talent.isTalentApiReady() then
            MultiBot.talent.scheduleTalentBuildRetry(options)
            return false
        end

        if options.clearBeforeBuild then
            MultiBot.talent.doClear()
        end

        local tClass, tArrow = MultiBot.talent.resolveTalentBuildClassData()
        if not (tClass and tArrow) then
            return false
        end

        MultiBot.talent.applyTalentBuildHeaderFromOptions(options)

        local buildFailed = MultiBot.talent.buildAllTalentTrees(tClass, tArrow, options.resolveTalent)
        if buildFailed then
            MultiBot.talent.scheduleTalentBuildRetry(options)
            return false
        end

        return MultiBot.talent.finalizeTalentBuild(options)
    end

    function MultiBot.talent.buildActiveTalentsResolver(activeGroup)
        return function(treeIndex, talentIndex)
            local link = GetTalentLink(treeIndex, talentIndex, true, nil, activeGroup)
            local talentId = MultiBot.talent.extractTalentIdFromLink(link)
            local talentName, _, _, _, rank = GetTalentInfo(treeIndex, talentIndex, true, nil, activeGroup)
            if not talentName then
                return nil
            end

            return {
                name = talentName,
                talentId = talentId,
                rank = rank,
            }
        end
    end

    function MultiBot.talent.buildCustomTalentsResolver()
        return function(treeIndex, talentIndex, talentData)
            local talentName, icon
            if MultiBot.talent.isTalentApiReady() then
                talentName, icon = GetTalentInfo(treeIndex, talentIndex, true)
            end

            local firstRankSpellId = tonumber(talentData and talentData[5]) or 0
            if (not talentName or talentName == "") and firstRankSpellId > 0 then
                talentName, _, icon = GetSpellInfo(firstRankSpellId)
            end

            if not talentName or talentName == "" then
                return nil
            end

            local link
            if MultiBot.talent.isTalentApiReady() then
                link = GetTalentLink(treeIndex, talentIndex, true)
            end

            local talentId = MultiBot.talent.extractTalentIdFromLink(link)
            if (not talentId or talentId == "0") and firstRankSpellId > 0 then
                talentId = tostring(firstRankSpellId)
            end

            return {
                name = talentName,
                talentId = talentId,
                rank = 0,
                icon = icon,
            }
        end
    end

    function MultiBot.talent.createTalentBuildOptions(baseOptions)
        return MultiBot.talent.copyOptionsTable(baseOptions)
    end

    function MultiBot.talent.getTalentsBuildOptions()
        local activeGroup = GetActiveTalentGroup(true) or 1

        return MultiBot.talent.createTalentBuildOptions({
            retryAfter = 0.1,
            retryAction = MultiBot.talent.setTalents,
            titleText = MultiBot.talent.getTalentTitleText(),
            getPoints = function()
                return tonumber(GetUnspentTalentPoints(true))
            end,
            resolveTalent = MultiBot.talent.buildActiveTalentsResolver(activeGroup),
            onSuccess = function()
                MultiBot.talent.__talentsTabApplyMode = MultiBot.talent.hasUnspentTalentPoints() and "apply" or "copy"
                MultiBot.talent.activateTalentsTabContext()
			MultiBot.auto.talent = false
            end,
        })
    end

    function MultiBot.talent.getCustomTalentsBuildOptions()
        return MultiBot.talent.createTalentBuildOptions({
            retryAfter = 0.05,
            retryAction = MultiBot.talent.setTalentsCustom,
            clearBeforeBuild = true,
            titleKey = "info.talentscustomtalentsfor",
            getPoints = function()
                local level = MultiBot.talent.getTalentBotLevel() or 80
                return level - 9
            end,
            resolveTalent = MultiBot.talent.buildCustomTalentsResolver(),
            requiresTalentApi = false,
            onSuccess = function()
                MultiBot.talent.activateTabState(MultiBot.TalentTabStates.CUSTOM_TALENTS)
            end,
        })
    end

    MultiBot.talent.setTalents = function()
        MultiBot.talent.__talentsTabApplyMode = nil
        MultiBot.talent.__talentsApplyPending = false
        MultiBot.talent.renderTalentBuild(MultiBot.talent.getTalentsBuildOptions())
    end

    function MultiBot.talent.updateTalentArrowState(tTab, tArrow)
	local isActive = tTab.buttons[tArrow.needs].value > 0
	tArrow.setTexture(isActive and tArrow.active or tArrow.inactive)
    end

    function MultiBot.talent.updateTalentArrows(tTab)
        MultiBot.talent.forEachIndexedEntry(tTab.arrows, function(_, arrow)
            MultiBot.talent.updateTalentArrowState(tTab, arrow)
            return nil
        end)
    end

    function MultiBot.talent.hideAndResetTalentTreeCollection(tTab, collectionKey)
        local entries = tTab and tTab[collectionKey]
        MultiBot.talent.forEachIndexedEntry(entries, function(_, entry)
            if entry and entry.Hide then
                entry:Hide()
            end
            return nil
        end)

        if type(entries) == "table" then
           for key in pairs(entries) do
               entries[key] = nil
           end
        end

        tTab[collectionKey] = {}
    end

    MultiBot.talent.doState = function()
	MultiBot.talent.forEachTalentTree(function(_, tTab)
            MultiBot.talent.forEachIndexedEntry(tTab.buttons, function(index, talentButton)
                local valueFrame = tTab.frames[index]
                local shouldEnable, shouldShow = MultiBot.talent.getTalentButtonState(tTab, talentButton)
                MultiBot.talent.applyTalentButtonState(talentButton, valueFrame, shouldEnable, shouldShow)
                return nil
            end)

		MultiBot.talent.updateTalentArrows(tTab)
	end)
    end

    MultiBot.talent.doClear = function()
	MultiBot.talent.forEachTalentTree(function(_, tTab)
            MultiBot.talent.hideAndResetTalentTreeCollection(tTab, "buttons")
            MultiBot.talent.hideAndResetTalentTreeCollection(tTab, "frames")
            MultiBot.talent.hideAndResetTalentTreeCollection(tTab, "arrows")
	end)
    end

    --[[
    Add a custom tab to talents windows to make custom builds (BOTTOM_TAB_CUSTOM_TALENTS)
    ]]--

    function MultiBot.talent.setTalentsCustom()
        MultiBot.talent.renderTalentBuild(MultiBot.talent.getCustomTalentsBuildOptions())
    end

    -- END TAB CUSTOM TALENTS --

    --[[
    Add a new tab to use custom Glyphs (BOTTOM_TAB_CUSTOM_GLYPHS)
    ]]--

    function MultiBot.talent.getGlyphItemType(itemID)
        if not MultiBot.talent.glyphTip then
            MultiBot.talent.glyphTip = ensureHiddenTooltip("MBHiddenTip", UIParent)
        end
        MultiBot.talent.glyphTip:ClearLines()
        MultiBot.talent.glyphTip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
        for i = 2, MultiBot.talent.glyphTip:NumLines() do
            local line = _G[MultiBot.talent.glyphTip:GetName().."TextLeft"..i]
            local txt = (line and line:GetText() or ""):lower()
            if txt:find("major glyph") then return "Major" end
            if txt:find("minor glyph") then return "Minor" end
        end
        return nil
    end

    function MultiBot.BuildGlyphClassTable()
        if MultiBot.__glyphClass then return end
        if not MultiBot.data or not MultiBot.data.talent or not MultiBot.data.talent.glyphs then return end
        MultiBot.__glyphClass = {}
        for clsKey, data in pairs(MultiBot.data.talent.glyphs) do
            for id in pairs(data.Major or {}) do
                MultiBot.__glyphClass[id] = clsKey
            end
            for id in pairs(data.Minor or {}) do
                MultiBot.__glyphClass[id] = clsKey
            end
        end
    end

    function MultiBot.talent.getGlyphSocketIndex(socketFrame)
        if not socketFrame then
            return nil
        end

        local socketIndex = socketFrame:GetID()
        if socketIndex == 0 then
            socketIndex = tonumber((socketFrame:GetName() or ""):match("Socket(%d+)"))
        end

        return socketIndex
    end

    function MultiBot.talent.isGlyphSocketUnlocked(socketFrame, level)
        local socketIndex = MultiBot.talent.getGlyphSocketIndex(socketFrame)
        if not socketIndex then
            return false
        end

        local requiredLevel = MultiBot.TalentTabLimits.SOCKET_REQUIREMENTS[socketIndex] or 1
        if type(level) ~= "number" then
            return socketFrame and socketFrame.locked ~= true
        end

        return level >= requiredLevel
    end

    function MultiBot.talent.resetGlyphSocketIconButton(button)
        if not button then
            return
        end

        if button.icon then button.icon:SetTexture(nil) end
        if button.bg then button.bg:Show() end
        button.glyphID = nil
        button.itemID = nil
        button.item = nil
        button.spellID = nil
        button.name = nil
        button.type = nil
        button:Show()
    end

    function MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, frameKey, visible)
        local frame = socketFrame and socketFrame.frames and socketFrame.frames[frameKey]
        if not frame then
            return
        end

        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end

    function MultiBot.talent.bindGlyphSocketIconButtonHandlers(button)
        if not button then
            return
        end

        button:RegisterForDrag("LeftButton")
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnEnter", MultiBot.talent.showGlyphTooltip)
        button:SetScript("OnLeave", MultiBot.talent.hideGlyphTooltip)
        button:SetScript("OnReceiveDrag", MultiBot.talent.onGlyphReceiveDrag)
        button:SetScript("OnClick", MultiBot.talent.onGlyphReceiveDrag)
        button:SetScript("OnMouseUp", function(self, mouseButton)
            if mouseButton == "RightButton" then
                MultiBot.talent.clearGlyphSocket(self:GetParent())
            end
        end)
    end

    function MultiBot.talent.ensureGlyphSocketIconButton(socketFrame)
        local button = socketFrame and socketFrame.frames and socketFrame.frames.IconBtn
        if button then
            MultiBot.talent.bindGlyphSocketIconButtonHandlers(button)
            return button
        end

        button = MultiBot.talent.createGlyphSocketIconButton(socketFrame)
        if socketFrame and socketFrame.frames then
            socketFrame.frames.IconBtn = button
        end

        return button
    end

    function MultiBot.talent.resolveGlyphDragPayload(itemID, classKey, level)
        if MultiBot.BuildGlyphClassTable then
            MultiBot.BuildGlyphClassTable()
        end

        local gDB = (MultiBot.data.talent.glyphs or {})[classKey] or {}
        local glyphClass = MultiBot.__glyphClass and MultiBot.__glyphClass[itemID]
        if glyphClass and glyphClass ~= classKey then
            return nil, MultiBot.L("info.glyphswrongclass")
        end

        local glyphType, glyphInfo
        if gDB.Major and gDB.Major[itemID] then
            glyphType, glyphInfo = "Major", gDB.Major[itemID]
        elseif gDB.Minor and gDB.Minor[itemID] then
            glyphType, glyphInfo = "Minor", gDB.Minor[itemID]
        else
            glyphType = MultiBot.talent.getGlyphItemType(itemID)
            if not glyphType then
                return nil, MultiBot.L("info.glyphsunknowglyph")
            end
        end

        if glyphInfo then
            local reqLvl = tonumber((strsplit(",%s*", glyphInfo)))
            if reqLvl and reqLvl > level then
                return nil, MultiBot.L("info.glyphsleveltoolow")
            end
        end

        return {
            glyphType = glyphType,
            glyphInfo = glyphInfo,
        }, nil
    end

    function MultiBot.talent.applyGlyphToSocket(socketFrame, button, itemID, glyphInfo)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Glow", true)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Overlay", true)
        if button.bg then button.bg:Hide() end

        local runeIdx = glyphInfo and select(2, strsplit(",%s*", glyphInfo)) or "1"
        local rune = socketFrame.frames.Rune
        if rune then
            (rune.texture or rune):SetTexture(MultiBot.SafeTexturePath("Interface\\Spellbook\\UI-Glyph-Rune-" .. runeIdx))
            rune:Show()
        end

        local tex = select(10, GetItemInfo(itemID))
        if not tex and type(GetItemIcon) == "function" then
            tex = GetItemIcon(itemID)
        end
        tex = tex or GetSpellTexture(itemID)
        local isFallback = tex == nil
        tex = tex or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
        MultiBot.talent.applyGlyphSocketIconLayout(button, socketFrame, isFallback)
        button.icon:SetTexture(MultiBot.SafeTexturePath(tex))
        button.icon:Show()
        if button.bg then
            button.bg:Hide()
        end
        button.glyphID = itemID
        button.itemID = itemID
        button.item = itemID
        button.spellID = nil
        button.type = socketFrame.socketType or socketFrame.type
        socketFrame.item = itemID
    end

    function MultiBot.talent.clearGlyphSocket(socketFrame)
        if MultiBot.talent.getActiveTabState() ~= MultiBot.TalentTabStates.CUSTOM_GLYPHS then
            return
        end

        socketFrame.item = 0

        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Rune", false)
        local button = socketFrame and socketFrame.frames and socketFrame.frames.IconBtn
        if button then
            MultiBot.talent.resetGlyphSocketIconButton(button)
        end

	MultiBot.talent.refreshApplyTabVisibility()
    end

    function MultiBot.talent.ensureGlyphIconButtonBackground(btn, socketType, parent)
        if btn.bg then return end
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints(parent)
        local texSlot = (socketType == "Minor") and
                        "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp" or
                        "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp"
        btn.bg:SetTexture(MultiBot.SafeTexturePath(texSlot))
    end

    function MultiBot.talent.onGlyphReceiveDrag(self)
        if MultiBot.talent.getActiveTabState() ~= MultiBot.TalentTabStates.CUSTOM_GLYPHS then
            return
        end

        local typ, itemID = GetCursorInfo()
        if typ ~= "item" then return end

        local socket = self and self:GetParent()
        if not socket then
            return
        end

        local lvl = MultiBot.talent.getTalentBotLevel() or socket.__cachedBotLevel
        if not MultiBot.talent.isGlyphSocketUnlocked(socket, lvl) then
            UIErrorsFrame:AddMessage(MultiBot.L("info.glyphssocketnotunlocked"), 1, 0.3, 0.3, 1)
            return
        end

        local classKey = MultiBot.talent.getTalentBotClassKey()
        if not classKey then
            return
        end
        local payload, payloadError = MultiBot.talent.resolveGlyphDragPayload(itemID, classKey, lvl)
        if not payload then
            UIErrorsFrame:AddMessage(payloadError, 1, 0.3, 0.3, 1)
            return
        end

        local expectedGlyphType = socket.socketType or socket.type or "Major"
        if payload.glyphType ~= expectedGlyphType then
            UIErrorsFrame:AddMessage(MultiBot.L("info.glyphsglyphtype") .. payload.glyphType .. " : " .. MultiBot.L("info.glyphsglyphsocket"), 1, 0.3, 0.3, 1)
            return
        end

        MultiBot.talent.applyGlyphToSocket(socket, self, itemID, payload.glyphInfo)
        ClearCursor()
        MultiBot.talent.refreshApplyTabVisibility()
    end

    function MultiBot.talent.ensureGlyphSocketOverlay(socketFrame)
        local overlay = socketFrame and socketFrame.frames and socketFrame.frames.Overlay
        if overlay and not overlay.texture then
            overlay.texture = overlay:CreateTexture(nil, "BORDER")
            overlay.texture:SetAllPoints(overlay)
            local base = "Interface\\AddOns\\MultiBot\\Textures\\"
            overlay.texture:SetTexture(base .. (socketFrame.type == "Major" and "gliph_majeur_layout.blp" or "gliph_mineur_layout.blp"))
        end

        return overlay
    end

    function MultiBot.talent.createGlyphSocketIconButton(socketFrame)
        local btn = CreateFrame("Button", nil, socketFrame)
        btn:SetAllPoints(socketFrame)
        MultiBot.talent.ensureGlyphIconButtonBackground(btn, socketFrame.socketType or socketFrame.type, socketFrame)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        btn.icon = icon
        MultiBot.talent.applyGlyphSocketIconLayout(btn, socketFrame, false)

        MultiBot.talent.bindGlyphSocketIconButtonHandlers(btn)

        return btn
    end

    function MultiBot.talent.applyGlyphSocketLockState(socketFrame)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Glow", false)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Overlay", false)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Rune", false)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "IconBtn", false)
        socketFrame.locked = true
    end

    function MultiBot.talent.applyGlyphSocketUnlockedState(socketFrame)
        socketFrame.locked = false

        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Glow", true)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Overlay", true)
        MultiBot.talent.setGlyphSocketElementVisibility(socketFrame, "Rune", false)

        local btn = MultiBot.talent.ensureGlyphSocketIconButton(socketFrame)
        MultiBot.talent.ensureGlyphIconButtonBackground(btn, socketFrame.type, socketFrame)
        if btn.icon then btn.icon:Show() end
        MultiBot.talent.resetGlyphSocketIconButton(btn)
        socketFrame.item = 0
    end

    function MultiBot.talent.updateCustomGlyphSocketState(socketFrame, socketIndex, botLevel)
        socketFrame:SetID(socketIndex)
        MultiBot.talent.ensureGlyphSocketOverlay(socketFrame)

        if type(botLevel) == "number" and botLevel > 0 then
            socketFrame.__cachedBotLevel = botLevel
        end

        if not MultiBot.talent.isGlyphSocketUnlocked(socketFrame, botLevel) then
            MultiBot.talent.applyGlyphSocketLockState(socketFrame)
        else
            MultiBot.talent.applyGlyphSocketUnlockedState(socketFrame)
        end
    end

    function MultiBot.talent.refreshAllCustomGlyphSockets(level)
        local botLevel = tonumber(level or MultiBot.talent.getTalentBotLevel() or MultiBot.talent.__cachedBotLevel)
        MultiBot.talent.forEachGlyphSocket(function(i, socket)
            if socket then
                MultiBot.talent.updateCustomGlyphSocketState(socket, i, botLevel)
            end
        end)
    end

    function MultiBot.talent.showCustomGlyphs()
        MultiBot.talent.activateTabState(
            MultiBot.TalentTabStates.CUSTOM_GLYPHS,
            {
                titleKey = nil,
            },
            function()
                MultiBot.talent.refreshAllCustomGlyphSockets()
            end
        )
    end

    -- END TAB CUSTOM GLYPHS --

    --[[
    Tab9: Copy — replaces the old copy button
    BOTTOM_TAB_COPY: Copy — replaces the old copy button
    ]]--

    function MultiBot.talent.getBottomTabButton(tabKey)
        local tab = MultiBot.talent.tabTextures and MultiBot.talent.tabTextures[tabKey]
        return tab and tab.btn
    end

    function MultiBot.talent.pulseCopyTabText()
        local btn = MultiBot.talent.getBottomTabButton(MultiBot.TalentTabKeys.COPY)
        if not (btn and btn.text) then
            return
        end

        local flashes = 0
        local maxFlashes = 6
        local pulseDelay = 0.15

        local function pulse()
            if flashes >= maxFlashes then
                btn.text:SetText("|cffaaaaaa " .. MultiBot.TalentTabLabels.COPY .. "|r")
                return
            end

            if flashes % 2 == 0 then
                btn.text:SetText("|cffffffff " .. MultiBot.TalentTabLabels.COPY .. "|r")
            else
                btn.text:SetText("|cffff4444 " .. MultiBot.TalentTabLabels.COPY .. "|r")
            end

            flashes = flashes + 1
            MultiBot.TimerAfter(pulseDelay, pulse)
        end

        pulse()
    end

    function MultiBot.talent.applyActiveTabSelection()
        return MultiBot.talent.applySelectionForState(MultiBot.talent.getActiveTabState())
    end

    function MultiBot.talent.resetDefaultTabVisualState()
        MultiBot.talent.resetBottomTabVisuals(MultiBot.TalentTabDefaults.ACTIVE, MultiBot.TalentTabDefaults.ACTIVE_LABEL)
    end

    function MultiBot.talent.runCopyTabAction()
        MultiBot.talent.copyCustomTalentsToTarget()
        MultiBot.talent.pulseCopyTabText()

        MultiBot.talent.resetDefaultTabVisualState()
    end

    function MultiBot.talent.runApplyTabAction()
        local activeState = MultiBot.talent.getActiveTabState()
        local applied = MultiBot.talent.applyActiveTabSelection()
        if applied and activeState == MultiBot.TalentTabStates.TALENTS then
            MultiBot.talent.__talentsApplyPending = false
        end

        MultiBot.talent.refreshApplyTabVisibility()
        return applied
    end

    function MultiBot.talent.onCopyTabClick()
        MultiBot.talent.runCopyTabAction()
    end

    function MultiBot.talent.onApplyTabClick()
        MultiBot.talent.runApplyTabAction()
    end

    MultiBot.talent.__moduleInitialized = true

end