MultiBot = CreateFrame("Frame", nil, UIParent)

local function ensureValue(root, key, defaultValue)
  if root[key] == nil then
    root[key] = defaultValue
  end
  return root[key]
end

local aceConsole = LibStub and LibStub("AceConsole-3.0", true)
local aceAddon = LibStub and LibStub("AceAddon-3.0", true)
if aceConsole then
  aceConsole:Embed(MultiBot)
end

ensureValue(MultiBot, "_registeredCommands", {})
ensureValue(MultiBot, "_coreEventsRegistered", false)
ensureValue(MultiBot, "_initEventsRegistered", false)

local CORE_EVENTS = {
  "WORLD_MAP_UPDATE",
  "PLAYER_ENTERING_WORLD",
  "GROUP_ROSTER_UPDATE",
  "PARTY_MEMBERS_CHANGED",
  "RAID_ROSTER_UPDATE",
  "UNIT_PET",
  "PLAYER_TARGET_CHANGED",
  "PLAYER_LOGOUT",
  "CHAT_MSG_WHISPER",
  "CHAT_MSG_SYSTEM",
  "CHAT_MSG_ADDON",
  "CHAT_MSG_LOOT",
  "QUEST_COMPLETE",
  "QUEST_LOG_UPDATE",
  "TRADE_CLOSED",
  "INSPECT_READY",
  "CHAT_MSG_PARTY",
  "CHAT_MSG_RAID",
}

local INIT_EVENTS = { "ADDON_LOADED" }
local LIFECYCLE_BRIDGE_NAME = "MultiBotLifecycleBridge"

local function normalizeTextToken(value)
  if type(value) ~= "string" then return nil end
  local cleaned = value:gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then return nil end
  return cleaned
end

local function normalizeAlias(alias)
  local cleaned = normalizeTextToken(alias)
  if not cleaned then return nil end
  cleaned = cleaned:gsub("^/+", "")
  if cleaned == "" then return nil end
  return string.upper(cleaned)
end

local function normalizeCommandName(name)
  local cleaned = normalizeTextToken(tostring(name or "MULTIBOT")) or "MULTIBOT"
  return string.upper(cleaned)
end

local function registerNativeSlashAlias(commandName, aliasIndex, lowerAlias, handler)
  _G["SLASH_" .. commandName .. tostring(aliasIndex)] = "/" .. lowerAlias
  SlashCmdList = SlashCmdList or {}
  SlashCmdList[commandName] = handler
end

local function createAliasRegistrar(commandName, handler, registerWithAce)
  if registerWithAce then
    return function(aliasIndex, normalizedAlias)
      MultiBot:RegisterChatCommand(string.lower(normalizedAlias), handler)
    end
  end

  return function(aliasIndex, normalizedAlias)
    registerNativeSlashAlias(commandName, aliasIndex, string.lower(normalizedAlias), handler)
  end
end

