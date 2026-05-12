if not MultiBot then
    return
end

local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local CATEGORY_ORDER = { "class", "profession", "secondary", "weapon", "armor" }

local CATEGORY_TITLE_KEYS = {
    class = "character.skills.category.class",
    profession = "character.skills.category.profession",
    secondary = "character.skills.category.secondary",
    weapon = "character.skills.category.weapon",
    armor = "character.skills.category.armor",
}

local DIFFICULTY_COLORS = {
    orange = "|cffff8040",
    yellow = "|cffffff00",
    green = "|cff80be80",
    gray = "|cff808080",
}

local HEADER_ROW_HEIGHT = 22
local SKILL_ROW_HEIGHT = 24
local SKILL_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local SKILL_BAR_BACKGROUND = "Interface\\Buttons\\WHITE8X8"
local TOGGLE_PLUS_TEXTURE = "Interface\\Buttons\\UI-PlusButton-Up"
local TOGGLE_MINUS_TEXTURE = "Interface\\Buttons\\UI-MinusButton-Up"
local CHARACTER_FRAME_WIDTH = 300
local CHARACTER_FRAME_X = -150
local CHARACTER_SKILL_ROW_WIDTH = 240
local CHARACTER_SKILL_HEADER_WIDTH = CHARACTER_SKILL_ROW_WIDTH - 20
local CHARACTER_SKILL_NAME_WIDTH = 132
local CHARACTER_SKILL_VALUE_X = 142
local CHARACTER_SKILL_VALUE_WIDTH = 72
local CHARACTER_TABS = {
    { id = "skills", key = "character.tab.skills", fallback = "Skills" },
    { id = "reputations", key = "character.tab.reputations", fallback = "Reputations" },
    { id = "emblems", key = "character.tab.emblems", fallback = "Emblems" },
}
local CHARACTER_TAB_WIDTH = 116
local CHARACTER_TAB_HEIGHT = 28
local CHARACTER_TAB_SPACING = 6
local CHARACTER_TAB_OFFSET_Y = -4
local CHARACTER_STATUS_Y = -10
local CHARACTER_SCROLL_TOP_Y = -32
local REPUTATION_ROW_HEIGHT = 24
local EMBLEM_ROW_HEIGHT = 26
local EMBLEM_ICON_SIZE = 16
local RECIPE_FRAME_WIDTH = 340
local RECIPE_FRAME_X = 145
local RECIPE_ROW_WIDTH = 286
local RECIPE_CRAFT_BUTTON_WIDTH = 62
local RECIPE_TEXT_WIDTH = 176
local RECIPE_REFRESH_DELAY = 3.0
local COOKING_SKILL_ID = 185

local REPUTATION_BAR_COLORS = {
    [0] = { 0.80, 0.12, 0.12 }, -- Hated
    [1] = { 0.80, 0.25, 0.12 }, -- Hostile
    [2] = { 0.75, 0.35, 0.12 }, -- Unfriendly
    [3] = { 0.75, 0.75, 0.10 }, -- Neutral
    [4] = { 0.10, 0.70, 0.10 }, -- Friendly
    [5] = { 0.10, 0.65, 0.75 }, -- Honored
    [6] = { 0.05, 0.45, 0.85 }, -- Revered
    [7] = { 0.65, 0.30, 0.85 }, -- Exalted
}

local EMBLEM_NAME_KEYS = {
    [29434] = "tips.every.BadgeofJustice",
    [40752] = "tips.every.EmblemofHeroism",
    [40753] = "tips.every.EmblemofValor",
    [45624] = "tips.every.EmblemofConquest",
    [47241] = "tips.every.EmblemofTriumph",
    [49426] = "tips.every.EmblemofFrost",
}

local SKILL_DISPLAY_SPELL_IDS = {
    [171] = 2259, -- Alchemy
    [164] = 2018, -- Blacksmithing
    [333] = 7411, -- Enchanting
    [202] = 4036, -- Engineering
    [182] = 2366, -- Herbalism
    [773] = 45357, -- Inscription
    [755] = 25229, -- Jewelcrafting
    [165] = 2108, -- Leatherworking
    [186] = 2575, -- Mining
    [393] = 8613, -- Skinning
    [197] = 3908, -- Tailoring
    [185] = 2550, -- Cooking
    [129] = 3273, -- First Aid
    [356] = 7620, -- Fishing
    [43] = 201, -- Swords
    [44] = 196, -- Axes
    [45] = 264, -- Bows
    [46] = 266, -- Guns
    [54] = 198, -- Maces
    [55] = 202, -- Two-Handed Swords
    [95] = 204, -- Defense
    [118] = 674, -- Dual Wield
    [136] = 227, -- Staves
    [160] = 199, -- Two-Handed Maces
    [162] = 203, -- Unarmed
    [172] = 197, -- Two-Handed Axes
    [173] = 1180, -- Daggers
    [176] = 2567, -- Thrown
    [226] = 5011, -- Crossbows
    [228] = 5009, -- Wands
    [229] = 200, -- Polearms
    [473] = 15590, -- Fist Weapons
    [293] = 750, -- Plate Mail
    [413] = 8737, -- Mail
    [414] = 9077, -- Leather
    [415] = 9078, -- Cloth
    [433] = 9116, -- Shield
}

local function getClientSkillName(skill)
    local spellId = tonumber(skill and (skill.displaySpellId or SKILL_DISPLAY_SPELL_IDS[tonumber(skill.skillId or 0) or 0]) or 0) or 0
    if spellId <= 0 or not GetSpellInfo then
        return nil
    end

    local name = GetSpellInfo(spellId)
    if type(name) == "string" and name ~= "" then
        return name
    end
    return nil
