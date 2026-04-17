--[[
MultiBotSpecUI.lua  – Extension module for the MultiBot addon by TheWarlock aka Wishmaster117
Adds a “Set talents” button on each bot frame and builds a dynamic dropdown list
with all spec builds returned by the command  /w <bot> "talents spec list".
]]--

local function getSpecIcons()
  local dataProvider = MultiBot.GetIconosEntries
  local icons = type(dataProvider) == "function" and dataProvider() or (MultiBot.data and MultiBot.data.iconos)
  if type(icons) ~= "table" then
    return {}
  end
  return icons
end

local icons = getSpecIcons()

local defaultIcon = "Interface\\Icons\\Achievement_Reputation_08"

local function specTip(key, fallback)
  local multiBot = _G["MultiBot"]
  if multiBot and multiBot.L then
    return multiBot.L("tips.spec." .. key, fallback)
  end
  return fallback or ("tips.spec." .. key)
end

-- canonicalisation des petits préfixes
local specCanonical = {
  -- Paladin
  holy        = "Holy",
  ret         = "Ret",
  -- Druid
  balance     = "Balance",
  bear        = "Bear",
  cat         = "Cat",
  resto       = "Restoration",
  -- Shaman
  ele         = "Ele",
  enh         = "Enh",
  -- Warrior
  arms        = "Arms",
  fury        = "Fury",
  prot        = "Protection",
  -- Hunter
  bm          = "BM",
  mm          = "Marksmanship",
  surv        = "Survival",
  -- Priest
  shadow      = "Shadow",
  disc        = "Discipline",
  -- Mage
  arcane      = "Arcane",
  fire        = "Fire",
  frostfire   = "Frostfire",
  frost       = "Frost",
  -- Warlock
  affli       = "Affliction",
  demo        = "Demonology",
  destro      = "Destruction",
  -- DK
  blood       = "Blood",
  unholy      = "Unholy",
  double      = "Double",
  -- Rogue
  as          = "As",
  combat      = "Combat",
  subtlety    = "Subtlety",
}


