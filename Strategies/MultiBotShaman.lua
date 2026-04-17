MultiBot.addShaman = function(pFrame, pCombat, pNormal)
	pFrame.addButton("Heal", 0, 0, "spell_holy_aspiration", MultiBot.L("tips.shaman.heal")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +heal,?", "co -heal,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Melee").setDisable()
		end
	end

	-- NON-COMBAT-TOTEM --

	local nonCombatTotemButton = pFrame.addButton(
		"NonCombatTotem", -30, 0, "spell_nature_manaregentotem",
		MultiBot.L("tips.shaman.ntotem.master"))
	nonCombatTotemButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["NonCombatTotem"])
	end

	local nonCombatTotemFrame = pFrame.addFrame("NonCombatTotem", -32, 30)
	nonCombatTotemFrame:Hide()

	nonCombatTotemFrame.addButton(
		"NonCombatMana", 0, 0, "spell_nature_manaregentotem",
		MultiBot.L("tips.shaman.ntotem.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatTotem", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("NonCombatTotem").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bmana,?", "nc -bmana,?", btn.getName())
		end
	end

	nonCombatTotemFrame.addButton(
		"NonCombatDps", 0, 26, "spell_nature_windfury",
		MultiBot.L("tips.shaman.ntotem.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatTotem", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("NonCombatTotem").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bdps,?", "nc -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:NON-COMBAT-TOTEM --

	if(MultiBot.isInside(pNormal, "bmana")) then
		nonCombatTotemButton.setTexture("spell_nature_manaregentotem").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
		nonCombatTotemButton.setTexture("spell_nature_windfury").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end

	-- COMBAT-TOTEM --

	local combatTotemButton = pFrame.addButton(
		"CombatTotem", -60, 0, "spell_nature_manaregentotem",
		MultiBot.L("tips.shaman.ctotem.master"))
	combatTotemButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["CombatTotem"])
	end

	local combatTotemFrame = pFrame.addFrame("CombatTotem", -62, 30)
	combatTotemFrame:Hide()

	combatTotemFrame.addButton(
		"CombatMana", 0, 0, "spell_nature_manaregentotem",
		MultiBot.L("tips.shaman.ctotem.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatTotem", pButton.texture, "co +bmana,?", pButton.getName())
		pButton.getButton("CombatTotem").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bmana,?", "co -bmana,?", btn.getName())
		end
	end

	combatTotemFrame.addButton(
		"CombatDps", 0, 26, "spell_nature_windfury",
		MultiBot.L("tips.shaman.ctotem.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatTotem", pButton.texture, "co +bdps,?", pButton.getName())
		pButton.getButton("CombatTotem").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bdps,?", "co -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:COMBAT-TOTEM --

	if(MultiBot.isInside(pCombat, "bmana")) then
		combatTotemButton.setTexture("spell_nature_manaregentotem").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bmana,?", "co -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bdps")) then
		combatTotemButton.setTexture("spell_nature_windfury").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bdps,?", "co -bdps,?", pButton.getName())
		end
	end

	-- PLAYBOOK --

	pFrame.addButton("Playbook", -90, 0, "inv_misc_book_06", MultiBot.L("tips.shaman.playbook.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
	end

	local playbookFrame = pFrame.addFrame("Playbook", -92, 30)
	playbookFrame:Hide()

	playbookFrame.addButton(
		"Totems", 0, 0, "inv_relics_totemofrebirth",
		MultiBot.L("tips.shaman.playbook.totems")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +totems,?", "co -totems,?", pButton.getName())
	end

	playbookFrame.addButton(
		"CasterAoe", 0, 26, "spell_nature_lightningoverload",
		MultiBot.L("tips.shaman.playbook.casterAoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +caster aoe,?", "co -caster aoe,?", pButton.getName())
	end

	playbookFrame.addButton("Caster", 0, 52, "spell_nature_lightning", MultiBot.L("tips.shaman.playbook.caster")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +caster,?", "co -caster,?", pButton.getName())) then
			pButton.getButton("Melee").setDisable()
			pButton.getButton("Heal").setDisable()
		end
	end

	playbookFrame.addButton(
		"MeleeAoe", 0, 78, "ability_warrior_shockwave",
		MultiBot.L("tips.shaman.playbook.meleeAoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +melee aoe,?", "co -melee aoe,?", pButton.getName())
	end

	playbookFrame.addButton("Melee", 0, 104, "ability_parry", MultiBot.L("tips.shaman.playbook.melee")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +melee,?", "co -melee,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Heal").setDisable()
		end
	end

	-- UTILITAIRE : CURE --
	pFrame.addButton("Cure", -180, 0, "Ability_Creature_Poison_02", MultiBot.L("tips.shaman.playbook.cure")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +cure,?", "co -cure,?", pButton.getName())
	end

	-- STRATEGIES:PLAYBOOK --

	if(MultiBot.isInside(pCombat, "heal")) then pFrame.getButton("Heal").setEnable() end
	if(MultiBot.isInside(pCombat, "melee,")) then pFrame.getButton("Melee").setEnable() end
	if(MultiBot.isInside(pCombat, "totems")) then pFrame.getButton("Totems").setEnable() end
	if(MultiBot.isInside(pCombat, "caster,")) then pFrame.getButton("Caster").setEnable() end
	if(MultiBot.isInside(pCombat, "melee aoe")) then pFrame.getButton("MeleeAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "caster aoe")) then pFrame.getButton("CasterAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "cure")) then pFrame.getButton("Cure").setEnable() end

	-- DPS --

	pFrame.addButton("DpsControl", -120, 0, "ability_warrior_challange", MultiBot.L("tips.shaman.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local dpsControlFrame = pFrame.addFrame("DpsControl", -122, 30)
	dpsControlFrame:Hide()

	dpsControlFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.shaman.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsControlFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.shaman.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	-- HEALER DPS --
	dpsControlFrame.addButton("HealerDps", 0, 52, "INV_Alchemy_Elixir_02", MultiBot.L("tips.shaman.dps.healerdps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +healer dps,?", "co -healer dps,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -150, 0, "ability_warrior_innerrage", MultiBot.L("tips.shaman.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "healer dps")) then pFrame.getButton("HealerDps").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end

end