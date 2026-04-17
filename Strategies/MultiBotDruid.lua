MultiBot.addDruid = function(pFrame, pCombat, pNormal)
	pFrame.addButton("Heal", 0, 0, "spell_holy_aspiration", MultiBot.L("tips.druid.heal")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +heal,?", "co -heal,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Tank").setDisable()
			pButton.getButton("Bear").setDisable()
			pButton.getButton("Cat").setDisable()
			pButton.getButton("Dps").setDisable()
			pButton.getButton("HealerDps").setDisable()
		end
	end

	-- BUFF --

	pFrame.addButton("Buff", -30, 0, "spell_holy_power", MultiBot.L("tips.druid.buff")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +buff,?", "nc -buff,?", pButton.getName())
	end

	-- PLAYBOOK --

	pFrame.addButton("Playbook", -60, 0, "inv_misc_book_06", MultiBot.L("tips.druid.playbook.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("Playbook"))
	end

	local tFrame = pFrame.addFrame("Playbook", -62, 30)
	tFrame:Hide()

	tFrame.addButton("CasterDebuff", 0, 0, "ability_druid_cower", MultiBot.L("tips.druid.playbook.casterDebuff")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +caster debuff,?", "co -caster debuff,?", pButton.getName())) then
			pButton.getButton("DpsDebuff").setEnable()
		else
			pButton.getButton("DpsDebuff").setDisable()
		end
	end

	tFrame.addButton("CasterAoe", 0, 26, "spell_arcane_starfire", MultiBot.L("tips.druid.playbook.casterAoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +caster aoe,?", "co -caster aoe,?", pButton.getName())
	end

	tFrame.addButton("Caster", 0, 52, "spell_nature_starfall", MultiBot.L("tips.druid.playbook.caster")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +caster,?", "co -caster,?", pButton.getName())) then
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Tank").setDisable()
			pButton.getButton("Bear").setDisable()
			pButton.getButton("Cat").setDisable()
			pButton.getButton("Dps").setDisable()
		end
	end

	tFrame.addButton("CatAoe", 0, 78, "ability_druid_bash", MultiBot.L("tips.druid.playbook.catAoe")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +cat aoe,?", "co -cat aoe,?", pButton.getName())
	end

	tFrame.addButton("Cat", 0, 104, "ability_druid_catform", MultiBot.L("tips.druid.playbook.cat")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +cat,?", "co -cat,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Tank").setDisable()
			pButton.getButton("Bear").setDisable()
			pButton.getButton("Dps").setEnable()
		else
			pButton.getButton("Dps").setDisable()
		end
	end

	tFrame.addButton("Bear", 0, 130, "ability_racial_bearform", MultiBot.L("tips.druid.playbook.bear")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +bear,?", "co -bear,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Cat").setDisable()
			pButton.getButton("Dps").setDisable()
			pButton.getButton("Tank").setEnable()
		else
			pButton.getButton("Tank").setDisable()
		end
	end

   -- Missin MELEE --
   tFrame.addButton("Melee", 0, 156, "ability_parry", MultiBot.L("tips.druid.playbook.melee")).setDisable()
   .doLeft = function(pButton)
     if(MultiBot.OnOffActionToTarget(pButton, "co +melee,?", "co -melee,?", pButton.getName())) then
       pButton.getButton("Caster").setDisable()
       pButton.getButton("Heal").setDisable()
     end
   end

	-- DPS --

	pFrame.addButton("DpsControl", -90, 0, "ability_warrior_challange", MultiBot.L("tips.druid.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local tDpsFrame = pFrame.addFrame("DpsControl", -92, 30)
	tDpsFrame:Hide()

	tDpsFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.druid.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	tDpsFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.L("tips.druid.dps.dpsDebuff")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +caster debuff,?", "co -caster debuff,?", pButton.getName())) then
			pButton.getButton("CasterDebuff").setEnable()
		else
			pButton.getButton("CasterDebuff").setDisable()
		end
	end

	tDpsFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.L("tips.druid.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

    -- Missing HEALER DPS --
	tDpsFrame.addButton("HealerDps", 0, 130, "INV_Alchemy_Elixir_02", MultiBot.L("tips.druid.dps.healerdps")).setDisable()
    .doLeft = function(pButton)
      if(MultiBot.OnOffActionToTarget(pButton, "co +healer dps,?", "co -healer dps,?", pButton.getName())) then
        pButton.getButton("Dps").setDisable()
        pButton.getButton("OffHeal").setDisable()
        pButton.getButton("Heal").setDisable()
      end
    end

	tDpsFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.L("tips.druid.dps.dps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +cat,?", "co -cat,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Tank").setDisable()
			pButton.getButton("Bear").setDisable()
			pButton.getButton("Cat").setEnable()
		else
			pButton.getButton("Cat").setDisable()
		end
	end

    -- OFF-HEAL --
	tDpsFrame.addButton("OffHeal", 0, 104, "spell_nature_healingtouch", MultiBot.L("tips.druid.dps.offheal")).setDisable()
        .doLeft = function(pButton)
            if (MultiBot.OnOffActionToTarget(
                    pButton, "co +offheal,?", "co -offheal,?",
                    pButton.getName())) then

                -- Modes exclusifs
                pButton.getButton("Dps").setDisable()
                pButton.getButton("Heal").setDisable()
            end
        end

	-- ASSIST --

	pFrame.addButton("TankAssist", -120, 0, "ability_warrior_innerrage", MultiBot.L("tips.druid.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- TANK --

	pFrame.addButton("Tank", -150, 0, "ability_warrior_shieldmastery", MultiBot.L("tips.druid.tank")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank,?", "co -tank,?", pButton.getName())) then
			pButton.getButton("Caster").setDisable()
			pButton.getButton("Heal").setDisable()
			pButton.getButton("Dps").setDisable()
			pButton.getButton("Cat").setDisable()
			pButton.getButton("Bear").setEnable()
		else
			pButton.getButton("Bear").setDisable()
		end
	end

	-- STRATEGIES --

	if(MultiBot.isInside(pCombat, "heal")) then pFrame.getButton("Heal").setEnable() end
	if(MultiBot.isInside(pNormal, "buff,")) then pFrame.getButton("Buff").setEnable() end
	if(MultiBot.isInside(pCombat, "caster debuff")) then pFrame.getButton("CasterDebuff").setEnable() end
	if(MultiBot.isInside(pCombat, "caster aoe")) then pFrame.getButton("CasterAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "caster,")) then pFrame.getButton("Caster").setEnable() end
	if(MultiBot.isInside(pCombat, "cat aoe")) then pFrame.getButton("CatAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "cat,")) then pFrame.getButton("Cat").setEnable() end
	if(MultiBot.isInside(pCombat, "bear")) then pFrame.getButton("Bear").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "cat,")) then pFrame.getButton("Dps").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "bear,")) then pFrame.getButton("Tank").setEnable() end
    if(MultiBot.isInside(pCombat, "healer dps")) then pFrame.getButton("HealerDps").setEnable() end
    if(MultiBot.isInside(pCombat, "melee")) then pFrame.getButton("Melee").setEnable() end
    if(MultiBot.isInside(pCombat, "offheal")) then pFrame.getButton("OffHeal").setEnable() end
end