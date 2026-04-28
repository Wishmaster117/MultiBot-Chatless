-- Confirmation popup for Autogear
if not StaticPopupDialogs["MULTIBOT_AUTOGEAR_CONFIRM"] then
  StaticPopupDialogs["MULTIBOT_AUTOGEAR_CONFIRM"] = {
    text = MultiBot.L("tips.every.autogearpopup"),
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self, data)
      if data and data.target then
        SendChatMessage("autogear", "WHISPER", nil, data.target)
      end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3, -- évite les conflits d’index avec d’autres popups
  }
end

local function showEveryMessage(message)
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

MultiBot.addEvery = function(pFrame, pCombat, pNormal)

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
            StaticPopup_Show("MULTIBOT_AUTOGEAR_CONFIRM", b.getName(), nil, { target = b.getName() })
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
		{ "Maintenance", "Achievement_Halloween_Smiley_01", MultiBot.L("tips.every.maintenance"), function(b)
            SendChatMessage("maintenance", "WHISPER", nil, b.getName())
        end
        },
	} do
		local btn = tMisc.addButton(data[1], 0, y, data[2], data[3])
		btn.doLeft = data[4]
		y = y + dy
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

	pFrame.addButton("Summon", 94, 0, "ability_hunter_beastcall", MultiBot.L("tips.every.summon"))
	.doLeft = function(pButton)
		MultiBot.ActionToTarget("summon", pButton.getName())
	end

	pFrame.addButton("Uninvite", 124, 0, "inv_misc_grouplooking", MultiBot.L("tips.every.uninvite")).doShow()
	.doLeft = function(pButton)
		MultiBot.doSlash("/uninvite", pButton.getName())
		pButton.getButton("Invite").doShow()
		pButton.doHide()
	end

	pFrame.addButton("Invite", 124, 0, "inv_misc_groupneedmore", MultiBot.L("tips.every.invite")).doHide()
	.doLeft = function(pButton)
		MultiBot.doSlash("/invite", pButton.getName())
		pButton.getButton("Uninvite").doShow()
		pButton.doHide()
	end

	pFrame.addButton("Food", 154, 0, "inv_drink_24_sealwhey", MultiBot.L("tips.every.food")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +food,?", "nc -food,?", pButton.getName())
	end

	pFrame.addButton("Loot", 184, 0, "inv_misc_coin_16", MultiBot.L("tips.every.loot")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +loot,?", "nc -loot,?", pButton.getName())
	end

	pFrame.addButton("Gather", 214, 0, "trade_mining", MultiBot.L("tips.every.gather")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +gather,?", "nc -gather,?", pButton.getName())
	end

	-- Selfbot is not allowed to use these Tools --
	if(pFrame.getName() == UnitName("player")) then return end

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

	local botName = pFrame.getName and pFrame.getName() or nil
	if MultiBot.BuildBotRTIUI and botName and botName ~= "" then
		MultiBot.BuildBotRTIUI(pFrame, botName, 394, 0)
	end

	local combatFrame = pFrame.addFrame("CombatCommands", 424, 29, nil, 58, 114)
	combatFrame:Hide()
	combatFrame._mbDropdownManaged = true

	pFrame.addButton("Combat", 424, 0, "Ability_Warrior_BattleShout", MultiBot.L("tips.every.combat"))
	.doLeft = function()
		MultiBot.ShowHideSwitch(combatFrame)
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

	if(MultiBot.isInside(pNormal, "food")) then pFrame.getButton("Food").setEnable() end
	if(MultiBot.isInside(pNormal, "loot")) then pFrame.getButton("Loot").setEnable() end
	if(MultiBot.isInside(pNormal, "gather")) then pFrame.getButton("Gather").setEnable() end
end