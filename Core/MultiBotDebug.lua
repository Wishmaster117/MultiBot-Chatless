-- MultiBotDebug.lua
-- Temporary migration debug helpers.
-- Keep this file during ACE3 migration; remove once migration diagnostics are no longer needed.

MultiBot.Debug = MultiBot.Debug or {}

local Debug = MultiBot.Debug

local DEFAULT_DEBUG_FLAGS = {
  core = false,
  options = false,
  scheduler = false,
  roster = false,
  quests = false,
  spellbook = false,
  migration = false,
  perf = false,
}

local function normalizeSubsystem(subsystem)
  if type(subsystem) ~= "string" then
    return nil
  end

  local cleaned = subsystem:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end

  return cleaned
end

local function ensureFlagsStore()
  if type(MultiBot._debugFlags) ~= "table" then
    MultiBot._debugFlags = {}
  end

  for subsystem, enabled in pairs(DEFAULT_DEBUG_FLAGS) do
    if MultiBot._debugFlags[subsystem] == nil then
      MultiBot._debugFlags[subsystem] = enabled and true or false
    end
  end

  return MultiBot._debugFlags
end


local function ensureCountersStore()
  if type(MultiBot._debugPerfCounters) ~= "table" then
    MultiBot._debugPerfCounters = {}
  end
  return MultiBot._debugPerfCounters
end


local function ensureRateLimitStore()
  if type(MultiBot._debugRateLimits) ~= "table" then
    MultiBot._debugRateLimits = {}
  end
  return MultiBot._debugRateLimits
end

local function shouldEmitRateLimited(key, minInterval)
  local rateStore = ensureRateLimitStore()
  local now = type(GetTime) == "function" and GetTime() or 0
  local threshold = math.max(tonumber(minInterval) or 0, 0)
  local last = tonumber(rateStore[key]) or -math.huge

  if (now - last) < threshold then
    return false
  end

  rateStore[key] = now
  return true
end

local function normalizeCounterName(counterName)
  if type(counterName) ~= "string" then
    return nil
  end

  local cleaned = counterName:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end

  return cleaned
end

local function parsePrintArgs(subsystemOrMessage, messageOrColor, colorHex)
  local subsystem = normalizeSubsystem(subsystemOrMessage)
  if subsystem then
    return subsystem, messageOrColor, colorHex
  end

  return nil, subsystemOrMessage, messageOrColor
end

local function EmitDebugMessage(message, colorHex)
  local text = message
  if colorHex and colorHex ~= "" then
    text = "|cff" .. colorHex .. message .. "|r"
  end

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  elseif type(print) == "function" then
    print(message)
  end
end

function Debug.GetFlags()
  local flags = ensureFlagsStore()
  local snapshot = {}
  for subsystem, enabled in pairs(flags) do
    snapshot[subsystem] = enabled and true or false
  end
  return snapshot
end

function Debug.IsEnabled(subsystem)
  local normalized = normalizeSubsystem(subsystem)
  if not normalized then
    return false
  end

  local flags = ensureFlagsStore()
  return flags[normalized] == true
end

function Debug.IsPerfEnabled()
  local flags = MultiBot._debugFlags
  if type(flags) == "table" and flags.perf ~= nil then
    return flags.perf == true
  end

  return Debug.IsEnabled("perf")
end

function Debug.SetEnabled(subsystem, enabled)
  local normalized = normalizeSubsystem(subsystem)
  if not normalized then
    return false
  end

  local flags = ensureFlagsStore()
  flags[normalized] = enabled and true or false

  if normalized == "core" then
    MultiBot.debug = flags[normalized]
  end

  return true
end

function Debug.SetAllEnabled(enabled)
  local flags = ensureFlagsStore()
  local target = enabled and true or false
  for subsystem in pairs(flags) do
    flags[subsystem] = target
  end
  MultiBot.debug = flags.core == true
end

function Debug.Toggle(subsystem)
  local normalized = normalizeSubsystem(subsystem)
  if not normalized then
    return nil
  end

  local flags = ensureFlagsStore()
  local nextValue = flags[normalized] ~= true
  flags[normalized] = nextValue

  if normalized == "core" then
    MultiBot.debug = nextValue
  end

  return nextValue
end

function Debug.Print(subsystemOrMessage, messageOrColor, colorHex)
  local subsystem, message, color = parsePrintArgs(subsystemOrMessage, messageOrColor, colorHex)
  if subsystem and not Debug.IsEnabled(subsystem) then
    return
  end

  EmitDebugMessage(tostring(message), color)
