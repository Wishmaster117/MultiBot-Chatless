-- MultiBotLootMasterUI.lua

local addonName = ...

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
local assignedLootSlots = {}
local recentLootByCandidate = {}
local lootHistory = {}

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 420
local ITEM_ROW_HEIGHT = 64
local DROPDOWN_WIDTH = 220
local MAX_MASTER_LOOT_CANDIDATES = 40
local RECENT_LOOT_PENALTY_SECONDS = 120
local LOOT_HISTORY_LINE_HEIGHT = 14
local LOOT_HISTORY_HEIGHT = 62
local LOOT_PREFERENCE_BONUS = 18
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

local function GetCachedTalentSpecList(name)
    local bridge = MultiBot and MultiBot.bridge
    local specs = bridge and bridge.talentSpecs

    if type(specs) ~= "table" then
        return nil
    end

    return specs[NormalizeName(name)] or specs[string.lower(ShortName(name) or "")] or specs[name]
end

local function FindKnownSpecNameFromBuild(name, build)
    if type(build) ~= "string" or build == "" then
        return nil
    end

    local specs = GetCachedTalentSpecList(name)
    if type(specs) ~= "table" then
        return nil
    end

    for _, entry in ipairs(specs) do
        if type(entry) == "table" and entry.build == build and type(entry.name) == "string" and entry.name ~= "" then
            return entry.name
        end
    end

    return nil
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

local function BuildCandidateSpecText(candidate)
    if not candidate then
        return MBLocal("lootmaster.unknown_spec", "Unknown spec")
    end

    local build = candidate.build
    local knownSpecName = FindKnownSpecNameFromBuild(candidate.name, build)
    local guessed = GuessSpecFromBuild(candidate.classToken, build)

    if knownSpecName and build then
        return knownSpecName .. " (" .. build .. ")"
    end

    if guessed and build then
        return guessed .. " (" .. build .. ")"
    end

    if build then
        return build
    end

    return MBLocal("lootmaster.unknown_spec", "Unknown spec")
end

local function GetCandidateDisplayName(candidate)
    local name = candidate and candidate.name or ""
    local classToken = candidate and candidate.classToken
    local color = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]

    if color and color.colorStr then
        return "|c" .. color.colorStr .. name .. "|r"
    end

    return name
end

local function ApplyClassIcon(texture, classToken)
    if not texture then
        return
    end

    if classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken] then
        local coords = CLASS_ICON_TCOORDS[classToken]
        texture:SetTexture(CLASS_ICON_TEXTURE)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        texture:Show()
        return
    end

    texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    texture:SetTexCoord(0, 1, 0, 1)
    texture:Show()
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

local function GetCandidateRole(candidate)
    local classFile = candidate and (candidate.classFile or candidate.classToken)
    local tree = GetCandidateTreeIndex(candidate)

    if classFile == "WARRIOR" then return tree == 3 and "tank" or "physical" end
    if classFile == "PALADIN" then return tree == 1 and "healer" or (tree == 2 and "tank" or "physical") end
    if classFile == "PRIEST" then return tree == 3 and "caster" or "healer" end
    if classFile == "DEATHKNIGHT" then return tree == 1 and "tank" or "physical" end
    if classFile == "SHAMAN" then return tree == 1 and "caster" or (tree == 2 and "physical" or "healer") end
    if classFile == "DRUID" then return tree == 1 and "caster" or (tree == 2 and "feral" or "healer") end
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

local function GetItemStatFlags(itemLink)
    local text = GetLootTooltipText(itemLink)
    local hasDefense = TextHasAny(text, { "defense", "d.fense", "dodge", "esquive", "parry", "parade", "block", "blocage" })
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
    local hasHealerHint = hasHealing or hasMp5 or hasSpirit
    local primary

    if hasDefense then
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
    }
end

local function BuildLootItemProfile(slot)
    local itemLink = GetLootSlotLink(slot)
    local _, itemName = GetLootSlotInfo(slot)
    local query = itemLink or itemName
    local _, _, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(query or "")

    return {
        link = itemLink,
        itemType = itemType,
        itemSubType = itemSubType,
        equipLoc = equipLoc,
        armorType = GetArmorType(itemSubType, equipLoc),
        weaponType = GetWeaponType(itemSubType, equipLoc),
        statFlags = GetItemStatFlags(itemLink),
    }
