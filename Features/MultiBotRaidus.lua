local MultiBotRaidusClassWeight = {
    DeathKnight = 1,
    Druid       = 2,
    Hunter      = 3,
    Mage        = 4,
    Paladin     = 5,
    Priest      = 6,
    Rogue       = 7,
    Shaman      = 8,
    Warlock     = 9,
    Warrior     = 10,
}

-- Rôle par défaut par classe (fallback si on ne peut pas lire les talents)
local MultiBotRaidusRoleDefaults = {
    DeathKnight = "TANK",
    Druid       = "HEAL",
    Hunter      = "DPS",
    Mage        = "DPS",
    Paladin     = "TANK",
    Priest      = "HEAL",
    Rogue       = "DPS",
    Shaman      = "HEAL",
    Warlock     = "DPS",
    Warrior     = "TANK",
}

-- Rôle par classe ET par arbre de talents dominant (index 1 / 2 / 3)
-- L’ordre des arbres est celui du client (1er onglet, 2ème, 3ème) et ne dépend pas de la langue.
local MultiBotRaidusRoleByTree = {
    Paladin     = { "HEAL", "TANK", "DPS" },        -- Sacré, Protection, Vindicte
    Warrior     = { "DPS",  "DPS",  "TANK" },       -- Armes, Fureur, Protection
    Druid       = { "DPS",  "TANK", "HEAL" },       -- Equilibre, Farouche, Restauration
    Priest      = { "HEAL", "HEAL", "DPS" },        -- Discipline, Sacré, Ombre
    Shaman      = { "DPS",  "DPS",  "HEAL" },       -- Élémentaire, Amélio, Restauration
    DeathKnight = { "TANK", "TANK", "DPS" },        -- Sang, Givre, Impie (approximation raid)
    Hunter      = { "DPS",  "DPS",  "DPS" },        -- Maîtrise des bêtes, Précision, Survie
    Rogue       = { "DPS",  "DPS",  "DPS" },        -- Assassinat, Combat, Finesse
    Mage        = { "DPS",  "DPS",  "DPS" },        -- Arcanes, Feu, Givre
    Warlock     = { "DPS",  "DPS",  "DPS" },        -- Affliction, Démonologie, Destruction
}

-- Détection de rôle indépendante de la langue :
--  On lit la répartition de talents "x/y/z"
--  On prend l'arbre dominant (1,2,3)
--  On mappe (classe, arbre) -> rôle TANK/HEAL/DPS
--  Fallback sur MultiBotRaidusRoleDefaults
local function MultiBotRaidusDetectRole(bot)
    if not bot then
        return "DPS"
    end

    -- Classe normalisée (MultiBot.toClass sait déjà gérer les noms de classes localisés)
    local class = MultiBot.toClass(bot.class)
    local talents = bot.talents or ""

    -- les talents doivent ressembler à par exemple "54/17/0"
    local t1, t2, t3 = talents:match("^(%d+)%/(%d+)%/(%d+)$")
    t1, t2, t3 = tonumber(t1), tonumber(t2), tonumber(t3)

    if t1 and t2 and t3 then
        local total = t1 + t2 + t3
        if total > 0 then
            local maxIndex = 1

            if t2 > t1 and t2 >= t3 then
                maxIndex = 2
            elseif t3 > t1 and t3 > t2 then
                maxIndex = 3
            end

            local byTree = MultiBotRaidusRoleByTree[class]
            if byTree and byTree[maxIndex] then
                return byTree[maxIndex]
            end
        end
    end

    -- Si on ne peut pas lire les talents ou que la classe n'est pas mappée on fallback
    local baseRole = MultiBotRaidusRoleDefaults[class]
    if baseRole then
        return baseRole
    end

    return "DPS"
end

-- MB_RAIDUS_STRUCTURED_LIFECYCLE_V1_BEGIN
local raidusLifecyclePending = {}

local function getRaidusLifecycleComm()
    local bridge = MultiBot and MultiBot.bridge
    local comm = MultiBot and MultiBot.Comm
    if not bridge or bridge.connected ~= true
        or bridge.botLifecycleCapable ~= true
        or bridge.botTargetResolveCapable ~= true
        or not comm
        or type(comm.ResolveBotTarget) ~= "function"
        or type(comm.RunBotLifecycle) ~= "function" then
        return nil
    end

    return comm
end

local function finishRaidusLifecyclePending(key, entry, refreshPool)
    if raidusLifecyclePending[key] == entry then
        raidusLifecyclePending[key] = nil
    end

    if refreshPool == true
        and MultiBot
        and MultiBot.raidus
        and type(MultiBot.raidus.ValidatePool) == "function" then
        MultiBot.raidus.ValidatePool(true)
    end
end

local function runRaidusLifecycleForName(name, mode, refreshPool)
    if type(name) ~= "string" or name == "" then
        return false
    end

    mode = string.upper(tostring(mode or "TOGGLE"))
    if mode ~= "TOGGLE" and mode ~= "DISCONNECT" then
        return false
    end

    local comm = getRaidusLifecycleComm()
    if not comm then
        if MultiBot and MultiBot.bridge then
            MultiBot.bridge.lastError = "RAIDUS_LIFECYCLE_UNAVAILABLE"
        end
        return false
    end

    local key = string.lower(name)
    if raidusLifecyclePending[key] ~= nil then
        return false
    end

    local entry = {
        name = name,
        mode = mode,
        phase = "RESOLVING",
    }
    raidusLifecyclePending[key] = entry

    local resolveToken = comm.ResolveBotTarget(name, function(result)
        if raidusLifecyclePending[key] ~= entry or entry.phase ~= "RESOLVING" then
            return
        end

        if not result or string.upper(tostring(result.status or "")) ~= "OK" then
            finishRaidusLifecyclePending(key, entry, false)
            return
        end

        local guid = tonumber(result.guid)
        local lifecycleState = string.upper(tostring(result.lifecycleState or ""))
        local reason = string.upper(tostring(result.reason or ""))

        if not guid or guid <= 0 or reason == "IN_USE" then
            finishRaidusLifecyclePending(key, entry, false)
            return
        end

        local action = nil
        if mode == "DISCONNECT" then
            if lifecycleState == "ONLINE" then
                action = "DISCONNECT"
            end
        elseif lifecycleState == "ONLINE" then
            action = "DISCONNECT"
        elseif lifecycleState == "OFFLINE" then
            action = "CONNECT"
        end

        if not action then
            finishRaidusLifecyclePending(key, entry, false)
            return
        end

        entry.phase = "MUTATING"
        entry.action = action

        local lifecycleToken = comm.RunBotLifecycle(action, guid, function(lifecycleResult)
            if raidusLifecyclePending[key] ~= entry or entry.phase ~= "MUTATING" then
                return
            end

            if lifecycleResult and lifecycleResult.final == false then
                return
            end

            finishRaidusLifecyclePending(key, entry, refreshPool == true)
        end)

        if not lifecycleToken then
            finishRaidusLifecyclePending(key, entry, false)
        end
    end)

    if not resolveToken then
        finishRaidusLifecyclePending(key, entry, false)
        return false
    end

    return true
end
-- MB_RAIDUS_STRUCTURED_LIFECYCLE_V1_END

MultiBot.raidus = MultiBot.newFrame(MultiBot, -340, -126, 32, 884, 884)
MultiBot.raidus:SetMovable(true)
MultiBot.raidus:Hide()

local function syncRaidusMainButtonState(isVisible)
    local mainFrame = MultiBot.frames and MultiBot.frames["MultiBar"] and MultiBot.frames["MultiBar"].frames and MultiBot.frames["MultiBar"].frames["Main"]
    local raidusButton = mainFrame and mainFrame.buttons and mainFrame.buttons["Raidus"]
    if not raidusButton then
        return
    end

    if isVisible then
        if raidusButton.setEnable then
            raidusButton.setEnable()
        end
    else
        if raidusButton.setDisable then
            raidusButton.setDisable()
        end
    end
end

MultiBot.raidus:HookScript("OnShow", function()
    syncRaidusMainButtonState(true)
    if type(MultiBot.raidus.ValidatePool) == "function" then
        MultiBot.raidus.ValidatePool(false)
    end
end)

MultiBot.raidus:HookScript("OnHide", function()
    syncRaidusMainButtonState(false)
end)

local raidusUsesAceWindow = false

local function getRaidusAceGUI()
    if type(LibStub) ~= "table" then
        return nil
    end

    local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
    if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
        return aceGUI
    end

    return nil
end

local function initRaidusAceWindow()
    local aceGUI = getRaidusAceGUI()
    if not aceGUI then
        return
    end

    local window = aceGUI:Create("Window")
    if not window or not window.frame or not window.content then
        return
    end

    raidusUsesAceWindow = true

    window:SetTitle("MultiBot - Raidus")
    window:SetWidth(920)
    window:SetHeight(630)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")

    MultiBot.raidus:SetParent(window.content)
    MultiBot.raidus:ClearAllPoints()
    MultiBot.raidus:SetPoint("TOP", window.content, "TOP", 0, -12)

    local visibilitySync = false
    local raidusShow = MultiBot.raidus.Show
    local raidusHide = MultiBot.raidus.Hide

    window:SetCallback("OnClose", function()
        if visibilitySync then
            return
        end

        visibilitySync = true
        raidusHide(MultiBot.raidus)
        window:Hide()
        visibilitySync = false
    end)

    MultiBot.raidus.Show = function(frame, ...)
        if visibilitySync then
            return raidusShow(frame, ...)
        end

        visibilitySync = true
        window:Show()
        local result = raidusShow(frame, ...)
        visibilitySync = false
        return result
    end

    MultiBot.raidus.Hide = function(frame, ...)
        if visibilitySync then
            return raidusHide(frame, ...)
        end

        visibilitySync = true
        local result = raidusHide(frame, ...)
        window:Hide()
        visibilitySync = false
        return result
    end

    window:Hide()
end

initRaidusAceWindow()

if not raidusUsesAceWindow then
    MultiBot.raidus.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus.blp")
end

MultiBot.raidus.addFrame("Pool", -20, 360, 28, 160, 490)
if not raidusUsesAceWindow then
    MultiBot.raidus.addFrame("Btop", -35, 822, 24, 128, 32).addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Banner_Top.blp")
    MultiBot.raidus.addFrame("Bbot", -35, 354, 24, 128, 32).addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Banner_Bottom.blp")
end

