local MultiBot = _G.MultiBot
if not MultiBot then
  return
end

MultiBot.bridge = MultiBot.bridge or {}

local Comm = MultiBot.Comm or {}
MultiBot.Comm = Comm

Comm.prefix = "MBOT"
Comm.version = "1"

local function safeNow()
  if type(GetTime) == "function" then
    return GetTime()
  end

  return 0
end

local function safeDelay(delaySeconds, callback)
  if type(callback) ~= "function" then
    return
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(delaySeconds or 0, callback)
    return
  end

  callback()
end

local function trim(value)
  if type(value) ~= "string" then
    return ""
  end

  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function splitOnce(value, separator)
  if type(value) ~= "string" or value == "" then
    return "", ""
  end

  local startIndex, endIndex = string.find(value, separator, 1, true)
  if not startIndex then
    return value, ""
  end

  return string.sub(value, 1, startIndex - 1), string.sub(value, endIndex + 1)
end

local function urlDecodeField(value)
  if type(value) ~= "string" or value == "" then
    return ""
  end

  return (value:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16) or 0)
  end))
end

local function urlEncodeField(value)
  value = tostring(value or "")
  return (value:gsub("([%%~\r\n])", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end))
end

local function getPlayerName()
  if type(UnitName) ~= "function" then
    return nil
  end

  local name = UnitName("player")
  if type(name) ~= "string" or name == "" then
    return nil
  end

  return name
end

local function ensureBridgeState()
  local state = MultiBot.bridge
  state.connected = state.connected or false
  state.protocol = state.protocol or nil
  state.server = state.server or nil
  state.lastSendAt = state.lastSendAt or 0
  state.lastHelloAt = state.lastHelloAt or 0
  state.lastPingAt = state.lastPingAt or 0
  state.lastPongAt = state.lastPongAt or 0
  state.lastPingToken = state.lastPingToken or nil
  state.lastError = state.lastError or nil
  state.roster = state.roster or {}
  state.states = state.states or {}
  state.details = state.details or {}
  state.pvpStats = state.pvpStats or {}
  state.stats = state.stats or {}
  state.quests = state.quests or {}
  state.questSeq = state.questSeq or 0
  state.questActive = state.questActive or {}
  state.talentSpecs = state.talentSpecs or {}
  state.talentSpecSeq = state.talentSpecSeq or 0
  state.talentSpecActive = state.talentSpecActive or nil
  state.bootstrapPending = state.bootstrapPending or false
  state.bootstrapDeadline = state.bootstrapDeadline or 0
  state.inventorySeq = state.inventorySeq or 0
  state.inventoryActive = state.inventoryActive or nil
  state.spellbookSeq = state.spellbookSeq or 0
  state.spellbookActive = state.spellbookActive or nil
  state.outfitSeq = state.outfitSeq or 0
  state.outfitActive = state.outfitActive or nil
  state.outfitCommands = state.outfitCommands or {}
  state.glyphs = state.glyphs or {}
  state.glyphSeq = state.glyphSeq or 0
  state.glyphActive = state.glyphActive or nil
  return state
end

local function debugPrint(...)
  if MultiBot and MultiBot.dprint then
    MultiBot.dprint(...)
  end
end

local function buildMessage(opcode, payload)
  local message = trim(opcode)
  if payload ~= nil and payload ~= "" then
    message = message .. "~" .. tostring(payload)
  end
  return message
end

function Comm.Send(opcode, payload)
  local state = ensureBridgeState()
  local playerName = getPlayerName()
  if not playerName or type(SendAddonMessage) ~= "function" then
    return false
  end

  local channel = "WHISPER"
  if type(GetNumRaidMembers) == "function" and GetNumRaidMembers() and GetNumRaidMembers() > 0 then
    channel = "RAID"
  elseif type(GetNumPartyMembers) == "function" and GetNumPartyMembers() and GetNumPartyMembers() > 0 then
    channel = "PARTY"
  end

  local message = buildMessage(opcode, payload)
  if channel == "WHISPER" then
    SendAddonMessage(Comm.prefix, message, channel, playerName)
  else
    SendAddonMessage(Comm.prefix, message, channel)
  end

  state.lastSendAt = safeNow()
  debugPrint("ADDON:TX", channel, opcode, payload or "")
  return true
end

function Comm.SendHello()
  local state = ensureBridgeState()
  state.lastHelloAt = safeNow()
  return Comm.Send("HELLO", Comm.version)
end

function Comm.SendPing()
  local state = ensureBridgeState()
  local token = tostring(math.floor(safeNow() * 1000))
  state.lastPingToken = token
  state.lastPingAt = safeNow()
  return Comm.Send("PING", token)
end

function Comm.RequestRoster()
  return Comm.Send("GET", "ROSTER")
end

function Comm.RequestState(name)
  name = trim(name)
  if name == "" then
    return false
  end

  return Comm.Send("GET", "STATE~" .. name)
end

function Comm.RequestStates()
  return Comm.Send("GET", "STATES")
end

