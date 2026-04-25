-- MultiBotConfig.lua
-- print("MultiBotConfig.lua loaded")
MultiBot = MultiBot or {}

-- Chatless mode:
-- false = bridge-first, aucun fallback chat automatique legacy.
-- true  = réactive temporairement les anciens fallbacks chat pour diagnostic.
MultiBot.allowLegacyChatFallback = false

local aceDB = LibStub and LibStub("AceDB-3.0", true)

-- Original values (seconds): kept unchanged.
local DEFAULTS = {
  stats  = 45,
  talent = 3,
  invite = 5,
  sort   = 1,
}

local THROTTLE_DEFAULTS = {
  rate = 5,
  burst = 8,
}

local UI_DEFAULTS = {
  mainBar = {
    moveLocked = true,
    disableAutoCollapse = false,
    autoHideEnabled = false,
    autoHideDelay = 60,
  },
}

local DB_DEFAULTS = {
  profile = {
    timers = {
      stats  = DEFAULTS.stats,
      talent = DEFAULTS.talent,
      invite = DEFAULTS.invite,
      sort   = DEFAULTS.sort,
    },
    throttle = {
      rate = THROTTLE_DEFAULTS.rate,
      burst = THROTTLE_DEFAULTS.burst,
    },
    ui = {
      mainBar = {
        moveLocked = UI_DEFAULTS.mainBar.moveLocked,
      },
    },
  },
}

local function getLegacyTimerValue(name)
  return MultiBotDB and MultiBotDB.timers and MultiBotDB.timers[name]
end

local function getLegacyThrottleValue(name)
  return MultiBotDB and MultiBotDB.throttle and MultiBotDB.throttle[name]
end

local ensureTableField

local function migrateLegacyConfigIntoProfile(profile)
  if type(profile) ~= "table" then return end

  local timers = ensureTableField(profile, "timers")
  for key, defaultValue in pairs(DEFAULTS) do
    local legacyValue = getLegacyTimerValue(key)
    if type(legacyValue) == "number" and legacyValue > 0 then
      timers[key] = legacyValue
    elseif type(timers[key]) ~= "number" or timers[key] <= 0 then
      timers[key] = defaultValue
    end
  end

  local throttle = ensureTableField(profile, "throttle")
  for key, defaultValue in pairs(THROTTLE_DEFAULTS) do
    local legacyValue = getLegacyThrottleValue(key)
    if type(legacyValue) == "number" and legacyValue > 0 then
      throttle[key] = legacyValue
    elseif type(throttle[key]) ~= "number" or throttle[key] <= 0 then
      throttle[key] = defaultValue
    end
  end

  local ui = ensureTableField(profile, "ui")
  local mainBar = ensureTableField(ui, "mainBar")
  if MultiBot.Store and MultiBot.Store.NormalizeMainBarSettings then
    MultiBot.Store.NormalizeMainBarSettings(mainBar, UI_DEFAULTS.mainBar)
    return
  end
  if type(mainBar.moveLocked) ~= "boolean" then
    mainBar.moveLocked = UI_DEFAULTS.mainBar.moveLocked
  end
  if type(mainBar.disableAutoCollapse) ~= "boolean" then
    mainBar.disableAutoCollapse = UI_DEFAULTS.mainBar.disableAutoCollapse
  end
  if type(mainBar.autoHideEnabled) ~= "boolean" then
    mainBar.autoHideEnabled = UI_DEFAULTS.mainBar.autoHideEnabled
  end
  if type(mainBar.autoHideDelay) ~= "number" or mainBar.autoHideDelay <= 0 then
    mainBar.autoHideDelay = UI_DEFAULTS.mainBar.autoHideDelay
  end
end

local function getConfigStore(createIfMissing)
  if createIfMissing then
    return MultiBot.Store and MultiBot.Store.EnsureProfileStore and MultiBot.Store.EnsureProfileStore()
  end
  return MultiBot.Store and MultiBot.Store.GetProfileStore and MultiBot.Store.GetProfileStore()
end

ensureTableField = function(parent, key)
  if type(parent) ~= "table" or type(key) ~= "string" or key == "" then
    return nil
  end
  if MultiBot.Store and MultiBot.Store.EnsureTableField then
    return MultiBot.Store.EnsureTableField(parent, key, {})
  end
  if type(parent[key]) ~= "table" then
    parent[key] = {}
  end
  return parent[key]
end