local specIconMap = {
  DeathKnight = {
    Blood  = {
      pve = { icon = icons[5427], tip =  specTip("dkbloodpve") },
      pvp = { icon = icons[5427], tip =  specTip("dkbloodpvp") },
    },
    Frost  = {
      pve = { icon = icons[5438], tip = specTip("dkbfrostpve") },
      pvp = { icon = icons[5438], tip = specTip("dkbfrostpvp") },
    },
    Unholy = {
      pve = { icon = icons[5454], tip = specTip("dkunhopve") },
      pvp = { icon = icons[5454], tip = specTip("dkunhopvp")  },
    },
    Double = {
      pve = { icon = icons[5946], tip = specTip("dkdoublepve") },
    },
  },

  Druid = {
    Balance     = {
      pve = { icon = icons[73], tip = specTip("druidbalpve") },
      pvp = { icon = icons[73], tip = specTip("druidbalpvp") },
    },
    Cat        = {
      pve = { icon = icons[28] , tip = specTip("druidcatpve") },
      pvp = { icon = icons[28], tip = specTip("druidcatpvp") },
    },
    Bear       = {
      pve = { icon = icons[325] , tip = specTip("druidbearpve") }
    },
    Restoration = {
      pve = { icon = icons[5745]  , tip = specTip("druidrestopve") },
      pvp = { icon = icons[5745], tip = specTip("druidrestopvp") },
    },
  },

  Hunter = {
    BM           = {
      pve = { icon = icons[103], tip = specTip("huntbmpve") },
      pvp = { icon = icons[103], tip = specTip("huntbmpvp") },
    },
    Marksmanship = {
      pve = { icon = icons[214], tip = specTip("huntmarkpve") },
      pvp = { icon = icons[214], tip = specTip("huntmarkpvp") },
    },
    Survival     = {
      pve = { icon = icons[181]  , tip = specTip("huntsurvpve") },
      pvp = { icon = icons[181]  , tip = specTip("huntsurvpvp") },
    },
  },

  Mage = {
    Arcane = {
      pve = { icon = icons[5551], tip = specTip("magearcapve")},
      pvp = { icon = icons[5551], tip = specTip("magearcapvp") },
    },
    Fire   = {
      pve = { icon = icons[5494] , tip = specTip("magefirepve") },
      pvp = { icon = icons[5494], tip = specTip("magefirepvp") },
    },
    Frostfire   = {
      pve = { icon = icons[200] , tip = specTip("magefrostfirepve") },
    },
    Frost  = {
      pve = { icon = icons[5521] , tip = specTip("magefrostpve") },
      pvp = { icon = icons[5521], tip = specTip("magefrostpvp")},
    },
  },

  Paladin = {
    Holy = {
      pve = { icon = icons[5608], tip = specTip("paladinholypve")},
      pvp = { icon = icons[5608], tip = specTip("paladinholypvp")},
    },
    Protection = {
      pve = { icon = icons[5578] , tip = specTip("paladinprotpve") },
      pvp = { icon = icons[5578], tip = specTip("paladinprotpvp") },
    },
    Ret   = {
      pve = { icon = icons[300], tip = specTip("paladinretpve") },
      pvp = { icon = icons[300], tip = specTip("paladinretpvp") }
    },
  },

  Priest = {
    Discipline = {
      pve = { icon = icons[5685], tip = specTip("priestdiscipve") },
      pvp = { icon = icons[5685], tip = specTip("priestdiscipvp") },
    },
    Holy = {
      pve = { icon = icons[5601], tip = specTip("priestholypve") },
      pvp = { icon = icons[5601], tip = specTip("priestholypvp") },
    },
    Shadow = {
      pve = { icon = icons[5929], tip = specTip("priestshadowpve") },
      pvp = { icon = icons[5929], tip = specTip("priestshadowpvp") },
    },
  },

  Rogue = {
    As = {
      pve = { icon = icons[346], tip = specTip("rogassapve") },
      pvp = { icon = icons[346], tip = specTip("rogassapvp") },
    },
    Combat = {
      pve = { icon = icons[358], tip = specTip("rogcombatpve") },
      pvp = { icon = icons[358], tip = specTip("rogcombatpvp") },
    },
    Subtlety = {
      pve = { icon = icons[331], tip = specTip("rogsubtipve") },
      pvp = { icon = icons[331], tip = specTip("rogsubtipvp") },
    },
  },

  Shaman = {
    Ele   = {
      pve = { icon = icons[5716], tip = specTip("shamanelempve") },
      pvp = { icon = icons[5716], tip = specTip("shamanelempvp") },
    },
    Enh  = {
      pve = { icon = icons[5755], tip = specTip("shamanenhpve") },
      pvp = { icon = icons[5755], tip = specTip("shamanenhpvp") },
    },
    Restoration = {
      pve = { icon = icons[5756], tip = specTip("shamanrestopve") },
      pvp = { icon = icons[5756], tip = specTip("shamanrestopvp") },
    },
  },

  Warlock = {
    Affliction = {
      pve = { icon = icons[5852], tip = specTip("warlockafflipve") },
      pvp = { icon = icons[5852], tip = specTip("warlockafflipvp") },
    },
    Demonology = {
      pve = { icon = icons[5889], tip = specTip("warlockdemonopve") },
      pvp = { icon = icons[5889], tip = specTip("warlockdemonopvp") },
    },
    Destruction = {
      pve = { icon = icons[5907], tip = specTip("warlockdestrupve") },
      pvp = { icon = icons[5907], tip = specTip("warlockdestrupvp") },
    },
  },

  Warrior = {
    Arms = {
      pve = { icon = icons[436], tip = specTip("warriorarmspve") },
      pvp = { icon = icons[436], tip = specTip("warriorarmspvp") },
    },
    Fury = {
      pve = { icon = icons[480], tip = specTip("warriorfurypve") },
      pvp = { icon = icons[480], tip = specTip("warriorfurypvp") },
    },
    Protection = {
      pve = { icon = icons[4456], tip = specTip("warriorprotecpve") },
      pvp = { icon = icons[4456], tip = specTip("warriorprotecpvp") },
    },
  },
}

-- renvoie le premier champ userdata trouvé dans un wrapper
local function unwrapFrame(obj)
    if type(obj) == "userdata" then return obj end
    if type(obj) == "table" then
        for _, v in pairs(obj) do
            if type(v) == "userdata" then
                return v
            end
        end
    end
    return nil
end


local MultiBot = _G["MultiBot"] or {}
_G["MultiBot"] = MultiBot