local RAIDUS_GROUP_SHIFT_X = -30
local RAIDUS_GROUP_PANEL_X = -180 + RAIDUS_GROUP_SHIFT_X
local RAIDUS_GROUP_PANEL_Y = 360
local RAIDUS_GROUP_PANEL_WIDTH = 665 -- Raid Frame Widht
local RAIDUS_GROUP_PANEL_HEIGHT = 490
local RAIDUS_POOL_PANEL_X = -18
local RAIDUS_POOL_PANEL_Y = 360
local RAIDUS_POOL_PANEL_WIDTH = 165
local RAIDUS_POOL_PANEL_HEIGHT = 490

local RAIDUS_GROUP_SLOT_WIDTH = 160 -- Group Frame Widht

local RAIDUS_SLOT_TEXTURE_INSET_X = 6 -- grey background widht, minus this value
local RAIDUS_SLOT_TEXTURE_INSET_Y = 4 -- grey background height, minus this value
local RAIDUS_SLOT_BORDER_INSET_X = 4 -- occuped frame widht, minus this value
local RAIDUS_SLOT_BORDER_INSET_Y = 0 -- occuped frame height, minus this value

local function applyRaidusSlotTextureInset(slotFrame, insetX, insetY)
    if not slotFrame or not slotFrame.texture then
        return
    end

    local x = insetX or RAIDUS_SLOT_TEXTURE_INSET_X
    local y = insetY or RAIDUS_SLOT_TEXTURE_INSET_Y

    slotFrame.texture:ClearAllPoints()
    slotFrame.texture:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", x, -y)
    slotFrame.texture:SetPoint("BOTTOMRIGHT", slotFrame, "BOTTOMRIGHT", -x, y)
end

local function formatRaidusBadgeLabel(text)
    return "|cffd4af37[|r " .. tostring(text or "") .. " |cffd4af37]|r"
end

local RAIDUS_SCORE_ANCHOR = "TOPLEFT"
local RAIDUS_SCORE_OFFSET_X = 26
local RAIDUS_SCORE_OFFSET_Y = -14
local RAIDUS_SCORE_FONT_SIZE = 12

local function formatRaidusScoreLabel(score)
    return "|cffd4af37[|r |cffffcc00RaidScore|r |cffb8b8b8" .. tostring(score or 0) .. "|r |cffd4af37]|r"
end

local function ApplyRaidusGroupCardChrome(groupFrame, groupIndex)
    if not groupFrame or groupFrame._cardStyled or not groupFrame.SetBackdrop then
        return
    end

    local topRow = groupIndex <= 4
    local bgAlpha = topRow and 0.30 or 0.26

    groupFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    groupFrame:SetBackdropColor(0, 0, 0, bgAlpha)
    groupFrame:SetBackdropBorderColor(0.78, 0.62, 0.18, 0.42)
    groupFrame._cardStyled = true
end

MultiBot.raidus.addFrame("Group8", -185 + RAIDUS_GROUP_SHIFT_X, 364, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group7", -350 + RAIDUS_GROUP_SHIFT_X, 364, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group6", -515 + RAIDUS_GROUP_SHIFT_X, 364, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group5", -680 + RAIDUS_GROUP_SHIFT_X, 364, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group4", -185 + RAIDUS_GROUP_SHIFT_X, 604, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group3", -350 + RAIDUS_GROUP_SHIFT_X, 604, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group2", -515 + RAIDUS_GROUP_SHIFT_X, 604, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addFrame("Group1", -680 + RAIDUS_GROUP_SHIFT_X, 604, 28, RAIDUS_GROUP_SLOT_WIDTH, 240)
MultiBot.raidus.addText("RaidScore", formatRaidusScoreLabel(0), RAIDUS_SCORE_ANCHOR, RAIDUS_SCORE_OFFSET_X, RAIDUS_SCORE_OFFSET_Y, RAIDUS_SCORE_FONT_SIZE)

local function CreateRaidusGoldOutline(x, y, width, height)
    local outline = CreateFrame("Frame", nil, MultiBot.raidus)
    outline:SetPoint("BOTTOMRIGHT", x, y)
    outline:SetSize(width, height)
    outline:EnableMouse(false)
    outline:SetFrameLevel(MultiBot.raidus:GetFrameLevel() + 1)

    if outline.SetBackdrop then
        outline:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        outline:SetBackdropColor(0, 0, 0, 0.10)
        outline:SetBackdropBorderColor(1, 0.82, 0, 0.75)
    end

    return outline
end

local function CreateRaidusPanelChrome(panelKey, x, y, width, height, title)
    local panel = CreateFrame("Frame", nil, MultiBot.raidus)
    panel:SetPoint("BOTTOMRIGHT", x, y)
    panel:SetSize(width, height)
    panel:EnableMouse(false)
    panel:SetFrameLevel(MultiBot.raidus:GetFrameLevel())

    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local isGroupsPanel = panelKey == "GroupsPanel"
        panel:SetBackdropColor(0, 0, 0, isGroupsPanel and 0.40 or 0.30)
        panel:SetBackdropBorderColor(isGroupsPanel and 0.44 or 0.30, isGroupsPanel and 0.34 or 0.22, isGroupsPanel and 0.10 or 0.08, isGroupsPanel and 0.62 or 0.42)
    end

    panel.texts = panel.texts or {}
    panel.texts["Title"] = panel:CreateFontString(nil, "ARTWORK")
    panel.texts["Title"]:SetFont("Fonts\\ARIALN.ttf", 16, "PLAIN")
    panel.texts["Title"]:SetPoint("BOTTOM", panel, "TOP", 0, 8)
    panel.texts["Title"]:SetText("|cffffcc00" .. title .. "|r")
    panel.texts["Title"]:Show()
    return panel
end

local raidusManageGroupsLabel = MultiBot.L("info.managegroups")
local raidusAvailableBotsLabel = MultiBot.L("info.avalaiblebots")

CreateRaidusPanelChrome("GroupsPanel", RAIDUS_GROUP_PANEL_X, RAIDUS_GROUP_PANEL_Y, RAIDUS_GROUP_PANEL_WIDTH, RAIDUS_GROUP_PANEL_HEIGHT, raidusManageGroupsLabel)
CreateRaidusPanelChrome("PoolPanel", RAIDUS_POOL_PANEL_X, RAIDUS_POOL_PANEL_Y, RAIDUS_POOL_PANEL_WIDTH, RAIDUS_POOL_PANEL_HEIGHT, raidusAvailableBotsLabel)
CreateRaidusGoldOutline(RAIDUS_GROUP_PANEL_X, RAIDUS_GROUP_PANEL_Y, RAIDUS_GROUP_PANEL_WIDTH, RAIDUS_GROUP_PANEL_HEIGHT)
CreateRaidusGoldOutline(RAIDUS_POOL_PANEL_X, RAIDUS_POOL_PANEL_Y, RAIDUS_POOL_PANEL_WIDTH, RAIDUS_POOL_PANEL_HEIGHT)

local RAIDUS_GROUP_COUNT = 8
local RAIDUS_GROUP_SLOT_COUNT = 5
local RAIDUS_POOL_PAGE_SIZE = 11

local RAIDUS_CLASS_SLOT_COLORS = {
	DeathKnight = { 0.77, 0.12, 0.23, 0.35 },
	Druid       = { 1.00, 0.49, 0.04, 0.35 },
	Hunter      = { 0.67, 0.83, 0.45, 0.35 },
	Mage        = { 0.41, 0.80, 0.94, 0.35 },
	Paladin     = { 0.96, 0.55, 0.73, 0.35 },
	Priest      = { 1.00, 1.00, 1.00, 0.35 },
	Rogue       = { 1.00, 0.96, 0.41, 0.35 },
	Shaman      = { 0.00, 0.44, 0.87, 0.35 },
	Warlock     = { 0.58, 0.51, 0.79, 0.35 },
	Warrior     = { 0.78, 0.61, 0.43, 0.35 },
}

local RAIDUS_ROLE_COLORS = {
    TANK = { 0.33, 0.61, 0.96, 1.00 },
    HEAL = { 0.32, 0.84, 0.46, 1.00 },
    DPS  = { 0.92, 0.33, 0.33, 1.00 },
}

local function formatRaidusRoleLabel(role)
    if role == "TANK" then
        return "Tank"
    elseif role == "HEAL" then
        return "Heal"
    end
    return "DPS"
end

local function getRaidusClassHexColor(className)
    local color = RAIDUS_CLASS_SLOT_COLORS[className]
    if not color then
        return "ffffffff"
    end

    local r = math.floor((color[1] or 1) * 255 + 0.5)
    local g = math.floor((color[2] or 1) * 255 + 0.5)
    local b = math.floor((color[3] or 1) * 255 + 0.5)
    return string.format("ff%02x%02x%02x", r, g, b)
end

local function ensureRaidusRoleBorder(slotFrame)
    if not slotFrame or slotFrame.roleBorder then
        return
    end

    local border = CreateFrame("Frame", nil, slotFrame)
    border:SetAllPoints(slotFrame)
    border:EnableMouse(false)
    border:SetFrameLevel(slotFrame:GetFrameLevel() + 2)

    local function edge(anchor, point, x, y, width, height)
        local tex = border:CreateTexture(nil, "OVERLAY")
        tex:SetTexture(MultiBot.SafeTexturePath("Interface\\Buttons\\WHITE8X8"))
        tex:SetPoint(anchor, border, point, x, y)
        tex:SetSize(width, height)
        return tex
    end

    border.top = edge("TOPLEFT", "TOPLEFT", 0, 0, 1, 1)
    border.bottom = edge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 1, 1)
    border.left = edge("TOPLEFT", "TOPLEFT", 0, 0, 1, 1)
    border.right = edge("TOPRIGHT", "TOPRIGHT", 0, 0, 1, 1)

    slotFrame.roleBorder = border
end

local function setRaidusSlotRoleBorder(slotFrame, role, alpha)
    if not slotFrame then
        return
    end

    ensureRaidusRoleBorder(slotFrame)
    if not slotFrame.roleBorder then
        return
    end

    local border = slotFrame.roleBorder
    local color = RAIDUS_ROLE_COLORS[role or ""]
    local r, g, b = 0.45, 0.45, 0.45
    if color then
        r, g, b = color[1], color[2], color[3]
    end

    local width = math.max((slotFrame.width or slotFrame:GetWidth() or 0) - (RAIDUS_SLOT_BORDER_INSET_X * 2), 1)
    local height = math.max((slotFrame.height or slotFrame:GetHeight() or 0) - (RAIDUS_SLOT_BORDER_INSET_Y * 2), 1)
    border.top:SetPoint("TOPLEFT", border, "TOPLEFT", RAIDUS_SLOT_BORDER_INSET_X, -RAIDUS_SLOT_BORDER_INSET_Y)
    border.top:SetSize(width, 1)
    border.bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", RAIDUS_SLOT_BORDER_INSET_X, RAIDUS_SLOT_BORDER_INSET_Y)
    border.bottom:SetSize(width, 1)
    border.left:SetPoint("TOPLEFT", border, "TOPLEFT", RAIDUS_SLOT_BORDER_INSET_X, -RAIDUS_SLOT_BORDER_INSET_Y)
    border.left:SetSize(1, height)
    border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", -RAIDUS_SLOT_BORDER_INSET_X, -RAIDUS_SLOT_BORDER_INSET_Y)
    border.right:SetSize(1, height)

    local a = alpha or 0.25
    border.top:SetVertexColor(r, g, b, a)
    border.bottom:SetVertexColor(r, g, b, a)
    border.left:SetVertexColor(r, g, b, a)
    border.right:SetVertexColor(r, g, b, a)