end

local function BuildLootPreferenceKey(profile)
    if type(profile) ~= "table" then
        return nil
    end

    local flags = profile.statFlags or {}
    return table.concat({
        flags.primary or "any",
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
        if role == "feral" then
            return flags.primary == "tank" or flags.primary == "physical"
        end

        return role == flags.primary
    end

    return role and flags[role] == true
end

local function GetRoleStatScore(role, flags)
    if not flags or not flags.primary then return 0 end
    if RoleMatchesStats(role, flags) then return 42 end
    if flags.primary == "physical" and (role == "healer" or role == "caster") then return -45 end
    if flags.primary == "caster" and (role == "physical" or role == "tank" or role == "feral") then return -45 end
    if flags.primary == "healer" and role ~= "healer" then return -45 end
    if flags.primary == "tank" and role ~= "tank" and role ~= "feral" then return -35 end
    return -25
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
    end

    if CandidateHadRecentLoot(candidate) then
        score = score - 15
    end

    candidate.lootScore = Clamp(score, 1, 99)
end

local function ApplyLootPreferenceScore(candidate, profile)
    local preferredName = GetPreferredLootCandidate(profile)

    candidate.lootPreference = false

    if preferredName and NormalizeName(candidate.name) == NormalizeName(preferredName) then
        candidate.lootPreference = true
        candidate.lootScore = Clamp((candidate.lootScore or 0) + LOOT_PREFERENCE_BONUS, 1, 99)
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
    return GetClassColorCode(candidate.classFile) .. candidate.name .. "|r  " .. GetCandidateSpecLabel(candidate) .. "  " .. GetCandidateScoreColor(score) .. score .. "%|r" .. prefText
end

local function SetClassIconTooltip(button, candidate)
    if not button then
        return
    end

    button.candidate = candidate
    button:SetScript("OnEnter", function(self)
        local activeCandidate = self.candidate
        if not activeCandidate then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(activeCandidate.name or MBLocal("lootmaster.unknown_candidate", "unknown"), 1, 1, 1)
        GameTooltip:AddLine(activeCandidate.className or MBLocal("lootmaster.unknown_class", "Unknown class"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(BuildCandidateSpecText(activeCandidate), 0.6, 0.8, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
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

    return "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
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

    local texture, itemName, quantity = GetLootSlotInfo(slot)

    if itemName and itemName ~= "" then
        if quantity and quantity > 1 then
            return itemName .. " x" .. quantity
        end

        return itemName
    end

    return MBLocal("lootmaster.unknown_item", "Unknown item")
end

local function BuildLootSlotKey(slot)
    local link = GetLootSlotLink(slot)
    if link and link ~= "" then
        return link
    end

    local _, itemName, quantity = GetLootSlotInfo(slot)
    return tostring(slot) .. ":" .. tostring(itemName or "") .. ":" .. tostring(quantity or 1)
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

local function MarkLootSlotAssigned(slot)
    assignedLootKeys[BuildLootSlotKey(slot)] = GetTime and GetTime() or time()
    assignedLootSlots[slot] = GetTime and GetTime() or time()
end

local function IsLootSlotAssignedLocally(slot)
    return assignedLootSlots[slot] ~= nil or assignedLootKeys[BuildLootSlotKey(slot)] ~= nil
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

    frame.historyScroll = CreateFrame("ScrollFrame", nil, frame.history, "UIPanelScrollFrameTemplate")
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

                local classColor = GetClassColorCode(candidate.classFile)
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
        local isMoney = IsLootSlotMoney(slot)

        if not isMoney and not IsLootSlotEmpty(slot) and not IsLootSlotAssignedLocally(slot) then
            local texture, itemName, quantity, quality, locked = GetLootSlotInfo(slot)
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

function LootMasterUI:OnLootOpened(autoLoot)
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
    if event == "LOOT_OPENED" then
        assignedLootKeys = {}
        assignedLootSlots = {}
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
        LootMasterUI:Close()
    end
end)

_G.MultiBotLootMasterUI = LootMasterUI