local Spec = MultiBot.spec or {}
Spec.currentBuild = {}  -- table pour conserver la build courante de chaque bot (ex : "0-13-58")
Spec.busy = false
Spec.pendingRefresh = nil
MultiBot.spec = Spec

if Spec.initialised then
    return
end
Spec.initialised = true

Spec.pending, Spec.buttons = nil, {}

function Spec:RequestList(bot, wrapper)
    if self.busy then
        return                  --    on ignore le clic
    end
    local frame = unwrapFrame(wrapper)
    if type(frame) ~= "userdata" then
        return
    end

    self:HideDropdown()

    self.pending = {
        bot     = bot,
        anchor  = frame,
        wrapper = wrapper,
        specs   = {},
        builds  = {},
    }
    self.activeWrapper = wrapper
    -- 1) on demande d'abord la spé courante
    SendChatMessage("talents", "WHISPER", nil, bot)
    -- 2) on attend ~0.2s puis on enchaîne sur la liste
    MultiBot.TimerAfter(0.2, function()
        -- si on est toujours sur le même bot, on demande la liste
        if Spec.pending and Spec.pending.bot == bot then
            SendChatMessage("talents spec list", "WHISPER", nil, bot)
            -- print("|cffffff00[SpecDEBUG]|r Message talents spec list envoyé!!!!!!!!!!!!!!!!!")
        end
    end)
end


local function short(name)
    local dash = name:find("-", 1, true)
    return dash and name:sub(1, dash-1) or name
end

local SPEC_DROPDOWN_MIGRATION_VERSION = 1
local SPEC_DROPDOWN_MIGRATION_KEY = "specDropdownPositionsVersion"

local function getLegacySpecDropdownStore(createIfMissing)
    local save = _G.MultiBotSave
    if type(save) ~= "table" then
        if not createIfMissing then
            return nil
        end

        save = {}
        _G.MultiBotSave = save
    end

    local store = save.SpecDropdown
    if type(store) ~= "table" then
        if not createIfMissing then
            return nil
        end

        store = {}
        save.SpecDropdown = store
    end

    return store
end

local function cleanupLegacySpecDropdownStoreIfEmpty()
    local save = _G.MultiBotSave
    if type(save) ~= "table" then
        return
    end

    local store = save.SpecDropdown
    if type(store) == "table" and next(store) == nil then
        save.SpecDropdown = nil
    end
end

local function getSpecDropdownStore()
    if MultiBot.Store and MultiBot.Store.EnsureUIChildStore then
        local store = MultiBot.Store.EnsureUIChildStore("specDropdownPositions")
        if store then
            return store
        end
    end

    local profile = MultiBot.db and MultiBot.db.profile
    if profile then
        profile.ui = profile.ui or {}
        profile.ui.specDropdownPositions = profile.ui.specDropdownPositions or {}
        return profile.ui.specDropdownPositions
    end

    return getLegacySpecDropdownStore(true)
end

local function migrateLegacySpecDropdownPositionsIfNeeded(store)
    if not MultiBot.GetProfileMigrationStore() then
        return
    end

    if not MultiBot.ShouldSyncLegacyState(SPEC_DROPDOWN_MIGRATION_KEY, SPEC_DROPDOWN_MIGRATION_VERSION) then
        return
    end

    local legacyStore = getLegacySpecDropdownStore(false)
    for charKey, pos in pairs(legacyStore or {}) do
        if store[charKey] == nil and pos ~= nil then
            store[charKey] = pos
        end
    end

    MultiBot.MarkLegacyStateMigrated(SPEC_DROPDOWN_MIGRATION_KEY, SPEC_DROPDOWN_MIGRATION_VERSION)

    -- Purge migrated legacy payload to avoid stale duplicate persistence.
    if type(legacyStore) == "table" then
        if wipe then
            wipe(legacyStore)
        else
            for key in pairs(legacyStore) do
                legacyStore[key] = nil
            end
        end
    end

    cleanupLegacySpecDropdownStoreIfEmpty()
end

