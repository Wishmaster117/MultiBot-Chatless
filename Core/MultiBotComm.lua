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
  state.bootstrapPending = state.bootstrapPending or false
  state.bootstrapDeadline = state.bootstrapDeadline or 0
  state.inventorySeq = state.inventorySeq or 0
  state.inventoryActive = state.inventoryActive or nil
  state.inventoryActive = state.inventoryActive or nil
  state.spellbookSeq = state.spellbookSeq or 0
  state.spellbookActive = state.spellbookActive or nil
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

  if opcode == "PVP_STATS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyPvpStatsPayload(payload)
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
  state.pvpStats = {}
  state.inventoryActive = nil
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