end

local RAIDUS_DROP_ANIM_DURATION = 0.12
local RAIDUS_FEEDBACK_DURATION = 1.4
local RAIDUS_FEEDBACK_ANCHOR = "TOPLEFT"
local RAIDUS_FEEDBACK_OFFSET_X = 26
local RAIDUS_FEEDBACK_OFFSET_Y = 14

local raidusFeedbackToken = 0
local function clearRaidusDropFeedback(token)
    if token ~= raidusFeedbackToken then
        return
    end
    local feedbackText = MultiBot.raidus and MultiBot.raidus.texts and MultiBot.raidus.texts["DropFeedback"]
    if feedbackText then
        feedbackText:SetText("")
        feedbackText:Hide()
    end
end

local function showRaidusDropFeedback(message)
    if not MultiBot.raidus then
        return
    end

    local text = tostring(message or "")
    if text == "" then
        return
    end

    if MultiBot.raidus.texts and MultiBot.raidus.texts["DropFeedback"] then
        MultiBot.raidus.setText("DropFeedback", "|cffb8b8b8" .. text .. "|r")
        MultiBot.raidus.texts["DropFeedback"]:Show()
    else
        MultiBot.raidus.addText("DropFeedback", "|cffb8b8b8" .. text .. "|r", RAIDUS_FEEDBACK_ANCHOR, RAIDUS_FEEDBACK_OFFSET_X, RAIDUS_FEEDBACK_OFFSET_Y, 15)
    end

    raidusFeedbackToken = raidusFeedbackToken + 1
    local token = raidusFeedbackToken
    local timerAfter = MultiBot.TimerAfter or _G.TimerAfter
    if type(timerAfter) == "function" then
        timerAfter(RAIDUS_FEEDBACK_DURATION, function()
            clearRaidusDropFeedback(token)
        end)
    else
        clearRaidusDropFeedback(token)
    end
end

local function playRaidusDropPulse(slotFrame)
    if not slotFrame then
        return
    end

    local driver = slotFrame._dropPulseDriver
    if not driver then
        driver = CreateFrame("Frame", nil, slotFrame)
        driver:SetAllPoints(slotFrame)
        slotFrame._dropPulseDriver = driver
    end

    driver.elapsed = 0
    driver:Show()
    -- M11 ownership: keep this OnUpdate local.
    -- Reason: pulse scale animation is frame-driven and intentionally not timer-based.
    driver:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local progress = self.elapsed / RAIDUS_DROP_ANIM_DURATION

        if progress >= 1 then
            slotFrame:SetScale(1)
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end

        local pulse = (progress < 0.5) and (progress * 2) or ((1 - progress) * 2)
        slotFrame:SetScale(1 + (0.03 * pulse))
    end)
end

local function getRaidusSlotColor(slotFrame)
	if not slotFrame or not slotFrame.bot or not slotFrame.bot.class then
		return nil
	end

	local className = MultiBot.toClass(slotFrame.bot.class)
	return RAIDUS_CLASS_SLOT_COLORS[className]
end

local function applyRaidusSlotTexture(slotFrame, useClassColor)
	if not slotFrame or not slotFrame.texture then
		return
	end

	if useClassColor then
		local color = getRaidusSlotColor(slotFrame)
		if color then
			slotFrame.texture:SetTexture(MultiBot.SafeTexturePath("Interface\\Buttons\\WHITE8X8"))
			slotFrame.texture:SetVertexColor(color[1], color[2], color[3], color[4])
			return
		end
	end

	slotFrame.texture:SetTexture(MultiBot.SafeTexturePath("Interface\\AddOns\\MultiBot\\Textures\\grey.blp"))
	slotFrame.texture:SetVertexColor(1, 1, 1, 1)
end

MultiBot.raidus.save = ""
MultiBot.raidus.from = 1
MultiBot.raidus.to = RAIDUS_POOL_PAGE_SIZE
MultiBot.raidus.sortMode = "Score" -- "Score" | "Level" | "Class"

local function getRaidusGroupSlotFrame(groupIndex, slotIndex)
    local groupFrame = MultiBot.raidus.frames["Group" .. groupIndex]
    local groupSlots = groupFrame and groupFrame.frames
    if not groupSlots then
        return nil
    end

    return groupSlots["Slot" .. slotIndex]
end

local function forEachRaidusGroupSlot(visitor)
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            visitor(groupIndex, slotIndex, getRaidusGroupSlotFrame(groupIndex, slotIndex))
        end
    end
end

local function serializeRaidusLayoutFromFrames()
    local serializedGroups = {}

    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        local serializedNames = {}
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            local slotFrame = getRaidusGroupSlotFrame(groupIndex, slotIndex)
            local slotName = MultiBot.IF(slotFrame and slotFrame.name ~= nil, slotFrame.name, "-")
            table.insert(serializedNames, slotName)
        end
        table.insert(serializedGroups, table.concat(serializedNames, ","))
    end

    return table.concat(serializedGroups, ";")
end

MultiBot.raidus.movButton("Move", -780, 790, 90, MultiBot.L("tips.move.raidus"))

if not raidusUsesAceWindow then
    MultiBot.raidus.wowButton("x", -13, 841, 16, 20, 12)
    .doLeft = function(pButton)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Raidus"]
		tButton.doLeft(tButton)
	end
end


local RAIDUS_LAYOUT_SLOT_MAX = 8
local RAIDUS_LAYOUT_MIGRATION_VERSION = 1
local RAIDUS_LAYOUT_MIGRATION_KEY = "raidusLayoutsVersion"

-- Forward declaration keeps a local upvalue even if helpers are reordered later.
local getRaidusLayoutKey
local getLegacyRaidusLayoutStore

local function getRaidusLayoutStore(createLegacyIfMissing)
    if MultiBot.Store and MultiBot.Store.EnsureUIChildStore then
        local store = MultiBot.Store.EnsureUIChildStore("raidusLayouts")
        if store then
            return store
        end
    end

    local profile = MultiBot.db and MultiBot.db.profile
    if profile then
        profile.ui = profile.ui or {}
        profile.ui.raidusLayouts = profile.ui.raidusLayouts or {}
        return profile.ui.raidusLayouts
    end

    return getLegacyRaidusLayoutStore(createLegacyIfMissing)
end

getRaidusLayoutKey = function(slot)
    return "Raidus" .. (slot or "")
end

getLegacyRaidusLayoutStore = function(createIfMissing)
    local store = _G.MultiBotSave
    if type(store) ~= "table" then
        if not createIfMissing then
            return nil
        end

        store = {}
        _G.MultiBotSave = store
    end

    return store
end

local function cleanupLegacyRaidusLayoutKeys(legacyStore)
    if type(legacyStore) ~= "table" then
        return
    end

    for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
        local slot = (slotIndex == 1) and nil or slotIndex
        local key = getRaidusLayoutKey(slot)
        if legacyStore[key] == "" then
            legacyStore[key] = nil
        end
    end
end

local function migrateLegacyRaidusLayoutsIfNeeded(store)
    if not MultiBot.GetProfileMigrationStore() then
        return
    end

    if not MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION) then
        return
    end

    local legacyStore = getLegacyRaidusLayoutStore(false)
    for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
        local slot = (slotIndex == 1) and nil or slotIndex
        local key = getRaidusLayoutKey(slot)
        if store[key] == nil and legacyStore and legacyStore[key] ~= nil then
            store[key] = legacyStore[key]
        end
    end

    MultiBot.MarkLegacyStateMigrated(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)

    -- Purge migrated legacy Raidus layout keys to avoid stale duplicate persistence.
    if type(legacyStore) == "table" then
        for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
            local slot = (slotIndex == 1) and nil or slotIndex
            legacyStore[getRaidusLayoutKey(slot)] = nil
        end

        cleanupLegacyRaidusLayoutKeys(legacyStore)
    end
end

local function getRaidusLayoutValue(slot)
    local key = getRaidusLayoutKey(slot)
    local hasProfileStore = MultiBot.db and MultiBot.db.profile
    local store = getRaidusLayoutStore(not hasProfileStore)
    migrateLegacyRaidusLayoutsIfNeeded(store)

    local value = store[key]
    if value ~= nil then
        return value
    end

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacyRaidusLayoutStore(false)
        value = legacyStore and legacyStore[key]
        if value ~= nil then
            store[key] = value
        end
    end

    return value
end

local function setRaidusLayoutValue(slot, value)
    local key = getRaidusLayoutKey(slot)
    local store = getRaidusLayoutStore(true)
    migrateLegacyRaidusLayoutsIfNeeded(store)
    store[key] = value

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacyRaidusLayoutStore(true)
        legacyStore[key] = value
    end
end

local function parseRaidusLayoutData(layoutData)
    if type(layoutData) ~= "string" or layoutData == "" then
        return nil
    end

    local layout = {}
    local serializedGroups = MultiBot.doSplit(layoutData, ";")
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        layout[groupIndex] = MultiBot.doSplit(serializedGroups[groupIndex], ",")
    end

    return layout
end

-- MB_RAIDUS_POOL_SERVER_VALIDATION_V1_FOUNDATION_BEGIN
local RAIDUS_POOL_VALIDATION_MAX_ACTIVE = 32
local RAIDUS_POOL_VALIDATION_BURST_SIZE = 4
local RAIDUS_POOL_VALIDATION_BURST_DELAY = 0.10
local RAIDUS_POOL_VALIDATION_COOLDOWN = 10.0

local function getRaidusPoolValidationState()
    local state = MultiBot.raidus._poolValidation
    if type(state) ~= "table" then
        state = {}
        MultiBot.raidus._poolValidation = state
    end

    if type(state.byName) ~= "table" then
        state.byName = {}
    end
    state.running = state.running == true
    state.cooldown = state.cooldown == true
    state.filterEnabled = state.filterEnabled == true
    state.generation = tonumber(state.generation or 0) or 0
    return state
