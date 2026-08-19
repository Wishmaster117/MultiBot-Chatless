MultiBot.addShaman = function(pFrame, pCombat, pNormal)
	-- PLAYBOOK --

	pFrame.addButton("Playbook", 0, 0, "inv_misc_book_06", MultiBot.L("tips.shaman.playbook.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
	end

	local playbookFrame = pFrame.addFrame("Playbook", -2, 30)
	playbookFrame:Hide()

	-- HOTFIX_MULTIBOT_SHAMAN_PLAYBOOK_SYNC_V2E2C_START --
	local shamanTotemGroups = {
		earth = { "strength of earth", "stoneskin", "tremor", "earthbind" },
		fire = { "searing", "magma", "flametongue", "wrath", "frost resistance" },
		water = { "healing stream", "mana spring", "cleansing", "fire resistance" },
		air = { "wrath of air", "windfury", "nature resistance", "grounding" },
	}

	local shamanSpecDefaults = {
		resto = {
			earth = { strategy = "stoneskin", icon = "spell_nature_stoneskintotem" },
			fire = { strategy = "flametongue", icon = "spell_nature_guardianward" },
			water = { strategy = "mana spring", icon = "spell_nature_manaregentotem" },
			air = { strategy = "wrath of air", icon = "spell_nature_slowingtotem" },
		},
		ele = {
			earth = { strategy = "stoneskin", icon = "spell_nature_stoneskintotem" },
			fire = { strategy = "wrath", icon = "spell_fire_totemofwrath" },
			water = { strategy = "mana spring", icon = "spell_nature_manaregentotem" },
			air = { strategy = "wrath of air", icon = "spell_nature_slowingtotem" },
		},
		enh = {
			earth = { strategy = "strength of earth", icon = "spell_nature_earthbindtotem" },
			fire = { strategy = "magma", icon = "spell_fire_moltenblood" },
			water = { strategy = "healing stream", icon = "spell_nature_healingwavelesser" },
			air = { strategy = "windfury", icon = "spell_nature_windfury" },
		},
	}

	local shamanElementOrder = { "earth", "fire", "water", "air" }
	local shamanCommandInterval = 0.10
	local shamanStateRefreshDelay = 1.30

	local function scheduleShamanTask(delay, callback)
		if(type(callback) ~= "function") then return end
		if(type(MultiBot.TimerAfter) == "function") then
			MultiBot.TimerAfter(delay, callback)
		else
			callback()
		end
	end

	local function buildShamanElementCommand(elementKey, selectedStrategy)
		local strategies = shamanTotemGroups[elementKey]
		if(not strategies or not selectedStrategy) then return nil end

		local changes = {}
		for _, strategy in ipairs(strategies) do
			table.insert(changes, "-" .. strategy)
		end
		table.insert(changes, "+" .. selectedStrategy)
		return "co " .. table.concat(changes, ",")
	end

	local function normalizeShamanBotName(name)
		if(type(name) ~= "string") then return "" end
		local normalized = string.lower(name)
		normalized = string.gsub(normalized, "%-.*$", "")
		return normalized
	end

	local function findQuickShamanRow(target)
		local quick = MultiBot.ShamanQuick
		local entries = quick and quick.entries
		if(not entries) then return nil end
		if(entries[target]) then return entries[target] end

		local wanted = normalizeShamanBotName(target)
		for owner, row in pairs(entries) do
			if(normalizeShamanBotName(owner) == wanted) then return row end
		end
		return nil
	end

	local function applyQuickShamanSpecDefaults(target, specKey)
		local defaults = shamanSpecDefaults[specKey]
		if(not defaults or type(target) ~= "string" or target == "") then return end

		local quick = MultiBot.ShamanQuick
		local row = findQuickShamanRow(target)
		local storageTarget = row and row.owner or target

		for _, elementKey in ipairs(shamanElementOrder) do
			local choice = defaults[elementKey]
			if(choice) then
				if(MultiBot.SetShamanTotemChoice) then
					MultiBot.SetShamanTotemChoice(storageTarget, elementKey, choice.icon)
				end

				if(row and quick) then
					if(quick.ClearTotemSelection) then
						quick:ClearTotemSelection(row, elementKey, { skipPersist = true })
					end

					local selectedButton = nil
					local buttons = row.gridButtons and row.gridButtons[elementKey]
					for _, button in ipairs(buttons or {}) do
						if(button.__mbSpell == choice.strategy) then
							selectedButton = button
							break
						end
					end

					row.selectedIcons = row.selectedIcons or {}
					row.selectedIcons[elementKey] = choice.icon
					if(selectedButton and quick.SetSelectedTotemButton) then
						quick:SetSelectedTotemButton(row, elementKey, selectedButton)
					end
					if(quick.SetElementIcon) then
						quick:SetElementIcon(row, elementKey, choice.icon)
					end
				end
			end
		end
	end

	local function getShamanBridgeStateTimestamp(target)
		local bridge = MultiBot.bridge
		local states = bridge and bridge.states
		local entry = states and states[string.lower(target or "")]
		return entry and tonumber(entry.lastUpdateAt) or 0
	end

	local function getShamanSequenceKey(target)
		if(type(target) ~= "string") then return "" end
		return string.lower(target)
	end

	local function beginShamanPlaybookSequence(target)
		MultiBot._shamanPlaybookSequences = MultiBot._shamanPlaybookSequences or {}
		local key = getShamanSequenceKey(target)
		local sequence = (MultiBot._shamanPlaybookSequences[key] or 0) + 1
		MultiBot._shamanPlaybookSequences[key] = sequence
		return key, sequence
	end

	local function isShamanPlaybookSequenceCurrent(sequenceKey, sequence)
		return MultiBot._shamanPlaybookSequences
			and MultiBot._shamanPlaybookSequences[sequenceKey] == sequence
	end

	local function getShamanUnitButton(target)
		local units = MultiBot.frames
			and MultiBot.frames["MultiBar"]
			and MultiBot.frames["MultiBar"].frames
			and MultiBot.frames["MultiBar"].frames["Units"]
		return units and units.buttons and units.buttons[target]
	end

	local function requestShamanCombatState(target, bridgeSync, sequenceKey, sequence)
		local previousUpdateAt = getShamanBridgeStateTimestamp(target)

		local function isCurrent()
			return isShamanPlaybookSequenceCurrent(sequenceKey, sequence)
		end

		local function requestBridgeState()
			if(not isCurrent()) then return end
			if(MultiBot.Comm and MultiBot.Comm.RequestState) then
				MultiBot.Comm.RequestState(target)
			end
		end

		local function requestLegacyState()
			if(not isCurrent()) then return end
			local unitButton = getShamanUnitButton(target)
			if(unitButton) then unitButton.waitFor = "CO" end
			MultiBot.ActionToTarget("co ?", target)
		end

		if(bridgeSync) then
			scheduleShamanTask(shamanStateRefreshDelay, requestBridgeState)
			scheduleShamanTask(shamanStateRefreshDelay + 0.65, requestBridgeState)
			scheduleShamanTask(shamanStateRefreshDelay + 1.55, function()
				if(not isCurrent()) then return end
				if(getShamanBridgeStateTimestamp(target) > previousUpdateAt) then return end
				requestLegacyState()
			end)
		else
			scheduleShamanTask(shamanStateRefreshDelay, requestLegacyState)
		end
	end

-- MB_P1A_SHAMAN_PLAYBOOK_BLOCKED_STATE_V1_START
	local function dispatchShamanPlaybookCommands(target, commands, bridgeSync, sequenceKey, sequence, onAccepted)
		local function sendCommand(index)
			if(not isShamanPlaybookSequenceCurrent(sequenceKey, sequence)) then return end

			local command = commands[index]
			if(not command) then return end
			if(not MultiBot.ActionToTarget(command, target)) then return end

			if(index < #commands) then
				scheduleShamanTask(shamanCommandInterval, function()
					sendCommand(index + 1)
				end)
			else
				if(type(onAccepted) == "function" and isShamanPlaybookSequenceCurrent(sequenceKey, sequence)) then
					onAccepted()
				end
				requestShamanCombatState(target, bridgeSync, sequenceKey, sequence)
			end
		end

		sendCommand(1)
	end
-- MB_P1A_SHAMAN_PLAYBOOK_BLOCKED_STATE_V1_END
	local function selectExclusiveShamanSpec(pButton, specKey, pOtherOne, pOtherTwo)
		local defaults = shamanSpecDefaults[specKey]
		local target = pButton.getName()
		if(not defaults or type(target) ~= "string" or target == "") then return end

		local bridgeSync = MultiBot.bridge
			and MultiBot.bridge.connected == true
			and MultiBot.Comm
			and MultiBot.Comm.RequestState

		local commands = { "co -resto,-ele,-enh,+" .. specKey }
		for _, elementKey in ipairs(shamanElementOrder) do
			local command = buildShamanElementCommand(elementKey, defaults[elementKey].strategy)
			if(command) then table.insert(commands, command) end
		end

		local sequenceKey, sequence = beginShamanPlaybookSequence(target)

		-- Commit the visible Playbook state and Quick Shaman persisted defaults only
		-- after every mutation in this sequence has been accepted for delivery.
		dispatchShamanPlaybookCommands(target, commands, bridgeSync, sequenceKey, sequence, function()
			if(not isShamanPlaybookSequenceCurrent(sequenceKey, sequence)) then return end
			pButton.setEnable()
			pButton.getButton(pOtherOne).setDisable()
			pButton.getButton(pOtherTwo).setDisable()
			applyQuickShamanSpecDefaults(target, specKey)
		end)
	end	-- HOTFIX_MULTIBOT_SHAMAN_PLAYBOOK_SYNC_V2E2C_END --

	playbookFrame.addButton(
		"Aoe", 0, 0, "spell_nature_lightningoverload",
		MultiBot.L("tips.shaman.playbook.aoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +aoe,?", "co -aoe,?", pButton.getName())
	end

	playbookFrame.addButton(
		"Restoration", 0, 26, "spell_holy_aspiration",
		MultiBot.L("tips.shaman.playbook.resto")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveShamanSpec(pButton, "resto", "Elemental", "Enhancement")
	end

	playbookFrame.addButton(
		"Elemental", 0, 52, "spell_nature_lightning",
		MultiBot.L("tips.shaman.playbook.ele")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveShamanSpec(pButton, "ele", "Restoration", "Enhancement")
	end

	playbookFrame.addButton(
		"Enhancement", 0, 78, "ability_parry",
		MultiBot.L("tips.shaman.playbook.enh")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveShamanSpec(pButton, "enh", "Restoration", "Elemental")
	end

	-- STRATEGIES:PLAYBOOK --

	if(MultiBot.hasStrategy(pCombat, "aoe")) then pFrame.getButton("Aoe").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "resto")) then pFrame.getButton("Restoration").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "ele")) then pFrame.getButton("Elemental").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "enh")) then pFrame.getButton("Enhancement").setEnable() end

	-- DPS --

	pFrame.addButton("DpsControl", -30, 0, "ability_warrior_challange", MultiBot.L("tips.shaman.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local dpsControlFrame = pFrame.addFrame("DpsControl", -32, 30)
	dpsControlFrame:Hide()

	dpsControlFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.shaman.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsControlFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.shaman.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	-- HEALER DPS --

	dpsControlFrame.addButton("HealerDps", 0, 52, "INV_Alchemy_Elixir_02", MultiBot.L("tips.shaman.dps.healerdps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +healer dps,?", "co -healer dps,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	if MultiBot.AddCommonCombatStrategyButtons then
		MultiBot.AddCommonCombatStrategyButtons(pFrame, dpsControlFrame, pCombat, 78)
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -60, 0, "ability_warrior_innerrage", MultiBot.L("tips.shaman.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- UTILITAIRE : CURE --

	pFrame.addButton("Cure", -90, 0, "Ability_Creature_Poison_02", MultiBot.L("tips.shaman.playbook.cure")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +cure,?", "co -cure,?", pButton.getName())
	end

	-- STRATEGIES --

	if(MultiBot.hasStrategy(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "healer dps")) then pFrame.getButton("HealerDps").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "cure")) then pFrame.getButton("Cure").setEnable() end
end
