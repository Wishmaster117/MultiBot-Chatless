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

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 420
local ITEM_ROW_HEIGHT = 64
local DROPDOWN_WIDTH = 190
local MAX_MASTER_LOOT_CANDIDATES = 40
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local AssignLoot
local QueueRefresh
local CloseAllDropdowns

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

local function GuessSpecFromBuild(classToken, build)
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

local function GetClassColorCode(classFile)
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

local function GetBridgeDetail(name)
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

local function GetSavedBotSpec(name)
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

local function GetSpecFromBridgeDetail(candidate)
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
        GameTooltip:Show()
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

    for index = 1, limit do
        local name = GetCandidateName(index)

        if not name then
            break
        end

        if not seen[name] then
            seen[name] = true

            local className, classToken = GetCandidateClassInfo(name)

            candidates[#candidates + 1] = {
                index = index,
                name = name,
                className = className,
                classToken = classToken,
                build = GetKnownBuildForCandidate(name),
                classFile = unitClasses[NormalizeUnitName(name)] or classToken,
            }
        end
    end

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

    frame.content = CreateFrame("Frame", nil, contentParent)
    frame.content:SetPoint("TOPLEFT", frame.status, "BOTTOMLEFT", 0, -16)
    frame.content:SetPoint("BOTTOMRIGHT", contentParent, "BOTTOMRIGHT", -8, 8)

    frame.rows = {}

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
            dropdown:SetWidth(DROPDOWN_WIDTH + 32)
            dropdown:SetHeight((#candidates * 20) + 12)
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
                    button:SetHeight(18)
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
                button.text:SetText(classColor .. candidate.name .. "|r")
                button:SetScript("OnClick", function(clicked)
                    local selected = clicked.candidate
                    local selectedRow = clicked.ownerRow

                    selectedRow.selectedCandidateIndex = selected.index
                    selectedRow.selectedCandidateName = selected.name
                    selectedRow.selectButton:SetText(GetClassColorCode(selected.classFile) .. selected.name .. "|r")
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
        row.assignButton:SetText(MBLocal("lootmaster.assign", "Assign"))
        row.assignButton:SetScript("OnClick", function(self)
            local ownerRow = self.ownerRow

            if not ownerRow or not ownerRow.slot or not ownerRow.selectedCandidateIndex then
                AddSystemMessage(MBLocal("lootmaster.error.invalid_candidate", "Invalid loot candidate."))
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
    row.selectButton:SetText(GetClassColorCode(candidate.classFile) .. candidate.name .. "|r")
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
    GiveMasterLoot(slot, candidateIndex)

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