end

local function getRaidusPoolValidationKey(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return string.lower(name)
end

local function isRaidusPoolNameUnavailable(name)
    local state = getRaidusPoolValidationState()
    if state.filterEnabled ~= true then
        return false
    end

    local key = getRaidusPoolValidationKey(name)
    local entry = key and state.byName[key]
    return type(entry) == "table" and entry.unavailable == true
end

MultiBot.raidus.GetPoolValidation = function(name)
    local state = getRaidusPoolValidationState()
    local key = getRaidusPoolValidationKey(name)
    if not key then
        return nil
    end
    return state.byName[key]
end
-- MB_RAIDUS_POOL_SERVER_VALIDATION_V1_FOUNDATION_END

local function buildRaidusPoolFrameIndex(poolFrames)
    local index = {}
    if not poolFrames then
        return index
    end

    for _, dragFrame in pairs(poolFrames) do
        if dragFrame and dragFrame.name ~= nil and dragFrame.name ~= "" and dragFrame.name ~= "-" then
            index[dragFrame.name] = dragFrame
        end
    end

    return index
end

local function getRaidusPoolFrameByName(poolFrameIndex, name)
    if not poolFrameIndex or not name or name == "" or name == "-" then
        return nil
    end
    if name == UnitName("player") then
        return poolFrameIndex[name]
    end
    if isRaidusPoolNameUnavailable(name) then
        return nil
    end

    return poolFrameIndex[name]
end

local function swapRaidusFrameIntoSlot(dragFrame, dropFrame)
    if not dragFrame or not dropFrame then
        return
    end

    local wasDragVisible = dragFrame:IsVisible()
    local dragParent = dragFrame.parent
    local dragHeight = dragFrame.height
    local dragWidth = dragFrame.width
    local dragSlot = dragFrame.slot
    local dragX = dragFrame.x
    local dragY = dragFrame.y

    MultiBot.raidus.doDrop(dragFrame, dropFrame.parent, dropFrame.x, dropFrame.y, dropFrame.width, dropFrame.height, dropFrame.slot)
    if dropFrame:IsVisible() then dragFrame:Show() else dragFrame:Hide() end

    MultiBot.raidus.doDrop(dropFrame, dragParent, dragX, dragY, dragWidth, dragHeight, dragSlot)
    if wasDragVisible then dropFrame:Show() else dropFrame:Hide() end
end

local function applyRaidusLayout(layout)
    if type(layout) ~= "table" then
        return
    end

    local frames = MultiBot.raidus and MultiBot.raidus.frames
    local pool = frames and frames["Pool"]
    local poolFrames = pool and pool.frames
    if not poolFrames then
        return
    end
    local poolFrameIndex = buildRaidusPoolFrameIndex(poolFrames)

    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        local groupLayout = layout[groupIndex]

        if groupLayout then
            for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
                local botName = groupLayout[slotIndex]
                if botName and botName ~= "-" then
                    local dropFrame = getRaidusGroupSlotFrame(groupIndex, slotIndex)
                    local dragFrame = getRaidusPoolFrameByName(poolFrameIndex, botName)
                    if dropFrame and dragFrame then
                        swapRaidusFrameIntoSlot(dragFrame, dropFrame)
                    end
                end
            end
        end
    end
end

-- MB_RAIDUS_POOL_DELETE_V1_BEGIN
if StaticPopupDialogs then
    StaticPopupDialogs["MULTIBOT_RAIDUS_DELETE_POOL_BOT"] = {
        text = MultiBot.L("raidus.pool.delete.confirm"),
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            local data = self and self.data
            local name = data and data.name
            if not name or name == "" or not MultiBot.RemoveGlobalBotEntry then
                return
            end

            local currentLayout = parseRaidusLayoutData(serializeRaidusLayoutFromFrames())
            if not MultiBot.RemoveGlobalBotEntry(name) then
                return
            end

            if MultiBot.raidus.setRaidus then
                MultiBot.raidus.setRaidus()
                applyRaidusLayout(currentLayout)
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    }
end
-- MB_RAIDUS_POOL_DELETE_V1_END

local RAIDUS_ACTION_BAR_Y = raidusUsesAceWindow and 332 or 360
local RAIDUS_ACTION_SHIFT_X = raidusUsesAceWindow and -20 or 0
local RAIDUS_SORT_SHIFT_X = raidusUsesAceWindow and -55 or 0

local function styleRaidusActionButton(button, isPrimary)
    if not button then
        return button
    end

    button:SetSize(80, 20)

    local normalTexture = button:GetNormalTexture()
    local pushedTexture = button:GetPushedTexture()
    local highlightTexture = button:GetHighlightTexture()
    local disabledTexture = button:GetDisabledTexture()

    if isPrimary then
        if normalTexture then normalTexture:SetVertexColor(1.00, 0.96, 0.78, 1.00) end
        if pushedTexture then pushedTexture:SetVertexColor(1.00, 0.90, 0.55, 1.00) end
        if highlightTexture then highlightTexture:SetVertexColor(1.00, 0.96, 0.72, 0.90) end
        if disabledTexture then disabledTexture:SetVertexColor(0.55, 0.55, 0.55, 1.00) end
    else
        if normalTexture then normalTexture:SetVertexColor(0.88, 0.88, 0.88, 1.00) end
        if pushedTexture then pushedTexture:SetVertexColor(0.74, 0.74, 0.74, 1.00) end
        if highlightTexture then highlightTexture:SetVertexColor(0.95, 0.95, 0.95, 0.85) end
        if disabledTexture then disabledTexture:SetVertexColor(0.50, 0.50, 0.50, 1.00) end
    end

    return button
end

local btnLoad = styleRaidusActionButton(MultiBot.raidus.wowButton("Load", -762 + RAIDUS_ACTION_SHIFT_X, RAIDUS_ACTION_BAR_Y, 80, 20, 12), false)
btnLoad.doLeft = function(pButton)
	local layoutData = getRaidusLayoutValue(MultiBot.raidus.save)
	if(layoutData == nil or layoutData == "") then
		SendChatMessage(MultiBot.L("info.nothing"), "SAY")
		return
	end

	local layout = parseRaidusLayoutData(layoutData)
	applyRaidusLayout(layout)
end

local function UpdateRaidusSlotButtonText(button)
	local label = "Slot"
	if MultiBot.raidus.save ~= "" then
		label = "Slot " .. MultiBot.raidus.save
	end
	button.text:SetText("|cffffcc00" .. label .. "|r")
end

local slotDropDown = CreateFrame("Frame", "MultiBotRaidusSlotDropDown", MultiBot.raidus, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(slotDropDown, 80)
UIDropDownMenu_Initialize(slotDropDown, function(self, level)
	for i = 1, 10 do
		local info = UIDropDownMenu_CreateInfo()
		info.text = tostring(i)
		info.value = tostring(i)
		info.func = function()
			MultiBot.raidus.save = tostring(i)
			UIDropDownMenu_SetSelectedValue(slotDropDown, tostring(i))
			UpdateRaidusSlotButtonText(MultiBot.raidus.buttons["Slot"])
			MultiBot.raidus.setRaidus()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end)

local slotButton = styleRaidusActionButton(MultiBot.raidus.wowButton("Slot", -682 + RAIDUS_ACTION_SHIFT_X, RAIDUS_ACTION_BAR_Y, 80, 20, 12), false)
slotButton.tip = MultiBot.L("tips.raidus.slot")
slotButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:SetText(self.tip or "", 1, 1, 1, true)
end)
slotButton:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)
slotButton.doLeft = function()
	if MultiBot.raidus.save ~= "" then
		UIDropDownMenu_SetSelectedValue(slotDropDown, MultiBot.raidus.save)
	end
	ToggleDropDownMenu(1, nil, slotDropDown, slotButton, 0, 0)
end
UpdateRaidusSlotButtonText(slotButton)

local function styleRaidusSortButtonVisual(button, isActive)
    if not button then
        return
    end

    local normalTexture = button:GetNormalTexture()
    local pushedTexture = button:GetPushedTexture()
    local highlightTexture = button:GetHighlightTexture()

    if isActive then
        if normalTexture then normalTexture:SetVertexColor(1.00, 0.92, 0.55, 1.00) end
        if pushedTexture then pushedTexture:SetVertexColor(1.00, 0.84, 0.35, 1.00) end
        if highlightTexture then highlightTexture:SetVertexColor(1.00, 0.95, 0.60, 0.90) end
        if button.text then button.text:SetTextColor(1.00, 0.95, 0.65) end
    else
        if normalTexture then normalTexture:SetVertexColor(0.74, 0.74, 0.74, 0.95) end
        if pushedTexture then pushedTexture:SetVertexColor(0.62, 0.62, 0.62, 0.95) end
        if highlightTexture then highlightTexture:SetVertexColor(0.85, 0.85, 0.85, 0.80) end
        if button.text then button.text:SetTextColor(0.86, 0.86, 0.86) end
    end
end

local function updateRaidusSortButtonsVisual(activeSortName)
    local sortButtons = MultiBot.raidus and MultiBot.raidus.buttons
    if not sortButtons then
        return
    end

    styleRaidusSortButtonVisual(sortButtons["Score"], activeSortName == "Score")
    styleRaidusSortButtonVisual(sortButtons["Level"], activeSortName == "Level")
    styleRaidusSortButtonVisual(sortButtons["Class"], activeSortName == "Class")
end

-- Contrôle du mode Tri, "Score / Level / Class"
local sortBaseX   = -300 + RAIDUS_SORT_SHIFT_X -- position du bouton "Score", pour déplacer tout le groupe il faut modifier cette valeur
local sortY       = RAIDUS_ACTION_BAR_Y
local sortSpacing = 6    -- espace entre les boutons

local scoreWidth  = 60
local levelWidth  = 60
local classWidth  = 60

-- Bouton "Score"
local btnScore = MultiBot.raidus.wowButton("Score", sortBaseX, sortY, scoreWidth, 20, 12)
btnScore.setEnable()
updateRaidusSortButtonsVisual("Score")
btnScore:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.L("tips.raidus.score"), 1, 1, 1, true)
end)
btnScore:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnScore.doLeft = function(pButton)
    pButton.parent.sortMode = "Score"

    pButton.setEnable()
    if pButton.parent.buttons["Level"] then
        pButton.parent.buttons["Level"].setDisable()
    end
    if pButton.parent.buttons["Class"] then
        pButton.parent.buttons["Class"].setDisable()
    end

    updateRaidusSortButtonsVisual("Score")
    MultiBot.raidus.setRaidus()
