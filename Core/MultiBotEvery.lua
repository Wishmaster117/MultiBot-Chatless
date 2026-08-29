local showEveryMessage

local function selfActionReasonText(reason)
  local reasonCode = tostring(reason or "UNKNOWN")
  if reasonCode == "RATE_LIMIT" then
    return MultiBot.L("selfaction.reason.RATE_LIMIT")
  end
  return reasonCode
end

local function runEverySelfAction(action, argument)
  local comm = MultiBot and MultiBot.Comm or nil
  if not (comm and type(comm.RunSelfAction) == "function") then
    if showEveryMessage then
      showEveryMessage(MultiBot.L("selfaction.bridge_unavailable"))
    end
    return false
  end

  local token = comm.RunSelfAction(action, argument or "", function(result)
    if type(result) == "table" and result.status ~= "ok" and showEveryMessage then
      local reasonText = selfActionReasonText(result.reason)
      showEveryMessage(string.format(MultiBot.L("selfaction.failed"), reasonText))
    end
  end)
  if not token and showEveryMessage then
    local reason = MultiBot and MultiBot.bridge and MultiBot.bridge.lastError or "UNAVAILABLE"
    showEveryMessage(string.format(MultiBot.L("selfaction.send_failed"), selfActionReasonText(reason)))
  end
  return token and true or false
end
-- Confirmation popup for Autogear
if not StaticPopupDialogs["MULTIBOT_AUTOGEAR_CONFIRM"] then
  StaticPopupDialogs["MULTIBOT_AUTOGEAR_CONFIRM"] = {
    text = MultiBot.L("tips.every.autogearpopup"),
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, data)
      if data and data.target then
        if data.selfAction == true then
          runEverySelfAction("AUTOGEAR", "")
        else
          SendChatMessage("autogear", "WHISPER", nil, data.target)
        end
      end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3, -- évite les conflits d’index avec d’autres popups
  }
end

