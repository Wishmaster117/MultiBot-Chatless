
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

	if(MultiBot.hasStrategy(pNormal, "bhealth")) then
		tButton.setTexture("spell_shadow_lifedrain02").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pNormal, "bmana")) then
		tButton.setTexture("spell_shadow_siphonmana").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.hasStrategy(pNormal, "bdps")) then
		tButton.setTexture("spell_shadow_haunting").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end]]--


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
	local btnStones = pFrame.addButton("StonesSelect", -120, 0,
		"inv_misc_orb_05",
		MultiBot.L("tips.warlock.stones.master"))
	btnStones._defaultIcon = "inv_misc_orb_05"

	local fStones = pFrame.addFrame("Stones", -122, 30)
	fStones:Hide()
	fStones.strategyStone = nil
	fStones.activeStone = nil
	fStones.authoritativeStoneState = false
	fStones.stateRequestToken = nil
	fStones.refreshAfterPending = false
	fStones.strategyPending = false

	btnStones.doLeft = function() MultiBot.ShowHideSwitch(fStones) end

	local stoneButtons = {}
	local stoneList = {
		{"Spellstone", "spellstone", "inv_misc_gem_amethyst_02", 41196},
		{"Firestone",  "firestone",  "inv_ammo_firetar",          41174},
	}

	local function UpdateStoneIcons(active)
		for label, b in pairs(stoneButtons) do
			_MB_setDesat(b, label ~= active)
		end
		if active and stoneButtons[active] then
			local icon = nil
			for _,v in ipairs(stoneList) do if v[1]==active then icon=GetItemIcon(v[4]) or MultiBot.SafeTexturePath(v[3]); break end end
			if icon and btnStones.icon and btnStones.icon.SetTexture then
				btnStones.icon:SetTexture(icon)
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

	MultiBot._warlockStoneMutationWatchers = MultiBot._warlockStoneMutationWatchers or {}
	if MultiBot._warlockStoneMutationHookInstalled ~= true then
		MultiBot._warlockStoneMutationHookInstalled = true
		MultiBot._warlockStonePreviousStrategyMutationApplied = MultiBot.OnStrategyMutationApplied
		MultiBot.OnStrategyMutationApplied = function(result)
			local previous = MultiBot._warlockStonePreviousStrategyMutationApplied
			if type(previous) == "function" then
				previous(result)
			end
			if type(result) ~= "table" or result.scope ~= "BOT" or result.stateScope ~= "N" then
				return
			end

			local targetKey = string.lower(tostring(result.target or ""))
			local watcher = MultiBot._warlockStoneMutationWatchers[targetKey]
			if type(watcher) ~= "table" or watcher.changes ~= result.changes then
				return
			end

			MultiBot._warlockStoneMutationWatchers[targetKey] = nil
			if type(watcher.callback) == "function" then
				watcher.callback(result.status == "ok", result)
			end
		end
	end

	local function GetStoneTarget()
		return type(btnStones.getName) == "function" and btnStones.getName() or nil
	end

	local function HasAuthoritativeStoneState(target)
		if type(target) ~= "string" or target == "" then return false end
		if MultiBot.IsSelfBotStrategyTarget and MultiBot.IsSelfBotStrategyTarget(target) then return false end
		return MultiBot.bridge
			and MultiBot.bridge.connected == true
			and MultiBot.bridge.warlockStoneStateCapable == true
			and MultiBot.Comm
			and type(MultiBot.Comm.RequestWarlockStoneState) == "function"
	end

	local function RefreshStoneState(forceAfterPending)
		local target = GetStoneTarget()
		if not HasAuthoritativeStoneState(target) then
			fStones.stateRequestToken = nil
			fStones.refreshAfterPending = false
			fStones.authoritativeStoneState = false
			fStones.activeStone = fStones.strategyStone
			UpdateStoneIcons(fStones.activeStone)
			return false
		end

		if fStones.stateRequestToken then
			if forceAfterPending then
				fStones.refreshAfterPending = true
			end
			return true
		end

		if fStones.authoritativeStoneState ~= true then
			fStones.activeStone = nil
			UpdateStoneIcons(nil)
		end

		local requestToken = nil
		requestToken = MultiBot.Comm.RequestWarlockStoneState(target, function(ok, result)
			if fStones.stateRequestToken ~= requestToken then
				return
			end

			fStones.stateRequestToken = nil
			local refreshAgain = fStones.refreshAfterPending == true
			fStones.refreshAfterPending = false

			if ok == true and type(result) == "table" then
				local active = nil
				if result.kind == "FIRESTONE" then
					active = "Firestone"
				elseif result.kind == "SPELLSTONE" then
					active = "Spellstone"
				end
				fStones.activeStone = active
				fStones.authoritativeStoneState = true
				UpdateStoneIcons(active)
			end

			if refreshAgain then
				if type(MultiBot.TimerAfter) == "function" then
					MultiBot.TimerAfter(0.01, function() RefreshStoneState(false) end)
				else
					RefreshStoneState(false)
				end
			end
		end)

		if requestToken == false or requestToken == nil then
			return false
		end
		fStones.stateRequestToken = requestToken
		return true
	end

	local function ScheduleStoneStateRefresh()
		local target = GetStoneTarget()
		if not HasAuthoritativeStoneState(target) then
			fStones.authoritativeStoneState = false
			fStones.activeStone = fStones.strategyStone
			UpdateStoneIcons(fStones.activeStone)
			return
		end

		if type(MultiBot.TimerAfter) == "function" then
			MultiBot.TimerAfter(0.60, function() RefreshStoneState(true) end)
		else
			RefreshStoneState(true)
		end
	end

	local function ToggleStone(pButton, label, cmd)
		if fStones.strategyPending then return end

		local target = pButton.getName()
		if type(target) ~= "string" or target == "" then return end

		local desired = nil
		local changes

		if fStones.strategyStone == label then
			changes = "-" .. cmd
		else
			desired = label
			if fStones.strategyStone then
				local old = fStones.strategyStone
				local oldCmd = (old=="Spellstone") and "spellstone" or "firestone"
				changes = "-" .. oldCmd .. ",+" .. cmd
			else
				changes = "+" .. cmd
			end
		end

		local action = "nc " .. changes .. ",?"
		local targetKey = string.lower(target)
		local selfStrategyTarget = MultiBot.IsSelfBotStrategyTarget
			and MultiBot.IsSelfBotStrategyTarget(target)

		local function mutationComplete(ok)
			fStones.strategyPending = false
			if ok ~= true then return end

			if MultiBot.Comm and type(MultiBot.Comm.ShowSystemMessage) == "function" then
				MultiBot.Comm.ShowSystemMessage("[MultiBot] " .. target .. ": " .. (desired or "Stones OFF") .. " OK")
			end

			fStones.strategyStone = desired
			if HasAuthoritativeStoneState(target) then
				ScheduleStoneStateRefresh()
			else
				fStones.authoritativeStoneState = false
				fStones.activeStone = desired
				UpdateStoneIcons(fStones.activeStone)
			end
			fStones:Hide()
		end

		MultiBot._warlockStoneMutationWatchers[targetKey] = nil
		local sent, transport = MultiBot.ActionToUnitStrategy(action, target, function(ok)
			mutationComplete(ok)
		end)

		if transport == "pending" then
			fStones.strategyPending = true
			return
		end
		if not sent then return end

		if transport == "bridge" then
			fStones.strategyPending = true
			if not selfStrategyTarget then
				MultiBot._warlockStoneMutationWatchers[targetKey] = {
					changes = changes,
					callback = mutationComplete,
				}
			end
			return
		end

		fStones.strategyStone = desired
		fStones.activeStone = desired
		fStones.authoritativeStoneState = false
		UpdateStoneIcons(fStones.activeStone)
		fStones:Hide()
	end

	for i,v in ipairs(stoneList) do
		local label, cmd, icon = unpack(v)
		local b = fStones.addButton("Stone"..label, 0, (i-1)*26, icon,
			MultiBot.L("tips.warlock.stones." .. label:lower()))
		if b.icon and b.icon.SetTexture then
			b.icon:SetTexture(GetItemIcon(v[4]) or MultiBot.SafeTexturePath(icon))
		end
		stoneButtons[label] = b
		_MB_setDesat(b, true)
		b.doLeft  = function(pButton) ToggleStone(pButton, label, cmd) end
	end

	for _,v in ipairs(stoneList) do
		if MultiBot.hasStrategy(pNormal, v[2]) then fStones.strategyStone = v[1]; break end
	end

	if HasAuthoritativeStoneState(GetStoneTarget()) then
		UpdateStoneIcons(nil)
		RefreshStoneState(false)
	else
		fStones.activeStone = fStones.strategyStone
		UpdateStoneIcons(fStones.activeStone)
	end

	fStones:SetScript("OnShow", function() RefreshStoneState(false) end)
	-- FIN STONES --

	-- SOULSTONES (stratégies) --
	local btnSoulstones = pFrame.addButton("SoulstonesSelect", -150, 0,
		"inv_misc_orb_04",
		MultiBot.L("tips.warlock.soulstones.masterbutton"))
	btnSoulstones._defaultIcon = "inv_misc_orb_04"

	local fSoul = pFrame.addFrame("Soulstones", -152, 30)
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
		local desired = nil
		local action

		if fSoul.activeSS == label then
			action = "nc -" .. cmd .. ",?"
		else
			desired = label
			if fSoul.activeSS then
				local old = fSoul.activeSS
				local oldCmd = nil
				for _,v in ipairs(ssList) do
					if v[1]==old then
						oldCmd = v[2]
						break
					end
				end
				if oldCmd then
					action = "nc -" .. oldCmd .. ",+" .. cmd .. ",?"
				else
					action = "nc +" .. cmd .. ",?"
				end
			else
				action = "nc +" .. cmd .. ",?"
			end
		end

		local sent, transport = MultiBot.ActionToUnitStrategy(action, target, function(ok)
			if ok == true then
				fSoul:Hide()
			end
		end)
		if transport == "pending" then return end
		if not sent then return end
		if transport ~= "bridge" then
			fSoul.activeSS = desired
			UpdateSSIcons(fSoul.activeSS)
		end
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
		if MultiBot.hasStrategy(pNormal, v[2]) then fSoul.activeSS = v[1]; break end
	end
	UpdateSSIcons(fSoul.activeSS)
	fSoul:SetScript("OnShow", function(self) UpdateSSIcons(self.activeSS) end)
	-- FIN SOULSTONES --

    -- PETS --
    local btnPets = pFrame.addButton(
      "PetsSelect", -180, 0,
      "ability_druid_forceofnature",
      MultiBot.L("tips.warlock.pets.master")
    )
    btnPets._defaultIcon = "ability_druid_forceofnature"

    local fPets = pFrame.addFrame("Pets", -182, 30)
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
      local desired = nil
      local action

      if fPets.activePet == label then
        action = "nc -" .. cmd .. ",?"
      else
        desired = label
        if fPets.activePet then
          local old = fPets.activePet
          local oldCmd = nil
          for _,v in ipairs(petList) do
            if v[1]==old then
              oldCmd = v[2]
              break
            end
          end
          if oldCmd then
            action = "nc -" .. oldCmd .. ",+" .. cmd .. ",?"
          else
            action = "nc +" .. cmd .. ",?"
          end
        else
          action = "nc +" .. cmd .. ",?"
        end
      end

      local sent, transport = MultiBot.ActionToUnitStrategy(action, target, function(ok)
        if ok == true then
          fPets:Hide()
        end
      end)
      if transport == "pending" then return end
      if not sent then return end
      if transport ~= "bridge" then
        fPets.activePet = desired
        UpdatePetIcons(fPets.activePet)
      end
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
      if MultiBot.hasStrategy(pNormal, v[2]) then fPets.activePet = v[1]; break end
    end
    UpdatePetIcons(fPets.activePet)

    fPets:SetScript("OnShow", function(self)
      UpdatePetIcons(self.activePet)
    end)

    -- FIN PETS --


	-- COMBAT STRATEGIES --
	-- DPS --

	pFrame.addButton("DpsControl", 0, 0, "ability_warrior_challange", MultiBot.L("tips.warlock.dps.master"))
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end

	local tFrame = pFrame.addFrame("DpsControl", -2, 30)
	tFrame:Hide()

	tFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.L("tips.warlock.dps.dpsAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end


	tFrame.addButton("DpsAoe", 0, 26, "spell_holy_surgeoflight", MultiBot.L("tips.warlock.dps.dpsAoe")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end


    -- META MELEE (Démonologie) --
    local btnMeta = tFrame.addButton(
      "MetaMelee", 0, 52, "Spell_Shadow_DemonForm",
      (MultiBot.L("tips.warlock.dps.metamelee") ~= "tips.warlock.dps.metamelee" and MultiBot.L("tips.warlock.dps.metamelee") or "Meta Melee")
    )
    btnMeta.setDisable()

    btnMeta.doLeft = function(pButton)
      MultiBot.OnOffUnitStrategy(pButton, "co +meta melee,?", "co -meta melee,?", pButton.getName())
    end

	if MultiBot.AddCommonCombatStrategyButtons then
		MultiBot.AddCommonCombatStrategyButtons(pFrame, tFrame, pCombat, 78)
	end

		-- ASSIST --

	pFrame.addButton("TankAssist", -30, 0, "ability_warrior_innerrage", MultiBot.L("tips.warlock.tankAssist")).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffUnitStrategy(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- TANK --

	pFrame.addButton("Tank", -60, 0, "ability_warrior_shieldmastery", MultiBot.L("tips.warlock.tank")).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffUnitStrategy(pButton, "co +tank,?", "co -tank,?", pButton.getName())
	end

   -- CURSES --
   local btnCurses = pFrame.addButton(
     "CursesSelect", -90, 0,
     "ability_warlock_avoidance",
     MultiBot.L("tips.warlock.curses.master")
   )
   btnCurses._defaultIcon = "ability_warlock_avoidance"

   local fCurses = pFrame.addFrame("Curses", -92, 30)
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
       local desired = nil
       local action

       if fCurses.activeCurse == label then
         action = "co -" .. cmd .. ",?"
       else
         desired = label
         if fCurses.activeCurse then
           local old = fCurses.activeCurse
           local oldCmd = nil
           for _,vv in ipairs(curseList) do
             if vv[1]==old then
               oldCmd = vv[2]
               break
             end
           end
           if oldCmd then
             action = "co -" .. oldCmd .. ",+" .. cmd .. ",?"
           else
             action = "co +" .. cmd .. ",?"
           end
         else
           action = "co +" .. cmd .. ",?"
         end
       end

       local sent, transport = MultiBot.ActionToUnitStrategy(action, target, function(ok)
         if ok == true then
           fCurses:Hide()
         end
       end)
       if transport == "pending" then return end
       if not sent then return end
       if transport ~= "bridge" then
         fCurses.activeCurse = desired
         UpdateCurseIcons(fCurses.activeCurse)
       end
       fCurses:Hide()
     end
   end

   for _,v in ipairs(curseList) do
     if MultiBot.hasStrategy(pCombat, v[2]) then fCurses.activeCurse = v[1]; break end
   end
   UpdateCurseIcons(fCurses.activeCurse)

   fCurses:SetScript("OnShow", function(self)
     UpdateCurseIcons(self.activeCurse)
   end)
   -- END CURSES --


	-- STRATEGIES --

    if(MultiBot.hasStrategy(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end

    if(MultiBot.hasStrategy(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
    if(MultiBot.hasStrategy(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
    if(MultiBot.hasStrategy(pCombat, "tank")) then pFrame.getButton("Tank").setEnable() end
    if(MultiBot.hasStrategy(pCombat, "meta melee")) then pFrame.getButton("MetaMelee").setEnable() end

    -- parent buttons des menus)
    if fCurses   and fCurses.activeCurse then   pFrame.getButton("CursesSelect").setEnable()   end
    if fStones   and fStones.activeStone then   pFrame.getButton("StonesSelect").setEnable()   end
    if fSoul     and fSoul.activeSS then        pFrame.getButton("SoulstonesSelect").setEnable() end
    if fPets     and fPets.activePet then       pFrame.getButton("PetsSelect").setEnable()     end

end