end

-- Bouton "Level"
local btnLevel = MultiBot.raidus.wowButton(
    "Level",
    sortBaseX + scoreWidth + sortSpacing,
    sortY,
    levelWidth,
    20,
    12
)
btnLevel.setDisable()
btnLevel:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.L("tips.raidus.level"), 1, 1, 1, true)
end)
btnLevel:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnLevel.doLeft = function(pButton)
    pButton.parent.sortMode = "Level"

    pButton.setEnable()
    if pButton.parent.buttons["Score"] then
        pButton.parent.buttons["Score"].setDisable()
    end
    if pButton.parent.buttons["Class"] then
        pButton.parent.buttons["Class"].setDisable()
    end

    updateRaidusSortButtonsVisual("Level")
    MultiBot.raidus.setRaidus()
end

-- Bouton "Class"
local btnClass = MultiBot.raidus.wowButton(
    "Class",
    sortBaseX + scoreWidth + sortSpacing + levelWidth + sortSpacing,
    sortY,
    classWidth,
    20,
    12
)
btnClass.setDisable()
btnClass:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.L("tips.raidus.class"), 1, 1, 1, true)
end)
btnClass:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnClass.doLeft = function(pButton)
    pButton.parent.sortMode = "Class"

    pButton.setEnable()
    if pButton.parent.buttons["Score"] then
        pButton.parent.buttons["Score"].setDisable()
    end
    if pButton.parent.buttons["Level"] then
        pButton.parent.buttons["Level"].setDisable()
    end

    updateRaidusSortButtonsVisual("Class")
    MultiBot.raidus.setRaidus()
end

local btnSave = styleRaidusActionButton(MultiBot.raidus.wowButton("Save", -597 + RAIDUS_ACTION_SHIFT_X, RAIDUS_ACTION_BAR_Y, 80, 20, 12), false)
btnSave.doLeft = function(pButton)
	setRaidusLayoutValue(MultiBot.raidus.save, serializeRaidusLayoutFromFrames())
	SendChatMessage("I wrote it down.", "SAY")
end

-- MB_RAIDUS_OUTSIDE_LAYOUT_PARTY_REMOVAL_V2_BEGIN
local function buildRaidusCurrentGroupMembersForCleanup()
    local currentMembers = {}
    local raidCount = GetNumRaidMembers() or 0

    if raidCount > 0 then
        for raidIndex = 1, raidCount do
            local raidName = GetRaidRosterInfo(raidIndex)
            if raidName and raidName ~= "" then
                currentMembers[raidName] = true
            end
        end
        return currentMembers
    end

    local partyCount = GetNumPartyMembers() or 0
    for partyIndex = 1, partyCount do
        local partyName = UnitName("party" .. partyIndex)
        if partyName and partyName ~= "" then
            currentMembers[partyName] = true
        end
    end

    return currentMembers
end
-- MB_RAIDUS_OUTSIDE_LAYOUT_PARTY_REMOVAL_V2_END
local function collectRaidusApplyInviteList(raidByIndex, selfName)
    local inviteList = {}
    local selectedCount = 0

    for index = 1, #(raidByIndex or {}) do
        local entry = raidByIndex[index]
        local raidName = entry and entry.name
        if raidName and raidName ~= "" and raidName ~= selfName then
            selectedCount = selectedCount + 1
            if not MultiBot.isMember(raidName) then
                table.insert(inviteList, raidName)
            end
        end
    end

    return selectedCount, inviteList, true
end

local function removeRaidusMembersOutsideLayout(raidByMembers, raidByName, selfName)
    for raidMemberName, _ in pairs(raidByMembers) do
        if raidMemberName ~= selfName and raidByName[raidMemberName] == nil then
            if MultiBot.isMember(raidMemberName) then
                UninviteUnit(raidMemberName)
            end
            runRaidusLifecycleForName(raidMemberName, "DISCONNECT", false)
        end
    end
end

local function announceRaidusApplySelection(selectedCount, inviteList, usedLayoutFallback)
    local inviteCount = #inviteList
    local selectedList = inviteCount > 0 and table.concat(inviteList, ", ") or ""

    if usedLayoutFallback then
        SendChatMessage("Raidus Apply: using layout list, selected=" .. selectedCount .. " toInvite=" .. inviteCount, "SAY")
    else
        SendChatMessage("Raidus Apply: selected=" .. selectedCount .. " toInvite=" .. inviteCount, "SAY")
    end

    if selectedList ~= "" then
        SendChatMessage("Raidus Apply list: " .. selectedList, "SAY")
    end
end

local function startRaidusApplyInviteOrSort(inviteCount)
    local invite = MultiBot.timer.invite
    invite.runId = (tonumber(invite.runId) or 0) + 1
    invite.elapsed = 0
    invite.roster = ""
    invite.index = 1
    invite.needs = 0
    invite.source = "RAIDUS"
    invite.pending = false
    invite.pendingName = nil

    MultiBot.auto.invite = false
    MultiBot.auto.sort = false

    if inviteCount > 0 then
        SendChatMessage(MultiBot.L("info.starting"), "SAY")
        invite.roster = "raidus"
        invite.needs = inviteCount
        MultiBot.auto.invite = true
    else
        MultiBot.timer.sort.elapsed = 0
        MultiBot.timer.sort.index = 1
        MultiBot.timer.sort.needs = 0
        MultiBot.auto.sort = true
    end
end

local btnApply = styleRaidusActionButton(MultiBot.raidus.wowButton("Apply", -514 + RAIDUS_ACTION_SHIFT_X, RAIDUS_ACTION_BAR_Y, 80, 20, 12), true)
btnApply.doLeft = function(pButton)
    local tRaidByIndex, tRaidByName = MultiBot.raidus.getRaidTarget()
    if(tRaidByIndex == nil or tRaidByName == nil) then return end

    local tSelf = UnitName("player")
    local tSelected, inviteList, usedLayoutFallback = collectRaidusApplyInviteList(tRaidByIndex, tSelf)

    MultiBot.index.raidus = inviteList
    local tNeeds = #inviteList

    local tRaidByMembers = buildRaidusCurrentGroupMembersForCleanup()
    removeRaidusMembersOutsideLayout(tRaidByMembers, tRaidByName, tSelf)

    announceRaidusApplySelection(tSelected, inviteList, usedLayoutFallback)
    startRaidusApplyInviteOrSort(tNeeds)
end


-- Bouton Auto-balance raid :
-- Clic gauche  : équilibrage simple par score
-- Clic droit   : équilibrage avancé Tank / Heal / DPS
local btnAuto = styleRaidusActionButton(MultiBot.raidus.wowButton("Auto", -431 + RAIDUS_ACTION_SHIFT_X, RAIDUS_ACTION_BAR_Y, 80, 20, 12), true)

btnAuto:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.L("tips.raidus.autobalance"), 1, 1, 1, true)
end)

btnAuto:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Clic gauche : simple, on répartit les bots par score le plus équilibré possible
btnAuto.doLeft = function(pButton)
    MultiBot.raidus.autoBalanceRaid("score")
end

-- Clic droit : mode avancé Tank / Heal / DPS
btnAuto.doRight = function(pButton)
    MultiBot.raidus.autoBalanceRaid("role")
end

-- Update pool visibility according to current Raidus page window.
local function refreshRaidusPoolPageVisibility()
	local poolFrame = MultiBot.raidus.frames["Pool"]
	local poolFrames = poolFrame.frames
	for slotIndex = 1, MultiBot.raidus.slots, 1 do
		local poolSlot = poolFrames["Slot" .. slotIndex]
		if poolSlot and poolSlot.parent == poolFrame then
			if(slotIndex >= MultiBot.raidus.from and slotIndex <= MultiBot.raidus.to) then poolSlot:Show() else poolSlot:Hide() end
		end
	end
end

MultiBot.raidus.wowButton("<", -110, RAIDUS_ACTION_BAR_Y, 16, 20, 12)
.doLeft = function(pButton)
	MultiBot.raidus.from = MultiBot.raidus.from - RAIDUS_POOL_PAGE_SIZE
	MultiBot.raidus.to = MultiBot.raidus.to - RAIDUS_POOL_PAGE_SIZE

	if(MultiBot.raidus.to < 1) then
		MultiBot.raidus.from = MultiBot.raidus.slots - (RAIDUS_POOL_PAGE_SIZE - 1)
		MultiBot.raidus.to = MultiBot.raidus.slots
	end

	refreshRaidusPoolPageVisibility()
end

MultiBot.raidus.wowButton(">", -70, RAIDUS_ACTION_BAR_Y, 16, 20, 12)
.doLeft = function(pButton)
	MultiBot.raidus.from = MultiBot.raidus.from + RAIDUS_POOL_PAGE_SIZE
	MultiBot.raidus.to = MultiBot.raidus.to + RAIDUS_POOL_PAGE_SIZE

	if(MultiBot.raidus.from > MultiBot.raidus.slots) then
		MultiBot.raidus.from = 1
		MultiBot.raidus.to = RAIDUS_POOL_PAGE_SIZE
	end

	refreshRaidusPoolPageVisibility()
end

MultiBot.raidus.getDrop = function()
	for i = 1, RAIDUS_GROUP_COUNT, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]

		if(MouseIsOver(tGroup)) then
			for j = 1, RAIDUS_GROUP_SLOT_COUNT, 1 do
				local tSlot = tGroup.frames["Slot" .. j]
				if(MouseIsOver(tSlot)) then return tSlot end
			end
		end
	end

	for i = 1, MultiBot.raidus.slots, 1 do
		local tSlot = MultiBot.raidus.frames["Pool"].frames["Slot" .. i]
		if(MouseIsOver(tSlot)) then return tSlot end
	end

	return nil
end

-- SETTER --

local function getRaidusGlobalBotStore()
    if MultiBot.GetGlobalBotStore then
        return MultiBot.GetGlobalBotStore()
    end

    if type(_G.MultiBotGlobalSave) ~= "table" then
        _G.MultiBotGlobalSave = {}
    end

    return _G.MultiBotGlobalSave
end

local function buildRaidusBotFromGlobalSave(name, value)
    if not value then
        return nil
    end

    local details = MultiBot.doSplit(value, ",")
    local rawClass = details[5]
    if not rawClass or rawClass == "" then
        return nil
    end

    local bot = {}
    bot.name = name
    bot.race = details[1]
    bot.gender = details[2]
    bot.special = details[3]
    bot.talents = details[4]
    bot.class = rawClass
    bot.level = tonumber(details[6]) or 0
    bot.score = tonumber(details[7]) or 0
    bot.role = MultiBotRaidusDetectRole(bot)
    return bot