local function getSpecDropdownPosition(charKey)
    if type(charKey) ~= "string" or charKey == "" then
        return nil
    end

    local store = getSpecDropdownStore()
    migrateLegacySpecDropdownPositionsIfNeeded(store)

    local pos = store[charKey]
    if pos ~= nil then
        return pos
    end

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(SPEC_DROPDOWN_MIGRATION_KEY, SPEC_DROPDOWN_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacySpecDropdownStore(false)
        pos = legacyStore and legacyStore[charKey]
        if pos ~= nil then
            store[charKey] = pos
        end
    end

    return pos
end

local function setSpecDropdownPosition(charKey, position)
    if type(charKey) ~= "string" or charKey == "" or type(position) ~= "table" then
        return
    end

    local store = getSpecDropdownStore()
    migrateLegacySpecDropdownPositionsIfNeeded(store)
    store[charKey] = position

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(SPEC_DROPDOWN_MIGRATION_KEY, SPEC_DROPDOWN_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacySpecDropdownStore(true)
        legacyStore[charKey] = position
    end
end

local function getSpecDropdownCharacterKey()
    return (UnitName("player") or "Player") .. "-" .. (GetRealmName() or "")
end


--------------------------------------------------------------
-- Whisper handler routed by central event dispatcher.
--------------------------------------------------------------
function MultiBot.HandleSpecWhisper(msg, sender)
    if type(msg) ~= "string" or type(sender) ~= "string" then
        return
    end

    ----------------------------------------------------------------
    -- 1) Basic cleanup for the incoming line
    ----------------------------------------------------------------
    local clean = msg
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("\r?\n", " ")

    ----------------------------------------------------------------
    -- 2) "My current talent spec is: … (x/x/x)"
    ----------------------------------------------------------------
    if clean:match("^%s*My current talent spec is:") then
        local inside = clean:match("%(([^%)]+)%)")
        if inside then
            local a, b, c = inside:match("(%d+)[^%d]*(%d+)[^%d]*(%d+)")
            if a and b and c then
                local key = short(sender):lower()
                Spec.currentBuild[key] = a.."-"..b.."-"..c
            end
        end

        ----------------------------------------------------------------
        -- 2-bis) pending refresh
        ----------------------------------------------------------------
        if Spec.pendingRefresh and short(sender) == short(Spec.pendingRefresh) then
            local unit = MultiBot.toUnit(sender)
            if unit then
                if not MultiBot.talent:IsShown() then
                    local _, token = UnitClass(unit)
                    MultiBot.talent.name  = sender
                    MultiBot.talent.class = MultiBot.toClass(token)
                end
                MultiBot.TimerAfter(0.6, function()
                    MultiBot.auto.talent = true
                    InspectUnit(unit)
                    if InspectFrame then HideUIPanel(InspectFrame) end
                    MultiBot.TimerAfter(0.1, function()
                        if MultiBot.talent:IsShown() then MultiBot.talent:Hide() end
                    end)
                end)
            end
            Spec.pendingRefresh = nil
            Spec.busy           = false
        end
        return
    end

    ----------------------------------------------------------------
    -- 3)  Spec list lines: "1) Feral pve (0-60-11)" … "Total …"
    ----------------------------------------------------------------
    local P = Spec.pending
    if not P or short(sender) ~= short(P.bot) then return end

    local name  = clean:match("^%d+[%.%)]?%s*([^%(]+)%s*%(")
                or clean:match("^([^%(]+)%s*%(")
    if name then
        local build = clean:match("%((%d+%-%d+%-%d+)%)")
        tinsert(P.specs,  strtrim(name))
        tinsert(P.builds, strtrim(build))
        return
    end

    local plain = clean:lower()
    if plain:find("total") and plain:find("spec") then
        Spec:BuildDropdown()
        Spec.pending = nil
    end
end


local function getAceGUI()
    if type(LibStub) ~= "table" then
        return nil
    end

    local ok, lib = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
    if ok and type(lib) == "table" and type(lib.Create) == "function" then
        return lib
    end

    return nil
end

local function debugSpecPath(path)
    -- Debug volontairement désactivé : helper conservé pour ne pas toucher les callsites.
    return path
end

local function disableSetTalentsToggle(wrapper)
    if type(wrapper) ~= "table" then
        return
    end

    if type(wrapper.setDisable) == "function" then
        wrapper:setDisable()
    end
end

function Spec:HideDropdown()
    disableSetTalentsToggle(self.activeWrapper)
    self.activeWrapper = nil

    if self.dropdownWidget and type(self.dropdownWidget.Release) == "function" then
        self.dropdownWidget:Release()
        self.dropdownWidget = nil
    end

    if self.dropdown then
        self.dropdown:Hide()
        self.dropdown:SetParent(nil)
        self.dropdown = nil
    end

    for _, b in ipairs(self.buttons) do
        b:Hide()
        b:SetParent(nil)
    end
    wipe(self.buttons)
