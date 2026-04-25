-- TIMER --
-- M11 ownership: keep this OnUpdate local.
-- Reason: automation core hot path (invite/talent/stats/sort) depends on frame-level cadence.

local function perfCount(counterName, delta)
	local debugApi = MultiBot and MultiBot.Debug
	if type(debugApi) ~= "table" or type(debugApi.IncrementCounter) ~= "function" or type(debugApi.IsPerfEnabled) ~= "function" or not debugApi.IsPerfEnabled() then
		return
	end

	debugApi.IncrementCounter(counterName, delta)
end

local function perfDuration(counterName, elapsed)
	local debugApi = MultiBot and MultiBot.Debug
	if type(debugApi) ~= "table" or type(debugApi.AddDuration) ~= "function" or type(debugApi.IsPerfEnabled) ~= "function" or not debugApi.IsPerfEnabled() then
		return
	end

	debugApi.AddDuration(counterName, elapsed)
end

local function BridgeBootOwnsState()
	local bridge = MultiBot and MultiBot.bridge
	if type(bridge) ~= "table" then
		return false
	end

	if bridge.connected or bridge.bootstrapPending or bridge.rosterPending then
		return true
	end

	if type(bridge.statePending) == "table" and next(bridge.statePending) ~= nil then
		return true
	end

	return false
end

local function RequestBridgeSnapshotAfterGroupReconnect()
	if not (MultiBot and MultiBot.Comm and MultiBot.bridge and MultiBot.bridge.connected) then
		return
	end

	local function refresh()
		if not (MultiBot and MultiBot.Comm and MultiBot.bridge and MultiBot.bridge.connected) then
			return
		end

		if MultiBot.Comm.RequestRoster then
			MultiBot.Comm.RequestRoster()
		end
		if MultiBot.Comm.RequestStates then
			MultiBot.Comm.RequestStates()
		end
		if MultiBot.Comm.RequestBotDetails then
			MultiBot.Comm.RequestBotDetails()
		end
	end

	if MultiBot.TimerAfter then
		MultiBot.TimerAfter(2.0, refresh)
	else
		refresh()
	end
end

local function ReconnectExistingGroupBots(reason)
	if MultiBot._groupReconnectDone then
		return false
	end

	local now = (type(GetTime) == "function") and GetTime() or 0
	if MultiBot._lastGroupReconnectAt and (now - MultiBot._lastGroupReconnectAt) < 3.0 then
		return false
	end

	local playerName = UnitName("player")
	local sent = 0

	if GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers() do
			local raidName = UnitName("raid" .. i)
			if raidName and raidName ~= "" and raidName ~= playerName then
				SendChatMessage(".playerbot bot add " .. raidName, "SAY")
				sent = sent + 1
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i = 1, GetNumPartyMembers() do
			local partyName = UnitName("party" .. i)
			if partyName and partyName ~= "" and partyName ~= playerName then
				SendChatMessage(".playerbot bot add " .. partyName, "SAY")
				sent = sent + 1
			end
		end
	end

	if sent <= 0 then
		return false
	end

	MultiBot._groupReconnectDone = true
	MultiBot._lastGroupReconnectAt = now
	MultiBot.dprint("GROUP_RECONNECT", reason or "?", sent)
	RequestBridgeSnapshotAfterGroupReconnect()
	return true
end

local function LegacyChatFallbackEnabled()
	return MultiBot and MultiBot.allowLegacyChatFallback == true
end

