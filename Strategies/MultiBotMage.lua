MultiBot.addMage = function(pFrame, pCombat, pNormal)
	local tButton = pFrame.addButton("Buff", 0, 0, "inv_elemental_primal_mana", MultiBot.L("tips.mage.buff.master"))
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["Buff"])
	end

    local buffFrame = pFrame.addFrame("Buff", -2, 30)
    buffFrame:Hide()

    buffFrame.addButton("NonCombatMana", 0, 0, "inv_elemental_primal_mana", MultiBot.L("tips.mage.buff.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bmana,?", pButton.getName())
        pButton.getButton("Buff").doRight = function(btn)
            MultiBot.OnOffActionToTarget(btn, "nc +bmana,?", "nc -bmana,?", btn.getName())
		end
	end

    buffFrame.addButton("NonCombatDps", 0, 26, "inv_elemental_primal_nether", MultiBot.L("tips.mage.buff.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bdps,?", pButton.getName())
        pButton.getButton("Buff").doRight = function(btn)
            MultiBot.OnOffActionToTarget(btn, "nc +bdps,?", "nc -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:BUFF --

	if(MultiBot.hasStrategy(pNormal, "bmana")) then
		tButton.setTexture("inv_elemental_primal_mana").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pNormal, "bdps")) then
		tButton.setTexture("inv_elemental_primal_nether").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end

	-- PLAYBOOK --

    pFrame.addButton("Playbook", -30, 0, "inv_misc_book_06", MultiBot.L("tips.mage.playbook.master"))
    .doLeft = function(pButton)
        MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
    end

    local playbookFrame = pFrame.addFrame("Playbook", -32, 30)
    playbookFrame:Hide()

    playbookFrame.addButton("Aoe", 0, 0, "spell_arcane_starfire", MultiBot.L("tips.mage.playbook.aoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffUnitStrategy(pButton, "co +aoe,?", "co -aoe,?", pButton.getName())
	end

	playbookFrame.addButton("Arcane", 0, 26, "ability_mage_arcanebarrage", MultiBot.L("tips.mage.playbook.arcane")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +arcane,?", "co -arcane,?", pButton.getName())) then
			pButton.getButton("Frost").setDisable()
			pButton.getButton("Fire").setDisable()
		end
	end

	playbookFrame.addButton("Frost", 0, 52, "spell_frost_frostbolt02", MultiBot.L("tips.mage.playbook.frost")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +frost,?", "co -frost,?", pButton.getName())) then
			pButton.getButton("Arcane").setDisable()
			pButton.getButton("Fire").setDisable()
		end
	end

	playbookFrame.addButton("Fire", 0, 78, "spell_fire_fireball02", MultiBot.L("tips.mage.playbook.fire")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +fire,?", "co -fire,?", pButton.getName())) then
			pButton.getButton("Arcane").setDisable()
			pButton.getButton("Frost").setDisable()
		end
	end
	-- missing Frostfire & Firestarter --
	playbookFrame.addButton("FrostFire", 0, 104, "ability_mage_frostfirebolt", MultiBot.L("tips.mage.playbook.frostfire")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +frostfire,?", "co -frostfire,?", pButton.getName())) then
			pButton.getButton("Arcane").setDisable()
			pButton.getButton("Frost").setDisable()
			pButton.getButton("Fire").setDisable()
		end
	end

	playbookFrame.addButton("Firestarter", 0, 130, "ability_mage_firestarter", MultiBot.L("tips.mage.playbook.firestarter")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffUnitStrategy(pButton, "co +firestarter,?", "co -firestarter,?", pButton.getName())
	end

	-- STRATEGIES:PLAYBOOK --

	if(MultiBot.hasStrategy(pCombat, "aoe")) then pFrame.getButton("Aoe").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "arcane")) then pFrame.getButton("Arcane").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "frost")) then pFrame.getButton("Frost").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "fire")) then pFrame.getButton("Fire").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "frostfire")) then pFrame.getButton("FrostFire").setEnable() end
	if(MultiBot.hasStrategy(pCombat, "firestarter")) then pFrame.getButton("Firestarter").setEnable() end

	-- DPS --

    pFrame.addButton("DpsControl", -60, 0, "ability_warrior_challange", MultiBot.L("tips.mage.dps.master"))
    .doLeft = function(pButton)
        MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
    end

    local dpsControlFrame = pFrame.addFrame("DpsControl", -62, 30)
    dpsControlFrame:Hide()

    dpsControlFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.mage.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsControlFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.mage.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	if MultiBot.AddCommonCombatStrategyButtons then
		MultiBot.AddCommonCombatStrategyButtons(pFrame, dpsControlFrame, pCombat, 52)
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -90, 0, "ability_warrior_innerrage", MultiBot.L("tips.mage.tankAssist")).setDisable()
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
end