end

local function L(key, fallback)
    if MultiBot.L then
        return MultiBot.L(key, fallback)
    end

    return fallback or key
end

local function getCategoryTitle(category)
    return L(CATEGORY_TITLE_KEYS[category] or "", category)
end

local function localizedOrNil(key)
    local value = L(key)
    if value ~= key then
        return value
    end
    return nil
end

local function getSkillDisplayName(skill)
    if type(skill) ~= "table" then
        return ""
    end

    local clientName = getClientSkillName(skill)
    if clientName then
        return clientName
    end

    local key = tostring(skill.key or "")
    if key ~= "" then
        if skill.category == "profession" or skill.category == "secondary" then
            local professionName = localizedOrNil("lootmaster.profession." .. key)
            if professionName then
                return professionName
            end
        end

        local skillName = localizedOrNil("character.skills.skill." .. key)
        if skillName then
            return skillName
        end
    end

    return skill.name or skill.key or ("Skill " .. tostring(skill.skillId or 0))
end

local function addSimpleBackdrop(frame, bgAlpha)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    if frame.SetBackdropColor then
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or 0.92)
    end

    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

local function createAceWindow(name, title, width, height, x)
    if not AceGUI then
        return nil
    end

    local widget = AceGUI:Create("Window")
    widget:SetTitle(title or "")
    widget:SetWidth(width)
    widget:SetHeight(height)
    widget:SetLayout("Absolute")

    if widget.SetLayout then
        widget:SetLayout("Manual")
    end

    if widget.EnableResize then
        widget:EnableResize(false)
    end

    local frame = widget.frame
    frame.aceWidget = widget
    frame.content = widget.content or frame

    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end

    if frame.content and frame.content.ClearAllPoints then
        frame.content:ClearAllPoints()
        frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
        frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
        addSimpleBackdrop(frame.content, 0.90)
    end

    frame:SetPoint("CENTER", UIParent, "CENTER", x or 0, 0)

    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        frame:SetFrameStrata(strataLevel)
    else
        frame:SetFrameStrata("DIALOG")
    end

    _G[name] = frame

    return frame
end

local function setWindowTitle(frame, title)
    if frame and frame.aceWidget and frame.aceWidget.SetTitle then
        frame.aceWidget:SetTitle(title or "")
    elseif frame and frame.title then
        frame.title:SetText(title or "")
    end
end

local function getFrameContent(frame)
    return (frame and frame.content) or frame
end

local function setButtonEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
    else
        button:Disable()
    end
end

