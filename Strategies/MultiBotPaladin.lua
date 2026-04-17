MultiBot.addPaladin = function(pFrame, pCombat, pNormal)
	pFrame.addButton("Heal", 0, 0, "spell_holy_aspiration", MultiBot.L("tips.paladin.heal")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +heal,?", "co -heal,?", pButton.getName())) then
			pButton.getButton("Tank").setDisable()
			pButton.getButton("Dps").setDisable()
		end
	end

	-- SEAL --

	local sealButton = pFrame.addButton("Seal", -30, 0, "spell_holy_healingaura", MultiBot.L("tips.paladin.seal.master"))
	sealButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["Seal"])
	end

	local sealFrame = pFrame.addFrame("Seal", -32, 30)
	sealFrame:Hide()

	sealFrame.addButton("SealHealth", 0, 0, "spell_holy_healingaura", MultiBot.L("tips.paladin.seal.bhealth"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Seal", pButton.texture, "nc +bhealth,?", pButton.getName())
		pButton.getButton("Seal").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bhealth,?", "nc -bhealth,?", btn.getName())
		end
	end

	sealFrame.addButton("SealMana", 0, 26, "spell_holy_sealofwisdom", MultiBot.L("tips.paladin.seal.bmana"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Seal", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("Seal").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bmana,?", "nc -bmana,?", btn.getName())
		end
	end

	sealFrame.addButton("SealStats", 0, 52, "spell_magic_magearmor", MultiBot.L("tips.paladin.seal.bstats"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Seal", pButton.texture, "nc +bstats,?", pButton.getName())
		pButton.getButton("Seal").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bstats,?", "nc -bstats,?", btn.getName())
		end
	end

	sealFrame.addButton("SealDps", 0, 78, "inv_hammer_01", MultiBot.L("tips.paladin.seal.bdps"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Seal", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("Seal").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bdps,?", "nc -bdps,?", btn.getName())
		end
	end

	-- STRATEGIES:SEAL --

	if(MultiBot.isInside(pNormal, "bhealth")) then
		sealButton.setTexture("spell_holy_healingaura").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bmana")) then
		sealButton.setTexture("spell_holy_sealofwisdom").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bstats")) then
		sealButton.setTexture("spell_magic_magearmor").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bstats,?", "nc -bstats,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
        sealButton.setTexture("inv_hammer_01").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end

	-- NON-COMBAT-AURA --

	local nonCombatAuraButton = pFrame.addButton("NonCombatAura", -60, 0, "spell_holy_crusaderaura", MultiBot.L("tips.paladin.naura.master"))
	nonCombatAuraButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["NonCombatAura"])
	end

	local nonCombatAuraFrame = pFrame.addFrame("NonCombatAura", -62, 30)
	nonCombatAuraFrame:Hide()

	nonCombatAuraFrame.addButton("NonCombatSpeed", 0, 0, "spell_holy_crusaderaura", MultiBot.L("tips.paladin.naura.bspeed"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +bspeed,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bspeed,?", "nc -bspeed,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatFire", 0, 26, "spell_fire_sealoffire", MultiBot.L("tips.paladin.naura.rfire"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +rfire,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +rfire,?", "nc -rfire,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatFrost", 0, 52, "spell_frost_wizardmark", MultiBot.L("tips.paladin.naura.rfrost"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +rfrost,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +rfrost,?", "nc -rfrost,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatShadow", 0, 78, "spell_shadow_sealofkings", MultiBot.L("tips.paladin.naura.rshadow"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +rshadow,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +rshadow,?", "nc -rshadow,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatDamage", 0, 104, "spell_holy_auraoflight", MultiBot.L("tips.paladin.naura.baoe"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +baoe,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +baoe,?", "nc -baoe,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatArmor", 0, 130, "spell_holy_devotionaura", MultiBot.L("tips.paladin.naura.barmor"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +barmor,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +barmor,?", "nc -barmor,?", btn.getName())
		end
	end

	nonCombatAuraFrame.addButton("NonCombatCast", 0, 156, "spell_holy_mindsooth", MultiBot.L("tips.paladin.naura.bcast"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAura", pButton.texture, "nc +bcast,?", pButton.getName())
		pButton.getButton("NonCombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "nc +bcast,?", "nc -bcast,?", btn.getName())
		end
	end

	-- STRATEGIES:NON-COMBAT-AURA --

	if(MultiBot.isInside(pNormal, "bspeed")) then
		nonCombatAuraButton.setTexture("spell_holy_crusaderaura").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bspeed,?", "nc -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "rfire")) then
		nonCombatAuraButton.setTexture("spell_fire_sealoffire").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rfire,?", "nc -rfire,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "rfrost")) then
		nonCombatAuraButton.setTexture("spell_frost_wizardmark").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rfrost,?", "nc -rfrost,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "rshadow")) then
		nonCombatAuraButton.setTexture("spell_shadow_sealofkings").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rshadow,?", "nc -rshadow,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "baoe")) then
		nonCombatAuraButton.setTexture("spell_holy_auraoflight").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +baoe,?", "nc -baoe,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "barmor")) then
		nonCombatAuraButton.setTexture("spell_holy_devotionaura").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +barmor,?", "nc -barmor,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bcast")) then
		nonCombatAuraButton.setTexture("spell_holy_mindsooth").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bcast,?", "nc -bcast,?", pButton.getName())
		end
	end

	-- COMBAT-AURA --

	local combatAuraButton = pFrame.addButton("CombatAura", -90, 0, "spell_holy_crusaderaura", MultiBot.L("tips.paladin.caura.master"))
	combatAuraButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["CombatAura"])
	end

	local combatAuraFrame = pFrame.addFrame("CombatAura", -92, 30)
	combatAuraFrame:Hide()

	combatAuraFrame.addButton("CombatSpeed", 0, 0, "spell_holy_crusaderaura", MultiBot.L("tips.paladin.caura.bspeed"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +bspeed,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bspeed,?", "co -bspeed,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatFire", 0, 26, "spell_fire_sealoffire", MultiBot.L("tips.paladin.caura.rfire"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +rfire,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +rfire,?", "co -rfire,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatFrost", 0, 52, "spell_frost_wizardmark", MultiBot.L("tips.paladin.caura.rfrost"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +rfrost,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +rfrost,?", "co -rfrost,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatShadow", 0, 78, "spell_shadow_sealofkings", MultiBot.L("tips.paladin.caura.rshadow"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +rshadow,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +rshadow,?", "co -rshadow,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatDamage", 0, 104, "spell_holy_auraoflight", MultiBot.L("tips.paladin.caura.baoe"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +baoe,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +baoe,?", "co -baoe,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatArmor", 0, 130, "spell_holy_devotionaura", MultiBot.L("tips.paladin.caura.barmor"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +barmor,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +barmor,?", "co -barmor,?", btn.getName())
		end
	end

	combatAuraFrame.addButton("CombatCast", 0, 156, "spell_holy_mindsooth", MultiBot.L("tips.paladin.caura.bcast"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAura", pButton.texture, "co +bcast,?", pButton.getName())
		pButton.getButton("CombatAura").doRight = function(btn)
			MultiBot.OnOffActionToTarget(btn, "co +bcast,?", "co -bcast,?", btn.getName())
		end
	end

	-- STRATEGIES:COMBAT-AURA --

	if(MultiBot.isInside(pCombat, "bspeed")) then
		combatAuraButton.setTexture("spell_holy_crusaderaura").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bspeed,?", "co -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "rfire")) then
		combatAuraButton.setTexture("spell_fire_sealoffire").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rfire,?", "co -rfire,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "rfrost")) then
		combatAuraButton.setTexture("spell_frost_wizardmark").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rfrost,?", "co -rfrost,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "rshadow")) then
		combatAuraButton.setTexture("spell_shadow_sealofkings").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rshadow,?", "co -rshadow,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "baoe")) then
		combatAuraButton.setTexture("spell_holy_auraoflight").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +baoe,?", "co -baoe,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "barmor")) then
		combatAuraButton.setTexture("spell_holy_devotionaura").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +barmor,?", "co -barmor,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bcast")) then
		combatAuraButton.setTexture("spell_holy_mindsooth").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bcast,?", "co -bcast,?", pButton.getName())
		end
	end

	-- DPS --

	pFrame.addButton("DpsControl", -120, 0, "ability_warrior_challange", MultiBot.L("tips.paladin.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local dpsFrame = pFrame.addFrame("DpsControl", -122, 30)
	dpsFrame:Hide()

	dpsFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.paladin.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.paladin.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	dpsFrame.addButton("Dps", 0, 52, "spell_holy_divinepurpose", MultiBot.L("tips.paladin.dps.dps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())) then
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Tank").setDisable()
		end
	end

    -- OFF-HEAL --
	dpsFrame.addButton("OffHeal", 0, 78, "Spell_Holy_FlashHeal", MultiBot.L("tips.paladin.dps.offheal")).setDisable()
        .doLeft = function(pButton)
            if (MultiBot.OnOffActionToTarget(
                    pButton, "co +offheal,?", "co -offheal,?",
                    pButton.getName())) then

                -- Modes exclusifs
                pButton.getButton("Dps").setDisable()
                pButton.getButton("Heal").setDisable()
            end
        end

    -- Added missing Healer DPS
	dpsFrame.addButton("HealerDps", 0, 104, "INV_Alchemy_Elixir_02", MultiBot.L("tips.paladin.dps.healerdps")).setDisable()
    .doLeft = function(pButton)
        if(MultiBot.OnOffActionToTarget(pButton, "co +healer dps,?", "co -healer dps,?", pButton.getName())) then
            pButton.getButton("TankAssist").setDisable()
            pButton.getButton("DpsAoe").setDisable()
            pButton.getButton("DpsAssist").setDisable()
        end
    end

	-- ASSIST --

	pFrame.addButton("TankAssist", -150, 0, "ability_warrior_innerrage", MultiBot.L("tips.paladin.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- TANK --

	pFrame.addButton("Tank", -180, 0, "ability_warrior_shieldmastery", MultiBot.L("tips.paladin.tank")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank,?", "co -tank,?", pButton.getName())) then
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Dps").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "dps,")) then pFrame.getButton("Dps").setEnable() end
	if(MultiBot.isInside(pCombat, "heal")) then pFrame.getButton("Heal").setEnable() end
	if(MultiBot.isInside(pCombat, "tank,")) then pFrame.getButton("Tank").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "offheal")) then pFrame.getButton("OffHeal").setEnable() end
	if(MultiBot.isInside(pCombat, "healer dps")) then pFrame.getButton("HealerDps").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
end