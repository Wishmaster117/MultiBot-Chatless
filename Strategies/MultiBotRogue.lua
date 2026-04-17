MultiBot.addRogue = function(pFrame, pCombat, pNormal)
	pFrame.addButton("DpsControl", 0, 0, "ability_warrior_challange", MultiBot.L("tips.rogue.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local tFrame = pFrame.addFrame("DpsControl", -2, 30)
	tFrame:Hide()

	tFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.rogue.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	tFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.rogue.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	tFrame.addButton("Dps", 0, 52, "spell_holy_divinepurpose", MultiBot.L("tips.rogue.dps.dps")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())
	end

	-- STEALTH (maintenir le camouflage HORS COMBAT)
	tFrame.addButton("Stealth", 0, 78, "ability_stealth",  MultiBot.L("tips.rogue.dps.stealth")).setDisable()
	.doLeft = function(pButton)
		-- "stealth" est une stratégie non-combat : on la pousse côté pNormal
		MultiBot.OnOffActionToTarget(pButton, "co +stealth,?", "co -stealth,?", pButton.getName())
	end

	-- STEALTHED (comportement EN CAMOUFLAGE en combat)
	tFrame.addButton("Stealthed", 0, 104, "ability_sap", MultiBot.L("tips.rogue.dps.stealthed")).setDisable()
	.doLeft = function(pButton)
		-- Pour entrer en mode "stealthed", on coupe dps et on force stealthed ; l'inverse pour repasser en dps.
		if(MultiBot.OnOffActionToTarget(pButton, "co +stealthed,?", "co -stealthed,?", pButton.getName())) then
			pButton.getButton("Dps")      .setDisable()
			pButton.getButton("DpsAoe")   .setDisable()
			pButton.getButton("DpsAssist")   .setDisable()
		end
	end

	-- BOOST (active les CD offensifs : Adrenaline Rush, Blade Flurry, etc.)
	tFrame.addButton("Boost", 0, 130, "ability_mage_potentspirit", MultiBot.L("tips.rogue.dps.boost")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +boost,?", "co -boost,?", pButton.getName())
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -30, 0, "ability_warrior_innerrage", MultiBot.L("tips.rogue.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "dps")) then pFrame.getButton("Dps").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.isInside(pNormal, "stealth")) then pFrame.getButton("Stealth").setEnable() end
	if(MultiBot.isInside(pCombat, "stealthed")) then pFrame.getButton("Stealthed").setEnable() end
	if(MultiBot.isInside(pCombat, "boost")) then pFrame.getButton("Boost").setEnable() end
end