function Comm.RequestBotDetail(name)
  name = trim(name)
  if name == "" then
    return false
  end

  return Comm.Send("GET", "DETAIL~" .. name)
end

function Comm.RequestBotDetails()
  return Comm.Send("GET", "DETAILS")
end

function Comm.RequestStats(name)
  ensureBridgeState()

  name = trim(name)
  if name ~= "" then
    return Comm.Send("GET", "STATS~" .. name)
  end

  return Comm.Send("GET", "STATS")
end

function Comm.RequestTalentSpecList(name)
  local state = ensureBridgeState()
  if not state.connected and not state.bootstrapPending then
    return false
  end

  name = trim(name)
  if name == "" then
    return false
  end

  state.talentSpecSeq = (tonumber(state.talentSpecSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.talentSpecSeq)
  state.talentSpecActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "TALENT_SPEC_LIST~" .. name .. "~" .. token) then
    state.talentSpecActive = nil
    return false
  end

  return token
end

function Comm.RequestOutfits(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.outfitSeq = (tonumber(state.outfitSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.outfitSeq)
  state.outfitActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    lines = {},
  }

  if not Comm.Send("GET", "OUTFITS~" .. name .. "~" .. token) then
    state.outfitActive = nil
    return false
  end

  return true
end

function Comm.RunOutfitCommand(name, commandSuffix, persist)
  local state = ensureBridgeState()
  name = trim(name)
  commandSuffix = trim(commandSuffix)
  if name == "" or commandSuffix == "" or not state.connected then
    return false
  end

  state.outfitSeq = (tonumber(state.outfitSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-cmd-" .. tostring(state.outfitSeq)
  state.outfitCommands[token] = {
    botName = name,
    botNameKey = string.lower(name),
    command = commandSuffix,
    startedAt = safeNow(),
  }

  local persistToken = persist and "1" or "0"
  if not Comm.Send("RUN", "OUTFIT~" .. name .. "~" .. token .. "~" .. urlEncodeField(commandSuffix) .. "~" .. persistToken) then
    state.outfitCommands[token] = nil
    return false
  end

  return true
end

function Comm.RequestGlyphs(name)
  local state = ensureBridgeState()
  if not state.connected and not state.bootstrapPending then
    return false
  end

  name = trim(name)
  if name == "" then
    return false
  end

  state.glyphSeq = (tonumber(state.glyphSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.glyphSeq)
  state.glyphActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "GLYPHS~" .. name .. "~" .. token) then
    state.glyphActive = nil
    return false
  end

  return token
end

function Comm.RequestQuests(mode, name)
  local state = ensureBridgeState()
  if not state.connected and not state.bootstrapPending then
    return false
  end

  mode = string.upper(trim(mode or "ALL"))
  if mode ~= "INCOMPLETED" and mode ~= "COMPLETED" and mode ~= "ALL" then
    mode = "ALL"
  end

  name = trim(name)
  state.questSeq = (tonumber(state.questSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.questSeq)

  state.questActive[token] = {
    mode = mode,
    botName = name,
    isGroup = name == "",
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "QUESTS~" .. mode .. "~" .. name .. "~" .. token) then
    state.questActive[token] = nil
    return false
  end

  return token
end

function Comm.RequestPvpStats(name)
  ensureBridgeState()

  name = trim(name)
  if name ~= "" then
    return Comm.Send("GET", "PVP_STATS~" .. name)
  end

  return Comm.Send("GET", "PVP_STATS")
end

function Comm.RequestInventory(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.inventorySeq = (tonumber(state.inventorySeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.inventorySeq)
  state.inventoryActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "INVENTORY~" .. name .. "~" .. token) then
    state.inventoryActive = nil
    return false
  end

  return true
end

function Comm.RequestSpellbook(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.spellbookSeq = (tonumber(state.spellbookSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.spellbookSeq)
  state.spellbookActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "SPELLBOOK~" .. name .. "~" .. token) then
    state.spellbookActive = nil
    return false
  end

  return true
end

function Comm.MarkDisconnected(reason)
  local state = ensureBridgeState()
  state.connected = false
  state.server = nil
  state.protocol = nil
  state.lastError = reason or nil
  state.inventoryActive = nil
  state.spellbookActive = nil
  state.outfitActive = nil
  state.outfitCommands = {}
end

local function parseBridgeDetailPayload(payload)
  local name, rest = splitOnce(payload or "", "~")
  local race, rest2 = splitOnce(rest or "", "~")
  local gender, rest3 = splitOnce(rest2 or "", "~")
  local className, rest4 = splitOnce(rest3 or "", "~")
  local level, rest5 = splitOnce(rest4 or "", "~")
  local talent1, rest6 = splitOnce(rest5 or "", "~")
  local talent2, rest7 = splitOnce(rest6 or "", "~")
  local talent3, score = splitOnce(rest7 or "", "~")

  name = trim(urlDecodeField(name))
  if name == "" then
    return nil
  end

  return {
    name = name,
    race = urlDecodeField(race),
    gender = urlDecodeField(gender),
    className = urlDecodeField(className),
    level = tonumber(level or "0") or 0,
    talent1 = tonumber(talent1 or "0") or 0,
    talent2 = tonumber(talent2 or "0") or 0,
    talent3 = tonumber(talent3 or "0") or 0,
    score = tonumber(score or "0") or 0,
    lastUpdateAt = safeNow(),
  }
end

local function parseRosterEntry(entry)
  local fields = {}
  for value in string.gmatch(entry or "", "([^,]+)") do
    fields[#fields + 1] = value
  end

  return {
    name = fields[1],
    classId = tonumber(fields[2] or "0") or 0,
    level = tonumber(fields[3] or "0") or 0,
    mapId = tonumber(fields[4] or "0") or 0,
    alive = fields[5] == "1",
    hpPct = tonumber(fields[6] or "0") or 0,
    mpPct = tonumber(fields[7] or "0") or 0,
  }
end

function Comm.ApplyRosterPayload(payload)
  local state = ensureBridgeState()
  local roster = {}

  if type(payload) == "string" and payload ~= "" then
    for entry in string.gmatch(payload, "([^;]+)") do
      roster[#roster + 1] = parseRosterEntry(entry)
    end
  end

  state.roster = roster

  if MultiBot.SyncBridgeRosterToPlayers then
    MultiBot.SyncBridgeRosterToPlayers(roster)
  end

  if state.connected and Comm.RequestBotDetails then
    Comm.RequestBotDetails()
  end

  debugPrint("ADDON:RX", "ROSTER", tostring(#roster))
  return roster
end

function Comm.ApplyStatePayload(payload)
  local state = ensureBridgeState()
  local name, rest = splitOnce(payload or "", "~")
  local combat, normal = splitOnce(rest or "", "~")

  name = trim(name)
  if name == "" then
    return nil
  end

  local entry = {
    name = name,
    combat = combat or "",
    normal = normal or "",
    lastUpdateAt = safeNow(),
  }

  state.states[string.lower(name)] = entry

  if MultiBot.ApplyBridgeBotState then
    MultiBot.ApplyBridgeBotState(name, entry.combat, entry.normal)
  end

  debugPrint("ADDON:RX", "STATE", name, entry.combat, entry.normal)
  return entry
end

function Comm.ApplyStatesPayload(payload)
  local applied = 0

  if type(payload) == "string" and payload ~= "" then
    for entryPayload in string.gmatch(payload, "([^;]+)") do
      if Comm.ApplyStatePayload(entryPayload) then
        applied = applied + 1
      end
    end
  end

  debugPrint("ADDON:RX", "STATES", tostring(applied))
  return applied
end

function Comm.ApplyBotDetailPayload(payload)
  local state = ensureBridgeState()
  local detail = parseBridgeDetailPayload(payload)
  if not detail then
    return nil
  end

  state.details[string.lower(detail.name)] = detail

  if MultiBot.ApplyBridgeBotDetail then
    MultiBot.ApplyBridgeBotDetail(detail)
  end

  debugPrint("ADDON:RX", "DETAIL", detail.name, detail.className or "", tostring(detail.level or 0), tostring(detail.score or 0))
  return detail
end

function Comm.ApplyBotDetailsPayload(payload)
  local applied = 0

  if type(payload) == "string" and payload ~= "" then
    for entryPayload in string.gmatch(payload, "([^;]+)") do
      if Comm.ApplyBotDetailPayload(entryPayload) then
        applied = applied + 1
      end
    end
  end

  debugPrint("ADDON:RX", "DETAILS", tostring(applied))
  return applied
end

local function parseStatsPayload(payload)
  local name, rest = splitOnce(payload or "", "~")
  local level, rest2 = splitOnce(rest or "", "~")
  local gold, rest3 = splitOnce(rest2 or "", "~")
  local silver, rest4 = splitOnce(rest3 or "", "~")
  local copper, rest5 = splitOnce(rest4 or "", "~")
  local bagUsed, rest6 = splitOnce(rest5 or "", "~")
  local bagTotal, rest7 = splitOnce(rest6 or "", "~")
  local durabilityPct, rest8 = splitOnce(rest7 or "", "~")
  local xpPct, manaPct = splitOnce(rest8 or "", "~")

  name = trim(urlDecodeField(name))
  if name == "" then
    return nil
  end

  return {
    name = name,
    level = tonumber(level or "0") or 0,
    gold = tonumber(gold or "0") or 0,
    silver = tonumber(silver or "0") or 0,
    copper = tonumber(copper or "0") or 0,
    bagUsed = tonumber(bagUsed or "0") or 0,
    bagTotal = tonumber(bagTotal or "0") or 0,
    durabilityPct = tonumber(durabilityPct or "0") or 0,
    xpPct = tonumber(xpPct or "0") or 0,
    manaPct = tonumber(manaPct or "0") or 0,
    lastUpdateAt = safeNow(),
  }
end

function Comm.ApplyStatsPayload(payload)
  local state = ensureBridgeState()
  local stats = parseStatsPayload(payload)
  if not stats then
    return nil
  end

  state.stats[string.lower(stats.name)] = stats

  if MultiBot.ApplyBridgeStats then
    MultiBot.ApplyBridgeStats(stats)
  end

  debugPrint(
    "ADDON:RX",
    "STATS",
    stats.name,
    tostring(stats.level or 0),
    tostring(stats.bagUsed or 0) .. "/" .. tostring(stats.bagTotal or 0),
    tostring(stats.durabilityPct or 0)
  )

  return stats
end

local function parsePvpStatsPayload(payload)
  local name, rest = splitOnce(payload or "", "~")
  local arenaPoints, rest2 = splitOnce(rest or "", "~")
  local honorPoints, rest3 = splitOnce(rest2 or "", "~")
  local team2v2, rest4 = splitOnce(rest3 or "", "~")
  local rating2v2, rest5 = splitOnce(rest4 or "", "~")
  local team3v3, rest6 = splitOnce(rest5 or "", "~")
  local rating3v3, rest7 = splitOnce(rest6 or "", "~")
  local team5v5, rating5v5 = splitOnce(rest7 or "", "~")

  name = trim(urlDecodeField(name))
  if name == "" then
    return nil
  end

  return {
    name = name,
    arenaPoints = tonumber(arenaPoints or "0") or 0,
    honorPoints = tonumber(honorPoints or "0") or 0,
    teams = {
      ["2v2"] = {
        team = urlDecodeField(team2v2),
        rating = tonumber(rating2v2 or "0") or 0,
      },
      ["3v3"] = {
        team = urlDecodeField(team3v3),
        rating = tonumber(rating3v3 or "0") or 0,
      },
      ["5v5"] = {
        team = urlDecodeField(team5v5),
        rating = tonumber(rating5v5 or "0") or 0,
      },
    },
    lastUpdateAt = safeNow(),
  }
end

function Comm.ApplyPvpStatsPayload(payload)
  local state = ensureBridgeState()
  local stats = parsePvpStatsPayload(payload)
  if not stats then
    return nil
  end

  state.pvpStats[string.lower(stats.name)] = stats

  if MultiBot.ApplyBridgePvpStats then
    MultiBot.ApplyBridgePvpStats(stats)
  end

  debugPrint(
    "ADDON:RX",
    "PVP_STATS",
    stats.name,
    tostring(stats.arenaPoints or 0),
    tostring(stats.honorPoints or 0)
  )

  return stats
end

local function ensureRuntimeTable(key)
  if MultiBot.Store and MultiBot.Store.EnsureRuntimeTable then
    return MultiBot.Store.EnsureRuntimeTable(key)
  end

  MultiBot[key] = type(MultiBot[key]) == "table" and MultiBot[key] or {}
  return MultiBot[key]
end

local function normalizeQuestMode(mode)
  mode = string.upper(trim(mode or "ALL"))
  if mode ~= "INCOMPLETED" and mode ~= "COMPLETED" and mode ~= "ALL" then
    mode = "ALL"
  end
  return mode
end

local function getActiveQuestRequest(token)
  local state = ensureBridgeState()
  token = trim(token)
  if token == "" then
    return nil
  end

  return state.questActive and state.questActive[token] or nil
end

local function buildQuestLink(questID, questName)
  questID = tonumber(questID or 0) or 0
  questName = tostring(questName or questID)
  return "|Hquest:" .. tostring(questID) .. ":0|h[" .. questName .. "]|h"
end

local function clearQuestStoresForMode(botName, mode)
  if type(botName) ~= "string" or botName == "" then
    return
  end

  mode = normalizeQuestMode(mode)

  if mode == "INCOMPLETED" or mode == "ALL" then
    ensureRuntimeTable("BotQuestsIncompleted")[botName] = {}
  end

  if mode == "COMPLETED" or mode == "ALL" then
    ensureRuntimeTable("BotQuestsCompleted")[botName] = {}
  end

  if mode == "ALL" then
    ensureRuntimeTable("BotQuestsAll")[botName] = {}
  end
end

function Comm.ApplyQuestBeginPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, mode = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  mode = normalizeQuestMode(mode)

  if botName == "" or not getActiveQuestRequest(token) then
    return false
  end

  clearQuestStoresForMode(botName, mode)
  debugPrint("ADDON:RX", "QUESTS_BEGIN", botName, mode)
  return true
end

function Comm.ApplyQuestItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local mode, rest3 = splitOnce(rest2 or "", "~")
  local status, rest4 = splitOnce(rest3 or "", "~")
  local questID, questName = splitOnce(rest4 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  mode = normalizeQuestMode(mode)
  status = string.upper(trim(status))
  questID = tonumber(questID or "0") or 0
  questName = trim(urlDecodeField(questName))
  if questName == "" then
    questName = tostring(questID)
  end

  if botName == "" or questID <= 0 or not getActiveQuestRequest(token) then
    return false
  end

  local incompletedStore = ensureRuntimeTable("BotQuestsIncompleted")
  local completedStore = ensureRuntimeTable("BotQuestsCompleted")
  local allStore = ensureRuntimeTable("BotQuestsAll")

  if status == "I" then
    incompletedStore[botName] = incompletedStore[botName] or {}
    incompletedStore[botName][questID] = questName
  elseif status == "C" then
    completedStore[botName] = completedStore[botName] or {}
    completedStore[botName][questID] = questName
  else
    return false
  end

  if mode == "ALL" then
    allStore[botName] = allStore[botName] or {}
    table.insert(allStore[botName], buildQuestLink(questID, questName))
  end

  debugPrint("ADDON:RX", "QUESTS_ITEM", botName, mode, status, tostring(questID))
  return true
end

function Comm.ApplyQuestEndPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, mode = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  mode = normalizeQuestMode(mode)

  if botName == "" or not getActiveQuestRequest(token) then
    return false
  end

  debugPrint("ADDON:RX", "QUESTS_END", botName, mode)
  return true
end

function Comm.ApplyQuestDonePayload(payload)
  local token, mode = splitOnce(payload or "", "~")
  token = trim(token)
  mode = normalizeQuestMode(mode)

  local state = ensureBridgeState()
  local request = getActiveQuestRequest(token)
  if not request then
    return false
  end

  state.questActive[token] = nil
  state.quests.lastMode = mode
  state.quests.lastDoneAt = safeNow()

  if MultiBot.OnBridgeQuestsDone then
    MultiBot.OnBridgeQuestsDone(mode, request)
  end

  debugPrint("ADDON:RX", "QUESTS_DONE", mode)
  return true
end

local function getActiveTalentSpecRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.talentSpecActive
  if type(active) ~= "table" then
    return nil
  end

  if trim(token) ~= trim(active.token or "") then
    return nil
  end

  if string.lower(trim(botName)) ~= tostring(active.botNameKey or "") then
    return nil
  end

  return active
end

function Comm.ApplyTalentSpecBeginPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveTalentSpecRequest(botName, token) then
    return false
  end

  local state = ensureBridgeState()
  state.talentSpecs[string.lower(botName)] = {}

  if MultiBot.ApplyBridgeTalentSpecBegin then
    MultiBot.ApplyBridgeTalentSpecBegin(botName, token)
  end

  debugPrint("ADDON:RX", "TALENT_SPEC_BEGIN", botName)
  return true
end

function Comm.ApplyTalentSpecItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local index, rest3 = splitOnce(rest2 or "", "~")
  local specName, build = splitOnce(rest3 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  index = tonumber(index or "0") or 0
  specName = trim(urlDecodeField(specName))
  build = trim(build)

  if botName == "" or specName == "" or not getActiveTalentSpecRequest(botName, token) then
    return false
  end

  local entry = {
    index = index,
    name = specName,
    build = build,
  }

  local state = ensureBridgeState()
  local key = string.lower(botName)
  state.talentSpecs[key] = state.talentSpecs[key] or {}
  table.insert(state.talentSpecs[key], entry)

  if MultiBot.ApplyBridgeTalentSpecItem then
    MultiBot.ApplyBridgeTalentSpecItem(botName, token, entry)
  end

  debugPrint("ADDON:RX", "TALENT_SPEC_ITEM", botName, specName, build)
  return true
end

local function getActiveGlyphRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.glyphActive
  if type(active) ~= "table" then
    return nil
  end

  if trim(token) ~= trim(active.token or "") then
    return nil
  end

  if string.lower(trim(botName)) ~= tostring(active.botNameKey or "") then
    return nil
  end

  return active
end

local function applyBridgeGlyphs(botName, token)
  local state = ensureBridgeState()
  local key = string.lower(botName)
  local glyphs = state.glyphs[key] or {}

  table.sort(glyphs, function(a, b)
    return (tonumber(a.index) or 0) < (tonumber(b.index) or 0)
  end)

  MultiBot.receivedGlyphs = MultiBot.receivedGlyphs or {}
  MultiBot.receivedGlyphs[botName] = glyphs

  if MultiBot.awaitGlyphs == botName then
    MultiBot.awaitGlyphs = nil
  end

  if MultiBot.ApplyBridgeGlyphs then
    MultiBot.ApplyBridgeGlyphs(botName, glyphs, token)
  elseif MultiBot.talent and MultiBot.talent.OnBridgeGlyphs then
    MultiBot.talent.OnBridgeGlyphs(botName, token, glyphs)
  elseif MultiBot.talent and MultiBot.talent.name == botName and MultiBot.FillDefaultGlyphs then
    MultiBot.FillDefaultGlyphs()
  end
end

local function getActiveOutfitRequest(botName, token)
  local active = ensureBridgeState().outfitActive
  if not active then return nil end
  botName = trim(botName)
  token = trim(token)
  if token ~= active.token then return nil end
  if botName ~= "" and string.lower(botName) ~= active.botNameKey then return nil end
  return active
end

local function clearActiveOutfitRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveOutfitRequest(botName, token) then
    state.outfitActive = nil
  end
end

function Comm.ApplyOutfitsBeginPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveOutfitRequest(botName, token) then
    return false
  end

  local active = getActiveOutfitRequest(botName, token)
  if active then
    active.botName = botName
    active.botNameKey = string.lower(botName)
    active.lines = {}
  end

  if MultiBot.OutfitUI and MultiBot.OutfitUI.HandleBridgeBegin then
    MultiBot.OutfitUI:HandleBridgeBegin(botName, token)
  end

  debugPrint("ADDON:RX", "OUTFITS_BEGIN", botName)
  return true
end

function Comm.ApplyOutfitsItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, encodedLine = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  local active = getActiveOutfitRequest(botName, token)
  if botName == "" or not active then
    return false
  end

  local rawLine = urlDecodeField(encodedLine)
  active.lines[#active.lines + 1] = rawLine

  if MultiBot.OutfitUI and MultiBot.OutfitUI.HandleBridgeLine then
    MultiBot.OutfitUI:HandleBridgeLine(botName, token, rawLine)
  end

  debugPrint("ADDON:RX", "OUTFITS_ITEM", botName, rawLine)
  return true
end

function Comm.ApplyOutfitsEndPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveOutfitRequest(botName, token) then
    return false
  end

  if MultiBot.OutfitUI and MultiBot.OutfitUI.HandleBridgeEnd then
    MultiBot.OutfitUI:HandleBridgeEnd(botName, token)
  end

  clearActiveOutfitRequest(botName, token)
  debugPrint("ADDON:RX", "OUTFITS_END", botName)
  return true
end

function Comm.ApplyOutfitCommandPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, result = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  result = trim(result)

  local state = ensureBridgeState()
  local command = state.outfitCommands and state.outfitCommands[token] or nil
  if not command then
    return false
  end

  command.botName = botName ~= "" and botName or command.botName
  command.botNameKey = string.lower(command.botName or "")
  command.result = result

  if MultiBot.OutfitUI and MultiBot.OutfitUI.HandleBridgeCommandResult then
    MultiBot.OutfitUI:HandleBridgeCommandResult(command.botName, token, result)
  end

  state.outfitCommands[token] = nil
  debugPrint("ADDON:RX", "OUTFITS_CMD", command.botName, result)
  return true
end

function Comm.ApplyGlyphsBeginPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveGlyphRequest(botName, token) then
    return false
  end

  local state = ensureBridgeState()
  state.glyphs[string.lower(botName)] = {}

  debugPrint("ADDON:RX", "GLYPHS_BEGIN", botName)
  return true
end

function Comm.ApplyGlyphsItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local index, rest3 = splitOnce(rest2 or "", "~")
  local itemId, rest4 = splitOnce(rest3 or "", "~")
  local glyphId, rest5 = splitOnce(rest4 or "", "~")
  local spellId, glyphType = splitOnce(rest5 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveGlyphRequest(botName, token) then
    return false
  end

  local entry = {
    index = tonumber(index or "0") or 0,
    id = tonumber(itemId or "0") or 0,
    itemId = tonumber(itemId or "0") or 0,
    glyphId = tonumber(glyphId or "0") or 0,
    spellId = tonumber(spellId or "0") or 0,
    type = trim(urlDecodeField(glyphType or "")),
  }

  local state = ensureBridgeState()
  local key = string.lower(botName)
  state.glyphs[key] = state.glyphs[key] or {}
  table.insert(state.glyphs[key], entry)

  debugPrint("ADDON:RX", "GLYPHS_ITEM", botName, entry.index, entry.itemId, entry.glyphId, entry.spellId, entry.type)
  return true
end

function Comm.ApplyGlyphsPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, entries = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" then
    return false
  end

  local state = ensureBridgeState()
  local key = string.lower(botName)
  state.glyphs[key] = {}

  local fields = { strsplit("~", entries or "") }
  for i = 1, #fields do
    local raw = fields[i]
    if raw and raw ~= "" then
      local itemId, r1 = splitOnce(raw, ":")
      local glyphId, r2 = splitOnce(r1 or "", ":")
      local spellId, glyphType = splitOnce(r2 or "", ":")
      table.insert(state.glyphs[key], {
        index = #state.glyphs[key] + 1,
        id = tonumber(itemId or "0") or 0,
        itemId = tonumber(itemId or "0") or 0,
        glyphId = tonumber(glyphId or "0") or 0,
        spellId = tonumber(spellId or "0") or 0,
        type = trim(urlDecodeField(glyphType or "")),
      })
    end
  end

  applyBridgeGlyphs(botName, token)
  debugPrint("ADDON:RX", "GLYPHS", botName, #state.glyphs[key])
  return true
end

function Comm.ApplyGlyphsEndPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveGlyphRequest(botName, token) then
    return false
  end

  applyBridgeGlyphs(botName, token)

  local state = ensureBridgeState()
  state.glyphActive = nil

  debugPrint("ADDON:RX", "GLYPHS_END", botName)
  return true
end

function Comm.ApplyTalentSpecEndPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)

  if botName == "" or not getActiveTalentSpecRequest(botName, token) then
    return false
  end

  local state = ensureBridgeState()
  state.talentSpecActive = nil

  if MultiBot.ApplyBridgeTalentSpecEnd then
    MultiBot.ApplyBridgeTalentSpecEnd(botName, token)
  end

  debugPrint("ADDON:RX", "TALENT_SPEC_END", botName)
  return true
end

local function getActiveInventoryRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.inventoryActive
  if not active then
    return nil
  end

  if trim(token) ~= trim(active.token) then
    return nil
  end

  if string.lower(trim(botName)) ~= tostring(active.botNameKey or "") then
    return nil
  end

  return active
end

local function clearActiveInventoryRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveInventoryRequest(botName, token) then
    state.inventoryActive = nil
  end
end

local function getInventoryFrame()
  return MultiBot and MultiBot.inventory or nil
end

local function getActiveSpellbookRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.spellbookActive
  if type(active) ~= "table" then
    return nil
  end

  if botName and botName ~= "" and string.lower(trim(botName)) ~= trim(active.botNameKey or "") then
    return nil
  end

  if token and token ~= "" and tostring(token) ~= tostring(active.token or "") then
    return nil
  end

  return active
end

local function clearActiveSpellbookRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveSpellbookRequest(botName, token) then
    state.spellbookActive = nil
  end
end

local function getSpellbookFrame()
  return MultiBot and MultiBot.spellbook or nil
end

function Comm.HandleAddonMessage(prefix, message, distribution, sender)
  if prefix ~= Comm.prefix then
    return false
  end

  local state = ensureBridgeState()
  local opcode, payload = splitOnce(message or "", "~")
  opcode = string.upper(trim(opcode))

  if opcode == "HELLO_ACK" then
    local protocol, serverName = splitOnce(payload, "~")
    local wasConnected = state.connected == true

    state.connected = true
    state.protocol = protocol ~= "" and protocol or nil
    state.server = serverName ~= "" and serverName or nil
    state.lastError = nil
    debugPrint("ADDON:RX", "HELLO_ACK", payload or "")

    if (not wasConnected or state.bootstrapPending) and state.protocol then
      safeDelay(0.10, function()
        if MultiBot and MultiBot.bridge and MultiBot.bridge.connected then
          state.bootstrapPending = false
          state.bootstrapDeadline = 0
          if Comm.RequestRoster then
            Comm.RequestRoster()
          end
          if Comm.RequestStates then
            Comm.RequestStates()
          end
          if Comm.RequestBotDetails then
            Comm.RequestBotDetails()
          end
        end
      end)
    else
      state.bootstrapPending = false
      state.bootstrapDeadline = 0
    end

    return true
  end

  if opcode == "PONG" then
    state.connected = true
    state.lastPongAt = safeNow()
    state.lastError = nil
    state.bootstrapPending = false
    state.bootstrapDeadline = 0
    debugPrint("ADDON:RX", "PONG", payload or "")
    return true
  end

  if opcode == "ROSTER" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyRosterPayload(payload)
    return true
  end

  if opcode == "STATE" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStatePayload(payload)
    return true
  end

  if opcode == "STATES" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStatesPayload(payload)
    return true
  end

  if opcode == "DETAIL" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyBotDetailPayload(payload)
    return true
  end

  if opcode == "DETAILS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyBotDetailsPayload(payload)
    return true
  end

  if opcode == "TALENT_SPEC_BEGIN" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyTalentSpecBeginPayload(payload)
    return true
  end

  if opcode == "TALENT_SPEC_ITEM" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyTalentSpecItemPayload(payload)
    return true
  end

  if opcode == "TALENT_SPEC_END" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyTalentSpecEndPayload(payload)
    return true
  end

  if opcode == "OUTFITS_BEGIN" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyOutfitsBeginPayload(payload)
  end

  if opcode == "OUTFITS_ITEM" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyOutfitsItemPayload(payload)
  end

  if opcode == "OUTFITS_END" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyOutfitsEndPayload(payload)
  end

  if opcode == "OUTFITS_CMD" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyOutfitCommandPayload(payload)
  end

  if opcode == "GLYPHS_BEGIN" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyGlyphsBeginPayload(payload)
    return true
  end

  if opcode == "GLYPHS_ITEM" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyGlyphsItemPayload(payload)
    return true
  end

  if opcode == "GLYPHS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyGlyphsPayload(payload)
    return true
  end

  if opcode == "GLYPHS_END" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyGlyphsEndPayload(payload)
    return true
  end

  if opcode == "QUESTS_BEGIN" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyQuestBeginPayload(payload)
    return true
  end

  if opcode == "QUESTS_ITEM" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyQuestItemPayload(payload)
    return true
  end

  if opcode == "QUESTS_END" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyQuestEndPayload(payload)
    return true
  end

  if opcode == "QUESTS_DONE" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyQuestDonePayload(payload)
    return true
  end

  if opcode == "PVP_STATS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyPvpStatsPayload(payload)
    return true
  end

  if opcode == "STATS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStatsPayload(payload)
    return true
  end

  if opcode == "INV_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    if getActiveInventoryRequest(botName, token) then
      local inventory = getInventoryFrame()
      if inventory and inventory.beginPayload then
        inventory:beginPayload(trim(botName))
      end
    end

    return true
  end

  if opcode == "INV_SUMMARY" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local gold, rest3 = splitOnce(rest2 or "", "~")
    local silver, rest4 = splitOnce(rest3 or "", "~")
    local copper, rest5 = splitOnce(rest4 or "", "~")
    local bagUsed, bagTotal = splitOnce(rest5 or "", "~")

    state.connected = true
    state.lastError = nil

    if getActiveInventoryRequest(botName, token) then
      local inventory = getInventoryFrame()
      if inventory and inventory.applySummaryData then
        inventory:applySummaryData({
          gold = tonumber(gold or "0") or 0,
          silver = tonumber(silver or "0") or 0,
          copper = tonumber(copper or "0") or 0,
          bagUsed = tonumber(bagUsed or "0") or 0,
          bagTotal = tonumber(bagTotal or "0") or 0,
        })
      end
    end

    return true
  end

  if opcode == "INV_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, encodedLine = splitOnce(rest or "", "~")

    state.connected = true
    state.lastError = nil

    if getActiveInventoryRequest(botName, token) then
      local inventory = getInventoryFrame()
      local itemsFrame = inventory and inventory.frames and inventory.frames.Items or nil
      if itemsFrame and itemsFrame.addChatItem then
        itemsFrame:addChatItem(urlDecodeField(encodedLine))
        if itemsFrame.updateCanvas then
          itemsFrame:updateCanvas()
        end
      end
    end

    return true
  end

  if opcode == "INV_END" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    if getActiveInventoryRequest(botName, token) then
      local inventory = getInventoryFrame()
      local itemsFrame = inventory and inventory.frames and inventory.frames.Items or nil
      if itemsFrame then
        if itemsFrame.updateCanvas then
          itemsFrame:updateCanvas()
        end
        if itemsFrame.updateLayout then
          itemsFrame:updateLayout()
        end
      end
    end

    clearActiveInventoryRequest(botName, token)
    return true
  end

  if opcode == "SB_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    if getActiveSpellbookRequest(botName, token) then
      local spellbook = getSpellbookFrame()
      if spellbook and spellbook.beginPayload then
        spellbook:beginPayload(trim(botName))
      elseif MultiBot and MultiBot.beginSpellbookCollection then
        MultiBot.beginSpellbookCollection(trim(botName))
      end
    end

    return true
  end

  if opcode == "SB_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, spellId = splitOnce(rest or "", "~")

    state.connected = true
    state.lastError = nil

    if getActiveSpellbookRequest(botName, token) then
      local spellbook = getSpellbookFrame()
      if spellbook and spellbook.appendSpellId then
        spellbook:appendSpellId(tonumber(spellId or "0") or 0, trim(botName))
      elseif MultiBot and MultiBot.addSpellById then
        MultiBot.addSpellById(tonumber(spellId or "0") or 0, trim(botName))
      end
    end

    return true
  end

  if opcode == "SB_END" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    if getActiveSpellbookRequest(botName, token) then
      local spellbook = getSpellbookFrame()
      if spellbook and spellbook.finishPayload then
        spellbook:finishPayload()
      elseif MultiBot and MultiBot.finishSpellbookCollection then
        MultiBot.finishSpellbookCollection()
      end
    end

    clearActiveSpellbookRequest(botName, token)
    return true
  end

  if opcode == "ERR" then
    state.lastError = payload
    debugPrint("ADDON:RX", "ERR", payload or "")
    return true
  end

  debugPrint("ADDON:RX", opcode, payload or "")
  return true
end

local function dispatchBootstrapRequests()
  Comm.SendHello()
  Comm.SendPing()
  Comm.RequestRoster()
  if Comm.RequestStates then
    Comm.RequestStates()
  end
  if Comm.RequestBotDetails then
    Comm.RequestBotDetails()
  end
end

function Comm.OnPlayerEnteringWorld()
  local state = ensureBridgeState()
  state.states = {}
  state.details = {}
  state.stats = {}
  state.pvpStats = {}
  state.quests = {}
  state.questActive = {}
  state.talentSpecs = {}
  state.talentSpecActive = nil
  state.inventoryActive = nil
  state.spellbookActive = nil
  state.outfitActive = nil
  state.outfitCommands = {}
  Comm.MarkDisconnected(nil)
  state.bootstrapPending = true
  state.bootstrapDeadline = safeNow() + 4.0

  local function expireBootstrap()
    local bridge = ensureBridgeState()
    if not bridge.connected and bridge.bootstrapPending and bridge.bootstrapDeadline > 0 and safeNow() >= bridge.bootstrapDeadline then
      bridge.bootstrapPending = false
      bridge.bootstrapDeadline = 0
    end
  end

  if not MultiBot.TimerAfter then
    dispatchBootstrapRequests()
    expireBootstrap()
    return
  end

  dispatchBootstrapRequests()

  MultiBot.TimerAfter(1.0, function()
    dispatchBootstrapRequests()
  end)

  MultiBot.TimerAfter(4.1, expireBootstrap)
end

ensureBridgeState()