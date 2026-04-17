MultiBot = MultiBot or {}

local aceLocale = LibStub and LibStub("AceLocale-3.0", true)
local LOCALE_NAMESPACE = "MultiBot"

local function sanitizeLocaleTable(values)
  if type(values) ~= "table" then
    return nil
  end

  local sanitized = {}
  for key, value in pairs(values) do
    if type(key) == "string" and type(value) == "string" then
      sanitized[key] = value
    end
  end

  return sanitized
end

local function registerDefaultStrings(values)
  local defaults = MultiBot._localeDefaults or {}
  for key, value in pairs(values) do
    defaults[key] = value
  end
  MultiBot._localeDefaults = defaults
end

function MultiBot.RegisterLocaleStrings(locale, values, isDefault)
  local normalized = sanitizeLocaleTable(values)
  if not normalized then
    return nil
  end

  if isDefault then
    registerDefaultStrings(normalized)
  end

  if not aceLocale then
    return nil
  end

  local localeTable = aceLocale:NewLocale(LOCALE_NAMESPACE, locale, isDefault)
  if not localeTable then
    local currentLocale = GetLocale and GetLocale() or nil
    if currentLocale and currentLocale == locale then
      localeTable = aceLocale:GetLocale(LOCALE_NAMESPACE, true)
    end
    if not localeTable then
      return nil
    end
  end

  for key, value in pairs(normalized) do
    localeTable[key] = value
  end

  return localeTable
end

function MultiBot.GetLocaleString(key, fallback)
  if type(key) ~= "string" then
    return fallback
  end

  if aceLocale then
    local activeLocale = aceLocale:GetLocale(LOCALE_NAMESPACE, true)
    local activeValue = type(activeLocale) == "table" and rawget(activeLocale, key) or nil
    if type(activeValue) == "string" then
      return activeValue
    end
  end

  local defaults = MultiBot._localeDefaults
  local defaultValue = defaults and defaults[key]
  if type(defaultValue) == "string" then
    return defaultValue
  end

  if type(fallback) == "string" then
    return fallback
  end

  return key
end


local function setValueByPath(root, keyPath, value)
  if type(root) ~= "table" or type(keyPath) ~= "string" then
    return
  end

  local target = root
  local startIndex = 1

  while true do
    local separatorIndex = string.find(keyPath, ".", startIndex, true)
    if not separatorIndex then
      local leafKey = string.sub(keyPath, startIndex)
      if leafKey ~= "" then
        target[leafKey] = value
      end
      return
    end

    local segment = string.sub(keyPath, startIndex, separatorIndex - 1)
    if segment == "" then
      return
    end

    local nextTarget = target[segment]
    if type(nextTarget) ~= "table" then
      nextTarget = {}
      target[segment] = nextTarget
    end

    target = nextTarget
    startIndex = separatorIndex + 1
  end
end

function MultiBot.ApplyLocaleKeyValues(localeValues)
  if type(localeValues) ~= "table" then
    return
  end

  for keyPath, value in pairs(localeValues) do
    if type(keyPath) == "string" and type(value) == "string" then
      setValueByPath(MultiBot, keyPath, value)
    end
  end
end

MultiBot.L = MultiBot.GetLocaleString