end

local function appendRaidusBotIfValid(bots, name, value)
    local bot = buildRaidusBotFromGlobalSave(name, value)
    if bot then
        table.insert(bots, bot)
    end
end

-- MB_RAIDUS_PLAYER_SLOT_MASTER_V1_FOUNDATION_BEGIN
local function buildRaidusPlayerCardData()
    local name = UnitName("player")
    if not name or name == "" then
        return nil
    end

    local localClass, classToken = UnitClass("player")
    local localRace = UnitRace("player")
    local normalizedClass = MultiBot.toClass(classToken or localClass or "")
    if not normalizedClass or normalizedClass == "" then
        return nil
    end

    local score = 0
    if type(MultiBot.ItemLevel) == "function" then
        score = tonumber(MultiBot.ItemLevel("player")) or 0
    end

    return {
        name = name,
        race = localRace or "",
        gender = MultiBot.CASE(UnitSex("player"), "[U]", "[N]", "[M]", "[F]"),
        special = "",
        talents = "",
        class = normalizedClass,
        level = tonumber(UnitLevel("player")) or 0,
        score = score,
        isPlayer = true,
    }
end
-- MB_RAIDUS_PLAYER_SLOT_MASTER_V1_FOUNDATION_END

MultiBot.raidus.setRaidus = function()
	local tPool = MultiBot.raidus.frames["Pool"]
	local tSlot = 1
	local tY = 426

	for k,v in pairs(tPool.frames) do v:Hide() end

	local tBots = {}
	-- Mode de tri actuel ("Score", "Level", "Class")
	local sortMode = MultiBot.raidus.sortMode or "Score"
    local playerName = UnitName("player")

    for tName, tValue in pairs(getRaidusGlobalBotStore()) do
        local tBot = nil
        if tName ~= playerName and not isRaidusPoolNameUnavailable(tName) then
            tBot = buildRaidusBotFromGlobalSave(tName, tValue)
        end
        if tBot then
            local tClass = MultiBot.toClass(tBot.class)
			local classWeight = MultiBotRaidusClassWeight[tClass] or 0
			local botLevel   = tBot.level or 0
			local botScore   = tBot.score or 0

			-- Tri Score / Level / Class
			if sortMode == "Score" then
				-- Score desc, puis niveau desc, puis classe
				tBot.sort = botScore * 1000000 + botLevel * 1000 + classWeight
			elseif sortMode == "Level" then
				-- Niveau desc, puis score desc, puis classe
				tBot.sort = botLevel * 1000000 + botScore * 1000 + classWeight
			elseif sortMode == "Class" then
				-- Classe (ordre fixe), puis niveau desc, puis score desc
				tBot.sort = classWeight * 1000000 + botLevel * 1000 + botScore
			else
				-- fallback : tri par score
				tBot.sort = botScore * 1000000 + botLevel * 1000 + classWeight
			end

			table.insert(tBots, tBot)
		end
	end

	table.sort(tBots, function(a, b)
		return (a.sort or 0) > (b.sort or 0)
	end)

    local playerBot = buildRaidusPlayerCardData()
    if playerBot then
        table.insert(tBots, 1, playerBot)
    end

	local function formatRaidusSlotName(name, maxLen)
		local text = tostring(name or "")
		local limit = maxLen or 16
		if string.len(text) <= limit then
			return text
		end
		return string.sub(text, 1, limit - 1) .. "..."
	end

	for tIndex = 1, #tBots do
		local tBot = tBots[tIndex]

		local tFrame = tPool.addFrame("Slot" .. tSlot, 0, tY, 28, 160, 36)
		tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
		applyRaidusSlotTextureInset(tFrame)
		tFrame:SetResizable(false)
		tFrame:SetMovable(true)
		tFrame.class = MultiBot.toClass(tBot.class)
		tFrame.slot = "Slot" .. tSlot
		tFrame.name = tBot.name
		tFrame.bot = tBot
        tFrame.isPlayer = tBot.isPlayer == true
		setRaidusSlotRoleBorder(tFrame, nil, 0.22)

        local tButton = tFrame.addButton("Icon", -128, 3, "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tFrame.class) .. ".blp", "")

		tButton:SetScript("OnEnter", function(pButton)
			local bot = pButton.parent.bot
			if not bot then
				return
			end

			local botName    = bot.name or "?"
			local botGender  = bot.gender or "?"
			local botRace    = bot.race or "?"
			local botClass   = bot.class or "Unknown"
			local botTalents = bot.talents or "?"
			local botSpecial = bot.special or "?"
			local botLevel   = bot.level or 0
			local botScore   = bot.score or 0
			local botRole    = bot.isPlayer and nil or (bot.role or MultiBotRaidusDetectRole(bot))
			local roleColor  = RAIDUS_ROLE_COLORS[botRole] or RAIDUS_ROLE_COLORS["DPS"]
			local roleHex    = string.format("ff%02x%02x%02x", math.floor(roleColor[1] * 255 + 0.5), math.floor(roleColor[2] * 255 + 0.5), math.floor(roleColor[3] * 255 + 0.5))
			local classHex   = getRaidusClassHexColor(MultiBot.toClass(botClass))

			local tReward = botLevel .. "." .. MultiBot.IF(botScore < 100, "0", MultiBot.IF(botScore < 10, "00", "")) .. botScore

			pButton.tip = MultiBot.newFrame(pButton, -pButton.size, 160, 28, 256, 512, "TOPRIGHT")
			pButton.tip.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Wanted.blp")
			pButton.tip.addModel(botName, 0, 64, 160, 240, 1.0)
			pButton.tip.addText("1", "|cff555555- WANTED -|h", "TOP", 0, -30, 24)
			pButton.tip.addText("2", "|cff555555-DEAD OR ALIVE-|h", "TOP", 0, -55, 24)
			pButton.tip.addText("3", "|cff333333" .. botName .. " - " .. botGender .. " - " .. botRace .. "|h", "BOTTOM", 0, 224, 15)
			pButton.tip.addText("4", "|c" .. classHex .. botClass .. "|r  |cff909090(" .. botSpecial .. ")|r", "BOTTOM", 0, 206, 15)
            local roleScoreText = "|cff333333Score:|r |cffffdd55" .. botScore .. "|r"
            local talentsText = ""
            if not bot.isPlayer then
                roleScoreText = "|c" .. roleHex .. formatRaidusRoleLabel(botRole) .. "|r  " .. roleScoreText
                talentsText = "|cff333333Talents:|r |cff505050" .. botTalents .. "|r"
            end
			pButton.tip.addText("5", roleScoreText, "BOTTOM", 0, 188, 15)
			pButton.tip.addText("6", talentsText, "BOTTOM", 0, 172, 14)
			pButton.tip.addText("7", "|cff555555CASH - " .. tReward .. " - GOLD|h", "BOTTOM", 0, 154, 20)
			-- MB_RAIDUS_TOOLTIP_INTERACTION_PANEL_V1_BEGIN
			local interactionPanel = CreateFrame("Frame", nil, pButton.tip)
			interactionPanel:SetPoint("BOTTOM", pButton.tip, "BOTTOM", 0, 96)
			interactionPanel:SetSize(232, 54)
			interactionPanel:EnableMouse(false)
			interactionPanel:SetFrameLevel((pButton.tip:GetFrameLevel() or 0) + 2)

			if interactionPanel.SetBackdrop then
				interactionPanel:SetBackdrop({
					bgFile = "Interface\\Buttons\\WHITE8X8",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile = true,
					tileSize = 8,
					edgeSize = 10,
					insets = { left = 3, right = 3, top = 3, bottom = 3 },
				})
				interactionPanel:SetBackdropColor(0, 0, 0, 0.82)
				interactionPanel:SetBackdropBorderColor(1, 0.82, 0, 0.78)
			end

			local interactionText = interactionPanel:CreateFontString(nil, "ARTWORK")
			interactionText:SetFont("Fonts\\ARIALN.ttf", 13, "PLAIN")
			interactionText:SetPoint("CENTER", interactionPanel, "CENTER", 0, 0)
			interactionText:SetWidth(214)
			interactionText:SetJustifyH("CENTER")
            local interactionHint = MultiBot.L("tips.raidus.pool.interactions")
            if bot.isPlayer and type(interactionHint) == "string" then
                interactionHint = string.match(interactionHint, "^[^\r\n]+") or interactionHint
            end
			interactionText:SetText(interactionHint)
			interactionText:Show()
			-- MB_RAIDUS_TOOLTIP_INTERACTION_PANEL_V1_END
			pButton.tip:Show()
		end)

        -- Clic gauche : drag & drop dans les groupes
        -- Clic droit  : connecte / déconnecte le bot via Bridge lifecycle
        tButton:SetScript("OnMouseDown", function(pButton, button)
            if button == "LeftButton" then
                pButton.parent:StartMoving()
                pButton.parent.isMoving = true
            end
        end)

        tButton:SetScript("OnMouseUp", function(pButton, button)
            if button == "LeftButton" then
                -- Drag & drop (inchangé)
                pButton.parent:StopMovingOrSizing()
                pButton.parent.isMoving = false

                local tDrag = pButton.parent
                local tDrop = MultiBot.raidus.getDrop()

                if tDrop ~= nil then
                    local tParent  = tDrag.parent
                    local tHeight  = tDrag.height
                    local tWidth   = tDrag.width
                    local dropSlot = tDrag.slot
                    local tX       = tDrag.x
                    local dropY    = tDrag.y
                    local targetGroup = tDrop.parent and tDrop.parent.group
                    local targetSlot = tDrop.slot
                    local swappedName = tDrop.name

                    MultiBot.raidus.doDrop(
                        tDrag,
                        tDrop.parent,
                        tDrop.x,
                        tDrop.y,
                        tDrop.width,
                        tDrop.height,
                        tDrop.slot
                    )
                    MultiBot.raidus.doDrop(
                        tDrop,
                        tParent,
                        tX,
                        dropY,
                        tWidth,
                        tHeight,
                        dropSlot
                    )

                    playRaidusDropPulse(tDrag)
                    if targetGroup then
                        if swappedName and swappedName ~= "" and swappedName ~= tDrag.name then
                            showRaidusDropFeedback("Echange avec " .. swappedName .. " -> " .. targetGroup .. " / " .. targetSlot)
                        else
                            showRaidusDropFeedback("Ajoute dans " .. targetGroup .. " / " .. targetSlot)
                        end
                    end
                else
                    pButton.parent:ClearAllPoints()
                    pButton.parent:SetPoint(pButton.parent.align, pButton.parent.x, pButton.parent.y)
                    pButton.parent:SetSize(pButton.parent.width, pButton.parent.height)
                end

            elseif button == "RightButton" then
                local name = pButton.parent.name
                if not name or name == "" then
                    return
                end
                if pButton.parent.isPlayer then
                    return
                end

                if IsShiftKeyDown and IsShiftKeyDown() then
                    local poolFrame = MultiBot.raidus.frames and MultiBot.raidus.frames["Pool"]
                    if pButton.parent.parent ~= poolFrame then
                        return
                    end

                    local dialog = StaticPopup_Show and StaticPopup_Show("MULTIBOT_RAIDUS_DELETE_POOL_BOT", name)
                    if dialog then
                        dialog.data = { name = name }
                    end
                    return
                end

                runRaidusLifecycleForName(name, "TOGGLE", true)
            end
        end)

		local displayLevel   = tBot.level or 0
		local displayScore   = tBot.score or 0
		local displaySpecial = tBot.special or ""
		local displayName    = formatRaidusSlotName(tBot.name, 14)

		tFrame.addText("Name", "|cfffff2c0" .. displayName .. "|r", "BOTTOMLEFT", 36, 18, 13) -- Display name in bot frame
		tFrame.addText("Meta", "|cffb8b8b8" .. displayLevel .. " - " .. displaySpecial .. "|r", "BOTTOMLEFT", 36, 6, 11) -- Display level and spec in bot frame
		tFrame.addText("ScoreBadge", "|cffd4af37[" .. displayScore .. "]|r", "BOTTOMRIGHT", -8, 16, 11) -- Display Score in bot frame

		if(tSlot > RAIDUS_POOL_PAGE_SIZE) then tFrame:Hide() else tFrame:Show() end
		tY = MultiBot.IF(tSlot % RAIDUS_POOL_PAGE_SIZE == 0, 426, tY - 40)
		tSlot = tSlot + 1
	end

	for i = tSlot % RAIDUS_POOL_PAGE_SIZE, RAIDUS_POOL_PAGE_SIZE, 1 do
		local tFrame = tPool.addFrame("Slot" .. tSlot, 0, tY, 28, 160, 36)
		tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
		applyRaidusSlotTextureInset(tFrame)
		tFrame.slot = "Slot" .. tSlot
		setRaidusSlotRoleBorder(tFrame, nil, 0.22)
		if(tSlot > RAIDUS_POOL_PAGE_SIZE) then tFrame:Hide() else tFrame:Show() end
		tSlot = tSlot + 1
		tY = tY - 40
	end

	MultiBot.raidus.slots = tSlot - 1

	for i = 1, RAIDUS_GROUP_COUNT, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]
		local groupY = 182

		ApplyRaidusGroupCardChrome(tGroup, i)
		tGroup.addText("GroupName", "|cffffcc00Group" .. i .. "|r", "BOTTOM", -20, 223, 12)
		tGroup.addText("GroupScoreBadge", formatRaidusBadgeLabel(0), "BOTTOM", 52, 223, 11)
		tGroup.group = "Group" .. i
		tGroup.score = 0

		for j = 1, RAIDUS_GROUP_SLOT_COUNT, 1 do
			local tFrame = tGroup.addFrame("Slot" .. j, 0, groupY, 28, RAIDUS_GROUP_SLOT_WIDTH, 36)
			tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
			applyRaidusSlotTextureInset(tFrame)
			tFrame.slot = "Slot" .. j
			setRaidusSlotRoleBorder(tFrame, nil, 0.20)
			groupY = groupY - 40
		end
	end
