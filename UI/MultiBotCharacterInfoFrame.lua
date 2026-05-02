if not MultiBot then
    return
end

local CATEGORY_ORDER = { "class", "profession", "secondary", "weapon", "armor" }
local CATEGORY_TITLES = {
    class = "Compétences de classe",
    profession = "Métiers",
    secondary = "Compétences secondaires",
    weapon = "Compétences d'arme",
    armor = "Armures",
}

local DIFFICULTY_COLORS = {
    orange = "|cffff8040",
    yellow = "|cffffff00",
    green = "|cff80be80",
    gray = "|cff808080",
}

local function L(key, fallback)
    if MultiBot.L then
        return MultiBot.L(key, fallback)
    end

    return fallback or key
end

local function setBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
end

local function createCloseButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
    return button
end

local function createTabButton(parent, text, x)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -28)
    button:SetWidth(112)
    button:SetHeight(20)
    button:SetText(text)
    return button
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

    local frame = CreateFrame("Frame", "MultiBotProfessionRecipeFrame", UIParent)
    frame:SetWidth(430)
    frame:SetHeight(450)
    frame:SetPoint("CENTER", UIParent, "CENTER", 130, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    setBackdrop(frame)

    frame.title = createText(frame, "GameFontNormalLarge", "TOPLEFT", 16, -14)
    createCloseButton(frame)

    frame.status = createText(frame, "GameFontHighlightSmall", "TOPLEFT", 18, -42)
    frame.rows = {}
    frame.page = 1
    frame.pageSize = 14
    frame.recipes = {}

    for i = 1, frame.pageSize do
        local row = CreateFrame("Button", nil, frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -62 - ((i - 1) * 25))
        row:SetWidth(392)
        row:SetHeight(22)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon:SetWidth(20)
        row.icon:SetHeight(20)
        row.text = createText(row, "GameFontHighlightSmall", "LEFT", 26, 0)
        row.text:SetWidth(360)
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

    frame.prev = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.prev:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 14)
    frame.prev:SetWidth(48)
    frame.prev:SetHeight(20)
    frame.prev:SetText("<")

    frame.pageText = createText(frame, "GameFontNormalSmall", "BOTTOM", 0, 18)

    frame.next = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.next:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14)
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
        self.title:SetText((skill and skill.name or L("profession.recipes", "Recettes")) .. " - " .. (botName or ""))
        self.status:SetText(#self.recipes .. " " .. L("profession.recipes.count", "recette(s) connue(s)"))
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

    local frame = CreateFrame("Frame", "MultiBotCharacterInfoFrame", UIParent)
    frame:SetWidth(390)
    frame:SetHeight(450)
    frame:SetPoint("CENTER", UIParent, "CENTER", -130, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    setBackdrop(frame)

    frame.title = createText(frame, "GameFontNormalLarge", "TOPLEFT", 16, -14)
    createCloseButton(frame)

    frame.skillsTab = createTabButton(frame, L("character.skills", "Compétences"), 16)
    setButtonEnabled(frame.skillsTab, false)

    frame.status = createText(frame, "GameFontHighlightSmall", "TOPLEFT", 18, -56)
    frame.rows = {}
    frame.skills = {}

    for i = 1, 18 do
        local row = CreateFrame("Button", nil, frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -80 - ((i - 1) * 19))
        row:SetWidth(350)
        row:SetHeight(18)
        row.text = createText(row, "GameFontHighlightSmall", "LEFT", 0, 0)
        row.text:SetWidth(340)
        row:SetScript("OnClick", function(self)
            if not self.skill then return end
            if self.skill.category ~= "profession" and self.skill.category ~= "secondary" then return end
            if MultiBot.Comm and MultiBot.Comm.RequestProfessionRecipes then
                ensureRecipeFrame()
                MultiBot.professionRecipeFrame.title:SetText(self.skill.name .. " - " .. (frame.botName or ""))
                MultiBot.professionRecipeFrame.status:SetText(L("profession.recipes.loading", "Chargement..."))
                MultiBot.professionRecipeFrame.recipes = {}
                MultiBot.professionRecipeFrame:render()
                MultiBot.professionRecipeFrame:Show()
                MultiBot.Comm.RequestProfessionRecipes(frame.botName, self.skill.skillId)
            end
        end)
        frame.rows[i] = row
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
                table.insert(ordered, { header = CATEGORY_TITLES[category] or category })
                table.sort(categoryItems, function(a, b) return tostring(a.name or "") < tostring(b.name or "") end)
                for _, skill in ipairs(categoryItems) do
                    table.insert(ordered, { skill = skill })
                end
            end
        end

        self.status:SetText(#(self.skills or {}) .. " " .. L("character.skills.count", "compétence(s)"))
        for i = 1, #self.rows do
            local row = self.rows[i]
            local item = ordered[i]
            row.skill = item and item.skill or nil
            if not item then
                row:Hide()
            elseif item.header then
                row.text:SetText("|cffffcc00" .. item.header .. "|r")
                row:Show()
            else
                local skill = item.skill
                local clickable = (skill.category == "profession" or skill.category == "secondary") and "|cff80d0ff" or "|cffffffff"
                row.text:SetText(clickable .. (skill.name or skill.key or ("Skill " .. tostring(skill.skillId))) .. "|r |cff999999" .. getSkillBarText(skill) .. "|r")
                row:Show()
            end
        end
    end

    frame.setSkills = function(self, botName, skills)
        self.botName = botName
        self.skills = skills or {}
        self.title:SetText(L("character.info", "Infos personnage") .. " - " .. (botName or ""))
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
    frame.title:SetText(L("character.info", "Infos personnage") .. " - " .. botName)
    frame.skills = {}
    frame:renderSkills()
    frame.status:SetText(L("character.skills.loading", "Chargement..."))
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