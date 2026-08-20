MultiBot.addHunter = function(pFrame, pCombat, pNormal)
	local nonCombatAspectButton = pFrame.addButton("NonCombatAspect", 0, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.naspect.master"))
	nonCombatAspectButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["NonCombatAspect"])
	end

	local nonCombatAspectFrame = pFrame.addFrame("NonCombatAspect", -2, 30)
	nonCombatAspectFrame:Hide()

	nonCombatAspectFrame.addButton("NonCombatNature", 0, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.naspect.rnature"))
	.doLeft = function(pButton)
		MultiBot.SelectToUnitStrategy(pButton.get(), "NonCombatAspect", pButton.texture, "nc +rnature,?", pButton.getName(), function()
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "nc +rnature,?", "nc -rnature,?", btn.getName())
		end
		end)
	end

	nonCombatAspectFrame.addButton("NonCombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.L("tips.hunter.naspect.bspeed"))
	.doLeft = function(pButton)
		MultiBot.SelectToUnitStrategy(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bspeed,?", pButton.getName(), function()
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "nc +bspeed,?", "nc -bspeed,?", btn.getName())
		end
		end)
	end

	nonCombatAspectFrame.addButton("NonCombatDps", 0, 52, "ability_hunter_pet_dragonhawk", MultiBot.L("tips.hunter.naspect.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToUnitStrategy(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bdps,?", pButton.getName(), function()
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "nc +bdps,?", "nc -bdps,?", btn.getName())
		end
		end)
	end

	-- STRATEGIES:NON-COMBAT-BUFF --

	if(MultiBot.hasStrategy(pNormal, "rnature")) then
		nonCombatAspectButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "nc +rnature,?", "nc -rnature,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pNormal, "bspeed")) then
		nonCombatAspectButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "nc +bspeed,?", "nc -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pNormal, "bdps")) then
		nonCombatAspectButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end

	-- COMABT-BUFF --

	local combatAspectButton = pFrame.addButton("CombatAspect", -30, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.caspect.master"))
	combatAspectButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["CombatAspect"])
	end

	local combatAspectFrame = pFrame.addFrame("CombatAspect", -32, 30)
	combatAspectFrame:Hide()

	combatAspectFrame.addButton("CombatNature", 0, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.caspect.rnature"))
	.doLeft = function(pButton)
		MultiBot.SelectToUnitStrategy(pButton.get(), "CombatAspect", pButton.texture, "co +rnature,?", pButton.getName(), function()
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "co +rnature,?", "co -rnature,?", btn.getName())
		end
		end)
	end

	combatAspectFrame.addButton("CombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.L("tips.hunter.caspect.bspeed"))
    .doLeft = function(pButton)
        MultiBot.SelectToUnitStrategy(pButton.get(), "CombatAspect", pButton.texture, "co +bspeed,?", pButton.getName(), function()
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "co +bspeed,?", "co -bspeed,?", btn.getName())
		end
		end)
	end

	combatAspectFrame.addButton("CombatDps", 0, 52, "ability_hunter_pet_dragonhawk", MultiBot.L("tips.hunter.caspect.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToUnitStrategy(pButton.get(), "CombatAspect", pButton.texture, "co +bdps,?", pButton.getName(), function()
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffUnitStrategy(btn, "co +bdps,?", "co -bdps,?", btn.getName())
		end
		end)
	end

	-- STRATEGIES:COMABT-ASPECT --

	if(MultiBot.hasStrategy(pCombat, "rnature")) then
		combatAspectButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "co +rnature,?", "co -rnature,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pCombat, "bspeed")) then
		combatAspectButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "co +bspeed,?", "co -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pCombat, "bdps")) then
		combatAspectButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffUnitStrategy(pButton, "co +bdps,?", "co -bdps,?", pButton.getName())
		end
	end

	-- PLAYBOOK --

	pFrame.addButton("Playbook", -60, 0, "inv_misc_book_06", MultiBot.L("tips.hunter.playbook.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
	end

	local playbookFrame = pFrame.addFrame("Playbook", -62, 30)
	playbookFrame:Hide()

	local function selectExclusiveHunterSpec(pButton, pCommand, pOtherOne, pOtherTwo)
		local bridgeSync = MultiBot.bridge
			and MultiBot.bridge.connected == true
			and MultiBot.Comm
			and MultiBot.Comm.RequestState

		-- En mode chat historique, force la branche d'activation même si la
		-- spécialisation cliquée est déjà active dans un état cumulé.
		if(not bridgeSync and pButton.state) then
			pButton.setDisable()
		end

		if(MultiBot.OnOffUnitStrategy(pButton, pCommand, pCommand, pButton.getName())) then
			pButton.getButton(pOtherOne).setDisable()
			pButton.getButton(pOtherTwo).setDisable()
		end
	end

	playbookFrame.addButton("Aoe", 0, 0, "spell_holy_surgeoflight", MultiBot.L("tips.hunter.playbook.aoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffUnitStrategy(pButton, "co +aoe,?", "co -aoe,?", pButton.getName())
	end

	playbookFrame.addButton("BeastMastery", 0, 26, "ability_hunter_pet_dragonhawk", MultiBot.L("tips.hunter.playbook.bm")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveHunterSpec(pButton, "co -mm,-surv,+bm,?", "Marksmanship", "Survival")
	end

	playbookFrame.addButton("Marksmanship", 0, 52, "spell_holy_divinepurpose", MultiBot.L("tips.hunter.playbook.mm")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveHunterSpec(pButton, "co -bm,-surv,+mm,?", "BeastMastery", "Survival")
	end

	playbookFrame.addButton("Survival", 0, 78, "ability_ensnare", MultiBot.L("tips.hunter.playbook.surv")).setDisable()
	.doLeft = function(pButton)
		selectExclusiveHunterSpec(pButton, "co -bm,-mm,+surv,?", "BeastMastery", "Marksmanship")
	end

	-- STRATEGIES:PLAYBOOK --

	if(MultiBot.hasStrategy(pCombat, "aoe")) then pFrame.getButton("Aoe").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "bm")) then pFrame.getButton("BeastMastery").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "mm")) then pFrame.getButton("Marksmanship").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "surv")) then pFrame.getButton("Survival").setEnable() end

	-- DPS --

	pFrame.addButton("DpsControl", -90, 0, "ability_warrior_challange", MultiBot.L("tips.hunter.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local dpsFrame = pFrame.addFrame("DpsControl", -92, 30)
	dpsFrame:Hide()

	dpsFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.hunter.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.hunter.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	dpsFrame.addButton("TrapWeave", 0, 52, "ability_ensnare", MultiBot.L("tips.hunter.trapweave")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffUnitStrategy(pButton, "co +trap weave,?", "co -trap weave,?", pButton.getName())
	end

	if MultiBot.AddCommonCombatStrategyButtons then
		MultiBot.AddCommonCombatStrategyButtons(pFrame, dpsFrame, pCombat, 78)
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -120, 0, "ability_warrior_innerrage", MultiBot.L("tips.hunter.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.hasStrategy(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "trap weave")) then pFrame.getButton("TrapWeave").setEnable() end
end