end

-- MB_RAIDUS_POOL_SERVER_VALIDATION_V1_RUNTIME_BEGIN
local function rebuildRaidusPoolAfterValidation()
    if not MultiBot.raidus or not MultiBot.raidus.IsShown or not MultiBot.raidus:IsShown() then
        return
    end

    local currentLayout = parseRaidusLayoutData(serializeRaidusLayoutFromFrames())
    MultiBot.raidus.setRaidus()
    if currentLayout then
        applyRaidusLayout(currentLayout)
    end
end

-- MB_RAIDUS_PRESERVE_LAYOUT_ON_BRIDGE_DETAIL_V1_BEGIN
MultiBot.raidus.refreshPreservingLayout = function()
    rebuildRaidusPoolAfterValidation()
end
-- MB_RAIDUS_PRESERVE_LAYOUT_ON_BRIDGE_DETAIL_V1_END

local function scheduleRaidusPoolValidation(delaySeconds, callback)
    if type(callback) ~= "function" then
        return
    end
    if type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delaySeconds or 0, callback)
    else
        callback()
    end
end

local function recordRaidusPoolValidationResult(state, name, result)
    local key = getRaidusPoolValidationKey(name)
    if not key then
        return
    end

    local status = type(result) == "table" and tostring(result.status or "") or ""
    local reason = type(result) == "table" and tostring(result.reason or "") or "LOCAL_UNAVAILABLE"
    local lifecycleState = type(result) == "table" and tostring(result.lifecycleState or "UNKNOWN") or "UNKNOWN"
    local unavailable = status == "ERR" and reason == "NOT_ALLOWED"
    local verified = status == "OK" or unavailable

    state.byName[key] = {
        name = name,
        status = status ~= "" and status or "ERR",
        reason = reason,
        lifecycleState = lifecycleState,
        unavailable = unavailable,
        verified = verified,
        transient = not verified,
    }
end

MultiBot.raidus.ValidatePool = function(force)
    local state = getRaidusPoolValidationState()
    if state.running then
        return false
    end
    if force ~= true and state.cooldown then
        return false
    end

    local bridge = MultiBot.bridge
    local comm = MultiBot.Comm
    if not bridge or bridge.connected ~= true or bridge.botTargetResolveCapable ~= true
        or not comm or type(comm.ResolveBotTarget) ~= "function" then
        local hadFilter = state.filterEnabled == true
        state.filterEnabled = false
        if hadFilter then
            rebuildRaidusPoolAfterValidation()
        end
        return false
    end

    local names = {}
    local activeNames = {}
    local playerName = UnitName("player")
    for name, value in pairs(getRaidusGlobalBotStore()) do
        if name ~= playerName and buildRaidusBotFromGlobalSave(name, value) then
            table.insert(names, name)
            local key = getRaidusPoolValidationKey(name)
            if key then
                activeNames[key] = true
            end
        end
    end

    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for key, _ in pairs(state.byName) do
        if not activeNames[key] then
            state.byName[key] = nil
        end
    end

    state.running = true
    state.cooldown = true
    state.generation = state.generation + 1
    state.queue = names
    state.nextIndex = 1
    state.active = 0
    state.completed = 0
    state.total = #names

    local generation = state.generation
    scheduleRaidusPoolValidation(RAIDUS_POOL_VALIDATION_COOLDOWN, function()
        local live = getRaidusPoolValidationState()
        if live.generation == generation then
            live.cooldown = false
        end
    end)

    local finished = false
    local function finishValidation()
        if finished then
            return
        end
        local live = getRaidusPoolValidationState()
        if live.generation ~= generation then
            return
        end

        finished = true
        live.running = false
        live.filterEnabled = true
        live.queue = nil
        live.nextIndex = nil
        rebuildRaidusPoolAfterValidation()
    end

    if #names == 0 then
        finishValidation()
        return true
    end

    local pumpValidation
    pumpValidation = function()
        local live = getRaidusPoolValidationState()
        if live.generation ~= generation or live.running ~= true then
            return
        end

        local launched = 0
        while live.active < RAIDUS_POOL_VALIDATION_MAX_ACTIVE
            and live.nextIndex <= #names
            and launched < RAIDUS_POOL_VALIDATION_BURST_SIZE do
            local name = names[live.nextIndex]
            live.nextIndex = live.nextIndex + 1
            live.active = live.active + 1
            launched = launched + 1

            local token = comm.ResolveBotTarget(name, function(result)
                local callbackState = getRaidusPoolValidationState()
                if callbackState.generation ~= generation or callbackState.running ~= true then
                    return
                end

                callbackState.active = math.max(0, (callbackState.active or 1) - 1)
                callbackState.completed = (callbackState.completed or 0) + 1
                recordRaidusPoolValidationResult(callbackState, name, result)

                if callbackState.nextIndex > #names and callbackState.active == 0 then
                    finishValidation()
                end
            end)

            if not token then
                live.active = math.max(0, live.active - 1)
                live.completed = (live.completed or 0) + 1
                recordRaidusPoolValidationResult(live, name, {
                    status = "ERR",
                    reason = "LOCAL_UNAVAILABLE",
                    lifecycleState = "UNKNOWN",
                })
            end
        end

        if live.nextIndex > #names and live.active == 0 then
            finishValidation()
            return
        end

        scheduleRaidusPoolValidation(RAIDUS_POOL_VALIDATION_BURST_DELAY, pumpValidation)
    end

    pumpValidation()
    return true
end
-- MB_RAIDUS_POOL_SERVER_VALIDATION_V1_RUNTIME_END

-- MB_RAIDUS_PLAYER_SLOT_MASTER_V1_RUNTIME_END

-- GETTER --

local function buildRaidusCurrentRosterState()
	local raidByMembers = {}
	local raidByGroups = {}
	local raidCount = GetNumRaidMembers() or 0

	for raidIndex = 1, raidCount do
		local raidName, _, raidGroup = GetRaidRosterInfo(raidIndex)
		if raidName and raidGroup then
			raidByMembers[raidName] = { index = raidIndex, group = raidGroup }
			raidByGroups[raidGroup] = (raidByGroups[raidGroup] or 0) + 1
		end
	end

	return raidByMembers, raidByGroups
end

MultiBot.raidus.getRaidState = function()
	return buildRaidusCurrentRosterState()
end

MultiBot.raidus.getRaidTarget = function()
	local tRaidByIndex = {}
	local tRaidByName = {}
	local tIndex = 1

	local tSelf = UnitName("player")
	local tUser = true
	local tBots = true

	forEachRaidusGroupSlot(function(groupIndex, slotIndex, slotFrame)
		local slotName = slotFrame and slotFrame.name
		if(slotName ~= nil) then
			if(slotName == tSelf) then tUser = false end
			tRaidByIndex[tIndex] = { name = slotName, group = groupIndex }
			tRaidByName[slotName] = groupIndex
			tIndex = tIndex + 1
			tBots = false
		end
	end)

	if(tBots) then return SendChatMessage("There is no Bot in the Raid", "SAY") end
	if(tUser) then return SendChatMessage("Place me in a Raidus raid group slot before clicking Apply.", "SAY") end
	return tRaidByIndex, tRaidByName
