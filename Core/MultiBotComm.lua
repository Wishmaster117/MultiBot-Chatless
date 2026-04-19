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
  state.bootstrapPending = state.bootstrapPending or false
  state.bootstrapDeadline = state.bootstrapDeadline or 0
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

function Comm.MarkDisconnected(reason)
  local state = ensureBridgeState()
  state.connected = false
  state.server = nil
  state.protocol = nil
  state.lastError = reason or nil
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

  if opcode == "ERR" then
    state.lastError = payload
    debugPrint("ADDON:RX", "ERR", payload or "")
    return true
  end

  debugPrint("ADDON:RX", opcode, payload or "")
  return true
end

function Comm.OnPlayerEnteringWorld()
  local state = ensureBridgeState()
  state.states = {}
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
    Comm.SendHello()
    Comm.SendPing()
    Comm.RequestRoster()
    if Comm.RequestStates then
      Comm.RequestStates()
    end
    expireBootstrap()
    return
  end

  MultiBot.TimerAfter(1.0, function()
    Comm.SendHello()
    Comm.SendPing()
    Comm.RequestRoster()
    if Comm.RequestStates then
      Comm.RequestStates()
    end
  end)

  MultiBot.TimerAfter(4.1, expireBootstrap)
end

ensureBridgeState()