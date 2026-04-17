MultiBot.addHunter = function(pFrame, pCombat, pNormal)
	local nonCombatAspectButton = pFrame.addButton("NonCombatAspect", 0, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.naspect.master"))
	nonCombatAspectButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["NonCombatAspect"])
	end

	local nonCombatAspectFrame = pFrame.addFrame("NonCombatAspect", -2, 30)
	nonCombatAspectFrame:Hide()

	nonCombatAspectFrame.addButton("NonCombatNature", 0, 0, "spell_nature_protectionformnature", MultiBot.L("tips.hunter.naspect.rnature"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +rnature,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +rnature,?", "nc -rnature,?", btn.getName())
		end
	end

	nonCombatAspectFrame.addButton("NonCombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.L("tips.hunter.naspect.bspeed"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bspeed,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bspeed,?", "nc -bspeed,?", btn.getName())
		end
	end

	nonCombatAspectFrame.addButton("NonCombatMana", 0, 52, "ability_hunter_aspectoftheviper", MultiBot.L("tips.hunter.naspect.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bmana,?", "nc -bmana,?", btn.getName())
		end
	end

	nonCombatAspectFrame.addButton("NonCombatDps", 0, 78, "ability_hunter_pet_dragonhawk", MultiBot.L("tips.hunter.naspect.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bdps,?", "nc -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:NON-COMBAT-BUFF --

	if(MultiBot.isInside(pNormal, "rnature")) then
		nonCombatAspectButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rnature,?", "nc -rnature,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bspeed")) then
		nonCombatAspectButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bspeed,?", "nc -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bmana")) then
		nonCombatAspectButton.setTexture("ability_hunter_aspectoftheviper").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
		nonCombatAspectButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
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
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +rnature,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +rnature,?", "co -rnature,?", btn.getName())
		end
	end

	combatAspectFrame.addButton("CombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.L("tips.hunter.caspect.bspeed"))
    .doLeft = function(pButton)
        MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bspeed,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bspeed,?", "co -bspeed,?", btn.getName())
		end
	end

	combatAspectFrame.addButton("CombatMana", 0, 52, "ability_hunter_aspectoftheviper", MultiBot.L("tips.hunter.caspect.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bmana,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bmana,?", "co -bmana,?", btn.getName())
		end
	end

	combatAspectFrame.addButton("CombatDps", 0, 78, "ability_hunter_pet_dragonhawk", MultiBot.L("tips.hunter.caspect.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bdps,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bdps,?", "co -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:COMABT-ASPECT --

	if(MultiBot.isInside(pCombat, "rnature")) then
		combatAspectButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rnature,?", "co -rnature,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bspeed")) then
		combatAspectButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bspeed,?", "co -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bmana")) then
		combatAspectButton.setTexture("ability_hunter_aspectoftheviper").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bmana,?", "co -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bdps")) then
		combatAspectButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bdps,?", "co -bdps,?", pButton.getName())
		end
	end

	-- DPS --

	pFrame.addButton("DpsControl", -60, 0, "ability_warrior_challange", MultiBot.L("tips.hunter.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local dpsFrame = pFrame.addFrame("DpsControl", -62, 30)
	dpsFrame:Hide()

	dpsFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.hunter.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.L("tips.hunter.dps.dpsDebuff")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps debuff,?", "co -dps debuff,?", pButton.getName())
	end

	dpsFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.L("tips.hunter.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	dpsFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.L("tips.hunter.dps.dps")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())
	end

	dpsFrame.addButton("TrapWeave", 0, 104, "ability_ensnare", MultiBot.L("tips.hunter.trapweave")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +trap weave,?", "co -trap weave,?", pButton.getName())
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -90, 0, "ability_warrior_innerrage", MultiBot.L("tips.hunter.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "dps,")) then pFrame.getButton("Dps").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "dps debuff")) then pFrame.getButton("DpsDebuff").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "trap weave")) then pFrame.getButton("TrapWeave").setEnable() end
end