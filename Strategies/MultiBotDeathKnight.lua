MultiBot.addDeathKnight = function(pFrame, pCombat, pNormal)
	local tButton = pFrame.addButton("Presence", 0, 0, "spell_deathknight_bloodpresence", MultiBot.L("tips.deathknight.presence.master")).setDisable()
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Presence"))
	end

	local tFrame = pFrame.addFrame("Presence", -2, 30)
	tFrame:Hide()

	tFrame.addButton("Unholy", 0, 0, "spell_deathknight_unholypresence", MultiBot.L("tips.deathknight.presence.unholy"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Presence", pButton.texture, "co +unholy,?", pButton.getName())
		pButton.getButton("Presence").doRight = function()
			MultiBot.OnOffActionToTarget(pButton, "co +unholy,?", "co -unholy,?", pButton.getName())
		end
	end

	tFrame.addButton("Frost", 0, 26, "spell_deathknight_frostpresence", MultiBot.L("tips.deathknight.presence.frost"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Presence", pButton.texture, "co +frost,?", pButton.getName())
		pButton.getButton("Presence").doRight = function()
			MultiBot.OnOffActionToTarget(pButton, "co +frost,?", "co -frost,?", pButton.getName())
		end
	end

	tFrame.addButton("Blood", 0, 52, "spell_deathknight_bloodpresence", MultiBot.L("tips.deathknight.presence.blood"))
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Presence", pButton.texture, "co +blood,?", pButton.getName())
		pButton.getButton("Presence").doRight = function()
			MultiBot.OnOffActionToTarget(pButton, "co +blood,?", "co -blood,?", pButton.getName())
		end
	end

	-- SRATEGIES:PRESENCE ---

	if(MultiBot.isInside(pCombat, "unholy")) then
		tButton.setTexture("spell_deathknight_unholypresence").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +unholy,?", "co -unholy,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "frost")) then
		tButton.setTexture("spell_deathknight_frostpresence").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +frost,?", "co -frost,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "blood")) then
		tButton.setTexture("spell_deathknight_bloodpresence").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +blood,?", "co -blood,?", pButton.getName())
		end
	end

	-- DPS --

	pFrame.addButton("DpsControl", -30, 0, "ability_warrior_challange", MultiBot.L("tips.deathknight.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local tDpsFrame = pFrame.addFrame("DpsControl", -32, 30)
	tDpsFrame:Hide()

	tDpsFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.deathknight.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	tDpsFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.deathknight.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

    -- missing CLASS AOE (Frost/Unholy) --

	tDpsFrame.addButton("FrostAoe", 0, 52, "spell_frost_frostbolt02", MultiBot.L("tips.deathknight.dps.frostAoe")).setDisable() -- Variable a créér
    .doLeft = function(pButton)
        if(MultiBot.OnOffActionToTarget(pButton, "co +frost aoe,?", "co -frost aoe,?", pButton.getName())) then
            pButton.getButton("DpsAoe").setDisable()
            pButton.getButton("UnholyAoe").setDisable()
        end
    end

	tDpsFrame.addButton("UnholyAoe", 0, 78, "spell_fire_felflamering", MultiBot.L("tips.deathknight.dps.unholyAoe")).setDisable() -- Variable à créer
    .doLeft = function(pButton)
        if(MultiBot.OnOffActionToTarget(pButton, "co +unholy aoe,?", "co -unholy aoe,?", pButton.getName())) then
            pButton.getButton("DpsAoe").setDisable()
            pButton.getButton("FrostAoe").setDisable()
        end
    end

	-- ASSIST --

	pFrame.addButton("TankAssist", -60, 0, "ability_warrior_innerrage", MultiBot.L("tips.deathknight.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
    if(MultiBot.isInside(pCombat, "frost aoe"))   then pFrame.getButton("FrostAoe").setEnable()   end
    if(MultiBot.isInside(pCombat, "unholy aoe"))  then pFrame.getButton("UnholyAoe").setEnable()  end
end