local function createText(parent, template, point, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    text:SetPoint(point or "TOPLEFT", parent, point or "TOPLEFT", x or 0, y or 0)
    text:SetJustifyH("LEFT")
    return text
end

local function setFrameShown(frame, shown)
    if not frame then
        return
    end

    if shown then
        frame:Show()
    else
        frame:Hide()
    end
end

local function getTabTitle(tab)
    return L(tab.key, tab.fallback)
end

local function createCharacterTab(parent, name, index, text)
    local template = (_G["CharacterFrameTabButtonTemplate"] and "CharacterFrameTabButtonTemplate") or "UIPanelButtonTemplate"
    local button = CreateFrame("Button", name .. "Tab" .. tostring(index), parent, template)
    button:SetID(index)
    button:SetWidth(CHARACTER_TAB_WIDTH)
    button:SetHeight(CHARACTER_TAB_HEIGHT)
    button:SetText(text or "")
    return button
end

local function getFactionDisplayName(reputation)
    local factionId = tonumber(reputation and reputation.factionId or 0) or 0
    if factionId > 0 and GetFactionInfoByID then
        local name = GetFactionInfoByID(factionId)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    local name = tostring(reputation and reputation.name or "")
    if name ~= "" then
        return name
    end

    return "Faction " .. tostring(factionId)
end

local function getReputationRankLabel(rank)
    local index = (tonumber(rank or 0) or 0) + 1
    local label = _G["FACTION_STANDING_LABEL" .. tostring(index)]
    if type(label) == "string" and label ~= "" then
        return label
    end

    return tostring(rank or "")
end

local function getReputationColor(rank)
    local color = REPUTATION_BAR_COLORS[tonumber(rank or 0) or 0] or REPUTATION_BAR_COLORS[3]
    return color[1], color[2], color[3]
end

local function getEmblemInfo(itemId)
    itemId = tonumber(itemId or 0) or 0
    local name, icon
    if itemId > 0 and GetItemInfo then
        local itemInfo = { GetItemInfo(itemId) }
        name = itemInfo[1]
        icon = itemInfo[10]
    end

    if itemId > 0 and not icon and GetItemIcon then
        icon = GetItemIcon(itemId)
    end

    if type(name) ~= "string" or name == "" then
        local key = EMBLEM_NAME_KEYS[itemId]
        name = key and L(key, "item:" .. tostring(itemId)) or ("item:" .. tostring(itemId))
    end

    if type(icon) ~= "string" or icon == "" then
        icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    return name, icon
end

local function formatMoneyText(money)
    money = math.max(0, tonumber(money or 0) or 0)
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    local parts = {}

    if gold > 0 then
        table.insert(parts, gold .. " |TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
    end

    if silver > 0 or gold > 0 then
        table.insert(parts, silver .. " |TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t")
    end

    table.insert(parts, copper .. " |TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t")
    return table.concat(parts, "  ")
end

local function getSkillBarText(skill)
    local value = tonumber(skill and skill.value or 0) or 0
    local max = tonumber(skill and skill.max or 0) or 0
    if max <= 0 then
        return tostring(value)
    end

    return value .. "/" .. max
end

local function getSkillBarValues(skill)
    local value = tonumber(skill and skill.value or 0) or 0
    local max = tonumber(skill and skill.max or 0) or 0
    return value, math.max(1, max)
end

local function getItemName(itemId)
    itemId = tonumber(itemId or 0) or 0
    if itemId <= 0 then
        return ""
    end

    local name = GetItemInfo(itemId)
    return name or ("item:" .. itemId)
end

local function getSpellDisplay(spellId)
    spellId = tonumber(spellId or 0) or 0
    if spellId <= 0 then
        return "spell:0", "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local name, rank, icon = GetSpellInfo(spellId)
    return name or ("spell:" .. spellId), icon or "Interface\\Icons\\INV_Misc_QuestionMark", rank or ""
end

local function buildMaterialsText(recipe)
    local parts = {}
    for _, material in ipairs(recipe.materials or {}) do
        local itemId = tonumber(material.itemId or 0) or 0
        local required = tonumber(material.required or 0) or 0
        local available = tonumber(material.available or 0) or 0
        if itemId > 0 and required > 0 then
            table.insert(parts, getItemName(itemId) .. " " .. available .. "/" .. required)
        end
    end

    return table.concat(parts, ", ")
end

local function getFirstMissingMaterial(recipe)
    for _, material in ipairs((recipe and recipe.materials) or {}) do
        local itemId = tonumber(material.itemId or 0) or 0
        local required = tonumber(material.required or 0) or 0
        local available = tonumber(material.available or 0) or 0
        if itemId > 0 and required > available then
            return {
                itemId = itemId,
                missing = required - available,
            }
        end
    end

    return nil
end

local function getMissingMaterials(recipe)
    local missings = {}
    for _, material in ipairs((recipe and recipe.materials) or {}) do
        local itemId = tonumber(material.itemId or 0) or 0
        local required = tonumber(material.required or 0) or 0
        local available = tonumber(material.available or 0) or 0
        if itemId > 0 and required > available then
            table.insert(missings, {
                itemId = itemId,
                missing = required - available,
            })
        end
    end

    return missings
end

local function getRecipePendingKey(botName, skillId, spellId)
    return string.lower(tostring(botName or "")) .. ":" .. tostring(tonumber(skillId or 0) or 0) .. ":" .. tostring(tonumber(spellId or 0) or 0)
end

local function getCraftReasonText(reason, skillId)
    reason = tostring(reason or "")
    if reason == "" or reason == "OK" then
        return ""
    end

    if reason == "REQUIRES_SPELL_FOCUS" and tonumber(skillId or 0) == COOKING_SKILL_ID then
        return L("profession.recipes.craft.reason.REQUIRES_SPELL_FOCUS.cooking", "You must be near a cooking fire.")
    end

    local castCode = string.match(reason, "^CAST_FAILED_(%d+)$")
    if castCode then
        return string.format(L("profession.recipes.craft.reason.cast_code", "The server refused the cast (code %s)."), castCode)
    end

    return L("profession.recipes.craft.reason." .. reason, reason)
end

local function scheduleRecipeRefresh(botName, skillId)
    if not MultiBot.Comm or not MultiBot.Comm.RequestProfessionRecipes then
        return
    end

    local function refresh()
        local frame = MultiBot.professionRecipeFrame
        if frame and not frame:IsShown() then
            return
        end

        if frame and frame:IsShown() and frame.botName ~= botName then
            return
        end

        if frame and frame:IsShown() and frame.skill and tonumber(frame.skill.skillId or 0) ~= tonumber(skillId or 0) then
            return
        end

        MultiBot.Comm.RequestProfessionRecipes(botName, skillId)
    end

    if type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(RECIPE_REFRESH_DELAY, refresh)
    else
        refresh()
    end
end

local function ensureRecipeFrame()
    if MultiBot.professionRecipeFrame then
        return MultiBot.professionRecipeFrame
    end

    local frame = createAceWindow("MultiBotProfessionRecipeFrame", L("profession.recipes", "Recipes"), RECIPE_FRAME_WIDTH, 450, RECIPE_FRAME_X)
    if not frame then
        return nil
    end

    local content = getFrameContent(frame)
    frame.status = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, -10)
    frame.rows = {}
    frame.page = 1
    frame.pageSize = 14
    frame.recipes = {}
    frame.pendingCrafts = {}

    for i = 1, frame.pageSize do
        local row = CreateFrame("Button", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -30 - ((i - 1) * 25))
        row:SetWidth(RECIPE_ROW_WIDTH)
        row:SetHeight(22)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetWidth(20)
        row.icon:SetHeight(20)
        row.text = createText(row, "GameFontHighlightSmall", "LEFT", 26, 0)
        row.text:SetWidth(RECIPE_TEXT_WIDTH)
        row.text:SetHeight(20)
        row.craftButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.craftButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.craftButton:SetWidth(RECIPE_CRAFT_BUTTON_WIDTH)
        row.craftButton:SetHeight(20)
        row.craftButton:SetText(L("profession.recipes.craft", "Craft"))
        row.craftButton:SetScript("OnClick", function()
            local recipe = row.recipe
            if not recipe or not frame.botName then return end

            local skillId = tonumber(recipe.skillId or (frame.skill and frame.skill.skillId) or 0) or 0
            local spellId = tonumber(recipe.spellId or 0) or 0
            local itemId = tonumber(recipe.itemId or 0) or 0
            local craftable = tonumber(recipe.craftable or 0) or 0
            if craftable <= 0 then
                local missings = getMissingMaterials(recipe)
                local requested = false
                if #missings > 0 and MultiBot.Comm and MultiBot.Comm.RunInventoryItemAction then
                    for _, missing in ipairs(missings) do
                        local token = MultiBot.Comm.RunInventoryItemAction(frame.botName, "BUY_ITEM", missing.itemId, missing.missing)
                        if token then
                            requested = true
                        end
                    end
                end
                if requested then
                    frame.status:SetText(L("profession.recipes.buy_missing.pending", "Buy requested..."))
                else
                    frame.status:SetText(L("profession.recipes.buy_missing.failed", "Buy request failed."))
                end
                return
            end

            if skillId <= 0 or spellId <= 0 then
                return
            end

            if MultiBot.Comm and MultiBot.Comm.RunProfessionRecipeCraft then
                local token = MultiBot.Comm.RunProfessionRecipeCraft(frame.botName, skillId, spellId, itemId)
                if token then
                    frame.pendingCrafts[getRecipePendingKey(frame.botName, skillId, spellId)] = true
                    frame.status:SetText(L("profession.recipes.craft.pending", "Craft requested..."))
                    frame:render()
                else
                    frame.status:SetText(L("profession.recipes.craft.failed", "Craft request failed."))
                end
            end
        end)
        row.craftButton:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if row.recipe and tonumber(row.recipe.craftable or 0) <= 0 and getFirstMissingMaterial(row.recipe) then
                GameTooltip:AddLine(L("profession.recipes.buy_missing", "Buy"))
                GameTooltip:AddLine(L("profession.recipes.buy_missing.tooltip", "Ask the bot to buy the first missing material from a nearby vendor."), 1, 1, 1, true)
            else
                GameTooltip:AddLine(L("profession.recipes.craft", "Craft"))
                GameTooltip:AddLine(L("profession.recipes.craft.tooltip", "Ask the bot to craft this recipe once."), 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        row.craftButton:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        row:SetScript("OnEnter", function(self)
            if not self.recipe or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.recipe.spellId and self.recipe.spellId > 0 then
                GameTooltip:SetHyperlink("spell:" .. self.recipe.spellId)
            end
            local materials = buildMaterialsText(self.recipe)
            if materials ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(materials, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        frame.rows[i] = row
    end

    frame.prev = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    frame.prev:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 18, 8)
    frame.prev:SetWidth(48)
    frame.prev:SetHeight(20)
    frame.prev:SetText("<")

    frame.pageText = createText(content, "GameFontNormalSmall", "BOTTOM", 0, 12)

    frame.next = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    frame.next:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -18, 8)
    frame.next:SetWidth(48)
    frame.next:SetHeight(20)
    frame.next:SetText(">")

    frame.render = function(self)
        local maxPage = math.max(1, math.ceil(#self.recipes / self.pageSize))
        if self.page > maxPage then self.page = maxPage end
        if self.page < 1 then self.page = 1 end

        self.pageText:SetText(self.page .. "/" .. maxPage)
        setButtonEnabled(self.prev, self.page > 1)
        setButtonEnabled(self.next, self.page < maxPage)

        local from = ((self.page - 1) * self.pageSize) + 1
        for i = 1, self.pageSize do
            local row = self.rows[i]
            local recipe = self.recipes[from + i - 1]
            row.recipe = recipe
            if recipe then
                local name, icon = getSpellDisplay(recipe.spellId)
                local color = DIFFICULTY_COLORS[recipe.difficulty or ""] or "|cffffffff"
                local craftable = tonumber(recipe.craftable or 0) or 0
                local pending = self.pendingCrafts[getRecipePendingKey(self.botName, recipe.skillId, recipe.spellId)]
                local missing = getFirstMissingMaterial(recipe)
                row.icon:SetTexture(MultiBot.SafeTexturePath(icon))
                row.text:SetText(color .. name .. "|r |cff999999x" .. craftable .. "|r")
                if craftable > 0 then
                    row.craftButton:SetText(pending and "..." or L("profession.recipes.craft", "Craft"))
                    setButtonEnabled(row.craftButton, tonumber(recipe.spellId or 0) > 0 and not pending)
                elseif missing then
                    row.craftButton:SetText(L("profession.recipes.buy_missing", "Buy"))
                    setButtonEnabled(row.craftButton, true)
                else
                    row.craftButton:SetText(L("profession.recipes.craft", "Craft"))
                    setButtonEnabled(row.craftButton, false)
                end
                row.craftButton:Show()
                row:Show()
            else
                row.craftButton:Hide()
                row:Hide()
            end
        end
    end

    frame.prev:SetScript("OnClick", function()
        frame.page = frame.page - 1
        frame:render()
    end)

    frame.next:SetScript("OnClick", function()
        frame.page = frame.page + 1
        frame:render()
    end)

    frame.setRecipes = function(self, botName, skill, recipes)
        self.botName = botName
        self.skill = skill
        self.recipes = recipes or {}
        self.page = 1
        setWindowTitle(self, (skill and getSkillDisplayName(skill) or L("profession.recipes", "Recipes")) .. " - " .. (botName or ""))
        self.status:SetText(#self.recipes .. " " .. L("profession.recipes.count", "unknown recipe(s)"))
        self:render()
        self:Show()
    end

    frame:Hide()
    MultiBot.professionRecipeFrame = frame
    return frame
end

local function ensureCharacterFrame()
    if MultiBot.characterInfoFrame then
        return MultiBot.characterInfoFrame
    end

    local frame = createAceWindow("MultiBotCharacterInfoFrame", L("character.info", "Character info"), CHARACTER_FRAME_WIDTH, 450, CHARACTER_FRAME_X)
    if not frame then
        return nil
    end

    local content = getFrameContent(frame)

    frame.tabs = {}
    frame.activeTab = "skills"
    frame.status = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, CHARACTER_STATUS_Y)
    frame.reputationStatus = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, CHARACTER_STATUS_Y)
    frame.emblemStatus = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, CHARACTER_STATUS_Y)
    frame.rows = {}
    frame.reputationRows = {}
    frame.emblemRows = {}
    frame.skills = {}
    frame.reputations = {}
    frame.emblems = {}
    frame.emblemMoney = nil
    frame.collapsedCategories = frame.collapsedCategories or {}

    local tabTotalWidth = (#CHARACTER_TABS * CHARACTER_TAB_WIDTH) + ((#CHARACTER_TABS - 1) * CHARACTER_TAB_SPACING)
    local tabStartX = -math.floor(tabTotalWidth / 2)

    for index, tab in ipairs(CHARACTER_TABS) do
        local button = createCharacterTab(frame, "MultiBotCharacterInfoFrame", index, getTabTitle(tab))
        button:SetPoint("TOPLEFT", content, "BOTTOM", tabStartX + ((index - 1) * (CHARACTER_TAB_WIDTH + CHARACTER_TAB_SPACING)), CHARACTER_TAB_OFFSET_Y)
        button:SetScript("OnClick", function()
            frame:setActiveTab(tab.id)
        end)
        button.tabId = tab.id
        button.tabIndex = index
        frame.tabs[tab.id] = button
    end

    frame.numTabs = #CHARACTER_TABS
    frame.usePanelTemplates = _G["CharacterFrameTabButtonTemplate"] and PanelTemplates_SetTab
    if frame.usePanelTemplates and PanelTemplates_SetNumTabs then
        PanelTemplates_SetNumTabs(frame, frame.numTabs)
    end

    frame.scrollFrame = CreateFrame("ScrollFrame", "MultiBotCharacterInfoFrameSkillScrollFrame", content, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 18, CHARACTER_SCROLL_TOP_Y)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -28, 36)

    frame.scrollChild = CreateFrame("Frame", "MultiBotCharacterInfoFrameSkillScrollChild", frame.scrollFrame)
    frame.scrollChild:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
    frame.scrollChild:SetHeight(1)
    frame.scrollFrame:SetScrollChild(frame.scrollChild)

    frame.reputationScrollFrame = CreateFrame("ScrollFrame", "MultiBotCharacterInfoFrameReputationScrollFrame", content, "UIPanelScrollFrameTemplate")
    frame.reputationScrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 18, CHARACTER_SCROLL_TOP_Y)
    frame.reputationScrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -28, 36)

    frame.reputationScrollChild = CreateFrame("Frame", "MultiBotCharacterInfoFrameReputationScrollChild", frame.reputationScrollFrame)
    frame.reputationScrollChild:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
    frame.reputationScrollChild:SetHeight(1)
    frame.reputationScrollFrame:SetScrollChild(frame.reputationScrollChild)

    frame.emblemScrollFrame = CreateFrame("ScrollFrame", "MultiBotCharacterInfoFrameEmblemScrollFrame", content, "UIPanelScrollFrameTemplate")
    frame.emblemScrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 18, CHARACTER_SCROLL_TOP_Y)
    frame.emblemScrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -28, 58)

    frame.emblemScrollChild = CreateFrame("Frame", "MultiBotCharacterInfoFrameEmblemScrollChild", frame.emblemScrollFrame)
    frame.emblemScrollChild:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
    frame.emblemScrollChild:SetHeight(1)
    frame.emblemScrollFrame:SetScrollChild(frame.emblemScrollChild)

    frame.emblemMoneyText = createText(content, "GameFontHighlightSmall", "BOTTOMRIGHT", -18, 14)
    frame.emblemMoneyText:SetWidth(170)
    frame.emblemMoneyText:SetHeight(18)
    frame.emblemMoneyText:SetJustifyH("RIGHT")

    frame.itemInfoEventFrame = CreateFrame("Frame")
    pcall(frame.itemInfoEventFrame.RegisterEvent, frame.itemInfoEventFrame, "GET_ITEM_INFO_RECEIVED")
    frame.itemInfoEventFrame:SetScript("OnEvent", function()
        if frame.activeTab == "emblems" then
            frame:renderEmblems()
        end
    end)

    local function ensureSkillRow(index)
        if frame.rows[index] then
            return frame.rows[index]
        end

        local row = CreateFrame("Button", nil, frame.scrollChild)
        row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, 0)
        row:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
        row:SetHeight(SKILL_ROW_HEIGHT)

        row.toggle = row:CreateTexture(nil, "ARTWORK")
        row.toggle:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.toggle:SetWidth(16)
        row.toggle:SetHeight(16)
        row.toggle:Hide()

        row.headerText = createText(row, "GameFontNormal", "LEFT", 20, 0)
        row.headerText:SetWidth(CHARACTER_SKILL_HEADER_WIDTH)
        row.headerText:SetHeight(18)
        row.headerText:Hide()

        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.bar:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.bar:SetHeight(18)
        row.bar:SetStatusBarTexture(SKILL_BAR_TEXTURE)
        row.bar:SetStatusBarColor(0.05, 0.12, 0.70, 0.85)
        row.bar:SetMinMaxValues(0, 1)
        row.bar:SetValue(0)
        row.bar:SetBackdrop({
            bgFile = SKILL_BAR_BACKGROUND,
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        row.bar:SetBackdropColor(0.02, 0.02, 0.10, 0.75)
        row.bar:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

        row.nameText = createText(row.bar, "GameFontNormalSmall", "LEFT", 8, 0)
        row.nameText:SetWidth(CHARACTER_SKILL_NAME_WIDTH)
        row.nameText:SetHeight(18)

        row.valueText = createText(row.bar, "GameFontHighlightSmall", "LEFT", CHARACTER_SKILL_VALUE_X, 0)
        row.valueText:SetWidth(CHARACTER_SKILL_VALUE_WIDTH)
        row.valueText:SetHeight(18)

        row:SetScript("OnClick", function(self)
            if self.categoryHeader then
                frame.collapsedCategories[self.categoryHeader] = not frame.collapsedCategories[self.categoryHeader]
                frame:renderSkills()
                return
            end

            if not self.skill then return end
            if self.skill.category ~= "profession" and self.skill.category ~= "secondary" then return end
            if MultiBot.Comm and MultiBot.Comm.RequestProfessionRecipes then
                ensureRecipeFrame()
                setWindowTitle(MultiBot.professionRecipeFrame, getSkillDisplayName(self.skill) .. " - " .. (frame.botName or ""))
                MultiBot.professionRecipeFrame.status:SetText(L("profession.recipes.loading", "Loading..."))
                MultiBot.professionRecipeFrame.recipes = {}
                MultiBot.professionRecipeFrame:render()
                MultiBot.professionRecipeFrame:Show()
                MultiBot.Comm.RequestProfessionRecipes(frame.botName, self.skill.skillId)
            end
        end)

        frame.rows[index] = row
        return row
    end

    local function ensureReputationRow(index)
        if frame.reputationRows[index] then
            return frame.reputationRows[index]
        end

        local row = CreateFrame("Frame", nil, frame.reputationScrollChild)
        row:SetPoint("TOPLEFT", frame.reputationScrollChild, "TOPLEFT", 0, 0)
        row:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
        row:SetHeight(REPUTATION_ROW_HEIGHT)
        row:EnableMouse(true)

        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.bar:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.bar:SetHeight(18)
        row.bar:SetStatusBarTexture(SKILL_BAR_TEXTURE)
        row.bar:SetMinMaxValues(0, 1)
        row.bar:SetValue(0)
        row.bar:SetBackdrop({
            bgFile = SKILL_BAR_BACKGROUND,
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        row.bar:SetBackdropColor(0.02, 0.02, 0.10, 0.75)
        row.bar:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

        row.nameText = createText(row.bar, "GameFontNormalSmall", "LEFT", 8, 0)
        row.nameText:SetWidth(128)
        row.nameText:SetHeight(18)

        row.valueText = createText(row.bar, "GameFontHighlightSmall", "RIGHT", -8, 0)
        row.valueText:SetWidth(98)
        row.valueText:SetHeight(18)
        row.valueText:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self)
            if not self.reputation then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(getFactionDisplayName(self.reputation), 1, 0.82, 0)
            GameTooltip:AddLine(getReputationRankLabel(self.reputation.rank) .. " " .. tostring(self.reputation.value or 0) .. "/" .. tostring(self.reputation.max or 0), 1, 1, 1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.reputationRows[index] = row
        return row
    end

    local function ensureEmblemRow(index)
        if frame.emblemRows[index] then
            return frame.emblemRows[index]
        end

        local row = CreateFrame("Button", nil, frame.emblemScrollChild)
        row:SetPoint("TOPLEFT", frame.emblemScrollChild, "TOPLEFT", 0, 0)
        row:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
        row:SetHeight(EMBLEM_ROW_HEIGHT)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        row.icon:SetWidth(EMBLEM_ICON_SIZE)
        row.icon:SetHeight(EMBLEM_ICON_SIZE)

        row.nameText = createText(row, "GameFontHighlightSmall", "LEFT", 0, 0)
        row.nameText:SetWidth(160)
        row.nameText:SetHeight(20)

        row.countText = createText(row, "GameFontNormalSmall", "RIGHT", -56, 0)
        row.countText:SetWidth(48)
        row.countText:SetHeight(20)
        row.countText:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self)
            local itemId = tonumber(self.itemId or 0) or 0
            if itemId <= 0 then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. tostring(itemId))
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame.emblemRows[index] = row
        return row
    end

    local function showHeaderRow(row, item, y)
        row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -y)
        row:SetHeight(HEADER_ROW_HEIGHT)
        row.skill = nil
        row.categoryHeader = item.category

        row.bar:Hide()
        row.nameText:Hide()
        row.valueText:Hide()

        row.toggle:SetTexture(MultiBot.SafeTexturePath(frame.collapsedCategories[item.category] and TOGGLE_PLUS_TEXTURE or TOGGLE_MINUS_TEXTURE))
        row.toggle:Show()

        row.headerText:SetText("|cffffcc00" .. item.header .. "|r")
        row.headerText:Show()

        row:Show()
        return HEADER_ROW_HEIGHT
    end

    local function showSkillRow(row, item, y)
        local skill = item.skill
        local value, max = getSkillBarValues(skill)
        local clickable = skill.category == "profession" or skill.category == "secondary"

        row:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 0, -y)
        row:SetHeight(SKILL_ROW_HEIGHT)
        row.skill = skill
        row.categoryHeader = nil

        row.toggle:Hide()
        row.headerText:Hide()

        row.bar:SetMinMaxValues(0, max)
        row.bar:SetValue(math.min(value, max))
        row.bar:Show()

        row.nameText:SetText((clickable and "|cffffcc00" or "|cffffffff") .. getSkillDisplayName(skill) .. "|r")
        row.nameText:Show()

        row.valueText:SetText("|cffffffff" .. getSkillBarText(skill) .. "|r")
        row.valueText:Show()

        row:Show()
        return SKILL_ROW_HEIGHT
    end

    local function setVisibleRows(rows, visible, hasContent)
        for _, row in ipairs(rows or {}) do
            if visible and hasContent(row) then
                row:Show()
            else
                row:Hide()
            end
        end
    end

    frame.syncTabVisibility = function(self)
        local showSkills = self.activeTab == "skills"
        local showReputations = self.activeTab == "reputations"
        local showEmblems = self.activeTab == "emblems"

        setFrameShown(self.status, showSkills)
        setFrameShown(self.scrollFrame, showSkills)
        setFrameShown(self.scrollChild, showSkills)
        setVisibleRows(self.rows, showSkills, function(row)
            return row.skill ~= nil or row.categoryHeader ~= nil
        end)

        setFrameShown(self.reputationStatus, showReputations)
        setFrameShown(self.reputationScrollFrame, showReputations)
        setFrameShown(self.reputationScrollChild, showReputations)
        setVisibleRows(self.reputationRows, showReputations, function(row)
            return row.reputation ~= nil
        end)

        setFrameShown(self.emblemStatus, showEmblems)
        setFrameShown(self.emblemScrollFrame, showEmblems)
        setFrameShown(self.emblemScrollChild, showEmblems)
        setFrameShown(self.emblemMoneyText, showEmblems)
        setVisibleRows(self.emblemRows, showEmblems, function(row)
            return row.itemId ~= nil
        end)
    end

    frame.renderSkills = function(self)
        local ordered = {}

        for _, category in ipairs(CATEGORY_ORDER) do
            local categoryItems = {}

            for _, skill in ipairs(self.skills or {}) do
                if skill.category == category then
                    table.insert(categoryItems, skill)
                end
            end

            if #categoryItems > 0 then
                table.insert(ordered, { header = getCategoryTitle(category), category = category })
                table.sort(categoryItems, function(a, b) return getSkillDisplayName(a) < getSkillDisplayName(b) end)

                if not self.collapsedCategories[category] then
                    for _, skill in ipairs(categoryItems) do
                        table.insert(ordered, { skill = skill })
                    end
                end
            end
        end

        self.status:SetText(#(self.skills or {}) .. " " .. L("character.skills.count", "skill(s)"))

        local contentHeight = 0

        for i = 1, #ordered do
            local row = ensureSkillRow(i)
            local item = ordered[i]

            if not item then
                row:Hide()
            elseif item.header then
                contentHeight = contentHeight + showHeaderRow(row, item, contentHeight)
            else
                contentHeight = contentHeight + showSkillRow(row, item, contentHeight)
            end
        end

        for i = #ordered + 1, #self.rows do
            local row = self.rows[i]
            row.skill = nil
            row.categoryHeader = nil
            row:Hide()
        end

        self.scrollChild:SetHeight(math.max(1, contentHeight))
        self.scrollFrame:SetVerticalScroll(0)
        self:syncTabVisibility()
    end

    frame.renderReputations = function(self)
        local reputations = {}
        for _, reputation in ipairs(self.reputations or {}) do
            table.insert(reputations, reputation)
        end

        table.sort(reputations, function(a, b)
            return getFactionDisplayName(a) < getFactionDisplayName(b)
        end)

        self.reputationStatus:SetText(#reputations .. " " .. L("character.reputations.count", "reputation(s)"))
        if #reputations == 0 then
            self.reputationStatus:SetText(L("character.reputations.empty", "No reputation data."))
        end

        local contentHeight = 0
        for i = 1, #reputations do
            local reputation = reputations[i]
            local row = ensureReputationRow(i)
            local value = tonumber(reputation.value or 0) or 0
            local max = tonumber(reputation.max or 0) or 0
            if max <= 0 then
                max = 1
            end

            row:SetPoint("TOPLEFT", frame.reputationScrollChild, "TOPLEFT", 0, -contentHeight)
            row.reputation = reputation
            row.bar:SetMinMaxValues(0, max)
            row.bar:SetValue(math.min(value, max))
            row.bar:SetStatusBarColor(getReputationColor(reputation.rank))
            row.nameText:SetText("|cffffcc00" .. getFactionDisplayName(reputation) .. "|r")
            row.valueText:SetText("|cffffffff" .. getReputationRankLabel(reputation.rank) .. " " .. value .. "/" .. max .. "|r")
            row:Show()
            contentHeight = contentHeight + REPUTATION_ROW_HEIGHT
        end

        for i = #reputations + 1, #self.reputationRows do
            local row = self.reputationRows[i]
            row.reputation = nil
            row:Hide()
        end

        self.reputationScrollChild:SetHeight(math.max(1, contentHeight))
        self.reputationScrollFrame:SetVerticalScroll(0)
        self:syncTabVisibility()
    end

    frame.renderEmblems = function(self)
        local emblems = {}
        for _, emblem in ipairs(self.emblems or {}) do
            table.insert(emblems, emblem)
        end

        table.sort(emblems, function(a, b)
            return (tonumber(a.itemId or 0) or 0) < (tonumber(b.itemId or 0) or 0)
        end)

        self.emblemStatus:SetText(#emblems .. " " .. L("character.emblems.count", "emblem(s)"))
        if #emblems == 0 then
            self.emblemStatus:SetText(L("character.emblems.empty", "No emblems."))
        end

        local contentHeight = 0
        for i = 1, #emblems do
            local emblem = emblems[i]
            local row = ensureEmblemRow(i)
            local itemId = tonumber(emblem.itemId or 0) or 0
            local count = tonumber(emblem.count or 0) or 0
            local name, icon = getEmblemInfo(itemId)

            row:SetPoint("TOPLEFT", frame.emblemScrollChild, "TOPLEFT", 0, -contentHeight)
            row.itemId = itemId
            row.icon:SetTexture(MultiBot.SafeTexturePath(icon))
            row.nameText:SetText((count > 0 and "|cffffffff" or "|cff808080") .. name .. "|r")
            row.countText:SetText((count > 0 and "|cffffcc00" or "|cff808080") .. tostring(count) .. "|r")
            row:Show()
            contentHeight = contentHeight + EMBLEM_ROW_HEIGHT
        end

        for i = #emblems + 1, #self.emblemRows do
            local row = self.emblemRows[i]
            row.itemId = nil
            row:Hide()
        end

        self.emblemScrollChild:SetHeight(math.max(1, contentHeight))
        self.emblemMoneyText:SetText(self.emblemMoney and formatMoneyText(self.emblemMoney) or "")
        self:syncTabVisibility()
    end

    frame.setActiveTab = function(self, tabId)
        tabId = tabId or "skills"
        self.activeTab = tabId
        local selectedIndex

        for id, button in pairs(self.tabs or {}) do
            if id == tabId then
                selectedIndex = button.tabIndex
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end

        if selectedIndex and self.usePanelTemplates then
            PanelTemplates_SetTab(self, selectedIndex)
        end

        self:syncTabVisibility()
    end

    frame.setSkills = function(self, botName, skills)
        self.botName = botName
        self.skills = skills or {}
        setWindowTitle(self, L("character.info", "Character info") .. " - " .. (botName or ""))
        self:renderSkills()
        self:Show()
    end

    frame.setReputations = function(self, botName, reputations)
        self.botName = botName
        self.reputations = reputations or {}
        setWindowTitle(self, L("character.info", "Character info") .. " - " .. (botName or ""))
        self:renderReputations()
        self:Show()
    end

    frame.setEmblems = function(self, botName, emblems, money)
        self.botName = botName
        self.emblems = emblems or {}
        self.emblemMoney = money
        setWindowTitle(self, L("character.info", "Character info") .. " - " .. (botName or ""))
        self:renderEmblems()
        self:Show()
    end

    frame:setActiveTab("skills")
    frame:Hide()
    MultiBot.characterInfoFrame = frame
    return frame
end

function MultiBot.OpenCharacterInfo(botName)
    botName = tostring(botName or "")
    if botName == "" then
        return false
    end

    local frame = ensureCharacterFrame()
    frame.botName = botName
    setWindowTitle(frame, L("character.info", "Character info") .. " - " .. botName)
    frame.skills = {}
    frame.reputations = {}
    frame.emblems = {}
    frame.emblemMoney = nil
    frame:renderSkills()
    frame:renderReputations()
    frame:renderEmblems()
    frame.status:SetText(L("character.skills.loading", "Loading..."))
    frame.reputationStatus:SetText(L("character.reputations.loading", "Loading..."))
    frame.emblemStatus:SetText(L("character.emblems.loading", "Loading..."))
    frame:setActiveTab("skills")
    frame:Show()

    local requested = false
    if MultiBot.Comm and MultiBot.Comm.RequestBotSkills then
        requested = MultiBot.Comm.RequestBotSkills(botName) or requested
    end

    if MultiBot.Comm and MultiBot.Comm.RequestBotReputations then
        requested = MultiBot.Comm.RequestBotReputations(botName) or requested
    end

    if MultiBot.Comm and MultiBot.Comm.RequestBotEmblems then
        requested = MultiBot.Comm.RequestBotEmblems(botName) or requested
    end

    return requested
end

function MultiBot.OnBridgeBotSkills(botName, skills)
    ensureCharacterFrame():setSkills(botName, skills or {})
end

function MultiBot.OnBridgeBotReputations(botName, reputations)
    ensureCharacterFrame():setReputations(botName, reputations or {})
end

function MultiBot.OnBridgeBotEmblems(botName, emblems, _token, money)
    ensureCharacterFrame():setEmblems(botName, emblems or {}, money)
end

function MultiBot.OnBridgeProfessionRecipes(botName, skillId, recipes)
    local skill
    local frame = ensureCharacterFrame()
    for _, candidate in ipairs(frame.skills or {}) do
        if tonumber(candidate.skillId or 0) == tonumber(skillId or 0) then
            skill = candidate
            break
        end
    end

    ensureRecipeFrame():setRecipes(botName, skill or { name = "Skill " .. tostring(skillId), skillId = skillId }, recipes or {})
end

function MultiBot.OnBridgeProfessionRecipeCraftResult(botName, skillId, spellId, _itemId, result, reason)
    local frame = ensureRecipeFrame()
    local sameBot = string.lower(tostring(frame.botName or "")) == string.lower(tostring(botName or ""))
    local sameSkill = frame.skill and tonumber(frame.skill.skillId or 0) == tonumber(skillId or 0)

    frame.pendingCrafts[getRecipePendingKey(botName, skillId, spellId)] = nil

    if result == "OK" then
        if sameBot and sameSkill then
            frame.status:SetText(L("profession.recipes.craft.ok", "Craft started."))
            frame:render()
        end
        scheduleRecipeRefresh(botName, skillId)
        return
    end

    if sameBot and sameSkill then
        local reasonText = getCraftReasonText(reason, skillId)
        if reasonText ~= "" then
            frame.status:SetText(string.format(L("profession.recipes.craft.err", "Craft failed: %s"), reasonText))
        else
            frame.status:SetText(L("profession.recipes.craft.failed", "Craft request failed."))
        end
        frame:render()
    end
end

function MultiBot.InitializeCharacterInfoFrame()
    ensureCharacterFrame()
    ensureRecipeFrame()
end