end

local function ensureDropdownFrame(specObject, parentFrame, isEmbedded)
    local frame = specObject.dropdown
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", nil, parentFrame or UIParent)

    if isEmbedded then
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            frame:SetFrameStrata(strataLevel)
        end
        frame:SetFrameLevel((parentFrame and parentFrame:GetFrameLevel() or 1) + 5)
        frame:SetAllPoints(parentFrame)
    else
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            frame:SetFrameStrata(strataLevel)
        end
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile     = true, tileSize = 16,
                edgeSize = 16,
                insets   = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            frame:SetBackdropColor(0, 0, 0, 0.8)
        end

        if not frame._mb_movable_init then
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            frame:SetClampedToScreen(true)
            frame:SetScript("OnDragStart", frame.StartMoving)
            frame:SetScript("OnDragStop", function(activeFrame)
                activeFrame:StopMovingOrSizing()
                local cx, cy = activeFrame:GetCenter()
                local ux, uy = UIParent:GetCenter()
                local dx, dy = (cx - ux), (cy - uy)
                local charKey = getSpecDropdownCharacterKey()
                setSpecDropdownPosition(charKey, { point = "CENTER", x = dx, y = dy })
            end)
            frame._mb_movable_init = true
        end
    end

    specObject.dropdown = frame
    return frame
end

local function applyDropdownPosition(frame, anchor, isEmbedded)
    if isEmbedded then
        return
    end

    frame:ClearAllPoints()

    local restored = false
    local charKey = getSpecDropdownCharacterKey()
    local pos = getSpecDropdownPosition(charKey)
    if type(pos) == "table" and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x or 0, pos.y or 0)
        restored = true
    end

    if not restored then
        frame:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
    end
end

