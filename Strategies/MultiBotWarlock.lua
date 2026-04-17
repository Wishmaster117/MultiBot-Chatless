
MultiBot.addWarlock = function(pFrame, pCombat, pNormal)
	-- NON COMBAT STRATEGIES --
	--[[local tButton = pFrame.addButton("Buff", 0, 0, "spell_shadow_lifedrain02", MultiBot.tips.warlock.buff.master)
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["Buff"])
	end

	local tFrame = pFrame.addFrame("Buff", -2, 30)
	tFrame:Hide()

	tFrame.addButton("BuffHealth", 0, 0, "spell_shadow_lifedrain02", MultiBot.tips.warlock.buff.bhealth)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bhealth,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	end

	tFrame.addButton("BuffMana", 0, 26, "spell_shadow_siphonmana", MultiBot.tips.warlock.buff.bmana)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	end

	tFrame.addButton("BuffDps", 0, 52, "spell_shadow_haunting", MultiBot.tips.warlock.buff.bdps)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end

	-- STRATEGIES:BUFF --

	if(MultiBot.isInside(pNormal, "bhealth")) then
		tButton.setTexture("spell_shadow_lifedrain02").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bmana")) then
		tButton.setTexture("spell_shadow_siphonmana").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
		tButton.setTexture("spell_shadow_haunting").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end]]--

    -- BUFF — non supporté pour Warlock bouton placeholder désactivé
    local btnBuff = pFrame.addButton(
        "Buff", 0, 0, "spell_shadow_lifedrain02",
         (MultiBot.L("tips.warlock.buff.master") ~= "tips.warlock.buff.master" and MultiBot.L("tips.warlock.buff.master") or "Buffs")
          .. "|n|cffff0000Not available for Warlock.|r"
    )
    btnBuff.setDisable()
    btnBuff.doLeft = function() end

    -- Helper commun pour (dé)saturer les icônes (réutilisé par pierres / pets / malédictions)
    local _MB_setDesat = _MB_setDesat
    if not _MB_setDesat then
        local function __getIcon(btn)
            if not btn then return nil end
            if btn.icon and btn.icon.GetObjectType and btn.icon:GetObjectType() == "Texture" then
                return btn.icon
            end
            if btn.GetNormalTexture then
                local nt = btn:GetNormalTexture()
                if nt and nt.GetObjectType and nt:GetObjectType() == "Texture" then
                    return nt
                end
            end
            if btn.Icon and btn.Icon.GetObjectType and btn.Icon:GetObjectType() == "Texture" then
                return btn.Icon
            end
            if btn.texture and btn.texture.GetObjectType and btn.texture:GetObjectType() == "Texture" then
                return btn.texture
            end
            return nil
        end

        local function __apply(tex, isDesat)
            if not tex then return end
            local ok = false
            if tex.SetDesaturated then
                ok = pcall(tex.SetDesaturated, tex, isDesat and true or false)
            end
            if not ok then
                if isDesat then
                    tex:SetVertexColor(0.35, 0.35, 0.35, 1)
                else
                    tex:SetVertexColor(1, 1, 1, 1)
                end
            else
                if not isDesat then
                    tex:SetVertexColor(1, 1, 1, 1)
                end
            end
        end

        function _MB_setDesat(btn, isDesat)
            local tex = __getIcon(btn)
            __apply(tex, isDesat)
            if btn and btn.GetNormalTexture then
                local nt = btn:GetNormalTexture()
                if nt and nt ~= tex then
                    __apply(nt, isDesat)
                end
            end
        end
    end

	-- STONES (Spellstone / Firestone) --
	local btnStones = pFrame.addButton("StonesSelect", -150, 0,
		"inv_misc_orb_05",
		MultiBot.L("tips.warlock.stones.master"))
	btnStones._defaultIcon = "inv_misc_orb_05"

	local fStones = pFrame.addFrame("Stones", -152, 30)
	fStones:Hide()
	fStones.activeStone = nil

	btnStones.doLeft = function() MultiBot.ShowHideSwitch(fStones) end

	local stoneButtons = {}
	local stoneList = {
		{"Spellstone", "spellstone", "inv_misc_gem_amethyst_02"},
		{"Firestone",  "firestone",  "inv_ammo_firetar"},
	}

	local function UpdateStoneIcons(active)
		for label, b in pairs(stoneButtons) do
			_MB_setDesat(b, label ~= active)
		end
		if active and stoneButtons[active] then
			local icon = nil
			for _,v in ipairs(stoneList) do if v[1]==active then icon=v[3]; break end end
			if icon and btnStones.icon and btnStones.icon.SetTexture then
				btnStones.icon:SetTexture(MultiBot.SafeTexturePath(icon))
			elseif icon and btnStones.setIcon then
				btnStones.setIcon(icon)
			end
			_MB_setDesat(btnStones, false)
		else
			if btnStones.icon and btnStones.icon.SetTexture then
				btnStones.icon:SetTexture(MultiBot.SafeTexturePath(btnStones._defaultIcon))
			elseif btnStones.setIcon then
				btnStones.setIcon(btnStones._defaultIcon)
			end
			_MB_setDesat(btnStones, true)
		end
	end

	local function ToggleStone(pButton, label, cmd)
		local target = pButton.getName()
		if fStones.activeStone == label then
			SendChatMessage("nc -" .. cmd .. ",?", "WHISPER", nil, target)
			fStones.activeStone = nil
		else
			if fStones.activeStone then
				local old = fStones.activeStone
				local oldCmd = (old=="Spellstone") and "spellstone" or "firestone"
				SendChatMessage("nc -" .. oldCmd, "WHISPER", nil, target)
			end
			SendChatMessage("nc +" .. cmd .. ",?", "WHISPER", nil, target)
			fStones.activeStone = label
		end
		UpdateStoneIcons(fStones.activeStone)
		fStones:Hide()
	end

	for i,v in ipairs(stoneList) do
		local label, cmd, icon = unpack(v)
		local b = fStones.addButton("Stone"..label, 0, (i-1)*26, icon,
			MultiBot.L("tips.warlock.stones." .. label:lower()))
		stoneButtons[label] = b
		_MB_setDesat(b, true)
		b.doLeft  = function(pButton) ToggleStone(pButton, label, cmd) end
	end

	for _,v in ipairs(stoneList) do
		if MultiBot.isInside(pNormal, v[2]) then fStones.activeStone = v[1]; break end
	end
	UpdateStoneIcons(fStones.activeStone)
	fStones:SetScript("OnShow", function(self) UpdateStoneIcons(self.activeStone) end)
	-- FIN STONES --

	-- SOULSTONES (stratégies) --
	local btnSoulstones = pFrame.addButton("SoulstonesSelect", -180, 0,
		"inv_misc_orb_04",
		MultiBot.L("tips.warlock.soulstones.masterbutton"))
	btnSoulstones._defaultIcon = "inv_misc_orb_04"

	local fSoul = pFrame.addFrame("Soulstones", -182, 30)
	fSoul:Hide()
	fSoul.activeSS = nil

	local ssButtons = {}
	local ssList = {
		{"Self",   "ss self",   "Spell_shadow_Shadowform"},
		{"Master", "ss master", "Achievement_WorldEvent_LittleHelper"},
		{"Tank",   "ss tank",   "ability_warrior_defensivestance"},
		{"Healer", "ss healer", "INV_Elemental_Primal_life"},
	}

	local function UpdateSSIcons(active)
		for label, b in pairs(ssButtons) do
			_MB_setDesat(b, label ~= active)
		end
		if active and ssButtons[active] then
			local icon=nil; for _,v in ipairs(ssList) do if v[1]==active then icon=v[3]; break end end
			if icon and btnSoulstones.icon and btnSoulstones.icon.SetTexture then
				btnSoulstones.icon:SetTexture(MultiBot.SafeTexturePath(icon))
			elseif icon and btnSoulstones.setIcon then
				btnSoulstones.setIcon(icon)
			end
			_MB_setDesat(btnSoulstones, false)
		else
			if btnSoulstones.icon and btnSoulstones.icon.SetTexture then
				btnSoulstones.icon:SetTexture(MultiBot.SafeTexturePath(btnSoulstones._defaultIcon))
			elseif btnSoulstones.setIcon then
				btnSoulstones.setIcon(btnSoulstones._defaultIcon)
			end
			_MB_setDesat(btnSoulstones, true)
		end
	end

	btnSoulstones.doLeft = function() MultiBot.ShowHideSwitch(fSoul) end

	local function ToggleSS(pButton, label, cmd)
		local target = pButton.getName()
		if fSoul.activeSS == label then
			SendChatMessage("nc -" .. cmd .. ",?", "WHISPER", nil, target)
			fSoul.activeSS = nil
		else
			if fSoul.activeSS then
				local old = fSoul.activeSS
				for _,v in ipairs(ssList) do
					if v[1]==old then
						SendChatMessage("nc -" .. v[2], "WHISPER", nil, target)
						break
					end
				end
			end
			SendChatMessage("nc +" .. cmd .. ",?", "WHISPER", nil, target)
			fSoul.activeSS = label
		end
		UpdateSSIcons(fSoul.activeSS)
		fSoul:Hide()
	end

	for i,v in ipairs(ssList) do
		local label, cmd, icon = unpack(v)
		local b = fSoul.addButton("SS"..label, 0, (i-1)*26, icon,
			MultiBot.L("tips.warlock.soulstones." .. label:lower()) or label)
		ssButtons[label] = b
		_MB_setDesat(b, true)
		b.doLeft = function(pButton) ToggleSS(pButton, label, cmd) end
	end

	for _,v in ipairs(ssList) do
		if MultiBot.isInside(pNormal, v[2]) then fSoul.activeSS = v[1]; break end
	end
	UpdateSSIcons(fSoul.activeSS)
	fSoul:SetScript("OnShow", function(self) UpdateSSIcons(self.activeSS) end)
	-- FIN SOULSTONES --

    -- PETS --
    local btnPets = pFrame.addButton(
      "PetsSelect", -210, 0,
      "ability_druid_forceofnature",
      MultiBot.L("tips.warlock.pets.master")
    )
    btnPets._defaultIcon = "ability_druid_forceofnature"

    local fPets = pFrame.addFrame("Pets", -212, 30)
    fPets:Hide()
    fPets.activePet = nil
    btnPets.doLeft = function() MultiBot.ShowHideSwitch(fPets) end

    local petList = {
      {"Imp",        "imp",        "spell_shadow_summonimp"},
      {"Voidwalker", "voidwalker", "spell_shadow_summonvoidwalker"},
      {"Succubus",   "succubus",   "spell_shadow_summonsuccubus"},
      {"Felhunter",  "felhunter",  "spell_shadow_summonfelhunter"},
      {"Felguard",   "felguard",   "spell_shadow_summonfelguard"},
    }

    local petButtons = {}

    local function UpdatePetIcons(active)
      for label, b in pairs(petButtons) do
        _MB_setDesat(b, label ~= active)
      end
      if active and petButtons[active] then
        local icon=nil
        for _,v in ipairs(petList) do if v[1]==active then icon=v[3]; break end end
        if icon and btnPets.icon and btnPets.icon.SetTexture then
          btnPets.icon:SetTexture(MultiBot.SafeTexturePath(icon))
        elseif icon and btnPets.setIcon then
          btnPets.setIcon(icon)
        end
        _MB_setDesat(btnPets, false)
      else
        if btnPets.icon and btnPets.icon.SetTexture then
          btnPets.icon:SetTexture(MultiBot.SafeTexturePath(btnPets._defaultIcon))
        elseif btnPets.setIcon then
          btnPets.setIcon(btnPets._defaultIcon)
        end
        _MB_setDesat(btnPets, true)
      end
    end

    local function TogglePet(pButton, label, cmd)
      local target = pButton.getName()
      if fPets.activePet == label then
        SendChatMessage("nc -" .. cmd .. ",?", "WHISPER", nil, target)
        fPets.activePet = nil
      else
        if fPets.activePet then
          local old = fPets.activePet
          for _,v in ipairs(petList) do
            if v[1]==old then
              SendChatMessage("nc -" .. v[2], "WHISPER", nil, target)
              break
            end
          end
        end
        SendChatMessage("nc +" .. cmd .. ",?", "WHISPER", nil, target)
        fPets.activePet = label
      end
      UpdatePetIcons(fPets.activePet)
      fPets:Hide()
    end

    for i, v in ipairs(petList) do
      local label, cmd, icon = unpack(v)
      local b = fPets.addButton("Pet"..label, 0, (i-1)*26, icon,
        MultiBot.L("tips.warlock.pets." .. label:lower())
      )
      petButtons[label] = b
      _MB_setDesat(b, true)

      b.doLeft  = function(pButton) TogglePet(pButton, label, cmd) end
      b.doRight = b.doLeft
    end

    for _, v in ipairs(petList) do
      if MultiBot.isInside(pNormal, v[2]) then fPets.activePet = v[1]; break end
    end
    UpdatePetIcons(fPets.activePet)

    fPets:SetScript("OnShow", function(self)
      UpdatePetIcons(self.activePet)
    end)

    -- FIN PETS --


	-- COMBAT STRATEGIES --
	-- DPS --

	pFrame.addButton("DpsControl", -30, 0, "ability_warrior_challange", MultiBot.L("tips.warlock.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local tFrame = pFrame.addFrame("DpsControl", -32, 30)
	tFrame:Hide()

	tFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.warlock.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	tFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.L("tips.warlock.dps.dpsDebuff")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps debuff,?", "co -dps debuff,?", pButton.getName())
	end

	tFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.L("tips.warlock.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end

	tFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.L("tips.warlock.dps.dps")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())) then
			pButton.getButton("Tank").setDisable()
		end
	end

    -- META MELEE (Démonologie) --
    local btnMeta = tFrame.addButton(
      "MetaMelee", 0, 104, "Spell_Shadow_DemonForm",
      (MultiBot.L("tips.warlock.dps.metamelee") ~= "tips.warlock.dps.metamelee" and MultiBot.L("tips.warlock.dps.metamelee") or "Meta Melee")
    )
    btnMeta.setDisable()

    btnMeta.doLeft = function(pButton)
      MultiBot.OnOffActionToTarget(pButton, "co +meta melee,?", "co -meta melee,?", pButton.getName())
    end

		-- ASSIST --

	pFrame.addButton("TankAssist", -60, 0, "ability_warrior_innerrage", MultiBot.L("tips.warlock.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- TANK --

	pFrame.addButton("Tank", -90, 0, "ability_warrior_shieldmastery", MultiBot.L("tips.warlock.tank")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank,?", "co -tank,?", pButton.getName())) then
			pButton.getButton("Dps").setDisable()
		end
	end

   -- CURSES --
   local btnCurses = pFrame.addButton(
     "CursesSelect", -120, 0,
     "ability_warlock_avoidance",
     MultiBot.L("tips.warlock.curses.master")
   )
   btnCurses._defaultIcon = "ability_warlock_avoidance"

   local fCurses = pFrame.addFrame("Curses", -122, 30)
   fCurses:Hide()
   fCurses.activeCurse = nil

   btnCurses.doLeft = function() MultiBot.ShowHideSwitch(fCurses) end

   local curseButtons = {}

   local curseList = {
     {"Agony",      "curse of agony",      "Spell_Shadow_CurseOfSargeras"},
     {"Elements",   "curse of elements",   "Spell_Shadow_ChillTouch"},
     {"Exhaustion", "curse of exhaustion", "Spell_Shadow_GrimWard"},
     {"Doom",       "curse of doom",       "Spell_Shadow_AuraOfDarkness"},
     {"Weakness",   "curse of weakness",   "Spell_Shadow_CurseOfMannoroth"},
     {"Tongues",    "curse of tongues",    "Spell_Shadow_CurseOfTounges"},
   }

   local function UpdateCurseIcons(active)
     for label, b in pairs(curseButtons) do
       _MB_setDesat(b, label ~= active)
     end

     if active and curseButtons[active] then
       local icon=nil
       for _,v in ipairs(curseList) do if v[1]==active then icon=v[3]; break end end
       if icon and btnCurses.icon and btnCurses.icon.SetTexture then
         btnCurses.icon:SetTexture(MultiBot.SafeTexturePath(icon))
       elseif icon and btnCurses.setIcon then
         btnCurses.setIcon(icon)
       end
       _MB_setDesat(btnCurses, false)
     else
       if btnCurses.icon and btnCurses.icon.SetTexture then
         btnCurses.icon:SetTexture(MultiBot.SafeTexturePath(btnCurses._defaultIcon))
       elseif btnCurses.setIcon then
         btnCurses.setIcon(btnCurses._defaultIcon)
       end
       _MB_setDesat(btnCurses, true)
     end
   end

   for i, v in ipairs(curseList) do
     local label, cmd, icon = unpack(v)
     local b = fCurses.addButton("Curse"..label, 0, (i-1)*26, icon,
       MultiBot.L("tips.warlock.curses." .. label:lower())
     )
     curseButtons[label] = b

     _MB_setDesat(b, true)

     b.doLeft = function(pButton)
       local target = pButton.getName()

       if fCurses.activeCurse == label then
         SendChatMessage("co -" .. cmd .. ",?", "WHISPER", nil, target)
         fCurses.activeCurse = nil
         UpdateCurseIcons(nil)
         fCurses:Hide()
         return
       end

       if fCurses.activeCurse then
         local old = fCurses.activeCurse
         for _,vv in ipairs(curseList) do
           if vv[1]==old then
             SendChatMessage("co -" .. vv[2], "WHISPER", nil, target)
             break
           end
         end
       end
       SendChatMessage("co +" .. cmd .. ",?", "WHISPER", nil, target)
       fCurses.activeCurse = label

       UpdateCurseIcons(fCurses.activeCurse)
       fCurses:Hide()
     end
   end

   for _,v in ipairs(curseList) do
     if MultiBot.isInside(pCombat, v[2]) then fCurses.activeCurse = v[1]; break end
   end
   UpdateCurseIcons(fCurses.activeCurse)

   fCurses:SetScript("OnShow", function(self)
     UpdateCurseIcons(self.activeCurse)
   end)
   -- END CURSES --


	-- STRATEGIES --
    if(MultiBot.isInside(pCombat, "dps")) then pFrame.getButton("Dps").setEnable() end
    if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
    if(MultiBot.isInside(pCombat, "dps debuff")) then pFrame.getButton("DpsDebuff").setEnable() end
    if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
    if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
    if(MultiBot.isInside(pCombat, "tank")) then pFrame.getButton("Tank").setEnable() end
    if(MultiBot.isInside(pCombat, "meta melee")) then pFrame.getButton("MetaMelee").setEnable() end

    -- parent buttons des menus)
    if fCurses   and fCurses.activeCurse then   pFrame.getButton("CursesSelect").setEnable()   end
    if fStones   and fStones.activeStone then   pFrame.getButton("StonesSelect").setEnable()   end
    if fSoul     and fSoul.activeSS then        pFrame.getButton("SoulstonesSelect").setEnable() end
    if fPets     and fPets.activePet then       pFrame.getButton("PetsSelect").setEnable()     end

end