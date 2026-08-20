local MultiBot = _G.MultiBot
if not MultiBot then
  return
end

MultiBot.bridge = MultiBot.bridge or {}

local Comm = MultiBot.Comm or {}
MultiBot.Comm = Comm

Comm.prefix = "MBOT"
Comm.version = "1"

local STATE_FRAMING_CAPABILITY = "STATE_FRAMING_V1"
local STRATEGY_MUTATION_CAPABILITY = "STRATEGY_MUTATION_V1"
local SELF_ACTION_CAPABILITY = "SELF_ACTION_V1"
local OUTFIT_CAPABILITY = "OUTFIT_V1"
local INVENTORY_CAPABILITY = "INVENTORY_V1"
local INVENTORY_EXACT_CAPABILITY = "INVENTORY_EXACT_V1"
local INVENTORY_ITEM_MOVE_CAPABILITY = "ITEM_MOVE_V1"
local INVENTORY_ITEM_TRADE_CAPABILITY = "ITEM_TRADE_V1"
local INVENTORY_ITEM_EQUIP_CAPABILITY = "ITEM_EQUIP_V1"
local INVENTORY_ITEM_UNEQUIP_CAPABILITY = "ITEM_UNEQUIP_V1"
local INVENTORY_ITEM_DESTROY_CAPABILITY = "ITEM_DESTROY_V1"
local INVENTORY_ITEM_USE_CAPABILITY = "ITEM_USE_V1"
local INVENTORY_ITEM_SELL_CAPABILITY = "ITEM_SELL_SINGLE_V1"
local INVENTORY_BULK_SELL_CAPABILITY = "INVENTORY_BULK_SELL_V1"
local INVENTORY_OPEN_CAPABILITY = "INVENTORY_OPEN_V1"
local GROUP_ROLL_CAPABILITY = "GROUP_ROLL_V1"
local ENCHANT_TRADE_CAPABILITY = "ENCHANT_TRADE_V1"
local QUEST_ABANDON_CAPABILITY = "QUEST_ABANDON_V1"
-- MB_LUA51_UPVALUE_REFACTOR_V1_BEGIN
-- Keep capability-to-state mapping outside Comm.HandleAddonMessage so each
-- capability does not consume a separate Lua 5.1 upvalue in that dispatcher.
local CAPABILITY_STATE_FIELDS = {
  [STATE_FRAMING_CAPABILITY] = "stateFramingCapable",
  [STRATEGY_MUTATION_CAPABILITY] = "strategyMutationCapable",
  ["SELF_STRATEGY_V1"] = "selfStrategyCapable",
  [SELF_ACTION_CAPABILITY] = "selfActionCapable",
  [OUTFIT_CAPABILITY] = "outfitCapable",
  [INVENTORY_CAPABILITY] = "inventoryCapable",
  [INVENTORY_EXACT_CAPABILITY] = "inventoryExactCapable",
  [INVENTORY_ITEM_MOVE_CAPABILITY] = "inventoryItemMoveCapable",
  [INVENTORY_ITEM_TRADE_CAPABILITY] = "inventoryItemTradeCapable",
  [INVENTORY_ITEM_EQUIP_CAPABILITY] = "inventoryItemEquipCapable",
  [INVENTORY_ITEM_UNEQUIP_CAPABILITY] = "inventoryItemUnequipCapable",
  [INVENTORY_ITEM_DESTROY_CAPABILITY] = "inventoryItemDestroyCapable",
  [INVENTORY_ITEM_USE_CAPABILITY] = "inventoryItemUseCapable",
  [INVENTORY_ITEM_SELL_CAPABILITY] = "inventoryItemSellCapable",
  ["VENDOR_BUYBACK_V1"] = "inventoryBuybackCapable",
  [INVENTORY_BULK_SELL_CAPABILITY] = "inventoryBulkSellCapable",
  [INVENTORY_OPEN_CAPABILITY] = "inventoryOpenCapable",
  [GROUP_ROLL_CAPABILITY] = "groupRollCapable",
  [ENCHANT_TRADE_CAPABILITY] = "enchantTradeCapable",
  [QUEST_ABANDON_CAPABILITY] = "questAbandonCapable",
  ["SELF_BOT_V1"] = "selfBotCapable",
}
-- MB_LUA51_UPVALUE_REFACTOR_V1_END
local SELF_BOT_TIMEOUT_SECONDS = 5.0
local GROUP_ROLL_TIMEOUT_SECONDS = 5.0
local ENCHANT_TRADE_TIMEOUT_SECONDS = 5.0
local QUEST_ABANDON_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_MOVE_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_TRADE_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_EQUIP_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_UNEQUIP_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_DESTROY_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_USE_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_SELL_TIMEOUT_SECONDS = 5.0
local INVENTORY_BUYBACK_TIMEOUT_SECONDS = 5.0
local INVENTORY_ITEM_MOVE_MAX_COUNT = 1000
local INVENTORY_ITEM_TRADE_MAX_COUNT = 1000
local INVENTORY_ITEM_EQUIP_MAX_COUNT = 1000
local INVENTORY_ITEM_DESTROY_MAX_COUNT = 1000
local INVENTORY_ITEM_USE_MAX_COUNT = 1000
local INVENTORY_ITEM_SELL_MAX_COUNT = 1000
local INVENTORY_BUYBACK_MAX_COUNT = 1000
local ENCHANT_TRADE_MAX_ACTIVE = 8
local GROUP_ROLL_MAX_ITEM_LINK_LENGTH = 160
local STATE_TIMEOUT_SECONDS = 5.0
local STATES_TIMEOUT_SECONDS = 15.0
local STRATEGY_MUTATION_TIMEOUT_SECONDS = 5.0
local SELF_STRATEGY_MUTATION_TIMEOUT_SECONDS = 10.0
local SELF_ACTION_TIMEOUT_SECONDS = 10.0
local STRATEGY_MUTATION_MAX_ACTIVE = 32
local SELF_STRATEGY_MUTATION_MAX_ACTIVE = 1
local STRATEGY_MUTATION_MAX_CHANGES_LENGTH = 160
local STRATEGY_MUTATION_MAX_OPERATIONS = 32
local STRATEGY_MUTATION_MAX_STRATEGY_LENGTH = 96
local STATE_MAX_ACTIVE = 32
local STATE_MAX_BOTS = 128
local STATE_MAX_STRATEGIES_PER_SCOPE = 256
local STATE_MAX_STRATEGY_LENGTH = 192
local STATE_MAX_TOTAL_BYTES = 32768
local STATE_CAPABILITY_FALLBACK_SECONDS = 3.0
local STATE_BOOTSTRAP_RETRY_SECONDS = 1.0
local STATE_BOOTSTRAP_MAX_AUTO_ATTEMPTS = 3

local requestBootstrapStates
local flushPendingStateRefreshes
local armCapabilityFallback
local maybeResolveCapabilityFallback

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

local function isInventoryViewCurrent(name)
  local inventory = MultiBot and MultiBot.inventory or nil
  if not inventory or not inventory.IsVisible or not inventory:IsVisible() then
    return true
  end

  local activeName = trim(inventory.name)
  name = trim(name)
  return activeName == "" or name == "" or string.lower(activeName) == string.lower(name)
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