local function bindSpecSelection(button, spec, build, tip, bot, className, currentBuild)
    if build == currentBuild then
        button:SetAlpha(0.4)
        local tex = button:GetNormalTexture()
        if tex and tex.SetDesaturated then
            tex:SetDesaturated(true)
        end
        button:SetScript("OnClick", nil)
    else
        button:SetAlpha(1)
        button:SetScript("OnClick", function(_, btn)
            if Spec.busy then
                return
            end
            Spec.busy = true

            SendChatMessage("stopcasting", "WHISPER", nil, bot)

            local slot = (btn == "RightButton") and 2 or 1
            SendChatMessage("talents switch " .. slot, "WHISPER", nil, bot)

            MultiBot.TimerAfter(0.4, function()
                SendChatMessage("talents spec " .. spec, "WHISPER", nil, bot)
            end)

            Spec.pendingRefresh = bot
            Spec:HideDropdown()

            MultiBot.TimerAfter(1.3, function()
                if Spec.pendingRefresh and Spec.pendingRefresh == bot then
                    local unit = MultiBot.toUnit(bot)

                    if unit then
                        if not MultiBot.talent:IsShown() then
                            MultiBot.talent.name = bot
                            MultiBot.talent.class = className
                        end

                        MultiBot.TimerAfter(0.6, function()
                            MultiBot.auto.talent = true
                            InspectUnit(unit)

                            if InspectFrame then
                                HideUIPanel(InspectFrame)
                            end

                            MultiBot.TimerAfter(0.1, function()
                                if MultiBot.talent:IsShown() then
                                    MultiBot.talent:Hide()
                                end
                            end)
                        end)
                    end

                    Spec.pendingRefresh = nil
                    Spec.busy = false
                end
            end)
        end)
    end

    button:SetScript("OnEnter", function(activeButton)
        GameTooltip:SetOwner(activeButton, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("LEFT", activeButton, "RIGHT", 30, 0)
        GameTooltip:SetText(tip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

function Spec:BuildDropdown()
    if self.busy then
        return
    end

    local pending = self.pending
    if not pending or #pending.specs == 0 then
        return
    end

    local botKey = short(pending.bot):lower()
    local currentBuild = Spec.currentBuild[botKey]

    local aceGUI = getAceGUI()
    local dropdownFrame
    local embeddedInWindow = false

    if aceGUI then
        local widget = aceGUI:Create("Window")
        if widget and widget.frame and widget.content then
            local title = "Set talents"
            if MultiBot and type(MultiBot.L) == "function" then
                local localized = MultiBot.L("spec.list.title", title)
                if localized and localized ~= "" and localized ~= "spec.list.title" then
                    title = localized
                end
            end

            widget:SetTitle(title)
            widget:SetWidth(92)
            widget:SetHeight((#pending.specs * 37) + 40)
            widget:EnableResize(false)
            local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
            if strataLevel then
                widget.frame:SetFrameStrata(strataLevel)
            end

            local function saveWindowPosition()
                local cx, cy = widget.frame:GetCenter()
                local ux, uy = UIParent:GetCenter()
                if cx and cy and ux and uy then
                    setSpecDropdownPosition(getSpecDropdownCharacterKey(), {
                        point = "CENTER",
                        x = cx - ux,
                        y = cy - uy,
                    })
                end
            end

            if widget.title and type(widget.title.HookScript) == "function" then
                widget.title:HookScript("OnMouseUp", saveWindowPosition)
            end

            widget:SetCallback("OnClose", function()
                saveWindowPosition()
                Spec:HideDropdown()
            end)
            self.dropdownWidget = widget

            local frame = ensureDropdownFrame(self, widget.content, true)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", widget.content, "TOPLEFT", 0, 0)
            frame:SetPoint("BOTTOMRIGHT", widget.content, "BOTTOMRIGHT", 0, 0)

            local pos = getSpecDropdownPosition(getSpecDropdownCharacterKey())
            widget.frame:ClearAllPoints()
            if type(pos) == "table" and pos.point then
                widget.frame:SetPoint(pos.point, UIParent, pos.point, pos.x or 0, pos.y or 0)
            else
                widget.frame:SetPoint("TOP", pending.anchor, "BOTTOM", 0, -4)
            end

            dropdownFrame = frame
            embeddedInWindow = true
            debugSpecPath("AceGUI")
        end
    end

	if not dropdownFrame then
        dropdownFrame = ensureDropdownFrame(self, UIParent, false)
        debugSpecPath("legacy")
    end

    applyDropdownPosition(dropdownFrame, pending.anchor, embeddedInWindow)

    local step = 37
    local needed = #pending.specs
    while #self.buttons < needed do
        local button = CreateFrame("Button", nil, dropdownFrame)
        button:RegisterForClicks("AnyUp")
        button:SetFrameLevel(dropdownFrame:GetFrameLevel() + 1)
        button:SetSize(32, 32)
        button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
        if strataLevel then
            button:SetFrameStrata(strataLevel)
        end
        table.insert(self.buttons, button)
    end

    local alreadyMarked = false
    for index, button in ipairs(self.buttons) do
        if index <= needed then
            local specName = pending.specs[index]
            local build = pending.builds[index]

            button:ClearAllPoints()
            if index == 1 then
                button:SetPoint("TOP", dropdownFrame, "TOP", 0, -4)
            else
                button:SetPoint("TOP", self.buttons[index - 1], "BOTTOM", 0, -4)
            end

            local mode = specName:lower():find("pvp") and "pvp" or "pve"
            local prefix = (specName:match("^[^%s]+") or ""):lower()
            local canonicalSpec = specCanonical[prefix] or prefix:gsub("^%l", string.upper)
            local className = pending.wrapper:getClass():gsub("^%l", string.upper)
            local entry = (((specIconMap[className] or {})[canonicalSpec] or {})[mode]) or {}
            local icon = entry.icon or defaultIcon
            local tip = entry.tip or specName

            button:SetNormalTexture(icon)
            button:SetDisabledTexture(icon)
            button:Show()

            if (not alreadyMarked) and build == currentBuild then
                alreadyMarked = true
                bindSpecSelection(button, specName, build, tip, pending.bot, className, currentBuild)
            else
                bindSpecSelection(button, specName, build, tip, pending.bot, className, nil)
            end
        else
            button:Hide()
        end
    end

    dropdownFrame:SetWidth(40)
    dropdownFrame:SetHeight(needed * step)
    if self.dropdownWidget and type(self.dropdownWidget.SetHeight) == "function" then
        self.dropdownWidget:SetHeight((needed * step) + 40)
    end
    dropdownFrame:Show()
end