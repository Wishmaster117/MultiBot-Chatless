-- MultiBotLootMasterUI.lua

local AceLocale = LibStub and LibStub("AceLocale-3.0", true)
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local L = AceLocale and AceLocale:GetLocale("MultiBot", true)

if not L then
    L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
end

local LootMasterUI = {}
local assignedLootKeys = {}
local recentLootByCandidate = {}
local lootHistory = {}

local FRAME_WIDTH = 480
local FRAME_HEIGHT = 460
local ITEM_ROW_HEIGHT = 64
local DROPDOWN_WIDTH = 220
local MAX_MASTER_LOOT_CANDIDATES = 40
local RECENT_LOOT_PENALTY_SECONDS = 120
local LOOT_HISTORY_LINE_HEIGHT = 14
local LOOT_HISTORY_HEIGHT = 96
local LOOT_PREFERENCE_BONUS = 18
local LOOT_PROFESSION_BONUS = 55
local LOOT_PROFESSION_MISMATCH_PENALTY = 35
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local AssignLoot
local QueueRefresh
local CloseAllDropdowns
local GetBridgeDetail
local GetSavedBotSpec
local GetSpecFromBridgeDetail
local GuessSpecFromBuild
local GetClassColorCode

local function AddDarkBackdrop(frame, bgAlpha)
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

local function MBLocal(key, fallback)
    local value = L[key]
    if value == key then
        return fallback
    end

    return value or fallback
end

local function AddSystemMessage(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99MultiBot|r: " .. tostring(message))
    end
end

local function IsLootMasterUIEnabled()
    if MultiBot and type(MultiBot.GetLootMasterUIEnabled) == "function" then
        return MultiBot.GetLootMasterUIEnabled()
    end

    return true
end

local function OpenCandidateInventory(candidate)
    local botName = candidate and candidate.name

    if not botName or botName == "" then
        return
    end

    if MultiBot then
        if type(MultiBot.RequestBotInventory) == "function" then
            MultiBot.RequestBotInventory(botName)
            return
        end

        if type(MultiBot.InitializeInventoryFrame) == "function" then
            local inventory = MultiBot.InitializeInventoryFrame()
            if inventory and type(inventory.requestBotInventory) == "function" then
                inventory:requestBotInventory(botName)
                return
            end
        end
    end

    AddSystemMessage(MBLocal("lootmaster.inventory_unavailable", "Inventory frame is not available."))
end

local function RunLater(delay, callback)
    if MultiBot and type(MultiBot.TimerAfter) == "function" then
        MultiBot.TimerAfter(delay, callback)
        return
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay, callback)
        return
    end

    callback()
end

local pendingLootCloseToken = 0

local function CancelQueuedLootClose()
    pendingLootCloseToken = pendingLootCloseToken + 1
end

local function IsNativeLootFrameStillOpen()
    if _G.LootFrame and _G.LootFrame:IsShown() then
        return true
    end

    return GetNumLootItems and (GetNumLootItems() or 0) > 0
end

local function QueueLootClose()
    CancelQueuedLootClose()
    local token = pendingLootCloseToken

    RunLater(0.20, function()
        if token ~= pendingLootCloseToken then
            return
        end

        if IsNativeLootFrameStillOpen() then
            if LootMasterUI.frame and LootMasterUI.frame:IsShown() and QueueRefresh then
                QueueRefresh(0.05)
            end
            return
        end

        LootMasterUI:Close()
    end)
end

local function ShortName(name)
    if type(name) ~= "string" then
        return ""
    end

    if Ambiguate then
        name = Ambiguate(name, "none") or name
    end

    return (name:match("^[^-]+") or name)
end

local function NormalizeName(name)
    return string.lower(ShortName(name) or "")
end

local function FindGroupUnitByName(name)
    local wanted = NormalizeName(name)

    if wanted == "" then
        return nil
    end

    if NormalizeName(UnitName("player")) == wanted then
        return "player"
    end

    local raidCount = GetNumRaidMembers and (GetNumRaidMembers() or 0) or 0
    for index = 1, raidCount do
        local unit = "raid" .. index
        if NormalizeName(UnitName(unit)) == wanted then
            return unit
        end
    end

    local partyCount = GetNumPartyMembers and (GetNumPartyMembers() or 0) or 0
    for index = 1, partyCount do
        local unit = "party" .. index
        if NormalizeName(UnitName(unit)) == wanted then
            return unit
        end
    end

    return nil
end

local function GetCandidateClassInfo(name)
    local unit = FindGroupUnitByName(name)
    if not unit then
        return nil, nil
    end

    local localizedClass, classToken = UnitClass(unit)
    return localizedClass, classToken
end