function MultiBot.HandleOnUpdate(pElapsed)
	perfCount("handler.onupdate.calls")
	perfDuration("handler.onupdate.elapsed", tonumber(pElapsed) or 0)
	if(MultiBot.auto.invite) then MultiBot.timer.invite.elapsed = MultiBot.timer.invite.elapsed + pElapsed end
	if(MultiBot.auto.talent) then MultiBot.timer.talent.elapsed = MultiBot.timer.talent.elapsed + pElapsed end
	if(MultiBot.auto.stats) then MultiBot.timer.stats.elapsed = MultiBot.timer.stats.elapsed + pElapsed end
	if(MultiBot.auto.sort) then MultiBot.timer.sort.elapsed = MultiBot.timer.sort.elapsed + pElapsed end

	if(MultiBot.auto.stats and MultiBot.timer.stats.elapsed >= MultiBot.timer.stats.interval) then
		for i = 1, GetNumPartyMembers() do
			local botName = UnitName("party" .. i)
			if MultiBot.RequestStatsRefresh then
				MultiBot.RequestStatsRefresh(botName)
			end
		end
		MultiBot.timer.stats.elapsed = 0
	end

	if(MultiBot.auto.talent and MultiBot.timer.talent.elapsed >= MultiBot.timer.talent.interval) then
		MultiBot.talent.setTalents()
		MultiBot.timer.talent.elapsed = 0
		MultiBot.auto.talent = false
	end

	if(MultiBot.auto.invite and MultiBot.timer.invite.elapsed >= MultiBot.timer.invite.interval) then
		local tTable = MultiBot.index[MultiBot.timer.invite.roster]

		if(MultiBot.timer.invite.needs == 0 or MultiBot.timer.invite.index > #tTable) then
			if(MultiBot.timer.invite.roster == "raidus") then
				MultiBot.timer.sort.elapsed = 0
				MultiBot.timer.sort.index = 1
				MultiBot.timer.sort.needs = 0
				MultiBot.auto.sort = true
			end

			MultiBot.timer.invite.elapsed = 0
			MultiBot.timer.invite.roster = ""
			MultiBot.timer.invite.index = 1
			MultiBot.timer.invite.needs = 0
			MultiBot.auto.invite = false
			return
		end

		if(MultiBot.isMember(tTable[MultiBot.timer.invite.index]) == false) then
			SendChatMessage(MultiBot.doReplace(MultiBot.L("info.inviting"), "NAME", tTable[MultiBot.timer.invite.index]), "SAY")
			SendChatMessage(".playerbot bot add " .. tTable[MultiBot.timer.invite.index], "SAY")
			MultiBot.timer.invite.needs = MultiBot.timer.invite.needs - 1
		end

		MultiBot.timer.invite.index = MultiBot.timer.invite.index + 1
		MultiBot.timer.invite.elapsed = 0
	end

	if(MultiBot.auto.sort and MultiBot.timer.sort.elapsed >= MultiBot.timer.sort.interval) then
		MultiBot.timer.sort.index = MultiBot.raidus.doRaidSort(MultiBot.timer.sort.index)

		if(MultiBot.timer.sort.index == nil) then
			MultiBot.timer.sort.index = MultiBot.raidus.doRaidSortCheck()
		end

		if(MultiBot.timer.sort.index == nil) then
			SendChatMessage("Ready for Raid now.", "SAY")
			MultiBot.timer.sort.elapsed = 0
			MultiBot.timer.sort.index = 1
			MultiBot.timer.sort.needs = 0
			MultiBot.auto.sort = false
			return
		end

		MultiBot.timer.sort.elapsed = 0
	end
end

MultiBot:SetScript("OnUpdate", function(_, pElapsed)
	MultiBot.DispatchUpdate(pElapsed)
 end)

local MAINBAR_MIGRATION_VERSION = 1
local LAYOUT_MIGRATION_VERSION = 1
local MAINBAR_MIGRATION_KEY = "mainBarStateVersion"
local LAYOUT_MIGRATION_KEY = "layoutStateVersion"

local MAINBAR_STATE_KEYS = {
	"AttackButton",
	"FleeButton",
	"AutoRelease",
	"NecroNet",
	"Reward",
	"Masters",
	"Creator",
	"Beast",
	"Expand",
	"RTSC",
}

local LAYOUT_STATE_KEYS = {
	"MultiBarPoint",
	"InventoryPoint",
	"SpellbookPoint",
	"ItemusPoint",
	"IconosPoint",
	"StatsPoint",
	"RewardPoint",
	"TalentPoint",
	"MemoryGem1",
	"MemoryGem2",
	"MemoryGem3",
}

local function getLegacyStateStore(createIfMissing)
	local store = _G.MultiBotSave
	if type(store) ~= "table" then
		if not createIfMissing then
			return nil
		end

		store = {}
		_G.MultiBotSave = store
	end

	return store
end

local function getMainBarProfileStore()
	if not (MultiBot.Store and MultiBot.Store.EnsureMainBarStore) then
		return nil
	end
	return MultiBot.Store.EnsureMainBarStore()
end

local function migrateLegacyMainBarStateIfNeeded(profileStore)
	if not profileStore or not MultiBot.ShouldSyncLegacyState(MAINBAR_MIGRATION_KEY, MAINBAR_MIGRATION_VERSION) then
		return
	end

	local legacy = getLegacyStateStore(false)
	for _, key in ipairs(MAINBAR_STATE_KEYS) do
		if profileStore[key] == nil and legacy and legacy[key] ~= nil then
			profileStore[key] = legacy[key]
		end
	end

	MultiBot.MarkLegacyStateMigrated(MAINBAR_MIGRATION_KEY, MAINBAR_MIGRATION_VERSION)

	-- Purge migrated legacy main-bar keys to avoid stale duplicate persistence.
	if type(legacy) == "table" then
		for _, key in ipairs(MAINBAR_STATE_KEYS) do
			legacy[key] = nil
		end
	end
end

local function getSavedMainBarValue(key)
	local legacy = getLegacyStateStore(false)
	local profileStore = getMainBarProfileStore()
	if profileStore then
		migrateLegacyMainBarStateIfNeeded(profileStore)
	end

	local value = profileStore and profileStore[key] or (legacy and legacy[key])
	if profileStore and value == nil and MultiBot.ShouldSyncLegacyState(MAINBAR_MIGRATION_KEY, MAINBAR_MIGRATION_VERSION) then
		value = legacy and legacy[key]
		if value ~= nil then
			profileStore[key] = value
		end
	end
	return value
end

local function setSavedMainBarValue(key, value)
	local profileStore = getMainBarProfileStore()
	if profileStore then
		migrateLegacyMainBarStateIfNeeded(profileStore)
		profileStore[key] = value
	end

	if MultiBot.ShouldSyncLegacyState(MAINBAR_MIGRATION_KEY, MAINBAR_MIGRATION_VERSION) then
		local legacy = getLegacyStateStore(true)
		legacy[key] = value
	end
	return value
end

MultiBot.GetSavedMainBarValue = function(key)
	return getSavedMainBarValue(key)
end

MultiBot.SetSavedMainBarValue = function(key, value)
	return setSavedMainBarValue(key, value)
end

local function getLayoutProfileStore(createIfMissing)
	if not MultiBot.Store then
		return nil
	end

	if createIfMissing then
		if type(MultiBot.Store.EnsureUIChildStore) == "function" then
			return MultiBot.Store.EnsureUIChildStore("layout")
		end
		return nil
	end

	if type(MultiBot.Store.GetUIChildStore) == "function" then
		return MultiBot.Store.GetUIChildStore("layout")
	end

	return nil
end

local function migrateLegacyLayoutStateIfNeeded(profileStore)
	if not profileStore or not MultiBot.ShouldSyncLegacyState(LAYOUT_MIGRATION_KEY, LAYOUT_MIGRATION_VERSION) then
		return
	end

	local legacy = getLegacyStateStore(false)
	for _, key in ipairs(LAYOUT_STATE_KEYS) do
		if profileStore[key] == nil and legacy and legacy[key] ~= nil then
			profileStore[key] = legacy[key]
		end
	end

	MultiBot.MarkLegacyStateMigrated(LAYOUT_MIGRATION_KEY, LAYOUT_MIGRATION_VERSION)

	-- Purge migrated legacy layout keys to avoid stale duplicate persistence.
	if type(legacy) == "table" then
		for _, key in ipairs(LAYOUT_STATE_KEYS) do
			legacy[key] = nil
		end
	end
end

local function getSavedLayoutValue(key)
	local legacy = getLegacyStateStore(false)
	local profileStore = getLayoutProfileStore(false)
	if profileStore then
		migrateLegacyLayoutStateIfNeeded(profileStore)
	end

	local value = profileStore and profileStore[key] or (legacy and legacy[key])
	if value == nil and MultiBot.ShouldSyncLegacyState(LAYOUT_MIGRATION_KEY, LAYOUT_MIGRATION_VERSION) then
		value = legacy and legacy[key]
		if value ~= nil then
			if not profileStore then
				profileStore = getLayoutProfileStore(true)
				if profileStore then
					migrateLegacyLayoutStateIfNeeded(profileStore)
				end
			end
			if profileStore then
				profileStore[key] = value
			end
		end
	end
	return value
end

local function setSavedLayoutValue(key, value)
	local profileStore = getLayoutProfileStore(true)
	if profileStore then
		migrateLegacyLayoutStateIfNeeded(profileStore)
		profileStore[key] = value
	end

	if MultiBot.ShouldSyncLegacyState(LAYOUT_MIGRATION_KEY, LAYOUT_MIGRATION_VERSION) then
		local legacy = getLegacyStateStore(true)
		legacy[key] = value
	end
	return value
end

MultiBot.GetSavedLayoutValue = function(key)
	return getSavedLayoutValue(key)
end

MultiBot.SetSavedLayoutValue = function(key, value)
	return setSavedLayoutValue(key, value)
end

local LAYOUT_EXPORT_VERSION = "MBLAYOUT1"

local function getPlayerLayoutOwnerKey()
	local playerName = UnitName and UnitName("player") or nil
	local realmName = GetRealmName and GetRealmName() or nil
	if type(playerName) ~= "string" or playerName == "" then
		playerName = "UnknownPlayer"
	end
	if type(realmName) ~= "string" or realmName == "" then
		return playerName
	end
	return playerName .. "-" .. realmName
end

local function getGlobalLayoutLibrary(createIfMissing)
	local globalSave = _G.MultiBotGlobalSave
	if type(globalSave) ~= "table" then
		if not createIfMissing then
			return nil
		end
		globalSave = {}
		_G.MultiBotGlobalSave = globalSave
	end

	if createIfMissing then
		if MultiBot.Store and MultiBot.Store.EnsureTableField then
			MultiBot.Store.EnsureTableField(globalSave, "savedLayoutsByPlayer", {})
		elseif type(globalSave.savedLayoutsByPlayer) ~= "table" then
			globalSave.savedLayoutsByPlayer = {}
		end

		local db = MultiBot.db
		local legacyStore = db and db.global and db.global.ui and db.global.ui.savedLayoutsByPlayer or nil
		if type(legacyStore) == "table" then
			for ownerKey, payload in pairs(legacyStore) do
				if type(ownerKey) == "string" and type(payload) == "string" and payload ~= "" and globalSave.savedLayoutsByPlayer[ownerKey] == nil then
					globalSave.savedLayoutsByPlayer[ownerKey] = payload
				end
			end
		end
	end
	return globalSave.savedLayoutsByPlayer
end

local function encodePayloadValue(value)
	return (tostring(value):gsub(".", function(ch)
		return string.format("%02X", string.byte(ch))
	end))
end

local function decodePayloadValue(value)
	if type(value) ~= "string" or value == "" or (string.len(value) % 2) ~= 0 then
		return nil
	end

	local chunks = {}
	for i = 1, string.len(value), 2 do
		local byteHex = string.sub(value, i, i + 1)
		local byte = tonumber(byteHex, 16)
		if not byte then
			return nil
		end
		chunks[#chunks + 1] = string.char(byte)
	end
	return table.concat(chunks)
end

local function shouldExportLayoutKey(key)
	return type(key) == "string" and (key == "MultiBarPoint" or string.find(key, "^ButtonLayout:") ~= nil)
end

local function collectLayoutExportEntries()
	local entries = {}
	local profileStore = getLayoutProfileStore()
	if profileStore then
		migrateLegacyLayoutStateIfNeeded(profileStore)
		for key, value in pairs(profileStore) do
			if shouldExportLayoutKey(key) and type(value) == "string" and value ~= "" then
				entries[key] = value
			end
		end
	end

	local registered = MultiBot._mbRegisteredButtonLayoutKeys
	if type(registered) ~= "table" then
		registered = {}
	end
	for key in pairs(registered) do
		if shouldExportLayoutKey(key) and entries[key] == nil then
			local value = getSavedLayoutValue(key)
			if type(value) == "string" and value ~= "" then
				entries[key] = value
			end
		end
	end

	if entries["MultiBarPoint"] == nil then
		local pointValue = getSavedLayoutValue("MultiBarPoint")
		if type(pointValue) == "string" and pointValue ~= "" then
			entries["MultiBarPoint"] = pointValue
		end
	end

	return entries
end

local function sortedKeysOf(map)
	local keys = {}
	if type(map) ~= "table" then
		return keys
	end
	for key in pairs(map) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

function MultiBot.ExportMainBarLayoutPayload()
	local payloadParts = { LAYOUT_EXPORT_VERSION }
	local moveLocked = MultiBot.GetMainBarMoveLocked and MultiBot.GetMainBarMoveLocked() and "1" or "0"
	payloadParts[#payloadParts + 1] = "mainBarMoveLocked=" .. encodePayloadValue(moveLocked)

	local entries = collectLayoutExportEntries()
	for _, key in ipairs(sortedKeysOf(entries)) do
		payloadParts[#payloadParts + 1] = encodePayloadValue(key) .. "=" .. encodePayloadValue(entries[key])
	end

	return table.concat(payloadParts, "|")
end

function MultiBot.SaveMainBarLayoutForCurrentPlayer()
	local payload = MultiBot.ExportMainBarLayoutPayload()
	local ownerKey = getPlayerLayoutOwnerKey()
	local store = getGlobalLayoutLibrary(true)
	if not store then
		return false, "store_global_indisponible"
	end
	store[ownerKey] = payload
	return true, ownerKey, payload
end

function MultiBot.GetSavedMainBarLayoutOwners()
	local store = getGlobalLayoutLibrary(false)
	local owners = {}
	if type(store) ~= "table" then
		return owners
	end
	for ownerKey, payload in pairs(store) do
		if type(ownerKey) == "string" and type(payload) == "string" and payload ~= "" then
			owners[#owners + 1] = ownerKey
		end
	end
	table.sort(owners)
	return owners
end

function MultiBot.GetSavedMainBarLayoutPayload(ownerKey)
	if type(ownerKey) ~= "string" or ownerKey == "" then
		return nil
	end
	local store = getGlobalLayoutLibrary(false)
	local payload = store and store[ownerKey] or nil
	if type(payload) ~= "string" or payload == "" then
		return nil
	end
	return payload
end

function MultiBot.ImportSavedMainBarLayout(ownerKey)
	local payload = MultiBot.GetSavedMainBarLayoutPayload(ownerKey)
	if not payload then
		return false, "layout_introuvable"
	end
	return MultiBot.ImportMainBarLayoutPayload(payload)
end

function MultiBot.DeleteSavedMainBarLayout(ownerKey)
	if type(ownerKey) ~= "string" or ownerKey == "" then
		return false, "owner_invalide"
	end
	local store = getGlobalLayoutLibrary(true)
	if not store or store[ownerKey] == nil then
		return false, "layout_introuvable"
	end
	store[ownerKey] = nil
	return true
end

local function isMainBarLayoutKey(key)
	return type(key) == "string" and (key == "MultiBarPoint" or string.find(key, "^ButtonLayout:") ~= nil)
end

function MultiBot.ResetMainBarLayoutState()
	local removed = 0
	local profileStore = getLayoutProfileStore()
	if profileStore then
		migrateLegacyLayoutStateIfNeeded(profileStore)
		for key in pairs(profileStore) do
			if isMainBarLayoutKey(key) then
				profileStore[key] = nil
				removed = removed + 1
			end
		end
	end

	local legacy = getLegacyStateStore(false)
	if type(legacy) == "table" then
		for key in pairs(legacy) do
			if isMainBarLayoutKey(key) then
				legacy[key] = nil
			end
		end
	end

	if MultiBot._mbShiftSwapGlobal and MultiBot.ResetButtonLayoutContext then
		for contextKey in pairs(MultiBot._mbShiftSwapGlobal) do
			MultiBot.ResetButtonLayoutContext(contextKey, false)
		end
	end

	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	if multiBar and multiBar.setPoint then
		multiBar.setPoint(-262, 144)
	end
	if MultiBot.RefreshMainBarAutoHideState then
		MultiBot.RefreshMainBarAutoHideState()
	end

	return true, removed
end

local function applyImportedLayoutEntry(key, value)
	if key == "mainBarMoveLocked" then
		if MultiBot.SetMainBarMoveLocked then
			MultiBot.SetMainBarMoveLocked(value == "1")
		end
		return true
	end

	if not shouldExportLayoutKey(key) then
		return false
	end

	setSavedLayoutValue(key, value)
	if key == "MultiBarPoint" then
		local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
		if multibar and multibar.setPoint and MultiBot.doSplit then
			local split = MultiBot.doSplit(value, ", ")
			multibar.setPoint(tonumber(split[1]), tonumber(split[2]))
		end
		if MultiBot.RefreshMainBarAutoHideState then
			MultiBot.RefreshMainBarAutoHideState()
		end
		return true
	end

	local context = string.match(key, "^ButtonLayout:(.+)$")
	if context and MultiBot.ApplySavedButtonLayout then
		MultiBot.ApplySavedButtonLayout(context)
	end
	return true
end

function MultiBot.ImportMainBarLayoutPayload(payload)
	if type(payload) ~= "string" or payload == "" then
		return false, "payload_vide"
	end

	local tokens = {}
	for token in string.gmatch(payload, "([^|]+)") do
		tokens[#tokens + 1] = token
	end
	if tokens[1] ~= LAYOUT_EXPORT_VERSION then
		return false, "version_invalide"
	end

	local imported = 0
	for index = 2, #tokens do
		local token = tokens[index]
		local left, right = string.match(token, "^([^=]+)=(.+)$")
		if left and right then
			local key = left
			if key ~= "mainBarMoveLocked" then
				key = decodePayloadValue(left)
			end
			local value = decodePayloadValue(right)
			if key and value and applyImportedLayoutEntry(key, value) then
				imported = imported + 1
			end
		end
	end

	if imported == 0 then
		return false, "aucune_donnee_importee"
	end
	return true, imported
end

-- HANDLER --


local POINT_FRAME_BINDINGS = {
	{ saveKey = "MultiBarPoint", getFrame = function() return MultiBot.frames and MultiBot.frames["MultiBar"] end },
	{ saveKey = "InventoryPoint", getFrame = function() return MultiBot.inventory end },
	{ saveKey = "SpellbookPoint", getFrame = function() return MultiBot.spellbook end },
	{ saveKey = "ItemusPoint", getFrame = function() return MultiBot.itemus end },
	{ saveKey = "IconosPoint", getFrame = function() return MultiBot.iconos or (MultiBot.iconos and MultiBot.iconos.frame) end },
	{ saveKey = "StatsPoint", getFrame = function() return MultiBot.stats end },
	{ saveKey = "RewardPoint", getFrame = function() return MultiBot.reward end },
	{ saveKey = "TalentPoint", getFrame = function() return MultiBot.talent end },
}

local PORTAL_MEMORY_BINDINGS = {
	{ saveKey = "MemoryGem1", color = "Red" },
	{ saveKey = "MemoryGem2", color = "Green" },
	{ saveKey = "MemoryGem3", color = "Blue" },
}

local function getPortalButton(color)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local masters = multiBar and multiBar.frames and multiBar.frames["Masters"]
	local portal = masters and masters.frames and masters.frames["Portal"]
	return portal and portal.buttons and portal.buttons[color]
end

local function saveBoundFramePoints()
	local function canReadPoint(frame)
		if not frame then
			return false
		end

		local getRight = frame.GetRight or frame.getRight
		local getBottom = frame.GetBottom or frame.getBottom
		if type(getRight) ~= "function" or type(getBottom) ~= "function" then
			return false
		end

		return getRight(frame) ~= nil and getBottom(frame) ~= nil
	end

	for _, binding in ipairs(POINT_FRAME_BINDINGS) do
		local frame = binding.getFrame and binding.getFrame()
		if frame and canReadPoint(frame) then
			local tX, tY = MultiBot.toPoint(frame)
			setSavedLayoutValue(binding.saveKey, tX .. ", " .. tY)
		end
	end
end

local function restoreBoundFramePoints()
	for _, binding in ipairs(POINT_FRAME_BINDINGS) do
		local pointValue = getSavedLayoutValue(binding.saveKey)
		local frame = binding.getFrame and binding.getFrame()
		if pointValue ~= nil and frame and frame.setPoint then
			local pointX, pointY = string.match(tostring(pointValue), "^%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
			pointX = tonumber(pointX)
			pointY = tonumber(pointY)
			if pointX and pointY then
				frame.setPoint(pointX, pointY)
			end
		end
	end
end

local function savePortalMemory()
	for _, binding in ipairs(PORTAL_MEMORY_BINDINGS) do
		local portalButton = getPortalButton(binding.color)
		if portalButton then
			setSavedLayoutValue(binding.saveKey, MultiBot.SavePortal(portalButton))
		end
	end
end

local function restorePortalMemory()
	for _, binding in ipairs(PORTAL_MEMORY_BINDINGS) do
		local memory = getSavedLayoutValue(binding.saveKey)
		if memory ~= nil then
			local portalButton = getPortalButton(binding.color)
			if portalButton then
				MultiBot.LoadPortal(portalButton, memory)
			end
		end
	end
end

local ATTACK_BUTTON_BINDINGS = {
	attack = "Attack",
	attack_ranged = "Ranged",
	attack_melee = "Melee",
	attack_healer = "Healer",
	attack_dps = "Dps",
	attack_tank = "Tank",
}

local FLEE_BUTTON_BINDINGS = {
	flee = "Flee",
	flee_ranged = "Ranged",
	flee_melee = "Melee",
	flee_healer = "Healer",
	flee_dps = "Dps",
	flee_tank = "Tank",
	flee_target = "Target",
}

local function getMultiBarButton(sectionName, frameName, buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local section = multiBar and multiBar.frames and multiBar.frames[sectionName]
	local frame = section and section.frames and section.frames[frameName]
	return frame and frame.buttons and frame.buttons[buttonName]
end

local function getMainBarButton(buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local main = multiBar and multiBar.frames and multiBar.frames["Main"]
	return main and main.buttons and main.buttons[buttonName]
end

local function getMastersBarButton(buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local masters = multiBar and multiBar.frames and multiBar.frames["Masters"]
	return masters and masters.buttons and masters.buttons[buttonName]
end

local function restoreRightClickMode(saveKey, frameName, buttonBindings)
	local savedMode = getSavedMainBarValue(saveKey)
	if savedMode == nil then return end

	local buttonName = buttonBindings[savedMode]
	if not buttonName then return end

	local button = getMultiBarButton("Left", frameName, buttonName)
	if button and button.doRight then
		button.doRight(button)
	end
end

local function restoreBinaryLeftToggle(saveKey, getButton)
	local savedState = getSavedMainBarValue(saveKey)
	if savedState == nil then return end

	local button = getButton()
	if not button then return end

	if savedState == "true" then
		if button.setDisable then button.setDisable() end
	else
		if button.setEnable then button.setEnable() end
	end

	if button.doLeft then
		button.doLeft(button)
	end
end

local function restoreEnableOnlyLeftToggle(saveKey, getButton, onEnabled)
	if getSavedMainBarValue(saveKey) ~= "true" then return end

	local button = getButton()
	if not button then return end

	if onEnabled then
		onEnabled(button)
	end

	if button.setDisable then
		button.setDisable()
	end

	if button.doLeft then
		button.doLeft(button)
	end
end

local function restoreMainBarSavedStates()
	restoreRightClickMode("AttackButton", "Attack", ATTACK_BUTTON_BINDINGS)
	restoreRightClickMode("FleeButton", "Flee", FLEE_BUTTON_BINDINGS)

	restoreBinaryLeftToggle("AutoRelease", function()
		return getMainBarButton("Release")
	end)
	restoreBinaryLeftToggle("NecroNet", function()
		return getMastersBarButton("NecroNet")
	end)
	restoreBinaryLeftToggle("Reward", function()
		return getMainBarButton("Reward")
	end)

	restoreEnableOnlyLeftToggle("Masters", function()
		return getMainBarButton("Masters")
	end, function()
		MultiBot.GM = true
	end)
	restoreEnableOnlyLeftToggle("Creator", function()
		return getMainBarButton("Creator")
	end)
	restoreEnableOnlyLeftToggle("Beast", function()
		return getMainBarButton("Beast")
	end)
	restoreEnableOnlyLeftToggle("Expand", function()
		return getMainBarButton("Expand")
	end)
	restoreEnableOnlyLeftToggle("RTSC", function()
		return getMainBarButton("RTSC")
	end, function()
		if MultiBot.frames and MultiBot.frames["MultiBar"] then
			MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y - 34)
		end
	end)
end

local function hideButtonUnitFrame(button)
	if not button or not button.parent or not button.parent.frames then return end
	local unitFrame = button.parent.frames[button.name]
	if unitFrame ~= nil then
		unitFrame:Hide()
	end
end

local function bindUnitToggleHandlers(button, options)
	if not button then return end

local requireEnabledStateOnRight = options and options.requireEnabledStateOnRight

	button.doRight = function(pButton)
		if requireEnabledStateOnRight and pButton.state == false then
			return
		end

		SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
		hideButtonUnitFrame(pButton)
		pButton.setDisable()
	end

	button.doLeft = function(pButton)
		if pButton.state then
			if pButton.parent and pButton.parent.frames and pButton.parent.frames[pButton.name] ~= nil then
				MultiBot.ShowHideSwitch(pButton.parent.frames[pButton.name])
			end
		else
			SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
			pButton.setEnable()
		end
	end
end

local function ensureQuestStateTables()
	local ensureRuntime = MultiBot.Store and MultiBot.Store.EnsureRuntimeTable
	if type(ensureRuntime) ~= "function" then
		return
	end
	ensureRuntime("BotQuestsIncompleted")
	ensureRuntime("BotQuestsCompleted")
	ensureRuntime("BotQuestsAll")
	ensureRuntime("_awaitingQuestsIncompleted")
	ensureRuntime("_awaitingQuestsCompleted")
	ensureRuntime("LastGameObjectSearch")
	ensureRuntime("_GameObjCaptureInProgress")
	ensureRuntime("_GameObjCurrentSection")
	ensureRuntime("_questAllBuffer")
end

local function FillQuestTable(tbl, author, msg)
	local bucket = MultiBot.Store.EnsureRuntimeTable(tbl)
	MultiBot.Store.EnsureTableField(bucket, author, {})
	for link in msg:gmatch("|Hquest:[^|]+|h%[[^%]]+%]|h") do
		local id = tonumber(link:match("|Hquest:(%d+):"))
		local name = link:match("%[([^%]]+)%]")
		if id and name then
			bucket[author][id] = name
		end
	end
end
local QUEST_LINE_MARKERS = {
	incompleted = "Incompleted quests",
	completed = "Completed quests",
	summary = "Summary",
	questToken = "quest",
	questLink = "|Hquest:",
}

local function containsAnyToken(rawMsg, tokens)
	if type(rawMsg) ~= "string" then
		return false
	end

	for _, token in ipairs(tokens) do
		if rawMsg:find(token, 1, true) then
			return true
		end
	end

	return false
end


local function showPopupIfHidden(popup)
	if popup and not popup:IsShown() then
		popup:Show()
	end
end

local function runQuestListBuild(modeValue, groupedMode, groupedBuilder, singleBuilder, author)
	if modeValue == groupedMode then
		if type(groupedBuilder) == "function" then
			groupedBuilder()
		end
	elseif type(singleBuilder) == "function" then
		singleBuilder(author)
	end
end

local function scheduleQuestListBuild(delay, modeValue, groupedMode, groupedBuilder, singleBuilder, author)
	MultiBot.TimerAfter(delay, function()
		runQuestListBuild(modeValue, groupedMode, groupedBuilder, singleBuilder, author)
	end)
end

local function finalizeQuestSection(author, awaitingTable, popup, modeValue, groupedMode, groupedBuilder, singleBuilder, singleAuthor)
	awaitingTable[author] = nil
	showPopupIfHidden(popup)
	scheduleQuestListBuild(0.1, modeValue, groupedMode, groupedBuilder, singleBuilder, singleAuthor or author)
end

local function refreshQuestSectionProgress(author, modeValue, groupedMode, groupedBuilder, singleBuilder, singleAuthor)
	if modeValue == groupedMode then
		return
	end
	scheduleQuestListBuild(0.05, modeValue, groupedMode, groupedBuilder, singleBuilder, singleAuthor or author)
end

local function HandleQuestResponse(rawMsg, author)
	if MultiBot._awaitingQuestsAll or MultiBot._blockOtherQuests then
		if MultiBot.dprint then
			MultiBot.dprint("QUEST", "SKIP HandleQuestResponse (awaitingQuestsAll)")
		end
		return
	end

	local hasKeyword = containsAnyToken(rawMsg, { QUEST_LINE_MARKERS.questToken, QUEST_LINE_MARKERS.summary })
	local awaiting = MultiBot._awaitingQuestsIncompleted[author] or MultiBot._awaitingQuestsCompleted[author]
	if not hasKeyword and not awaiting then
		return
	end

	if rawMsg:find(QUEST_LINE_MARKERS.incompleted, 1, true) then
		MultiBot.Store.EnsureRuntimeTable("BotQuestsIncompleted")[author] = {}
		MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsIncompleted")[author] = true
		return
	end

	if MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsIncompleted")[author] then
		FillQuestTable("BotQuestsIncompleted", author, rawMsg)
		local incRenderAuthor = author
		if MultiBot._lastIncMode == "WHISPER" and type(MultiBot._lastIncWhisperBot) == "string" and MultiBot._lastIncWhisperBot ~= "" then
			incRenderAuthor = MultiBot._lastIncWhisperBot
		end
		if rawMsg:find(QUEST_LINE_MARKERS.summary, 1, true) then
			finalizeQuestSection(
				author,
				MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsIncompleted"),
				MultiBot.tBotPopup,
				MultiBot._lastIncMode,
				"GROUP",
				MultiBot.BuildAggregatedQuestList,
				MultiBot.BuildBotQuestList,
				incRenderAuthor
			)
		else
			refreshQuestSectionProgress(
				author,
				MultiBot._lastIncMode,
				"GROUP",
				MultiBot.BuildAggregatedQuestList,
				MultiBot.BuildBotQuestList,
				incRenderAuthor
			)
		end
		return
	end

	if rawMsg:find(QUEST_LINE_MARKERS.completed, 1, true) then
		MultiBot.Store.EnsureRuntimeTable("BotQuestsCompleted")[author] = {}
		MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsCompleted")[author] = true
		return
	end

	if MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsCompleted")[author] then
		FillQuestTable("BotQuestsCompleted", author, rawMsg)
		local compRenderAuthor = author
		if MultiBot._lastCompMode == "WHISPER" and type(MultiBot._lastCompWhisperBot) == "string" and MultiBot._lastCompWhisperBot ~= "" then
			compRenderAuthor = MultiBot._lastCompWhisperBot
		end
		if rawMsg:find(QUEST_LINE_MARKERS.summary, 1, true) then
			finalizeQuestSection(
				author,
				MultiBot.Store.EnsureRuntimeTable("_awaitingQuestsCompleted"),
				MultiBot.tBotCompPopup,
				MultiBot._lastCompMode,
				"GROUP",
				MultiBot.BuildAggregatedCompletedList,
				MultiBot.BuildBotCompletedList,
				compRenderAuthor
			)
		else
			refreshQuestSectionProgress(
				author,
				MultiBot._lastCompMode,
				"GROUP",
				MultiBot.BuildAggregatedCompletedList,
				MultiBot.BuildBotCompletedList,
				compRenderAuthor
			)
		end
		return
	end
end

local function isQuestLikeWhisper(rawMsg)
	if type(rawMsg) ~= "string" then
		return false
	end

	return containsAnyToken(rawMsg, {
		QUEST_LINE_MARKERS.questToken,
		QUEST_LINE_MARKERS.summary,
		QUEST_LINE_MARKERS.questLink,
		QUEST_LINE_MARKERS.incompleted,
		QUEST_LINE_MARKERS.completed,
	})
end

local function shouldHandleQuestsAllWhisper(rawMsg, author)
	if not MultiBot._awaitingQuestsAll then
		return false
	end

	if MultiBot._awaitingQuestsAllBots and MultiBot._awaitingQuestsAllBots[author] ~= nil then
		return true
	end

	return isQuestLikeWhisper(rawMsg)
end

-- Compatibility alias: keep callable even if local scope changes during merges.
MultiBot.ShouldHandleQuestsAllWhisper = shouldHandleQuestsAllWhisper
_G.shouldHandleQuestsAllWhisper = shouldHandleQuestsAllWhisper

local function fillQuestsAllTablesFromBuffer(author)
	local questAllBuffer = MultiBot.Store.EnsureRuntimeTable("_questAllBuffer")
	local linesBuffer = questAllBuffer[author]
	if type(linesBuffer) ~= "table" then
		linesBuffer = {}
	end
	local allStore = MultiBot.Store.EnsureRuntimeTable("BotQuestsAll")
	local completedStore = MultiBot.Store.EnsureRuntimeTable("BotQuestsCompleted")
	local incompletedStore = MultiBot.Store.EnsureRuntimeTable("BotQuestsIncompleted")

	allStore[author] = {}
	completedStore[author] = {}
	incompletedStore[author] = {}

	local mode = nil
	for _, line in ipairs(linesBuffer) do
		if line:find(QUEST_LINE_MARKERS.incompleted, 1, true) then
			mode = "incomplete"
		elseif line:find(QUEST_LINE_MARKERS.completed, 1, true) then
			mode = "complete"
		elseif line:find(QUEST_LINE_MARKERS.summary, 1, true) then
			mode = nil
		else
			local id = tonumber(line:match("|Hquest:(%d+):"))
			local name = line:match("%[([^%]]+)%]")
			if id and name then
				table.insert(allStore[author], line)
				if mode == "incomplete" then
					incompletedStore[author][id] = name
				elseif mode == "complete" then
					completedStore[author][id] = name
				end
			end
		end
	end
end

local function areAllQuestsAllBotsCompleted()
	local awaiting = (MultiBot.Store and MultiBot.Store.GetRuntimeTable and MultiBot.Store.GetRuntimeTable("_awaitingQuestsAllBots")) or MultiBot._awaitingQuestsAllBots
	if type(awaiting) ~= "table" then
		return true
	end
	for _, ok in pairs(awaiting) do
		if not ok then
			return false
		end
	end

	return true
end

function HandleQuestsAllResponse(rawMsg, author)
	local questAllBuffer = MultiBot.Store.EnsureRuntimeTable("_questAllBuffer")
	MultiBot.Store.EnsureTableField(questAllBuffer, author, {})
	table.insert(questAllBuffer[author], rawMsg)

	if not rawMsg:find(QUEST_LINE_MARKERS.summary, 1, true) then
		return
	end

	fillQuestsAllTablesFromBuffer(author)

	if MultiBot._awaitingQuestsAllBots then
		MultiBot._awaitingQuestsAllBots[author] = true
	end

	questAllBuffer[author] = nil

	if areAllQuestsAllBotsCompleted() then
		MultiBot._awaitingQuestsAll = false
		MultiBot._blockOtherQuests = false
		MultiBot._awaitingQuestsAllBots = nil
		if MultiBot.tBotAllPopup and MultiBot.BuildAggregatedAllList then
			MultiBot.tBotAllPopup:Show()
			MultiBot.BuildAggregatedAllList()
		end
	else
		if MultiBot.dprint then
			MultiBot.dprint("QUEST", "Quests all aggregation still running")
		end
	end
end

local GAMEOBJECT_SECTION_MARKERS = {
	relevant = { "targets", "npcs", "corpses", "game objects" },
	terminal = { "triggers" },
}

local function normalizeGameObjectSectionLabel(label)
	if type(label) ~= "string" then
		return ""
	end

	return string.lower((label:gsub("^%s+", ""):gsub("%s+$", "")))
end

local function clearGameObjectCaptureState(author, shouldShowPopup)
	MultiBot._GameObjCaptureInProgress[author] = nil
	MultiBot._GameObjCurrentSection[author] = nil

	if shouldShowPopup and MultiBot.ShowGameObjectPopup then
		MultiBot.ShowGameObjectPopup()
	end
end

local function extractGameObjectSectionLabel(rawMsg)
	if type(rawMsg) ~= "string" then
		return nil
	end

	return rawMsg:match("^%s*%-+%s*(.-)%s*%-+%s*$")
end

local function isRelevantGameObjectSection(label)
	local normalized = normalizeGameObjectSectionLabel(label)
	return containsAnyToken(normalized, GAMEOBJECT_SECTION_MARKERS.relevant)
end

local function isTerminalGameObjectSection(label)
	local normalized = normalizeGameObjectSectionLabel(label)
	return containsAnyToken(normalized, GAMEOBJECT_SECTION_MARKERS.terminal)
end

function MultiBot.HandleGameObjectWhisper(rawMsg, author)
	if type(rawMsg) ~= "string" or author == nil then
		return false
	end

	local sectionLabel = extractGameObjectSectionLabel(rawMsg)
	local isSectionHeader = sectionLabel ~= nil

	if isSectionHeader and isTerminalGameObjectSection(sectionLabel) then
		if MultiBot._GameObjCaptureInProgress[author] then
			clearGameObjectCaptureState(author, true)
			return true
		end
		return false
	end

	if isSectionHeader then
		if isRelevantGameObjectSection(sectionLabel) then
			if not MultiBot._GameObjCaptureInProgress[author] then
				MultiBot.LastGameObjectSearch[author] = {}
				MultiBot._GameObjCaptureInProgress[author] = true
			end

			MultiBot._GameObjCurrentSection[author] = sectionLabel
			table.insert(MultiBot.LastGameObjectSearch[author], rawMsg)
			return true
		end

		if MultiBot._GameObjCaptureInProgress[author] then
			MultiBot._GameObjCurrentSection[author] = nil
			return true
		end

		return false
	end

	if not MultiBot._GameObjCaptureInProgress[author] then
		return false
	end

	if MultiBot._GameObjCurrentSection[author] and rawMsg ~= "" then
		table.insert(MultiBot.LastGameObjectSearch[author], rawMsg)
	end

	if rawMsg == "" then
		clearGameObjectCaptureState(author, true)
	end

	return true
end

function MultiBot.HandleMultiBotEvent(event, ...)
	local arg1, arg2, arg3, arg4 = ...
	perfCount("events.total")
	if type(event) == "string" then
		perfCount("events." .. string.lower(event))
	end
	if(event == "PLAYER_LOGOUT") then
		saveBoundFramePoints()
		savePortalMemory()

		local tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Attack"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		setSavedMainBarValue("AttackButton", tValue)

		tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Flee"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		setSavedMainBarValue("FleeButton", tValue)

		setSavedMainBarValue("AutoRelease", MultiBot.IF(MultiBot.auto.release, "true", "false"))
		setSavedMainBarValue("NecroNet", MultiBot.IF(MultiBot.necronet.state, "true", "false"))
		setSavedMainBarValue("Reward", MultiBot.IF(MultiBot.reward.state, "true", "false"))

		setSavedMainBarValue("Masters", MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Masters"].state, "true", "false"))
		setSavedMainBarValue("Creator", MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Creator"].state, "true", "false"))
		setSavedMainBarValue("Beast", MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Beast"].state, "true", "false"))
		setSavedMainBarValue("Expand", MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Expand"].state, "true", "false"))
		setSavedMainBarValue("RTSC", MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["RTSC"].state, "true", "false"))

		return
	end

	-- ADDON:LOADED --

    if(event == "ADDON_LOADED" and arg1 == "MultiBot") then
	        -- Core startup helpers are now routed via lifecycle (OnInitialize/OnEnable).
	        -- [EXISTANT] restauration des positions / états
		restoreBoundFramePoints()

	        -- Restore MultiBot bar visibility from saved state (default visible).
	        if MultiBot.ToggleMainUIVisibility then
	          local savedVisible = (MultiBot.GetMainUIVisibleConfig and MultiBot.GetMainUIVisibleConfig())
	          MultiBot.ToggleMainUIVisibility(savedVisible ~= false)
	        end

		restorePortalMemory()

		restoreMainBarSavedStates()

        local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel() or nil
        if strataLevel ~= nil then
          if MultiBot.ApplyGlobalStrata then
            MultiBot.ApplyGlobalStrata()
          else
            -- minimal fallback if the function does not exist
            if MultiBot.frames and MultiBot.frames["MultiBar"] then
              MultiBot.PromoteFrame(MultiBot.frames["MultiBar"], strataLevel)
            end
          end
        end

		return
	end

	-- QUICK BARS: roster/pet refresh now routed through central dispatcher.
	if (event == "PLAYER_ENTERING_WORLD"
		or event == "GROUP_ROSTER_UPDATE"
		or event == "PARTY_MEMBERS_CHANGED"
		or event == "RAID_ROSTER_UPDATE"
		or event == "UNIT_PET") then
		local hunterQuick = MultiBot and MultiBot.HunterQuick
		if hunterQuick then
			if event ~= "UNIT_PET" and hunterQuick.Rebuild then
				hunterQuick:Rebuild()
			end
			if hunterQuick.UpdateAllPetPresence then
				hunterQuick:UpdateAllPetPresence()
			end
		end

		if event ~= "UNIT_PET" then
			local shamanQuick = MultiBot and MultiBot.ShamanQuick
			if shamanQuick and shamanQuick.RefreshFromGroup then
				shamanQuick:RefreshFromGroup()
			end
		end

		if event ~= "PLAYER_ENTERING_WORLD" then
			if event ~= "UNIT_PET" then
				if MultiBot.TimerAfter then
					MultiBot.TimerAfter(0.8, function()
						ReconnectExistingGroupBots(event)
					end)
				else
					ReconnectExistingGroupBots(event)
				end
			end

			return
		end
	end

	-- PLAYER:ENTERING --

	if(event == "PLAYER_ENTERING_WORLD") then
        MultiBot.dprint("EVT", "PLAYER_ENTERING_WORLD") -- DEBUG

        if MultiBot.Comm and MultiBot.Comm.OnPlayerEnteringWorld then
            MultiBot.Comm.OnPlayerEnteringWorld()
        end

        if MultiBot.TimerAfter then
            MultiBot.TimerAfter(1.5, function()
                ReconnectExistingGroupBots("entering-world")
            end)
        else
            ReconnectExistingGroupBots("entering-world")
        end

        SendChatMessage(".account", "SAY")

        if(MultiBot.init == nil) then
            MultiBot.init = true
            MultiBot.TimerAfter(6.0, function()
                local bridge = MultiBot.bridge
                local playersSize = 0

                if MultiBot and MultiBot.index and MultiBot.index.players then
                    playersSize = #MultiBot.index.players
                end

                local bridgeRosterSize = 0
                if bridge and bridge.roster then
                    bridgeRosterSize = #bridge.roster
                end

                if playersSize > 1 then
                    ReconnectExistingGroupBots("players-index")
                    return
                end

                if bridge and bridge.connected and bridgeRosterSize > 0 then
                    ReconnectExistingGroupBots("bridge-roster")
                    return
                end

                if not LegacyChatFallbackEnabled() then
                    return
                end

                SendChatMessage(".playerbot bot list", "SAY")
            end)
        end

        return
    end

	if (event == "CHAT_MSG_ADDON") then
		if MultiBot.Comm and MultiBot.Comm.HandleAddonMessage and MultiBot.Comm.HandleAddonMessage(arg1, arg2, arg3, arg4) then
			return
		end
	end


	-- CHAT:SYSTEM --
	if(event == "CHAT_MSG_SYSTEM") then
	MultiBot.dprint("SYS", arg1) -- DEBUG

		-- Détection générique du niveau de compte (toutes langues prises en charge via patrons)
        do
          local msg = arg1
          if MultiBot.GM_DetectFromSystem and type(msg) == "string" then
            MultiBot.GM_DetectFromSystem(msg)
          end
        end

		if(MultiBot.isInside(arg1, "Possible strategies")) then
			local tStrategies = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== STRATEGIES ===", "SAY")
			for i = 1, #tStrategies do SendChatMessage(i .. " : " .. tStrategies[i], "SAY") end
			return
		end

		if(MultiBot.isInside(arg1, "Whisper any of")) then
			local tCommands = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== WHISPER-COMMANDS ===", "SAY")
			for i = 1, #tCommands do SendChatMessage(i .. " : " .. tCommands[i], "SAY") end
			return
		end

		if(MultiBot.auto.release == true) then
			if(MultiBot.isInside(arg1, "已经死亡")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doReplace(arg1, "已经死亡。", ""))
				return
			end

			if(MultiBot.isInside(arg1, "ist tot", "has dies", "has died")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doSplit(arg1, " ")[1])
				return
			end
		end

        -- Anti-dup: ignore the same "Bot roster:" line repeated in a short window
        do
          local text = (type(arg1) == "string") and arg1 or ""
          local roster = text:match("^%s*[Bb]ot%W+[Rr]oster:%s*(.+)$")
          if roster then
            MultiBot._lastRosterMsg = MultiBot._lastRosterMsg or { txt = nil, t = 0 }
            local now = (type(GetTime) == "function") and GetTime() or 0
            if MultiBot._lastRosterMsg.txt == roster and (now - MultiBot._lastRosterMsg.t) < 1.0 then
              return
            end
            MultiBot._lastRosterMsg.txt = roster
            MultiBot._lastRosterMsg.t   = now
          end
        end

		if(string.sub(arg1, 1, 12) == "Bot roster: ") then
			MultiBot.dprint("SYS", "Bot roster received") -- DEBUG
			MultiBot.dprint("UIready",
              (MultiBot.frames and MultiBot.frames["MultiBar"] and MultiBot.frames["MultiBar"].frames and MultiBot.frames["MultiBar"].frames["Units"]) and true or false) -- DEBUG
            -- ------------------------------------------------------------
            -- SECURITY : wait to MultiBar construction
            -- ------------------------------------------------------------
            if not (MultiBot.frames and MultiBot.frames["MultiBar"]
                    and MultiBot.frames["MultiBar"].frames
                    and MultiBot.frames["MultiBar"].frames["Units"]) then
                -- UI pas encore prête : on re-propulse le même event vers NOTRE OnEvent
                local saved_msg = arg1

                local function ReDispatchRoster()
                    local onEvent = MultiBot:GetScript("OnEvent")
                    if onEvent then
                        -- Sauvegarde/restaure les globals d’événement
                        local _event, _arg1 = event, arg1
                        event, arg1 = "CHAT_MSG_SYSTEM", saved_msg
                        onEvent()
                        event, arg1 = _event, _arg1
                    end
                end

                MultiBot.TimerAfter(0.2, ReDispatchRoster)
                return
            end

			local _, tClass, _, _, _, tName = GetPlayerInfoByGUID(UnitGUID("player"))
			tClass = MultiBot.toClass(tClass)

			local tPlayer = MultiBot.addSelf(tClass, tName).setDisable()
			tPlayer.class = tClass
			tPlayer.name = tName

			tPlayer.doLeft = function(pButton)
				SendChatMessage(".playerbot bot self", "SAY")
				MultiBot.OnOffSwitch(pButton)
			end

			-- PLAYERBOTS --

			-- On reste sur le format historique : "Bot roster: +Name Class, -Name Class, ..."
			local tTable = MultiBot.doSplit(string.sub(arg1, 13), ", ")
			MultiBot.dprint("ROSTER_PARSE_COUNT", #tTable) -- DEBUG

			for key, value in pairs(tTable) do
				if value == "" then break end

				local tBot = MultiBot.doSplit(value, " ")
				local rawNameToken  = tBot[1]
				local rawClassToken = tBot[2]

				if rawNameToken and rawClassToken then
					local botName  = string.sub(rawNameToken, 2) -- enlève le signe +/-
					local botClass = MultiBot.toClass(rawClassToken)

					-- Filtre de sécurité :
					--  - pas de nom vide
					--  - pas de classe inconnue => on évite les boutons Unknown
					if botName ~= "" and botClass and botClass ~= "Unknown" then
						local botButton = MultiBot.addPlayer(botClass, botName).setDisable()
						bindUnitToggleHandlers(botButton, { requireEnabledStateOnRight = true })
					else
						MultiBot.dprint("ROSTER_SKIP_BAD_ENTRY",
							tostring(value),
							"name=", botName or "<nil>",
							"class=", rawClassToken or "<nil>",
							"canon=", botClass or "<nil>")
					end
				else
					MultiBot.dprint("ROSTER_SKIP_MALFORMED", tostring(value))
				end
			end

			MultiBot.dprint("INDEX_PLAYERS_SIZE", #(MultiBot.index.players or {})) -- DEBUG
			do local n=0; for _ in pairs(MultiBot.index.classes.players or {}) do n=n+1 end; MultiBot.dprint("INDEX_CLASSES_PLAYERS_KEYS", n) end -- DEBUG

        -- La liste des players est prête : on met l’index Favoris à jour
        if MultiBot.UpdateFavoritesIndex then MultiBot.UpdateFavoritesIndex() end

        -- UI REFRESH (INCONDITIONNEL) :
        -- Rafraîchit la vue en réutilisant le roster courant (players/favorites/actives/…)
        -- pour ne pas écraser le choix de l’utilisateur.
        do
          local unitsBtn = MultiBot.frames
                          and MultiBot.frames["MultiBar"]
                          and MultiBot.frames["MultiBar"].buttons
                          and MultiBot.frames["MultiBar"].buttons["Units"]
          if unitsBtn and unitsBtn.doLeft then
            local roster = unitsBtn.roster or "players"
            unitsBtn.doLeft(unitsBtn, roster, unitsBtn.filter)
          end
        end
        -- Retry différé : couvre le cas où l’UI n’est pas encore prête (timing au login)
        MultiBot.TimerAfter(0.05, function()
          local unitsBtn = MultiBot.frames
                          and MultiBot.frames["MultiBar"]
                          and MultiBot.frames["MultiBar"].buttons
                          and MultiBot.frames["MultiBar"].buttons["Units"]
          if unitsBtn and unitsBtn.doLeft then
            local roster = unitsBtn.roster or "players"
            unitsBtn.doLeft(unitsBtn, roster, unitsBtn.filter)
          end
        end)

			-- MEMBERBOTS --
			local tGuildCount = 0
			if type(GetNumGuildMembers) == "function" then
				tGuildCount = select(1, GetNumGuildMembers()) or 0
			end
			local memberLoopMax = (tGuildCount > 0) and tGuildCount or 50

			for i = 1, memberLoopMax do
				local memberName, _, _, memberLevel, memberClass = GetGuildRosterInfo(i)

				-- Ensure that the Counter is not bigger than the Amount of Members in Guildlist
				if(memberName ~= nil and memberLevel ~= nil and memberClass ~= nil and memberName ~= UnitName("player")) then
					local tMember = MultiBot.addMember(memberClass, memberLevel, memberName).setDisable()
					bindUnitToggleHandlers(tMember, { requireEnabledStateOnRight = true })
				else
					break
				end
			end

			-- FRIENDBOTS --
			local tFriendCount = 0
			if type(GetNumFriends) == "function" then
				tFriendCount = GetNumFriends() or 0
			end
			local friendLoopMax = (tFriendCount > 0) and tFriendCount or 50

			for i = 1, friendLoopMax do
				local friendName, friendLevel, friendClass = GetFriendInfo(i)

				-- Ensure that the Counter is not bigger than the Amount of Members in Friendlist
				if(friendName ~= nil and friendLevel ~= nil and friendClass ~= nil and friendName ~= UnitName("player")) then
					local tFriend = MultiBot.addFriend(friendClass, friendLevel, friendName).setDisable()
					bindUnitToggleHandlers(tFriend, { requireEnabledStateOnRight = true })
				else
					break
				end
			end

			-- REFRESH:RAID --

			if(GetNumRaidMembers() > 4) then
				for i = 1, GetNumRaidMembers() do
					local raidName = UnitName("raid" .. i)
					SendChatMessage(".playerbot bot add " .. raidName, "SAY")
				end

				return
			end

			-- REFRESH:GROUP --

			if(GetNumPartyMembers() > 0) then
				for i = 1, GetNumPartyMembers() do
					local partyName = UnitName("party" .. i)
					SendChatMessage(".playerbot bot add " .. partyName, "SAY")
				end

				return
			end

			return
		end

		if(MultiBot.isInside(arg1, "player already logged in")) then
			local tName = string.sub(arg1, 6, string.find(arg1, " ", 6) - 1)
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end

            if(MultiBot.isMember(tName)) then
               -- On ne redemande plus les stratégies ici pour éviter les doublons.
               -- Le flux normal via le WHISPER "Hello" s'en chargera.
               if(BridgeBootOwnsState() and MultiBot.Comm and MultiBot.Comm.RequestState) then
                  tButton.waitFor = "BRIDGE_STATE"
                  tButton.setEnable()
                  MultiBot.Comm.RequestState(tName)
                  if(MultiBot.Comm.RequestBotDetail) then
                     MultiBot.Comm.RequestBotDetail(tName)
                  end
                  return
               end

               if LegacyChatFallbackEnabled() then
                  tButton.waitFor = "CO"
                  SendChatMessage("co ?", "WHISPER", nil, tName)
               else
                  tButton.waitFor = ""
               end
               tButton.setEnable()
               return
            end

			if(GetNumPartyMembers() == 4) then ConvertToRaid() end
			MultiBot.doSlash("/invite", tName)
			return
		end

		if(MultiBot.isInside(arg1, "remove: ")) then
			local tName = string.sub(arg1, 9, string.find(arg1, " ", 9) - 1)
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end

			if(MultiBot.isInside(arg1, "not your bot")) then
				SendChatMessage("leave", "WHISPER", nil, tName)
			end

			MultiBot.doRemove(MultiBot.index.classes.actives[tButton.class], tButton.name)
			MultiBot.doRemove(MultiBot.index.actives, tButton.name)

			if(tFrame ~= nil) then tFrame:Hide() end
			tButton.setDisable()
			return
		end

		if(arg1 == "Enable player botAI") then
			local tName = UnitName("player")
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			if LegacyChatFallbackEnabled() then
				tButton.waitFor = "CO"
				SendChatMessage("co ?", "WHISPER", nil, tName)
			else
				tButton.waitFor = ""
			end
			tButton.setEnable()
			return
		end

		if(arg1 == "Disable player botAI") then
			local tName = UnitName("player")
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			if(tFrame ~= nil) then tFrame:Hide() end
			tButton.setDisable()
			return
		end

		if(MultiBot.isInside(arg1, "Zone:", "zone:")) then
			local tPlayer = MultiBot.getBot(UnitName("player"))
			if(tPlayer.waitFor ~= "COORDS") then return end

			local tLocation = MultiBot.doSplit(arg1, " ")
			local tZone = string.sub(tLocation[6], 2, string.len(tLocation[6]) - 1)
			local tMap = string.sub(tLocation[3], 2, string.len(tLocation[3]) - 1)
			local tTip = MultiBot.doReplace(MultiBot.doReplace(MultiBot.L("info.teleport"), "MAP", tMap), "ZONE", tZone)

			tPlayer.memory.goMap = tLocation[2]
			tPlayer.memory.tip = MultiBot.doReplace(MultiBot.L("tips.game.memory"), "ABOUT", tTip)
			return
		end

		if(MultiBot.isInside(arg1, "X:") and MultiBot.isInside(arg1, "Y:")) then
			local tPlayer = MultiBot.getBot(UnitName("player"))
			if(tPlayer.waitFor ~= "COORDS") then return end

			local tCoords = MultiBot.doSplit(arg1, " ")
			tPlayer.memory.goX = tCoords[2]
			tPlayer.memory.goY = tCoords[4]
			tPlayer.memory.goZ = tCoords[6]
			tPlayer.memory.setEnable()
			tPlayer.waitFor = ""
			return
		end
	end

	-- ADDED FOR QUESTS --
	ensureQuestStateTables()
	-- END ADD FOR QUESTS --

	-- CHAT:WHISPER --
	if(event == "CHAT_MSG_WHISPER") then
		perfCount("events.chat_msg_whisper")

		-- Glyphs start
		local rawMsg, author = arg1, arg2

		if MultiBot.HandleSpecWhisper then
			MultiBot.HandleSpecWhisper(rawMsg, author)
		end

		if MultiBot.HandlePvpWhisper then
			MultiBot.HandlePvpWhisper(rawMsg, author)
		end

		-- Add for QUESTS
		local questsAllPredicate = MultiBot.ShouldHandleQuestsAllWhisper or shouldHandleQuestsAllWhisper
		if questsAllPredicate and questsAllPredicate(rawMsg, author) then -- QuestsAll
			HandleQuestsAllResponse(rawMsg, author)
			return
		end

		HandleQuestResponse(rawMsg, author) -- Incomp and Comp Quests

		if MultiBot.HandleGameObjectWhisper(rawMsg, author) then -- Use GOB
			return
		end

		if MultiBot.awaitGlyphs and author == MultiBot.awaitGlyphs then

			-- On ne traite que les réponses commençant par "Glyphs:" ou "No glyphs"
			if not rawMsg:match("^[Gg]lyphs:") and not rawMsg:match("^[Nn]o glyphs") then
				DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[ERROR]|r " .. MultiBot.L("talent.glyphs.error_ignored_non_glyph"))
				return
			end

			-- On extrait tout ce qui suit "Glyphs:"
			local rest = rawMsg:match("^[Gg]lyphs:%s*(.*)") or ""
			local ids = {}

			if rest:lower():match("^no glyphs") then
				-- pas de glyphe → on met 6 zéros
				for i = 1, 6 do ids[i] = 0 end
			else
				-- on récupère directement chaque ID depuis les liens cliquables
				for id in rest:gmatch("|Hitem:(%d+):") do
					table.insert(ids, tonumber(id))
				end
				-- on complète si moins de 6
				for i = #ids + 1, 6 do
					ids[i] = 0
				end
			end

			-- On stocke cette liste pour le rafraîchissement
			local receivedGlyphs = (MultiBot.Store and MultiBot.Store.EnsureRuntimeTable and MultiBot.Store.EnsureRuntimeTable("receivedGlyphs")) or MultiBot.receivedGlyphs
			if type(receivedGlyphs) ~= "table" then
				receivedGlyphs = {}
				MultiBot.receivedGlyphs = receivedGlyphs
			end
			receivedGlyphs[author] = {}

			-- Détermination du type Major/Minor et remplissage
			local unit = MultiBot.toUnit(author)
			local _, cf = UnitClass(unit or "player")
			local classKey = (cf == "DEATHKNIGHT")
							and "DeathKnight"
							or cf:sub(1,1)..cf:sub(2):lower()
			local glyphDB = MultiBot.data.talent.glyphs[classKey] or {}

			-- Mappage des sockets
			local map = { 1, 2, 5, 6, 4, 3 }
			for idx, id in ipairs(ids) do
				local sock = map[idx]                    -- n° de socket cible
				local typ  = (glyphDB.Major and glyphDB.Major[id]) and "Major" or "Minor"
				receivedGlyphs[author][sock] = { id = id, type = typ }
			end

			-- Si l'onglet Glyphes est ouvert, on force son rafraîchissement.
			local glyphFrameKey = MultiBot.TalentTabGroups and MultiBot.TalentTabGroups.GLYPH
			local glyphFrame = glyphFrameKey and MultiBot.talent.frames[glyphFrameKey]
			if glyphFrame and glyphFrame:IsShown() then

				MultiBot.FillDefaultGlyphs()
			end

			MultiBot.awaitGlyphs = nil
			return
		end
		-- END GLYPHES --

		if(MultiBot.auto.release == true) then
			-- Graveyard not ready to talk Bot in the chinese Version --
			if(arg1 == "在墓地见我") then
				MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2].waitFor = "你好"
				return
			end

			if(arg1 == "Meet me at the graveyard") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				return
			end
		end

		if(MultiBot.isInside(arg1, "StatsOfPlayer")) then
			local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
			if not statsFrame then
				return
			end

			local tUnit = MultiBot.toUnit(arg2)
			local unitStats = statsFrame.frames[tUnit]
			if unitStats and unitStats.setStats then
				unitStats.setStats(arg2, UnitLevel(tUnit), arg1, true)
			end
		end

		if(arg1 == "stats" and arg2 ~= UnitName("player")) then
			local tXP = math.floor(100.0 / UnitXPMax("player") * UnitXP("player"))
			local tMana = math.floor(100.0 / UnitManaMax("player") * UnitMana("player"))
			SendChatMessage("StatsOfPlayer " .. tXP .. " " .. tMana, "WHISPER", nil, arg2)
		end

		-- REQUIREMENT --

		local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2]

		if(MultiBot.auto.release == true) then
			-- Graveyard ready to talk Bot in the chinese Version --
			if(tButton ~= nil and tButton.waitFor == "你好" and arg1 == "你好") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				tButton.waitFor = ""
				return
			end
		end

		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton == nil) then
            local tUnit = MultiBot.toUnit(arg2)
            if not (tUnit and UnitExists(tUnit)) then
               -- Bot is still not in party/raid we stop
               return
            end

            local _, tClass = UnitClass(tUnit)
            local tLevel    = UnitLevel(tUnit)

				tButton = MultiBot.addActive(tClass, tLevel, arg2).setDisable()
				bindUnitToggleHandlers(tButton, { requireEnabledStateOnRight = false })
			elseif(tButton == nil) then return end

		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton.class == "Unknown" and tButton.roster == "friends") then
			local tName = ""
			local tLevel = ""
			local tClass = ""
			local tFriendScanCount = 0
			if type(GetNumFriends) == "function" then
				tFriendScanCount = GetNumFriends() or 0
			end
			local friendScanMax = (tFriendScanCount > 0) and tFriendScanCount or 50

			for i = 1, friendScanMax do
				tName, tLevel, tClass = GetFriendInfo(i)
				if(tName == arg2) then break end
				if(tName == nil) then break end
			end

			tClass = MultiBot.toClass(tClass)
			local tTable = MultiBot.index.classes[tButton.roster][tButton.class]
			local tIndex = 0

			for i = 1, #tTable do
				if(tTable[i] == arg2) then
					tIndex = i
					break
				end
			end

			if(tIndex > 0) then
				if(MultiBot.index.classes[tButton.roster][tClass] == nil) then MultiBot.index.classes[tButton.roster][tClass] = {} end
				table.remove(MultiBot.index.classes[tButton.roster][tButton.class], tIndex)
				table.insert(MultiBot.index.classes[tButton.roster][tClass], tName)
			end

			tButton.setTexture("Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp")
			tButton.tip = MultiBot.toTip(tClass, tLevel, tName)
			tButton.class = tClass
		end

		if(MultiBot.isInside(arg1, "Hello", "你好")) then
			if(BridgeBootOwnsState() and MultiBot.Comm and MultiBot.Comm.RequestState) then
				tButton.waitFor = "BRIDGE_STATE"
				MultiBot.Comm.RequestState(arg2)
				if(MultiBot.Comm.RequestBotDetail) then
					MultiBot.Comm.RequestBotDetail(arg2)
				end
				return
			end

			if LegacyChatFallbackEnabled() then
				tButton.waitFor = "CO"
				SendChatMessage("co ?", "WHISPER", nil, arg2)
			else
				tButton.waitFor = ""
			end
			return
		end

		if(MultiBot.isInside(arg1, "Goodbye", "再见")) then
			return
		end

		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "CO") then
			SendChatMessage("co ,?", "WHISPER", nil, arg2)
			return
		end

		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "NC") then
			SendChatMessage("nc ,?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "DETAIL" and MultiBot.isInside(arg1, "playing with")) then
			tButton.waitFor = ""
			MultiBot.RaidPool(arg2, arg1)
			return
		end

		if(tButton.waitFor == "IGNORE" and MultiBot.isInside(arg1, "Ignored ")) then
			if(MultiBot.spells[arg2] == nil) then MultiBot.spells[arg2] = {} end
			tButton.waitFor = "DETAIL"

			local tIgnores = MultiBot.doSplit(arg1, ": ")[2]

			if(tIgnores ~= nil) then
				local tSpells = MultiBot.doSplit(tIgnores, ", ")

				for k,v in pairs(tSpells) do
					local tSpell = MultiBot.doSplit(v, "|")[3]
					if(tSpell ~= nil) then MultiBot.spells[arg2][MultiBot.doSplit(tSpell, ":")[2]] = false end
				end
			end

			SendChatMessage("who", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "NC" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "IGNORE"
			tButton.normal = string.sub(arg1, 13)

			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].addFrame(arg2, tButton.x - tButton.size - 2, tButton.y + 2)
			tFrame.class = tButton.class
			tFrame.name = tButton.name

			MultiBot["add" .. tButton.class](tFrame, tButton.combat, tButton.normal)
			MultiBot.addEvery(tFrame, tButton.combat, tButton.normal)

			if(MultiBot.index.classes.actives[tButton.class] == nil) then MultiBot.index.classes.actives[tButton.class] = {} end
			if(MultiBot.isActive(tButton.name) == false) then
				table.insert(MultiBot.index.classes.actives[tButton.class], tButton.name)
				table.insert(MultiBot.index.actives, tButton.name)
			end

			tButton.setEnable()
			SendChatMessage("ss ?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "CO" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "NC"
			tButton.combat = string.sub(arg1, 13)
			SendChatMessage("nc ?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor ~= "ITEM" and tButton.waitFor ~= "SPELL" and MultiBot.auto.stats and MultiBot.isInside(arg1, "Bag")) then
			local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
			if not statsFrame then
				return
			end

			local tUnit = MultiBot.toUnit(arg2)
			if(statsFrame.frames[tUnit] == nil) then
				MultiBot.addStats(statsFrame, tUnit, 0, 0, 32, 192, 96)
			end

			if statsFrame.frames[tUnit] and statsFrame.frames[tUnit].setStats then
				statsFrame.frames[tUnit].setStats(arg2, UnitLevel(tUnit), arg1)
			end
			return
		end

		if(tButton.waitFor == "OUTFITS" and MultiBot.HandleOutfitChatLine and MultiBot.HandleOutfitChatLine(tButton, arg1, arg2)) then
			return
		end

		-- Inventory --

		if(tButton.waitFor == "INVENTORY" and MultiBot.isInside(arg1, "Inventory", "背包")) then
			if(MultiBot.inventory and MultiBot.inventory.beginPayload) then
				MultiBot.inventory:beginPayload(arg2)
			else
				local tItems = MultiBot.inventory.frames["Items"]
				if(tItems.clear) then
					tItems:clear()
				else
					for key, value in pairs(tItems.buttons) do value:Hide() end
					for key in pairs(tItems.buttons) do tItems.buttons[key] = nil end
				end
				MultiBot.inventory.setText("Title", MultiBot.doReplace(MultiBot.L("info.inventory"), "NAME", arg2))
				MultiBot.inventory.name = arg2
				tItems.index = 0
			end
			tButton.waitFor = "ITEM"
			SendChatMessage("stats", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "ITEM" and (MultiBot.beInside(arg1, "Bag,", "Dur") or MultiBot.beInside(arg1, "背包", "耐久度"))) then
			if MultiBot.inventory and MultiBot.inventory.applySummaryLine then
				MultiBot.inventory:applySummaryLine(arg1)
			end
			MultiBot.inventory:Show()
			tButton.waitFor = ""
			InspectUnit(arg2)
			return
		end

		if(tButton.waitFor == "ITEM") then
			if(string.sub(arg1, 1, 3) == "---") then return end
			if(MultiBot.inventory and MultiBot.inventory.appendItem) then
				MultiBot.inventory:appendItem(arg1)
			else
				MultiBot.addItem(MultiBot.inventory.frames["Items"], arg1)
			end
			return
		end

		-- Spellbook --

		if(MultiBot.handleSpellbookChatLine and MultiBot.handleSpellbookChatLine(tButton, arg1, arg2)) then
			return
		end

		-- EQUIPPING --

		if(MultiBot.inventory:IsVisible()) then
			if(MultiBot.isInside(arg1, "装备", "卸下", "使用", "吃", "喝", "盛宴", "摧毁")) then
				if(MultiBot.RequestInventoryPostActionRefresh and MultiBot.RequestInventoryPostActionRefresh(tButton.name, 0.45, 1.20)) then
					return
				end

				if(MultiBot.RequestInventoryRefresh and MultiBot.RequestInventoryRefresh(tButton.name, 0.45)) then
					return
				end

				if LegacyChatFallbackEnabled() then
					tButton.waitFor = "INVENTORY"
					if(MultiBot.TimerAfter) then
						MultiBot.TimerAfter(0.45, function()
							SendChatMessage("items", "WHISPER", nil, tButton.name)
						end)
					else
						SendChatMessage("items", "WHISPER", nil, tButton.name)
					end
				else
					tButton.waitFor = ""
				end
				return
			end

			if(MultiBot.isInside(string.lower(arg1), "equipping", "unequipping", "using", "eating", "drinking", "feasting", "destroyed", "removed", "taking off")) then
				if(MultiBot.RequestInventoryPostActionRefresh and MultiBot.RequestInventoryPostActionRefresh(tButton.name, 0.45, 1.20)) then
					return
				end

				if(MultiBot.RequestInventoryRefresh and MultiBot.RequestInventoryRefresh(tButton.name, 0.45)) then
					return
				end

				if LegacyChatFallbackEnabled() then
					tButton.waitFor = "INVENTORY"
					if(MultiBot.TimerAfter) then
						MultiBot.TimerAfter(0.45, function()
							SendChatMessage("items", "WHISPER", nil, tButton.name)
						end)
					else
						SendChatMessage("items", "WHISPER", nil, tButton.name)
					end
				else
					tButton.waitFor = ""
				end
				return
			end

			if(MultiBot.inventory:IsVisible() and MultiBot.isInside(string.lower(arg1), "opened")) then
				if(MultiBot.inventory and MultiBot.inventory.markLootPending) then
					MultiBot.inventory:markLootPending(tButton.name)
				else
					tButton.waitFor = "LOOT"
				end
				return
			end
		end

		return
	end

	if(event == "CHAT_MSG_LOOT") then
		if(MultiBot.inventory:IsVisible()) then
			local tButton = nil

			if(MultiBot.isInside(arg1, "获得了物品")) then
				local tName = MultiBot.doReplace(MultiBot.doSplit(arg1, ":")[1], "获得了物品", "")
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end

			if(MultiBot.isInside(string.lower(arg1), "beute", "receives")) then
				local tName = MultiBot.doSplit(arg1, " ")[1]
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end

			if(tButton ~= nil and MultiBot.inventory and MultiBot.inventory.handleLootReceived
				and MultiBot.inventory:handleLootReceived(tButton.name)) then
				tButton.waitFor = ""
				return
			end

			if(tButton ~= nil and tButton.waitFor == "LOOT" and tButton ~= nil) then
				if(MultiBot.RequestInventoryPostActionRefresh and MultiBot.RequestInventoryPostActionRefresh(tButton.name, 0.25, 0.85)) then
					tButton.waitFor = ""
					return
				end

				if LegacyChatFallbackEnabled() then
					tButton.waitFor = "INVENTORY"
					SendChatMessage("items", "WHISPER", nil, tButton.name)
				else
					tButton.waitFor = ""
				end
				return
			end
		end

		return
	end

	if(event == "TRADE_CLOSED") then
		local inventory = MultiBot.inventory
		local botName = inventory and inventory.name or ""

		if inventory and inventory:IsVisible() and botName ~= "" then
			local bridgeConnected = MultiBot.bridge and MultiBot.bridge.connected

			if MultiBot.RequestInventoryPostActionRefresh
				and MultiBot.RequestInventoryPostActionRefresh(botName, 0.45, 1.20, { noChatFallbackWhenBridgeConnected = true }) then
				return
			end

			if bridgeConnected then
				return
			end

			if MultiBot.RefreshInventory then
				MultiBot.RefreshInventory(0.45)
				return
			end
			return
		end

		return
	end

	-- QUEST:COMPLETE --

	if(event == "QUEST_COMPLETE") then
		if(MultiBot.reward.state) then
			MultiBot.setRewards()
			return
		end

		return
	end

	-- QUEST:CHANGED --

	if(event == "QUEST_LOG_UPDATE") then
		local tButton = MultiBot.frames["MultiBar"].frames["Right"].buttons["Quests"]
		tButton.doRight(tButton)
		return
	end

	-- WORLD:MAP --

	if(event == "WORLD_MAP_UPDATE") then
		if(MultiBot.necronet.state == false) then return end

		local tCont = GetCurrentMapContinent()
		local tArea = GetCurrentMapAreaID()

		-- Recalculate Necronet button positions when map size changes
		if MultiBot.Necronet_RecalcButtons then MultiBot.Necronet_RecalcButtons() end

		if(MultiBot.necronet.cont ~= tCont or MultiBot.necronet.area ~= tArea) then
			for key, value in pairs(MultiBot.necronet.buttons) do value:Hide() end

			MultiBot.necronet.cont = tCont
			MultiBot.necronet.area = tArea

			local tTable = MultiBot.necronet.index[tCont]
			if(tTable ~= nil) then tTable = tTable[tArea] end
			if(tTable ~= nil) then for key, value in pairs(tTable) do value:Show() end end
		end

		return
	end
end

MultiBot:SetScript("OnEvent", function(_, eventName, ...)
	MultiBot.DispatchEvent(eventName, ...)
end)

local function ToggleMultiBotUI()
	if MultiBot.ToggleMainUIVisibility then
		MultiBot.ToggleMainUIVisibility()
	end
end

local function printToChat(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message)
    return
  end

  if print then
    print(message)
  end
end

local function parseIntegerArg(msg, defaultValue)
  local value = tonumber(msg or "")
  if value == nil then
    return defaultValue
  end

  return math.floor(value)
end

local function formatClassResolutionMessage(input)
  local canon = MultiBot.NormalizeClass(input)
  if canon then
    return ("Input='%s' -> Canon='%s' | Display='%s'"):format(
      tostring(input),
      canon,
      MultiBot.GetClassDisplay(canon) or "?"
    )
  end

  return ("Input='%s' -> (no match)"):format(tostring(input))
end

local CLASS_TEST_SAMPLES = {
  "dk", "death knight", "DeathKnight",
  "lock", "warlock",
  "pala", "paladin",
  "sham", "shaman",
  "mage", "priest", "warrior", "rogue", "druid", "hunter",
}

local function FakeGMCommand(msg)
  local n = parseIntegerArg(msg, 0)
  MultiBot.GM_DetectFromSystem(("Account level: %d"):format(n))
  printToChat(("GM now: %s (lvl=%d, threshold=%d)"):format(tostring(MultiBot.GM), n, MultiBot.GM_THRESHOLD))
end

local function ClassCommand(msg)
  printToChat(formatClassResolutionMessage(msg))
end

-- /mbclasstest -> batterie de cas utiles (aliases + localisés FR si le client est frFR)
local function ClassTestCommand()
  for _, sample in ipairs(CLASS_TEST_SAMPLES) do
    printToChat(("[MB] '%s' -> %s"):format(sample, tostring(MultiBot.toClass(sample))))
  end
end

local function MainBarLayoutExportCommand()
  if not MultiBot.SaveMainBarLayoutForCurrentPlayer then
    printToChat("[MB] Export indisponible.")
    return
  end

  local ok, ownerKeyOrError = MultiBot.SaveMainBarLayoutForCurrentPlayer()
  if not ok then
    printToChat(("[MB] Export échoué: %s"):format(tostring(ownerKeyOrError)))
    return
  end
  printToChat(("[MB] Layout sauvegardé pour %s"):format(ownerKeyOrError))
end

local function MainBarLayoutImportOwnerCommand(msg)
  if not MultiBot.ImportSavedMainBarLayout then
    printToChat("[MB] Import (owner) indisponible.")
    return
  end

  local ownerKey = tostring(msg or "")
  ownerKey = string.match(ownerKey, "^%s*(.-)%s*$") or ""
  if ownerKey == "" then
    printToChat("[MB] Usage: /mblio <NomJoueur-Royaume>")
    return
  end

  local ok, detail = MultiBot.ImportSavedMainBarLayout(ownerKey)
  if ok then
    printToChat(("[MB] Layout '%s' importé (%s entrées)."):format(ownerKey, tostring(detail)))
    return
  end
  printToChat(("[MB] Import '%s' échoué: %s"):format(ownerKey, tostring(detail)))
end

local function MainBarLayoutListCommand()
  if not MultiBot.GetSavedMainBarLayoutOwners then
    printToChat("[MB] Liste layouts indisponible.")
    return
  end
  local owners = MultiBot.GetSavedMainBarLayoutOwners()
  if #owners == 0 then
    printToChat("[MB] Aucun layout sauvegardé.")
    return
  end
  printToChat("[MB] Layouts sauvegardés:")
  for _, owner in ipairs(owners) do
    printToChat(" - " .. owner)
  end
end

local function MainBarLayoutImportPayloadCommand(msg)
  if not MultiBot.ImportMainBarLayoutPayload then
    printToChat("[MB] Import payload indisponible.")
    return
  end

  local payload = tostring(msg or "")
  payload = string.match(payload, "^%s*(.-)%s*$") or ""
  local ok, detail = MultiBot.ImportMainBarLayoutPayload(payload)
  if ok then
    printToChat(("[MB] Payload importé (%s entrées)."):format(tostring(detail)))
    return
  end
  printToChat(("[MB] Import payload échoué: %s"):format(tostring(detail)))
end

local function MainBarLayoutShowPayloadCommand(msg)
  if not MultiBot.GetSavedMainBarLayoutPayload then
    printToChat("[MB] Show payload indisponible.")
    return
  end

  local ownerKey = tostring(msg or "")
  ownerKey = string.match(ownerKey, "^%s*(.-)%s*$") or ""
  if ownerKey == "" then
    ownerKey = getPlayerLayoutOwnerKey()
  end
  local payload = MultiBot.GetSavedMainBarLayoutPayload(ownerKey)
  if not payload then
    printToChat(("[MB] Aucun payload pour '%s'."):format(ownerKey))
    return
  end
  printToChat(("[MB] Payload '%s':"):format(ownerKey))
  printToChat(payload)
end

local function MainBarLayoutDeleteCommand(msg)
  if not MultiBot.DeleteSavedMainBarLayout then
    printToChat("[MB] Delete layout indisponible.")
    return
  end

  local ownerKey = tostring(msg or "")
  ownerKey = string.match(ownerKey, "^%s*(.-)%s*$") or ""
  if ownerKey == "" then
    printToChat("[MB] Usage: /mbldel <NomJoueur-Royaume>")
    return
  end

  local ok, detail = MultiBot.DeleteSavedMainBarLayout(ownerKey)
  if ok then
    printToChat(("[MB] Layout supprimé: %s"):format(ownerKey))
    return
  end
  printToChat(("[MB] Suppression impossible (%s): %s"):format(ownerKey, tostring(detail)))
end

local function MainBarLayoutResetCommand()
  if not MultiBot.ResetMainBarLayoutState then
    printToChat("[MB] Reset layout indisponible.")
    return
  end

  local ok, removed = MultiBot.ResetMainBarLayoutState()
  if ok then
    printToChat(("[MB] Layout reset effectué (%s clés supprimées)."):format(tostring(removed)))
    return
  end
  printToChat("[MB] Reset layout échoué.")
end

local function normalizeDebugToken(value)
  if type(value) ~= "string" then
    return nil
  end

  local cleaned = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end

  return cleaned
end

local function parseDebugCommandArgs(msg)
  local action, subsystem = string.match(tostring(msg or ""), "^%s*(%S*)%s*(.-)%s*$")
  return normalizeDebugToken(action), normalizeDebugToken(subsystem)
end

local function DebugCommand(msg)
  local debugApi = MultiBot.Debug
  if type(debugApi) ~= "table" then
    printToChat("[MB] Debug API indisponible.")
    return
  end

  local action, subsystem = parseDebugCommandArgs(msg)
  if not action or action == "list" then
    local text = (type(debugApi.ListFlagsText) == "function") and debugApi.ListFlagsText() or ""
    printToChat("[MB] Debug flags: " .. (text ~= "" and text or "(none)"))
    return
  end

  if action == "all" then
    if type(debugApi.SetAllEnabled) ~= "function" then
      printToChat("[MB] Action indisponible: all")
      return
    end

    debugApi.SetAllEnabled(subsystem == "on")
    printToChat("[MB] Debug all => " .. ((subsystem == "on") and "on" or "off"))
    return
  end

  if action == "counters" then
    if type(debugApi.FormatCounters) ~= "function" then
      printToChat("[MB] Action indisponible: counters")
      return
    end

    if subsystem == "reset" and type(debugApi.ResetCounters) == "function" then
      debugApi.ResetCounters()
      printToChat("[MB] Compteurs perf réinitialisés.")
      return
    end

    printToChat("[MB] Perf counters: " .. debugApi.FormatCounters(25))
    return
  end

  if not subsystem then
    printToChat("[MB] Usage: /mbdebug list | /mbdebug on <subsystem> | /mbdebug off <subsystem> | /mbdebug toggle <subsystem> | /mbdebug all on|off | /mbdebug counters [reset]")
    return
  end

  if action == "on" then
    if debugApi.SetEnabled and debugApi.SetEnabled(subsystem, true) then
      printToChat("[MB] Debug " .. subsystem .. " => on")
    else
      printToChat("[MB] Sous-système invalide: " .. subsystem)
    end
    return
  end

  if action == "off" then
    if debugApi.SetEnabled and debugApi.SetEnabled(subsystem, false) then
      printToChat("[MB] Debug " .. subsystem .. " => off")
    else
      printToChat("[MB] Sous-système invalide: " .. subsystem)
    end
    return
  end

  if action == "toggle" then
    if not debugApi.Toggle then
      printToChat("[MB] Action indisponible: toggle")
      return
    end

    local value = debugApi.Toggle(subsystem)
    if value == nil then
      printToChat("[MB] Sous-système invalide: " .. subsystem)
      return
    end

    printToChat("[MB] Debug " .. subsystem .. " => " .. (value and "on" or "off"))
    return
  end

  printToChat("[MB] Action inconnue: " .. action)
end

local COMMAND_DEFINITIONS = {
  { "MULTIBOT", ToggleMultiBotUI, { "multibot", "mbot", "mb" } },
  { "MBFAKEGM", FakeGMCommand, { "mbfakegm" } },
  { "MBCLASS", ClassCommand, { "mbclass" } },
  { "MBCLASSTEST", ClassTestCommand, { "mbclasstest" } },
  { "MBLAYOUTEXPORT", MainBarLayoutExportCommand, { "mblayoutexport", "mblx" } },
  { "MBLAYOUTLIST", MainBarLayoutListCommand, { "mblayoutlist", "mbll" } },
  { "MBLAYOUTIMPORTOWNER", MainBarLayoutImportOwnerCommand, { "mblayoutimportowner", "mblio" } },
  { "MBLAYOUTIMPORTPAYLOAD", MainBarLayoutImportPayloadCommand, { "mblayoutimportpayload", "mbli" } },
  { "MBLAYOUTSHOWPAYLOAD", MainBarLayoutShowPayloadCommand, { "mblayoutshowpayload", "mblp" } },
  { "MBLAYOUTDELETE", MainBarLayoutDeleteCommand, { "mblayoutdelete", "mbldel" } },
  { "MBLAYOUTRESET", MainBarLayoutResetCommand, { "mblayoutreset", "mblreset" } },
  { "MBDEBUG", DebugCommand, { "mbdebug" } },
}

for _, def in ipairs(COMMAND_DEFINITIONS) do
  MultiBot.RegisterCommandAliases(def[1], def[2], def[3])
end