local function collectNormalizedAliases(aliases)
  local normalizedAliases = {}
  local seen = {}

  for _, alias in ipairs(aliases) do
    local normalized = normalizeAlias(alias)
    if normalized and not seen[normalized] then
      seen[normalized] = true
      normalizedAliases[#normalizedAliases + 1] = normalized
    end
  end

  return normalizedAliases
end

local function buildCommandRegistrationContext(name, handler, aliases)
  if type(handler) ~= "function" or type(aliases) ~= "table" then
    return nil
  end

  local commandName = normalizeCommandName(name)
  local registeredAliases = ensureValue(MultiBot._registeredCommands, commandName, {})

  local registerAlias = createAliasRegistrar(commandName, handler, type(MultiBot.RegisterChatCommand) == "function")

  return {
    commandName = commandName,
    aliases = collectNormalizedAliases(aliases),
    registeredAliases = registeredAliases,
    registerAlias = registerAlias,
  }
end

local function registerCommandAliasesFromContext(context)
  for aliasIndex, normalized in ipairs(context.aliases) do
    if not context.registeredAliases[normalized] then
      context.registerAlias(aliasIndex, normalized)
      context.registeredAliases[normalized] = true
    end
  end
end

function MultiBot.RegisterCommandAliases(name, handler, aliases)
  local context = buildCommandRegistrationContext(name, handler, aliases)
  if not context then return end
  registerCommandAliasesFromContext(context)
end

local MAIN_VISIBILITY_EXCLUDED_FRAMES = {
  ShamanQuick = true,
  HunterQuick = true,
}

function MultiBot.ShouldAffectMainVisibility(frameKey)
  return not MAIN_VISIBILITY_EXCLUDED_FRAMES[frameKey]
end

local function setFrameVisibility(frame, visible)
  if not frame or not frame.Show or not frame.Hide then return end
  if visible then
    frame:Show()
  else
    frame:Hide()
  end
end

local function applyMainVisibility(frames, visible)
  for frameKey, frame in pairs(frames or {}) do
    if MultiBot.ShouldAffectMainVisibility(frameKey) then
      setFrameVisibility(frame, visible)
    end
  end
end

local function ensureSavedVariables()
  MultiBotSave = ensureValue(_G, "MultiBotSave", {})
  MultiBotGlobalSave = ensureValue(_G, "MultiBotGlobalSave", {})
  return MultiBotSave, MultiBotGlobalSave
end

local MINIMAP_CONFIG_MIGRATION_VERSION = 1
local STRATA_LEVEL_MIGRATION_VERSION = 1
local MAIN_VISIBLE_MIGRATION_VERSION = 1
local QUICK_FRAME_POSITIONS_MIGRATION_VERSION = 1
local HUNTER_PET_STANCE_MIGRATION_VERSION = 1
local FAVORITES_MIGRATION_VERSION = 1
local GLOBAL_BOT_STORE_MIGRATION_VERSION = 1

local GLOBAL_BOT_STORE_MIGRATION_KEY = "globalBotStoreVersion"
local MINIMAP_CONFIG_MIGRATION_KEY = "minimapConfigVersion"
local STRATA_LEVEL_MIGRATION_KEY = "strataLevelVersion"
local MAIN_VISIBLE_MIGRATION_KEY = "mainVisibleVersion"
local QUICK_FRAME_POSITIONS_MIGRATION_KEY = "quickFramePositionsVersion"
local HUNTER_PET_STANCE_MIGRATION_KEY = "hunterPetStanceVersion"
local FAVORITES_MIGRATION_KEY = "favoritesVersion"

local function getUiMigrationStore()
  if not (MultiBot.Store and MultiBot.Store.GetMigrationStore) then
    return nil
  end
  return MultiBot.Store.GetMigrationStore()
end

local function shouldSyncLegacyUiState(versionKey, targetVersion)
  local migrations = getUiMigrationStore()
  if not migrations then
    return true
  end

  local version = migrations[versionKey]
  return type(version) ~= "number" or version < targetVersion
end

local function markLegacyUiStateMigrated(versionKey, targetVersion)
  local migrations = MultiBot.Store and MultiBot.Store.EnsureMigrationStore and MultiBot.Store.EnsureMigrationStore()
  if not migrations then
    return
  end

  migrations[versionKey] = targetVersion
end

function MultiBot.GetProfileMigrationStore()
  return getUiMigrationStore()
end

function MultiBot.ShouldSyncLegacyState(versionKey, targetVersion)
  return shouldSyncLegacyUiState(versionKey, targetVersion)
end

function MultiBot.MarkLegacyStateMigrated(versionKey, targetVersion)
  markLegacyUiStateMigrated(versionKey, targetVersion)
end

local function getLegacyGlobalBotStore()
  local _, globalSave = ensureSavedVariables()
  return globalSave
end

local function isGlobalBotRosterEntry(value)
  return MultiBot.Store
    and MultiBot.Store.IsValidGlobalBotRosterEntry
    and MultiBot.Store.IsValidGlobalBotRosterEntry(value)
end

local function migrateLegacyGlobalBotStoreIfNeeded(store, legacyStore)
  if not store or not shouldSyncLegacyUiState(GLOBAL_BOT_STORE_MIGRATION_KEY, GLOBAL_BOT_STORE_MIGRATION_VERSION) then
    return
  end

  for botName, value in pairs(legacyStore or {}) do
    if store[botName] == nil and isGlobalBotRosterEntry(value) then
      store[botName] = value
    end
  end

  markLegacyUiStateMigrated(GLOBAL_BOT_STORE_MIGRATION_KEY, GLOBAL_BOT_STORE_MIGRATION_VERSION)

  -- Purge migrated legacy global bot entries without touching unrelated global keys.
  for botName, value in pairs(legacyStore or {}) do
    if isGlobalBotRosterEntry(value) then
      legacyStore[botName] = nil
    end
  end
end

function MultiBot.GetGlobalBotStore()
  local legacyStore = getLegacyGlobalBotStore()
  local store = MultiBot.Store and MultiBot.Store.GetBotsStore and MultiBot.Store.GetBotsStore()
  if not store and shouldSyncLegacyUiState(GLOBAL_BOT_STORE_MIGRATION_KEY, GLOBAL_BOT_STORE_MIGRATION_VERSION) then
    for _, value in pairs(legacyStore or {}) do
      if isGlobalBotRosterEntry(value) then
        store = MultiBot.Store and MultiBot.Store.EnsureBotsStore and MultiBot.Store.EnsureBotsStore()
        break
      end
    end
  end
  if store then
    migrateLegacyGlobalBotStoreIfNeeded(store, legacyStore)
    MultiBot.Store.SanitizeGlobalBotStore(store)
    return store
  end

  return legacyStore
end

function MultiBot.SetGlobalBotEntry(name, value)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  if not isGlobalBotRosterEntry(value) then
    return nil
  end

  local store = MultiBot.Store and MultiBot.Store.EnsureBotsStore and MultiBot.Store.EnsureBotsStore()
  if not store then
    store = getLegacyGlobalBotStore()
  end
  store[name] = value

  if shouldSyncLegacyUiState(GLOBAL_BOT_STORE_MIGRATION_KEY, GLOBAL_BOT_STORE_MIGRATION_VERSION) then
    local legacyStore = getLegacyGlobalBotStore()
    legacyStore[name] = value
  end

  return value
end

function MultiBot.ClearGlobalBotStore()
  local store = MultiBot.Store and MultiBot.Store.EnsureBotsStore and MultiBot.Store.EnsureBotsStore()
  if not store then
    store = getLegacyGlobalBotStore()
  end
  if wipe then
    wipe(store)
  else
    for key in pairs(store) do
      store[key] = nil
    end
  end

  if shouldSyncLegacyUiState(GLOBAL_BOT_STORE_MIGRATION_KEY, GLOBAL_BOT_STORE_MIGRATION_VERSION) then
    local legacyStore = getLegacyGlobalBotStore()
    if wipe then
      wipe(legacyStore)
    else
      for key in pairs(legacyStore) do
        legacyStore[key] = nil
      end
    end
  end
end

local MINIMAP_CONFIG_DEFAULTS = {
  hide = false,
  angle = 220,
}

local function getLegacyMinimapConfig(createIfMissing)
  local save = ensureSavedVariables()
  local minimap = save.Minimap

  if type(minimap) ~= "table" then
    if not createIfMissing then
      return nil
    end

    minimap = {}
    save.Minimap = minimap
  end

  if type(minimap.hide) ~= "boolean" then
    minimap.hide = MINIMAP_CONFIG_DEFAULTS.hide
  end
  if type(minimap.angle) ~= "number" then
    minimap.angle = MINIMAP_CONFIG_DEFAULTS.angle
  end

  return save.Minimap
end

function MultiBot.GetMinimapConfig()
  local minimap = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("minimap")
  local legacy = getLegacyMinimapConfig(false)

  if not minimap and shouldSyncLegacyUiState(MINIMAP_CONFIG_MIGRATION_KEY, MINIMAP_CONFIG_MIGRATION_VERSION) and legacy then
    minimap = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("minimap")
  end
  if minimap then
    if shouldSyncLegacyUiState(MINIMAP_CONFIG_MIGRATION_KEY, MINIMAP_CONFIG_MIGRATION_VERSION) then
      if type(minimap.hide) ~= "boolean" then
        minimap.hide = (legacy and legacy.hide) or MINIMAP_CONFIG_DEFAULTS.hide
      end
      if type(minimap.angle) ~= "number" then
        minimap.angle = (legacy and legacy.angle) or MINIMAP_CONFIG_DEFAULTS.angle
      end
      markLegacyUiStateMigrated(MINIMAP_CONFIG_MIGRATION_KEY, MINIMAP_CONFIG_MIGRATION_VERSION)

      -- Purge migrated legacy minimap payload to avoid stale duplicate persistence.
      local save = ensureSavedVariables()
      save.Minimap = nil
    end

    if type(minimap.hide) ~= "boolean" then
      minimap.hide = MINIMAP_CONFIG_DEFAULTS.hide
    end
    if type(minimap.angle) ~= "number" then
      minimap.angle = MINIMAP_CONFIG_DEFAULTS.angle
    end
    return minimap
  end

  return legacy or { hide = MINIMAP_CONFIG_DEFAULTS.hide, angle = MINIMAP_CONFIG_DEFAULTS.angle }
end

function MultiBot.SetMinimapConfig(key, value)
  local minimap = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("minimap")
  if not minimap then
    minimap = getLegacyMinimapConfig(true)
  end
  minimap[key] = value

  if shouldSyncLegacyUiState(MINIMAP_CONFIG_MIGRATION_KEY, MINIMAP_CONFIG_MIGRATION_VERSION) then
    local legacy = getLegacyMinimapConfig(true)
    legacy[key] = value
  end

  return minimap
end

local STRATA_LEVEL_DEFAULT = "HIGH"

local function getLegacyGlobalStrataLevel(createIfMissing)
  local _, globalSave = ensureSavedVariables()
  local value = globalSave["Strata.Level"]
  if type(value) ~= "string" or value == "" then
    if not createIfMissing then
      return nil
    end

    value = STRATA_LEVEL_DEFAULT
    globalSave["Strata.Level"] = value
  end

  return value
end

function MultiBot.GetGlobalStrataLevel()
  local strata = MultiBot.Store and MultiBot.Store.GetUIValue and MultiBot.Store.GetUIValue("strataLevel")
  if MultiBot.Store and MultiBot.Store.GetUIStore and MultiBot.Store.GetUIStore() then
    if shouldSyncLegacyUiState(STRATA_LEVEL_MIGRATION_KEY, STRATA_LEVEL_MIGRATION_VERSION) then
      local legacyLevel = getLegacyGlobalStrataLevel(false)
      if (type(strata) ~= "string" or strata == "") and legacyLevel then
        strata = MultiBot.Store.SetUIValue and MultiBot.Store.SetUIValue("strataLevel", legacyLevel)
      end
      markLegacyUiStateMigrated(STRATA_LEVEL_MIGRATION_KEY, STRATA_LEVEL_MIGRATION_VERSION)

      -- Purge migrated legacy strata key to avoid stale duplicate persistence.
      local _, globalSave = ensureSavedVariables()
      globalSave["Strata.Level"] = nil
    end
    if type(strata) ~= "string" or strata == "" then
      strata = STRATA_LEVEL_DEFAULT
    end
    return strata
  end

  return getLegacyGlobalStrataLevel(false) or STRATA_LEVEL_DEFAULT
end

function MultiBot.SetGlobalStrataLevel(level)
  if type(level) ~= "string" or level == "" then
    level = STRATA_LEVEL_DEFAULT
  end

  if shouldSyncLegacyUiState(STRATA_LEVEL_MIGRATION_KEY, STRATA_LEVEL_MIGRATION_VERSION) then
    local _, globalSave = ensureSavedVariables()
    globalSave["Strata.Level"] = level
  end

  if MultiBot.Store and MultiBot.Store.SetUIValue then
    MultiBot.Store.SetUIValue("strataLevel", level)
  end

  return level
end

local function callIfFunction(fn, ...)
  if type(fn) == "function" then
    return fn(...)
  end
end

local function callMethodIfFunction(target, methodName, passSelf, ...)
  local fn = target and target[methodName]
  if passSelf then
    return callIfFunction(fn, target, ...)
  end
  return callIfFunction(fn, ...)
end

local MAIN_UI_VISIBLE_DEFAULT = true

local function getLegacyMainUIVisible(createIfMissing)
  local save = ensureSavedVariables()
  local value = save["UIVisible"]
  if type(value) ~= "boolean" then
    if not createIfMissing then
      return nil
    end

    value = MAIN_UI_VISIBLE_DEFAULT
    save["UIVisible"] = value
  end

  return value
end

function MultiBot.GetMainUIVisibleConfig()
  local uiStore = MultiBot.Store and MultiBot.Store.GetUIStore and MultiBot.Store.GetUIStore()
  local visible = MultiBot.Store and MultiBot.Store.GetUIValue and MultiBot.Store.GetUIValue("mainVisible")
  if uiStore then
    if shouldSyncLegacyUiState(MAIN_VISIBLE_MIGRATION_KEY, MAIN_VISIBLE_MIGRATION_VERSION) then
      if type(visible) ~= "boolean" then
        local legacyValue = getLegacyMainUIVisible(false)
        if type(legacyValue) == "boolean" then
          visible = MultiBot.Store.SetUIValue and MultiBot.Store.SetUIValue("mainVisible", legacyValue)
        end
      end
      markLegacyUiStateMigrated(MAIN_VISIBLE_MIGRATION_KEY, MAIN_VISIBLE_MIGRATION_VERSION)

      -- Purge migrated legacy main UI visibility key to avoid stale duplicate persistence.
      local save = ensureSavedVariables()
      save["UIVisible"] = nil
    end
    if type(visible) ~= "boolean" then
      visible = MAIN_UI_VISIBLE_DEFAULT
    end
    return visible
  end

  return getLegacyMainUIVisible(false) or MAIN_UI_VISIBLE_DEFAULT
end

function MultiBot.SetMainUIVisibleConfig(value)
  local visible = not not value
  if shouldSyncLegacyUiState(MAIN_VISIBLE_MIGRATION_KEY, MAIN_VISIBLE_MIGRATION_VERSION) then
    local save = ensureSavedVariables()
    save["UIVisible"] = visible
  end

  if MultiBot.Store and MultiBot.Store.SetUIValue then
    MultiBot.Store.SetUIValue("mainVisible", visible)
  end

  return visible
end

local function getLegacyCharacterStateRoot(createIfMissing)
  local saved = _G.MultiBotSaved
  if type(saved) ~= "table" then
    if not createIfMissing then
      return nil
    end

    saved = {}
    _G.MultiBotSaved = saved
  end

  return saved
end

local function cleanupLegacyCharacterStateKey(key)
  if type(key) ~= "string" or key == "" then
    return
  end

  local saved = getLegacyCharacterStateRoot(false)
  if type(saved) ~= "table" then
    return
  end

  local value = saved[key]
  if type(value) == "table" and next(value) == nil then
    saved[key] = nil
  end

  if next(saved) == nil then
    _G.MultiBotSaved = nil
  end
end

local function getLegacyQuickFramePositionStore(createIfMissing)
  local saved = getLegacyCharacterStateRoot(createIfMissing)
  local pos = saved and saved.pos

  if type(pos) ~= "table" then
    if not createIfMissing then
      return nil
    end

    pos = {}
    saved.pos = pos
  end

  return pos
end

local function migrateLegacyQuickFramePositionsIfNeeded(store, legacyStore)
  if not store or not shouldSyncLegacyUiState(QUICK_FRAME_POSITIONS_MIGRATION_KEY, QUICK_FRAME_POSITIONS_MIGRATION_VERSION) then
    return
  end

  for frameKey, legacyEntry in pairs(legacyStore or {}) do
    local legacyFrame = legacyEntry and legacyEntry.frame
    if store[frameKey] == nil and legacyFrame ~= nil then
      store[frameKey] = legacyFrame
    end
  end

  local migrations = getUiMigrationStore()
  if migrations then
    migrations[QUICK_FRAME_POSITIONS_MIGRATION_KEY] = QUICK_FRAME_POSITIONS_MIGRATION_VERSION
  end

  -- Purge migrated legacy quick-frame payload to avoid stale duplicate persistence.
  if type(legacyStore) == "table" then
    if wipe then
      wipe(legacyStore)
    else
      for key in pairs(legacyStore) do
        legacyStore[key] = nil
      end
    end
  end

  cleanupLegacyCharacterStateKey("pos")
end

function MultiBot.GetQuickFramePosition(frameKey)
  if type(frameKey) ~= "string" or frameKey == "" then
    return nil
  end

  local legacyPosStore = getLegacyQuickFramePositionStore(false)
  local store = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("quickFramePositions")
  if not store and shouldSyncLegacyUiState(QUICK_FRAME_POSITIONS_MIGRATION_KEY, QUICK_FRAME_POSITIONS_MIGRATION_VERSION) and legacyPosStore then
    store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("quickFramePositions")
  end
  if store then
    migrateLegacyQuickFramePositionsIfNeeded(store, legacyPosStore)

    local pos = store[frameKey]
    if pos == nil and shouldSyncLegacyUiState(QUICK_FRAME_POSITIONS_MIGRATION_KEY, QUICK_FRAME_POSITIONS_MIGRATION_VERSION) then
      local legacyFrame = legacyPosStore and legacyPosStore[frameKey] and legacyPosStore[frameKey].frame
      if legacyFrame ~= nil then
        store[frameKey] = legacyFrame
        pos = legacyFrame
      end
    end

    return pos
  end

  return legacyPosStore and legacyPosStore[frameKey] and legacyPosStore[frameKey].frame
end

function MultiBot.SetQuickFramePosition(frameKey, point, relPoint, x, y)
  if type(frameKey) ~= "string" or frameKey == "" then
    return nil
  end

  local position = {
    point = point,
    relPoint = relPoint,
    x = x,
    y = y,
  }

  local legacyPosStore = getLegacyQuickFramePositionStore(false)
  local store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("quickFramePositions")
  if store then
    migrateLegacyQuickFramePositionsIfNeeded(store, legacyPosStore)
    store[frameKey] = position
  end

  if shouldSyncLegacyUiState(QUICK_FRAME_POSITIONS_MIGRATION_KEY, QUICK_FRAME_POSITIONS_MIGRATION_VERSION) then
    legacyPosStore = legacyPosStore or getLegacyQuickFramePositionStore(true)
    local legacyEntry
    if MultiBot.Store and MultiBot.Store.EnsureTableField then
      legacyEntry = MultiBot.Store.EnsureTableField(legacyPosStore, frameKey, {})
    else
      legacyEntry = legacyPosStore[frameKey]
      if type(legacyEntry) ~= "table" then
        legacyEntry = {}
        legacyPosStore[frameKey] = legacyEntry
      end
    end
    legacyEntry.frame = position
  end

  return position
end

function MultiBot.GetQuickFrameVisibleConfig(frameKey)
  if type(frameKey) ~= "string" or frameKey == "" then
    return true
  end

  local store = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("quickFrameVisibility")
  if not store then
    return true
  end

  local value = store[frameKey]
  if type(value) ~= "boolean" then
    store[frameKey] = true
    return true
  end

  return value
end

function MultiBot.SetQuickFrameVisibleConfig(frameKey, visible)
  if type(frameKey) ~= "string" or frameKey == "" then
    return true
  end

  local value = not not visible
  local store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("quickFrameVisibility")
  if store then
    store[frameKey] = value
  end

  return value
end

local function getLegacyHunterPetStanceStore(createIfMissing)
  local saved = getLegacyCharacterStateRoot(createIfMissing)
  local store = saved and saved.hunterPetStance

  if type(store) ~= "table" then
    if not createIfMissing then
      return nil
    end

    store = {}
    saved.hunterPetStance = store
  end

  return store
end

local function migrateLegacyHunterPetStanceIfNeeded(store, legacyStore)
  if not store or not shouldSyncLegacyUiState(HUNTER_PET_STANCE_MIGRATION_KEY, HUNTER_PET_STANCE_MIGRATION_VERSION) then
    return
  end

  for botName, stance in pairs(legacyStore or {}) do
    if store[botName] == nil and stance ~= nil then
      store[botName] = stance
    end
  end

  local migrations = getUiMigrationStore()
  if migrations then
    migrations[HUNTER_PET_STANCE_MIGRATION_KEY] = HUNTER_PET_STANCE_MIGRATION_VERSION
  end

  -- Purge migrated legacy hunter-pet stance payload to avoid stale duplicate persistence.
  if type(legacyStore) == "table" then
    if wipe then
      wipe(legacyStore)
    else
      for key in pairs(legacyStore) do
        legacyStore[key] = nil
      end
    end
  end

  cleanupLegacyCharacterStateKey("hunterPetStance")
end

function MultiBot.GetHunterPetStance(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local legacyStore = getLegacyHunterPetStanceStore(false)
  local store = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("hunterPetStance")
  if not store and shouldSyncLegacyUiState(HUNTER_PET_STANCE_MIGRATION_KEY, HUNTER_PET_STANCE_MIGRATION_VERSION) and legacyStore then
    store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("hunterPetStance")
  end
  if store then
    migrateLegacyHunterPetStanceIfNeeded(store, legacyStore)

    local value = store[name]
    if value == nil and shouldSyncLegacyUiState(HUNTER_PET_STANCE_MIGRATION_KEY, HUNTER_PET_STANCE_MIGRATION_VERSION) then
      value = legacyStore and legacyStore[name]
      if value ~= nil then
        store[name] = value
      end
    end

    return value
  end

  return legacyStore and legacyStore[name]
end

function MultiBot.SetHunterPetStance(name, stance)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local legacyStore = getLegacyHunterPetStanceStore(false)
  local store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("hunterPetStance")
  if store then
    migrateLegacyHunterPetStanceIfNeeded(store, legacyStore)
    store[name] = stance
  end

  if shouldSyncLegacyUiState(HUNTER_PET_STANCE_MIGRATION_KEY, HUNTER_PET_STANCE_MIGRATION_VERSION) then
    legacyStore = legacyStore or getLegacyHunterPetStanceStore(true)
    legacyStore[name] = stance
  end

  return stance
end

local SHAMAN_TOTEMS_MIGRATION_VERSION = 1

local function getLegacyShamanTotemsStore(createIfMissing)
  local saved = getLegacyCharacterStateRoot(createIfMissing)
  local store = saved and saved.shamanTotems

  if type(store) ~= "table" then
    if not createIfMissing then
      return nil
    end

    store = {}
    saved.shamanTotems = store
  end

  return store
end

local function getShamanTotemsStore(createLegacyIfMissing)
  local store
  if createLegacyIfMissing then
    store = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("shamanTotems")
  else
    store = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("shamanTotems")
  end
  if store then
    return store, true
  end

  return getLegacyShamanTotemsStore(createLegacyIfMissing), false
end

local function getShamanTotemsMigrationStore()
  if not (MultiBot.Store and MultiBot.Store.EnsureMigrationStore) then
    return nil
  end
  return MultiBot.Store.EnsureMigrationStore()
end

local function shouldSyncLegacyShamanTotems()
  local migrationStore = getShamanTotemsMigrationStore()
  if not migrationStore then
    return true
  end

  local version = migrationStore.shamanTotemsVersion
  return type(version) ~= "number" or version < SHAMAN_TOTEMS_MIGRATION_VERSION
end

local function migrateLegacyShamanTotemsIfNeeded(store)
  local migrationStore = getShamanTotemsMigrationStore()
  if not migrationStore then
    return
  end

  local version = migrationStore.shamanTotemsVersion
  if type(version) == "number" and version >= SHAMAN_TOTEMS_MIGRATION_VERSION then
    return
  end

  local legacyStore = getLegacyShamanTotemsStore(false)
  for botName, perBot in pairs(legacyStore or {}) do
    if store[botName] == nil and perBot ~= nil then
      store[botName] = perBot
    end
  end

  migrationStore.shamanTotemsVersion = SHAMAN_TOTEMS_MIGRATION_VERSION

  -- Purge migrated legacy shaman-totems payload to avoid stale duplicate persistence.
  if type(legacyStore) == "table" then
    if wipe then
      wipe(legacyStore)
    else
      for key in pairs(legacyStore) do
        legacyStore[key] = nil
      end
    end
  end

  cleanupLegacyCharacterStateKey("shamanTotems")
end

function MultiBot.GetShamanTotemsForBot(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local store = getShamanTotemsStore(false)
  migrateLegacyShamanTotemsIfNeeded(store)

  local perBot = store and store[name]
  if perBot ~= nil then
    return perBot
  end

  if shouldSyncLegacyShamanTotems() then
    local legacyStore = getLegacyShamanTotemsStore(false)
    perBot = legacyStore and legacyStore[name]
    if perBot ~= nil then
      if store then
        store[name] = perBot
      end
    end
  end

  return perBot
end

function MultiBot.SetShamanTotemChoice(name, elementKey, icon)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  if type(elementKey) ~= "string" or elementKey == "" then
    return nil
  end

  local store = getShamanTotemsStore(true)
  migrateLegacyShamanTotemsIfNeeded(store)
  if not store then
    return nil
  end
  local botStore
  if MultiBot.Store and MultiBot.Store.EnsureTableField then
    botStore = MultiBot.Store.EnsureTableField(store, name, {})
  else
    botStore = store[name]
    if type(botStore) ~= "table" then
      botStore = {}
      store[name] = botStore
    end
  end
  botStore[elementKey] = icon

  if shouldSyncLegacyShamanTotems() then
    local legacyStore = getLegacyShamanTotemsStore(true)
    local legacyBotStore
    if MultiBot.Store and MultiBot.Store.EnsureTableField then
      legacyBotStore = MultiBot.Store.EnsureTableField(legacyStore, name, {})
    else
      legacyBotStore = legacyStore[name]
      if type(legacyBotStore) ~= "table" then
        legacyBotStore = {}
        legacyStore[name] = legacyBotStore
      end
    end
    legacyBotStore[elementKey] = icon
  end

  return icon
end

function MultiBot.ClearShamanTotemChoice(name, elementKey)
  if type(name) ~= "string" or name == "" then
    return
  end
  if type(elementKey) ~= "string" or elementKey == "" then
    return
  end

  local store = getShamanTotemsStore(true)
  migrateLegacyShamanTotemsIfNeeded(store)
  if store and store[name] then
    store[name][elementKey] = nil
  end

  if shouldSyncLegacyShamanTotems() then
    local legacyStore = getLegacyShamanTotemsStore(true)
    if legacyStore[name] then
      legacyStore[name][elementKey] = nil
    end
  end
end

function MultiBot.ToggleMainUIVisibility(desiredState)
  local targetState = desiredState
  if targetState == nil then
    targetState = not MultiBot.state
  else
    targetState = not not targetState
  end

  applyMainVisibility(MultiBot.frames, targetState)

  MultiBot.state = targetState
  MultiBot.SetMainUIVisibleConfig(targetState and true or false)
  return targetState
end

function MultiBot.DispatchEvent(eventName, ...)
  callMethodIfFunction(MultiBot, "HandleMultiBotEvent", false, eventName, ...)
end

function MultiBot.DispatchUpdate(pElapsed)
  callMethodIfFunction(MultiBot, "HandleOnUpdate", false, pElapsed)
end

local function registerEventsOnce(self, flagKey, eventList)
  if not self or self[flagKey] then return end
  self[flagKey] = true

  for _, eventName in ipairs(eventList) do
    if type(eventName) == "string" then
      callMethodIfFunction(self, "RegisterEvent", true, eventName)
    end
  end
end

function MultiBot:RegisterCoreEventsOnce()
  registerEventsOnce(self, "_coreEventsRegistered", CORE_EVENTS)
end

function MultiBot:RegisterInitEventsOnce()
  registerEventsOnce(self, "_initEventsRegistered", INIT_EVENTS)
end

callIfFunction(MultiBot.RegisterInitEventsOnce, MultiBot)

-- ACE3 lifecycle bridge: keep legacy startup logic, but route it through
-- OnInitialize/OnEnable so migration can stay incremental.
local LIFECYCLE_INIT_STEPS = {
  { name = "EnsureFavorites" },
  { name = "UpdateFavoritesIndex" },
  { name = "Config_Ensure" },
  { name = "ApplyTimersToRuntime" },
  { name = "BuildGlyphClassTable" },
  { name = "BuildOptionsPanel" },
}

local LIFECYCLE_ENABLE_STEPS = {
  { name = "RegisterCoreEventsOnce", passSelf = true },
  { name = "Throttle_Init" },
  { name = "ApplyGlobalStrata" },
  { name = "Minimap_Refresh" },
}

local function runLifecycleSteps(self, steps)
  for _, step in ipairs(steps) do
    callMethodIfFunction(self, step.name, step.passSelf)
  end
end

local function runLifecyclePhase(self, guardKey, steps)
  if not self or self[guardKey] then return end
  self[guardKey] = true
  runLifecycleSteps(self, steps)
end

function MultiBot:OnInitialize()
  runLifecyclePhase(self, "_initializedOnce", LIFECYCLE_INIT_STEPS)
end

function MultiBot:OnEnable()
  runLifecyclePhase(self, "_enabledOnce", LIFECYCLE_ENABLE_STEPS)
end

local function runLifecycle()
  MultiBot:OnInitialize()
  MultiBot:OnEnable()
end

local function bindLifecycleBridge(bridge)
  if not bridge then return false end

  function bridge:OnInitialize()
    MultiBot:OnInitialize()
  end

  function bridge:OnEnable()
    MultiBot:OnEnable()
  end

  return true
end

local function tryCreateLifecycleBridge()
  if not aceAddon then
    return false
  end

  local bridge = callIfFunction(aceAddon.NewAddon, aceAddon, LIFECYCLE_BRIDGE_NAME)
  return bindLifecycleBridge(bridge)
end

if not tryCreateLifecycleBridge() then
  -- Fallback for environments where AceAddon is not available.
  runLifecycle()
end

-- GM core --
MultiBot.GM = MultiBot.GM or false

function MultiBot.ApplyGMVisibility() end

function MultiBot.SetGM(isGM)
  isGM = not not isGM
  if MultiBot.GM ~= isGM then
    MultiBot.GM = isGM
    if MultiBot.ApplyGMVisibility then MultiBot.ApplyGMVisibility() end
  end
end
-- end GM core --

-- UI helper: promote a frame to the foreground without breaking tooltips
function MultiBot.PromoteFrame(f, strata)
  if not f or not f.SetFrameStrata then return end
  -- Add a default fallback kept at "DIALOG" to avoid regressions and it's safer
  local level = strata or (MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()) or STRATA_LEVEL_DEFAULT
  f:SetFrameStrata(level)
  if f.SetToplevel then f:SetToplevel(true) end
  if f.HookScript then
    f:HookScript("OnShow", function(self) if self.Raise then self:Raise() end end)
  end
end

function MultiBot.ApplyGlobalStrata()
  local level = (MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()) or nil
  if not MultiBot.frames then return end
  --for name, frm in pairs(MultiBot.frames) do
    for _, frm in pairs(MultiBot.frames) do
    if type(frm) == "table" and frm.SetFrameStrata then
      MultiBot.PromoteFrame(frm, level)
    end
  end
end

-- Account level detection (multi-locale, no hardcoding in handler) --
-- Set your GM threshold here (>= value means GM). ONLY set it once.
MultiBot.GM_THRESHOLD = 3

-- DEBUG (set to true temporarily if you want to see what gets parsed)
MultiBot.DEBUG_GM = false

-- Multi-language patterns that capture the level number.
-- We anchor to "account level" but allow anything between it and the number (e.g. "is: ").
MultiBot._acctlvl_patterns = {
  -- EN (covers "Your account level is: 3")
  "[Aa]ccount%W*[Ll]evel.-(%d+)",
  -- FR
  "[Nn]iveau%W*de%W*compte.-(%d+)",
  -- ES
  "[Nn]ivel%W*de%W*cuenta.-(%d+)",
  -- DE (Accountstufe/Kontostufe)
  "[Aa]ccount%W*[Ss]tufe.-(%d+)",
  "[Kk]onto%W*[Ss]tufe.-(%d+)",
  -- RU
  "Уровень%W*аккаунта.-(%d+)",
  -- ZH
  "账号%W*等级.-(%d+)",
  "帳號%W*等級.-(%d+)",
  -- KO
  "계정%W*등급.-(%d+)",
}

-- Fallbacks:
--  1) number after ':' near the end ("...: 3")
--  2) last number in a short line (avoid collisions)
local function _acctlvl_fallbacks(msg)
  local n = tonumber(string.match(msg, "[:：]%s*(%d+)%s*$"))
  if n then return n end
  if #msg <= 60 then
    local last = nil
    for d in string.gmatch(msg, "(%d+)") do last = d end
    if last then return tonumber(last) end
  end
  return nil
end

function MultiBot.ParseAccountLevel(msg)
  if type(msg) ~= "string" then return nil end

  -- Explicit fast-path for the common EN string:
  local capEN = msg:match("[Yy]our%W*[Aa]ccount%W*[Ll]evel%W*is%W*:%s*(%d+)")
  if capEN then return tonumber(capEN) end

  -- Try known patterns
  for _, pat in ipairs(MultiBot._acctlvl_patterns) do
    local cap = msg:match(pat)
    if cap then
      local n = tonumber(cap)
      if n then return n end
    end
  end

  -- Fallbacks
  return _acctlvl_fallbacks(msg)
end

function MultiBot.GM_DetectFromSystem(msg)
  local lvl = MultiBot.ParseAccountLevel(msg)
  MultiBot.LastAccountLevel = lvl

  if MultiBot.DEBUG_GM and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(
      ("[GMDetect] msg='%s' -> lvl=%s, thr=%d"):format(
        tostring(msg),
        tostring(lvl),
        MultiBot.GM_THRESHOLD
      )
    )
  end

  if lvl ~= nil then
    MultiBot.SetGM(lvl >= (MultiBot.GM_THRESHOLD or 2))
    if MultiBot.DEBUG_GM and DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage(("[GMDetect] GM=%s"):format(tostring(MultiBot.GM)))
    end
    --if MultiBot.RaidPool then MultiBot.RaidPool("player") end
    if MultiBot.RaidPool then
      local timerAfter = MultiBot.TimerAfter or _G.TimerAfter
      if type(timerAfter) == "function" then
        timerAfter(0.2, function() MultiBot.RaidPool("player") end)
      else
        MultiBot.RaidPool("player")
      end
    end
    return true
  end
  return false
end

-- end account level detection --

MultiBot:SetPoint("BOTTOMRIGHT", 0, 0)
MultiBot:SetSize(1, 1)
MultiBot:Show()

-- ============================================================================
-- SANITY : reconstruire l'index 'players' à partir des boutons existants
-- ============================================================================
function MultiBot.RebuildPlayersIndexFromButtons()
  if not (MultiBot.frames and MultiBot.frames["MultiBar"]
          and MultiBot.frames["MultiBar"].frames
          and MultiBot.frames["MultiBar"].frames["Units"]) then
    return
  end
  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local buttons = units.buttons or {}
  MultiBot.index.players = {}
  MultiBot.index.classes.players = {}
  for name, btn in pairs(buttons) do
    if btn and (btn.roster == "players" or btn.roster == nil) then
      table.insert(MultiBot.index.players, name)
      local cls = (btn.class and MultiBot.toClass(btn.class)) or "UNKNOWN"
      MultiBot.index.classes.players[cls] = MultiBot.index.classes.players[cls] or {}
      table.insert(MultiBot.index.classes.players[cls], name)
    end
  end
end

local BRIDGE_CLASS_ID_TO_CLASS = {
  [1] = "WARRIOR",
  [2] = "PALADIN",
  [3] = "HUNTER",
  [4] = "ROGUE",
  [5] = "PRIEST",
  [6] = "DEATHKNIGHT",
  [7] = "SHAMAN",
  [8] = "MAGE",
  [9] = "WARLOCK",
  [11] = "DRUID",
}

local function GetBridgeRosterClass(classId)
  local rawClass = BRIDGE_CLASS_ID_TO_CLASS[tonumber(classId or 0) or 0]
  if not rawClass then
    return "UNKNOWN"
  end

  return MultiBot.toClass(rawClass)
end

local function IsBridgeRosterBotActive(botName)
  if type(botName) ~= "string" or botName == "" then
    return false
  end

  local playerName = type(UnitName) == "function" and UnitName("player") or nil
  if botName == playerName then
    return false
  end

  if type(IsInRaid) == "function" and IsInRaid() then
    local raidCount = 0
    if type(GetNumGroupMembers) == "function" then
      raidCount = GetNumGroupMembers() or 0
    elseif type(GetNumRaidMembers) == "function" then
      raidCount = GetNumRaidMembers() or 0
    end

    for index = 1, raidCount do
      if UnitName("raid" .. index) == botName then
        return true
      end
    end
  end

  local partyCount = 0
  if type(GetNumSubgroupMembers) == "function" then
    partyCount = GetNumSubgroupMembers() or 0
  elseif type(GetNumPartyMembers) == "function" then
    partyCount = GetNumPartyMembers() or 0
  end

  for index = 1, partyCount do
    if UnitName("party" .. index) == botName then
      return true
    end
  end

  return false
end

function MultiBot.SyncBridgeRosterToPlayers(roster)
  if type(roster) ~= "table" then
    return false
  end

  if not (MultiBot.frames and MultiBot.frames["MultiBar"]
          and MultiBot.frames["MultiBar"].frames
          and MultiBot.frames["MultiBar"].frames["Units"]
          and MultiBot.addPlayer
          and MultiBot.addSelf) then
    return false
  end

  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local buttons = units.buttons or {}
  local frames = units.frames or {}
  local visibleNames = {}

  local playerName = nil
  if type(UnitName) == "function" then
    playerName = UnitName("player")
  end
  if type(playerName) == "string" and playerName ~= "" then
    visibleNames[playerName] = true
  end

  for _, entry in ipairs(roster) do
    if entry and type(entry.name) == "string" and entry.name ~= "" then
      visibleNames[entry.name] = true
    end
  end

  for name, btn in pairs(buttons) do
    if btn and btn.roster == "players" and not visibleNames[name] then
      local frame = frames[name]
      if frame then
        frame:Hide()
      end
      btn:Hide()
      if btn.setDisable then
        btn.setDisable()
      end
    end
  end

  MultiBot.index.players = {}
  MultiBot.index.classes.players = {}
  MultiBot.index.actives = {}
  MultiBot.index.classes.actives = {}

  if type(playerName) == "string" and playerName ~= "" and type(UnitClass) == "function" then
    local _, playerClassToken = UnitClass("player")
    local playerClass = MultiBot.toClass(playerClassToken or "UNKNOWN")
    local selfButton = MultiBot.addSelf(playerClass, playerName)
    if selfButton and selfButton.setDisable then
      selfButton.setDisable()
    end
  end

  for _, entry in ipairs(roster) do
    if entry and type(entry.name) == "string" and entry.name ~= "" then
      local botClass = GetBridgeRosterClass(entry.classId)
      local button = MultiBot.addPlayer(botClass, entry.name)
      if button then
        local isActive = IsBridgeRosterBotActive(entry.name)

        button.class = botClass
        button.classId = tonumber(entry.classId or 0) or 0
        button.level = tonumber(entry.level or 0) or 0
        button.mapId = tonumber(entry.mapId or 0) or 0
        button.alive = entry.alive and true or false
        button.hpPct = tonumber(entry.hpPct or 0) or 0
        button.mpPct = tonumber(entry.mpPct or 0) or 0
        button.bridge = entry

        if isActive then
          if MultiBot.index.classes.actives[botClass] == nil then
            MultiBot.index.classes.actives[botClass] = {}
          end
          table.insert(MultiBot.index.classes.actives[botClass], entry.name)
          table.insert(MultiBot.index.actives, entry.name)
          if button.setEnable then
            button.setEnable()
          end
        else
          if button.setDisable then
            button.setDisable()
          end
        end
      end
    end
  end

  if MultiBot.UpdateFavoritesIndex then
    MultiBot.UpdateFavoritesIndex()
  end

  if MultiBot.ApplyAllBridgeStates then
    MultiBot.ApplyAllBridgeStates()
  end

   if MultiBot.RelayoutUnitsDisplay then
     MultiBot.RelayoutUnitsDisplay()
   end

  return true
end

function MultiBot.GetCachedBridgeState(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  if not (MultiBot and MultiBot.bridge and MultiBot.bridge.states) then
    return nil
  end

  return MultiBot.bridge.states[string.lower(name)]
end

function MultiBot.ApplyAllBridgeStates()
  if not (MultiBot and MultiBot.bridge and MultiBot.bridge.states) then
    return 0
  end

  local applied = 0
  for _, entry in pairs(MultiBot.bridge.states) do
    if type(entry) == "table" and entry.name and MultiBot.ApplyBridgeBotState then
      if MultiBot.ApplyBridgeBotState(entry.name, entry.combat or "", entry.normal or "") then
        applied = applied + 1
      end
    end
  end

  return applied
end

function MultiBot.GetCachedBridgeDetail(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  if not (MultiBot and MultiBot.bridge and MultiBot.bridge.details) then
    return nil
  end

  return MultiBot.bridge.details[string.lower(name)]
end

local function BuildBridgeDetailStoreValue(detail)
  if type(detail) ~= "table" or type(detail.name) ~= "string" or detail.name == "" then
    return nil
  end

  local classCanon = (MultiBot.toClass and MultiBot.toClass(detail.className or detail.class or "Unknown")) or "Unknown"
  if classCanon == "" then
    classCanon = "Unknown"
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

  local special = tostring(classCanon)
  if MultiBot.L and classCanon ~= "Unknown" then
    local localized = MultiBot.L("info.talent." .. classCanon .. tabIndex)
    if localized and localized ~= "" then
      special = (MultiBot.CLEAR and MultiBot.CLEAR(localized, 1)) or localized
    end
  end

  local classDisplay = (MultiBot.GetClassDisplay and MultiBot.GetClassDisplay(classCanon)) or classCanon
  local race = tostring(detail.race or "Unknown")
  local gender = tostring(detail.gender or "Unknown")
  local talents = talent1 .. "/" .. talent2 .. "/" .. talent3
  local level = tonumber(detail.level or 0) or 0
  local score = tonumber(detail.score or 0) or 0

  return race .. "," .. gender .. "," .. special .. "," .. talents .. "," .. classDisplay .. "," .. level .. "," .. score
end

function MultiBot.ApplyBridgeBotDetail(detail)
  if type(detail) ~= "table" or type(detail.name) ~= "string" or detail.name == "" then
    return false
  end

  local value = BuildBridgeDetailStoreValue(detail)
  if not value then
    return false
  end

  if MultiBot.SetGlobalBotEntry then
    MultiBot.SetGlobalBotEntry(detail.name, value)
  else
    if type(_G.MultiBotGlobalSave) ~= "table" then
      _G.MultiBotGlobalSave = {}
    end
    _G.MultiBotGlobalSave[detail.name] = value
  end

  if MultiBot.raidus and MultiBot.raidus.setRaidus and MultiBot.raidus.IsShown and MultiBot.raidus:IsShown() then
    MultiBot.raidus.setRaidus()
  end

  return true
end

local function InsertBridgeNameUnique(list, name)
  if type(list) ~= "table" or type(name) ~= "string" or name == "" then
    return
  end

  for _, existing in ipairs(list) do
    if existing == name then
      return
    end
  end

  table.insert(list, name)
end

local function RequestBridgeUnitsRelayout()
  if MultiBot._bridgeUnitsRelayoutPending then
    return
  end

  MultiBot._bridgeUnitsRelayoutPending = true

  local function runRelayout()
    MultiBot._bridgeUnitsRelayoutPending = nil
    if MultiBot.RelayoutUnitsDisplay then
      MultiBot.RelayoutUnitsDisplay()
    end
  end

  if MultiBot.NextTick then
    MultiBot.NextTick(runRelayout)
  elseif MultiBot.TimerAfter then
    MultiBot.TimerAfter(0, runRelayout)
  else
    runRelayout()
  end
end

function MultiBot.ApplyBridgeBotState(name, combat, normal)
  if type(name) ~= "string" or name == "" then
    return false
  end

  if not (MultiBot.frames and MultiBot.frames["MultiBar"]
          and MultiBot.frames["MultiBar"].frames
          and MultiBot.frames["MultiBar"].frames["Units"]) then
    return false
  end

  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local button = units.buttons and units.buttons[name] or nil
  if not button then
    return false
  end

  button.combat = combat or ""
  button.normal = normal or ""
  button.waitFor = ""

  if not button.class or button.class == "" then
    if button.setEnable then
      button.setEnable()
    end
    return true
  end

  local unitFrame = units.addFrame(name, -34, 2)
  if unitFrame and unitFrame.Hide then
    unitFrame:Hide()
  end

  unitFrame.class = button.class
  unitFrame.name = button.name or name

  local classBuilder = MultiBot["add" .. button.class]
  if type(classBuilder) == "function" then
    classBuilder(unitFrame, button.combat, button.normal)
  end

  if MultiBot.addEvery then
    MultiBot.addEvery(unitFrame, button.combat, button.normal)
  end

  MultiBot.index.classes.actives[button.class] = MultiBot.index.classes.actives[button.class] or {}
  InsertBridgeNameUnique(MultiBot.index.classes.actives[button.class], name)
  InsertBridgeNameUnique(MultiBot.index.actives, name)

  if button.setEnable then
    button.setEnable()
  end

  if unitFrame and unitFrame.Hide then
    unitFrame:Hide()
  end

  RequestBridgeUnitsRelayout()

  return true
end

local save, globalSave = ensureSavedVariables()
MultiBotSave = save
MultiBotGlobalSave = globalSave
MultiBot.data = {}
MultiBot.index = {}
MultiBot.index.classes = {}
MultiBot.index.classes.actives = {}
MultiBot.index.classes.players = {}
MultiBot.index.classes.members = {}
MultiBot.index.classes.friends = {}
-- Per-character favorites
MultiBot.index.classes.favorites = {}
MultiBot.index.actives = {}
MultiBot.index.players = {}
MultiBot.index.members = {}
MultiBot.index.friends = {}
MultiBot.index.raidus = {}
MultiBot.index.favorites = {}
MultiBot.spells = {}
MultiBot.frames = {}
MultiBot.units = {}

-- Legacy compatibility bootstrap: this container remains for non-localized runtime metadata
-- and is intentionally not used for user-facing tooltip text lookups anymore.
MultiBot.tips = {}
MultiBot.tips.spec = MultiBot.tips.spec or {}

MultiBot.auto = {}
MultiBot.auto.sort = false
MultiBot.auto.stats = false
MultiBot.auto.talent = false
MultiBot.auto.invite = false
MultiBot.auto.release = false

-- =========================
-- DEBUG helpers (trace chat)
-- =========================
MultiBot.debug = false
local function MB_tostring(v)
  if type(v) == "table" then
    local ok, s = pcall(function() return tostring(v) end)
    if ok then return s else return "<table>" end
  end
  return tostring(v)
end
function MultiBot.dprint(...)
  local debugApi = MultiBot.Debug
  if type(debugApi) == "table" and type(debugApi.IsEnabled) == "function" then
    if not debugApi.IsEnabled("core") then
      return
    end
    MultiBot.debug = true
  elseif not MultiBot.debug then
    return
  end

  local parts = {}
  for i=1,select("#", ...) do
    parts[#parts+1] = MB_tostring(select(i, ...))
  end

  local message = "|cffff7f00[MultiBot]|r " .. table.concat(parts, " ")
  if type(debugApi) == "table" and type(debugApi.PrintRateLimited) == "function" then
    local rateKey = "core.dprint." .. string.lower(tostring(select(1, ...) or "generic"))
    debugApi.PrintRateLimited(rateKey, 0.2, "core", message)
    return
  end

  if type(debugApi) == "table" and type(debugApi.Print) == "function" then
    debugApi.Print("core", message)
    return
  end

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message)
  else
    print("[MultiBot] ".. table.concat(parts, " "))
  end
end


-- ============================================================================
-- FAVORITES (per-character)
-- ============================================================================
local function getLegacyFavoritesStore(createIfMissing)
  local savedVars = ensureSavedVariables()
  local favorites = savedVars.Favorites

  if type(favorites) ~= "table" then
    if not createIfMissing then
      return nil
    end

    favorites = {}
    savedVars.Favorites = favorites
  end

  return favorites
end

local function getFavoritesStore()
  local favorites = MultiBot.Store and MultiBot.Store.GetFavoritesStore and MultiBot.Store.GetFavoritesStore()
  local legacyFavorites = getLegacyFavoritesStore(false) or {}
  local hasLegacyFavorites = next(legacyFavorites) ~= nil
  if not favorites and hasLegacyFavorites and shouldSyncLegacyUiState(FAVORITES_MIGRATION_KEY, FAVORITES_MIGRATION_VERSION) then
    favorites = MultiBot.Store and MultiBot.Store.EnsureFavoritesStore and MultiBot.Store.EnsureFavoritesStore()
  end
  if favorites then
    if shouldSyncLegacyUiState(FAVORITES_MIGRATION_KEY, FAVORITES_MIGRATION_VERSION) then
      for name, isFavorite in pairs(legacyFavorites) do
        if favorites[name] == nil then
          favorites[name] = isFavorite
        end
      end

      markLegacyUiStateMigrated(FAVORITES_MIGRATION_KEY, FAVORITES_MIGRATION_VERSION)

      -- Purge migrated legacy favorites payload to avoid stale duplicate persistence.
      local savedVars = ensureSavedVariables()
      savedVars.Favorites = nil
    end

    return favorites
  end

  return getLegacyFavoritesStore(false) or {}
end

function MultiBot.EnsureFavorites()
  getFavoritesStore()
end

function MultiBot.IsFavorite(name)
  local favorites = getFavoritesStore()
  return favorites and favorites[name] == true
end

function MultiBot.UpdateFavoritesIndex()
  local favorites = getFavoritesStore()

  MultiBot.index.favorites = {}
  MultiBot.index.classes.favorites = {}
  for name, _ in pairs(favorites or {}) do
    table.insert(MultiBot.index.favorites, name)
    local cls = nil
    -- 1) If the unit button already exists, use its class.
    local units = nil
    if MultiBot.frames and MultiBot.frames["MultiBar"]
       and MultiBot.frames["MultiBar"].frames
       and MultiBot.frames["MultiBar"].frames["Units"]
    then
      units = MultiBot.frames["MultiBar"].frames["Units"]
    end
    local buttons = units and units.buttons or nil
    if buttons and buttons[name] and buttons[name].class then
      cls = buttons[name].class
    else
      -- 2) Otherwise fallback to players class index.
      local byClass = MultiBot.index and MultiBot.index.classes and MultiBot.index.classes.players
      if byClass then
        for c, arr in pairs(byClass) do
          for i = 1, (arr and #arr or 0) do
            if arr[i] == name then cls = c break end
          end
          if cls then break end
        end
      end
    end
    cls = cls or "UNKNOWN"
    MultiBot.index.classes.favorites[cls] = MultiBot.index.classes.favorites[cls] or {}
    table.insert(MultiBot.index.classes.favorites[cls], name)
  end
end

function MultiBot.SetFavorite(name, isFav)
  local favorites = MultiBot.Store and MultiBot.Store.EnsureFavoritesStore and MultiBot.Store.EnsureFavoritesStore()
  if not favorites then
    favorites = getLegacyFavoritesStore(true)
  end
  if isFav then favorites[name] = true
           else favorites[name] = nil
  end
  MultiBot.UpdateFavoritesIndex()
end

function MultiBot.ToggleFavorite(name)
  MultiBot.SetFavorite(name, not MultiBot.IsFavorite(name))
end

MultiBot.timer = {}
MultiBot.timer.sort = {}
MultiBot.timer.sort.elapsed = 0
MultiBot.timer.sort.interval = 1
MultiBot.timer.stats = {}
MultiBot.timer.stats.elapsed = 0
MultiBot.timer.stats.interval = 45
MultiBot.timer.talent = {}
MultiBot.timer.talent.elapsed = 0
MultiBot.timer.talent.interval = 3
MultiBot.timer.invite = {}
MultiBot.timer.invite.elapsed = 0
MultiBot.timer.invite.interval = 5

-- CLASSES (canonical + backward-compat)
MultiBot.CLASSES_CANON = {
  "DeathKnight","Druid","Hunter","Mage","Paladin",
  "Priest","Rogue","Shaman","Warlock","Warrior"
}

MultiBot.data = MultiBot.data or {}
MultiBot.data.classes = MultiBot.data.classes or {}

local function _mb_copy(a)
  local r = {}
  for i,v in ipairs(a) do r[i] = v end
  return r
end

MultiBot.data.classes.input  = MultiBot.data.classes.input  or _mb_copy(MultiBot.CLASSES_CANON)
MultiBot.data.classes.output = MultiBot.data.classes.output or _mb_copy(MultiBot.CLASSES_CANON)

function MultiBot.BuildClassMaps()
  if MultiBot._classMapsBuilt then return end
  MultiBot._classMapsBuilt = true

  local male   = _G.LOCALIZED_CLASS_NAMES_MALE   or {}
  local female = _G.LOCALIZED_CLASS_NAMES_FEMALE or {}
  local upper = {
    DeathKnight="DEATHKNIGHT", Druid="DRUID", Hunter="HUNTER", Mage="MAGE",
    Paladin="PALADIN", Priest="PRIEST", Rogue="ROGUE", Shaman="SHAMAN",
    Warlock="WARLOCK", Warrior="WARRIOR",
  }

  MultiBot.CLASS_ALIAS = {}

  local function add(alias, canon)
    if alias and alias ~= "" then
      MultiBot.CLASS_ALIAS[string.lower(alias)] = canon
    end
  end

  for _, canon in ipairs(MultiBot.CLASSES_CANON) do
    local token = upper[canon]
    -- variantes évidentes
    add(canon, canon)             -- "DeathKnight"
    add(token, canon)             -- "DEATHKNIGHT"
    add(string.lower(canon), canon)
    add(string.lower(token), canon)

    -- noms localisés (homme/femme) si dispo
    add(male[token],   canon)
    add(female[token], canon)

    -- alias fréquents libres
    if canon == "DeathKnight" then
      add("death knight", canon); add("dk", canon)
    elseif canon == "Warlock" then
      add("lock", canon)
    elseif canon == "Paladin" then
      add("pala", canon)
    elseif canon == "Shaman" then
      add("sham", canon)
    end
  end

  -- alias par locale
  local loc = GetLocale and GetLocale() or "enUS"
  MultiBot.CLASS_EXTRA_ALIASES = MultiBot.CLASS_EXTRA_ALIASES or {
    frFR = { ["chevalier de la mort"]="DeathKnight", ["cdm"]="DeathKnight", ["prêtre"]="Priest" },
    deDE = { ["todesritter"]="DeathKnight" },
    esES = { ["caballero de la muerte"]="DeathKnight" },
    ruRU = { ["рыцарь смерти"]="DeathKnight" },
    zhCN = { ["死亡骑士"]="DeathKnight" },
    zhTW = { ["死亡騎士"]="DeathKnight" },
    koKR = { ["죽음의 기사"]="DeathKnight" },
  }
  local extra = MultiBot.CLASS_EXTRA_ALIASES[loc]
  if extra then
    for alias, canon in pairs(extra) do add(alias, canon) end
  end
end

-- Retourne le canon "DeathKnight"/"Mage"/... à partir d’un texte libre (toutes langues)
function MultiBot.NormalizeClass(text)
  if not text then return nil end
  MultiBot.BuildClassMaps()
  local key = string.lower((tostring(text):gsub("%s+", " ")))
  return MultiBot.CLASS_ALIAS[key]
end

-- Texte à afficher pour une classe canon (localisé si possible)
function MultiBot.GetClassDisplay(canon)
  if not canon then return nil end
  local upper = {
    DeathKnight="DEATHKNIGHT", Druid="DRUID", Hunter="HUNTER", Mage="MAGE",
    Paladin="PALADIN", Priest="PRIEST", Rogue="ROGUE", Shaman="SHAMAN",
    Warlock="WARLOCK", Warrior="WARRIOR",
  }
  local token = upper[canon]
  local male = _G.LOCALIZED_CLASS_NAMES_MALE or {}
  return male[token] or canon
end
-- end CLASS DETECTION --

--  Compatibility API for refactored
if not IsInRaid then
  -- Client 3.3.5 compatibility
  function IsInRaid()
    return GetNumRaidMembers() > 0
  end
end

if not IsInGroup then
  function IsInGroup()              -- Define if it's a raid or party
    return IsInRaid() or GetNumPartyMembers() > 0
  end
end

if not GetNumGroupMembers then
  -- Wrath : "raid" only
  function GetNumGroupMembers()
    return GetNumRaidMembers()
  end
end

if not GetNumSubgroupMembers then
  -- Number of members in party (without player) in Wrath
  function GetNumSubgroupMembers()
    return GetNumPartyMembers()
  end
end

--  AddClassToTarget Wrapper
-- Usage : MultiBot.AddClassToTarget("warlock"        ) -- Random
--         MultiBot.AddClassToTarget("warlock","male" ) -- Male
--         MultiBot.AddClassToTarget("warlock","female") -- Female
MultiBot.AddClassToTarget = function(classCmd, gender)
  if not classCmd then return end             -- secure that
  local msg = ".playerbot bot addclass " .. classCmd
  if gender then                                 -- male / female / 0 / 1
	msg = msg .. " " .. gender
	print("[DBG] Message de sortie :" ,msg)
  end
  SendChatMessage(msg, "SAY")
end

-- Init Wrapper
function MultiBot.InitAuto(name)
  SendChatMessage(".playerbot bot init=auto " .. name, "SAY")
end

-- Localization payload moved to AceLocale files.
-- Keep runtime containers initialized elsewhere; locale files hydrate values.

MultiBot.GM = false