local SPEC_TREE_NAMES = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    HUNTER = { "Beast Mastery", "Marksmanship", "Survival" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    MAGE = { "Arcane", "Fire", "Frost" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
    DRUID = { "Balance", "Feral", "Restoration" },
}

local function GetKnownBuildForCandidate(name)
    local spec = MultiBot and MultiBot.spec
    local builds = spec and spec.currentBuild

    if type(builds) ~= "table" then
        return nil
    end

    local shortName = ShortName(name)
    local normalized = NormalizeName(name)

    return builds[normalized]
        or builds[string.lower(shortName or "")]
        or builds[shortName]
        or builds[name]
end

GuessSpecFromBuild = function(classToken, build)
    if type(build) ~= "string" then
        return nil
    end

    local a, b, c = build:match("^(%d+)%-(%d+)%-(%d+)$")
    a, b, c = tonumber(a), tonumber(b), tonumber(c)

    if not a or not b or not c then
        return nil
    end

    local treeIndex = 1
    local best = a

    if b > best then
        treeIndex = 2
        best = b
    end

    if c > best then
        treeIndex = 3
    end

    local treeNames = SPEC_TREE_NAMES[classToken or ""]
    return treeNames and treeNames[treeIndex] or nil
end

local function GetCandidateSpecLabel(candidate)
    if not candidate then return MBLocal("lootmaster.unknown_spec", "Unknown spec") end

    local spec, build = GetSpecFromBridgeDetail(candidate)
    if not spec then
        spec, build = GetSavedBotSpec(candidate.name)
    end
    if not spec then
        spec = GuessSpecFromBuild(candidate.classFile or candidate.classToken, candidate.build or build)
    end

    return spec or MBLocal("lootmaster.unknown_spec", "Unknown spec")
end

local function Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function TextHasAny(text, patterns)
    if type(text) ~= "string" then return false end
    text = string.lower(text)

    for _, pattern in ipairs(patterns) do
        if string.find(text, pattern) then
            return true
        end
    end

    return false
end

local PROFESSION_DISPLAY_KEYS = {
    alchemy = { key = "lootmaster.profession.alchemy", fallback = "Alchemy" },
    blacksmithing = { key = "lootmaster.profession.blacksmithing", fallback = "Blacksmithing" },
    enchanting = { key = "lootmaster.profession.enchanting", fallback = "Enchanting" },
    engineering = { key = "lootmaster.profession.engineering", fallback = "Engineering" },
    herbalism = { key = "lootmaster.profession.herbalism", fallback = "Herbalism" },
    inscription = { key = "lootmaster.profession.inscription", fallback = "Inscription" },
    jewelcrafting = { key = "lootmaster.profession.jewelcrafting", fallback = "Jewelcrafting" },
    leatherworking = { key = "lootmaster.profession.leatherworking", fallback = "Leatherworking" },
    mining = { key = "lootmaster.profession.mining", fallback = "Mining" },
    skinning = { key = "lootmaster.profession.skinning", fallback = "Skinning" },
    tailoring = { key = "lootmaster.profession.tailoring", fallback = "Tailoring" },
    cooking = { key = "lootmaster.profession.cooking", fallback = "Cooking" },
    firstaid = { key = "lootmaster.profession.firstaid", fallback = "First Aid" },
    fishing = { key = "lootmaster.profession.fishing", fallback = "Fishing" },
}

local PROFESSION_SPELL_IDS = {
    alchemy = 2259,
    blacksmithing = 2018,
    enchanting = 7411,
    engineering = 4036,
    herbalism = 2366,
    inscription = 45357,
    jewelcrafting = 25229,
    leatherworking = 2108,
    mining = 2575,
    skinning = 8613,
    tailoring = 3908,
    cooking = 2550,
    firstaid = 3273,
    fishing = 7620,
}

local PROFESSION_MATCH_PATTERNS = {
    alchemy = { "alchemy", "alchimie" },
    blacksmithing = { "blacksmithing", "blacksmith", "forge" },
    enchanting = { "enchanting", "enchantement", "enchant" },
    engineering = { "engineering", "engineer", "ingenier", "ing.nier" },
    inscription = { "inscription", "calligraphie", "scribe" },
    jewelcrafting = { "jewelcrafting", "jewelcraft", "joaillerie" },
    leatherworking = { "leatherworking", "leatherwork", "travail du cuir" },
    tailoring = { "tailoring", "couture" },
    cooking = { "cooking", "cuisine" },
    firstaid = { "first aid", "firstaid", "secourisme", "premiers soins" },
    fishing = { "fishing", "peche", "p.che" },
}

local function GetProfessionKeyFromText(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    text = string.lower(text)
    for profession, patterns in pairs(PROFESSION_MATCH_PATTERNS) do
        if TextHasAny(text, patterns) then
            return profession
        end
    end

    return nil
end

local function GetProfessionDisplayName(profession)
    local spellId = PROFESSION_SPELL_IDS[profession or ""]
    if spellId and GetSpellInfo then
        local spellName = GetSpellInfo(spellId)
        if spellName and spellName ~= "" then
            return spellName
        end
    end

    local entry = PROFESSION_DISPLAY_KEYS[profession or ""]
    if entry then
        return MBLocal(entry.key, entry.fallback)
    end

    return profession
end

local function GetRequiredProfessionForLoot(itemName, itemType, itemSubType, tooltipText)
    local text = table.concat({
        itemName or "",
        itemType or "",
        itemSubType or "",
        tooltipText or "",
    }, " ")

    if not TextHasAny(text, {
        "recipe", "recette", "pattern", "patron", "design", "dessin",
        "formula", "formule", "plans", "plan", "schematic", "sch.ma",
        "manual", "manuel", "technique",
    }) then
        return nil
    end

    return GetProfessionKeyFromText(text)
end

local function AddProfessionKeysFromValue(professions, value)
    if type(value) == "string" then
        local key = GetProfessionKeyFromText(value)
        if key then
            professions[key] = true
        end
        return
    end

    if type(value) ~= "table" then
        return
    end

    for key, entry in pairs(value) do
        if entry == true then
            AddProfessionKeysFromValue(professions, tostring(key))
        else
            AddProfessionKeysFromValue(professions, entry)
            AddProfessionKeysFromValue(professions, tostring(key))
        end
    end
end

local function GetCandidateProfessionKeys(candidate)
    local professions = {}
    local detail = candidate and GetBridgeDetail(candidate.name)

    if type(detail) == "table" then
        AddProfessionKeysFromValue(professions, detail.professions)
        AddProfessionKeysFromValue(professions, detail.profession)
        AddProfessionKeysFromValue(professions, detail.profession1)
        AddProfessionKeysFromValue(professions, detail.profession2)
        AddProfessionKeysFromValue(professions, detail.primaryProfession)
        AddProfessionKeysFromValue(professions, detail.secondaryProfession)
    end

    local cache = _G.MultiBotLootMasterProfessionCache
    if type(cache) == "table" and candidate and candidate.name then
        AddProfessionKeysFromValue(professions, cache[NormalizeName(candidate.name)])
        AddProfessionKeysFromValue(professions, cache[ShortName(candidate.name)])
        AddProfessionKeysFromValue(professions, cache[candidate.name])
    end

    return professions
end

local function CandidateHasProfession(candidate, profession)
    if not profession then
        return nil
    end

    local professions = GetCandidateProfessionKeys(candidate)
    local hasKnownProfession = false

    for key in pairs(professions) do
        hasKnownProfession = true
        if key == profession then
            return true
        end
    end

    if hasKnownProfession then
        return false
    end

    return nil
end

local ARMOR_RANK = { CLOTH = 1, LEATHER = 2, MAIL = 3, PLATE = 4 }
local CLASS_ARMOR_RANK = {
    WARRIOR = 4, PALADIN = 4, DEATHKNIGHT = 4,
    HUNTER = 3, SHAMAN = 3,
    ROGUE = 2, DRUID = 2,
    PRIEST = 1, MAGE = 1, WARLOCK = 1,
}

local CLASS_WEAPONS = {
    WARRIOR = { AXE_1H = true, AXE_2H = true, MACE_1H = true, MACE_2H = true, SWORD_1H = true, SWORD_2H = true, DAGGER = true, FIST = true, POLEARM = true, SHIELD = true, BOW = true, CROSSBOW = true, GUN = true, THROWN = true },
    PALADIN = { AXE_1H = true, AXE_2H = true, MACE_1H = true, MACE_2H = true, SWORD_1H = true, SWORD_2H = true, POLEARM = true, SHIELD = true },
    HUNTER = { AXE_1H = true, AXE_2H = true, SWORD_1H = true, SWORD_2H = true, DAGGER = true, FIST = true, POLEARM = true, STAFF = true, BOW = true, CROSSBOW = true, GUN = true, THROWN = true },
    ROGUE = { AXE_1H = true, MACE_1H = true, SWORD_1H = true, DAGGER = true, FIST = true, BOW = true, CROSSBOW = true, GUN = true, THROWN = true },
    PRIEST = { MACE_1H = true, DAGGER = true, STAFF = true, WAND = true, HOLDABLE = true },
    DEATHKNIGHT = { AXE_1H = true, AXE_2H = true, MACE_1H = true, MACE_2H = true, SWORD_1H = true, SWORD_2H = true, POLEARM = true },
    SHAMAN = { AXE_1H = true, MACE_1H = true, DAGGER = true, FIST = true, STAFF = true, SHIELD = true, HOLDABLE = true },
    MAGE = { DAGGER = true, SWORD_1H = true, STAFF = true, WAND = true, HOLDABLE = true },
    WARLOCK = { DAGGER = true, SWORD_1H = true, STAFF = true, WAND = true, HOLDABLE = true },
    DRUID = { MACE_1H = true, MACE_2H = true, DAGGER = true, FIST = true, STAFF = true, POLEARM = true, HOLDABLE = true },
}

local function GetCandidateTreeIndex(candidate)
    local detail = candidate and GetBridgeDetail(candidate.name)
    if type(detail) == "table" then
        local a, b, c = tonumber(detail.talent1 or 0) or 0, tonumber(detail.talent2 or 0) or 0, tonumber(detail.talent3 or 0) or 0
        if c > a and c > b then return 3 end
        if b > a and b > c then return 2 end
        return 1
    end

    local build = candidate and candidate.build
    if not build then
        local _, savedBuild = GetSavedBotSpec(candidate and candidate.name)
        build = savedBuild
    end

    local a, b, c = tostring(build or ""):match("^(%d+)[%/%-](%d+)[%/%-](%d+)$")
    a, b, c = tonumber(a), tonumber(b), tonumber(c)
    if not a or not b or not c then return nil end
    if c > a and c > b then return 3 end
    if b > a and b > c then return 2 end
    return 1
end

local function GetCandidateSpecRoleHint(candidate)
    local parts = {}
    local spec = GetSpecFromBridgeDetail(candidate)
    local savedSpec = GetSavedBotSpec(candidate and candidate.name)

    if spec and spec ~= "" then parts[#parts + 1] = spec end
    if savedSpec and savedSpec ~= "" then parts[#parts + 1] = savedSpec end

    local label = table.concat(parts, " "):lower()
    if label == "" then return nil end

    if label:find("bear") or label:find("ours") or label:find("tank") then
        return "bear"
    end

    if label:find("cat") or label:find("chat") or label:find("dps") or label:find("feral") or label:find("farouche") then
        return "feral"
    end

    return nil
end

local function GetCandidateRole(candidate)
    local classFile = candidate and (candidate.classFile or candidate.classToken)
    local tree = GetCandidateTreeIndex(candidate)

    if classFile == "WARRIOR" then return tree == 3 and "tank" or "physical" end
    if classFile == "PALADIN" then return tree == 1 and "healer" or (tree == 2 and "tank" or "physical") end
    if classFile == "PRIEST" then return tree == 3 and "caster" or "healer" end
    if classFile == "DEATHKNIGHT" then return tree == 1 and "tank" or "physical" end
    if classFile == "SHAMAN" then
        if tree == 1 then return "caster" end
        if tree == 2 then return "physical" end
        if tree == 3 then return "healer" end
        return "unknown"
    end
    if classFile == "DRUID" then
        if tree == 1 then return "caster" end
        if tree == 2 then return GetCandidateSpecRoleHint(candidate) or "feral" end
        return "healer"
    end
    if classFile == "MAGE" or classFile == "WARLOCK" then return "caster" end
    if classFile == "HUNTER" or classFile == "ROGUE" then return "physical" end

    return "unknown"
end

local function GetArmorType(itemSubType, equipLoc)
    if equipLoc == "INVTYPE_SHIELD" then return "SHIELD" end
    if TextHasAny(itemSubType, { "cloth", "tissu" }) then return "CLOTH" end
    if TextHasAny(itemSubType, { "leather", "cuir" }) then return "LEATHER" end
    if TextHasAny(itemSubType, { "mail", "maille" }) then return "MAIL" end
    if TextHasAny(itemSubType, { "plate", "plaque" }) then return "PLATE" end
    return nil
end

local function GetWeaponType(itemSubType, equipLoc)
    local twoHand = equipLoc == "INVTYPE_2HWEAPON"
    if equipLoc == "INVTYPE_SHIELD" then return "SHIELD" end
    if equipLoc == "INVTYPE_HOLDABLE" then return "HOLDABLE" end
    if equipLoc ~= "INVTYPE_WEAPON" and equipLoc ~= "INVTYPE_2HWEAPON" and equipLoc ~= "INVTYPE_WEAPONMAINHAND" and equipLoc ~= "INVTYPE_WEAPONOFFHAND" and equipLoc ~= "INVTYPE_RANGED" and equipLoc ~= "INVTYPE_RANGEDRIGHT" and equipLoc ~= "INVTYPE_THROWN" then return nil end

    if TextHasAny(itemSubType, { "crossbow", "arbal" }) then return "CROSSBOW" end
    if TextHasAny(itemSubType, { "bow", "arc" }) then return "BOW" end
    if TextHasAny(itemSubType, { "gun", "fusil" }) then return "GUN" end
    if TextHasAny(itemSubType, { "wand", "baguette" }) then return "WAND" end
    if TextHasAny(itemSubType, { "thrown", "jet" }) then return "THROWN" end
    if TextHasAny(itemSubType, { "dagger", "dague" }) then return "DAGGER" end
    if TextHasAny(itemSubType, { "fist", "pugilat" }) then return "FIST" end
    if TextHasAny(itemSubType, { "polearm", "hast" }) then return "POLEARM" end
    if TextHasAny(itemSubType, { "staff", "b.ton" }) then return "STAFF" end
    if TextHasAny(itemSubType, { "axe", "hache" }) then return twoHand and "AXE_2H" or "AXE_1H" end
    if TextHasAny(itemSubType, { "mace", "masse" }) then return twoHand and "MACE_2H" or "MACE_1H" end
    if TextHasAny(itemSubType, { "sword", "epee", "p..e" }) then return twoHand and "SWORD_2H" or "SWORD_1H" end

    return nil
end

local lootScanTooltip
local function GetLootTooltipText(itemLink)
    if not itemLink then return "" end
    if not lootScanTooltip then
        lootScanTooltip = CreateFrame("GameTooltip", "MultiBotLootMasterScanTooltip", nil, "GameTooltipTemplate")
    end

    lootScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    lootScanTooltip:ClearLines()
    lootScanTooltip:SetHyperlink(itemLink)

    local lines = {}
    for i = 2, lootScanTooltip:NumLines() do
        local left = _G["MultiBotLootMasterScanTooltipTextLeft" .. i]
        local text = left and left:GetText()
        if text and text ~= "" then
            lines[#lines + 1] = text
        end
    end

    lootScanTooltip:Hide()
    return table.concat(lines, " ")
end

local function GetItemStatFlags(itemLink, tooltipText)
    local text = tooltipText or GetLootTooltipText(itemLink)
    local hasDefense = TextHasAny(text, { "defense", "d.fense" })
    local hasDodge = TextHasAny(text, { "dodge", "esquive" })
    local hasParry = TextHasAny(text, { "parry", "parade" })
    local hasBlock = TextHasAny(text, { "block", "blocage" })
    local hasStamina = TextHasAny(text, { "stamina", "endurance" })
    local hasAgility = TextHasAny(text, { "agility", "agilit" })
    local hasStrength = TextHasAny(text, { "strength", "force" })
    local hasAttackPower = TextHasAny(text, { "attack power", "puissance d.attaque" })
    local hasExpertise = TextHasAny(text, { "expertise" })
    local hasArmorPen = TextHasAny(text, { "armor penetration", "p.n.tration d.armure" })
    local hasSpellPower = TextHasAny(text, { "spell power", "puissance des sorts", "spell damage", "d.g.ts des sorts" })
    local hasHealing = TextHasAny(text, { "healing", "soins" })
    local hasMp5 = TextHasAny(text, { "mana per", "mp5", "mana toutes les" })
    local hasSpirit = TextHasAny(text, { "spirit", "esprit" })
    local hasIntellect = TextHasAny(text, { "intellect", "intelligence" })
    local hasHit = TextHasAny(text, { "hit rating", "score de toucher" })
    local hasCrit = TextHasAny(text, { "critical strike", "coup critique", "critique" })
    local hasHaste = TextHasAny(text, { "haste", "h.te" })

    local hasPhysicalPower = hasAgility or hasStrength or hasAttackPower or hasExpertise or hasArmorPen
    local hasTankPrimary = hasDefense or hasDodge or hasParry or hasBlock
    local hasHealerHint = hasHealing or hasMp5 or hasSpirit
    local primary

    if hasTankPrimary then
        primary = "tank"
    elseif hasPhysicalPower and not hasSpellPower and not hasHealing then
        primary = "physical"
    elseif hasSpellPower or hasHealing then
        if hasHit then
            primary = "caster"
        elseif hasHealerHint then
            primary = "healer"
        else
            primary = "caster"
        end
    elseif hasPhysicalPower then
        primary = "physical"
    elseif hasIntellect then
        primary = "caster"
    end

    return {
        primary = primary,
        tank = primary == "tank",
        healer = primary == "healer",
        caster = primary == "caster",
        physical = primary == "physical",
        defense = hasDefense,
        dodge = hasDodge,
        parry = hasParry,
        block = hasBlock,
        stamina = hasStamina,
        agility = hasAgility,
        strength = hasStrength,
        attackPower = hasAttackPower,
        expertise = hasExpertise,
        armorPen = hasArmorPen,
        spellPower = hasSpellPower,
        healing = hasHealing,
        mp5 = hasMp5,
        spirit = hasSpirit,
        intellect = hasIntellect,
        hit = hasHit,
        crit = hasCrit,
        haste = hasHaste,
    }
end

local function BuildLootItemProfile(slot)
    local itemLink = GetLootSlotLink(slot)
    local _, itemName = GetLootSlotInfo(slot)
    local query = itemLink or itemName
    local _, _, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(query or "")
    local tooltipText = GetLootTooltipText(itemLink)

    return {
        link = itemLink,
        itemType = itemType,
        itemSubType = itemSubType,
        equipLoc = equipLoc,
        armorType = GetArmorType(itemSubType, equipLoc),
        weaponType = GetWeaponType(itemSubType, equipLoc),
        statFlags = GetItemStatFlags(itemLink, tooltipText),
        requiredProfession = GetRequiredProfessionForLoot(itemName, itemType, itemSubType, tooltipText),
    }
end

local function BuildLootPreferenceKey(profile)
    if type(profile) ~= "table" then
        return nil
    end

    local flags = profile.statFlags or {}
    return table.concat({
        flags.primary or "any",
        profile.requiredProfession or "noprofession",
        profile.armorType or "noarmor",
        profile.weaponType or "noweapon",
        profile.equipLoc or "noequip",
    }, "|")
end

local function GetLootPreferenceStore(createIfMissing)
    local store

    if MultiBot and MultiBot.Store then
        if createIfMissing and type(MultiBot.Store.EnsureUIChildStore) == "function" then
            store = MultiBot.Store.EnsureUIChildStore("lootMaster")
        elseif type(MultiBot.Store.GetUIChildStore) == "function" then
            store = MultiBot.Store.GetUIChildStore("lootMaster")
        end
    end

    if type(store) ~= "table" then
        if not createIfMissing then
            store = _G.MultiBotSave and _G.MultiBotSave.lootMaster
            if type(store) ~= "table" then
                return nil
            end
        else
            _G.MultiBotSave = _G.MultiBotSave or {}
            _G.MultiBotSave.lootMaster = _G.MultiBotSave.lootMaster or {}
            store = _G.MultiBotSave.lootMaster
        end
    end

    if createIfMissing then
        store.preferences = store.preferences or {}
    end

    return type(store.preferences) == "table" and store.preferences or nil
end

local function GetPreferredLootCandidate(profile)
    local key = BuildLootPreferenceKey(profile)
    local preferences = key and GetLootPreferenceStore(false)
    local value = preferences and preferences[key]

    if type(value) == "table" then
        return value.name
    end

    return value
end

local function SaveLootPreference(slot, candidate)
    if not slot or not candidate or not candidate.name then
        return
    end

    local profile = BuildLootItemProfile(slot)
    local key = BuildLootPreferenceKey(profile)
    local preferences = key and GetLootPreferenceStore(true)

    if not preferences then
        return
    end

    preferences[key] = {
        name = candidate.name,
        savedAt = time and time() or 0,
    }

    AddSystemMessage(string.format(MBLocal("lootmaster.preference_saved", "Preference saved: similar items -> %s."), candidate.name))
end

local function ClearLootPreference(slot)
    if not slot then
        return false
    end

    local profile = BuildLootItemProfile(slot)
    local key = BuildLootPreferenceKey(profile)
    local preferences = key and GetLootPreferenceStore(false)

    if not preferences or not preferences[key] then
        AddSystemMessage(MBLocal("lootmaster.preference_missing", "No preference saved for this item type."))
        return false
    end

    preferences[key] = nil
    AddSystemMessage(MBLocal("lootmaster.preference_cleared", "Preference cleared for similar items."))
    return true
end

local function RoleMatchesStats(role, flags)
    if not flags then return false end
    if flags.primary then
        if role == "feral" then return flags.primary == "physical" end
        if role == "bear" then return flags.primary == "tank" end

        return role == flags.primary
    end

    return role and flags[role] == true
end

local function GetRoleStatScore(role, flags)
    if not flags or not flags.primary then return 0 end
    if RoleMatchesStats(role, flags) then return 42 end
    if flags.primary == "physical" and (role == "healer" or role == "caster") then return -45 end
    if flags.primary == "physical" and role == "bear" then return -45 end
    if flags.primary == "caster" and (role == "physical" or role == "tank" or role == "feral" or role == "bear") then return -45 end
    if flags.primary == "healer" and role ~= "healer" then return -45 end
    if flags.primary == "tank" and role ~= "tank" and role ~= "bear" then return -35 end
    return -25
end

local STAT_SCORE_KEYS = {
    "defense", "dodge", "parry", "block", "stamina",
    "agility", "strength", "attackPower", "expertise", "armorPen",
    "spellPower", "healing", "mp5", "spirit", "intellect",
    "hit", "crit", "haste",
}

local ROLE_STAT_WEIGHTS = {
    physical = {
        agility = 10, strength = 10, attackPower = 12, expertise = 10, armorPen = 10,
        hit = 8, crit = 8, haste = 5, stamina = 1,
        spellPower = -25, healing = -30, mp5 = -15, spirit = -15, intellect = -4,
        defense = -18, dodge = -12, parry = -12, block = -12,
    },
    caster = {
        spellPower = 16, intellect = 8, hit = 10, crit = 8, haste = 8, spirit = 4,
        mp5 = -6, healing = -4,
        agility = -22, strength = -28, attackPower = -28, expertise = -35, armorPen = -28,
        defense = -20, dodge = -15, parry = -15, block = -15,
    },
    healer = {
        healing = 18, spellPower = 12, intellect = 10, mp5 = 12, spirit = 10, crit = 6, haste = 8,
        hit = -20,
        agility = -22, strength = -28, attackPower = -28, expertise = -35, armorPen = -28,
        defense = -12, dodge = -8, parry = -8, block = -8,
    },
    tank = {
        defense = 18, dodge = 14, parry = 14, block = 12, stamina = 10,
        strength = 6, expertise = 8, hit = 6, agility = 3,
        spellPower = -25, healing = -25, mp5 = -10, spirit = -10, armorPen = -5,
    },
    feral = {
        agility = 16, attackPower = 12, armorPen = 12, expertise = 10,
        hit = 9, crit = 10, haste = 4, stamina = 2, strength = 4,
        defense = -25, dodge = -10, parry = -30, block = -30,
        spellPower = -25, healing = -25, mp5 = -10, spirit = -8,
    },
    bear = {
        stamina = 14, dodge = 16, defense = 12, agility = 10,
        expertise = 8, hit = 6, strength = 4, attackPower = 4,
        armorPen = 2, crit = 4,
        parry = -30, block = -30,
        spellPower = -25, healing = -25, mp5 = -10, spirit = -8,
    },
}

local CLASS_ROLE_STAT_WEIGHTS = {
    SHAMAN = {
        caster = {
            spellPower = 18, hit = 10, haste = 9, crit = 8, intellect = 8, mp5 = 2,
            agility = -25, strength = -25, attackPower = -30, expertise = -30,
            armorPen = -30, healing = -18, spirit = -8,
        },
        physical = {
            agility = 12, attackPower = 12, hit = 10, expertise = 10, crit = 9,
            haste = 8, intellect = 4, strength = 4, armorPen = 2,
            spellPower = -18, healing = -25, mp5 = -8, spirit = -12,
            defense = -25, dodge = -18, parry = -18, block = -18,
        },
        healer = {
            healing = 18, spellPower = 14, intellect = 12, haste = 10,
            crit = 8, mp5 = 8,
            hit = -20, agility = -25, strength = -25, attackPower = -30,
            expertise = -30, armorPen = -30, spirit = -8,
        },
    },

    DRUID = {
        caster = {
            spellPower = 16, intellect = 8, hit = 10, crit = 8, haste = 8, spirit = 6,
            agility = -25, strength = -25, attackPower = -30, expertise = -35, armorPen = -30,
        },
        healer = {
            healing = 18, spellPower = 12, intellect = 10, spirit = 12, haste = 8, crit = 6, mp5 = 6,
            hit = -20, agility = -25, strength = -25, attackPower = -30, expertise = -35, armorPen = -30,
        },
        feral = {
            agility = 16, attackPower = 12, armorPen = 12, expertise = 10, hit = 9, crit = 10,
            stamina = 2, defense = -25, dodge = -10, block = -30, parry = -30,
            spellPower = -25, healing = -25,
        },
        bear = {
            stamina = 14, dodge = 16, defense = 12, agility = 10, expertise = 8, hit = 6,
            attackPower = 4, armorPen = 2, crit = 4,
            block = -30, parry = -30, spellPower = -25, healing = -25,
        },
    },

    HUNTER = {
        physical = {
            agility = 16, attackPower = 14, armorPen = 16, hit = 12, crit = 10, haste = 4, intellect = 2,
            strength = -35, expertise = -45,
            spellPower = -35, healing = -35, mp5 = -20, spirit = -20,
        },
    },
    ROGUE = {
        physical = { agility = 16, attackPower = 12, expertise = 14, armorPen = 12, hit = 12, crit = 10, haste = 6, strength = -15 },
    },
    PALADIN = {
        physical = { strength = 16, expertise = 12, hit = 10, crit = 10, haste = 8, attackPower = 8, agility = -8, spellPower = -25 },
        healer = { healing = 18, spellPower = 14, intellect = 12, mp5 = 10, crit = 8, haste = 8, spirit = -8 },
        tank = { defense = 18, dodge = 12, parry = 12, block = 14, stamina = 10, strength = 8, expertise = 8, hit = 6 },
    },
    WARRIOR = {
        physical = { strength = 16, expertise = 14, armorPen = 12, hit = 10, crit = 10, haste = 6, agility = -5, spellPower = -35 },
        tank = { defense = 18, dodge = 12, parry = 12, block = 12, stamina = 10, strength = 8, expertise = 8, hit = 6 },
    },
    DEATHKNIGHT = {
        physical = { strength = 16, expertise = 14, armorPen = 10, hit = 10, crit = 10, haste = 6, agility = -8, spellPower = -35 },
        tank = { defense = 18, dodge = 12, parry = 12, stamina = 10, strength = 8, expertise = 8, hit = 6, block = -20 },
    },
}

local CLASS_ROLE_STAT_RULES = {
    SHAMAN = {
        caster = {
            requiredAny = { "spellPower", "hit", "crit", "haste", "intellect" },
            badPrimary = {
                agility = true, strength = true, attackPower = true,
                expertise = true, armorPen = true, healing = true,
            },
            badPrimaryCap = 49,
        },
        physical = {
            requiredAny = { "agility", "attackPower", "expertise", "hit", "crit", "haste" },
            badPrimary = {
                spellPower = true, healing = true, mp5 = true, spirit = true,
                defense = true, dodge = true, parry = true, block = true,
            },
            badPrimaryCap = 49,
        },
        healer = {
            requiredAny = { "healing", "spellPower", "intellect", "haste", "crit", "mp5" },
            badPrimary = {
                hit = true, agility = true, strength = true, attackPower = true,
                expertise = true, armorPen = true,
            },
            badPrimaryCap = 49,
        },
    },

    DRUID = {
        feral = {
            requiredAny = { "agility", "attackPower", "armorPen", "expertise", "hit", "crit" },
            badPrimary = {
                defense = true, dodge = true, parry = true, block = true,
                spellPower = true, healing = true, intellect = true, spirit = true, mp5 = true,
            },
            badPrimaryCap = 49,
        },
        bear = {
            requiredAny = { "stamina", "dodge", "defense", "agility" },
            badPrimary = {
                spellPower = true, healing = true, intellect = true, spirit = true, mp5 = true,
                block = true, parry = true,
            },
            badPrimaryCap = 49,
        },
    },

    HUNTER = {
        physical = {
            requiredAny = { "agility", "attackPower", "armorPen" },
            badPrimary = { strength = true, expertise = true },
            badPrimaryCap = 49,
        },
    },
    WARRIOR = {
        physical = {
            requiredAny = { "strength", "attackPower", "armorPen" },
            badPrimary = { spellPower = true, healing = true, intellect = true, spirit = true, mp5 = true },
            badPrimaryCap = 45,
        },
    },
    PALADIN = {
        physical = {
            requiredAny = { "strength", "attackPower" },
            badPrimary = { spellPower = true, healing = true, spirit = true, mp5 = true },
            badPrimaryCap = 45,
        },
        healer = {
            requiredAny = { "spellPower", "healing", "intellect", "mp5", "crit", "haste" },
            badPrimary = { strength = true, agility = true, attackPower = true, armorPen = true, expertise = true },
            badPrimaryCap = 45,
        },
    },
    DEATHKNIGHT = {
        physical = {
            requiredAny = { "strength", "attackPower", "armorPen" },
            badPrimary = { spellPower = true, healing = true, intellect = true, spirit = true, mp5 = true, block = true },
            badPrimaryCap = 45,
        },
    },
}

local function HasAnyStat(flags, statList)
    if type(flags) ~= "table" or type(statList) ~= "table" then return false end

    for _, statKey in ipairs(statList) do
        if flags[statKey] then
            return true
        end
    end

    return false
end

local function GetCandidateStatRule(candidate)
    local classFile = candidate and (candidate.classFile or candidate.classToken)
    local role = candidate and candidate.lootRole
    local classRules = classFile and CLASS_ROLE_STAT_RULES[classFile]
    return classRules and role and classRules[role] or nil
end

local function GetCandidateStatWeight(candidate, statKey)
    local classFile = candidate and (candidate.classFile or candidate.classToken)
    local role = candidate and candidate.lootRole
    local classWeights = classFile and CLASS_ROLE_STAT_WEIGHTS[classFile]
    local classRoleWeights = classWeights and role and classWeights[role]

    if classRoleWeights and classRoleWeights[statKey] ~= nil then
        return classRoleWeights[statKey]
    end

    local roleWeights = role and ROLE_STAT_WEIGHTS[role]
    return roleWeights and roleWeights[statKey] or 0
end

local function GetCandidateStatScore(candidate, flags)
    local score = 0
    if type(flags) ~= "table" then return 0 end

    for _, statKey in ipairs(STAT_SCORE_KEYS) do
        if flags[statKey] then
            score = score + GetCandidateStatWeight(candidate, statKey)
        end
    end

    return Clamp(score, -55, 35)
end

local function GetCandidateStatScoreCap(candidate, flags)
    local rule = GetCandidateStatRule(candidate)

    if not rule or type(flags) ~= "table" or type(rule.badPrimary) ~= "table" then
        return nil
    end

    local hasBadPrimary = false
    for statKey in pairs(rule.badPrimary) do
        if flags[statKey] then
            hasBadPrimary = true
            break
        end
    end

    if not hasBadPrimary then return nil end
    if HasAnyStat(flags, rule.requiredAny) then return nil end

    return rule.badPrimaryCap or 49
end

local function CandidateHadRecentLoot(candidate)
    local key = NormalizeName(candidate and candidate.name)
    return key and recentLootByCandidate[key] ~= nil
end

local function ScoreCandidateForItem(candidate, profile)
    local classFile = candidate.classFile or candidate.classToken
    local score = 45
    local flags = profile.statFlags
    local hasKnownStats = flags and (flags.primary or flags.tank or flags.healer or flags.caster or flags.physical)
    candidate.lootRole = GetCandidateRole(candidate)
    candidate.lootProfession = profile.requiredProfession
    candidate.lootProfessionMatch = nil

    if profile.requiredProfession then
        candidate.lootProfessionMatch = CandidateHasProfession(candidate, profile.requiredProfession)
        if candidate.lootProfessionMatch == true then
            score = score + LOOT_PROFESSION_BONUS
        elseif candidate.lootProfessionMatch == false then
            score = score - LOOT_PROFESSION_MISMATCH_PENALTY
        end
    end

    if profile.armorType == "SHIELD" then
        score = score + ((CLASS_WEAPONS[classFile] and CLASS_WEAPONS[classFile].SHIELD) and 18 or -35)
    elseif profile.armorType then
        local itemRank = ARMOR_RANK[profile.armorType]
        local classRank = CLASS_ARMOR_RANK[classFile]
        if itemRank and classRank and itemRank <= classRank then
            if itemRank == classRank then
                score = score + 18
            elseif flags and (flags.primary == "caster" or flags.primary == "healer") then
                score = score + 2
            else
                score = score - 18
            end
        else
            score = score - 35
        end
    end

    if profile.weaponType then
        score = score + ((CLASS_WEAPONS[classFile] and CLASS_WEAPONS[classFile][profile.weaponType]) and 18 or -35)
    end

    if hasKnownStats then
        score = score + GetRoleStatScore(candidate.lootRole, flags)
        score = score + GetCandidateStatScore(candidate, flags)
    end

    if CandidateHadRecentLoot(candidate) then
        score = score - 15
    end

    candidate.lootScoreCap = GetCandidateStatScoreCap(candidate, flags)
    candidate.lootScore = Clamp(score, 1, candidate.lootScoreCap or 99)
end

local function ApplyLootPreferenceScore(candidate, profile)
    local preferredName = GetPreferredLootCandidate(profile)

    candidate.lootPreference = false

    if preferredName and NormalizeName(candidate.name) == NormalizeName(preferredName) then
        candidate.lootPreference = true
        candidate.lootScore = Clamp((candidate.lootScore or 0) + LOOT_PREFERENCE_BONUS, 1, candidate.lootScoreCap or 99)
    end
end

local function GetCandidateScoreColor(score)
    if score >= 80 then return "|cff33ff66" end
    if score >= 60 then return "|cffffff66" end
    if score >= 35 then return "|cffff9933" end
    return "|cffff4444"
end

local function BuildCandidateSelectionText(candidate)
    if not candidate then return MBLocal("lootmaster.select_bot", "Select a bot") end
    local score = candidate.lootScore or 0
    local prefText = candidate.lootPreference and " |cffffcc00Pref|r" or ""
    return GetClassColorCode(candidate.classFile) .. candidate.name .. "|r " .. GetCandidateScoreColor(score) .. score .. "%|r" .. prefText
end

local function BuildCandidateDropdownText(candidate)
    local score = candidate.lootScore or 0
    local prefText = candidate.lootPreference and " |cffffcc00Pref|r" or ""
    local professionText = ""

    if candidate.lootProfession then
        local professionName = GetProfessionDisplayName(candidate.lootProfession)
        if candidate.lootProfessionMatch == true then
            professionText = " |cff66ccff" .. professionName .. "|r"
        elseif candidate.lootProfessionMatch == false then
            professionText = " |cff777777-" .. professionName .. "|r"
        else
            professionText = " |cffaaaaaa" .. professionName .. "?|r"
        end
    end

    return GetClassColorCode(candidate.classFile) .. candidate.name .. "|r  " .. GetCandidateSpecLabel(candidate) .. "  " .. GetCandidateScoreColor(score) .. score .. "%|r" .. prefText .. professionText
end

local function IsPlayerMasterLooter()
    local method, partyIndex, raidIndex = GetLootMethod()

    if method ~= "master" then
        return false
    end

    if partyIndex == 0 then
        return true
    end

    if raidIndex and raidIndex > 0 then
        return UnitIsUnit("raid" .. raidIndex, "player")
    end

    if partyIndex and partyIndex > 0 then
        return UnitIsUnit("party" .. partyIndex, "player")
    end

    return false
end

local function GetCandidateName(index)

    if not GetMasterLootCandidate then
        return nil
    end

    local candidate = GetMasterLootCandidate(index)

    if type(candidate) == "string" and candidate ~= "" then
        return candidate
    end

    return nil
end

local function NormalizeUnitName(name)
    if not name or name == "" then
        return nil
    end

    return string.match(name, "^([^%-]+)") or name
end

GetClassColorCode = function(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]

    if not color then
        return "|cffffffff"
    end

    return string.format("|cff%02x%02x%02x", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255)
end

local function GetLocalizedClassName(classFile)
    if not classFile then return nil end

    if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile] then
        return LOCALIZED_CLASS_NAMES_MALE[classFile]
    end

    if LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[classFile] then
        return LOCALIZED_CLASS_NAMES_FEMALE[classFile]
    end

    return classFile
end

local function GetLootMasterUnit()
    local method, partyIndex, raidIndex = GetLootMethod()

    if method ~= "master" then return nil end
    if raidIndex and raidIndex > 0 then return "raid" .. raidIndex end
    if partyIndex == 0 then return "player" end
    if partyIndex and partyIndex > 0 then return "party" .. partyIndex end

    return nil
end

local function BuildLootMasterTitle()
    local title = MBLocal("lootmaster.title", "MultiBot Loot Master")
    local unit = GetLootMasterUnit()

    if not unit then return title end

    local name = UnitName(unit)
    if not name or name == "" then return title end

    local _, classFile = UnitClass(unit)
    return title .. " - " .. GetClassColorCode(classFile) .. name .. "|r"
end

local function UpdateLootMasterTitle(frame)
    if not frame then return end

    local title = BuildLootMasterTitle()

    if frame.widget and type(frame.widget.SetTitle) == "function" then
        frame.widget:SetTitle(title)
    end

    if frame.title then
        frame.title:SetText(title)
    end
end

local function GetClassIconTexture(classFile)
    if not classFile or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classFile] then
        return nil
    end

    return CLASS_ICON_TEXTURE
end

local function GetClassIconCoords(classFile)
    if not classFile or not CLASS_ICON_TCOORDS then
        return nil
    end

    return CLASS_ICON_TCOORDS[classFile]
end


local function SetLootIconTooltip(button, itemLink)
    if not button then
        return
    end

    button.itemLink = itemLink
    button:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

GetBridgeDetail = function(name)
    if not name or name == "" then
        return nil
    end

    local shortName = NormalizeUnitName(name) or name

    if MultiBot and type(MultiBot.GetCachedBridgeDetail) == "function" then
        local detail = MultiBot.GetCachedBridgeDetail(shortName) or MultiBot.GetCachedBridgeDetail(name)
        if type(detail) == "table" then
            return detail
        end
    end

    local details = MultiBot and MultiBot.bridge and MultiBot.bridge.details
    if type(details) == "table" then
        return details[string.lower(shortName)] or details[string.lower(name)] or details[shortName] or details[name]
    end

    return nil
end

GetSavedBotSpec = function(name)
    if not name or not _G.MultiBotGlobalSave then
        return nil
    end

    local shortName = NormalizeUnitName(name) or name
    local value = _G.MultiBotGlobalSave[shortName] or _G.MultiBotGlobalSave[name]
    if type(value) ~= "string" then
        return nil
    end

    local fields = {}
    for field in string.gmatch(value, "([^,]+)") do
        fields[#fields + 1] = field
    end

    return fields[3], fields[4]
end

GetSpecFromBridgeDetail = function(candidate)
    local detail = candidate and GetBridgeDetail(candidate.name)
    if type(detail) ~= "table" then
        return nil
    end

    local talent1 = tonumber(detail.talent1 or 0) or 0
    local talent2 = tonumber(detail.talent2 or 0) or 0
    local talent3 = tonumber(detail.talent3 or 0) or 0
    local tabIndex = 1

    if talent3 > talent2 and talent3 > talent1 then
        tabIndex = 3
    elseif talent2 > talent3 and talent2 > talent1 then
        tabIndex = 2
    end

    local classCanon = candidate.classFile
    if MultiBot and type(MultiBot.toClass) == "function" then
        classCanon = MultiBot.toClass(detail.className or detail.class or candidate.classFile or "") or classCanon
    end

    if MultiBot and type(MultiBot.L) == "function" and classCanon and classCanon ~= "" then
        local localized = MultiBot.L("info.talent." .. classCanon .. tabIndex)
        if localized and localized ~= "" then
            return (MultiBot.CLEAR and MultiBot.CLEAR(localized, 1)) or localized, talent1 .. "/" .. talent2 .. "/" .. talent3
        end
    end

    return nil, talent1 .. "/" .. talent2 .. "/" .. talent3
end

local function GetCandidateSpecText(candidate)
    local spec, build = GetSpecFromBridgeDetail(candidate)

    if not spec then
        spec, build = GetSavedBotSpec(candidate and candidate.name)
    end

    if spec and build and build ~= "" then
        return spec .. " (" .. build .. ")"
    end

    if spec and spec ~= "" then
        return spec
    end

    return MBLocal("lootmaster.unknown_spec", "Unknown spec")
end

local function GetCandidateGearScore(candidate)
    if type(candidate) ~= "table" then
        return nil
    end

    local score = tonumber(candidate.gearScore or candidate.itemLevelScore or candidate.score)
    if score and score > 0 then
        return score
    end

    local detail = GetBridgeDetail and GetBridgeDetail(candidate.name)
    if type(detail) == "table" then
        score = tonumber(detail.gearScore or detail.itemLevelScore or detail.score)
        if score and score > 0 then
            return score
        end
    end

    if candidate.name and _G.MultiBotGlobalSave then
        local shortName = NormalizeUnitName(candidate.name) or candidate.name
        local value = _G.MultiBotGlobalSave[shortName] or _G.MultiBotGlobalSave[candidate.name]
        if type(value) == "string" then
            local fields = {}
            for field in string.gmatch(value, "([^,]+)") do
                fields[#fields + 1] = field
            end

            score = tonumber(fields[7])
            if score and score > 0 then
                return score
            end
        end
    end

    return nil
end

local function SetClassIconTooltip(button, candidate)
    if not button then
        return
    end

    button.candidate = candidate
    button:SetScript("OnEnter", function(self)
        local current = self.candidate
        if not current then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(current.name or MBLocal("lootmaster.unknown_candidate", "unknown"), 1, 1, 1)

        local className = current.className or GetLocalizedClassName(current.classFile)
        if className then
            GameTooltip:AddLine(className, 0.75, 0.75, 0.75)
        end

        GameTooltip:AddLine(GetCandidateSpecText(current), 0.6, 0.8, 1)

        local gearScore = GetCandidateGearScore(current)
        if gearScore then
            GameTooltip:AddLine(string.format(MBLocal("lootmaster.gear_score", "GearScore: %d"), gearScore), 0.95, 0.82, 0.35)
        end

        local professions = GetCandidateProfessionKeys and GetCandidateProfessionKeys(current)
        if type(professions) == "table" then
            local professionNames = {}
            for profession in pairs(professions) do
                professionNames[#professionNames + 1] = GetProfessionDisplayName(profession)
            end

            table.sort(professionNames)

            if #professionNames > 0 then
                GameTooltip:AddLine(
                    string.format(
                        MBLocal("lootmaster.professions", "Professions: %s"),
                        table.concat(professionNames, ", ")
                    ),
                    0.4, 1, 0.7
                )
            else
                GameTooltip:AddLine(MBLocal("lootmaster.professions_unknown", "Professions: unknown"), 0.65, 0.65, 0.65)
            end
        end

        if current.lootProfession then
            local professionName = GetProfessionDisplayName(current.lootProfession)
            if current.lootProfessionMatch == true then
                GameTooltip:AddLine(string.format(MBLocal("lootmaster.profession_known", "Profession: %s"), professionName), 0.4, 1, 0.7)
            elseif current.lootProfessionMatch == false then
                GameTooltip:AddLine(string.format(MBLocal("lootmaster.profession_missing", "Required profession: %s (not known)"), professionName), 1, 0.45, 0.35)
            else
                GameTooltip:AddLine(string.format(MBLocal("lootmaster.profession_unknown", "Required profession: %s (unknown)"), professionName), 0.9, 0.9, 0.5)
            end
        end
        if current.lootScore then
            GameTooltip:AddLine(MBLocal("lootmaster.priority_score", "Priorite:") .. " " .. GetCandidateScoreColor(current.lootScore) .. current.lootScore .. "%|r", 0.9, 0.9, 0.9)
        end
        GameTooltip:AddLine(MBLocal("lootmaster.inventory_hint", "Right-click: open inventory/equipment."), 0.6, 1, 0.6)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function BuildUnitClassLookup()
    local lookup = {}
    local raidCount = 0
    local partyCount = 0

    if GetNumRaidMembers then
        raidCount = GetNumRaidMembers() or 0
    end

    if raidCount > 0 then
        for index = 1, raidCount do
            local unit = "raid" .. index
            local name = NormalizeUnitName(UnitName(unit))
            local _, classFile = UnitClass(unit)

            if name and classFile then
                lookup[name] = classFile
            end
        end

        return lookup
    end

    local playerName = NormalizeUnitName(UnitName("player"))
    local _, playerClass = UnitClass("player")

    if playerName and playerClass then
        lookup[playerName] = playerClass
    end

    if GetNumPartyMembers then
        partyCount = GetNumPartyMembers() or 0
    end

    for index = 1, partyCount do
        local unit = "party" .. index
        local name = NormalizeUnitName(UnitName(unit))
        local _, classFile = UnitClass(unit)

        if name and classFile then
            lookup[name] = classFile
        end
    end

    return lookup
end

local function GetCandidateScanLimit()
    local raidCount = 0
    local partyCount = 0

    if GetNumRaidMembers then
        raidCount = GetNumRaidMembers() or 0
    end

    if raidCount > 0 then
        if raidCount > MAX_MASTER_LOOT_CANDIDATES then
            return MAX_MASTER_LOOT_CANDIDATES
        end

        return raidCount
    end

    if GetNumPartyMembers then
        partyCount = GetNumPartyMembers() or 0
    end

    if partyCount > 0 then
        return partyCount + 1
    end

    return 1
end

local function BuildCandidateList(slot)
    local candidates = {}
    local seen = {}
    local limit = GetCandidateScanLimit()
    local unitClasses = BuildUnitClassLookup()
    local itemProfile = BuildLootItemProfile(slot)

    for index = 1, limit do
        local name = GetCandidateName(index)

        if not name then
            break
        end

        if not seen[name] then
            seen[name] = true

            local className, classToken = GetCandidateClassInfo(name)

            local candidate = {
                index = index,
                name = name,
                className = className,
                classToken = classToken,
                build = GetKnownBuildForCandidate(name),
                classFile = unitClasses[NormalizeUnitName(name)] or classToken,
            }

            ScoreCandidateForItem(candidate, itemProfile)
            ApplyLootPreferenceScore(candidate, itemProfile)
            candidates[#candidates + 1] = candidate
        end
    end

    table.sort(candidates, function(left, right)
        if (left.lootScore or 0) == (right.lootScore or 0) then
            return tostring(left.name or "") < tostring(right.name or "")
        end
        return (left.lootScore or 0) > (right.lootScore or 0)
    end)

    return candidates
end

local function SafeItemText(slot)
    local link = GetLootSlotLink(slot)

    if link then
        return link
    end

    local _, itemName, quantity = GetLootSlotInfo(slot)

    if itemName and itemName ~= "" then
        if quantity and quantity > 1 then
            return itemName .. " x" .. quantity
        end

        return itemName
    end

    return MBLocal("lootmaster.unknown_item", "Unknown item")
end

local function EnsureLootHistoryLine(frame, index)
    if not frame or not frame.historyContent then
        return nil
    end

    frame.historyLines = frame.historyLines or {}

    if frame.historyLines[index] then
        return frame.historyLines[index]
    end

    local line = frame.historyContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetWidth(FRAME_WIDTH - 72)
    line:SetJustifyH("LEFT")

    if index == 1 then
        line:SetPoint("TOPLEFT", frame.historyContent, "TOPLEFT", 0, -2)
    else
        line:SetPoint("TOPLEFT", frame.historyLines[index - 1], "BOTTOMLEFT", 0, -1)
    end

    frame.historyLines[index] = line
    return line
end

local function UpdateLootHistoryFrame(frame)
    frame = frame or LootMasterUI.frame

    if not frame or not frame.historyLines then
        return
    end

    if #lootHistory == 0 then
        local line = EnsureLootHistoryLine(frame, 1)
        line:SetText("|cff888888" .. MBLocal("lootmaster.history_empty", "No loot assigned yet.") .. "|r")
        line:Show()

        for i = 2, #frame.historyLines do
            frame.historyLines[i]:Hide()
        end

        frame.historyContent:SetHeight(LOOT_HISTORY_HEIGHT)
        return
    end

    for i = 1, #lootHistory do
        local entry = lootHistory[i]
        local line = EnsureLootHistoryLine(frame, i)

        if entry then
            line:SetText(string.format("|cffaaaaaa%s|r %s |cffaaaaaa->|r %s", entry.timeText or "", entry.itemText or "?", entry.candidateName or "?"))
            line:Show()
        end
    end

    for i = #lootHistory + 1, #frame.historyLines do
        frame.historyLines[i]:Hide()
    end

    frame.historyContent:SetHeight(math.max(LOOT_HISTORY_HEIGHT, (#lootHistory * LOOT_HISTORY_LINE_HEIGHT) + 8))
end

local function AddLootHistory(itemText, candidateName)
    table.insert(lootHistory, 1, {
        itemText = itemText or MBLocal("lootmaster.unknown_item", "Unknown item"),
        candidateName = candidateName or MBLocal("lootmaster.unknown_candidate", "unknown"),
        timeText = date and date("%H:%M") or "",
    })

    UpdateLootHistoryFrame()
end

local function IsLootSlotMoney(slot)
    return LootSlotIsCoin and LootSlotIsCoin(slot)
end

local function IsLootSlotEmpty(slot)
    if LootSlotIsItem and LootSlotIsItem(slot) then
        return false
    end

    local link = GetLootSlotLink(slot)
    if link and link ~= "" then
        return false
    end

    local _, itemName = GetLootSlotInfo(slot)
    return not itemName or itemName == ""
end

local function IsLootSlotIgnoredQuality(slot)
    local _, itemName, _, quality = GetLootSlotInfo(slot)

    if not itemName or itemName == "" then
        return false
    end

    local threshold = GetLootThreshold and (GetLootThreshold() or 2) or 2

    if threshold < 2 then
        threshold = 2
    end

    return not quality or quality < threshold
end

local function IsLootSlotRelevant(slot)
    if IsLootSlotMoney(slot) then return false end
    if IsLootSlotEmpty(slot) then return false end
    if IsLootSlotIgnoredQuality(slot) then return false end

    return true
end

local function GetLootSlotHideKey(slot)
    local link = GetLootSlotLink(slot)

    if link and link ~= "" then
        return link
    end

    local _, itemName, quantity, quality = GetLootSlotInfo(slot)

    if itemName and itemName ~= "" then
        return table.concat({ tostring(itemName), tostring(quantity or 1), tostring(quality or 0) }, "|")
    end

    return nil
end

local function PruneAssignedLootKeys()
    local now = GetTime and GetTime() or time() or 0

    for key, expiresAt in pairs(assignedLootKeys) do
        if (tonumber(expiresAt) or 0) <= now then
            assignedLootKeys[key] = nil
        end
    end

    for name, expiresAt in pairs(recentLootByCandidate) do
        if (tonumber(expiresAt) or 0) <= now then
            recentLootByCandidate[name] = nil
        end
    end
end

local function MarkCandidateRecentLoot(candidateName)
    local key = NormalizeName(candidateName)
    if key and key ~= "" then
        recentLootByCandidate[key] = (GetTime and GetTime() or time() or 0) + RECENT_LOOT_PENALTY_SECONDS
    end
end

local function MarkLootSlotAssigned(slot)
    local key = GetLootSlotHideKey(slot)

    if key then
        assignedLootKeys[key] = (GetTime and GetTime() or time() or 0) + 3
    end
end

local function IsLootSlotAssignedLocally(slot)
    local key = GetLootSlotHideKey(slot)

    return key and assignedLootKeys[key] ~= nil
end

local function CreateBasicFrame()
    local widget
    local frame
    local contentParent

    if AceGUI and type(AceGUI.Create) == "function" then
        widget = AceGUI:Create("Window")
        widget:SetTitle(BuildLootMasterTitle())
        widget:SetWidth(FRAME_WIDTH)
        widget:SetHeight(FRAME_HEIGHT)
        widget:EnableResize(false)
        widget:SetCallback("OnClose", function(activeWidget)
            activeWidget.frame:Hide()
        end)

        frame = widget.frame
        frame.widget = widget
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)

        contentParent = widget.content or frame
        AddDarkBackdrop(contentParent, 0.90)
    else
        frame = CreateFrame("Frame", "MultiBotLootMasterFrame", UIParent)
        frame:SetWidth(FRAME_WIDTH)
        frame:SetHeight(FRAME_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)

        AddDarkBackdrop(frame, 0.90)

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
        frame.title:SetText(BuildLootMasterTitle())

        frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
        frame.close:SetScript("OnClick", function()
            frame:Hide()
        end)

        contentParent = frame
    end

    frame.status = contentParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("TOPLEFT", contentParent, "TOPLEFT", 8, -8)
    frame.status:SetWidth(FRAME_WIDTH - 40)
    frame.status:SetJustifyH("LEFT")
    frame.status:SetText(MBLocal("lootmaster.status.ready", "Select an item recipient."))

    frame.refresh = CreateFrame("Button", nil, contentParent, "UIPanelButtonTemplate")
    frame.refresh:SetWidth(90)
    frame.refresh:SetHeight(22)
    frame.refresh:SetPoint("TOPRIGHT", contentParent, "TOPRIGHT", -8, -4)
    frame.refresh:SetText(MBLocal("lootmaster.refresh", "Refresh"))
    frame.refresh:SetScript("OnClick", function()
        LootMasterUI:Refresh()
    end)

    frame.history = CreateFrame("Frame", nil, contentParent)
    frame.history:SetPoint("BOTTOMLEFT", contentParent, "BOTTOMLEFT", 8, 8)
    frame.history:SetPoint("BOTTOMRIGHT", contentParent, "BOTTOMRIGHT", -8, 8)
    frame.history:SetHeight(LOOT_HISTORY_HEIGHT)

    frame.historyTitle = frame.history:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.historyTitle:SetPoint("TOPLEFT", frame.history, "TOPLEFT", 0, 0)
    frame.historyTitle:SetText(MBLocal("lootmaster.history_title", "Recent loot"))

    frame.historyScroll = CreateFrame("ScrollFrame", "MultiBotLootMasterHistoryScrollFrame", frame.history, "UIPanelScrollFrameTemplate")
    frame.historyScroll:SetPoint("TOPLEFT", frame.historyTitle, "BOTTOMLEFT", 0, -2)
    frame.historyScroll:SetPoint("BOTTOMRIGHT", frame.history, "BOTTOMRIGHT", -24, 0)
    frame.historyScroll:EnableMouseWheel(true)
    frame.historyScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maxScroll = self:GetVerticalScrollRange() or 0

        if delta < 0 then
            self:SetVerticalScroll(math.min(current + 20, maxScroll))
        else
            self:SetVerticalScroll(math.max(current - 20, 0))
        end
    end)

    frame.historyContent = CreateFrame("Frame", nil, frame.historyScroll)
    frame.historyContent:SetWidth(FRAME_WIDTH - 72)
    frame.historyContent:SetHeight(LOOT_HISTORY_HEIGHT)
    frame.historyScroll:SetScrollChild(frame.historyContent)

    frame.historyLines = {}

    frame.content = CreateFrame("Frame", nil, contentParent)
    frame.content:SetPoint("TOPLEFT", frame.status, "BOTTOMLEFT", 0, -16)
    frame.content:SetPoint("BOTTOMRIGHT", frame.history, "TOPRIGHT", 0, 8)

    frame.rows = {}
    UpdateLootHistoryFrame(frame)

    frame:Hide()

    return frame
end

local function ClearRows(frame)
    if not frame or not frame.rows then
        return
    end

    for _, row in ipairs(frame.rows) do
        row:Hide()
    end
end

local function AcquireRow(frame, index)
    frame.rows[index] = frame.rows[index] or CreateFrame("Frame", nil, frame.content)

    local row = frame.rows[index]
    row.index = index

    row:SetParent(frame.content)
    row:SetWidth(FRAME_WIDTH - 52)
    row:SetHeight(ITEM_ROW_HEIGHT)
    row:ClearAllPoints()

    if index == 1 then
        row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", frame.rows[index - 1], "BOTTOMLEFT", 0, -8)
    end

    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(28)
        row.icon:SetHeight(28)
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -4)
    end

    if not row.iconButton then
        row.iconButton = CreateFrame("Button", nil, row)
        row.iconButton:SetWidth(28)
        row.iconButton:SetHeight(28)
        row.iconButton:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
    end

    if not row.itemButton then
        row.itemButton = CreateFrame("Button", nil, row)
        row.itemButton:SetWidth(FRAME_WIDTH - 128)
        row.itemButton:SetHeight(22)
        row.itemButton:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)

        row.itemButton.text = row.itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.itemButton.text:SetPoint("LEFT", row.itemButton, "LEFT", 0, 0)
        row.itemButton.text:SetWidth(FRAME_WIDTH - 128)
        row.itemButton.text:SetJustifyH("LEFT")

    end

    if not row.candidateLabel then
        row.candidateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.candidateLabel:SetPoint("TOPLEFT", row.itemButton, "BOTTOMLEFT", 0, -8)
        row.candidateLabel:SetText(MBLocal("lootmaster.assign_to", "Assign to:"))
    end

    if not row.selectButton then
        row.selectButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.selectButton:SetWidth(DROPDOWN_WIDTH)
        row.selectButton:SetHeight(22)
        row.selectButton:SetPoint("LEFT", row.candidateLabel, "RIGHT", 8, 0)
        row.selectButton.ownerRow = row

        row.selectButton:SetScript("OnClick", function(self)
            local ownerRow = self.ownerRow
            local candidates = ownerRow and ownerRow.candidates or nil

            if not candidates or #candidates == 0 then
                return
            end

            if ownerRow.dropdown and ownerRow.dropdown:IsShown() then
                ownerRow.dropdown:Hide()
                return
            end

            if CloseAllDropdowns then
                CloseAllDropdowns()
            end

            ownerRow.dropdown = ownerRow.dropdown or CreateFrame("Frame", nil, UIParent)
            local dropdown = ownerRow.dropdown
            dropdown:SetFrameStrata("TOOLTIP")
            dropdown:SetWidth(DROPDOWN_WIDTH + 72)
            dropdown:SetHeight((#candidates * 22) + 12)
            dropdown:ClearAllPoints()
            dropdown:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            dropdown:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            dropdown:SetBackdropColor(0, 0, 0, 0.95)
            dropdown.buttons = dropdown.buttons or {}

            for i, candidate in ipairs(candidates) do
                local button = dropdown.buttons[i]

                if not button then
                    button = CreateFrame("Button", nil, dropdown)
                    dropdown.buttons[i] = button
                    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    button:SetHeight(20)
                    button:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
                    button:SetPoint("RIGHT", dropdown, "RIGHT", -8, 0)

                    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    button.text:SetPoint("LEFT", button, "LEFT", 0, 0)
                    button.text:SetPoint("RIGHT", button, "RIGHT", -24, 0)
                    button.text:SetJustifyH("LEFT")

                    button.classIconButton = CreateFrame("Button", nil, button)
                    button.classIconButton:SetWidth(16)
                    button.classIconButton:SetHeight(16)
                    button.classIconButton:SetPoint("RIGHT", button, "RIGHT", 0, 0)
                    button.classIcon = button.classIconButton:CreateTexture(nil, "ARTWORK")
                    button.classIcon:SetAllPoints(button.classIconButton)
                end

                button:ClearAllPoints()
                if i == 1 then
                    button:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 8, -6)
                    button:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -8, -6)
                else
                    button:SetPoint("TOPLEFT", dropdown.buttons[i - 1], "BOTTOMLEFT", 0, -2)
                    button:SetPoint("TOPRIGHT", dropdown.buttons[i - 1], "BOTTOMRIGHT", 0, -2)
                end

                local classIcon = GetClassIconTexture(candidate.classFile)
                local classIconCoords = GetClassIconCoords(candidate.classFile)

                button.ownerRow = ownerRow
                button.candidate = candidate
                button.text:SetText(BuildCandidateDropdownText(candidate))
                SetClassIconTooltip(button, candidate)

                button:SetScript("OnClick", function(clicked, mouseButton)
                    local selected = clicked.candidate
                    local selectedRow = clicked.ownerRow

                    if mouseButton == "RightButton" then
                        OpenCandidateInventory(selected)
                        dropdown:Hide()
                        return
                    end

                    if not selected or not selectedRow then
                        return
                    end

                    selectedRow.selectedCandidateIndex = selected.index
                    selectedRow.selectedCandidateName = selected.name
                    selectedRow.selectedCandidate = selected
                    selectedRow.selectButton:SetText(BuildCandidateSelectionText(selected))
                    dropdown:Hide()
                end)

                if classIcon then
                    button.classIcon:SetTexture(classIcon)
                    if classIconCoords then
                        button.classIcon:SetTexCoord(classIconCoords[1], classIconCoords[2], classIconCoords[3], classIconCoords[4])
                    else
                        button.classIcon:SetTexCoord(0, 1, 0, 1)
                    end
                    button.classIconButton:Show()
                    SetClassIconTooltip(button.classIconButton, candidate)
                else
                    button.classIconButton:Hide()
                    SetClassIconTooltip(button.classIconButton, nil)
                end

                button:Show()
            end

            for i = #candidates + 1, #dropdown.buttons do
                dropdown.buttons[i]:Hide()
            end

            dropdown:Show()
        end)
    end

    if not row.assignButton then
        row.assignButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.assignButton:SetWidth(90)
        row.assignButton:SetHeight(22)
        row.assignButton:SetPoint("LEFT", row.selectButton, "RIGHT", 8, 0)
        row.assignButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.assignButton:SetText(MBLocal("lootmaster.assign", "Assign"))
        row.assignButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(MBLocal("lootmaster.assign", "Assign"), 1, 1, 1)
            GameTooltip:AddLine(MBLocal("lootmaster.preference_hint", "Right-click: remember. Shift-right-click: forget."), 0.6, 1, 0.6)
            GameTooltip:Show()
        end)
        row.assignButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row.assignButton:SetScript("OnClick", function(self, mouseButton)
            local ownerRow = self.ownerRow

            if not ownerRow or not ownerRow.slot or not ownerRow.selectedCandidateIndex then
                AddSystemMessage(MBLocal("lootmaster.error.invalid_candidate", "Invalid loot candidate."))
                return
            end

            if mouseButton == "RightButton" then
                if IsShiftKeyDown and IsShiftKeyDown() then
                    ClearLootPreference(ownerRow.slot)
                else
                    SaveLootPreference(ownerRow.slot, ownerRow.selectedCandidate)
                end

                if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
                    LootMasterUI:Refresh()
                end

                return
            end

            AssignLoot(ownerRow.slot, ownerRow.selectedCandidateIndex, ownerRow.selectedCandidateName)
        end)

        row.assignButton.ownerRow = row
    end

    if not row.noCandidateText then
        row.noCandidateText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.noCandidateText:SetPoint("LEFT", row.candidateLabel, "RIGHT", 8, 0)
        row.noCandidateText:SetJustifyH("LEFT")
        row.noCandidateText:SetText(MBLocal("lootmaster.no_candidates_for_item", "No candidates for this item."))
        row.noCandidateText:Hide()
    end

    if row.dropdown then
        row.dropdown:Hide()
    end

    row.candidates = nil
    row.selectedCandidateIndex = nil
    row.selectedCandidateName = nil
    row.selectedCandidate = nil
    row.slot = nil
    SetLootIconTooltip(row.iconButton, nil)

    row:Show()

    return row
end

local function ApplyCandidateSelection(row, candidate)
    if not row then
        return
    end

    if not candidate then
        row.selectedCandidateIndex = nil
        row.selectedCandidateName = nil
        row.selectedCandidate = nil
        row.selectButton:SetText(MBLocal("lootmaster.select_bot", "Select a bot"))
        return
    end

    row.selectedCandidateIndex = candidate.index
    row.selectedCandidateName = candidate.name
    row.selectedCandidate = candidate
    row.selectButton:SetText(BuildCandidateSelectionText(candidate))
end

local function PrepareRowSelection(row, candidates)
    row.candidates = candidates or {}
    ApplyCandidateSelection(row, row.candidates[1])
end

CloseAllDropdowns = function()
    local frame = LootMasterUI.frame
    if not frame or not frame.rows then
        return
    end

    for _, row in ipairs(frame.rows) do
        if row.dropdown then
            row.dropdown:Hide()
        end
    end
end

local function UpdateRowCandidateControls(row, candidates)
    PrepareRowSelection(row, candidates)

    if candidates and #candidates > 0 then
        row.selectButton:Show()
        row.assignButton:Show()
        row.noCandidateText:Hide()
        row.candidateLabel:SetText(MBLocal("lootmaster.assign_to", "Assign to:"))
    else
        row.selectButton:Hide()
        row.assignButton:Hide()
        row.noCandidateText:Show()
        row.candidateLabel:SetText(MBLocal("lootmaster.assign_to", "Assign to:"))
    end
end

QueueRefresh = function(delay)
    local frame = LootMasterUI.frame

    if not frame then
        return
    end

    frame.refreshDelay = delay or 0.15
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.refreshDelay = (self.refreshDelay or 0) - elapsed

        if self.refreshDelay > 0 then
            return
        end

        self:SetScript("OnUpdate", nil)

        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            LootMasterUI:Refresh()
        end
    end)
end

AssignLoot = function(slot, candidateIndex, candidateName)
    local itemText = SafeItemText(slot)

    if not IsPlayerMasterLooter() then
        AddSystemMessage(MBLocal("lootmaster.error.not_master", "You are not the master looter."))
        return
    end

    if not candidateIndex then
        AddSystemMessage(MBLocal("lootmaster.error.invalid_candidate", "Invalid loot candidate."))
        return
    end

    MarkLootSlotAssigned(slot)
    MarkCandidateRecentLoot(candidateName)
    GiveMasterLoot(slot, candidateIndex)
    AddLootHistory(itemText, candidateName)

    if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
        LootMasterUI:Refresh()
    end

    AddSystemMessage(
        string.format(
            MBLocal("lootmaster.assigned", "Assigned %s to %s."),
            itemText,
            candidateName or MBLocal("lootmaster.unknown_candidate", "unknown")
        )
    )

    RunLater(0.2, function()
        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            QueueRefresh(0.05)
        end
    end)

    RunLater(0.7, function()
        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            QueueRefresh(0.05)
        end
    end)

    RunLater(1.4, function()
        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            LootMasterUI:Refresh()
        end
    end)
end

function LootMasterUI:EnsureFrame()
    if self.frame then
        return self.frame
    end

    self.frame = CreateBasicFrame()

    return self.frame
end

function LootMasterUI:Refresh()
    local frame = self:EnsureFrame()
    local numSlots = GetNumLootItems() or 0
    local rowIndex = 1
    local totalCandidates = 0

    PruneAssignedLootKeys()
    ClearRows(frame)
    UpdateLootMasterTitle(frame)

    if not IsPlayerMasterLooter() then
        frame.status:SetText(MBLocal("lootmaster.status.not_master", "Loot method is not master loot, or you are not the master looter."))
        return
    end

    if numSlots <= 0 then
        frame.status:SetText(MBLocal("lootmaster.status.no_loot", "No loot available."))
        return
    end

    frame.status:SetText(MBLocal("lootmaster.status.ready", "Select an item recipient."))

    for slot = 1, numSlots do
        if IsLootSlotRelevant(slot) and not IsLootSlotAssignedLocally(slot) then
            local texture, itemName, quantity, quality = GetLootSlotInfo(slot)
            local itemLink = GetLootSlotLink(slot)
            local candidates = BuildCandidateList(slot)

            if itemName and itemName ~= "" then
                local row = AcquireRow(frame, rowIndex)
                local itemText = itemName

                if quantity and quantity > 1 then
                    itemText = itemText .. " x" .. quantity
                end

                row.slot = slot
                row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                SetLootIconTooltip(row.iconButton, itemLink)
                row.itemButton.text:SetText(itemText)

                if quality and GetItemQualityColor then
                    local r, g, b = GetItemQualityColor(quality)
                    row.itemButton.text:SetTextColor(r or 1, g or 1, b or 1)
                else
                    row.itemButton.text:SetTextColor(1, 1, 1)
                end

                UpdateRowCandidateControls(row, candidates)

                totalCandidates = totalCandidates + #candidates
                rowIndex = rowIndex + 1
            end
        end
    end

    for i = rowIndex, #frame.rows do
        if frame.rows[i] then
            frame.rows[i]:Hide()
        end
    end

    if rowIndex == 1 then
        frame.status:SetText(MBLocal("lootmaster.status.no_loot", "No loot available."))
        return
    end

    if totalCandidates == 0 and rowIndex > 1 then
        frame.status:SetText(MBLocal("lootmaster.status.no_candidates", "Loot found, but no master-loot candidates were returned by the client."))
        AddSystemMessage("Loot master debug: loot exists, but GetMasterLootCandidate returned no candidates.")
        return
    end
end

function LootMasterUI:Open()
    if not IsLootMasterUIEnabled() then
        self:Close()
        return
    end

    local frame = self:EnsureFrame()

    frame:Show()

    if frame.Raise then
        frame:Raise()
    end

    AddSystemMessage("Loot master UI opening frame.")

    self:Refresh()

    if frame.Raise then
        frame:Raise()
    end
end

function LootMasterUI:Close()
    if CloseAllDropdowns then
        CloseAllDropdowns()
    end

    if self.frame then
        self.frame:Hide()
    end
end

function LootMasterUI:RegisterProfessionCandidate(botName, profession)
    local professionKey = GetProfessionKeyFromText(profession)
    if not botName or botName == "" or not professionKey then
        return false
    end

    _G.MultiBotLootMasterProfessionCache = _G.MultiBotLootMasterProfessionCache or {}

    local nameKey = NormalizeName(botName)
    _G.MultiBotLootMasterProfessionCache[nameKey] = _G.MultiBotLootMasterProfessionCache[nameKey] or {}
    _G.MultiBotLootMasterProfessionCache[nameKey][professionKey] = true

    return true
end

function LootMasterUI:OnLootOpened(autoLoot)
    if not IsLootMasterUIEnabled() then
        self:Close()
        return
    end

    local numSlots = GetNumLootItems() or 0
    local method, partyIndex, raidIndex = GetLootMethod()

    AddSystemMessage(
        string.format(
            "LOOT_OPENED debug: autoLoot=%s, method=%s, partyMaster=%s, raidMaster=%s, slots=%d",
            tostring(autoLoot),
            tostring(method),
            tostring(partyIndex),
            tostring(raidIndex),
            numSlots
        )
    )

    if raidIndex and raidIndex > 0 then
        AddSystemMessage(
            string.format(
                "Loot master debug: raid master unit=raid%d, name=%s, isPlayer=%s",
                raidIndex,
                tostring(UnitName("raid" .. raidIndex)),
                tostring(UnitIsUnit("raid" .. raidIndex, "player"))
            )
        )
    elseif partyIndex then
        AddSystemMessage(
            string.format("Loot master debug: partyMaster=%s, isPlayerMaster=%s", tostring(partyIndex), tostring(partyIndex == 0))
        )
    end

    if not IsPlayerMasterLooter() then
        AddSystemMessage("Loot master UI skipped: you are not detected as master looter.")
        return
    end

    if numSlots <= 0 then
        AddSystemMessage("Loot master UI skipped: no visible loot slots.")
        return
    end

    local hasRelevantLoot = false
    for slot = 1, numSlots do
        if IsLootSlotRelevant(slot) then
            hasRelevantLoot = true
            break
        end
    end

    if not hasRelevantLoot then
        self:Close()
        return
    end

    self:Open()

    if MultiBot and MultiBot.Comm and type(MultiBot.Comm.RequestBotDetails) == "function" then
        MultiBot.Comm.RequestBotDetails()
        QueueRefresh(0.35)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_SLOT_CHANGED")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if not IsLootMasterUIEnabled() then
        if event == "LOOT_CLOSED" then
            LootMasterUI:Close()
        end
        return
    end

    if event == "LOOT_OPENED" then
        CancelQueuedLootClose()
        assignedLootKeys = {}
        LootMasterUI:OnLootOpened(...)
        return
    end

    if event == "LOOT_SLOT_CHANGED" then
        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            QueueRefresh(0.05)
        end
        return
    end

    if event == "PARTY_LOOT_METHOD_CHANGED" then
        if LootMasterUI.frame and LootMasterUI.frame:IsShown() then
            LootMasterUI:Refresh()
        end
        return
    end

    if event == "LOOT_CLOSED" then
        QueueLootClose()
    end
end)

_G.MultiBotLootMasterUI = LootMasterUI