local function splitFields(value)
  local fields = {}
  value = type(value) == "string" and value or ""
  local startIndex = 1

  while true do
    local separatorIndex = string.find(value, "~", startIndex, true)
    if not separatorIndex then
      fields[#fields + 1] = string.sub(value, startIndex)
      break
    end

    fields[#fields + 1] = string.sub(value, startIndex, separatorIndex - 1)
    startIndex = separatorIndex + 1
  end

  return fields
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

local function urlDecodeFieldStrict(value, maxLength, allowEmpty)
  if type(value) ~= "string" then
    return nil
  end

  maxLength = tonumber(maxLength or 0) or 0
  if maxLength <= 0 or #value > (maxLength * 3) then
    return nil
  end

  local output = {}
  local outputLength = 0
  local index = 1

  while index <= #value do
    local byteValue = string.byte(value, index)
    if byteValue == 37 then
      if index + 2 > #value then
        return nil
      end

      local hex = string.sub(value, index + 1, index + 2)
      if not string.match(hex, "^%x%x$") then
        return nil
      end

      byteValue = tonumber(hex, 16)
      index = index + 3
    else
      index = index + 1
    end

    if not byteValue or byteValue < 32 or byteValue == 127 then
      return nil
    end

    outputLength = outputLength + 1
    if outputLength > maxLength then
      return nil
    end

    output[#output + 1] = string.char(byteValue)
  end

  local decoded = table.concat(output)
  if decoded == "" and not allowEmpty then
    return nil
  end

  return decoded
end

local function parseBoundedInteger(value, minimum, maximum)
  value = trim(value)
  if value == "" or not string.match(value, "^%d+$") then
    return nil
  end

  local number = tonumber(value)
  if not number or number < minimum or number > maximum or math.floor(number) ~= number then
    return nil
  end

  return number
end

local function isValidStateToken(token)
  token = trim(token)
  return token ~= "" and #token <= 64 and string.match(token, "^[%w%-%_%.:]+$") ~= nil
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
  state.stateSeq = state.stateSeq or 0
  state.stateRequests = state.stateRequests or {}
  state.stateActive = state.stateActive or {}
  state.stateLatestByBot = state.stateLatestByBot or {}
  state.stateLatestOrderByBot = state.stateLatestOrderByBot or {}
  state.stateGlobalLatestToken = state.stateGlobalLatestToken or nil
  state.selfStrategyStateToken = state.selfStrategyStateToken or nil
  state.stateFramingCapable = state.stateFramingCapable or false
  state.connectionGeneration = tonumber(state.connectionGeneration) or 0
  state.capabilityFallbackDeadline = tonumber(state.capabilityFallbackDeadline) or 0
  state.capabilityFallbackGeneration = tonumber(state.capabilityFallbackGeneration) or 0
  state.capabilitiesResolved = state.capabilitiesResolved or false
  state.capabilityBatchActive = state.capabilityBatchActive or false
  state.bootstrapStatePending = state.bootstrapStatePending or false
  state.bootstrapStateRequested = state.bootstrapStateRequested or false
  state.bootstrapStateToken = state.bootstrapStateToken or nil
  state.bootstrapStateAttempts = tonumber(state.bootstrapStateAttempts) or 0
  state.pendingStateRefreshAll = state.pendingStateRefreshAll or false
  state.pendingStateRefreshByBot = state.pendingStateRefreshByBot or {}
  state.strategyMutationCapable = state.strategyMutationCapable or false
  state.selfStrategyCapable = state.selfStrategyCapable or false
  state.selfActionCapable = state.selfActionCapable or false
  state.outfitCapable = state.outfitCapable or false
  state.inventoryCapable = state.inventoryCapable or false
  state.inventoryExactCapable = state.inventoryExactCapable or false
  state.inventoryItemMoveCapable = state.inventoryItemMoveCapable or false
  state.inventoryItemTradeCapable = state.inventoryItemTradeCapable or false
  state.inventoryItemEquipCapable = state.inventoryItemEquipCapable or false
  state.inventoryItemUnequipCapable = state.inventoryItemUnequipCapable or false
  state.inventoryItemDestroyCapable = state.inventoryItemDestroyCapable or false
  state.inventoryItemUseCapable = state.inventoryItemUseCapable or false
  state.inventoryItemSellCapable = state.inventoryItemSellCapable or false
  state.inventoryBuybackCapable = state.inventoryBuybackCapable or false
  state.inventoryBulkSellCapable = state.inventoryBulkSellCapable or false
  state.inventoryOpenCapable = state.inventoryOpenCapable or false
  state.groupRollCapable = state.groupRollCapable or false
  state.enchantTradeCapable = state.enchantTradeCapable or false
  state.questAbandonCapable = state.questAbandonCapable or false
  state.selfBotCapable = state.selfBotCapable or false
  state.selfBotStateSeq = state.selfBotStateSeq or 0
  state.selfBotStateActive = state.selfBotStateActive or nil
  state.selfBotCommandSeq = state.selfBotCommandSeq or 0
  state.selfBotCommandActive = state.selfBotCommandActive or nil
  state.selfBotMountNormalized = state.selfBotMountNormalized == true
  state.selfBotMountNormalizePending = state.selfBotMountNormalizePending == true
  state.selfBotMountNormalizeEpoch = tonumber(state.selfBotMountNormalizeEpoch) or 0
  state.enchantTradeSeq = state.enchantTradeSeq or 0
  state.enchantTradeActive = state.enchantTradeActive or nil
  state.enchantTradeCommands = state.enchantTradeCommands or {}
  state.enchantTradeLists = state.enchantTradeLists or {}
  state.groupRollSeq = state.groupRollSeq or 0
  state.groupRollCommands = state.groupRollCommands or {}
  state.questAbandonSeq = state.questAbandonSeq or 0
  state.questAbandonCommands = state.questAbandonCommands or {}
  state.strategyMutationSeq = state.strategyMutationSeq or 0
  state.strategyMutationCommands = state.strategyMutationCommands or {}
  state.selfStrategySeq = state.selfStrategySeq or 0
  state.selfStrategyCommands = state.selfStrategyCommands or {}
  state.selfActionSeq = state.selfActionSeq or 0
  state.selfActionCommands = state.selfActionCommands or {}
  state.weaponEnchantDebugSeq = state.weaponEnchantDebugSeq or 0
  state.details = state.details or {}
  state.professions = state.professions or {}
  state.pvpStats = state.pvpStats or {}
  state.stats = state.stats or {}
  state.quests = state.quests or {}
  state.questSeq = state.questSeq or 0
  state.questActive = state.questActive or {}
  state.gameObjects = state.gameObjects or {}
  state.gameObjectSeq = state.gameObjectSeq or 0
  state.gameObjectActive = state.gameObjectActive or {}
  state.talentSpecs = state.talentSpecs or {}
  state.talentSpecSeq = state.talentSpecSeq or 0
  state.talentSpecActive = state.talentSpecActive or nil
  state.bootstrapPending = state.bootstrapPending or false
  state.bootstrapDeadline = state.bootstrapDeadline or 0
  state.inventorySeq = state.inventorySeq or 0
  state.inventoryActive = state.inventoryActive or nil
  state.inventoryExactSeq = state.inventoryExactSeq or 0
  state.inventoryExactActive = state.inventoryExactActive or nil
  state.inventoryExactSnapshots = state.inventoryExactSnapshots or {}
  state.inventoryItemMoveSeq = state.inventoryItemMoveSeq or 0
  state.inventoryItemMoves = state.inventoryItemMoves or {}
  state.inventoryItemTradeSeq = state.inventoryItemTradeSeq or 0
  state.inventoryItemTrades = state.inventoryItemTrades or {}
  state.inventoryItemEquipSeq = state.inventoryItemEquipSeq or 0
  state.inventoryItemEquips = state.inventoryItemEquips or {}
  state.inventoryItemUnequipSeq = state.inventoryItemUnequipSeq or 0
  state.inventoryItemUnequips = state.inventoryItemUnequips or {}
  state.inventoryItemDestroySeq = state.inventoryItemDestroySeq or 0
  state.inventoryItemDestroys = state.inventoryItemDestroys or {}
  state.inventoryItemUseSeq = state.inventoryItemUseSeq or 0
  state.inventoryItemUses = state.inventoryItemUses or {}
  state.inventoryItemSellSeq = state.inventoryItemSellSeq or 0
  state.inventoryItemSells = state.inventoryItemSells or {}
  state.inventoryBuybackSeq = state.inventoryBuybackSeq or 0
  state.inventoryBuybackItemSeq = state.inventoryBuybackItemSeq or 0
  state.inventoryBuybackActive = state.inventoryBuybackActive or nil
  state.inventoryBuybackCommands = state.inventoryBuybackCommands or {}
  state.bankItems = state.bankItems or {}
  state.bankSeq = state.bankSeq or 0
  state.bankActive = state.bankActive or nil
  state.guildBankItems = state.guildBankItems or {}
  state.guildBankSeq = state.guildBankSeq or 0
  state.guildBankActive = state.guildBankActive or nil
  state.inventoryItemActionSeq = state.inventoryItemActionSeq or 0
  state.inventoryItemActions = state.inventoryItemActions or {}
  state.spellbookSeq = state.spellbookSeq or 0
  state.spellbookActive = state.spellbookActive or nil
  state.botSkills = state.botSkills or {}
  state.botSkillSeq = state.botSkillSeq or 0
  state.botSkillActive = state.botSkillActive or nil
  state.botReputations = state.botReputations or {}
  state.botReputationSeq = state.botReputationSeq or 0
  state.botReputationActive = state.botReputationActive or nil
  state.botEmblems = state.botEmblems or {}
  state.botEmblemMoney = state.botEmblemMoney or {}
  state.botEmblemSeq = state.botEmblemSeq or 0
  state.botEmblemActive = state.botEmblemActive or nil
  state.professionRecipes = state.professionRecipes or {}
  state.professionRecipeSeq = state.professionRecipeSeq or 0
  state.professionRecipeActive = state.professionRecipeActive or nil
  state.professionRecipeCraftSeq = state.professionRecipeCraftSeq or 0
  state.professionRecipeCrafts = state.professionRecipeCrafts or {}
  state.outfitSeq = state.outfitSeq or 0
  state.outfitActive = state.outfitActive or nil
  state.outfitCommands = state.outfitCommands or {}
  state.trainerSeq = state.trainerSeq or 0
  state.trainerActive = state.trainerActive or nil
  state.trainerCommands = state.trainerCommands or {}
  state.trainerSpells = state.trainerSpells or {}
  state.glyphs = state.glyphs or {}
  state.glyphSeq = state.glyphSeq or 0
  state.glyphActive = state.glyphActive or nil
  state.rtiSeq = state.rtiSeq or 0
  state.combatSeq = state.combatSeq or 0
  state.positionSeq = state.positionSeq or 0
  state.lootSeq = state.lootSeq or 0
  state.formationSeq = state.formationSeq or 0
  state.formationCommands = state.formationCommands or {}
  state.formationQuerySeq = state.formationQuerySeq or 0
  state.formationQueryActive = state.formationQueryActive or nil
  return state
end

local function countTableEntries(values)
  local count = 0
  for _ in pairs(values or {}) do
    count = count + 1
  end
  return count
end

local function stateTransactionKey(token, botName)
  return tostring(token or "") .. "\031" .. string.lower(tostring(botName or ""))
end

local function clearStateTransactionsForToken(state, token)
  for key, transaction in pairs(state.stateActive or {}) do
    if type(transaction) == "table" and transaction.token == token then
      state.stateActive[key] = nil
    end
  end
end

local function clearStateRequest(state, token)
  local request = state.stateRequests and state.stateRequests[token] or nil
  if type(request) == "table" then
    if request.global then
      if state.stateGlobalLatestToken == token then
        state.stateGlobalLatestToken = nil
      end
    else
      local botKey = string.lower(request.botName or "")
      if state.stateLatestByBot[botKey] == token then
        state.stateLatestByBot[botKey] = nil
      end
    end
  end

  clearStateTransactionsForToken(state, token)
  state.stateRequests[token] = nil

  if state.selfStrategyStateToken == token then
    state.selfStrategyStateToken = nil
  end

  if state.bootstrapStateToken == token then
    state.bootstrapStateToken = nil
  end
end

local function scheduleBootstrapStateRetry(generation)
  local state = ensureBridgeState()
  if state.bootstrapStateAttempts >= STATE_BOOTSTRAP_MAX_AUTO_ATTEMPTS then
    return
  end

  if not (MultiBot and type(MultiBot.TimerAfter) == "function") then
    return
  end

  MultiBot.TimerAfter(STATE_BOOTSTRAP_RETRY_SECONDS, function()
    local bridge = ensureBridgeState()
    if bridge.connectionGeneration ~= generation
        or not bridge.connected
        or not bridge.capabilitiesResolved
        or bridge.bootstrapStateRequested
        or not bridge.bootstrapStatePending then
      return
    end

    requestBootstrapStates()
  end)
end

local function failBootstrapStateRequest(state, token)
  if state.bootstrapStateToken ~= token then
    return false
  end

  local generation = state.connectionGeneration
  state.bootstrapStateToken = nil
  state.bootstrapStateRequested = false
  state.bootstrapStatePending = true
  scheduleBootstrapStateRetry(generation)
  return true
end

local function scheduleStateTimeout(token, isGlobal)
  if not (MultiBot and type(MultiBot.TimerAfter) == "function") then
    return
  end

  local timeoutSeconds = isGlobal and STATES_TIMEOUT_SECONDS or STATE_TIMEOUT_SECONDS
  MultiBot.TimerAfter(timeoutSeconds, function()
    local state = ensureBridgeState()
    if not state.stateRequests[token] then
      return
    end

    failBootstrapStateRequest(state, token)
    clearStateRequest(state, token)
    state.lastError = "STATE_TIMEOUT~" .. token
  end)
end

local function beginStateRequest(state, botName, isGlobal)
  if countTableEntries(state.stateRequests) >= STATE_MAX_ACTIVE then
    return nil
  end

  state.stateSeq = (tonumber(state.stateSeq) or 0) + 1
  local suffix = isGlobal and "states" or "state"
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. suffix .. "-" .. tostring(state.stateSeq)

  state.stateRequests[token] = {
    token = token,
    botName = botName or "",
    global = isGlobal == true,
    order = state.stateSeq,
    startedAt = safeNow(),
    begun = false,
    expectedBots = 0,
    completedBots = 0,
    completedBotKeys = {},
  }

  if isGlobal then
    local previous = state.stateGlobalLatestToken
    local replacesBootstrap = previous and state.bootstrapStateToken == previous
    if previous and previous ~= token then
      clearStateRequest(state, previous)
    end
    state.stateGlobalLatestToken = token
    if replacesBootstrap then
      state.bootstrapStateToken = token
    end
  else
    local botKey = string.lower(botName or "")
    local previous = state.stateLatestByBot[botKey]
    if previous and previous ~= token then
      clearStateRequest(state, previous)
    end
    state.stateLatestByBot[botKey] = token
  end

  scheduleStateTimeout(token, isGlobal)
  return token
end

local function debugPrint(...)
  if MultiBot and MultiBot.dprint then
    MultiBot.dprint(...)
  end
end

local function L(key, fallback)
  if MultiBot and type(MultiBot.L) == "function" then
    return MultiBot.L(key, fallback)
  end

  return fallback or key
end

local function systemMessage(message)
  message = trim(message)
  if message == "" then
    return
  end

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message)
  elseif type(print) == "function" then
    print(message)
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

local function queuePendingStateRefresh(state, name, isGlobal)
  if isGlobal then
    state.pendingStateRefreshAll = true
    state.pendingStateRefreshByBot = {}
    return true
  end

  if state.pendingStateRefreshAll then
    return true
  end

  local key = string.lower(name or "")
  if key == "" then
    return false
  end

  if countTableEntries(state.pendingStateRefreshByBot) >= STATE_MAX_BOTS
      and state.pendingStateRefreshByBot[key] == nil then
    state.pendingStateRefreshAll = true
    state.pendingStateRefreshByBot = {}
    return true
  end

  state.pendingStateRefreshByBot[key] = name
  return true
end

function Comm.RequestState(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" then
    return false
  end

  if not state.capabilitiesResolved then
    local queued = queuePendingStateRefresh(state, name, false)
    armCapabilityFallback(state.connectionGeneration)
    maybeResolveCapabilityFallback(state.connectionGeneration)
    return queued
  end

  if not state.stateFramingCapable then
    return Comm.Send("GET", "STATE~" .. name)
  end

  local token = beginStateRequest(state, name, false)
  if not token then
    state.lastError = "STATE_TOO_MANY_REQUESTS"
    return false
  end
  if not Comm.Send("GET", "STATE~" .. urlEncodeField(name) .. "~" .. token) then
    clearStateRequest(state, token)
    return false
  end

  local request = state.stateRequests[token]
  if type(request) == "table" then
    local botKey = string.lower(name)
    local requestOrder = tonumber(request.order) or 0
    local latestOrder = tonumber(state.stateLatestOrderByBot[botKey]) or 0
    if requestOrder > latestOrder then
      state.stateLatestOrderByBot[botKey] = requestOrder
    end
  end

  return token
end

function Comm.RequestSelfStrategyState()
  local state = ensureBridgeState()
  local name = getPlayerName()

  if not name
      or not state.connected
      or state.selfStrategyCapable ~= true
      or state.selfBotLastActive ~= true
      or state.stateFramingCapable ~= true then
    state.lastError = "SELF_STRATEGY_STATE_UNAVAILABLE"
    return false
  end

  local token = beginStateRequest(state, name, false)
  if not token then
    state.lastError = "SELF_STRATEGY_STATE_TOO_MANY_REQUESTS"
    return false
  end

  if not Comm.Send("GET", "SELF_STRATEGY_STATE~" .. token) then
    clearStateRequest(state, token)
    state.lastError = "SELF_STRATEGY_STATE_SEND_FAILED"
    return false
  end

  state.selfStrategyStateToken = token

  local request = state.stateRequests[token]
  if type(request) == "table" then
    local botKey = string.lower(name)
    local requestOrder = tonumber(request.order) or 0
    local latestOrder = tonumber(state.stateLatestOrderByBot[botKey]) or 0
    if requestOrder > latestOrder then
      state.stateLatestOrderByBot[botKey] = requestOrder
    end
  end

  return token
end
function Comm.RequestStates()
  local state = ensureBridgeState()
  if not state.capabilitiesResolved then
    local queued = queuePendingStateRefresh(state, "", true)
    armCapabilityFallback(state.connectionGeneration)
    maybeResolveCapabilityFallback(state.connectionGeneration)
    return queued
  end

  if not state.stateFramingCapable then
    return Comm.Send("GET", "STATES")
  end

  local token = beginStateRequest(state, "", true)
  if not token then
    state.lastError = "STATE_TOO_MANY_REQUESTS"
    return false
  end
  if not Comm.Send("GET", "STATES~" .. token) then
    clearStateRequest(state, token)
    return false
  end

  return token
end

requestBootstrapStates = function()
  local state = ensureBridgeState()
  if state.bootstrapStateRequested then
    return false
  end

  if not state.capabilitiesResolved then
    state.bootstrapStatePending = true
    return true
  end

  if not Comm.RequestStates then
    return false
  end

  local request = Comm.RequestStates()
  if not request then
    state.bootstrapStatePending = true
    return false
  end

  state.bootstrapStatePending = false
  state.bootstrapStateRequested = true
  state.bootstrapStateAttempts = state.bootstrapStateAttempts + 1
  state.bootstrapStateToken = type(request) == "string" and request or nil
  return request
end

flushPendingStateRefreshes = function()
  local state = ensureBridgeState()
  if not state.capabilitiesResolved then
    return false
  end

  if state.bootstrapStatePending and not state.bootstrapStateRequested then
    if requestBootstrapStates() then
      state.pendingStateRefreshAll = false
      state.pendingStateRefreshByBot = {}
      return true
    end
  elseif state.bootstrapStateRequested then
    state.pendingStateRefreshAll = false
    state.pendingStateRefreshByBot = {}
    return true
  end

  if state.pendingStateRefreshAll then
    state.pendingStateRefreshAll = false
    state.pendingStateRefreshByBot = {}
    if not Comm.RequestStates() then
      state.pendingStateRefreshAll = true
      return false
    end
    return true
  end

  local pending = state.pendingStateRefreshByBot
  state.pendingStateRefreshByBot = {}
  local sent = false
  for key, name in pairs(pending or {}) do
    if Comm.RequestState(name) then
      sent = true
    else
      state.pendingStateRefreshByBot[key] = name
    end
  end

  return sent
end

armCapabilityFallback = function(generation)
  local state = ensureBridgeState()
  if state.connectionGeneration ~= generation or state.capabilitiesResolved then
    return false
  end

  if state.capabilityFallbackGeneration == generation
      and state.capabilityFallbackDeadline > 0 then
    return true
  end

  state.capabilityFallbackGeneration = generation
  state.capabilityFallbackDeadline = safeNow() + STATE_CAPABILITY_FALLBACK_SECONDS

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(STATE_CAPABILITY_FALLBACK_SECONDS, function()
      maybeResolveCapabilityFallback(generation)
    end)
  end

  return true
end

maybeResolveCapabilityFallback = function(generation)
  local state = ensureBridgeState()
  if state.connectionGeneration ~= generation
      or state.capabilityFallbackGeneration ~= generation
      or state.capabilitiesResolved
      or not state.connected
      or state.capabilityFallbackDeadline <= 0
      or safeNow() < state.capabilityFallbackDeadline then
    return false
  end

  if state.capabilityBatchActive then
    state.capabilityBatchActive = false
    state.stateFramingCapable = false
    state.strategyMutationCapable = false
state.selfStrategyCapable = false
state.selfActionCapable = false
    state.outfitCapable = false
    state.inventoryCapable = false
    state.inventoryExactCapable = false
    state.inventoryItemMoveCapable = false
    state.inventoryItemTradeCapable = false
    state.inventoryItemEquipCapable = false
    state.inventoryItemUnequipCapable = false
    state.inventoryItemDestroyCapable = false
    state.inventoryItemUseCapable = false
    state.inventoryItemSellCapable = false
    state.inventoryBuybackCapable = false
    state.inventoryBulkSellCapable = false
    state.inventoryOpenCapable = false
    state.groupRollCapable = false
    state.enchantTradeCapable = false
    state.selfBotCapable = false
  end

  state.capabilityFallbackDeadline = 0
  state.capabilityFallbackGeneration = 0
  state.stateFramingCapable = false
  state.capabilitiesResolved = true
  flushPendingStateRefreshes()
  return true
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

function Comm.RequestWeaponEnchantDebug(name)
  local state = ensureBridgeState()
  if not state.connected then
    state.lastError = "WEAPON_ENCHANT_NOT_CONNECTED"
    return false
  end

  name = trim(name)
  if name == "" or #name > 64 then
    state.lastError = "WEAPON_ENCHANT_BAD_BOT_NAME"
    return false
  end

  state.weaponEnchantDebugSeq = (tonumber(state.weaponEnchantDebugSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-enchant-" .. tostring(state.weaponEnchantDebugSeq)

  if not Comm.Send("GET", "WEAPON_ENCHANT~" .. urlEncodeField(name) .. "~" .. token) then
    state.lastError = "WEAPON_ENCHANT_SEND_FAILED"
    return false
  end

  return token
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

function Comm.RunRtiCommand(scope, target, command)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  command = trim(command or "")
  if command == "" then
    return false
  end

  scope = string.upper(trim(scope or "ALL"))
  target = trim(target or "")

  if scope ~= "ALL" and scope ~= "GROUP" and scope ~= "BOT" then
    return false
  end

  state.rtiSeq = (tonumber(state.rtiSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.rtiSeq)

  return Comm.Send("RUN", "RTI~" .. scope .. "~" .. urlEncodeField(target) .. "~" .. token .. "~" .. urlEncodeField(command))
end

function Comm.RunCombatCommand(scope, target, command)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  command = trim(command or "")
  if command == "" then
    return false
  end

  scope = string.upper(trim(scope or "BOT"))
  target = trim(target or "")

  if scope ~= "ALL" and scope ~= "GROUP" and scope ~= "BOT" then
    return false
  end

  state.combatSeq = (tonumber(state.combatSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.combatSeq)

  return Comm.Send("RUN", "COMBAT~" .. scope .. "~" .. urlEncodeField(target) .. "~" .. token .. "~" .. urlEncodeField(command))
end

local function validateStrategyMutationChanges(changes)
  changes = trim(changes or "")
  if changes == "" or #changes > STRATEGY_MUTATION_MAX_CHANGES_LENGTH then
    return nil
  end

  local normalized = {}
  local startIndex = 1

  while true do
    local separatorIndex = string.find(changes, ",", startIndex, true)
    local operation
    if separatorIndex then
      operation = string.sub(changes, startIndex, separatorIndex - 1)
    else
      operation = string.sub(changes, startIndex)
    end

    operation = trim(operation)
    local prefix = string.sub(operation, 1, 1)
    local strategy = string.lower(trim(string.sub(operation, 2)))

    if (prefix ~= "+" and prefix ~= "-")
        or strategy == ""
        or #strategy > STRATEGY_MUTATION_MAX_STRATEGY_LENGTH
        or string.find(strategy, "[^%w%s%-%_']") then
      return nil
    end

    normalized[#normalized + 1] = prefix .. strategy
    if #normalized > STRATEGY_MUTATION_MAX_OPERATIONS then
      return nil
    end

    if not separatorIndex then
      break
    end
    startIndex = separatorIndex + 1
  end

  if #normalized == 0 then
    return nil
  end

  return table.concat(normalized, ",")
end

local function finishStrategyMutationCommand(token, result)
  local state = ensureBridgeState()
  local pending = state.strategyMutationCommands[token]
  if type(pending) ~= "table" then
    return false
  end

  state.strategyMutationCommands[token] = nil
  result = type(result) == "table" and result or {}
  result.token = token
  result.scope = result.scope or pending.scope
  result.target = result.target or pending.target
  result.stateScope = result.stateScope or pending.stateScope
  result.changes = result.changes or pending.changes

  if type(pending.callback) == "function" then
    pending.callback(result)
  end

  if MultiBot.OnStrategyMutationApplied then
    MultiBot.OnStrategyMutationApplied(result)
  end

  return true
end

function Comm.RunStrategyCommand(scope, target, stateScope, changes, callback)
  local state = ensureBridgeState()

  if not state.connected then
    state.lastError = "STRATEGY_NOT_CONNECTED"
    return false
  end
  if not state.strategyMutationCapable then
    state.lastError = "STRATEGY_CAPABILITY_UNAVAILABLE"
    return false
  end

  scope = string.upper(trim(scope or "BOT"))
  target = trim(target or "")
  stateScope = string.upper(trim(stateScope or ""))
  changes = validateStrategyMutationChanges(changes)

  if scope ~= "ALL" and scope ~= "GROUP" and scope ~= "PARTY" and scope ~= "RAID" and scope ~= "BOT" then
    state.lastError = "STRATEGY_INVALID_SCOPE"
    return false
  end
  if scope == "BOT" and target == "" then
    state.lastError = "STRATEGY_TARGET_REQUIRED"
    return false
  end
  if scope ~= "BOT" and target ~= "" then
    state.lastError = "STRATEGY_TARGET_NOT_ALLOWED"
    return false
  end
  if stateScope ~= "C" and stateScope ~= "N" then
    state.lastError = "STRATEGY_INVALID_STATE_SCOPE"
    return false
  end
  if not changes then
    state.lastError = "STRATEGY_INVALID_CHANGES"
    return false
  end
  if countTableEntries(state.strategyMutationCommands) >= STRATEGY_MUTATION_MAX_ACTIVE then
    state.lastError = "STRATEGY_TOO_MANY_REQUESTS"
    return false
  end

  state.strategyMutationSeq = (tonumber(state.strategyMutationSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-strategy-" .. tostring(state.strategyMutationSeq)
  state.strategyMutationCommands[token] = {
    scope = scope,
    target = target,
    stateScope = stateScope,
    changes = changes,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  local payload = "STRATEGY~"
    .. scope .. "~"
    .. urlEncodeField(target) .. "~"
    .. token .. "~"
    .. stateScope .. "~"
    .. urlEncodeField(changes)

  if not Comm.Send("RUN", payload) then
    state.strategyMutationCommands[token] = nil
    state.lastError = "STRATEGY_SEND_FAILED"
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(STRATEGY_MUTATION_TIMEOUT_SECONDS, function()
      local bridge = ensureBridgeState()
      if not bridge.strategyMutationCommands[token] then
        return
      end

      bridge.lastError = "STRATEGY_TIMEOUT~" .. token
      finishStrategyMutationCommand(token, {
        status = "timeout",
        matched = 0,
        succeeded = 0,
        failed = 0,
        reason = "TIMEOUT",
      })
    end)
  end

  return token
end

local function finishSelfStrategyCommand(token, result)
  local state = ensureBridgeState()
  local pending = state.selfStrategyCommands[token]
  if type(pending) ~= "table" then
    return false
  end

  state.selfStrategyCommands[token] = nil
  result = type(result) == "table" and result or {}
  result.token = token
  result.stateScope = result.stateScope or pending.stateScope
  result.changes = result.changes or pending.changes

  if type(pending.callback) == "function" then
    pending.callback(result)
  end

  if MultiBot.OnSelfStrategyMutationApplied then
    MultiBot.OnSelfStrategyMutationApplied(result)
  end

  return true
end

local function invalidateInactiveSelfBotWork(state)
  state = type(state) == "table" and state or ensureBridgeState()

  local strategyStateToken = state.selfStrategyStateToken
  if type(strategyStateToken) == "string" and strategyStateToken ~= "" then
    clearStateRequest(state, strategyStateToken)
  end
  state.selfStrategyStateToken = nil

  local pendingSelfStrategyTokens = {}
  for token in pairs(state.selfStrategyCommands or {}) do
    pendingSelfStrategyTokens[#pendingSelfStrategyTokens + 1] = token
  end
  for _, token in ipairs(pendingSelfStrategyTokens) do
    finishSelfStrategyCommand(token, {
      status = "error",
      reason = "SELF_STRATEGY_NOT_ACTIVE",
    })
  end
  state.selfStrategyCommands = {}

  -- SELF_ACTION consumers currently use callbacks for result/error reporting
  -- only; there is no local optimistic button state to repair. Dropping these
  -- requests prevents late ACKs from completing work that belonged to the
  -- previous active SelfBot lifecycle without adding disable-time UI spam.
  state.selfActionCommands = {}
end

function Comm.RunSelfStrategyCommand(stateScope, changes, callback)
  local state = ensureBridgeState()

  if not state.connected then
    state.lastError = "SELF_STRATEGY_NOT_CONNECTED"
    return false
  end
  if state.selfBotCapable ~= true then
    state.lastError = "SELF_BOT_CAPABILITY_UNAVAILABLE"
    return false
  end
  if state.selfStrategyCapable ~= true then
    state.lastError = "SELF_STRATEGY_CAPABILITY_UNAVAILABLE"
    return false
  end
  if state.selfBotLastActive ~= true then
    state.lastError = "SELF_STRATEGY_NOT_ACTIVE"
    return false
  end

  stateScope = string.upper(trim(stateScope or ""))
  changes = validateStrategyMutationChanges(changes)

  if stateScope ~= "C" and stateScope ~= "N" then
    state.lastError = "SELF_STRATEGY_INVALID_STATE_SCOPE"
    return false
  end
  if not changes then
    state.lastError = "SELF_STRATEGY_INVALID_CHANGES"
    return false
  end
  if countTableEntries(state.selfStrategyCommands) >= SELF_STRATEGY_MUTATION_MAX_ACTIVE then
    state.lastError = "SELF_STRATEGY_TOO_MANY_REQUESTS"
    return false
  end

  state.selfStrategySeq = (tonumber(state.selfStrategySeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-self-strategy-" .. tostring(state.selfStrategySeq)
  state.selfStrategyCommands[token] = {
    stateScope = stateScope,
    changes = changes,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  local payload = "SELF_STRATEGY~"
    .. token .. "~"
    .. stateScope .. "~"
    .. urlEncodeField(changes)

  if not Comm.Send("RUN", payload) then
    state.selfStrategyCommands[token] = nil
    state.lastError = "SELF_STRATEGY_SEND_FAILED"
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(SELF_STRATEGY_MUTATION_TIMEOUT_SECONDS, function()
      local bridge = ensureBridgeState()
      if not bridge.selfStrategyCommands[token] then
        return
      end

      bridge.lastError = "SELF_STRATEGY_TIMEOUT~" .. token
      finishSelfStrategyCommand(token, {
        status = "timeout",
        reason = "TIMEOUT",
      })
    end)
  end

  return token
end
function Comm.RunLootCommand(scope, target, command)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  command = trim(command or "")
  if command == "" then
    return false
  end

  scope = string.upper(trim(scope or "ALL"))
  target = trim(target or "")

  if scope ~= "ALL" and scope ~= "GROUP" and scope ~= "BOT" then
    return false
  end

  state.lootSeq = (tonumber(state.lootSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-loot-" .. tostring(state.lootSeq)

  return Comm.Send("RUN", "LOOT~" .. scope .. "~" .. urlEncodeField(target) .. "~" .. token .. "~" .. urlEncodeField(command))
end

function Comm.RunPositionCommand(scope, target, command)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  command = trim(command or "")
  if command == "" then
    return false
  end

  scope = string.upper(trim(scope or "ALL"))
  target = trim(target or "")

  if scope ~= "ALL" and scope ~= "GROUP" and scope ~= "BOT" then
    return false
  end

  state.positionSeq = (tonumber(state.positionSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-position-" .. tostring(state.positionSeq)

  return Comm.Send("RUN", "POSITION~" .. scope .. "~" .. urlEncodeField(target) .. "~" .. token .. "~" .. urlEncodeField(command))
end

function Comm.RunFormationCommand(scope, target, formation, callback)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  scope = string.upper(trim(scope or "GROUP"))
  target = trim(target or "")
  formation = string.lower(trim(formation or ""))

  local allowed = {
    arrow = true,
    queue = true,
    near = true,
    melee = true,
    line = true,
    circle = true,
    chaos = true,
    shield = true,
  }

  if scope ~= "GROUP" or target ~= "" or not allowed[formation] then
    return false
  end

  state.formationSeq = (tonumber(state.formationSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-formation-" .. tostring(state.formationSeq)
  state.formationCommands[token] = {
    formation = formation,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "FORMATION~" .. scope .. "~~" .. token .. "~" .. urlEncodeField(formation)) then
    state.formationCommands[token] = nil
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(5.0, function()
      local bridge = ensureBridgeState()
      local pending = bridge.formationCommands[token]
      if not pending then
        return
      end

      bridge.formationCommands[token] = nil
      local result = {
        status = "timeout",
        scope = scope,
        target = target,
        token = token,
        success = 0,
        failure = 0,
        formation = formation,
      }

      if type(pending.callback) == "function" then
        pending.callback(result)
      end

      if MultiBot.OnFormationCommandApplied then
        MultiBot.OnFormationCommandApplied(result)
      end

      systemMessage(L("formation.confirm.timeout"))
    end)
  end

  return token
end

function Comm.RequestFormations(callback)
  local state = ensureBridgeState()

  if not state.connected then
    return false
  end

  state.formationQuerySeq = (tonumber(state.formationQuerySeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-formations-" .. tostring(state.formationQuerySeq)

  state.formationQueryActive = {
    token = token,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
    expected = 0,
    items = {},
    begun = false,
  }

  if not Comm.Send("GET", "FORMATIONS~GROUP~~" .. token) then
    state.formationQueryActive = nil
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(5.0, function()
      local bridge = ensureBridgeState()
      local active = bridge.formationQueryActive
      if not active or active.token ~= token then
        return
      end

      bridge.formationQueryActive = nil
      local result = {
        token = token,
        status = "timeout",
        expected = tonumber(active.expected or 0) or 0,
        sent = #(active.items or {}),
        items = active.items or {},
      }

      if type(active.callback) == "function" then
        active.callback(result)
      end

      if MultiBot.OnFormationQueryCompleted then
        MultiBot.OnFormationQueryCompleted(result)
      end
    end)
  end

  return token
end

local function getActiveFormationQuery(token)
  local active = ensureBridgeState().formationQueryActive
  token = trim(token)

  if type(active) ~= "table" or token == "" or active.token ~= token then
    return nil
  end

  return active
end

function Comm.ApplyFormationsBeginPayload(payload)
  local token, countText = splitOnce(payload or "", "~")
  token = trim(token)

  local active = getActiveFormationQuery(token)
  if not active then
    return false
  end

  active.expected = tonumber(countText or "0") or 0
  active.items = {}
  active.begun = true

  debugPrint("ADDON:RX", "FORMATIONS_BEGIN", token, active.expected)
  return true
end

function Comm.ApplyFormationsItemPayload(payload)
  local token, rest = splitOnce(payload or "", "~")
  local encodedBotName, encodedFormation = splitOnce(rest or "", "~")
  token = trim(token)

  local active = getActiveFormationQuery(token)
  if not active or not active.begun then
    return false
  end

  local botName = trim(urlDecodeField(encodedBotName))
  local formation = string.lower(trim(urlDecodeField(encodedFormation)))

  if botName == "" then
    return false
  end

  if formation == "" then
    formation = "?"
  end

  active.items[#active.items + 1] = {
    botName = botName,
    formation = formation,
  }

  debugPrint("ADDON:RX", "FORMATIONS_ITEM", token, botName, formation)
  return true
end

function Comm.ApplyFormationsEndPayload(payload)
  local token, sentText = splitOnce(payload or "", "~")
  token = trim(token)

  local state = ensureBridgeState()
  local active = getActiveFormationQuery(token)
  if not active or not active.begun then
    return false
  end

  table.sort(active.items, function(left, right)
    return string.lower(left.botName or "") < string.lower(right.botName or "")
  end)

  state.formationQueryActive = nil

  local result = {
    token = token,
    status = "ok",
    expected = tonumber(active.expected or 0) or 0,
    sent = tonumber(sentText or "0") or 0,
    items = active.items or {},
  }

  debugPrint("ADDON:RX", "FORMATIONS_END", token, result.sent)

  if type(active.callback) == "function" then
    active.callback(result)
  end

  if MultiBot.OnFormationQueryCompleted then
    MultiBot.OnFormationQueryCompleted(result)
  end

  return true
end

function Comm.RequestOutfits(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected or state.outfitCapable ~= true then
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

function Comm.RunOutfitCommand(name, commandSuffix, persist, wasCreate)
  local state = ensureBridgeState()
  name = trim(name)
  commandSuffix = trim(commandSuffix)
  if name == "" or commandSuffix == "" or not state.connected or state.outfitCapable ~= true then
    return false
  end

  state.outfitSeq = (tonumber(state.outfitSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-cmd-" .. tostring(state.outfitSeq)
  state.outfitCommands[token] = {
    botName = name,
    botNameKey = string.lower(name),
    command = commandSuffix,
    persist = persist == true,
    wasCreate = wasCreate == true,
    startedAt = safeNow(),
  }

  local persistToken = persist == true and "1" or "0"
  if not Comm.Send("RUN", "OUTFIT~" .. name .. "~" .. token .. "~" .. urlEncodeField(commandSuffix) .. "~" .. persistToken) then
    state.outfitCommands[token] = nil
    return false
  end

  return true
end

function Comm.RequestTrainer(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.trainerSeq = (tonumber(state.trainerSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-trainer-" .. tostring(state.trainerSeq)
  state.trainerActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    trainerEntry = 0,
    trainerName = "",
    startedAt = safeNow(),
    spells = {},
  }

  if not Comm.Send("GET", "TRAINER~" .. name .. "~" .. token) then
    state.trainerActive = nil
    return false
  end

  return true
end

function Comm.RunTrainerLearn(name, trainerEntry, spellId)
  local state = ensureBridgeState()
  name = trim(name)
  trainerEntry = tonumber(trainerEntry or 0) or 0

  local spellToken = trim(spellId)
  if spellToken == "" and tonumber(spellId or 0) then
    spellToken = tostring(tonumber(spellId or 0) or 0)
  end
  if string.upper(spellToken) ~= "ALL" then
    local numericSpellId = tonumber(spellToken or "0") or 0
    if numericSpellId <= 0 then
      return false
    end
    spellToken = tostring(numericSpellId)
  else
    spellToken = "ALL"
  end

  if name == "" or trainerEntry <= 0 or not state.connected then
    return false
  end

  state.trainerSeq = (tonumber(state.trainerSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-trainer-learn-" .. tostring(state.trainerSeq)
  state.trainerCommands[token] = {
    botName = name,
    botNameKey = string.lower(name),
    trainerEntry = trainerEntry,
    spellId = spellToken,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "TRAINER_LEARN~" .. name .. "~" .. token .. "~" .. trainerEntry .. "~" .. spellToken) then
    state.trainerCommands[token] = nil
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

function Comm.RequestGameObjects(name)
  local state = ensureBridgeState()
  if not state.connected and not state.bootstrapPending then
    return false
  end

  name = trim(name)
  state.gameObjectSeq = (tonumber(state.gameObjectSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-gob-" .. tostring(state.gameObjectSeq)

  state.gameObjectActive[token] = {
    botName = name,
    isGroup = name == "",
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "GAMEOBJECTS~" .. name .. "~" .. token) then
    state.gameObjectActive[token] = nil
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

-- MB_ISSUE33_SELF_BOT_V1_BEGIN
local function finishSelfBotRequest(kind, token, result)
  local state = ensureBridgeState()
  local field = kind == "command" and "selfBotCommandActive" or "selfBotStateActive"
  local pending = state[field]
  if type(pending) ~= "table" or pending.token ~= token then
    return false
  end

  state[field] = nil
  result = type(result) == "table" and result or {}
  result.token = token
  result.kind = kind

  -- Recovery state requests must never promote a cached/local fallback value
  -- to authoritative UI state. Only a successfully parsed server response may
  -- carry active through such a request.
  if pending.authoritativeOnly == true and result.authoritative ~= true then
    result.active = nil
  end

  if type(result.active) == "boolean" then
    state.selfBotLastActive = result.active
  end

  if result.status == "ok" then
    state.lastError = nil
  else
    state.lastError = "SELF_BOT_" .. tostring(result.reason or "UNKNOWN")
  end

  if type(result.active) == "boolean" and MultiBot.OnBridgeSelfBotState then
    MultiBot.OnBridgeSelfBotState(result.active, result)
  end

  if type(pending.callback) == "function" then
    pending.callback(result)
  end

  return true
end

local function normalizeSelfBotMountStrategy(state)
  state = type(state) == "table" and state or ensureBridgeState()

  if state.connected ~= true
      or state.selfBotLastActive ~= true
      or state.selfStrategyCapable ~= true
      or type(Comm.RunSelfStrategyCommand) ~= "function" then
    return false
  end

  if state.selfBotMountNormalized == true or state.selfBotMountNormalizePending == true then
    return true
  end

  local generation = tonumber(state.connectionGeneration) or 0
  local epoch = tonumber(state.selfBotMountNormalizeEpoch) or 0
  state.selfBotMountNormalizePending = true

  local token = Comm.RunSelfStrategyCommand("N", "-mount", function(result)
    local bridge = ensureBridgeState()
    if (tonumber(bridge.connectionGeneration) or 0) ~= generation
        or (tonumber(bridge.selfBotMountNormalizeEpoch) or 0) ~= epoch then
      return
    end

    bridge.selfBotMountNormalizePending = false
    if bridge.selfBotLastActive == true
        and type(result) == "table"
        and result.status == "ok" then
      bridge.selfBotMountNormalized = true
      debugPrint("SELFBOT:MOUNT_NORMALIZE", "OK")
    else
      bridge.selfBotMountNormalized = false
      debugPrint("SELFBOT:MOUNT_NORMALIZE", "FAILED",
        type(result) == "table" and tostring(result.reason or result.status or "UNKNOWN") or "INVALID_RESULT")
    end
  end)

  if token == false or token == nil then
    state.selfBotMountNormalizePending = false
    return false
  end

  debugPrint("SELFBOT:MOUNT_NORMALIZE", "SENT", tostring(token))
  return true
end

-- Keep SELF_BOT response parsing outside Comm.HandleAddonMessage. WoW 3.3.5a
-- uses Lua 5.1, whose function upvalue limit is 60; the main dispatcher is
-- already close to that limit.
function Comm.HandleSelfBotAddonMessage(opcode, payload, state)
  if opcode ~= "SELF_BOT_STATE" and opcode ~= "SELF_BOT_RESULT" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()

  local fields = splitFields(payload or "")
  local kind = opcode == "SELF_BOT_RESULT" and "command" or "state"
  local pending = kind == "command" and state.selfBotCommandActive or state.selfBotStateActive

  if #fields ~= 4 then
    if type(pending) == "table" then
      finishSelfBotRequest(kind, pending.token, {
        status = "error",
        active = type(state.selfBotLastActive) == "boolean" and state.selfBotLastActive or nil,
        reason = "BAD_RESPONSE",
      })
    else
      state.lastError = "SELF_BOT_BAD_RESPONSE"
    end
    return true
  end

  local token = trim(fields[1])
  local status = string.upper(trim(fields[2]))
  local activeText = trim(fields[3])
  local reason = urlDecodeFieldStrict(fields[4], 64, false)

  if type(pending) ~= "table" or pending.token ~= token then
    return true
  end

  if not isValidStateToken(token)
      or (status ~= "OK" and status ~= "ERR")
      or (activeText ~= "0" and activeText ~= "1")
      or reason == nil then
    finishSelfBotRequest(kind, token, {
      status = "error",
      active = type(state.selfBotLastActive) == "boolean" and state.selfBotLastActive or nil,
      reason = "BAD_RESPONSE",
    })
    return true
  end

  state.connected = true
  finishSelfBotRequest(kind, token, {
    status = status == "OK" and "ok" or "error",
    active = activeText == "1",
    authoritative = true,
    reason = reason,
    desiredState = type(pending) == "table" and pending.desiredState or nil,
  })
  if activeText == "0" then
    state.selfBotMountNormalizeEpoch = (tonumber(state.selfBotMountNormalizeEpoch) or 0) + 1
    state.selfBotMountNormalizePending = false
    state.selfBotMountNormalized = false
    invalidateInactiveSelfBotWork(state)
  elseif state.selfStrategyCapable == true then
    normalizeSelfBotMountStrategy(state)
  end

  if status == "OK" and activeText == "1" and state.selfStrategyCapable == true
      and type(Comm.RequestSelfStrategyState) == "function" then
    Comm.RequestSelfStrategyState()
  end

  debugPrint("ADDON:RX", opcode, token, status, activeText, reason)
  return true
end

function Comm.HandleSelfBotProtocolError(requestType, token, reason, state)
  if requestType ~= "SELF_BOT" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()

  if type(state.selfBotCommandActive) == "table"
      and state.selfBotCommandActive.token == token then
    finishSelfBotRequest("command", token, {
      status = "error",
      active = type(state.selfBotLastActive) == "boolean" and state.selfBotLastActive or nil,
      reason = reason,
      desiredState = state.selfBotCommandActive.desiredState,
    })
  elseif type(state.selfBotStateActive) == "table"
      and state.selfBotStateActive.token == token then
    finishSelfBotRequest("state", token, {
      status = "error",
      active = type(state.selfBotLastActive) == "boolean" and state.selfBotLastActive or nil,
      reason = reason,
    })
  end

  return true
end

function Comm.IsSelfBotCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.selfBotCapable == true
end

local function requestSelfBotState(callback, options)
  local state = ensureBridgeState()
  options = type(options) == "table" and options or {}
  local allowDuringCommand = options.allowDuringCommand == true
  local authoritativeOnly = options.authoritativeOnly == true

  if not state.connected or state.selfBotCapable ~= true then
    return false
  end
  if type(state.selfBotCommandActive) == "table" and not allowDuringCommand then
    return false
  end
  if type(state.selfBotStateActive) == "table" then
    -- A recovery caller requires its own completion callback. Do not silently
    -- attach it to an unrelated state request.
    if authoritativeOnly then
      return false
    end
    return state.selfBotStateActive.token
  end

  state.selfBotStateSeq = (tonumber(state.selfBotStateSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000))
      .. "-self-state-" .. tostring(state.selfBotStateSeq)
  state.selfBotStateActive = {
    token = token,
    callback = type(callback) == "function" and callback or nil,
    authoritativeOnly = authoritativeOnly,
    startedAt = safeNow(),
  }

  if not Comm.Send("GET", "SELF_BOT~" .. token) then
    state.selfBotStateActive = nil
    state.lastError = "SELF_BOT_STATE_SEND_FAILED"
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(SELF_BOT_TIMEOUT_SECONDS, function()
      local bridge = ensureBridgeState()
      local pending = bridge.selfBotStateActive
      if type(pending) ~= "table" or pending.token ~= token then
        return
      end

      finishSelfBotRequest("state", token, {
        status = "timeout",
        active = type(bridge.selfBotLastActive) == "boolean" and bridge.selfBotLastActive or nil,
        reason = "TIMEOUT",
      })
    end)
  end

  return token
end

function Comm.RequestSelfBotState(callback)
  return requestSelfBotState(callback, nil)
end

function Comm.RunSelfBot(desiredState, callback)
  local state = ensureBridgeState()
  desiredState = string.upper(trim(desiredState or ""))

  if not state.connected or state.selfBotCapable ~= true then
    return false
  end
  if desiredState ~= "ENABLE" and desiredState ~= "DISABLE" then
    return false
  end
  if type(state.selfBotCommandActive) == "table" then
    return false
  end

  -- A state response created before this mutation is stale by definition.
  local staleState = state.selfBotStateActive
  if type(staleState) == "table" then
    finishSelfBotRequest("state", staleState.token, {
      status = "error",
      reason = "SUPERSEDED",
    })
  end

  state.selfBotCommandSeq = (tonumber(state.selfBotCommandSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000))
      .. "-self-cmd-" .. tostring(state.selfBotCommandSeq)
  state.selfBotCommandActive = {
    token = token,
    desiredState = desiredState,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "SELF_BOT~" .. token .. "~" .. desiredState) then
    state.selfBotCommandActive = nil
    state.lastError = "SELF_BOT_SEND_FAILED"
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(SELF_BOT_TIMEOUT_SECONDS, function()
      local bridge = ensureBridgeState()
      local pending = bridge.selfBotCommandActive
      if type(pending) ~= "table" or pending.token ~= token then
        return
      end

      local desiredAtTimeout = pending.desiredState
      local recoveryToken = requestSelfBotState(function(stateResult)
        local current = ensureBridgeState().selfBotCommandActive
        if type(current) ~= "table" or current.token ~= token then
          return
        end

        finishSelfBotRequest("command", token, {
          status = "timeout",
          active = type(stateResult) == "table"
              and type(stateResult.active) == "boolean"
              and stateResult.active
              or nil,
          reason = "TIMEOUT",
          desiredState = current.desiredState,
        })
      end, {
        allowDuringCommand = true,
        authoritativeOnly = true,
      })

      if not recoveryToken then
        finishSelfBotRequest("command", token, {
          status = "timeout",
          reason = "TIMEOUT_STATE_REFRESH_FAILED",
          desiredState = desiredAtTimeout,
        })
      end
    end)
  end

  return token
end
-- MB_ISSUE33_SELF_BOT_V1_END

function Comm.RequestInventory(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected or state.inventoryCapable ~= true then
    return false
  end
  if not isInventoryViewCurrent(name) then
    return false
  end

  state.inventorySeq = (tonumber(state.inventorySeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.inventorySeq)
  state.inventoryActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    begun = false,
  }

  if not Comm.Send("GET", "INVENTORY~" .. name .. "~" .. token) then
    state.inventoryActive = nil
    return false
  end

  return true
end

function Comm.RequestInventoryExact(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected or state.inventoryExactCapable ~= true then
    return false
  end
  if not isInventoryViewCurrent(name) then
    return false
  end

  state.inventoryExactSeq = (tonumber(state.inventoryExactSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-invx-" .. tostring(state.inventoryExactSeq)
  state.inventoryExactActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    begun = false,
    bags = {},
    items = {},
    itemsByPosition = {},
  }

  if not Comm.Send("GET", "INVENTORY_EXACT~" .. name .. "~" .. token) then
    state.inventoryExactActive = nil
    return false
  end

  return token
end

function Comm.GetInventoryExactSnapshot(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" then
    return nil
  end

  return state.inventoryExactSnapshots[string.lower(name)]
end

function Comm.IsInventoryItemMoveCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemMoveCapable == true
end

function Comm.RunInventoryItemMove(name, srcBag, srcSlot, srcItemId, srcCount, dstBag, dstSlot, dstItemId, dstCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_MOVE_MAX_COUNT)
  dstBag = parseBoundedInteger(tostring(dstBag or ""), 0, 255)
  dstSlot = parseBoundedInteger(tostring(dstSlot or ""), 0, 255)
  dstItemId = parseBoundedInteger(tostring(dstItemId or ""), 0, 4294967295)
  dstCount = parseBoundedInteger(tostring(dstCount or ""), 0, INVENTORY_ITEM_MOVE_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemMoveCapable ~= true then
    return false
  end
  if not srcBag or not srcSlot or not srcItemId or not srcCount or not dstBag or not dstSlot or dstItemId == nil or dstCount == nil then
    return false
  end
  if (dstItemId == 0 and dstCount ~= 0) or (dstItemId ~= 0 and dstCount == 0) then
    return false
  end
  if srcBag == dstBag and srcSlot == dstSlot then
    return false
  end

  state.inventoryItemMoveSeq = (tonumber(state.inventoryItemMoveSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-move-" .. tostring(state.inventoryItemMoveSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = string.lower(name),
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    dstBag = dstBag,
    dstSlot = dstSlot,
    dstItemId = dstItemId,
    dstCount = dstCount,
    startedAt = safeNow(),
  }
  state.inventoryItemMoves[token] = command

  local payload = table.concat({
    "ITEM_MOVE", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
    tostring(dstBag), tostring(dstSlot), tostring(dstItemId), tostring(dstCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemMoves[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_MOVE_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    local pending = bridge.inventoryItemMoves and bridge.inventoryItemMoves[token] or nil
    if not pending then
      return
    end

    bridge.inventoryItemMoves[token] = nil
    bridge.lastError = "ITEM_MOVE_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemMoveResult then
      MultiBot.OnBridgeInventoryItemMoveResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.srcBag, pending.srcSlot, pending.dstBag, pending.dstSlot, pending
      )
    end
  end)

  return token
end

function Comm.IsInventoryItemTradeCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemTradeCapable == true
end

function Comm.RunInventoryItemTrade(name, srcBag, srcSlot, srcItemId, srcCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_TRADE_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemTradeCapable ~= true then
    return false
  end
  if srcBag == nil or srcSlot == nil or not srcItemId or not srcCount then
    return false
  end

  local botNameKey = string.lower(name)
  for _, pending in pairs(state.inventoryItemTrades or {}) do
    if pending.botNameKey == botNameKey
        and pending.srcBag == srcBag
        and pending.srcSlot == srcSlot
        and pending.srcItemId == srcItemId
        and pending.srcCount == srcCount then
      return false
    end
  end

  state.inventoryItemTradeSeq = (tonumber(state.inventoryItemTradeSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-trade-" .. tostring(state.inventoryItemTradeSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = botNameKey,
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    startedAt = safeNow(),
  }
  state.inventoryItemTrades[token] = command

  local payload = table.concat({
    "ITEM_TRADE", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemTrades[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_TRADE_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local pending = bridgeState.inventoryItemTrades and bridgeState.inventoryItemTrades[token] or nil
    if not pending then
      return
    end

    bridgeState.inventoryItemTrades[token] = nil
    bridgeState.lastError = "ITEM_TRADE_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemTradeResult then
      MultiBot.OnBridgeInventoryItemTradeResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.srcBag, pending.srcSlot, pending.srcItemId, pending.srcCount, 255, pending
      )
    end
  end)

  return token
end

function Comm.IsInventoryItemEquipCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemEquipCapable == true
end

function Comm.RunInventoryItemEquip(name, srcBag, srcSlot, srcItemId, srcCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_EQUIP_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemEquipCapable ~= true then
    return false
  end
  if not srcBag or not srcSlot or not srcItemId or not srcCount then
    return false
  end

  state.inventoryItemEquipSeq = (tonumber(state.inventoryItemEquipSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-equip-" .. tostring(state.inventoryItemEquipSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = string.lower(name),
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    startedAt = safeNow(),
  }
  state.inventoryItemEquips[token] = command

  local payload = table.concat({
    "ITEM_EQUIP", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemEquips[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_EQUIP_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    local pending = bridge.inventoryItemEquips and bridge.inventoryItemEquips[token] or nil
    if not pending then
      return
    end

    bridge.inventoryItemEquips[token] = nil
    bridge.lastError = "ITEM_EQUIP_TIMEOUT"
    if bridge.connected then
      local refreshed = MultiBot.RequestInventoryRefresh
        and MultiBot.RequestInventoryRefresh(pending.botName, 0.30)
      if not refreshed and Comm.RequestInventoryExact then
        Comm.RequestInventoryExact(pending.botName)
      end
    end
  end)

  return token
end

function Comm.IsInventoryItemUnequipCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryItemUnequipCapable == true
end

function Comm.RunInventoryItemUnequip(name, srcSlot, srcItemId)
  local state = ensureBridgeState()
  name = trim(name)

  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 18)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)

  if name == "" or not state.connected or state.inventoryItemUnequipCapable ~= true then
    return false
  end
  if srcSlot == nil or not srcItemId then
    return false
  end

  state.inventoryItemUnequipSeq = (tonumber(state.inventoryItemUnequipSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-unequip-" .. tostring(state.inventoryItemUnequipSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = string.lower(name),
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    startedAt = safeNow(),
  }
  state.inventoryItemUnequips[token] = command

  local payload = table.concat({
    "ITEM_UNEQUIP", name, token,
    tostring(srcSlot), tostring(srcItemId),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemUnequips[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_UNEQUIP_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    local pending = bridge.inventoryItemUnequips and bridge.inventoryItemUnequips[token] or nil
    if not pending then
      return
    end

    bridge.inventoryItemUnequips[token] = nil
    bridge.lastError = "ITEM_UNEQUIP_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemUnequipResult then
      MultiBot.OnBridgeInventoryItemUnequipResult(
        pending.botName, "ERR", "TIMEOUT", pending.srcSlot, pending.srcItemId, pending
      )
    end
  end)

  return token
end

function Comm.IsInventoryItemDestroyCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemDestroyCapable == true
end

function Comm.RunInventoryItemDestroy(name, srcBag, srcSlot, srcItemId, srcCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_DESTROY_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemDestroyCapable ~= true then
    return false
  end
  if srcBag == nil or srcSlot == nil or not srcItemId or not srcCount then
    return false
  end

  state.inventoryItemDestroySeq = (tonumber(state.inventoryItemDestroySeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-destroy-" .. tostring(state.inventoryItemDestroySeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = string.lower(name),
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    startedAt = safeNow(),
  }
  state.inventoryItemDestroys[token] = command

  local payload = table.concat({
    "ITEM_DESTROY", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemDestroys[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_DESTROY_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local pending = bridgeState.inventoryItemDestroys and bridgeState.inventoryItemDestroys[token] or nil
    if not pending then
      return
    end

    bridgeState.inventoryItemDestroys[token] = nil
    bridgeState.lastError = "ITEM_DESTROY_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemDestroyResult then
      MultiBot.OnBridgeInventoryItemDestroyResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.srcBag, pending.srcSlot, pending.srcItemId, pending
      )
    end
  end)

  return token
end
function Comm.IsInventoryItemUseCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemUseCapable == true
end

function Comm.RunInventoryItemUse(name, srcBag, srcSlot, srcItemId, srcCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_USE_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemUseCapable ~= true then
    return false
  end
  if srcBag == nil or srcSlot == nil or not srcItemId or not srcCount then
    return false
  end

  local botNameKey = string.lower(name)
  for _, pending in pairs(state.inventoryItemUses or {}) do
    if pending.botNameKey == botNameKey
        and pending.srcBag == srcBag
        and pending.srcSlot == srcSlot
        and pending.srcItemId == srcItemId
        and pending.srcCount == srcCount then
      return false
    end
  end

  state.inventoryItemUseSeq = (tonumber(state.inventoryItemUseSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-use-" .. tostring(state.inventoryItemUseSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = botNameKey,
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    startedAt = safeNow(),
  }
  state.inventoryItemUses[token] = command

  local payload = table.concat({
    "ITEM_USE", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemUses[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_USE_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local pending = bridgeState.inventoryItemUses and bridgeState.inventoryItemUses[token] or nil
    if not pending then
      return
    end

    bridgeState.inventoryItemUses[token] = nil
    bridgeState.lastError = "ITEM_USE_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemUseResult then
      MultiBot.OnBridgeInventoryItemUseResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.srcBag, pending.srcSlot, pending.srcItemId, pending
      )
    end
  end)

  return token
end

-- MB_ITEM_SELL_SINGLE_V1_COMM_BEGIN
function Comm.IsInventoryItemSellCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.inventoryExactCapable == true and state.inventoryItemSellCapable == true
end

function Comm.RunInventoryItemSell(name, srcBag, srcSlot, srcItemId, srcCount)
  local state = ensureBridgeState()
  name = trim(name)

  srcBag = parseBoundedInteger(tostring(srcBag or ""), 0, 255)
  srcSlot = parseBoundedInteger(tostring(srcSlot or ""), 0, 255)
  srcItemId = parseBoundedInteger(tostring(srcItemId or ""), 1, 4294967295)
  srcCount = parseBoundedInteger(tostring(srcCount or ""), 1, INVENTORY_ITEM_SELL_MAX_COUNT)

  if name == "" or not state.connected or state.inventoryExactCapable ~= true or state.inventoryItemSellCapable ~= true then
    return false
  end
  if srcBag == nil or srcSlot == nil or not srcItemId or not srcCount then
    return false
  end

  local botNameKey = string.lower(name)
  for _, pending in pairs(state.inventoryItemSells or {}) do
    if pending.botNameKey == botNameKey
        and pending.srcBag == srcBag
        and pending.srcSlot == srcSlot
        and pending.srcItemId == srcItemId
        and pending.srcCount == srcCount then
      return false
    end
  end

  state.inventoryItemSellSeq = (tonumber(state.inventoryItemSellSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-sell-" .. tostring(state.inventoryItemSellSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = botNameKey,
    srcBag = srcBag,
    srcSlot = srcSlot,
    srcItemId = srcItemId,
    srcCount = srcCount,
    startedAt = safeNow(),
  }
  state.inventoryItemSells[token] = command

  local payload = table.concat({
    "ITEM_SELL", name, token,
    tostring(srcBag), tostring(srcSlot), tostring(srcItemId), tostring(srcCount),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryItemSells[token] = nil
    return false
  end

  safeDelay(INVENTORY_ITEM_SELL_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local pending = bridgeState.inventoryItemSells and bridgeState.inventoryItemSells[token] or nil
    if not pending then
      return
    end

    bridgeState.inventoryItemSells[token] = nil
    bridgeState.lastError = "ITEM_SELL_TIMEOUT"
    if MultiBot.OnBridgeInventoryItemSellResult then
      MultiBot.OnBridgeInventoryItemSellResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.srcBag, pending.srcSlot, pending.srcItemId, 0, pending
      )
    end
  end)

  return token
end
-- MB_ITEM_SELL_SINGLE_V1_COMM_END
-- MB_VENDOR_BUYBACK_V1_COMM_BEGIN
function Comm.IsInventoryBuybackCapable()
  local state = ensureBridgeState()
  return state.connected == true
    and state.inventoryExactCapable == true
    and state.inventoryBuybackCapable == true
end

function Comm.RequestInventoryBuyback(name)
  local state = ensureBridgeState()
  name = trim(name)

  if name == "" or not Comm.IsInventoryBuybackCapable() then
    return false
  end
  if type(state.inventoryBuybackActive) == "table" then
    return false
  end

  state.inventoryBuybackSeq = (tonumber(state.inventoryBuybackSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-buyback-list-" .. tostring(state.inventoryBuybackSeq)
  state.inventoryBuybackActive = {
    token = token,
    botName = name,
    botNameKey = string.lower(name),
    startedAt = safeNow(),
    begun = false,
    expectedCount = nil,
    items = {},
    seenSlots = {},
    error = nil,
  }

  if not Comm.Send("GET", "BUYBACK~" .. name .. "~" .. token) then
    state.inventoryBuybackActive = nil
    return false
  end

  safeDelay(INVENTORY_BUYBACK_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local active = bridgeState.inventoryBuybackActive
    if type(active) ~= "table" or active.token ~= token then
      return
    end

    bridgeState.inventoryBuybackActive = nil
    bridgeState.lastError = "BUYBACK_TIMEOUT"
    if MultiBot.OnBridgeInventoryBuybackList then
      MultiBot.OnBridgeInventoryBuybackList(active.botName, {}, {
        token = token,
        status = "ERR",
        reason = "TIMEOUT",
      })
    end
  end)

  return token
end

function Comm.RunInventoryBuyback(name, slot, itemId, count, price)
  local state = ensureBridgeState()
  name = trim(name)
  slot = parseBoundedInteger(tostring(slot or ""), 74, 85)
  itemId = parseBoundedInteger(tostring(itemId or ""), 1, 4294967295)
  count = parseBoundedInteger(tostring(count or ""), 1, INVENTORY_BUYBACK_MAX_COUNT)
  price = parseBoundedInteger(tostring(price or ""), 0, 4294967295)

  if name == "" or not Comm.IsInventoryBuybackCapable() then
    return false
  end
  if slot == nil or itemId == nil or count == nil or price == nil then
    return false
  end

  local botNameKey = string.lower(name)
  for _, pending in pairs(state.inventoryBuybackCommands or {}) do
    if pending.botNameKey == botNameKey and pending.slot == slot then
      return false
    end
  end

  state.inventoryBuybackItemSeq = (tonumber(state.inventoryBuybackItemSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-buyback-item-" .. tostring(state.inventoryBuybackItemSeq)
  local command = {
    token = token,
    botName = name,
    botNameKey = botNameKey,
    slot = slot,
    itemId = itemId,
    count = count,
    price = price,
    startedAt = safeNow(),
  }
  state.inventoryBuybackCommands[token] = command

  local payload = table.concat({
    "BUYBACK_ITEM", name, token,
    tostring(slot), tostring(itemId), tostring(count), tostring(price),
  }, "~")

  if not Comm.Send("RUN", payload) then
    state.inventoryBuybackCommands[token] = nil
    return false
  end

  safeDelay(INVENTORY_BUYBACK_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    local pending = bridgeState.inventoryBuybackCommands and bridgeState.inventoryBuybackCommands[token] or nil
    if not pending then
      return
    end

    bridgeState.inventoryBuybackCommands[token] = nil
    bridgeState.lastError = "BUYBACK_TIMEOUT"
    if MultiBot.OnBridgeInventoryBuybackResult then
      MultiBot.OnBridgeInventoryBuybackResult(
        pending.botName, "ERR", "TIMEOUT",
        pending.slot, pending.itemId, pending.count, pending.price, pending
      )
    end
  end)

  return token
end
-- MB_VENDOR_BUYBACK_V1_COMM_END


function Comm.RequestBank(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.bankSeq = (tonumber(state.bankSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-bank-" .. tostring(state.bankSeq)
  state.bankActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    items = {},
    error = nil,
  }

  if not Comm.Send("GET", "BANK~" .. name .. "~" .. token) then
    state.bankActive = nil
    return false
  end

  return token
end

function Comm.RequestGuildBank(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.guildBankSeq = (tonumber(state.guildBankSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-gbank-" .. tostring(state.guildBankSeq)
  state.guildBankActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    items = {},
    error = nil,
  }

  if not Comm.Send("GET", "GBANK~" .. name .. "~" .. token) then
    state.guildBankActive = nil
    return false
  end

  return token
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

function Comm.RequestBotSkills(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.botSkillSeq = (tonumber(state.botSkillSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.botSkillSeq)
  state.botSkillActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    items = {},
  }

  if not Comm.Send("GET", "BOT_SKILLS~" .. name .. "~" .. token) then
    state.botSkillActive = nil
    return false
  end

  return true
end

function Comm.RequestBotReputations(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.botReputationSeq = (tonumber(state.botReputationSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-rep-" .. tostring(state.botReputationSeq)
  state.botReputationActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    items = {},
  }

  if not Comm.Send("GET", "BOT_REPUTATIONS~" .. name .. "~" .. token) then
    state.botReputationActive = nil
    return false
  end

  return true
end

function Comm.RequestBotEmblems(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected then
    return false
  end

  state.botEmblemSeq = (tonumber(state.botEmblemSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-emblem-" .. tostring(state.botEmblemSeq)
  state.botEmblemActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = safeNow(),
    items = {},
    money = nil,
  }

  if not Comm.Send("GET", "BOT_EMBLEMS~" .. name .. "~" .. token) then
    state.botEmblemActive = nil
    return false
  end

  return true
end

function Comm.RequestProfessionRecipes(name, skillId)
  local state = ensureBridgeState()
  name = trim(name)
  skillId = tonumber(skillId or 0) or 0
  if name == "" or skillId <= 0 or not state.connected then
    return false
  end

  state.professionRecipeSeq = (tonumber(state.professionRecipeSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-" .. tostring(state.professionRecipeSeq)
  state.professionRecipeActive = {
    botName = name,
    botNameKey = string.lower(name),
    skillId = skillId,
    token = token,
    startedAt = safeNow(),
    recipes = {},
  }

  if not Comm.Send("GET", "PROFESSION_RECIPES~" .. name .. "~" .. skillId .. "~" .. token) then
    state.professionRecipeActive = nil
    return false
  end

  return true
end

function Comm.IsEnchantTradeCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.enchantTradeCapable == true
end

function Comm.IsBotEnchanter(name)
  local state = ensureBridgeState()
  name = string.lower(trim(name))
  if name == "" then
    return false
  end

  local entry = state.professions and state.professions[name] or nil
  return type(entry) == "table"
      and type(entry.professions) == "table"
      and entry.professions.enchanting ~= nil
end

local function scheduleEnchantTradeListTimeout(name, token, delaySeconds)
  safeDelay(delaySeconds or ENCHANT_TRADE_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    local active = bridge.enchantTradeActive
    if type(active) ~= "table" or active.token ~= token then
      return
    end

    local now = safeNow()
    local lastProgressAt = tonumber(active.lastProgressAt) or tonumber(active.startedAt) or 0
    if now > 0 and lastProgressAt > 0 then
      local idleSeconds = now - lastProgressAt
      if idleSeconds < ENCHANT_TRADE_TIMEOUT_SECONDS
          and MultiBot
          and type(MultiBot.TimerAfter) == "function" then
        scheduleEnchantTradeListTimeout(
          name,
          token,
          math.max(0.05, ENCHANT_TRADE_TIMEOUT_SECONDS - idleSeconds)
        )
        return
      end
    end

    bridge.enchantTradeActive = nil
    if MultiBot.OnBridgeEnchantTradeList then
      MultiBot.OnBridgeEnchantTradeList(active.botName or name, {}, {
        token = token,
        status = "ERR",
        reason = "TIMEOUT",
        skillValue = 0,
        maxSkill = 0,
      })
    end
  end)
end

local function markEnchantTradeListProgress(active)
  if type(active) == "table" then
    active.lastProgressAt = safeNow()
  end
end

function Comm.RequestEnchantTrade(name)
  local state = ensureBridgeState()
  name = trim(name)
  if name == "" or not state.connected or state.enchantTradeCapable ~= true then
    return false
  end

  state.enchantTradeSeq = (tonumber(state.enchantTradeSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-ench-list-" .. tostring(state.enchantTradeSeq)
  local now = safeNow()
  state.enchantTradeActive = {
    botName = name,
    botNameKey = string.lower(name),
    token = token,
    startedAt = now,
    lastProgressAt = now,
    began = false,
    status = "PENDING",
    reason = "",
    skillValue = 0,
    maxSkill = 0,
    items = {},
  }

  if not Comm.Send("GET", "ENCHANT_TRADE~" .. name .. "~" .. token) then
    state.enchantTradeActive = nil
    return false
  end

  scheduleEnchantTradeListTimeout(name, token, ENCHANT_TRADE_TIMEOUT_SECONDS)
  return token
end

function Comm.RunEnchantTrade(name, spellId)
  local state = ensureBridgeState()
  name = trim(name)
  spellId = tonumber(spellId or 0) or 0
  if name == "" or spellId <= 0 or not state.connected or state.enchantTradeCapable ~= true then
    return false
  end

  if countTableEntries(state.enchantTradeCommands) >= ENCHANT_TRADE_MAX_ACTIVE then
    return false
  end

  state.enchantTradeSeq = (tonumber(state.enchantTradeSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-ench-run-" .. tostring(state.enchantTradeSeq)
  state.enchantTradeCommands[token] = {
    botName = name,
    botNameKey = string.lower(name),
    spellId = spellId,
    token = token,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "ENCHANT_TRADE~" .. name .. "~" .. token .. "~" .. tostring(spellId)) then
    state.enchantTradeCommands[token] = nil
    return false
  end

  safeDelay(ENCHANT_TRADE_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    local command = bridge.enchantTradeCommands[token]
    if not command then
      return
    end

    bridge.enchantTradeCommands[token] = nil
    if MultiBot.OnBridgeEnchantTradeResult then
      MultiBot.OnBridgeEnchantTradeResult(command.botName, command.spellId, "ERR", "TIMEOUT", command)
    end
  end)

  return token
end

function Comm.RunProfessionRecipeCraft(name, skillId, spellId, itemId)
  local state = ensureBridgeState()
  name = trim(name)
  skillId = tonumber(skillId or 0) or 0
  spellId = tonumber(spellId or 0) or 0
  itemId = tonumber(itemId or 0) or 0
  if name == "" or skillId <= 0 or spellId <= 0 or itemId < 0 or not state.connected then
    return false
  end

  state.professionRecipeCraftSeq = (tonumber(state.professionRecipeCraftSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-craft-" .. tostring(state.professionRecipeCraftSeq)
  state.professionRecipeCrafts[token] = {
    botName = name,
    botNameKey = string.lower(name),
    skillId = skillId,
    spellId = spellId,
    itemId = itemId,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "CRAFT_RECIPE~" .. name .. "~" .. token .. "~" .. skillId .. "~" .. spellId .. "~" .. itemId) then
    state.professionRecipeCrafts[token] = nil
    return false
  end

  return token
end

-- MB_QUEST_ABANDON_V1_BEGIN
local function finishQuestAbandonCommand(token, result)
  local state = ensureBridgeState()
  local pending = state.questAbandonCommands[token]
  if type(pending) ~= "table" then
    return false
  end

  state.questAbandonCommands[token] = nil
  result = type(result) == "table" and result or {}
  result.token = token
  result.questId = result.questId or pending.questId

  if type(pending.callback) == "function" then
    pending.callback(result)
  end

  if MultiBot.OnBridgeQuestAbandonResult then
    MultiBot.OnBridgeQuestAbandonResult(result)
  end

  return true
end

function Comm.IsQuestAbandonCapable()
  local state = ensureBridgeState()
  return state.connected == true and state.questAbandonCapable == true
end

function Comm.RunQuestAbandon(questId, callback)
  local state = ensureBridgeState()
  questId = tonumber(questId or 0) or 0

  if not state.connected or state.questAbandonCapable ~= true then
    return false
  end
  if questId <= 0 or questId > 4294967295 or math.floor(questId) ~= questId then
    return false
  end
  if countTableEntries(state.questAbandonCommands) >= 8 then
    state.lastError = "QUEST_ABANDON_TOO_MANY_REQUESTS"
    return false
  end

  state.questAbandonSeq = (tonumber(state.questAbandonSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-quest-abandon-" .. tostring(state.questAbandonSeq)
  state.questAbandonCommands[token] = {
    questId = questId,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "QUEST_ABANDON~" .. token .. "~" .. tostring(questId)) then
    state.questAbandonCommands[token] = nil
    return false
  end

  safeDelay(QUEST_ABANDON_TIMEOUT_SECONDS, function()
    local bridgeState = ensureBridgeState()
    if not bridgeState.questAbandonCommands[token] then
      return
    end

    bridgeState.lastError = "QUEST_ABANDON_TIMEOUT"
    finishQuestAbandonCommand(token, {
      status = "error",
      reason = "TIMEOUT",
      matched = 0,
      abandoned = 0,
      questId = questId,
    })
  end)

  return token
end

local function handleQuestAbandonResponse(payload, state)
  local fields = splitFields(payload or "")
  if #fields ~= 6 then
    state.lastError = "QUEST_ABANDON_BAD_FIELD_COUNT"
    return true
  end

  local token = trim(fields[1])
  local questId = parseBoundedInteger(fields[2], 1, 4294967295)
  local status = string.upper(trim(fields[3]))
  local reason = urlDecodeFieldStrict(fields[4], 64, false)
  local matched = parseBoundedInteger(fields[5], 0, 128)
  local abandoned = parseBoundedInteger(fields[6], 0, 128)
  local pending = state.questAbandonCommands[token]

  if not isValidStateToken(token)
      or questId == nil
      or (status ~= "OK" and status ~= "ERR")
      or reason == nil
      or matched == nil
      or abandoned == nil
      or abandoned > matched
      or type(pending) ~= "table"
      or pending.questId ~= questId then
    state.lastError = "QUEST_ABANDON_BAD_RESPONSE"
    return true
  end

  state.connected = true
  state.lastError = status == "OK" and nil or ("QUEST_ABANDON_" .. reason)
  finishQuestAbandonCommand(token, {
    status = status == "OK" and "ok" or "error",
    reason = reason,
    matched = matched,
    abandoned = abandoned,
    questId = questId,
  })
  return true
end
-- MB_QUEST_ABANDON_V1_END
local function finishGroupRollCommand(token, result)
  local state = ensureBridgeState()
  local pending = state.groupRollCommands[token]
  if not pending then
    return false
  end

  state.groupRollCommands[token] = nil
  result = type(result) == "table" and result or {}
  result.token = token
  result.mode = result.mode or pending.mode

  if type(pending.callback) == "function" then
    pending.callback(result)
  end

  if MultiBot.OnGroupRollResult then
    MultiBot.OnGroupRollResult(result)
  end

  return true
end

function Comm.RunGroupRoll(itemLink, callback)
  local state = ensureBridgeState()
  if not state.connected or state.groupRollCapable ~= true then
    return false
  end

  itemLink = trim(itemLink or "")
  local mode = "NORMAL"
  if itemLink ~= "" then
    if #itemLink > GROUP_ROLL_MAX_ITEM_LINK_LENGTH or not string.find(itemLink, "|Hitem:", 1, true) then
      return false
    end
    mode = "ITEM"
  end

  state.groupRollSeq = (tonumber(state.groupRollSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-roll-" .. tostring(state.groupRollSeq)
  state.groupRollCommands[token] = {
    mode = mode,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  local payload = "GROUP_ROLL~" .. token .. "~" .. mode
  if mode == "ITEM" then
    payload = payload .. "~" .. urlEncodeField(itemLink)
  end

  if not Comm.Send("RUN", payload) then
    state.groupRollCommands[token] = nil
    return false
  end

  safeDelay(GROUP_ROLL_TIMEOUT_SECONDS, function()
    local bridge = ensureBridgeState()
    if not bridge.groupRollCommands[token] then
      return
    end

    finishGroupRollCommand(token, {
      status = "timeout",
      matched = 0,
      invoked = 0,
      reason = "TIMEOUT",
    })
  end)

  return token
end

function Comm.RunInventoryItemAction(name, action, itemId, count)
  local state = ensureBridgeState()
  name = trim(name)
  action = string.upper(trim(action))
  itemId = tonumber(itemId or 0) or 0
  count = tonumber(count or 0) or 0

  local isBulkSellAction = action == "SELL_GREY" or action == "SELL_VENDOR"
  local isOpenItemsAction = action == "OPEN_ITEMS"
  local allowsZeroItemId = isBulkSellAction or isOpenItemsAction
  if name == "" or action == "" or itemId < 0 or count < 0 or not state.connected then
    return false
  end
  if allowsZeroItemId then
    if state.inventoryCapable ~= true then
      return false
    end
    if isBulkSellAction and state.inventoryBulkSellCapable ~= true then
      return false
    end
    if isOpenItemsAction and state.inventoryOpenCapable ~= true then
      return false
    end
    if itemId ~= 0 or count ~= 0 then
      return false
    end
  elseif itemId <= 0 then
    return false
  end

  state.inventoryItemActionSeq = (tonumber(state.inventoryItemActionSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-item-" .. tostring(state.inventoryItemActionSeq)
  state.inventoryItemActions[token] = {
    botName = name,
    botNameKey = string.lower(name),
    action = action,
    itemId = itemId,
    count = count,
    startedAt = safeNow(),
  }

  if not Comm.Send("RUN", "ITEM_ACTION~" .. name .. "~" .. token .. "~" .. action .. "~" .. itemId .. "~" .. count) then
    state.inventoryItemActions[token] = nil
    return false
  end

  return token
end

function Comm.MarkDisconnected(reason)
  local state = ensureBridgeState()
  state.connectionGeneration = state.connectionGeneration + 1
  state.connected = false
  state.server = nil
  state.protocol = nil
  state.lastError = reason or nil
  state.capabilityBatchActive = false
  state.inventoryActive = nil
  state.inventoryExactActive = nil
  state.inventoryExactSnapshots = {}

  local selfBotStatePending = state.selfBotStateActive
  local selfBotCommandPending = state.selfBotCommandActive
  state.selfBotStateActive = nil
  state.selfBotCommandActive = nil
  state.selfBotLastActive = nil
  if MultiBot and type(MultiBot.OnBridgeSelfBotState) == "function" then
    MultiBot.OnBridgeSelfBotState(false, reason or "DISCONNECTED")
  end
  state.selfBotMountNormalizeEpoch = (tonumber(state.selfBotMountNormalizeEpoch) or 0) + 1
  state.selfBotMountNormalizePending = false
  state.selfBotMountNormalized = false

  if type(selfBotStatePending) == "table" and type(selfBotStatePending.callback) == "function" then
    selfBotStatePending.callback({
      status = "error",
      active = nil,
      reason = "DISCONNECTED",
      token = selfBotStatePending.token,
      kind = "state",
    })
  end

  if type(selfBotCommandPending) == "table" and type(selfBotCommandPending.callback) == "function" then
    selfBotCommandPending.callback({
      status = "error",
      active = nil,
      reason = "DISCONNECTED",
      token = selfBotCommandPending.token,
      kind = "command",
      desiredState = selfBotCommandPending.desiredState,
    })
  end

  for _, command in pairs(state.inventoryItemMoves or {}) do
    if MultiBot.OnBridgeInventoryItemMoveResult then
      MultiBot.OnBridgeInventoryItemMoveResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.srcBag or 0, command.srcSlot or 0, command.dstBag or 0, command.dstSlot or 0, command
      )
    end
  end
  state.inventoryItemMoves = {}
  for _, command in pairs(state.inventoryItemTrades or {}) do
    if MultiBot.OnBridgeInventoryItemTradeResult then
      MultiBot.OnBridgeInventoryItemTradeResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.srcBag or 0, command.srcSlot or 0, command.srcItemId or 0, command.srcCount or 0, 255, command
      )
    end
  end
  state.inventoryItemTrades = {}
  state.inventoryItemEquips = {}
  for _, command in pairs(state.inventoryItemUnequips or {}) do
    if MultiBot.OnBridgeInventoryItemUnequipResult then
      MultiBot.OnBridgeInventoryItemUnequipResult(
        command.botName or "", "ERR", "DISCONNECTED", command.srcSlot or 0, command.srcItemId or 0, command
      )
    end
  end
  state.inventoryItemUnequips = {}
  for _, command in pairs(state.inventoryItemDestroys or {}) do
    if MultiBot.OnBridgeInventoryItemDestroyResult then
      MultiBot.OnBridgeInventoryItemDestroyResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.srcBag or 0, command.srcSlot or 0, command.srcItemId or 0, command
      )
    end
  end
  state.inventoryItemDestroys = {}
  for _, command in pairs(state.inventoryItemUses or {}) do
    if MultiBot.OnBridgeInventoryItemUseResult then
      MultiBot.OnBridgeInventoryItemUseResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.srcBag or 0, command.srcSlot or 0, command.srcItemId or 0, command
      )
    end
  end
  state.inventoryItemUses = {}
  for _, command in pairs(state.inventoryItemSells or {}) do
    if MultiBot.OnBridgeInventoryItemSellResult then
      MultiBot.OnBridgeInventoryItemSellResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.srcBag or 0, command.srcSlot or 0, command.srcItemId or 0, 0, command
      )
    end
  end
  state.inventoryItemSells = {}
  if type(state.inventoryBuybackActive) == "table" and MultiBot.OnBridgeInventoryBuybackList then
    MultiBot.OnBridgeInventoryBuybackList(state.inventoryBuybackActive.botName or "", {}, {
      token = state.inventoryBuybackActive.token or "",
      status = "ERR",
      reason = "DISCONNECTED",
    })
  end
  state.inventoryBuybackActive = nil
  for _, command in pairs(state.inventoryBuybackCommands or {}) do
    if MultiBot.OnBridgeInventoryBuybackResult then
      MultiBot.OnBridgeInventoryBuybackResult(
        command.botName or "", "ERR", "DISCONNECTED",
        command.slot or 74, command.itemId or 0, command.count or 0, command.price or 0, command
      )
    end
  end
  state.inventoryBuybackCommands = {}


  state.bankActive = nil
  state.guildBankActive = nil
  state.inventoryItemActions = {}

  local pendingQuestAbandonTokens = {}
  for token in pairs(state.questAbandonCommands or {}) do
    pendingQuestAbandonTokens[#pendingQuestAbandonTokens + 1] = token
  end
  for _, token in ipairs(pendingQuestAbandonTokens) do
    local pending = state.questAbandonCommands[token]
    finishQuestAbandonCommand(token, {
      status = "error",
      reason = "DISCONNECTED",
      matched = 0,
      abandoned = 0,
      questId = pending and pending.questId or 0,
    })
  end
  state.questAbandonCommands = {}

  local pendingRollTokens = {}
  for token in pairs(state.groupRollCommands or {}) do
    pendingRollTokens[#pendingRollTokens + 1] = token
  end
  for _, token in ipairs(pendingRollTokens) do
    finishGroupRollCommand(token, {
      status = "error",
      matched = 0,
      invoked = 0,
      reason = "DISCONNECTED",
    })
  end
  state.groupRollCommands = {}

  state.spellbookActive = nil
  state.botSkillActive = nil
  state.botReputationActive = nil
  state.botEmblemActive = nil
  state.professionRecipeActive = nil
  state.professionRecipeCrafts = {}

  if type(state.enchantTradeActive) == "table" and MultiBot.OnBridgeEnchantTradeList then
    MultiBot.OnBridgeEnchantTradeList(state.enchantTradeActive.botName or "", {}, {
      token = state.enchantTradeActive.token or "",
      status = "ERR",
      reason = "DISCONNECTED",
      skillValue = 0,
      maxSkill = 0,
    })
  end
  for _, command in pairs(state.enchantTradeCommands or {}) do
    if MultiBot.OnBridgeEnchantTradeResult then
      MultiBot.OnBridgeEnchantTradeResult(command.botName or "", command.spellId or 0, "ERR", "DISCONNECTED", command)
    end
  end
  state.enchantTradeActive = nil
  state.enchantTradeCommands = {}
  state.enchantTradeLists = {}
  state.outfitActive = nil
  state.outfitCommands = {}
  state.trainerActive = nil
  state.trainerCommands = {}
  state.formationCommands = {}
  state.formationQueryActive = nil
  state.strategyMutationCapable = false
state.selfStrategyCapable = false
state.selfActionCapable = false
  state.outfitCapable = false
  state.inventoryCapable = false
  state.inventoryExactCapable = false
  state.inventoryItemMoveCapable = false
  state.inventoryItemTradeCapable = false
  state.inventoryItemEquipCapable = false
  state.inventoryItemUnequipCapable = false
  state.inventoryItemDestroyCapable = false
  state.inventoryItemUseCapable = false
  state.inventoryItemSellCapable = false
  state.inventoryBuybackCapable = false
  state.inventoryBulkSellCapable = false
  state.inventoryOpenCapable = false
  state.groupRollCapable = false
  state.enchantTradeCapable = false
  state.selfBotCapable = false
  state.stateFramingCapable = false
  state.capabilityFallbackDeadline = 0
  state.capabilityFallbackGeneration = 0
  state.capabilitiesResolved = false
  state.bootstrapStatePending = false
  state.bootstrapStateRequested = false
  state.bootstrapStateToken = nil
  state.bootstrapStateAttempts = 0
  state.pendingStateRefreshAll = false
  state.pendingStateRefreshByBot = {}

  if MultiBot.RefreshEnchantingEveryButtons then
    MultiBot.RefreshEnchantingEveryButtons()
  end

  local pendingSelfStrategyTokens = {}
  for token in pairs(state.selfStrategyCommands or {}) do
    pendingSelfStrategyTokens[#pendingSelfStrategyTokens + 1] = token
  end
  for _, token in ipairs(pendingSelfStrategyTokens) do
    finishSelfStrategyCommand(token, {
      status = "error",
      reason = "DISCONNECTED",
    })
  end
  state.selfStrategyCommands = {}

  for token, pending in pairs(state.selfActionCommands or {}) do
    if type(pending) == "table" and type(pending.callback) == "function" then
      pending.callback({
        status = "error",
        action = pending.action,
        reason = "DISCONNECTED",
      })
    end
  end
  state.selfActionCommands = {}

  local pendingTokens = {}
  for token in pairs(state.strategyMutationCommands or {}) do
    pendingTokens[#pendingTokens + 1] = token
  end
  for _, token in ipairs(pendingTokens) do
    finishStrategyMutationCommand(token, {
      status = "error",
      matched = 0,
      succeeded = 0,
      failed = 0,
      reason = "DISCONNECTED",
    })
  end
  state.strategyMutationCommands = {}

  state.stateRequests = {}
  state.stateActive = {}
  state.selfStrategyStateToken = nil
  state.stateLatestByBot = {}
  state.stateLatestOrderByBot = {}
  state.stateGlobalLatestToken = nil
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

local function parseBridgeProfessionPayload(payload)
  local name, professionPayload = splitOnce(payload or "", "~")

  name = trim(urlDecodeField(name))
  if name == "" then
    return nil
  end

  local professions = {}
  for token in string.gmatch(professionPayload or "", "([^;]+)") do
    token = trim(urlDecodeField(token))

    local profession, value = splitOnce(token, ":")
    profession = string.lower(trim(profession or ""))

    if profession ~= "" then
      professions[profession] = value ~= "" and value or true
    end
  end

  return {
    name = name,
    professions = professions,
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

local function applyStateEntry(name, combat, normal)
  local state = ensureBridgeState()
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

function Comm.ApplyStatePayload(payload)
  local name, rest = splitOnce(payload or "", "~")
  local combat, normal = splitOnce(rest or "", "~")
  return applyStateEntry(name, combat, normal)
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

local function getStateRequest(token)
  local state = ensureBridgeState()
  token = trim(token)
  if not isValidStateToken(token) then
    return nil
  end
  return state.stateRequests[token]
end

local function abortStateRequest(token, reason)
  local state = ensureBridgeState()
  token = trim(token)
  if token == "" then
    return false
  end

  failBootstrapStateRequest(state, token)
  clearStateRequest(state, token)
  state.lastError = "STATE_ABORT~" .. token .. "~" .. tostring(reason or "UNKNOWN")
  debugPrint("ADDON:RX", "STATE_ABORT", token, reason or "UNKNOWN")
  return true
end

function Comm.ApplyStateBeginPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 4 then
    return false
  end

  local token = trim(fields[1])
  local botName = urlDecodeFieldStrict(fields[2], 64, false)
  local combatCount = parseBoundedInteger(fields[3], 0, STATE_MAX_STRATEGIES_PER_SCOPE)
  local normalCount = parseBoundedInteger(fields[4], 0, STATE_MAX_STRATEGIES_PER_SCOPE)
  local state = ensureBridgeState()
  local request = getStateRequest(token)

  if not request or not botName or combatCount == nil or normalCount == nil then
    return false
  end

  local botKey = string.lower(botName)
  if request.global then
    if not request.begun then
      return abortStateRequest(token, "GLOBAL_NOT_BEGUN")
    end
    if request.completedBotKeys[botKey] then
      return abortStateRequest(token, "DUPLICATE_BOT")
    end
  elseif string.lower(request.botName or "") ~= botKey then
    return abortStateRequest(token, "BOT_MISMATCH")
  end

  local key = stateTransactionKey(token, botName)
  if state.stateActive[key] then
    return abortStateRequest(token, "DUPLICATE_BEGIN")
  end

  if countTableEntries(state.stateActive) >= STATE_MAX_ACTIVE then
    return abortStateRequest(token, "TOO_MANY_ACTIVE")
  end

  state.stateActive[key] = {
    token = token,
    botName = botName,
    botKey = botKey,
    combatExpected = combatCount,
    normalExpected = normalCount,
    combatReceived = 0,
    normalReceived = 0,
    combat = {},
    normal = {},
    totalBytes = 0,
  }

  debugPrint("ADDON:RX", "STATE_BEGIN", token, botName, combatCount, normalCount)
  return true
end

function Comm.ApplyStateItemPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 5 then
    return false
  end

  local token = trim(fields[1])
  local botName = urlDecodeFieldStrict(fields[2], 64, false)
  local scope = string.upper(trim(fields[3]))
  local index = parseBoundedInteger(fields[4], 1, STATE_MAX_STRATEGIES_PER_SCOPE)
  local strategy = urlDecodeFieldStrict(fields[5], STATE_MAX_STRATEGY_LENGTH, false)
  if not botName or not index or not strategy or (scope ~= "C" and scope ~= "N") then
    return false
  end

  local state = ensureBridgeState()
  local transaction = state.stateActive[stateTransactionKey(token, botName)]
  if not transaction then
    return false
  end

  local expected = scope == "C" and transaction.combatExpected or transaction.normalExpected
  local items = scope == "C" and transaction.combat or transaction.normal
  if index > expected then
    return abortStateRequest(token, "INDEX_OUT_OF_RANGE")
  end

  if items[index] ~= nil then
    if items[index] == strategy then
      return true
    end
    return abortStateRequest(token, "CONFLICTING_DUPLICATE")
  end

  transaction.totalBytes = transaction.totalBytes + #strategy
  if transaction.totalBytes > STATE_MAX_TOTAL_BYTES then
    return abortStateRequest(token, "STATE_TOO_LARGE")
  end

  items[index] = strategy
  if scope == "C" then
    transaction.combatReceived = transaction.combatReceived + 1
  else
    transaction.normalReceived = transaction.normalReceived + 1
  end

  debugPrint("ADDON:RX", "STATE_ITEM", token, botName, scope, index, strategy)
  return true
end

function Comm.ApplyStateEndPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 4 then
    return false
  end

  local token = trim(fields[1])
  local botName = urlDecodeFieldStrict(fields[2], 64, false)
  local combatCount = parseBoundedInteger(fields[3], 0, STATE_MAX_STRATEGIES_PER_SCOPE)
  local normalCount = parseBoundedInteger(fields[4], 0, STATE_MAX_STRATEGIES_PER_SCOPE)
  if not botName or combatCount == nil or normalCount == nil then
    return false
  end

  local state = ensureBridgeState()
  local key = stateTransactionKey(token, botName)
  local transaction = state.stateActive[key]
  local request = getStateRequest(token)
  if not transaction or not request then
    return false
  end

  if combatCount ~= transaction.combatExpected or normalCount ~= transaction.normalExpected or
      transaction.combatReceived ~= combatCount or transaction.normalReceived ~= normalCount then
    return abortStateRequest(token, "COUNT_MISMATCH")
  end

  for index = 1, combatCount do
    if transaction.combat[index] == nil then
      return abortStateRequest(token, "MISSING_COMBAT_ITEM")
    end
  end
  for index = 1, normalCount do
    if transaction.normal[index] == nil then
      return abortStateRequest(token, "MISSING_NORMAL_ITEM")
    end
  end

  if request.global then
    if state.stateGlobalLatestToken ~= token then
      return abortStateRequest(token, "STALE_GLOBAL")
    end
  elseif state.stateLatestByBot[transaction.botKey] ~= token then
    return abortStateRequest(token, "STALE_BOT")
  end

  local requestOrder = tonumber(request.order) or 0
  local latestOrder = tonumber(state.stateLatestOrderByBot[transaction.botKey]) or 0
  if requestOrder < latestOrder then
    state.stateActive[key] = nil
    if request.global then
      if not request.completedBotKeys[transaction.botKey] then
        request.completedBotKeys[transaction.botKey] = true
        request.completedBots = request.completedBots + 1
      end
    else
      clearStateRequest(state, token)
    end

    debugPrint("ADDON:RX", "STATE_END_STALE", token, botName, requestOrder, latestOrder)
    return true
  end

  state.stateLatestOrderByBot[transaction.botKey] = requestOrder

  local entry = applyStateEntry(transaction.botName, table.concat(transaction.combat, ", "), table.concat(transaction.normal, ", "))
  if not entry then
    return abortStateRequest(token, "APPLY_FAILED")
  end

  state.stateActive[key] = nil
  if request.global then
    if not request.completedBotKeys[transaction.botKey] then
      request.completedBotKeys[transaction.botKey] = true
      request.completedBots = request.completedBots + 1
    end
  else
    clearStateRequest(state, token)
  end

  debugPrint("ADDON:RX", "STATE_END", token, botName, combatCount, normalCount)
  return true
end

function Comm.ApplyStateAbortPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 3 then
    return false
  end

  local token = trim(fields[1])
  local reason = urlDecodeFieldStrict(fields[3], 64, false) or "UNKNOWN"
  if not getStateRequest(token) then
    return false
  end

  return abortStateRequest(token, reason)
end

function Comm.ApplyStatesBeginPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 2 then
    return false
  end

  local token = trim(fields[1])
  local botCount = parseBoundedInteger(fields[2], 0, STATE_MAX_BOTS)
  local request = getStateRequest(token)
  if not request or not request.global or botCount == nil or request.begun then
    return false
  end

  request.begun = true
  request.expectedBots = botCount
  request.completedBots = 0
  request.completedBotKeys = {}
  debugPrint("ADDON:RX", "STATES_BEGIN", token, botCount)
  return true
end

function Comm.ApplyStatesEndPayload(payload)
  local fields = splitFields(payload)
  if #fields ~= 2 then
    return false
  end

  local token = trim(fields[1])
  local sentCount = parseBoundedInteger(fields[2], 0, STATE_MAX_BOTS)
  local state = ensureBridgeState()
  local request = getStateRequest(token)
  if not request or not request.global or not request.begun or sentCount == nil then
    return false
  end

  for _, transaction in pairs(state.stateActive) do
    if type(transaction) == "table" and transaction.token == token then
      return abortStateRequest(token, "INCOMPLETE_TRANSACTION")
    end
  end

  if sentCount ~= request.expectedBots or request.completedBots ~= request.expectedBots then
    return abortStateRequest(token, "GLOBAL_COUNT_MISMATCH")
  end

  clearStateRequest(state, token)
  debugPrint("ADDON:RX", "STATES_END", token, sentCount)
  return true
end

function Comm.ApplyBotDetailPayload(payload)
  local state = ensureBridgeState()
  local detail = parseBridgeDetailPayload(payload)
  if not detail then
    return nil
  end

  local key = string.lower(detail.name)
  local existing = state.details[key]
  local professionEntry = state.professions[key]

  if type(existing) == "table" and type(existing.professions) == "table" then
    detail.professions = existing.professions
  end

  if type(professionEntry) == "table" and type(professionEntry.professions) == "table" then
    detail.professions = professionEntry.professions
  end

  state.details[key] = detail

  if MultiBot.ApplyBridgeBotDetail then
    MultiBot.ApplyBridgeBotDetail(detail)
  end

  debugPrint("ADDON:RX", "DETAIL", detail.name, detail.className or "", tostring(detail.level or 0), tostring(detail.score or 0))
  return detail
end

function Comm.ApplyBotProfessionPayload(payload)
  local state = ensureBridgeState()
  local entry = parseBridgeProfessionPayload(payload)
  if not entry then
    return nil
  end

  local key = string.lower(entry.name)
  state.professions[key] = entry

  local detail = state.details[key]
  if type(detail) == "table" then
    detail.professions = entry.professions
    detail.lastProfessionUpdateAt = entry.lastUpdateAt
  end

  if MultiBot.ApplyBridgeBotProfession then
    MultiBot.ApplyBridgeBotProfession(entry.name, entry.professions)
  end

  debugPrint("ADDON:RX", "PROFESSION", entry.name)
  return entry
end

function Comm.ApplyBotProfessionsPayload(payload)
  local applied = 0

  if type(payload) == "string" and payload ~= "" then
    for entryPayload in string.gmatch(payload, "([^|]+)") do
      if Comm.ApplyBotProfessionPayload(entryPayload) then
        applied = applied + 1
      end
    end
  end

  debugPrint("ADDON:RX", "PROFESSIONS", tostring(applied))
  return applied
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

local function getActiveGameObjectRequest(token)
  local state = ensureBridgeState()
  token = trim(token)
  if token == "" then
    return nil
  end
  return state.gameObjectActive and state.gameObjectActive[token] or nil
end

function Comm.ApplyGameObjectBeginPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  if botName == "" or not getActiveGameObjectRequest(token) then
    return false
  end
  ensureRuntimeTable("LastGameObjectSearch")[botName] = {}
  debugPrint("ADDON:RX", "GAMEOBJECTS_BEGIN", botName)
  return true
end

function Comm.ApplyGameObjectItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, encodedLine = splitOnce(rest or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  if botName == "" or not getActiveGameObjectRequest(token) then
    return false
  end
  local store = ensureRuntimeTable("LastGameObjectSearch")
  store[botName] = store[botName] or {}
  table.insert(store[botName], urlDecodeField(encodedLine))
  return true
end

function Comm.ApplyGameObjectEndPayload(payload)
  local botName, token = splitOnce(payload or "", "~")
  botName = trim(urlDecodeField(botName))
  token = trim(token)
  if botName == "" or not getActiveGameObjectRequest(token) then
    return false
  end
  debugPrint("ADDON:RX", "GAMEOBJECTS_END", botName)
  return true
end

function Comm.ApplyGameObjectDonePayload(payload)
  local token = trim(payload or "")
  local state = ensureBridgeState()
  local request = getActiveGameObjectRequest(token)
  if not request then
    return false
  end
  state.gameObjectActive[token] = nil
  state.gameObjects.lastDoneAt = safeNow()
  if MultiBot.OnBridgeGameObjectsDone then
    MultiBot.OnBridgeGameObjectsDone(request)
  end
  debugPrint("ADDON:RX", "GAMEOBJECTS_DONE")
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
    MultiBot.OutfitUI:HandleBridgeCommandResult(command.botName, token, result, command.command, command.wasCreate == true)
  end

  state.outfitCommands[token] = nil
  debugPrint("ADDON:RX", "OUTFITS_CMD", command.botName, result)
  return true
end

local function getActiveTrainerRequest(botName, token)
  local active = ensureBridgeState().trainerActive
  if not active then return nil end
  botName = trim(botName)
  token = trim(token)
  if token ~= active.token then return nil end
  if botName ~= "" and string.lower(botName) ~= active.botNameKey then return nil end
  return active
end

local function clearActiveTrainerRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveTrainerRequest(botName, token) then
    state.trainerActive = nil
  end
end

function Comm.ApplyTrainerBeginPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local trainerEntry, trainerName = splitOnce(rest2 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  trainerEntry = tonumber(trainerEntry or "0") or 0
  trainerName = trim(urlDecodeField(trainerName))

  local active = getActiveTrainerRequest(botName, token)
  if botName == "" or not active then
    return false
  end

  active.botName = botName
  active.botNameKey = string.lower(botName)
  active.trainerEntry = trainerEntry
  active.trainerName = trainerName
  active.spells = {}

  if MultiBot.TrainerUI and MultiBot.TrainerUI.HandleBridgeBegin then
    MultiBot.TrainerUI:HandleBridgeBegin(botName, token, trainerEntry, trainerName)
  end

  debugPrint("ADDON:RX", "TRAINER_BEGIN", botName, trainerEntry)
  return true
end

function Comm.ApplyTrainerItemPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local trainerEntry, rest3 = splitOnce(rest2 or "", "~")
  local spellId, rest4 = splitOnce(rest3 or "", "~")
  local cost, canAfford = splitOnce(rest4 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  trainerEntry = tonumber(trainerEntry or "0") or 0
  spellId = tonumber(spellId or "0") or 0
  cost = tonumber(cost or "0") or 0
  canAfford = tostring(canAfford or "0") == "1"

  local active = getActiveTrainerRequest(botName, token)
  if botName == "" or not active or spellId <= 0 then
    return false
  end

  local entry = {
    spellId = spellId,
    cost = cost,
    canAfford = canAfford,
    trainerEntry = trainerEntry,
  }
  active.spells[#active.spells + 1] = entry

  if MultiBot.TrainerUI and MultiBot.TrainerUI.HandleBridgeLine then
    MultiBot.TrainerUI:HandleBridgeLine(botName, token, entry)
  end

  debugPrint("ADDON:RX", "TRAINER_ITEM", botName, spellId, cost, canAfford and 1 or 0)
  return true
end

function Comm.ApplyTrainerErrorPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local trainerEntry, reason = splitOnce(rest2 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  trainerEntry = tonumber(trainerEntry or "0") or 0
  reason = trim(urlDecodeField(reason))

  local active = getActiveTrainerRequest(botName, token)
  if botName == "" or not active then
    return false
  end

  active.error = reason
  active.trainerEntry = trainerEntry

  if MultiBot.TrainerUI and MultiBot.TrainerUI.HandleBridgeError then
    MultiBot.TrainerUI:HandleBridgeError(botName, token, reason, trainerEntry)
  end

  debugPrint("ADDON:RX", "TRAINER_ERROR", botName, reason)
  return true
end

function Comm.ApplyTrainerEndPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local trainerEntry, trainerName = splitOnce(rest2 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  trainerEntry = tonumber(trainerEntry or "0") or 0
  trainerName = trim(urlDecodeField(trainerName))

  local active = getActiveTrainerRequest(botName, token)
  if botName == "" or not active then
    return false
  end

  local state = ensureBridgeState()
  state.trainerSpells[string.lower(botName)] = active.spells or {}

  if MultiBot.TrainerUI and MultiBot.TrainerUI.HandleBridgeEnd then
    MultiBot.TrainerUI:HandleBridgeEnd(botName, token, trainerEntry, trainerName, active.spells or {}, active.error)
  end

  clearActiveTrainerRequest(botName, token)
  debugPrint("ADDON:RX", "TRAINER_END", botName)
  return true
end

function Comm.ApplyTrainerLearnPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local trainerEntry, rest3 = splitOnce(rest2 or "", "~")
  local spellId, rest4 = splitOnce(rest3 or "", "~")
  local result, rest5 = splitOnce(rest4 or "", "~")
  local reason, rest6 = splitOnce(rest5 or "", "~")
  local learnedCount, spent = splitOnce(rest6 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  trainerEntry = tonumber(trainerEntry or "0") or 0
  spellId = trim(urlDecodeField(spellId))
  result = trim(result)
  reason = trim(urlDecodeField(reason))
  learnedCount = tonumber(learnedCount or "0") or 0
  spent = tonumber(spent or "0") or 0

  local state = ensureBridgeState()
  local command = state.trainerCommands and state.trainerCommands[token] or nil
  if not command then
    return false
  end

  command.botName = botName ~= "" and botName or command.botName
  command.botNameKey = string.lower(command.botName or "")
  command.trainerEntry = trainerEntry
  command.spellId = spellId
  command.result = result
  command.reason = reason
  command.learnedCount = learnedCount
  command.spent = spent

  if MultiBot.TrainerUI and MultiBot.TrainerUI.HandleBridgeLearnResult then
    MultiBot.TrainerUI:HandleBridgeLearnResult(command.botName, token, trainerEntry, spellId, result, reason, learnedCount, spent)
  end

  state.trainerCommands[token] = nil
  debugPrint("ADDON:RX", "TRAINER_LEARN", command.botName, spellId, result, reason)
  return true
end

function Comm.ApplyProfessionRecipeCraftPayload(payload)
  local botName, rest = splitOnce(payload or "", "~")
  local token, rest2 = splitOnce(rest or "", "~")
  local skillId, rest3 = splitOnce(rest2 or "", "~")
  local spellId, rest4 = splitOnce(rest3 or "", "~")
  local itemId, rest5 = splitOnce(rest4 or "", "~")
  local result, reason = splitOnce(rest5 or "", "~")

  botName = trim(urlDecodeField(botName))
  token = trim(token)
  skillId = tonumber(skillId or "0") or 0
  spellId = tonumber(spellId or "0") or 0
  itemId = tonumber(itemId or "0") or 0
  result = trim(result)
  reason = trim(urlDecodeField(reason))

  local state = ensureBridgeState()
  local command = state.professionRecipeCrafts and state.professionRecipeCrafts[token] or nil
  if not command then
    return false
  end

  command.botName = botName ~= "" and botName or command.botName
  command.botNameKey = string.lower(command.botName or "")
  command.skillId = skillId > 0 and skillId or command.skillId
  command.spellId = spellId > 0 and spellId or command.spellId
  command.itemId = itemId >= 0 and itemId or command.itemId
  command.result = result
  command.reason = reason

  if MultiBot.OnBridgeProfessionRecipeCraftResult then
    MultiBot.OnBridgeProfessionRecipeCraftResult(command.botName, command.skillId, command.spellId, command.itemId, result, reason, command)
  end

  state.professionRecipeCrafts[token] = nil
  debugPrint("ADDON:RX", "PROFESSION_RECIPE_CRAFT", command.botName, command.skillId, command.spellId, result, reason)
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
  if not isInventoryViewCurrent(active.botName) then
    state.inventoryActive = nil
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

local function getActiveInventoryExactRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.inventoryExactActive
  if type(active) ~= "table" then
    return nil
  end

  if trim(token) ~= trim(active.token) then
    return nil
  end

  if string.lower(trim(botName)) ~= tostring(active.botNameKey or "") then
    return nil
  end
  if not isInventoryViewCurrent(active.botName) then
    state.inventoryExactActive = nil
    return nil
  end

  return active
end

local function clearActiveInventoryExactRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveInventoryExactRequest(botName, token) then
    state.inventoryExactActive = nil
  end
end

local function isWholeNumberInRange(value, minimum, maximum)
  value = tonumber(value)
  if not value or value ~= math.floor(value) then
    return nil
  end
  if value < minimum or value > maximum then
    return nil
  end
  return value
end

local function getActiveBankRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.bankActive
  if not active then
    return nil
  end

  if trim(token) ~= trim(active.token) then
    return nil
  end

  if string.lower(trim(urlDecodeField(botName))) ~= tostring(active.botNameKey or "") then
    return nil
  end

  return active
end

local function clearActiveBankRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveBankRequest(botName, token) then
    state.bankActive = nil
  end
end

local function getActiveGuildBankRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.guildBankActive
  if not active then
    return nil
  end

  if trim(token) ~= trim(active.token) then
    return nil
  end

  if string.lower(trim(urlDecodeField(botName))) ~= tostring(active.botNameKey or "") then
    return nil
  end

  return active
end

local function clearActiveGuildBankRequest(botName, token)
  local state = ensureBridgeState()
  if getActiveGuildBankRequest(botName, token) then
    state.guildBankActive = nil
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

local function getActiveBotSkillRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.botSkillActive
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

local function getActiveBotReputationRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.botReputationActive
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

local function getActiveBotEmblemRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.botEmblemActive
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

local function getActiveProfessionRecipeRequest(botName, token, skillId)
  local state = ensureBridgeState()
  local active = state.professionRecipeActive
  if type(active) ~= "table" then
    return nil
  end

  if botName and botName ~= "" and string.lower(trim(botName)) ~= trim(active.botNameKey or "") then
    return nil
  end

  if token and token ~= "" and tostring(token) ~= tostring(active.token or "") then
    return nil
  end

  if skillId and tonumber(skillId or 0) ~= tonumber(active.skillId or 0) then
    return nil
  end

  return active
end

local function getActiveEnchantTradeRequest(botName, token)
  local state = ensureBridgeState()
  local active = state.enchantTradeActive
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

local function parseRecipeMaterials(raw)
  local materials = {}
  for token in string.gmatch(raw or "", "([^;]+)") do
    local itemId, rest = splitOnce(token, ":")
    local required, available = splitOnce(rest or "", ":")
    table.insert(materials, {
      itemId = tonumber(itemId or "0") or 0,
      required = tonumber(required or "0") or 0,
      available = tonumber(available or "0") or 0,
    })
  end
  return materials
end

-- MB_VENDOR_BUYBACK_V1_RX_HELPER_BEGIN
function Comm.HandleInventoryBuybackAddonMessage(opcode, payload, state)
  if opcode == "BUYBACK_BEGIN" then
    local fields = splitFields(payload)
    local active = state.inventoryBuybackActive
    if #fields ~= 3 then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if type(active) == "table" then active.error = "BAD_RESPONSE" end
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local count = parseBoundedInteger(fields[3], 0, 12)
    if not botName or not isValidStateToken(token) or count == nil then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if type(active) == "table" then active.error = "BAD_RESPONSE" end
      return true
    end
    if type(active) ~= "table" or active.token ~= token then
      return true
    end
    if string.lower(botName) ~= active.botNameKey then
      active.error = "RESPONSE_MISMATCH"
      return true
    end

    active.begun = true
    active.expectedCount = count
    active.items = {}
    active.seenSlots = {}
    active.error = nil
    state.connected = true
    return true
  end

  if opcode == "BUYBACK_ITEM" then
    local fields = splitFields(payload)
    local active = state.inventoryBuybackActive
    if #fields ~= 7 then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if type(active) == "table" then active.error = "BAD_RESPONSE" end
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local slot = parseBoundedInteger(fields[3], 74, 85)
    local itemId = parseBoundedInteger(fields[4], 1, 4294967295)
    local count = parseBoundedInteger(fields[5], 1, INVENTORY_BUYBACK_MAX_COUNT)
    local price = parseBoundedInteger(fields[6], 0, 4294967295)
    local timestamp = parseBoundedInteger(fields[7], 0, 4294967295)

    if not botName or not isValidStateToken(token) or slot == nil or itemId == nil or
        count == nil or price == nil or timestamp == nil then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if type(active) == "table" then active.error = "BAD_RESPONSE" end
      return true
    end
    if type(active) ~= "table" or active.token ~= token then
      return true
    end
    if not active.begun or string.lower(botName) ~= active.botNameKey then
      active.error = "RESPONSE_MISMATCH"
      return true
    end
    if active.seenSlots[slot] then
      active.error = "BAD_RESPONSE"
      return true
    end

    active.seenSlots[slot] = true
    table.insert(active.items, {
      slot = slot,
      itemId = itemId,
      count = count,
      price = price,
      timestamp = timestamp,
    })
    state.connected = true
    return true
  end

  if opcode == "BUYBACK_END" then
    local fields = splitFields(payload)
    local active = state.inventoryBuybackActive
    if #fields ~= 5 then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if type(active) == "table" then
        state.inventoryBuybackActive = nil
        if MultiBot.OnBridgeInventoryBuybackList then
          MultiBot.OnBridgeInventoryBuybackList(active.botName, {}, {
            token = active.token or "",
            status = "ERR",
            reason = "BAD_RESPONSE",
          })
        end
      end
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local count = parseBoundedInteger(fields[5], 0, 12)

    if type(active) ~= "table" or active.token ~= token then
      return true
    end

    local valid = botName ~= nil and isValidStateToken(token) and
      (status == "OK" or status == "ERR") and reason ~= nil and count ~= nil and
      string.lower(botName) == active.botNameKey
    local items = active.items or {}

    if valid and status == "OK" then
      valid = active.begun == true and active.error == nil and
        active.expectedCount == count and #items == count
    elseif valid then
      valid = count == 0
      items = {}
    end

    if not valid then
      status = "ERR"
      reason = active.error or "RESPONSE_MISMATCH"
      items = {}
    end

    table.sort(items, function(left, right)
      local leftTime = tonumber(left.timestamp or 0) or 0
      local rightTime = tonumber(right.timestamp or 0) or 0
      if leftTime == rightTime then
        return (tonumber(left.slot or 0) or 0) > (tonumber(right.slot or 0) or 0)
      end
      return leftTime > rightTime
    end)

    state.inventoryBuybackActive = nil
    state.connected = true
    state.lastError = status == "OK" and nil or ("BUYBACK_" .. tostring(reason or "UNKNOWN"))

    if MultiBot.OnBridgeInventoryBuybackList then
      MultiBot.OnBridgeInventoryBuybackList(active.botName, items, {
        token = token,
        status = status,
        reason = reason or "UNKNOWN",
      })
    end
    return true
  end

  if opcode == "BUYBACK_RESULT" then
    local fields = splitFields(payload)
    if #fields ~= 8 then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local slot = parseBoundedInteger(fields[5], 74, 85)
    local itemId = parseBoundedInteger(fields[6], 1, 4294967295)
    local count = parseBoundedInteger(fields[7], 1, INVENTORY_BUYBACK_MAX_COUNT)
    local price = parseBoundedInteger(fields[8], 0, 4294967295)
    local command = state.inventoryBuybackCommands and state.inventoryBuybackCommands[token] or nil

    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or
        not reason or slot == nil or itemId == nil or count == nil or price == nil then
      state.lastError = "BUYBACK_BAD_RESPONSE"
      if command then
        state.inventoryBuybackCommands[token] = nil
        if MultiBot.OnBridgeInventoryBuybackResult then
          MultiBot.OnBridgeInventoryBuybackResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.slot, command.itemId, command.count, command.price, command
          )
        end
      end
      return true
    end
    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      slot == command.slot and itemId == command.itemId and
      count == command.count and price == command.price

    state.inventoryBuybackCommands[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "BUYBACK_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "BUYBACK_" .. reason
    end

    if MultiBot.OnBridgeInventoryBuybackResult then
      MultiBot.OnBridgeInventoryBuybackResult(
        command.botName, status, reason,
        command.slot, command.itemId, command.count, command.price, command
      )
    end

    debugPrint("ADDON:RX", "BUYBACK_RESULT", botName, token, status, reason, slot, itemId, count, price)
    return true
  end
  return false
end
-- MB_VENDOR_BUYBACK_V1_RX_HELPER_END

-- MB_SELFBOT_ACTION_V1_BEGIN
function Comm.RunSelfAction(action, argument, callback)
  local state = ensureBridgeState()
  action = string.upper(trim(action or ""))
  argument = trim(argument or "")

  if not state.connected then
    state.lastError = "SELF_ACTION_NOT_CONNECTED"
    return false
  end
  if state.selfBotCapable ~= true then
    state.lastError = "SELF_ACTION_SELF_BOT_CAPABILITY_UNAVAILABLE"
    return false
  end
  if state.selfActionCapable ~= true then
    state.lastError = "SELF_ACTION_CAPABILITY_UNAVAILABLE"
    return false
  end
  if state.selfBotLastActive ~= true then
    state.lastError = "SELF_ACTION_NOT_ACTIVE"
    return false
  end

  local allowed = action == "AUTOGEAR"
      or action == "MAINTENANCE"
      or action == "WAIT_ATTACK_TIME"
  if not allowed then
    state.lastError = "SELF_ACTION_UNSUPPORTED"
    return false
  end

  if (action == "AUTOGEAR" or action == "MAINTENANCE") and argument ~= "" then
    state.lastError = "SELF_ACTION_BAD_ARGUMENT"
    return false
  end
  if action == "WAIT_ATTACK_TIME"
      and argument ~= "0"
      and argument ~= "3"
      and argument ~= "5"
      and argument ~= "10" then
    state.lastError = "SELF_ACTION_BAD_ARGUMENT"
    return false
  end

  if countTableEntries(state.selfActionCommands) >= STRATEGY_MUTATION_MAX_ACTIVE then
    state.lastError = "SELF_ACTION_TOO_MANY_REQUESTS"
    return false
  end

  state.selfActionSeq = (tonumber(state.selfActionSeq) or 0) + 1
  local token = tostring(math.floor(safeNow() * 1000)) .. "-self-action-" .. tostring(state.selfActionSeq)
  state.selfActionCommands[token] = {
    action = action,
    argument = argument,
    callback = type(callback) == "function" and callback or nil,
    startedAt = safeNow(),
  }

  local payload = "SELF_ACTION~" .. token .. "~" .. action .. "~" .. argument
  if not Comm.Send("RUN", payload) then
    state.selfActionCommands[token] = nil
    state.lastError = "SELF_ACTION_SEND_FAILED"
    return false
  end

  if MultiBot and type(MultiBot.TimerAfter) == "function" then
    MultiBot.TimerAfter(SELF_ACTION_TIMEOUT_SECONDS, function()
      local bridge = ensureBridgeState()
      local pending = bridge.selfActionCommands[token]
      if type(pending) ~= "table" then
        return
      end

      bridge.selfActionCommands[token] = nil
      bridge.lastError = "SELF_ACTION_TIMEOUT"
      if type(pending.callback) == "function" then
        pending.callback({
          status = "timeout",
          action = pending.action,
          reason = "TIMEOUT",
        })
      end
    end)
  end

  return token
end

function Comm.HandleSelfActionAddonMessage(opcode, payload, state)
  if opcode ~= "SELF_ACTION_ACK" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()
  local fields = splitFields(payload or "")
  if #fields ~= 4 then
    state.lastError = "SELF_ACTION_ACK_BAD_FIELD_COUNT"
    return true
  end

  local token = trim(fields[1])
  local action = string.upper(trim(fields[2]))
  local status = string.upper(trim(fields[3]))
  local reason = urlDecodeFieldStrict(fields[4], 96, true)
  local pending = state.selfActionCommands[token]

  if not isValidStateToken(token)
      or (status ~= "OK" and status ~= "ERR")
      or reason == nil
      or type(pending) ~= "table"
      or pending.action ~= action then
    state.lastError = "SELF_ACTION_ACK_INVALID"
    return true
  end

  state.selfActionCommands[token] = nil
  state.connected = true
  state.lastError = status == "OK" and nil or ("SELF_ACTION_" .. reason)
  debugPrint("ADDON:RX", "SELF_ACTION_ACK", token, action, status, reason)

  if type(pending.callback) == "function" then
    pending.callback({
      status = status == "OK" and "ok" or "failed",
      action = action,
      reason = reason,
    })
  end

  return true
end

function Comm.HandleSelfActionProtocolError(requestType, token, reason, state)
  if requestType ~= "SELF_ACTION" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()
  token = trim(token)
  local pending = state.selfActionCommands[token]
  if type(pending) ~= "table" then
    return true
  end

  state.selfActionCommands[token] = nil
  local failureReason = reason or "PROTOCOL_ERROR"
  state.lastError = "SELF_ACTION_" .. failureReason
  if type(pending.callback) == "function" then
    pending.callback({
      status = "error",
      action = pending.action,
      reason = failureReason,
    })
  end
  return true
end
-- MB_SELFBOT_ACTION_V1_END
-- MB_SELFBOT_STRATEGY_V1_RX_HELPER_BEGIN
function Comm.HandleSelfStrategyAddonMessage(opcode, payload, state)
  if opcode ~= "SELF_STRATEGY_ACK" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()
  local fields = splitFields(payload or "")
  if #fields ~= 4 then
    state.lastError = "SELF_STRATEGY_ACK_BAD_FIELD_COUNT"
    return true
  end

  local token = trim(fields[1])
  local stateScope = string.upper(trim(fields[2]))
  local status = string.upper(trim(fields[3]))
  local reason = urlDecodeFieldStrict(fields[4], 64, false)
  local pending = state.selfStrategyCommands[token]

  if not isValidStateToken(token)
      or (stateScope ~= "C" and stateScope ~= "N")
      or (status ~= "OK" and status ~= "ERR")
      or reason == nil
      or type(pending) ~= "table"
      or pending.stateScope ~= stateScope then
    state.lastError = "SELF_STRATEGY_ACK_INVALID"
    return true
  end

  state.connected = true
  state.lastError = status == "OK" and nil or ("SELF_STRATEGY_" .. reason)
  debugPrint("ADDON:RX", "SELF_STRATEGY_ACK", token, stateScope, status, reason)
  finishSelfStrategyCommand(token, {
    status = status == "OK" and "ok" or "failed",
    stateScope = stateScope,
    reason = reason,
  })
  return true
end

function Comm.HandleSelfStrategyProtocolError(requestType, token, reason, state)
  if requestType ~= "SELF_STRATEGY" then
    return false
  end

  state = type(state) == "table" and state or ensureBridgeState()
  token = trim(token)
  local pending = state.selfStrategyCommands[token]
  if type(pending) ~= "table" then
    return true
  end

  finishSelfStrategyCommand(token, {
    status = "error",
    stateScope = pending.stateScope,
    reason = reason or "PROTOCOL_ERROR",
  })
  return true
end
-- MB_SELFBOT_STRATEGY_V1_RX_HELPER_END
function Comm.IsExpectedBridgeSender(sender)
  local expectedSender = getPlayerName()
  local senderName = trim(sender or "")
  senderName = string.gsub(senderName, "%-.*$", "")
  if not expectedSender or string.lower(senderName) ~= string.lower(expectedSender) then
    debugPrint("ADDON:RX:DROP", "SENDER", sender or "")
    return false
  end

  return true
end

local function resetCapabilityFlags(state)
  for _, stateField in pairs(CAPABILITY_STATE_FIELDS) do
    state[stateField] = false
  end
end

local function finishCapabilityResolution(state, debugOpcode, payload)
  state.capabilityFallbackDeadline = 0
  state.capabilityFallbackGeneration = 0
  state.capabilitiesResolved = true
  debugPrint("ADDON:RX", debugOpcode, payload or "")
  flushPendingStateRefreshes()
  if state.selfBotCapable == true and type(Comm.RequestSelfBotState) == "function" then
    Comm.RequestSelfBotState()
  end
  if MultiBot.RefreshEnchantingEveryButtons then
    MultiBot.RefreshEnchantingEveryButtons()
  end
end

local function handleCapabilityMessage(opcode, payload, state)
  if opcode == "CAPS_BEGIN" then
    resetCapabilityFlags(state)
    state.capabilityBatchActive = true
    state.capabilitiesResolved = false
    debugPrint("ADDON:RX", "CAPS_BEGIN")
    return true
  end

  if opcode == "CAPS" then
    if not state.capabilityBatchActive then
      resetCapabilityFlags(state)
    end

    for capability in string.gmatch(payload or "", "([^,]+)") do
      capability = trim(capability)
      local stateField = CAPABILITY_STATE_FIELDS[capability]
      if stateField then
        state[stateField] = true
      end
    end

    if state.capabilityBatchActive then
      debugPrint("ADDON:RX", "CAPS_PART", payload or "")
      return true
    end

    finishCapabilityResolution(state, "CAPS", payload)
    return true
  end

  if opcode == "CAPS_END" then
    if not state.capabilityBatchActive then
      return true
    end

    state.capabilityBatchActive = false
    finishCapabilityResolution(state, "CAPS_END")
    return true
  end

  return false
end

local function handleInventoryItemTradeResponse(payload, state)
  local fields = splitFields(payload)
  if #fields ~= 9 then
    state.lastError = "ITEM_TRADE_BAD_FIELD_COUNT"
    return true
  end

  local botName = urlDecodeFieldStrict(fields[1], 64, false)
  local token = trim(fields[2])
  local status = string.upper(trim(fields[3]))
  local reason = urlDecodeFieldStrict(fields[4], 64, false)
  local srcBag = parseBoundedInteger(fields[5], 0, 255)
  local srcSlot = parseBoundedInteger(fields[6], 0, 255)
  local srcItemId = parseBoundedInteger(fields[7], 1, 4294967295)
  local srcCount = parseBoundedInteger(fields[8], 1, INVENTORY_ITEM_TRADE_MAX_COUNT)
  local tradeSlot = parseBoundedInteger(fields[9], 0, 255)

  state.connected = true
  local command = state.inventoryItemTrades and state.inventoryItemTrades[token] or nil
  if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
    srcBag == nil or srcSlot == nil or srcItemId == nil or srcCount == nil or tradeSlot == nil then
    state.lastError = "ITEM_TRADE_BAD_RESPONSE"
    if command then
      state.inventoryItemTrades[token] = nil
      if MultiBot.OnBridgeInventoryItemTradeResult then
        MultiBot.OnBridgeInventoryItemTradeResult(
          command.botName, "ERR", "BAD_RESPONSE",
          command.srcBag, command.srcSlot, command.srcItemId, command.srcCount, 255, command
        )
      end
    end
    return true
  end

  if not command then
    return true
  end

  local responseMatches = string.lower(botName) == command.botNameKey and
    srcBag == command.srcBag and srcSlot == command.srcSlot and
    srcItemId == command.srcItemId and srcCount == command.srcCount and
    ((status == "OK" and tradeSlot >= 0 and tradeSlot <= 5) or status == "ERR")

  state.inventoryItemTrades[token] = nil
  if not responseMatches then
    status = "ERR"
    reason = "RESPONSE_MISMATCH"
    tradeSlot = 255
    state.lastError = "ITEM_TRADE_RESPONSE_MISMATCH"
  elseif status == "OK" then
    state.lastError = nil
  else
    state.lastError = "ITEM_TRADE_" .. reason
  end

  if MultiBot.OnBridgeInventoryItemTradeResult then
    MultiBot.OnBridgeInventoryItemTradeResult(
      command.botName, status, reason,
      command.srcBag, command.srcSlot, command.srcItemId, command.srcCount, tradeSlot, command
    )
  end

  debugPrint("ADDON:RX", "INVENTORY_ITEM_TRADE", botName, token, status, reason, srcBag, srcSlot, srcItemId, srcCount, tradeSlot)
  return true
end

-- New structured response handlers should be registered here instead of adding
-- another large branch directly inside Comm.HandleAddonMessage.
local STRUCTURED_OPCODE_HANDLERS = {
  INVENTORY_ITEM_TRADE = handleInventoryItemTradeResponse,
  QUEST_ABANDON_RESULT = handleQuestAbandonResponse,
}

function Comm.HandleAddonMessage(prefix, message, distribution, sender)
  if prefix ~= Comm.prefix then
    return false
  end

  if not Comm.IsExpectedBridgeSender(sender) then
    return true
  end

  local state = ensureBridgeState()
  local opcode, payload = splitOnce(message or "", "~")
  opcode = string.upper(trim(opcode))

  if opcode ~= "CAPS" and opcode ~= "CAPS_BEGIN" and opcode ~= "CAPS_END" then
    maybeResolveCapabilityFallback(state.connectionGeneration)
  end

  if opcode == "HELLO_ACK" then
    local protocol, serverName = splitOnce(payload, "~")
    local wasConnected = state.connected == true
    local generation = state.connectionGeneration

    state.connected = true
    state.protocol = protocol ~= "" and protocol or nil
    state.server = serverName ~= "" and serverName or nil
    state.lastError = nil
    debugPrint("ADDON:RX", "HELLO_ACK", payload or "")
    armCapabilityFallback(generation)

    if (not wasConnected or state.bootstrapPending) and state.protocol then
      safeDelay(0.10, function()
        local bridge = ensureBridgeState()
        if bridge.connectionGeneration == generation and bridge.connected then
          bridge.bootstrapPending = false
          bridge.bootstrapDeadline = 0
          if Comm.RequestRoster then
            Comm.RequestRoster()
          end
          requestBootstrapStates()
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

  if handleCapabilityMessage(opcode, payload, state) then
    return true
  end

  if opcode == "WEAPON_ENCHANT" then
    state.connected = true

    local fields = splitFields(payload)
    if #fields ~= 9 then
      state.lastError = "WEAPON_ENCHANT_BAD_FIELD_COUNT"
      return true
    end

    local token = trim(fields[1])
    local botName = urlDecodeFieldStrict(fields[2], 64, false)
    local status = string.upper(trim(fields[3]))
    local mainItem = parseBoundedInteger(fields[4], 0, 4294967295)
    local mainEnchant = parseBoundedInteger(fields[5], 0, 4294967295)
    local mainDuration = parseBoundedInteger(fields[6], 0, 4294967295)
    local offItem = parseBoundedInteger(fields[7], 0, 4294967295)
    local offEnchant = parseBoundedInteger(fields[8], 0, 4294967295)
    local offDuration = parseBoundedInteger(fields[9], 0, 4294967295)

    if not isValidStateToken(token)
        or not botName
        or (status ~= "OK" and status ~= "RATE_LIMIT" and status ~= "BOT_NOT_VISIBLE" and status ~= "FORBIDDEN")
        or mainItem == nil
        or mainEnchant == nil
        or mainDuration == nil
        or offItem == nil
        or offEnchant == nil
        or offDuration == nil then
      state.lastError = "WEAPON_ENCHANT_BAD_PAYLOAD"
      return true
    end

    state.lastError = status == "OK" and nil or ("WEAPON_ENCHANT_" .. status)
    debugPrint("ADDON:RX", "WEAPON_ENCHANT", payload or "")

    if MultiBot.OnWeaponEnchantDebug then
      MultiBot.OnWeaponEnchantDebug({
        token = token,
        botName = botName,
        status = status,
        mainItem = mainItem,
        mainEnchant = mainEnchant,
        mainDuration = mainDuration,
        offItem = offItem,
        offEnchant = offEnchant,
        offDuration = offDuration,
      })
    end

    return true
  end

  -- MB_ISSUE33_SELF_BOT_V1_RX_BEGIN
  if Comm.HandleSelfBotAddonMessage(opcode, payload, state) then
    return true
  end
  -- MB_ISSUE33_SELF_BOT_V1_RX_END

  -- MB_SELFBOT_ACTION_V1_RX_BEGIN
  if Comm.HandleSelfActionAddonMessage(opcode, payload, state) then
    return true
  end
  -- MB_SELFBOT_ACTION_V1_RX_END

  -- MB_SELFBOT_STRATEGY_V1_RX_BEGIN
  if Comm.HandleSelfStrategyAddonMessage(opcode, payload, state) then
    return true
  end
  -- MB_SELFBOT_STRATEGY_V1_RX_END

  if opcode == "ROSTER" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyRosterPayload(payload)
    return true
  end

  if opcode == "STATE_BEGIN" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStateBeginPayload(payload)
    return true
  end

  if opcode == "STATE_ITEM" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStateItemPayload(payload)
    return true
  end

  if opcode == "STATE_END" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStateEndPayload(payload)
    return true
  end

  if opcode == "STATE_ABORT" then
    state.connected = true
    Comm.ApplyStateAbortPayload(payload)
    return true
  end

  if opcode == "STATES_BEGIN" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStatesBeginPayload(payload)
    return true
  end

  if opcode == "STATES_END" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyStatesEndPayload(payload)
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

  if opcode == "PROFESSION" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyBotProfessionPayload(payload)
    return true
  end

  if opcode == "PROFESSIONS" then
    state.connected = true
    state.lastError = nil
    Comm.ApplyBotProfessionsPayload(payload)
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

  if opcode == "TRAINER_BEGIN" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyTrainerBeginPayload(payload)
  end

  if opcode == "TRAINER_ITEM" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyTrainerItemPayload(payload)
  end

  if opcode == "TRAINER_ERROR" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyTrainerErrorPayload(payload)
  end

  if opcode == "TRAINER_END" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyTrainerEndPayload(payload)
  end

  if opcode == "TRAINER_LEARN" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyTrainerLearnPayload(payload)
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

  if opcode == "GAMEOBJECTS_BEGIN" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyGameObjectBeginPayload(payload)
  end

  if opcode == "GAMEOBJECTS_ITEM" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyGameObjectItemPayload(payload)
  end

  if opcode == "GAMEOBJECTS_END" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyGameObjectEndPayload(payload)
  end

  if opcode == "GAMEOBJECTS_DONE" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyGameObjectDonePayload(payload)
  end

  if opcode == "INV_EXACT_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    local active = getActiveInventoryExactRequest(botName, token)
    if active then
      if active.begun then
        active.integrityError = "DUPLICATE_BEGIN"
        state.lastError = "INV_EXACT_DUPLICATE_BEGIN"
      else
        active.begun = true
        active.integrityError = nil
        active.bags = {}
        active.items = {}
        active.itemsByPosition = {}
      end
    end

    return true
  end

  if opcode == "INV_BAG" then
    local fields = splitFields(payload or "")
    state.connected = true
    state.lastError = nil

    if #fields ~= 7 then
      local active = #fields >= 2 and getActiveInventoryExactRequest(trim(fields[1]), trim(fields[2])) or nil
      if active then
        active.integrityError = "INV_BAG_BAD_FIELD_COUNT"
      end
      state.lastError = "INV_BAG_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(fields[1])
    local token = trim(fields[2])
    local kind = trim(fields[3])
    local bag = isWholeNumberInRange(fields[4], 0, 255)
    local slotStart = isWholeNumberInRange(fields[5], 0, 255)
    local slotCount = isWholeNumberInRange(fields[6], 0, 255)
    local bagItemId = isWholeNumberInRange(fields[7], 0, 4294967295)
    local active = getActiveInventoryExactRequest(botName, token)

    if not active then
      return true
    end
    if not active.begun then
      active.integrityError = "FRAME_BEFORE_BEGIN"
      state.lastError = "INV_BAG_BEFORE_BEGIN"
      return true
    end

    if (kind ~= "BACKPACK" and kind ~= "BAG" and kind ~= "KEYRING")
        or bag == nil or slotStart == nil or slotCount == nil or bagItemId == nil then
      active.integrityError = "INV_BAG_BAD_FIELDS"
      state.lastError = "INV_BAG_BAD_FIELDS"
      return true
    end

    local entry = {
      kind = kind,
      bag = bag,
      slotStart = slotStart,
      slotCount = slotCount,
      itemId = bagItemId,
    }
    table.insert(active.bags, entry)
    return true
  end

  if opcode == "INV_ITEM_LOC" then
    local fields = splitFields(payload or "")
    state.connected = true
    state.lastError = nil

    if #fields ~= 7 then
      local active = #fields >= 2 and getActiveInventoryExactRequest(trim(fields[1]), trim(fields[2])) or nil
      if active then
        active.integrityError = "INV_ITEM_LOC_BAD_FIELD_COUNT"
      end
      state.lastError = "INV_ITEM_LOC_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(fields[1])
    local token = trim(fields[2])
    local bag = isWholeNumberInRange(fields[3], 0, 255)
    local slot = isWholeNumberInRange(fields[4], 0, 255)
    local itemId = isWholeNumberInRange(fields[5], 1, 4294967295)
    local count = isWholeNumberInRange(fields[6], 1, 4294967295)
    local soulbound = trim(fields[7])
    local active = getActiveInventoryExactRequest(botName, token)

    if not active then
      return true
    end
    if not active.begun then
      active.integrityError = "FRAME_BEFORE_BEGIN"
      state.lastError = "INV_ITEM_LOC_BEFORE_BEGIN"
      return true
    end

    if bag == nil or slot == nil or itemId == nil or count == nil or (soulbound ~= "0" and soulbound ~= "1") then
      active.integrityError = "INV_ITEM_LOC_BAD_FIELDS"
      state.lastError = "INV_ITEM_LOC_BAD_FIELDS"
      return true
    end

    local positionKey = tostring(bag) .. ":" .. tostring(slot)
    if active.itemsByPosition[positionKey] then
      active.integrityError = "DUPLICATE_ITEM_POSITION"
      state.lastError = "INV_ITEM_LOC_DUPLICATE_POSITION"
      return true
    end

    local item = {
      bag = bag,
      slot = slot,
      itemId = itemId,
      count = count,
      soulbound = soulbound == "1",
    }
    table.insert(active.items, item)
    active.itemsByPosition[positionKey] = item
    return true
  end

  if opcode == "INV_EXACT_ERROR" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, reason = splitOnce(rest or "", "~")
    state.connected = true

    local active = getActiveInventoryExactRequest(botName, token)
    if active then
      if not active.begun then
        active.integrityError = "FRAME_BEFORE_BEGIN"
        state.lastError = "INV_EXACT_ERROR_BEFORE_BEGIN"
      else
        reason = trim(reason)
        active.integrityError = reason ~= "" and reason or "FAILED"
        state.lastError = "INV_EXACT_" .. active.integrityError
      end
    end
    return true
  end

  if opcode == "INV_EXACT_END" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true

    local active = getActiveInventoryExactRequest(botName, token)
    if active and active.begun and not active.integrityError then
      local snapshot = {
        botName = active.botName,
        token = active.token,
        receivedAt = safeNow(),
        bags = active.bags or {},
        items = active.items or {},
        itemsByPosition = active.itemsByPosition or {},
      }
      state.inventoryExactSnapshots[active.botNameKey] = snapshot
      state.lastError = nil

      if MultiBot.OnBridgeInventoryExactSnapshot then
        MultiBot.OnBridgeInventoryExactSnapshot(active.botName, snapshot)
      end
    elseif active then
      state.lastError = "INV_EXACT_" .. tostring(active.integrityError or "INCOMPLETE")
    end

    clearActiveInventoryExactRequest(botName, token)
    return true
  end

  if opcode == "INV_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    state.connected = true
    state.lastError = nil

    local active = getActiveInventoryRequest(botName, token)
    if active then
      active.begun = true
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
      if inventory and inventory.endPayload then
        inventory:endPayload(trim(botName))
      end
    end

    clearActiveInventoryRequest(botName, token)
    return true
  end

  if opcode == "BANK_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveBankRequest(botName, token)
    if active then
      active.items = {}
      active.error = nil
      if MultiBot.OnBridgeBankBegin then
        MultiBot.OnBridgeBankBegin(botName, token)
      end
    end

    return true
  end

  if opcode == "BANK_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, encodedLine = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveBankRequest(botName, token)
    if active then
      table.insert(active.items, urlDecodeField(encodedLine))
    end

    return true
  end

  if opcode == "BANK_ERROR" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, reason = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    reason = trim(urlDecodeField(reason))
    state.connected = true
    state.lastError = nil

    local active = getActiveBankRequest(botName, token)
    if active then
      active.error = reason ~= "" and reason or "FAILED"
    end

    return true
  end

  if opcode == "BANK_END" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveBankRequest(botName, token)
    if active then
      local key = string.lower(botName)
      state.bankItems[key] = active.items or {}
      if MultiBot.OnBridgeBankItems then
        MultiBot.OnBridgeBankItems(botName, state.bankItems[key], active.error, token)
      end
    end

    clearActiveBankRequest(botName, token)
    return true
  end

  if opcode == "GBANK_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveGuildBankRequest(botName, token)
    if active then
      active.items = {}
      active.error = nil
      if MultiBot.OnBridgeGuildBankBegin then
        MultiBot.OnBridgeGuildBankBegin(botName, token)
      end
    end

    return true
  end

  if opcode == "GBANK_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, encodedLine = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveGuildBankRequest(botName, token)
    if active then
      table.insert(active.items, urlDecodeField(encodedLine))
    end

    return true
  end

  if opcode == "GBANK_ERROR" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, reason = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    reason = trim(urlDecodeField(reason))
    state.connected = true
    state.lastError = nil

    local active = getActiveGuildBankRequest(botName, token)
    if active then
      active.error = reason ~= "" and reason or "FAILED"
    end

    return true
  end

  if opcode == "GBANK_RIGHTS" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local canWithdraw, remaining = splitOnce(rest2 or "", "~")
    botName = trim(urlDecodeField(botName))
    canWithdraw = trim(canWithdraw)
    remaining = tonumber(remaining or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveGuildBankRequest(botName, token)
    if active then
      active.rights = {
        canWithdraw = canWithdraw == "1" or string.lower(canWithdraw) == "true",
        remaining = remaining,
      }
    end

    return true
  end

  if opcode == "GBANK_END" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    state.connected = true
    state.lastError = nil

    local active = getActiveGuildBankRequest(botName, token)
    if active then
      local key = string.lower(botName)
      state.guildBankItems[key] = active.items or {}
      if MultiBot.OnBridgeGuildBankItems then
        MultiBot.OnBridgeGuildBankItems(botName, state.guildBankItems[key], active.error, token, active.rights)
      end
    end

    clearActiveGuildBankRequest(botName, token)
    return true
  end

  if opcode == "INVENTORY_ITEM_MOVE" then
    local fields = splitFields(payload)
    if #fields ~= 8 then
      state.lastError = "ITEM_MOVE_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcBag = parseBoundedInteger(fields[5], 0, 255)
    local srcSlot = parseBoundedInteger(fields[6], 0, 255)
    local dstBag = parseBoundedInteger(fields[7], 0, 255)
    local dstSlot = parseBoundedInteger(fields[8], 0, 255)

    state.connected = true
    local command = state.inventoryItemMoves and state.inventoryItemMoves[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcBag == nil or srcSlot == nil or dstBag == nil or dstSlot == nil then
      state.lastError = "ITEM_MOVE_BAD_RESPONSE"
      if command then
        state.inventoryItemMoves[token] = nil
        if MultiBot.OnBridgeInventoryItemMoveResult then
          MultiBot.OnBridgeInventoryItemMoveResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.srcBag, command.srcSlot, command.dstBag, command.dstSlot, command
          )
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcBag == command.srcBag and srcSlot == command.srcSlot and
      dstBag == command.dstBag and dstSlot == command.dstSlot

    state.inventoryItemMoves[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "ITEM_MOVE_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_MOVE_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemMoveResult then
      MultiBot.OnBridgeInventoryItemMoveResult(
        command.botName, status, reason,
        command.srcBag, command.srcSlot, command.dstBag, command.dstSlot, command
      )
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_MOVE", botName, token, status, reason, srcBag, srcSlot, dstBag, dstSlot)
    return true
  end

  local structuredHandler = STRUCTURED_OPCODE_HANDLERS[opcode]
  if structuredHandler then
    return structuredHandler(payload, state)
  end

  if opcode == "INVENTORY_ITEM_EQUIP" then
    local fields = splitFields(payload)
    if #fields ~= 7 then
      state.lastError = "ITEM_EQUIP_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcBag = parseBoundedInteger(fields[5], 0, 255)
    local srcSlot = parseBoundedInteger(fields[6], 0, 255)
    local dstSlot = parseBoundedInteger(fields[7], 0, 255)

    state.connected = true
    local command = state.inventoryItemEquips and state.inventoryItemEquips[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcBag == nil or srcSlot == nil or dstSlot == nil then
      state.lastError = "ITEM_EQUIP_BAD_RESPONSE"
      if command then
        state.inventoryItemEquips[token] = nil
        if MultiBot.OnBridgeInventoryItemEquipResult then
          MultiBot.OnBridgeInventoryItemEquipResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.srcBag, command.srcSlot, command.dstSlot, command
          )
        end
        if Comm.RequestInventoryExact then
          Comm.RequestInventoryExact(command.botName)
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcBag == command.srcBag and srcSlot == command.srcSlot

    state.inventoryItemEquips[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "ITEM_EQUIP_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_EQUIP_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemEquipResult then
      MultiBot.OnBridgeInventoryItemEquipResult(
        command.botName, status, reason,
        command.srcBag, command.srcSlot, dstSlot, command
      )
    end

    if status == "OK" then
      local refreshed = MultiBot.RequestInventoryRefresh
        and MultiBot.RequestInventoryRefresh(command.botName, 0.30)
      if not refreshed and Comm.RequestInventoryExact then
        Comm.RequestInventoryExact(command.botName)
      end
    elseif Comm.RequestInventoryExact then
      Comm.RequestInventoryExact(command.botName)
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_EQUIP", botName, token, status, reason, srcBag, srcSlot, dstSlot)
    return true
  end

  if opcode == "INVENTORY_ITEM_UNEQUIP" then
    local fields = splitFields(payload)
    if #fields ~= 6 then
      state.lastError = "ITEM_UNEQUIP_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcSlot = parseBoundedInteger(fields[5], 0, 18)
    local srcItemId = parseBoundedInteger(fields[6], 1, 4294967295)

    state.connected = true
    local command = state.inventoryItemUnequips and state.inventoryItemUnequips[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcSlot == nil or srcItemId == nil then
      state.lastError = "ITEM_UNEQUIP_BAD_RESPONSE"
      if command then
        state.inventoryItemUnequips[token] = nil
        if MultiBot.OnBridgeInventoryItemUnequipResult then
          MultiBot.OnBridgeInventoryItemUnequipResult(
            command.botName, "ERR", "BAD_RESPONSE", command.srcSlot, command.srcItemId, command
          )
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcSlot == command.srcSlot and srcItemId == command.srcItemId

    state.inventoryItemUnequips[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "ITEM_UNEQUIP_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_UNEQUIP_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemUnequipResult then
      MultiBot.OnBridgeInventoryItemUnequipResult(
        command.botName, status, reason, command.srcSlot, command.srcItemId, command
      )
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_UNEQUIP", botName, token, status, reason, srcSlot, srcItemId)
    return true
  end

  -- MB_ITEM_SELL_SINGLE_V1_RX_BEGIN
  if opcode == "INVENTORY_ITEM_SELL" then
    local fields = splitFields(payload)
    if #fields ~= 8 then
      state.lastError = "ITEM_SELL_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcBag = parseBoundedInteger(fields[5], 0, 255)
    local srcSlot = parseBoundedInteger(fields[6], 0, 255)
    local srcItemId = parseBoundedInteger(fields[7], 1, 4294967295)
    local soldCount = parseBoundedInteger(fields[8], 0, INVENTORY_ITEM_SELL_MAX_COUNT)

    state.connected = true
    local command = state.inventoryItemSells and state.inventoryItemSells[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcBag == nil or srcSlot == nil or srcItemId == nil or soldCount == nil then
      state.lastError = "ITEM_SELL_BAD_RESPONSE"
      if command then
        state.inventoryItemSells[token] = nil
        if MultiBot.OnBridgeInventoryItemSellResult then
          MultiBot.OnBridgeInventoryItemSellResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.srcBag, command.srcSlot, command.srcItemId, 0, command
          )
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcBag == command.srcBag and srcSlot == command.srcSlot and srcItemId == command.srcItemId and
      soldCount <= command.srcCount and
      ((status == "OK" and soldCount >= 1) or (status == "ERR" and soldCount == 0))

    state.inventoryItemSells[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      soldCount = 0
      state.lastError = "ITEM_SELL_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_SELL_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemSellResult then
      MultiBot.OnBridgeInventoryItemSellResult(
        command.botName, status, reason,
        command.srcBag, command.srcSlot, command.srcItemId, soldCount, command
      )
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_SELL", botName, token, status, reason, srcBag, srcSlot, srcItemId, soldCount)
    return true
  end
  -- MB_ITEM_SELL_SINGLE_V1_RX_END
  -- MB_VENDOR_BUYBACK_V1_RX_DISPATCH_BEGIN
  if Comm.HandleInventoryBuybackAddonMessage(opcode, payload, state) then
    return true
  end
  -- MB_VENDOR_BUYBACK_V1_RX_DISPATCH_END


  if opcode == "INVENTORY_ITEM_USE" then
    local fields = splitFields(payload)
    if #fields ~= 7 then
      state.lastError = "ITEM_USE_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcBag = parseBoundedInteger(fields[5], 0, 255)
    local srcSlot = parseBoundedInteger(fields[6], 0, 255)
    local srcItemId = parseBoundedInteger(fields[7], 1, 4294967295)

    state.connected = true
    local command = state.inventoryItemUses and state.inventoryItemUses[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcBag == nil or srcSlot == nil or srcItemId == nil then
      state.lastError = "ITEM_USE_BAD_RESPONSE"
      if command then
        state.inventoryItemUses[token] = nil
        if MultiBot.OnBridgeInventoryItemUseResult then
          MultiBot.OnBridgeInventoryItemUseResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.srcBag, command.srcSlot, command.srcItemId, command
          )
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcBag == command.srcBag and srcSlot == command.srcSlot and srcItemId == command.srcItemId

    state.inventoryItemUses[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "ITEM_USE_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_USE_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemUseResult then
      MultiBot.OnBridgeInventoryItemUseResult(
        command.botName, status, reason,
        command.srcBag, command.srcSlot, command.srcItemId, command
      )
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_USE", botName, token, status, reason, srcBag, srcSlot, srcItemId)
    return true
  end

  if opcode == "INVENTORY_ITEM_DESTROY" then
    local fields = splitFields(payload)
    if #fields ~= 7 then
      state.lastError = "ITEM_DESTROY_BAD_FIELD_COUNT"
      return true
    end

    local botName = urlDecodeFieldStrict(fields[1], 64, false)
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = urlDecodeFieldStrict(fields[4], 64, false)
    local srcBag = parseBoundedInteger(fields[5], 0, 255)
    local srcSlot = parseBoundedInteger(fields[6], 0, 255)
    local srcItemId = parseBoundedInteger(fields[7], 1, 4294967295)

    state.connected = true
    local command = state.inventoryItemDestroys and state.inventoryItemDestroys[token] or nil
    if not botName or not isValidStateToken(token) or (status ~= "OK" and status ~= "ERR") or not reason or
      srcBag == nil or srcSlot == nil or srcItemId == nil then
      state.lastError = "ITEM_DESTROY_BAD_RESPONSE"
      if command then
        state.inventoryItemDestroys[token] = nil
        if MultiBot.OnBridgeInventoryItemDestroyResult then
          MultiBot.OnBridgeInventoryItemDestroyResult(
            command.botName, "ERR", "BAD_RESPONSE",
            command.srcBag, command.srcSlot, command.srcItemId, command
          )
        end
      end
      return true
    end

    if not command then
      return true
    end

    local responseMatches = string.lower(botName) == command.botNameKey and
      srcBag == command.srcBag and srcSlot == command.srcSlot and srcItemId == command.srcItemId

    state.inventoryItemDestroys[token] = nil
    if not responseMatches then
      status = "ERR"
      reason = "RESPONSE_MISMATCH"
      state.lastError = "ITEM_DESTROY_RESPONSE_MISMATCH"
    elseif status == "OK" then
      state.lastError = nil
    else
      state.lastError = "ITEM_DESTROY_" .. reason
    end

    if MultiBot.OnBridgeInventoryItemDestroyResult then
      MultiBot.OnBridgeInventoryItemDestroyResult(
        command.botName, status, reason,
        command.srcBag, command.srcSlot, command.srcItemId, command
      )
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_DESTROY", botName, token, status, reason, srcBag, srcSlot, srcItemId)
    return true
  end
  if opcode == "INVENTORY_ITEM_ACTION" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local action, rest3 = splitOnce(rest2 or "", "~")
    local itemId, rest4 = splitOnce(rest3 or "", "~")
    local result, rest5 = splitOnce(rest4 or "", "~")
    local reason, moved = splitOnce(rest5 or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    action = string.upper(trim(action))
    itemId = tonumber(itemId or "0") or 0
    result = trim(result)
    reason = trim(urlDecodeField(reason))
    moved = tonumber(moved or "0") or 0
    state.connected = true
    state.lastError = nil

    local command = state.inventoryItemActions and state.inventoryItemActions[token] or nil
    if command then
      command.botName = botName ~= "" and botName or command.botName
      command.action = action ~= "" and action or command.action
      command.itemId = itemId > 0 and itemId or command.itemId
      command.result = result
      command.reason = reason
      command.moved = moved

      if MultiBot.OnBridgeInventoryItemActionResult then
        MultiBot.OnBridgeInventoryItemActionResult(command.botName, command.action, command.itemId, result, reason, moved, command)
      end

      state.inventoryItemActions[token] = nil
    end

    debugPrint("ADDON:RX", "INVENTORY_ITEM_ACTION", botName, action, itemId, result, reason, moved)
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

  if opcode == "BOT_SKILLS_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotSkillRequest(botName, token)
    if active then
      active.items = {}
    end

    return true
  end

  if opcode == "BOT_SKILLS_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local category, rest3 = splitOnce(rest2 or "", "~")
    local skillId, rest4 = splitOnce(rest3 or "", "~")
    local key, rest5 = splitOnce(rest4 or "", "~")
    local skillName, rest6 = splitOnce(rest5 or "", "~")
    local value, maxValue = splitOnce(rest6 or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotSkillRequest(botName, token)
    if active then
      table.insert(active.items, {
        category = trim(urlDecodeField(category)),
        skillId = tonumber(skillId or "0") or 0,
        key = trim(urlDecodeField(key)),
        name = trim(urlDecodeField(skillName)),
        value = tonumber(value or "0") or 0,
        max = tonumber(maxValue or "0") or 0,
      })
    end

    return true
  end

  if opcode == "BOT_SKILLS_END" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotSkillRequest(botName, token)
    if active then
      local key = string.lower(botName)
      state.botSkills[key] = active.items or {}
      if MultiBot.OnBridgeBotSkills then
        MultiBot.OnBridgeBotSkills(botName, state.botSkills[key], token)
      end
      state.botSkillActive = nil
    end

    return true
  end

  if opcode == "BOT_REPUTATIONS_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotReputationRequest(botName, token)
    if active then
      active.items = {}
    end

    return true
  end

  if opcode == "BOT_REPUTATION_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local factionId, rest3 = splitOnce(rest2 or "", "~")
    local factionName, rest4 = splitOnce(rest3 or "", "~")
    local rank, rest5 = splitOnce(rest4 or "", "~")
    local value, maxValue = splitOnce(rest5 or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotReputationRequest(botName, token)
    if active then
      table.insert(active.items, {
        factionId = tonumber(factionId or "0") or 0,
        name = trim(urlDecodeField(factionName)),
        rank = tonumber(rank or "0") or 0,
        value = tonumber(value or "0") or 0,
        max = tonumber(maxValue or "0") or 0,
      })
    end

    return true
  end

  if opcode == "BOT_REPUTATIONS_END" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotReputationRequest(botName, token)
    if active then
      local key = string.lower(botName)
      state.botReputations[key] = active.items or {}
      if MultiBot.OnBridgeBotReputations then
        MultiBot.OnBridgeBotReputations(botName, state.botReputations[key], token)
      end
      state.botReputationActive = nil
    end

    return true
  end

  if opcode == "BOT_EMBLEMS_BEGIN" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotEmblemRequest(botName, token)
    if active then
      active.items = {}
      active.money = nil
    end

    return true
  end

  if opcode == "BOT_EMBLEM_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local itemId, count = splitOnce(rest2 or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotEmblemRequest(botName, token)
    if active then
      table.insert(active.items, {
        itemId = tonumber(itemId or "0") or 0,
        count = tonumber(count or "0") or 0,
      })
    end

    return true
  end

  if opcode == "BOT_EMBLEMS_MONEY" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, money = splitOnce(rest or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotEmblemRequest(botName, token)
    if active then
      active.money = tonumber(money or "0") or 0
    end

    return true
  end

  if opcode == "BOT_EMBLEMS_END" then
    local botName, token = splitOnce(payload or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    state.connected = true
    state.lastError = nil

    local active = getActiveBotEmblemRequest(botName, token)
    if active then
      local key = string.lower(botName)
      state.botEmblems[key] = active.items or {}
      state.botEmblemMoney[key] = active.money
      if MultiBot.OnBridgeBotEmblems then
        MultiBot.OnBridgeBotEmblems(botName, state.botEmblems[key], token, state.botEmblemMoney[key])
      end
      state.botEmblemActive = nil
    end

    return true
  end

  if opcode == "ENCHANT_TRADE_BEGIN" then
    local fields = splitFields(payload or "")
    if #fields ~= 6 then
      state.lastError = "ENCHANT_TRADE_BEGIN_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(urlDecodeField(fields[1]))
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = string.upper(trim(urlDecodeField(fields[4])))
    local skillValue = tonumber(fields[5] or "0") or 0
    local maxSkill = tonumber(fields[6] or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveEnchantTradeRequest(botName, token)
    if active then
      if active.began then
        active.integrityError = active.integrityError or "DUPLICATE_BEGIN"
        state.lastError = "ENCHANT_TRADE_DUPLICATE_BEGIN"
      else
        active.began = true
        active.status = status
        active.reason = reason
        active.skillValue = skillValue
        active.maxSkill = maxSkill
        active.items = {}
        active.itemBySpellId = {}
        markEnchantTradeListProgress(active)
      end
    end

    return true
  end

  if opcode == "ENCHANT_TRADE_ITEM" then
    local fields = splitFields(payload or "")
    if #fields ~= 7 then
      state.lastError = "ENCHANT_TRADE_ITEM_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(urlDecodeField(fields[1]))
    local token = trim(fields[2])
    local spellId = tonumber(fields[3] or "0") or 0
    local difficulty = trim(urlDecodeField(fields[4]))
    local available = tonumber(fields[5] or "0") or 0
    local hasTools = tonumber(fields[6] or "0") or 0
    local materialCount = tonumber(fields[7] or "")
    state.connected = true
    state.lastError = nil

    local active = getActiveEnchantTradeRequest(botName, token)
    if active then
      if not active.began then
        active.integrityError = active.integrityError or "MISSING_BEGIN"
        state.lastError = "ENCHANT_TRADE_ITEM_BEFORE_BEGIN"
      elseif spellId <= 0 or materialCount == nil or materialCount < 0 or materialCount > 256 then
        active.integrityError = active.integrityError or "BAD_ITEM"
        state.lastError = "ENCHANT_TRADE_ITEM_INVALID"
      else
        active.itemBySpellId = active.itemBySpellId or {}
        if active.itemBySpellId[spellId] then
          active.integrityError = active.integrityError or "DUPLICATE_SPELL_ID"
          state.lastError = "ENCHANT_TRADE_DUPLICATE_SPELL_ID"
        else
          local entry = {
            spellId = spellId,
            difficulty = difficulty,
            available = available ~= 0 and 1 or 0,
            materials = {},
            hasTools = hasTools ~= 0 and 1 or 0,
            expectedMaterialCount = materialCount,
            receivedMaterialCount = 0,
            materialIndexes = {},
          }
          table.insert(active.items, entry)
          active.itemBySpellId[spellId] = entry
          markEnchantTradeListProgress(active)
        end
      end
    end

    return true
  end

  if opcode == "ENCHANT_TRADE_MATERIAL" then
    local fields = splitFields(payload or "")
    if #fields ~= 7 then
      state.lastError = "ENCHANT_TRADE_MATERIAL_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(urlDecodeField(fields[1]))
    local token = trim(fields[2])
    local spellId = tonumber(fields[3] or "0") or 0
    local materialIndex = tonumber(fields[4] or "0") or 0
    local itemId = tonumber(fields[5] or "0") or 0
    local required = tonumber(fields[6] or "0") or 0
    local available = tonumber(fields[7] or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveEnchantTradeRequest(botName, token)
    if active then
      if not active.began then
        active.integrityError = active.integrityError or "MISSING_BEGIN"
        state.lastError = "ENCHANT_TRADE_MATERIAL_BEFORE_BEGIN"
      else
        local entry = active.itemBySpellId and active.itemBySpellId[spellId] or nil
        if not entry then
          active.integrityError = active.integrityError or "MATERIAL_WITHOUT_ITEM"
          state.lastError = "ENCHANT_TRADE_MATERIAL_WITHOUT_ITEM"
        else
          local expectedMaterialCount = tonumber(entry.expectedMaterialCount or 0) or 0
          entry.materialIndexes = entry.materialIndexes or {}
          if materialIndex <= 0 or materialIndex > expectedMaterialCount then
            active.integrityError = active.integrityError or "MATERIAL_INDEX_OUT_OF_RANGE"
            state.lastError = "ENCHANT_TRADE_MATERIAL_INDEX_OUT_OF_RANGE"
          elseif entry.materialIndexes[materialIndex] then
            active.integrityError = active.integrityError or "DUPLICATE_MATERIAL_INDEX"
            state.lastError = "ENCHANT_TRADE_DUPLICATE_MATERIAL_INDEX"
          elseif itemId <= 0 or required <= 0 then
            active.integrityError = active.integrityError or "BAD_MATERIAL"
            state.lastError = "ENCHANT_TRADE_MATERIAL_INVALID"
          else
            entry.materials[materialIndex] = {
              itemId = itemId,
              required = required,
              available = available,
            }
            entry.materialIndexes[materialIndex] = true
            entry.receivedMaterialCount = (tonumber(entry.receivedMaterialCount or 0) or 0) + 1
            markEnchantTradeListProgress(active)
          end
        end
      end
    end

    return true
  end

  if opcode == "ENCHANT_TRADE_END" then
    local fields = splitFields(payload or "")
    if #fields ~= 5 then
      state.lastError = "ENCHANT_TRADE_END_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(urlDecodeField(fields[1]))
    local token = trim(fields[2])
    local status = string.upper(trim(fields[3]))
    local reason = string.upper(trim(urlDecodeField(fields[4])))
    local count = tonumber(fields[5] or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveEnchantTradeRequest(botName, token)
    if active then
      active.status = status
      active.reason = reason
      active.count = count

      local items = active.items or {}
      local deliveredItems = items
      local integrityError = active.integrityError

      if not active.began then
        integrityError = integrityError or "MISSING_BEGIN"
      end

      if status == "OK" and not integrityError and #items ~= count then
        integrityError = "COUNT_MISMATCH"
      end

      if status == "OK" and not integrityError then
        for _, entry in ipairs(items) do
          local expectedMaterialCount = tonumber(entry.expectedMaterialCount or 0) or 0
          local receivedMaterialCount = tonumber(entry.receivedMaterialCount or 0) or 0
          if receivedMaterialCount ~= expectedMaterialCount then
            integrityError = "MATERIAL_COUNT_MISMATCH"
            break
          end

          for materialIndex = 1, expectedMaterialCount do
            if not entry.materialIndexes or not entry.materialIndexes[materialIndex] then
              integrityError = "MATERIAL_INDEX_GAP"
              break
            end
          end

          if integrityError then
            break
          end
        end
      end

      if integrityError then
        status = "ERR"
        reason = "TRY_AGAIN"
        active.status = status
        active.reason = reason
        state.lastError = "ENCHANT_TRADE_" .. integrityError
        deliveredItems = {}
      elseif status == "OK" then
        local key = string.lower(active.botName or botName)
        state.enchantTradeLists[key] = items
      end

      state.enchantTradeActive = nil

      if MultiBot.OnBridgeEnchantTradeList then
        MultiBot.OnBridgeEnchantTradeList(active.botName or botName, deliveredItems, {
          token = active.token or token,
          status = status,
          reason = reason,
          skillValue = active.skillValue or 0,
          maxSkill = active.maxSkill or 0,
          count = count,
        })
      end
    end

    return true
  end

  if opcode == "ENCHANT_TRADE_RESULT" then
    local fields = splitFields(payload or "")
    if #fields ~= 6 then
      state.lastError = "ENCHANT_TRADE_RESULT_BAD_FIELD_COUNT"
      return true
    end

    local botName = trim(urlDecodeField(fields[1]))
    local token = trim(fields[2])
    local spellId = tonumber(fields[3] or "0") or 0
    local status = string.upper(trim(fields[4]))
    local reason = string.upper(trim(urlDecodeField(fields[5])))
    local accepted = tonumber(fields[6] or "0") or 0
    state.connected = true
    state.lastError = nil

    local command = state.enchantTradeCommands and state.enchantTradeCommands[token] or nil
    if command then
      if botName == "" or string.lower(botName) ~= tostring(command.botNameKey or "") then
        state.lastError = "ENCHANT_TRADE_RESULT_BOT_MISMATCH"
        return true
      end

      if spellId <= 0 or spellId ~= tonumber(command.spellId or 0) then
        state.lastError = "ENCHANT_TRADE_RESULT_SPELL_MISMATCH"
        return true
      end

      state.enchantTradeCommands[token] = nil
      command.accepted = accepted ~= 0
      command.status = status
      command.reason = reason

      if MultiBot.OnBridgeEnchantTradeResult then
        MultiBot.OnBridgeEnchantTradeResult(command.botName, command.spellId, status, reason, command)
      end
    end

    return true
  end

  if opcode == "PROFESSION_RECIPES_BEGIN" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, skillId = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    skillId = tonumber(skillId or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveProfessionRecipeRequest(botName, token, skillId)
    if active then
      active.recipes = {}
    end

    return true
  end

  if opcode == "PROFESSION_RECIPES_ITEM" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, rest2 = splitOnce(rest or "", "~")
    local skillId, rest3 = splitOnce(rest2 or "", "~")
    local spellId, rest4 = splitOnce(rest3 or "", "~")
    local itemId, rest5 = splitOnce(rest4 or "", "~")
    local difficulty, rest6 = splitOnce(rest5 or "", "~")
    local craftable, materials = splitOnce(rest6 or "", "~")

    botName = trim(urlDecodeField(botName))
    token = trim(token)
    skillId = tonumber(skillId or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveProfessionRecipeRequest(botName, token, skillId)
    if active then
      table.insert(active.recipes, {
        skillId = skillId,
        spellId = tonumber(spellId or "0") or 0,
        itemId = tonumber(itemId or "0") or 0,
        difficulty = trim(urlDecodeField(difficulty)),
        craftable = tonumber(craftable or "0") or 0,
        materials = parseRecipeMaterials(urlDecodeField(materials)),
      })
    end

    return true
  end

  if opcode == "PROFESSION_RECIPES_END" then
    local botName, rest = splitOnce(payload or "", "~")
    local token, skillId = splitOnce(rest or "", "~")
    botName = trim(urlDecodeField(botName))
    token = trim(token)
    skillId = tonumber(skillId or "0") or 0
    state.connected = true
    state.lastError = nil

    local active = getActiveProfessionRecipeRequest(botName, token, skillId)
    if active then
      local key = string.lower(botName) .. ":" .. tostring(skillId)
      state.professionRecipes[key] = active.recipes or {}
      if MultiBot.OnBridgeProfessionRecipes then
        MultiBot.OnBridgeProfessionRecipes(botName, skillId, state.professionRecipes[key], token)
      end
      state.professionRecipeActive = nil
    end

    return true
  end

  if opcode == "PROFESSION_RECIPE_CRAFT" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyProfessionRecipeCraftPayload(payload)
  end

  if opcode == "FORMATIONS_BEGIN" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyFormationsBeginPayload(payload)
  end

  if opcode == "FORMATIONS_ITEM" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyFormationsItemPayload(payload)
  end

  if opcode == "FORMATIONS_END" then
    state.connected = true
    state.lastError = nil
    return Comm.ApplyFormationsEndPayload(payload)
  end

  if opcode == "FORMATION_ACK" then
    local scope, rest = splitOnce(payload or "", "~")
    local target, rest2 = splitOnce(rest or "", "~")
    local token, rest3 = splitOnce(rest2 or "", "~")
    local successText, rest4 = splitOnce(rest3 or "", "~")
    local failureText, encodedFormation = splitOnce(rest4 or "", "~")

    scope = string.upper(trim(scope))
    target = trim(urlDecodeField(target))
    token = trim(token)
    local success = tonumber(successText or "0") or 0
    local failure = tonumber(failureText or "0") or 0
    local formation = string.lower(trim(urlDecodeField(encodedFormation)))

    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "FORMATION_ACK", payload or "")

    local pending = state.formationCommands[token]
    state.formationCommands[token] = nil

    local result = {
      scope = scope,
      target = target,
      token = token,
      success = success,
      failure = failure,
      formation = formation,
    }

    if pending and type(pending.callback) == "function" then
      pending.callback(result)
    end

    if MultiBot.OnFormationCommandApplied then
      MultiBot.OnFormationCommandApplied(result)
    end

    if success <= 0 then
      systemMessage(L("formation.confirm.none"))
    elseif failure > 0 then
      systemMessage(string.format(
        L("formation.confirm.partial"),
        success,
        failure
      ))
    end

    return true
  end

  if opcode == "STRATEGY_ACK" then
    local fields = splitFields(payload or "")
    if #fields ~= 8 then
      state.lastError = "STRATEGY_ACK_BAD_FIELD_COUNT"
      return true
    end

    local scope = string.upper(trim(fields[1]))
    local target = urlDecodeFieldStrict(fields[2], 64, true)
    local token = trim(fields[3])
    local stateScope = string.upper(trim(fields[4]))
    local matched = parseBoundedInteger(fields[5], 0, 128)
    local succeeded = parseBoundedInteger(fields[6], 0, 128)
    local failed = parseBoundedInteger(fields[7], 0, 128)
    local reason = urlDecodeFieldStrict(fields[8], 64, false)

    local pending = state.strategyMutationCommands[token]
    if (scope ~= "ALL" and scope ~= "GROUP" and scope ~= "PARTY" and scope ~= "RAID" and scope ~= "BOT")
        or target == nil
        or not isValidStateToken(token)
        or (stateScope ~= "C" and stateScope ~= "N")
        or matched == nil
        or succeeded == nil
        or failed == nil
        or reason == nil
        or succeeded + failed > matched
        or type(pending) ~= "table"
        or pending.scope ~= scope
        or string.lower(pending.target or "") ~= string.lower(target)
        or pending.stateScope ~= stateScope then
      state.lastError = "STRATEGY_ACK_INVALID"
      return true
    end

    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "STRATEGY_ACK", payload or "")

    local status = "failed"
    if matched == 0 then
      status = "no_match"
    elseif succeeded == matched and failed == 0 then
      status = "ok"
    elseif succeeded > 0 then
      status = "partial"
    end

    finishStrategyMutationCommand(token, {
      status = status,
      scope = scope,
      target = target,
      stateScope = stateScope,
      matched = matched,
      succeeded = succeeded,
      failed = failed,
      reason = reason,
    })
    return true
  end

  if opcode == "RTI_ACK" then
    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "RTI_ACK", payload or "")
    return true
  end

  if opcode == "COMBAT_ACK" then
    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "COMBAT_ACK", payload or "")
    return true
  end

  if opcode == "POSITION_ACK" then
    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "POSITION_ACK", payload or "")

    local rest = select(2, splitOnce(payload or "", "~"))
    local rest2 = select(2, splitOnce(rest, "~"))
    local rest3 = select(2, splitOnce(rest2, "~"))
    local executedText, encodedCommand = splitOnce(rest3, "~")
    local executed = tonumber(executedText) or 0
    local command = trim(urlDecodeField(encodedCommand))

    if executed > 0 then
      local distance = string.match(command, "^disperse set%s+(.+)$")

      if distance then
        systemMessage(string.format(
          L("disperse.confirm.set", "Disperse set to %s yards."),
          distance
        ))
      elseif command == "disperse disable" then
        systemMessage(L("disperse.confirm.disable", "Disperse disabled."))
      end
    end

    return true
  end

  if opcode == "LOOT_ACK" then
    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "LOOT_ACK", payload or "")

    local rest = select(2, splitOnce(payload or "", "~"))
    local rest2 = select(2, splitOnce(rest, "~"))
    local rest3 = select(2, splitOnce(rest2, "~"))
    local executedText, encodedCommand = splitOnce(rest3, "~")
    local executed = tonumber(executedText) or 0
    local command = string.lower(trim(urlDecodeField(encodedCommand)))

    if executed <= 0 then
      systemMessage(L("loot.confirm.none", "Loot command was not applied to any bot."))
      return true
    end

    if MultiBot.OnLootCommandApplied then
      MultiBot.OnLootCommandApplied(command, executed)
    end

    if command == "nc +loot" then
      systemMessage(string.format(L("loot.confirm.enable", "Loot enabled for %d bot(s)."), executed))
      return true
    end

    if command == "nc -loot" then
      systemMessage(string.format(L("loot.confirm.disable", "Loot disabled for %d bot(s)."), executed))
      return true
    end

    local profile = command:match("^ll%s+([%w_%-]+)$")
    if profile then
      local profileName = ({
        all = L("loot.profile.all", "All"),
        normal = L("loot.profile.normal", "Normal"),
        gray = L("loot.profile.gray", "Gray"),
        quest = L("loot.profile.quest", "Quest"),
        skill = L("loot.profile.skill", "Skill"),
      })[profile] or profile

      systemMessage(string.format(L("loot.confirm.profile", "Loot profile set to %s for %d bot(s)."), profileName, executed))
    end

    return true
  end

  if opcode == "GROUP_ROLL_ACK" then
    local fields = splitFields(payload or "")
    if #fields ~= 7 then
      state.lastError = "GROUP_ROLL_ACK_BAD_FIELD_COUNT"
      return true
    end

    local token = trim(fields[1])
    local status = string.upper(trim(fields[2]))
    local mode = string.upper(trim(fields[3]))
    local scope = string.upper(trim(fields[4]))
    local matched = parseBoundedInteger(fields[5], 0, 128)
    local invoked = parseBoundedInteger(fields[6], 0, 128)
    local reason = urlDecodeFieldStrict(fields[7], 64, false)
    local pending = state.groupRollCommands[token]

    if not isValidStateToken(token)
        or (status ~= "OK" and status ~= "ERR")
        or (mode ~= "NORMAL" and mode ~= "ITEM")
        or (scope ~= "PARTY" and scope ~= "RAID" and scope ~= "NONE")
        or matched == nil
        or invoked == nil
        or invoked > matched
        or reason == nil
        or type(pending) ~= "table"
        or pending.mode ~= mode then
      state.lastError = "GROUP_ROLL_ACK_INVALID"
      return true
    end

    state.connected = true
    state.lastError = nil
    debugPrint("ADDON:RX", "GROUP_ROLL_ACK", payload or "")

    finishGroupRollCommand(token, {
      status = status == "OK" and "ok" or "error",
      mode = mode,
      scope = scope,
      matched = matched,
      invoked = invoked,
      reason = reason,
    })

    return true
  end

  if opcode == "ERR" then
    state.lastError = payload
    debugPrint("ADDON:RX", "ERR", payload or "")

    local fields = splitFields(payload or "")
    if #fields == 4 then
      local requestType = urlDecodeFieldStrict(fields[2], 32, false)
      local token = trim(fields[3])
      local reason = urlDecodeFieldStrict(fields[4], 64, false)

      requestType = requestType and string.upper(trim(requestType)) or nil
      if requestType and isValidStateToken(token) and reason then
        if Comm.HandleSelfBotProtocolError(requestType, token, reason, state) then
          return true
        elseif Comm.HandleSelfActionProtocolError(requestType, token, reason, state) then
          return true
        elseif Comm.HandleSelfStrategyProtocolError(requestType, token, reason, state) then
          return true
        elseif requestType == "GROUP_ROLL" and state.groupRollCommands[token] then
          finishGroupRollCommand(token, {
            status = "error",
            matched = 0,
            invoked = 0,
            reason = reason,
          })
        elseif requestType == "STRATEGY" and state.strategyMutationCommands[token] then
          finishStrategyMutationCommand(token, {
            status = "error",
            matched = 0,
            succeeded = 0,
            failed = 0,
            reason = reason,
          })
        elseif (requestType == "STATE" or requestType == "STATES" or requestType == "SELF_STRATEGY_STATE") and state.stateRequests[token] then
          failBootstrapStateRequest(state, token)
          clearStateRequest(state, token)
        end
      end
    end

    return true
  end

  debugPrint("ADDON:RX", opcode, payload or "")
  return true
end

local function dispatchBootstrapRequests(generation)
  local state = ensureBridgeState()
  if generation ~= nil and state.connectionGeneration ~= generation then
    return false
  end

  Comm.SendHello()
  Comm.SendPing()
  Comm.RequestRoster()
  requestBootstrapStates()
  if Comm.RequestBotDetails then
    Comm.RequestBotDetails()
  end
  return true
end

function Comm.OnPlayerEnteringWorld()
  local state = ensureBridgeState()
  state.states = {}
  state.stateRequests = {}
  state.stateActive = {}
  state.stateLatestByBot = {}
  state.stateLatestOrderByBot = {}
  state.stateGlobalLatestToken = nil
  state.stateFramingCapable = false
  state.capabilitiesResolved = false
  state.bootstrapStatePending = false
  state.bootstrapStateRequested = false
  state.bootstrapStateToken = nil
  state.bootstrapStateAttempts = 0
  state.pendingStateRefreshAll = false
  state.pendingStateRefreshByBot = {}
  state.strategyMutationCapable = false
state.selfStrategyCapable = false
state.selfActionCapable = false
  state.outfitCapable = false
  state.inventoryCapable = false
  state.inventoryExactCapable = false
  state.inventoryItemMoveCapable = false
  state.inventoryItemTradeCapable = false
  state.inventoryItemEquipCapable = false
  state.inventoryItemUnequipCapable = false
  state.inventoryItemDestroyCapable = false
  state.inventoryItemUseCapable = false
  state.inventoryItemSellCapable = false
  state.inventoryBuybackCapable = false
  state.inventoryBulkSellCapable = false
  state.inventoryOpenCapable = false
  state.groupRollCapable = false
  state.enchantTradeCapable = false
  state.questAbandonCapable = false
  state.selfBotCapable = false
  state.strategyMutationCommands = {}
  state.details = {}
  state.stats = {}
  state.pvpStats = {}
  state.quests = {}
  state.questActive = {}
  state.gameObjects = {}
  state.gameObjectActive = {}
  state.formationCommands = {}
  state.formationQueryActive = nil
  state.talentSpecs = {}
  state.talentSpecActive = nil
  state.inventoryActive = nil
  state.inventoryExactActive = nil
  state.inventoryExactSnapshots = {}
  state.spellbookActive = nil
  state.botSkills = {}
  state.botSkillActive = nil
  state.botReputations = {}
  state.botReputationActive = nil
  state.botEmblems = {}
  state.botEmblemMoney = {}
  state.botEmblemActive = nil
  state.professionRecipes = {}
  state.professionRecipeActive = nil
  state.professionRecipeCrafts = {}
  state.outfitActive = nil
  state.outfitCommands = {}
  state.trainerActive = nil
  state.trainerCommands = {}
  state.trainerSpells = {}
  Comm.MarkDisconnected(nil)
  local generation = state.connectionGeneration
  state.trainerActive = nil
  state.trainerCommands = {}
  state.trainerSpells = {}
  state.bootstrapPending = true
  state.bootstrapDeadline = safeNow() + 4.0

  local function expireBootstrap()
    local bridge = ensureBridgeState()
    if bridge.connectionGeneration ~= generation then
      return
    end
    if not bridge.connected and bridge.bootstrapPending and bridge.bootstrapDeadline > 0 and safeNow() >= bridge.bootstrapDeadline then
      bridge.bootstrapPending = false
      bridge.bootstrapDeadline = 0
    end
  end

  if not MultiBot.TimerAfter then
    dispatchBootstrapRequests(generation)
    expireBootstrap()
    return
  end

  dispatchBootstrapRequests(generation)

  MultiBot.TimerAfter(1.0, function()
    dispatchBootstrapRequests(generation)
  end)

  MultiBot.TimerAfter(4.1, expireBootstrap)
end

ensureBridgeState()