end

function Debug.PrintRateLimited(rateKey, minInterval, subsystemOrMessage, messageOrColor, colorHex)
  local key = normalizeCounterName(rateKey) or "debug.print"
  if not shouldEmitRateLimited(key, minInterval) then
    return false
  end

  Debug.Print(subsystemOrMessage, messageOrColor, colorHex)
  return true
end

function Debug.Once(key, subsystemOrMessage, messageOrColor, colorHex)
  if type(key) ~= "string" or key == "" then
    Debug.Print(subsystemOrMessage, messageOrColor, colorHex)
    return
  end

  local subsystem, message, color = parsePrintArgs(subsystemOrMessage, messageOrColor, colorHex)
  if subsystem and not Debug.IsEnabled(subsystem) then
    return
  end

  MultiBot._debugOnceFlags = MultiBot._debugOnceFlags or {}
  if MultiBot._debugOnceFlags[key] then
    return
  end

  MultiBot._debugOnceFlags[key] = true
  EmitDebugMessage(tostring(message), color)
end

function Debug.OptionsPath(path, detail)
  local message = string.format("MultiBot Options: using %s path", tostring(path))
  if detail and detail ~= "" then
    message = message .. string.format(" (%s)", detail)
  end
  Debug.Once("options.path", "options", message, "33ff99")
end

function Debug.AceGUILoadState(reason)
  local hasLibStub = type(LibStub) == "table"
  local aceMinor = nil
  local aceLoaded = false

  if hasLibStub and type(LibStub.minors) == "table" then
    aceMinor = LibStub.minors["AceGUI-3.0"]
    aceLoaded = LibStub.libs and LibStub.libs["AceGUI-3.0"] ~= nil
  end

  local message = string.format(
    "MultiBot Options: AceGUI debug => reason=%s, LibStub=%s, minor=%s, loaded=%s",
    tostring(reason),
    tostring(hasLibStub),
    tostring(aceMinor),
    tostring(aceLoaded)
  )

  Debug.Once("options.acegui.load", "options", message, "ffff00")
end

function Debug.ListFlagsText()
  local flags = Debug.GetFlags()
  local keys = {}
  for subsystem in pairs(flags) do
    keys[#keys + 1] = subsystem
  end
  table.sort(keys)

  local parts = {}
  for _, subsystem in ipairs(keys) do
    parts[#parts + 1] = string.format("%s=%s", subsystem, flags[subsystem] and "on" or "off")
  end

  return table.concat(parts, ", ")
end


function Debug.IncrementCounter(counterName, delta)
  if not Debug.IsPerfEnabled() then
    return nil
  end

  local key = normalizeCounterName(counterName)
  if not key then
    return nil
  end

  local increment = tonumber(delta) or 1
  local counters = ensureCountersStore()
  counters[key] = (tonumber(counters[key]) or 0) + increment
  return counters[key]
end

function Debug.AddDuration(counterName, elapsed)
  return Debug.IncrementCounter(counterName, tonumber(elapsed) or 0)
end

function Debug.GetCounters()
  local counters = ensureCountersStore()
  local snapshot = {}
  for key, value in pairs(counters) do
    snapshot[key] = value
  end
  return snapshot
end

function Debug.ResetCounters(prefix)
  local counters = ensureCountersStore()
  local normalizedPrefix = normalizeCounterName(prefix)

  if not normalizedPrefix then
    for key in pairs(counters) do
      counters[key] = nil
    end
    return
  end

  local pattern = "^" .. normalizedPrefix
  for key in pairs(counters) do
    if string.match(key, pattern) then
      counters[key] = nil
    end
  end
end

function Debug.FormatCounters(limit)
  local counters = Debug.GetCounters()
  local keys = {}
  for key in pairs(counters) do
    keys[#keys + 1] = key
  end
  table.sort(keys)

  local maxItems = math.floor(tonumber(limit) or 20)
  if maxItems < 1 then
    maxItems = 1
  end

  local parts = {}
  local count = 0
  for _, key in ipairs(keys) do
    count = count + 1
    if count > maxItems then
      break
    end
    parts[#parts + 1] = string.format("%s=%.3f", key, tonumber(counters[key]) or 0)
  end

  if #parts == 0 then
    return "(empty)"
  end

  if #keys > maxItems then
    parts[#parts + 1] = string.format("... +%d", #keys - maxItems)
  end

  return table.concat(parts, ", ")
end

ensureFlagsStore()