end

local function getRaidusTargetAndState()
	local raidByIndex, raidByName = MultiBot.raidus.getRaidTarget()
	if not raidByIndex or not raidByName then
		return nil
	end

	local raidByMembers, raidByGroups = buildRaidusCurrentRosterState()
	return {
		raidByIndex = raidByIndex,
		raidByName = raidByName,
		raidByMembers = raidByMembers,
		raidByGroups = raidByGroups,
	}
end

local function findRaidusSwapCandidateIndex(raidByMembers, raidByName, expectedGroup)
	for memberName, memberData in pairs(raidByMembers) do
		if memberData.group == expectedGroup and raidByName[memberName] ~= expectedGroup then
			return memberData.index
		end
	end

	return nil
end

local function moveRaidusMemberToTargetGroup(memberData, expectedGroup, raidByGroups, raidByMembers, raidByName)
	if not memberData or memberData.group == expectedGroup then
		return false
	end

	local targetSize = raidByGroups[expectedGroup] or 0
	if targetSize < RAIDUS_GROUP_SLOT_COUNT then
		SetRaidSubgroup(memberData.index, expectedGroup)
		return true
	end

	local swapIndex = findRaidusSwapCandidateIndex(raidByMembers, raidByName, expectedGroup)
	if swapIndex then
		SwapRaidSubgroup(memberData.index, swapIndex)
		return true
	end

	return false
end

-- EVENTS --

MultiBot.raidus.doRaidSortCheck = function()
	local raidContext = getRaidusTargetAndState()
	if not raidContext then
		return nil
	end

	for targetName, targetGroup in pairs(raidContext.raidByName) do
		local memberData = raidContext.raidByMembers[targetName]
		if memberData and memberData.group ~= targetGroup then
			return 1
		end
	end

	return nil
end

MultiBot.raidus.doRaidSort = function(pIndex)
	local raidContext = getRaidusTargetAndState()
	if not raidContext then
		return nil
	end

	local targetEntry = raidContext.raidByIndex[pIndex]
	if not targetEntry then
		return nil
	end

	local memberData = raidContext.raidByMembers[targetEntry.name]
	moveRaidusMemberToTargetGroup(
		memberData,
		targetEntry.group,
		raidContext.raidByGroups,
		raidContext.raidByMembers,
		raidContext.raidByName
	)

	return pIndex + 1
end

MultiBot.raidus.doGroupScore = function(pGroup)
	if(pGroup == nil or pGroup.group == nil) then return end
	local tScore = 0
	local tSize = 0

	local roleCounts = { TANK = 0, HEAL = 0, DPS = 0 }
	for tKey, tSlot in pairs(pGroup.frames) do
		if(tSlot ~= nil and tSlot.bot ~= nil) then
			tScore = tScore + tSlot.bot.score
			tSize = tSize + 1
			local slotRole = tSlot.bot.role or MultiBotRaidusDetectRole(tSlot.bot)
			roleCounts[slotRole] = (roleCounts[slotRole] or 0) + 1
		end
	end

	local dominantRole = "DPS"
	if roleCounts.HEAL > roleCounts[dominantRole] then dominantRole = "HEAL" end
	if roleCounts.TANK > roleCounts[dominantRole] then dominantRole = "TANK" end

	for tKey, tSlot in pairs(pGroup.frames) do
		if tSlot ~= nil then
			setRaidusSlotRoleBorder(tSlot, dominantRole, tSize > 0 and 0.32 or 0.20)
		end
	end

	pGroup.score = MultiBot.IF(tSize > 0, math.floor(tScore / tSize), 0)
	pGroup.setText("GroupScoreBadge", formatRaidusBadgeLabel(pGroup.score))
end

MultiBot.raidus.doRaidScore = function()
	local tScore = 0
	local tSize = 0

	for tKey, tGroup in pairs(MultiBot.raidus.frames) do
		if(tGroup ~= nil and tGroup.score ~= nil and tGroup.score > 0) then
			tScore = tScore + tGroup.score
			tSize = tSize + 1
		end
	end

	tScore = MultiBot.IF(tSize > 0, math.floor(tScore / tSize), 0)
	local raidScoreLabel = formatRaidusScoreLabel(tScore)
	if MultiBot.raidus.texts and MultiBot.raidus.texts["RaidScore"] then
		MultiBot.raidus.setText("RaidScore", raidScoreLabel)
	else
		MultiBot.raidus.addText("RaidScore", raidScoreLabel, RAIDUS_SCORE_ANCHOR, RAIDUS_SCORE_OFFSET_X, RAIDUS_SCORE_OFFSET_Y, RAIDUS_SCORE_FONT_SIZE)
	end
end

MultiBot.raidus.doDrop = function(pObject, pParent, pX, pY, pWidth, pHeight, pSlot)
	pParent.frames[pSlot] = pObject
	pObject:ClearAllPoints()
	pObject:SetParent(pParent)
	pObject:SetPoint("BOTTOMRIGHT", pX, pY)
	pObject:SetSize(pWidth, pHeight)
	pObject.parent = pParent
	pObject.height = pHeight
	pObject.width = pWidth
	pObject.slot = pSlot
	pObject.x = pX
	pObject.y = pY
    local isGroupSlot = pParent and pParent.group ~= nil
    applyRaidusSlotTexture(pObject, isGroupSlot)
    if isGroupSlot then
		-- Keep dropped bot texture perfectly aligned with the empty slot grey background.
		applyRaidusSlotTextureInset(pObject)
    else
        applyRaidusSlotTextureInset(pObject)
		setRaidusSlotRoleBorder(pObject, nil, 0.22)
	end
	MultiBot.raidus.doGroupScore(pParent)
	MultiBot.raidus.doRaidScore()
end

-- ---------------------------------------------------------------------------
--  AUTO BALANCE RAID
-- ---------------------------------------------------------------------------

-- Récupère la liste des bots candidats à l'auto-balance.
-- On prend d'abord les bots cochés dans MultiBar -> Units
-- Si aucun n'est coché, on prend tous les bots connus dans MultiBotGlobalSave
local function MultiBotRaidusCollectSelectedBots()
    local bots = {}

    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsFrame = multiBar and multiBar.frames and multiBar.frames["Units"]
    local unitButtons = unitsFrame and unitsFrame.buttons

    local globalBots = getRaidusGlobalBotStore()
    local playerName = UnitName("player")

    if unitButtons then
        for name, button in pairs(unitButtons) do
            if button.state and name ~= playerName then
                appendRaidusBotIfValid(bots, name, globalBots[name])
            end
        end
    end

    -- Fallback : aucun bot sélectionné = on prend tout le monde
    if #bots == 0 then
        for name, value in pairs(globalBots) do
            if name ~= playerName then
                appendRaidusBotIfValid(bots, name, value)
            end
        end
    end

    return bots
end

-- Tri générique par score décroissant puis niveau décroissant
local function MultiBotRaidusSortByScore(list)
    table.sort(list, function(a, b)
        local sa = a.score or 0
        local sb = b.score or 0
        if sa ~= sb then
            return sa > sb
        end
        local la = a.level or 0
        local lb = b.level or 0
        return la > lb
    end)
end

local function createEmptyRaidusLayout()
    local layout = {}
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        layout[groupIndex] = {}
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            layout[groupIndex][slotIndex] = "-"
        end
    end
    return layout
end

-- Auto balance :
--   mode == "score" : simple équilibrage par score
--   mode == "role"  : Tank / Heal / DPS
MultiBot.raidus.autoBalanceRaid = function(mode)
    -- On repart d'un état propre : pool reconstruite, groupes vidés
    if MultiBot.raidus.setRaidus then
        MultiBot.raidus.setRaidus()
    end

    local bots = MultiBotRaidusCollectSelectedBots()
    local botCount = #bots

    if botCount == 0 then
        SendChatMessage("Auto balance raid : No bots selectd", "SAY")
        return
    end

    local playerName = UnitName("player")
    if not playerName or playerName == "" then
        return
    end

    local groupsUsed = math.min(RAIDUS_GROUP_COUNT, math.ceil((botCount + 1) / RAIDUS_GROUP_SLOT_COUNT))
    if groupsUsed <= 0 then
        return
    end

    -- Matrice [groupe][slot] initialisée à "-"
    local layout = createEmptyRaidusLayout()
    layout[1][1] = playerName

    if mode == "role" then
        -- Mode avancé Tank / Heal / DPS
        local tanks = {}
        local heals = {}
        local dps = {}

        for _, bot in ipairs(bots) do
            local role = bot.role or MultiBotRaidusDetectRole(bot)
            if role == "TANK" then
                table.insert(tanks, bot)
            elseif role == "HEAL" then
                table.insert(heals, bot)
            else
                table.insert(dps, bot)
            end
        end

        MultiBotRaidusSortByScore(tanks)
        MultiBotRaidusSortByScore(heals)
        MultiBotRaidusSortByScore(dps)

        local nextFreeSlot = {}
        for g = 1, groupsUsed do
            nextFreeSlot[g] = MultiBot.IF(g == 1, 2, 1)
        end

        local function placeListRoundRobin(list)
            local g = 1
            for _, bot in ipairs(list) do
                local tries = 0
                while tries < groupsUsed and nextFreeSlot[g] > RAIDUS_GROUP_SLOT_COUNT do
                    g = g + 1
                    if g > groupsUsed then
                        g = 1
                    end
                    tries = tries + 1
                end

                if nextFreeSlot[g] <= RAIDUS_GROUP_SLOT_COUNT then
                    layout[g][nextFreeSlot[g]] = bot.name
                    nextFreeSlot[g] = nextFreeSlot[g] + 1
                else
                    break
                end

                g = g + 1
                if g > groupsUsed then
                    g = 1
                end
            end
        end

        -- On commence par répartir les tanks, puis les heals, puis le reste
        placeListRoundRobin(tanks)
        placeListRoundRobin(heals)
        placeListRoundRobin(dps)
    else
        -- Mode score simple par défaut
        MultiBotRaidusSortByScore(bots)

        local positions = {}
        for s = 1, RAIDUS_GROUP_SLOT_COUNT do
            for g = 1, groupsUsed do
                if not (g == 1 and s == 1) then
                    table.insert(positions, { group = g, slot = s })
                end
            end
        end

        for index, bot in ipairs(bots) do
            local position = positions[index]
            if position then
                layout[position.group][position.slot] = bot.name
            end
        end
    end

     applyRaidusLayout(layout)
end