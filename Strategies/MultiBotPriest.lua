MultiBot.addPriest = function(pFrame, pCombat, pNormal)
	pFrame.addButton("Heal", 0, 0, "spell_holy_aspiration", MultiBot.L("tips.priest.heal")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +heal,?", "co -heal,?", pButton.getName())) then
			pButton.getButton("Shadow").setDisable()
			pButton.getButton("Dps").setDisable()
		end
	end

	-- BUFF --

	pFrame.addButton("Buff", -30, 0, "spell_holy_power", MultiBot.L("tips.priest.buff")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +buff,?", "co -buff,?", pButton.getName())
	end

	-- PLAYBOOK --

	pFrame.addButton("Playbook", -60, 0, "inv_misc_book_06", MultiBot.L("tips.priest.playbook.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
	end

	local playbookFrame = pFrame.addFrame("Playbook", -62, 30)
    playbookFrame:Hide()

    playbookFrame.addButton("ShadowDebuff", 0, 0, "spell_shadow_demonicempathy", MultiBot.L("tips.priest.playbook.shadowDebuff")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +shadow debuff,?", "co -shadow debuff,?", pButton.getName())) then
			pButton.getButton("DpsDebuff").setEnable()
		else
			pButton.getButton("DpsDebuff").setDisable()
		end
	end

	 playbookFrame.addButton("ShadowAoe", 0, 26, "spell_arcane_arcanetorrent", MultiBot.L("tips.priest.playbook.shadowAoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +shadow aoe,?", "co -shadow aoe,?", pButton.getName())
	end

	playbookFrame.addButton("Shadow", 0, 52, "spell_holy_devotion", MultiBot.L("tips.priest.playbook.shadow")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +shadow,?", "co -shadow,?", pButton.getName())) then
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Dps").setEnable()
		else
			pButton.getButton("Dps").setDisable()
		end
	end

	-- HOLY (PLAYBOOK) --
	playbookFrame.addButton("HolyHeal", 0, 78, "spell_holy_guardianspirit", MultiBot.L("tips.priest.playbook.holyheal")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +holy heal,?", "co -holy heal,?", pButton.getName())) then
			pButton.getButton("Shadow").setDisable()
			pButton.getButton("Dps").setDisable()
		end
	end

	playbookFrame.addButton("HolyDps", 0, 102, "spell_holy_holybolt", MultiBot.L("tips.priest.playbook.holydps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +holy dps,?", "co -holy dps,?", pButton.getName())) then
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Shadow").setDisable()
			pButton.getButton("Dps").setEnable()
		end
	end

   -- SHADOW RESISTANCE --
   -- (Expose 'rshadow' pour Shadow Protection)
   playbookFrame.addButton("ShadowRes", 0, 128, "spell_shadow_antishadow", MultiBot.L("tips.priest.playbook.rshadow")).setDisable()
   .doLeft = function(pButton)
       MultiBot.OnOffActionToTarget(pButton, "co +rshadow,?", "co -rshadow,?", pButton.getName())
   end

	-- DPS --

	pFrame.addButton("DpsControl", -90, 0, "ability_warrior_challange", MultiBot.L("tips.priest.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

    local dpsControlFrame = pFrame.addFrame("DpsControl", -92, 30)
    dpsControlFrame:Hide()

    dpsControlFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.priest.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +healer dps,?", "co -healer dps,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	dpsControlFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.L("tips.priest.dps.dpsDebuff")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +shadow debuff,?", "co -shadow debuff,?", pButton.getName())) then
			pButton.getButton("ShadowDebuff").setEnable()
		else
			pButton.getButton("ShadowDebuff").setDisable()
		end
	end

	dpsControlFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.L("tips.priest.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	dpsControlFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.L("tips.priest.dps.dps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +shadow,?", "co -shadow,?", pButton.getName())) then
			pButton.getButton("Shadow").setEnable()
			pButton.getButton("Heal").setDisable()
		else
			pButton.getButton("Shadow").setDisable()
		end
	end

	-- ASSIST --

	pFrame.addButton("TankAssist", -120, 0, "ability_warrior_innerrage", MultiBot.L("tips.priest.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "heal")) then pFrame.getButton("Heal").setEnable() end
	if(MultiBot.isInside(pNormal, "buff,")) then pFrame.getButton("Buff").setEnable() end
	if(MultiBot.isInside(pCombat, "shadow debuff")) then pFrame.getButton("ShadowDebuff").setEnable() end
	if(MultiBot.isInside(pCombat, "shadow aoe")) then pFrame.getButton("ShadowAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "holy heal")) then pFrame.getButton("HolyHeal").setEnable() end
	if(MultiBot.isInside(pCombat, "holy dps")) then pFrame.getButton("HolyDps").setEnable() end
	if(MultiBot.isInside(pCombat, "shadow,")) then pFrame.getButton("Shadow").setEnable() end
	if(MultiBot.isInside(pCombat, "healer dps")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "shadow debuff")) then pFrame.getButton("DpsDebuff").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "shadow,")) then pFrame.getButton("Shadow").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.isInside(pNormal, "rshadow")) then pFrame.getButton("ShadowRes").setEnable() end
end