function MultiBot.Config_InitDB()
  if MultiBot.db or not aceDB then
    return
  end

  MultiBotDB = MultiBotDB or {}
  local db = aceDB:New("MultiBotDB", DB_DEFAULTS, true)
  if not db or not db.profile then
    return
  end

  migrateLegacyConfigIntoProfile(db.profile)
  MultiBot.db = db
end

-- Ensure SavedVariables keys exist.
function MultiBot.Config_Ensure()
  MultiBot.Config_InitDB()

  local config = getConfigStore(true)

  local timers = ensureTableField(config, "timers")
  for key, defaultValue in pairs(DEFAULTS) do
    if type(timers[key]) ~= "number" or timers[key] <= 0 then
      timers[key] = defaultValue
    end
  end

  local throttle = ensureTableField(config, "throttle")
  if type(throttle.rate) ~= "number" or throttle.rate <= 0 then
    throttle.rate = THROTTLE_DEFAULTS.rate
  end
  if type(throttle.burst) ~= "number" or throttle.burst <= 0 then
    throttle.burst = THROTTLE_DEFAULTS.burst
  end

  local mainBar = MultiBot.Store and MultiBot.Store.EnsureMainBarStore and MultiBot.Store.EnsureMainBarStore()
  if mainBar and MultiBot.Store.NormalizeMainBarSettings then
    MultiBot.Store.NormalizeMainBarSettings(mainBar, UI_DEFAULTS.mainBar)
    return
  end

  local ui = ensureTableField(config, "ui")
  local legacyMainBar = ensureTableField(ui, "mainBar")
  if type(legacyMainBar.moveLocked) ~= "boolean" then
    legacyMainBar.moveLocked = UI_DEFAULTS.mainBar.moveLocked
  end
  if type(legacyMainBar.disableAutoCollapse) ~= "boolean" then
    legacyMainBar.disableAutoCollapse = UI_DEFAULTS.mainBar.disableAutoCollapse
  end
  if type(legacyMainBar.autoHideEnabled) ~= "boolean" then
    legacyMainBar.autoHideEnabled = UI_DEFAULTS.mainBar.autoHideEnabled
  end
  if type(legacyMainBar.autoHideDelay) ~= "number" or legacyMainBar.autoHideDelay <= 0 then
    legacyMainBar.autoHideDelay = UI_DEFAULTS.mainBar.autoHideDelay
  end
end

-- Copy saved values into runtime timers.
function MultiBot.ApplyTimersToRuntime()
  if not (MultiBot and MultiBot.timer) then return end
  local config = getConfigStore(false)
  if not config then
    return
  end
  if type(config.timers) ~= "table" then
    return
  end
  for key, value in pairs(config.timers) do
    MultiBot.timer[key] = MultiBot.timer[key] or { elapsed = 0, interval = value }
    MultiBot.timer[key].interval = value
  end
end

-- Read
function MultiBot.GetTimer(name)
  local config = getConfigStore(false)
  local value = config and config.timers and config.timers[name]
  if type(value) == "number" and value > 0 then
    return value
  end
  return DEFAULTS[name]
end

-- Reset elapsed counters (one or all)
function MultiBot.ApplyTimerChanges(name)
  if not (MultiBot and MultiBot.timer) then return end
  local function resetOne(timerName)
    if MultiBot.timer[timerName] and type(MultiBot.timer[timerName].elapsed) == "number" then
      MultiBot.timer[timerName].elapsed = 0
    end
  end
  if name then
    resetOne(name)
  else
    resetOne("stats"); resetOne("talent"); resetOne("invite"); resetOne("sort")
  end
end

-- Write + clamp + immediate apply
function MultiBot.SetTimer(name, value)
  if type(value) ~= "number" then return end
  if value < 0.1 then value = 0.1 end
  if value > 600 then value = 600 end

  local config = getConfigStore(true)
  local timers = ensureTableField(config, "timers")
  timers[name] = value

  if MultiBot and MultiBot.timer and MultiBot.timer[name] then
    MultiBot.timer[name].interval = value
  end
  MultiBot.ApplyTimerChanges(name)
end

-- Throttle: read
function MultiBot.GetThrottleRate()
  local config = getConfigStore()
  return (config and config.throttle and config.throttle.rate) or THROTTLE_DEFAULTS.rate
end

function MultiBot.GetThrottleBurst()
  local config = getConfigStore(false)
  return (config and config.throttle and config.throttle.burst) or THROTTLE_DEFAULTS.burst
end

