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
local RECIPE_FRAME_WIDTH = 340
local RECIPE_FRAME_X = 145
local RECIPE_ROW_WIDTH = 302
local RECIPE_TEXT_WIDTH = 270

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
                row.icon:SetTexture(MultiBot.SafeTexturePath(icon))
                row.text:SetText(color .. name .. "|r |cff999999x" .. craftable .. "|r")
                row:Show()
            else
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

    frame.status = createText(content, "GameFontHighlightSmall", "TOPLEFT", 18, -10)
    frame.rows = {}
    frame.skills = {}
    frame.collapsedCategories = frame.collapsedCategories or {}

    frame.scrollFrame = CreateFrame("ScrollFrame", "MultiBotCharacterInfoFrameSkillScrollFrame", content, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -32)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -28, 36)

    frame.scrollChild = CreateFrame("Frame", "MultiBotCharacterInfoFrameSkillScrollChild", frame.scrollFrame)
    frame.scrollChild:SetWidth(CHARACTER_SKILL_ROW_WIDTH)
    frame.scrollChild:SetHeight(1)
    frame.scrollFrame:SetScrollChild(frame.scrollChild)

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
    end

    frame.setSkills = function(self, botName, skills)
        self.botName = botName
        self.skills = skills or {}
        setWindowTitle(self, L("character.info", "Character info") .. " - " .. (botName or ""))
        self:renderSkills()
        self:Show()
    end

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
    frame:renderSkills()
    frame.status:SetText(L("character.skills.loading", "Loading..."))
    frame:Show()

    if MultiBot.Comm and MultiBot.Comm.RequestBotSkills then
        return MultiBot.Comm.RequestBotSkills(botName)
    end

    return false
end

function MultiBot.OnBridgeBotSkills(botName, skills)
    ensureCharacterFrame():setSkills(botName, skills or {})
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

function MultiBot.InitializeCharacterInfoFrame()
    ensureCharacterFrame()
    ensureRecipeFrame()
end