showEveryMessage = function(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99MultiBot|r " .. tostring(message or ""))
  elseif print then
    print("MultiBot " .. tostring(message or ""))
  end
end

local function runBotCombatCommand(button, command)
  if not button or type(command) ~= "string" or command == "" then
    return false
  end

  local botName = button.getName and button.getName() or ""
  if botName == "" then
    return false
  end

  local comm = MultiBot and MultiBot.Comm or nil
  if comm and comm.RunCombatCommand and comm.RunCombatCommand("BOT", botName, command) then
    return true
  end

  showEveryMessage(MultiBot.L("tips.every.combatbridge", "Bridge unavailable: combat command was not sent."))
  return false
end

local function runBotCombatToggle(button, enableCommand, disableCommand)
  if not button then
    return
  end

  if button.state then
    if runBotCombatCommand(button, disableCommand) then
      button.setDisable()
    end
  elseif runBotCombatCommand(button, enableCommand) then
    button.setEnable()
  end
end

local function addBotCombatButton(parent, name, x, y, icon, tip, enableCommand, disableCommand)
  local button = parent.addButton(name, x, y, icon, tip)

  if disableCommand then
    button.setDisable()
    button.doLeft = function(self)
      runBotCombatToggle(self, enableCommand, disableCommand)
    end
  else
    button.doLeft = function(self)
      runBotCombatCommand(self, enableCommand)
    end
  end

  return button
end

-- D3.1 dynamic group action state.
local function IsEveryGroupActive(name)
	if type(name) ~= "string" or name == "" then
		return false
	end

	local actives = MultiBot.index and MultiBot.index.actives or nil
	if type(actives) ~= "table" then
		return false
	end

	local normalizedName = string.lower(name)
	for _, activeName in pairs(actives) do
		if type(activeName) == "string" and string.lower(activeName) == normalizedName then
			return true
		end
	end

	return false
end

local function GetEveryUnitButton(pFrame, name)
	local parent = pFrame and pFrame.parent or nil
	local buttons = parent and parent.buttons or nil
	return buttons and name and buttons[name] or nil
end

local function RestoreEveryGroupCompactButtons(pFrame)
	local snapshot = pFrame and pFrame._mbGroupCompactButtonShown or nil
	if type(snapshot) ~= "table" or type(pFrame.buttons) ~= "table" then
		return
	end

	for key, button in pairs(pFrame.buttons) do
		if button then
			if snapshot[key] == true and button.Show then
				button:Show()
			elseif button.Hide then
				button:Hide()
			end
		end
	end

	pFrame._mbGroupCompactButtonShown = nil
end

local function EnterEveryGroupCompactMode(pFrame, inviteButton, unitButton)
	if pFrame._mbGroupCompact ~= true then
		local snapshot = {}
		for key, button in pairs(pFrame.buttons or {}) do
			snapshot[key] = button and button.IsShown and button:IsShown() and true or false
		end
		pFrame._mbGroupCompactButtonShown = snapshot
	end

	pFrame._mbGroupCompact = true
	if unitButton then
		unitButton._mbGroupRejoinCollapsed = false
	end

	for _, button in pairs(pFrame.buttons or {}) do
		if button and button.Hide then
			button:Hide()
		end
	end
	for _, childFrame in pairs(pFrame.frames or {}) do
		if childFrame and childFrame.Hide then
			childFrame:Hide()
		end
	end

	if inviteButton and inviteButton.Show then
		inviteButton:Show()
	end
end

local function LeaveEveryGroupCompactMode(pFrame, unitButton, collapseAfterRejoin)
	if pFrame._mbGroupCompact == true then
		RestoreEveryGroupCompactButtons(pFrame)
	end
	pFrame._mbGroupCompact = false

	if unitButton then
		unitButton._mbGroupRejoinCollapsed = false
	end
end

function MultiBot.RefreshEveryGroupActionFrame(pFrame)
	if not pFrame or type(pFrame.getButton) ~= "function" or type(pFrame.getName) ~= "function" then
		return false
	end

	local uninviteButton = pFrame.getButton("Uninvite")
	local inviteButton = pFrame.getButton("Invite")
	if not uninviteButton or not inviteButton then
		return false
	end

	local name = pFrame.getName()
	if type(name) ~= "string" or name == "" then
		return false
	end

	local unitButton = GetEveryUnitButton(pFrame, name)
	local unitsButton = MultiBot.frames
		and MultiBot.frames["MultiBar"]
		and MultiBot.frames["MultiBar"].buttons
		and MultiBot.frames["MultiBar"].buttons["Units"]
	local currentRoster = unitsButton and unitsButton.roster or nil
	local isOnline = false

	if unitButton then
		if currentRoster == "players" and MultiBot.IsBridgePlayerRosterBotOnline then
			isOnline = MultiBot.IsBridgePlayerRosterBotOnline(unitButton, name)
		elseif currentRoster == "members" and MultiBot.IsGuildRosterBotOnline then
			isOnline = MultiBot.IsGuildRosterBotOnline(unitButton, name)
		else
			isOnline = (
				(MultiBot.IsUnitBotOnline and MultiBot.IsUnitBotOnline(unitButton, name))
				or (not MultiBot.IsUnitBotOnline and unitButton.state == true)
			)
		end
	end
	local isActive = IsEveryGroupActive(name)

	if isActive then
		LeaveEveryGroupCompactMode(pFrame, unitButton, false)
		uninviteButton.doShow()
		inviteButton.doHide()
		if isOnline and pFrame.Show then
			pFrame:Show()
		elseif pFrame.Hide then
			pFrame:Hide()
		end
	elseif isOnline then
		EnterEveryGroupCompactMode(pFrame, inviteButton, unitButton)
		if pFrame.Show then
			pFrame:Show()
		end
	else
		if unitButton then
			unitButton._mbGroupRejoinCollapsed = false
		end
		LeaveEveryGroupCompactMode(pFrame, unitButton, false)
		uninviteButton.doHide()
		inviteButton.doShow()
		if pFrame.Hide then
			pFrame:Hide()
		end
	end

	return true
end

function MultiBot.RefreshEveryGroupActions()
	local units = MultiBot.frames
		and MultiBot.frames["MultiBar"]
		and MultiBot.frames["MultiBar"].frames
		and MultiBot.frames["MultiBar"].frames["Units"]

	if not units or type(units.frames) ~= "table" then
		return 0
	end

	local refreshed = 0
	for _, unitFrame in pairs(units.frames) do
		if MultiBot.RefreshEveryGroupActionFrame(unitFrame) then
			refreshed = refreshed + 1
		end
	end

	return refreshed
end

MultiBot.addEvery = function(pFrame, pCombat, pNormal)

    local isSelfBot = (pFrame.getName() == UnitName("player"))

    -- MENU MISC --------------------------------------------
    -- Crée un sous-frame « Misc » au-dessus du bouton
    local tMisc = pFrame.addFrame("Misc",  64,  29)
    tMisc:Hide()

    -- Bouton parent « Misc »
    local btnMisc = pFrame.addButton("Misc",  64,  0, "inv_misc_enggizmos_swissarmy", MultiBot.L("tips.every.misc"))
    btnMisc.doLeft = function(self)
       MultiBot.ShowHideSwitch(tMisc)
    end

    -- Texture étoile
    local STAR_TEX = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"
    local y, dy = 0, 28
    -- Buttons inside the "Misc" sub-frame
	for _, data in ipairs{
		{ "Wipe", "Achievement_Halloween_Ghost_01", MultiBot.L("tips.every.wipe"), function(b)
		    MultiBot.ActionToTarget("wipe", b.getName())
          end
		},
		{ "Autogear", "inv_misc_enggizmos_30", MultiBot.L("tips.every.autogear"), function(b)
            StaticPopup_Show("MULTIBOT_AUTOGEAR_CONFIRM", b.getName(), nil, { target = b.getName(), selfAction = isSelfBot })
          end
        },
        -- NEW: Favorite toggle (per-character)
        -- { "Favorite",   "Interface\\RaidFrame\\ReadyCheck-Ready",  MultiBot.L("tips.every.favorite"), function(b)
        -- Favorite toggle (per-character) - étoile
        { "Favorite",   STAR_TEX,  MultiBot.L("tips.every.favorite"), function(b)
            local name = b.getName()
            MultiBot.ToggleFavorite(name)
            local tex = b.icon
            if tex then
              tex:SetTexture(MultiBot.SafeTexturePath(STAR_TEX))
			  local isFav = MultiBot.IsFavorite(name)
              -- Griser l’étoile quand favori, sinon couleur normale
              if tex.SetDesaturated then tex:SetDesaturated(isFav) end
              if tex.SetVertexColor then
                if isFav then tex:SetVertexColor(0.5, 0.5, 0.5) else tex:SetVertexColor(1, 1, 1) end
              end
            end
            -- If the current roster filter is "favorites", refresh the list
            local unitsBtn = MultiBot.frames and
                MultiBot.frames["MultiBar"] and
                MultiBot.frames["MultiBar"].buttons and
                MultiBot.frames["MultiBar"].buttons["Units"]
            if unitsBtn and unitsBtn.roster == "favorites" then
              unitsBtn.doLeft(unitsBtn, "favorites", unitsBtn.filter)
            end
          end
        },
        { "CharacterInfo", "inv_misc_note_05", MultiBot.L("tips.every.characterinfo", "Infos personnage"), function(b)
            if MultiBot.OpenCharacterInfo then
                MultiBot.OpenCharacterInfo(b.getName())
            end
        end
        },
		{ "Maintenance", "Achievement_Halloween_Smiley_01", MultiBot.L("tips.every.maintenance"), function(b)
            if isSelfBot then
                runEverySelfAction("MAINTENANCE", "")
            else
                SendChatMessage("maintenance", "WHISPER", nil, b.getName())
            end
        end
        },
	} do
		if not (isSelfBot and (data[1] == "Wipe" or data[1] == "CharacterInfo")) then
			local btn = tMisc.addButton(data[1], 0, y, data[2], data[3])
			btn.doLeft = data[4]
			y = y + dy
		end
	end


    -- Initialize the Favorite icon to the correct state if this bot is already saved
    do
      local favBtn = tMisc.buttons and tMisc.buttons["Favorite"]
      if favBtn then
        local name = favBtn.getName and favBtn.getName()
        local tex = favBtn.icon
        if tex then
          tex:SetTexture(MultiBot.SafeTexturePath(STAR_TEX))
          local isFav = (name and MultiBot.IsFavorite and MultiBot.IsFavorite(name)) and true or false
          -- Appliquer l’état visuel au chargement
          if tex.SetDesaturated then tex:SetDesaturated(isFav) end
          if tex.SetVertexColor then
            if isFav then tex:SetVertexColor(0.5, 0.5, 0.5) else tex:SetVertexColor(1, 1, 1) end
          end
        end
      end
    end
    -- MENU MISC END-----------------------------------------


	if not isSelfBot then
		pFrame.addButton("Summon", 94, 0, "ability_hunter_beastcall", MultiBot.L("tips.every.summon"))
		.doLeft = function(pButton)
			MultiBot.ActionToTarget("summon", pButton.getName())
		end

		pFrame.addButton("Uninvite", 124, 0, "inv_misc_grouplooking", MultiBot.L("tips.every.uninvite")).doShow()
		.doLeft = function(pButton)
			MultiBot.doSlash("/uninvite", pButton.getName())
		end

		pFrame.addButton("Invite", 124, 0, "inv_misc_groupneedmore", MultiBot.L("tips.every.invite")).doHide()
		.doLeft = function(pButton)
			MultiBot.doSlash("/invite", pButton.getName())
		end

	end

	local everyActionStartX = isSelfBot and 94 or 154

	pFrame.addButton("Food", everyActionStartX, 0, "inv_drink_24_sealwhey", MultiBot.L("tips.every.food")).setDisable()
	.doLeft = function(pButton)
		if(isSelfBot) then
			MultiBot.OnOffSelfBotStrategy(pButton, "nc +food,?", "nc -food,?")
		else
			MultiBot.OnOffActionToTarget(pButton, "nc +food,?", "nc -food,?", pButton.getName())
		end
	end

	pFrame.addButton("Loot", everyActionStartX + 30, 0, "inv_misc_coin_16", MultiBot.L("tips.every.loot")).setDisable()
	.doLeft = function(pButton)
		if(isSelfBot) then
			MultiBot.OnOffSelfBotStrategy(pButton, "nc +loot,?", "nc -loot,?")
		else
			MultiBot.OnOffActionToTarget(pButton, "nc +loot,?", "nc -loot,?", pButton.getName())
		end
	end

	pFrame.addButton("Gather", everyActionStartX + 60, 0, "trade_mining", MultiBot.L("tips.every.gather")).setDisable()
	.doLeft = function(pButton)
		if(isSelfBot) then
			MultiBot.OnOffSelfBotStrategy(pButton, "nc +gather,?", "nc -gather,?")
		else
			MultiBot.OnOffActionToTarget(pButton, "nc +gather,?", "nc -gather,?", pButton.getName())
		end
	end

	-- Common EveryBar strategy state must be initialized before the SelfBot-only early return.
	if(MultiBot.hasStrategy(pNormal, "food")) then pFrame.getButton("Food").setEnable() end
	if(MultiBot.hasStrategy(pNormal, "loot")) then pFrame.getButton("Loot").setEnable() end
	if(MultiBot.hasStrategy(pNormal, "gather")) then pFrame.getButton("Gather").setEnable() end

	-- Selfbot is not allowed to use the ordinary bot-only Tools --
	-- SelfBot keeps a compact chatless Combat menu and never falls through to BOT commands.
	if(isSelfBot) then
		local selfCombatFrame = pFrame.addFrame("CombatCommands", everyActionStartX + 90, 29, nil, 58, 114)
		selfCombatFrame:Hide()
		selfCombatFrame._mbDropdownManaged = true

		pFrame.addButton("Combat", everyActionStartX + 90, 0, "Ability_Warrior_BattleShout", MultiBot.L("tips.every.combat"))
		.doLeft = function()
			MultiBot.ShowHideSwitch(selfCombatFrame)
		end

		local focusButton = selfCombatFrame.addButton("CombatFocus", -28, 84, "Ability_Hunter_MasterMarksman", MultiBot.L("tips.every.combatfocus"))
		focusButton.setDisable()
		focusButton.doLeft = function(pButton)
			MultiBot.OnOffSelfBotStrategy(pButton, "co +focus,?", "co -focus,?")
		end

		local function addSelfWaitButton(name, posX, posY, tip, value)
			local button = selfCombatFrame.addButton(name, posX, posY, "Spell_Holy_BorrowedTime", tip)
			button.doLeft = function()
				runEverySelfAction("WAIT_ATTACK_TIME", tostring(value))
			end
		end

		addSelfWaitButton("CombatWait0", -28, 56, MultiBot.L("tips.every.combatwait0"), 0)
		addSelfWaitButton("CombatWait3", 0, 56, MultiBot.L("tips.every.combatwait3"), 3)
		addSelfWaitButton("CombatWait5", -28, 28, MultiBot.L("tips.every.combatwait5"), 5)
		addSelfWaitButton("CombatWait10", 0, 28, MultiBot.L("tips.every.combatwait10"), 10)

		if(MultiBot.hasStrategy(pCombat, "focus")) then focusButton.setEnable() end
		return
	end

	pFrame.addButton("Inventory", 244, 0, "inv_misc_bag_08", MultiBot.L("tips.every.inventory")).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			MultiBot.inventory:Hide()
			pButton.setDisable()
			if(MultiBot.SyncToolWindowButtons) then
				MultiBot.SyncToolWindowButtons(nil, nil)
			end
			return
		end

		if(MultiBot.RequestBotInventory and MultiBot.RequestBotInventory(pButton.getName())) then
			if(MultiBot.SyncToolWindowButtons) then
				MultiBot.SyncToolWindowButtons(pButton.getName(), "Inventory")
			end
			return
		end

		pButton.setEnable()
		if(MultiBot.SyncToolWindowButtons) then
			MultiBot.SyncToolWindowButtons(pButton.getName(), "Inventory")
		end
	end

	pFrame.addButton("Outfits", 364, 0, "inv_chest_chain_15", MultiBot.L("tips.every.outfits", "Outfits")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OpenBotOutfits) then
			MultiBot.OpenBotOutfits(pButton.getName(), pButton)
		end
	end

	pFrame.addButton("Trainer", 394, 0, "spell_holy_magicalsentry", MultiBot.L("tips.every.trainer", "Trainer")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OpenBotTrainer) then
			MultiBot.OpenBotTrainer(pButton.getName(), pButton)
		end
	end

	local botName = pFrame.getName and pFrame.getName() or nil
	if MultiBot.BuildBotRTIUI and botName and botName ~= "" then
		MultiBot.BuildBotRTIUI(pFrame, botName, 424, 0)
	end

	local combatFrame = pFrame.addFrame("CombatCommands", 454, 29, nil, 58, 114)
	combatFrame:Hide()
	combatFrame._mbDropdownManaged = true

	pFrame.addButton("Combat", 454, 0, "Ability_Warrior_BattleShout", MultiBot.L("tips.every.combat"))
	.doLeft = function()
		MultiBot.ShowHideSwitch(combatFrame)
	end

	local enchantButton = pFrame.addButton("Enchant", 484, 0, "trade_engraving", MultiBot.L("lootmaster.profession.enchanting", "Enchanting"))
	enchantButton.setDisable()
	enchantButton.doHide()
	enchantButton.doLeft = function(pButton)
		if MultiBot.OpenBotEnchanting then
			MultiBot.OpenBotEnchanting(pButton.getName(), pButton)
		end
	end
	if MultiBot.IsBotEnchantingServiceAvailable and MultiBot.IsBotEnchantingServiceAvailable(botName) then
		enchantButton.setEnable()
		enchantButton.doShow()
	end

	addBotCombatButton(combatFrame, "CombatFocus", -28, 84, "Ability_Hunter_MasterMarksman", MultiBot.L("tips.every.combatfocus"), "co +focus", "co -focus")
	addBotCombatButton(combatFrame, "CombatAoe", 0, 84, "Spell_Fire_SelfDestruct", MultiBot.L("tips.every.combataoe"), "co +aoe", "co -aoe")
	addBotCombatButton(combatFrame, "CombatDpsAssist", -28, 56, "Ability_Hunter_Assassinate2", MultiBot.L("tips.every.combatdpsassist"), "co +dps assist", "co -dps assist")
	addBotCombatButton(combatFrame, "CombatTankAssist", 0, 56, "Ability_Warrior_DefensiveStance", MultiBot.L("tips.every.combattankassist"), "co +tank assist", "co -tank assist")
	addBotCombatButton(combatFrame, "CombatWait0", -28, 28, "Spell_Holy_BorrowedTime", MultiBot.L("tips.every.combatwait0"), "wait for attack time 0")
	addBotCombatButton(combatFrame, "CombatWait3", 0, 28, "Spell_Holy_BorrowedTime", MultiBot.L("tips.every.combatwait3"), "wait for attack time 3")
	addBotCombatButton(combatFrame, "CombatWait5", -28, 0, "Spell_Holy_BorrowedTime", MultiBot.L("tips.every.combatwait5"), "wait for attack time 5")
	addBotCombatButton(combatFrame, "CombatWait10", 0, 0, "Spell_Holy_BorrowedTime", MultiBot.L("tips.every.combatwait10"), "wait for attack time 10")

	pFrame.addButton("Spellbook", 274, 0, "inv_misc_book_09", MultiBot.L("tips.every.spellbook")).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			MultiBot.spellbook:Hide()
			pButton.setDisable()
		else
			local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
			for key, value in pairs(MultiBot.index.actives) do
				if(tUnits.buttons[value].name ~= UnitName("player")) then
					tUnits.frames[value].getButton("Spellbook").setDisable()
				end
			end

			pButton.setEnable()
			MultiBot.spellbook.name = pButton.getName()

			local tBridge = MultiBot and MultiBot.bridge or nil
			local tComm = MultiBot and MultiBot.Comm or nil
			if(tBridge and tBridge.connected and tComm and tComm.RequestSpellbook and tComm.RequestSpellbook(pButton.getName())) then
				tUnits.buttons[MultiBot.spellbook.name].waitFor = ""
				return
			end

			if(MultiBot.allowLegacyChatFallback == true) then
				tUnits.buttons[MultiBot.spellbook.name].waitFor = "SPELLBOOK"
				SendChatMessage("spells", "WHISPER", nil, pButton.getName())
			else
				tUnits.buttons[MultiBot.spellbook.name].waitFor = ""
			end
		end
	end

	pFrame.addButton("Talent", 304, 0, "ability_marksmanship", MultiBot.L("tips.every.talent")).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			pButton.setDisable()
			MultiBot.talent:Hide()
		elseif(UnitLevel(MultiBot.toUnit(pButton.getName())) < 10) then
			SendChatMessage(MultiBot.L("info.talent.Level"), "SAY")
		elseif(CheckInteractDistance(MultiBot.toUnit(pButton.getName()), 1) == nil) then
			SendChatMessage(MultiBot.L("info.talent.OutOfRange"), "SAY")
		else
			MultiBot.talent:Hide()
			MultiBot.talent.doClear()

			local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
			for key, value in pairs(MultiBot.index.actives) do
				if(tUnits.buttons[value].name ~= UnitName("player")) then
					tUnits.frames[value].getButton("Talent").setDisable()
				end
			end

			InspectUnit(MultiBot.toUnit(pButton.getName()))
			pButton.setEnable()

			MultiBot.talent.name = pButton.getName()
			MultiBot.talent.class = pButton.getClass()
			MultiBot.auto.talent = true
		end
	end

	-- BOUTON SETTALENTS : toggle affichage de la barre des specs
    local btn = pFrame
        .addButton("SetTalents", 334, 0, "inv_sword_22", MultiBot.L("tips.every.settalent"))
    -- état initial : toujours désactivé (zen, pas de barre affichée au load)
    btn:setDisable()

    btn.doLeft = function(self)
      -- si le dropdown existe et est visible → on le ferme
      if MultiBot.spec.dropdown and MultiBot.spec.dropdown:IsShown() then
        MultiBot.spec:HideDropdown()
        self:setDisable()
      else
        -- sinon on envoie la requête au bot, et on active le bouton
        MultiBot.spec:RequestList(self:getName(), self)
        self:setEnable()
      end
    end

-- STRATEGIES --
	if not isSelfBot then
		MultiBot.RefreshEveryGroupActionFrame(pFrame)
	end
end

local function sendCommonCombatStrategy(pButton, command)
	local botName = pButton and pButton.getName and pButton.getName() or nil
	if type(botName) ~= "string" or botName == "" then
		return false
	end

	if MultiBot.Comm and type(MultiBot.Comm.RunCombatCommand) == "function" then
		return MultiBot.Comm.RunCombatCommand("BOT", botName, command)
	end

	SendChatMessage(command, "WHISPER", nil, botName)
	return true
end

local function addCommonCombatStrategyButton(pFrame, pCombat, tFrame, buttonName, y, icon, tipKey, strategyName)
	if not pFrame or not tFrame or not tFrame.addButton then
		return
	end

	local plusCommand = "co +" .. strategyName
	local minusCommand = "co -" .. strategyName

	local button = tFrame.addButton(
		buttonName,
		0,
		y,
		"Interface\\Icons\\" .. icon,
		MultiBot.L(tipKey)
	):setDisable()

	button.doLeft = function(self)
		local botName = self.getName and self.getName() or ""
		if MultiBot.IsSelfBotStrategyTarget
			and MultiBot.IsSelfBotStrategyTarget(botName) then
			MultiBot.OnOffUnitStrategy(self, plusCommand, minusCommand, botName)
			return
		end

		if MultiBot.OnOffSwitch(self) then
			sendCommonCombatStrategy(self, plusCommand)
		else
			sendCommonCombatStrategy(self, minusCommand)
		end
	end

	if MultiBot.hasStrategy(pCombat, strategyName) then
		pFrame.getButton(buttonName).setEnable()
	end
end

function MultiBot.AddCommonCombatStrategyButtons(pFrame, tFrame, pCombat, yOffset)
	local y = tonumber(yOffset) or 0

	addCommonCombatStrategyButton(pFrame, pCombat, tFrame, "AvoidAoe", y, "spell_shadow_antishadow.blp", "tips.every.strategy.avoidaoe", "avoid aoe")
	addCommonCombatStrategyButton(pFrame, pCombat, tFrame, "SaveMana", y + 26, "spell_frost_manarecharge.blp", "tips.every.strategy.savemana", "save mana")
	addCommonCombatStrategyButton(pFrame, pCombat, tFrame, "Threat", y + 52, "ability_warrior_challange.blp", "tips.every.strategy.threat", "threat")
	addCommonCombatStrategyButton(pFrame, pCombat, tFrame, "Behind", y + 78, "ability_backstab.blp", "tips.every.strategy.behind", "behind")
end