-- Throttle: write + immediate apply
function MultiBot.SetThrottleRate(value)
  if type(value) ~= "number" then return end
  if value < 1 then value = 1 end
  if value > 50 then value = 50 end

  local config = getConfigStore(true)
  local throttle = ensureTableField(config, "throttle")
  throttle.rate = value

  if MultiBot._ThrottleStats then
    MultiBot._ThrottleStats(throttle.rate, MultiBot.GetThrottleBurst())
  end
end

function MultiBot.SetThrottleBurst(value)
  if type(value) ~= "number" then return end
  if value < 1 then value = 1 end
  if value > 100 then value = 100 end

  local config = getConfigStore(true)
  local throttle = ensureTableField(config, "throttle")
  throttle.burst = value

  if MultiBot._ThrottleStats then
    MultiBot._ThrottleStats(MultiBot.GetThrottleRate(), throttle.burst)
  end
end

function MultiBot.GetMainBarMoveLocked()
  local mainBar = MultiBot.Store and MultiBot.Store.GetMainBarStore and MultiBot.Store.GetMainBarStore()
  local value = mainBar and mainBar.moveLocked
  if type(value) == "boolean" then
    return value
  end

  return UI_DEFAULTS.mainBar.moveLocked
end

function MultiBot.SetMainBarMoveLocked(value)
  local mainBar = MultiBot.Store and MultiBot.Store.EnsureMainBarStore and MultiBot.Store.EnsureMainBarStore()
  if not mainBar then
    return UI_DEFAULTS.mainBar.moveLocked
  end
  mainBar.moveLocked = value and true or false
  if MultiBot.ApplyMainBarMoveLockState then
    MultiBot.ApplyMainBarMoveLockState(mainBar.moveLocked)
  end
  return mainBar.moveLocked
end

function MultiBot.GetDisableAutoCollapse()
  local mainBar = MultiBot.Store and MultiBot.Store.GetMainBarStore and MultiBot.Store.GetMainBarStore()
  local value = mainBar and mainBar.disableAutoCollapse
  if type(value) == "boolean" then
    return value
  end

  return UI_DEFAULTS.mainBar.disableAutoCollapse
end

function MultiBot.SetDisableAutoCollapse(value)
  local mainBar = MultiBot.Store and MultiBot.Store.EnsureMainBarStore and MultiBot.Store.EnsureMainBarStore()
  if not mainBar then
    return UI_DEFAULTS.mainBar.disableAutoCollapse
  end
  mainBar.disableAutoCollapse = value and true or false
  return mainBar.disableAutoCollapse
end

local function normalizeMainBarAutoHideDelay(value)
  if type(value) ~= "number" then
    return UI_DEFAULTS.mainBar.autoHideDelay
  end
  if value < 5 then
    return 5
  end
  if value > 600 then
    return 600
  end
  return value
end

function MultiBot.GetMainBarAutoHideEnabled()
  local mainBar = MultiBot.Store and MultiBot.Store.GetMainBarStore and MultiBot.Store.GetMainBarStore()
  local value = mainBar and mainBar.autoHideEnabled
  if type(value) == "boolean" then
    return value
  end

  return UI_DEFAULTS.mainBar.autoHideEnabled
end

function MultiBot.SetMainBarAutoHideEnabled(value)
  local mainBar = MultiBot.Store and MultiBot.Store.EnsureMainBarStore and MultiBot.Store.EnsureMainBarStore()
  if not mainBar then
    return UI_DEFAULTS.mainBar.autoHideEnabled
  end
  mainBar.autoHideEnabled = value and true or false
  if MultiBot.RefreshMainBarAutoHideState then
    MultiBot.RefreshMainBarAutoHideState()
  end
  return mainBar.autoHideEnabled
end

function MultiBot.GetMainBarAutoHideDelay()
  local mainBar = MultiBot.Store and MultiBot.Store.GetMainBarStore and MultiBot.Store.GetMainBarStore()
  local value = mainBar and mainBar.autoHideDelay
  if type(value) == "number" and value > 0 then
    return normalizeMainBarAutoHideDelay(value)
  end

  return UI_DEFAULTS.mainBar.autoHideDelay
end

function MultiBot.SetMainBarAutoHideDelay(value)
  local mainBar = MultiBot.Store and MultiBot.Store.EnsureMainBarStore and MultiBot.Store.EnsureMainBarStore()
  if not mainBar then
    return UI_DEFAULTS.mainBar.autoHideDelay
  end
  mainBar.autoHideDelay = normalizeMainBarAutoHideDelay(value)
  if MultiBot.RefreshMainBarAutoHideState then
    MultiBot.RefreshMainBarAutoHideState()
  end
  return mainBar.autoHideDelay
end