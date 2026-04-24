MultiBot.CLEAR = function(pString, pAmount, o1, o2, o3)
	for i = 1, pAmount, 1 do
		if(o1 == nil) then
			pString = MultiBot.doReplace(pString, "|cff%w%w%w%w%w%w", "")
			pString = MultiBot.doReplace(pString, "|h", "")
			pString = MultiBot.doReplace(pString, "|r", "")
		else
			if(o1 ~= nil) then pString = MultiBot.doReplace(pString, o1, "") end
			if(o2 ~= nil) then pString = MultiBot.doReplace(pString, o1, "") end
			if(o3 ~= nil) then pString = MultiBot.doReplace(pString, o1, "") end
		end
	end

	return pString
end

MultiBot.CASE = function(pCondition, pDefault, oCase1, oCase2, oCase3, oCase4, oCase5, oCase6, oCase7, oCase8, oCase9)
	if(pCondition == 1 and oCase1 ~= nil) then return oCase1 end
	if(pCondition == 2 and oCase2 ~= nil) then return oCase2 end
	if(pCondition == 3 and oCase3 ~= nil) then return oCase3 end
	if(pCondition == 4 and oCase4 ~= nil) then return oCase4 end
	if(pCondition == 5 and oCase5 ~= nil) then return oCase5 end
	if(pCondition == 6 and oCase6 ~= nil) then return oCase6 end
	if(pCondition == 7 and oCase7 ~= nil) then return oCase7 end
	if(pCondition == 8 and oCase8 ~= nil) then return oCase8 end
	if(pCondition == 9 and oCase9 ~= nil) then return oCase9 end
	return pDefault
end

MultiBot.IF = function(pCondition, pSuccess, pFailure)
	if(pCondition) then return pSuccess else return pFailure end
end

MultiBot.doSlash = function(pCommand, pArguments)
	local tCommand = string.upper(string.sub(pCommand, 2))

	for tKey, tFunc in pairs(SlashCmdList) do
		if(tKey == tCommand) then
			tFunc(pArguments)
			return true
		end
	end

	SendChatMessage(MultiBot.L("info.command"), "SAY")
	return false
end

MultiBot.doDot = function(pCommand, oArguments)
	SendChatMessage(pCommand .. " " .. oArguments)
	return false
end

MultiBot.doDotWithTarget = function(pCommand, oArguments)
	local tName = UnitName("target")

	if(tName ~= nil and tName ~= "Unknown Entity") then
		if(oArguments ~= nil)
		then SendChatMessage(pCommand .. " " .. tName .. " " .. oArguments)
		else SendChatMessage(pCommand .. " " .. tName)
		end

		return true
	end

	SendChatMessage(MultiBot.L("info.target"), "SAY")
	return false
end

MultiBot.doSplit = function(pString, pPattern)
    if not pString or pString == "" then -- Secure function if pString empty
        return {}
    end
	local tResult = {}
	local tStart = 1
	local tFrom, tTo = string.find(pString, pPattern, tStart)

	while tFrom do
		table.insert(tResult, string.sub(pString, tStart, tFrom - 1))
		tStart = tTo + 1
		tFrom, tTo = string.find(pString, pPattern, tStart)
	end

	table.insert(tResult, string.sub(pString, tStart))
	return tResult
end

MultiBot.doReplace = function(pString, pSearch, pReplace)
	local tFrom, tTo = string.find(pString, pSearch)
	if(tFrom == nil or tTo == nil) then return pString end
	return string.sub(pString, 1, tFrom - 1) .. pReplace .. string.sub(pString, tTo + 1)
end

MultiBot.doRemove = function(pIndex, pName)
	if(pIndex == nil) then return end
	local tFound = 0

	--for i = 1, table.getn(pIndex) do
	for i = 1, #pIndex do
		if(pIndex[i] == pName) then
			tFound = i
			break
		end
	end

	if(tFound == 0) then return false end
	table.remove(pIndex, tFound)
	return true
end

MultiBot.doRepos = function(pIndex, pOffsetX)
	local tButton = MultiBot.frames["MultiBar"].buttons[pIndex]
	local tFrame = MultiBot.frames["MultiBar"].frames[pIndex]
	if(tButton == nil) then tButton = MultiBot.frames["MultiBar"].frames["Left"].buttons[pIndex] end
	if(tFrame == nil) then tFrame = MultiBot.frames["MultiBar"].frames["Left"].frames[pIndex] end
	if(tButton == nil) then tButton = MultiBot.frames["MultiBar"].frames["Right"].buttons[pIndex] end
	if(tFrame == nil) then tFrame = MultiBot.frames["MultiBar"].frames["Right"].frames[pIndex] end
	if(tButton ~= nil) then tButton.setPoint(tButton.x + pOffsetX, tButton.y) end
	if(tFrame ~= nil) then tFrame.setPoint(tFrame.x + pOffsetX, tFrame.y) end
	return true
end

MultiBot.isActive = function(pName)
	for key, value in pairs(MultiBot.index.actives) do if(value == pName) then return true end end
	return false
end

MultiBot.isInside = function(pString, ...)
	if(pString == nil) then return false end
	for i = 1, select("#", ...) do
		local pattern = select(i, ...)
		if(pattern ~= nil and string.find(pString, pattern)) then
			return true
		end
	end
	return false
end

MultiBot.beInside = function(pString, ...)
	if(pString == nil) then return false end
	for i = 1, select("#", ...) do
		local pattern = select(i, ...)
		if(pattern ~= nil and nil == string.find(pString, pattern)) then
			return false
		end
	end
	return true
end

MultiBot.isRoster = function(pRoster, pName)
	for key, value in pairs(MultiBot.index[pRoster]) do if(pName == value) then return true end end
	return false
end

MultiBot.isMember = function(pName)
	if(GetNumRaidMembers() > 5) then
		for i = 1, GetNumRaidMembers() do
			if(UnitName("raid" .. i) == pName) then return true end
		end
	end

	if(GetNumPartyMembers() > 0) then
		for i = 1, 4 do
			if(UnitName("party" .. i) == pName) then return true end
		end
	end

	if(UnitName("player") == pName) then
		return true
	end

	return false
end

MultiBot.isTarget = function()
	local tName = UnitName("target")

	if(tName ~= nil and tName ~=  "Unknown Entity") then
		return true
	end

	SendChatMessage(MultiBot.L("info.target"), "SAY")
	return false
end

MultiBot.isUnit = function(pUnit)
	local tName = UnitName(pUnit)

	if(tName == nil or tName == "Unknown Entity") then
		return false
	end

	return true
end

-- Safe texture resolver to avoid calling string.sub on nil and to normalize paths
-- Returns a usable texture path string. Falls back to the question mark icon.
MultiBot.SafeTexturePath = function(pTexture)
	-- Guard: nil or non-string => fallback
	if type(pTexture) ~= "string" or pTexture == "" then
		return "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	-- Si l’appelant fournit déjà un chemin (avec / ou \), on le considère explicite
	-- et on le renvoie tel quel, après normalisation vers "\"
    local tex = pTexture:gsub("/", "\\")
	if tex:find("\\", 1, true) then
		return tex
	end
	-- Normalize: only prefix when not already an Interface path
	local head = string.sub(tex, 1, 9)
	local needsPrefix = string.lower(head) ~= "interface"
	if needsPrefix then
        return "Interface\\Icons\\" .. tex
	end
    return tex
end

-- Classe refactor
-- Sauvegarde l’ancienne version si elle existait avant refactor
if not MultiBot._toClass_legacy and type(MultiBot.toClass) == "function" then
  MultiBot._toClass_legacy = MultiBot.toClass
end

-- Nouvelle version avec fallback
MultiBot.toClass = function(pClass)
  if MultiBot.NormalizeClass then
    local canon = MultiBot.NormalizeClass(pClass)
    if canon then return canon end
  end
  if MultiBot._toClass_legacy then
    return MultiBot._toClass_legacy(pClass)
  end
  return "Unknown"
end

MultiBot.toUnit = function(pName)
	if(GetNumRaidMembers() > 5) then
		for i = 1, GetNumRaidMembers() do
			if(UnitName("raid" .. i) == pName) then
				return "raid" .. i
			end
		end
	end

	if(GetNumPartyMembers() > 0) then
		for i = 1, GetNumPartyMembers() do
			if(UnitName("party" .. i) == pName) then
				return "party" .. i
			end
		end
	end

	if(UnitName("player") == pName) then
		return "player"
	end

	return nil
end

MultiBot.toTip = function(pClass, pLevel, pName)
	local tTip = pClass .. " - "
	if(pLevel ~= nil) then tTip = tTip .. pLevel .. " - " end
	tTip = tTip .. pName .. MultiBot.L("tips.unit.button")
	tTip = MultiBot.doReplace(tTip, "NAME", pName)
	tTip = MultiBot.doReplace(tTip, "NAME", pName)
	tTip = MultiBot.doReplace(tTip, "NAME", pName)
	return tTip
end

MultiBot.toPoint = function(pFrame)
	    if not pFrame then
	        return 0, 0
	    end
	    -- Mesurer par rapport au parent global stable et arrondir à l’unité.
	    local uiRight = (UIParent and UIParent:GetRight()) or GetScreenWidth()
	    local getRight = pFrame.GetRight or pFrame.getRight
	    local getBottom = pFrame.GetBottom or pFrame.getBottom
	    local xRight  = (type(getRight) == "function" and getRight(pFrame)) or 0
	    local yBottom = (type(getBottom) == "function" and getBottom(pFrame)) or 0
	    -- Offset vers BOTTOMRIGHT (négatif ou nul)
	    local offX = xRight - uiRight
	    local offY = yBottom
    -- Arrondi au plus proche pour éviter la dérive cumulée
    return math.floor(offX + 0.5), math.floor(offY + 0.5)
end

MultiBot.RaidPool = function(pUnit, oWho)
	if(pUnit ~= "player" and MultiBot.getBot(pUnit) == nil) then return end

	local tGender = MultiBot.CASE(UnitSex(pUnit), "[U]", "[N]", "[M]", "[F]")
	local tLocalClass, tClass = UnitClass(pUnit)
	local tLocalRace, tRace = UnitRace(pUnit)
	local tLevel = UnitLevel(pUnit)
	local tName = UnitName(pUnit)
	local tIndex = { 4, 5, 6 }
	local tTabs = {}
	--local tScore = ""
	local tScore

	if(oWho ~= nil) then
		local tWho = MultiBot.CLEAR(oWho, 20)
		tWho = MultiBot.doReplace(tWho, "beast mastery", "Beast-Mastery")
		tWho = MultiBot.doReplace(tWho, "feral combat", "Feral-Combat")
		tWho = MultiBot.doReplace(tWho, "Blood Elf", "Blood-Elf")
		tWho = MultiBot.doReplace(tWho, "Night Elf", "Night-Elf")

		tParts = MultiBot.doSplit(tWho, ", ")
		tSpace = MultiBot.doSplit(tParts[1], " ")
		tScore = MultiBot.doSplit(tParts[2], " ")[1]

		if(MultiBot.isInside(tSpace[5], "/")) then tIndex = { 5, 6, 7 } else
		if(MultiBot.isInside(tSpace[6], "/")) then tIndex = { 6, 7, 8 } else
		if(MultiBot.isInside(tSpace[7], "/")) then tIndex = { 7, 8, 9 }
		end end end

		tTabs = MultiBot.doSplit(strsub(tSpace[tIndex[1]], 2, strlen(tSpace[tIndex[1]]) - 1), "/")

		if(tGender == nil) then tGender = tSpace[2] end
		if(tClass == nil) then tClass = MultiBot.toClass(tSpace[tIndex[2]]) end
		if(tRace == nil) then tRace = tSpace[1] end
		if(tName == nil) then tName = pUnit end
		if(tLevel == nil) then tLevel = substr(MultiBot.doSplit(tSpace[tIndex[3]], " ")[1], 2) end
	else
		tScore = MultiBot.ItemLevel(pUnit)
		tTabs[1] = GetNumTalents(1)
		tTabs[2] = GetNumTalents(2)
		tTabs[3] = GetNumTalents(3)
	end

	-- [SAFETY] tTabs doivent être numériques
	tTabs[1] = tonumber(tTabs[1]) or 0
	tTabs[2] = tonumber(tTabs[2]) or 0
	tTabs[3] = tonumber(tTabs[3]) or 0

	local tTabIndex = MultiBot.IF(tTabs[3] > tTabs[2] and tTabs[3] > tTabs[1], 3, MultiBot.IF(tTabs[2] > tTabs[3] and tTabs[2] > tTabs[1], 2, 1))
	local tSpecial = MultiBot.CLEAR(MultiBot.L("info.talent." .. MultiBot.toClass(tClass) .. tTabIndex), 1)

	if(tLocalClass == nil) then tLocalClass = tClass end
	if(tLocalRace == nil) then tLocalRace = tRace end

	local botValue = tLocalRace .. "," .. tGender .. "," .. tSpecial .. "," .. tTabs[1] .. "/" .. tTabs[2] .. "/" .. tTabs[3] .. "," .. tLocalClass .. "," .. tLevel .. "," .. tScore
	if MultiBot.SetGlobalBotEntry then
		MultiBot.SetGlobalBotEntry(tName, botValue)
	end
end

-- New Score formula
MultiBot.ItemLevel = function(pUnit)
	-- Calcule un “ilvl moyen” dans l’esprit de GetAverageItemLevel :
	--  - les slots vides comptent comme ilvl 0 (on divise toujours par 16 ou 17)
	--  - 2M sans Titan's Grip : 16 slots (pas d’off-hand possible)
	--  - 1M / 2x1M / 2M avec Titan's Grip : 17 slots (main + off-hand)
	--  - on garde la même plage de slots que le code d’origine (1..18) et on ignore la chemise.

	local hasTitanGrip = IsSpellKnown and IsSpellKnown(49152) or false

	local hasMainHand  = false
	local mainIs2H     = false
	local hasOffhand   = false

	local score = 0

	for slot = 1, 18 do
		-- On ignore la chemise (slot 4)
		if slot ~= 4 then
			local link = GetInventoryItemLink(pUnit, slot)
			if link then
				local _, _, _, iLevel, _, _, _, _, equipLoc = GetItemInfo(link)
				iLevel = iLevel or 0

				-- Gestion des slots arme principale / main gauche
				if slot == 16 then
					hasMainHand = true
					if equipLoc == "INVTYPE_2HWEAPON" then
						mainIs2H = true
					end
				elseif slot == 17 then
					hasOffhand = true
				end

				score = score + iLevel
			end
		end
	end

	-- Nombre de slots "théoriques" comme le client :
	--  - 16 si 2M sans Titan's Grip
	--  - 17 dès qu’un off-hand est possible ou présent
	local count = 16
	if (hasMainHand and not mainIs2H) or (hasMainHand and hasTitanGrip) or hasOffhand then
		count = 17
	end

	if count <= 0 then
		return 0, 0
	end

	return floor(score / count), count
end

MultiBot.SavePortal = function(pButton)
	local tSave = MultiBot.IF(pButton.goMap == nil, "", pButton.goMap)
	tSave = tSave .. ";" .. (math.ceil(pButton.goX * 1000) / 1000)
	tSave = tSave .. ";" .. (math.ceil(pButton.goY * 1000) / 1000)
	tSave = tSave .. ";" .. (math.ceil(pButton.goZ * 1000) / 1000)
	tSave = tSave .. ";" .. pButton.tip
	tSave = tSave .. ";" .. MultiBot.IF(pButton.state, 1, 0)
	return tSave
end

MultiBot.LoadPortal = function(pButton, pValue)
	local tValue = MultiBot.doSplit(pValue, ";")
	pButton.goMap = tonumber(tValue[1])
	pButton.goX = tonumber(tValue[2])
	pButton.goY = tonumber(tValue[3])
	pButton.goZ = tonumber(tValue[4])
	pButton.tip = tValue[5]
	if(tValue[6] == "1")
	then pButton.setEnable()
	else pButton.setDisable()
	end
end

MultiBot.SpellToMacro = function(pName, pSpell, pTexture)
	--local tGlobal, tAmount = GetNumMacros()
	local _, tAmount = GetNumMacros()

	if(pSpell == nil or pSpell == 0) then
		return SendChatMessage(MultiBot.L("info.spell"), "SAY")
	end
	if(tAmount == 18) then
		return SendChatMessage(MultiBot.L("info.macro"), "SAY")
	end

	local tMacro = string.sub(pName, 1, 14) .. tAmount
	--local tSpell, tIcon, tBody = GetMacroInfo(tMacro)
	local tSpell = GetMacroInfo(tMacro)

	if(tSpell == nil) then
		-- Sécurité : si l’icône n’est pas définie dans MultiBot.spellbook.icons,
		-- on utilise une icône par défaut (index 1).
		local icon = 1
		if MultiBot.spellbook and MultiBot.spellbook.icons then
			icon = MultiBot.spellbook.icons[pTexture] or 1
		end
		CreateMacro(tMacro, icon, "/t " .. pName .. " cast " .. pSpell, true)
	end
	PickupMacro(tMacro)
end

MultiBot.ActionToTarget = function(pAction, oTarget)
	local tName = MultiBot.IF(oTarget == nil, UnitName("target"), oTarget)

	if(tName ~= nil and tName ~= "Unknown Entity") then
		SendChatMessage(pAction, "WHISPER", nil, tName)
		return true
	end

	SendChatMessage(MultiBot.L("info.target"), "SAY")
	return false
end

MultiBot.ActionToTargetOrGroup = function(pAction)
	local tName = UnitName("target")

	if(tName ~= nil and tName ~= "Unknown Entity") then
		SendChatMessage(pAction, "WHISPER", nil, tName)
		return true
	end

	if(GetNumRaidMembers() > 5) then
		SendChatMessage(pAction, "RAID")
		return true
	end

	if(GetNumPartyMembers() > 0) then
		SendChatMessage(pAction, "PARTY")
		return true
	end

	SendChatMessage(MultiBot.L("info.neither"), "SAY")
	return false
end

MultiBot.ActionToGroup = function(pAction)
	if(GetNumRaidMembers() > 5) then
		SendChatMessage(pAction, "RAID")
		return true
	end

	if(GetNumPartyMembers() > 0) then
		SendChatMessage(pAction, "PARTY")
		return true
	end

	SendChatMessage(MultiBot.L("info.group"), "SAY")
	return false
end

MultiBot.SelectToTarget = function(pParent, pIndex, pTexture, pAction, oTarget)
	if(MultiBot.ActionToTarget(pAction, oTarget)) then
		local tFrame = pParent.frames[pIndex]
		local tButton = pParent.buttons[pIndex]
		tButton.setTexture(pTexture)
		tFrame:Hide()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
		return true
	end

	return false
end

MultiBot.SelectToTargetButton = function(pParent, pIndex, pTexture, pAction, oTarget)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) MultiBot.ActionToTarget(pAction, oTarget) end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
	return true
end

MultiBot.SelectToGroupButtonWithTarget = function(pParent, pIndex, pTexture, pAction)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) if(MultiBot.isTarget()) then MultiBot.ActionToGroup(pAction) end end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
	return true
end

MultiBot.SelectToGroupButton = function(pParent, pIndex, pTexture, pAction)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.doLeft = function(pButton) MultiBot.ActionToGroup(pAction) end
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
	return true
end

MultiBot.SelectToGroup = function(pParent, pIndex, pTexture, pAction)
	if(MultiBot.ActionToGroup(pAction)) then
		local tFrame = pParent.frames[pIndex]
		local tButton = pParent.buttons[pIndex]
		tButton.setTexture(pTexture)
		tFrame:Hide()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
		return true
	end

	return false
end

MultiBot.Select = function(pParent, pIndex, pTexture)
	local tFrame = pParent.frames[pIndex]
	local tButton = pParent.buttons[pIndex]
	tButton.setTexture(pTexture)
	tFrame:Hide()
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(tFrame) end
	return true
end

MultiBot.ShowHideSwitch = function(pFrame)
	if(pFrame:IsVisible()) then
		if MultiBot.RestoreCollapsedUnitBarsFromDropdown then
			MultiBot.RestoreCollapsedUnitBarsFromDropdown(pFrame)
		end
		pFrame:Hide()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(pFrame) end
		return false
	end

	if MultiBot.CollapseOtherUnitBarsForDropdown then
		MultiBot.CollapseOtherUnitBarsForDropdown(pFrame)
	end

	pFrame:Show()
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(pFrame) end
	return true
end

MultiBot.RestoreCollapsedUnitBarsFromDropdown = function(targetFrame)
	if not targetFrame then
		return
	end

	local collapsedBars = targetFrame._mbCollapsedBars
	if type(collapsedBars) ~= "table" then
		return
	end

	for index = 1, #collapsedBars do
		local frame = collapsedBars[index]
		if frame and frame.Show then
			frame:Show()
		end
	end

	targetFrame._mbCollapsedBars = nil
	targetFrame._mbCollapsedAutoRestoreNonce = nil
	if type(MultiBot._pendingCollapsedRestoreOwners) == "table" then
		MultiBot._pendingCollapsedRestoreOwners[targetFrame] = nil
	end
end

local function ResolveOwnerUnitBar(targetFrame, unitsFrame)
	if not targetFrame or not unitsFrame then
		return nil
	end

	local ownerBar = targetFrame.parent
	while ownerBar and ownerBar.parent and ownerBar.parent ~= unitsFrame do
		ownerBar = ownerBar.parent
	end

	if not ownerBar or ownerBar.parent ~= unitsFrame then
		return nil
	end

	return ownerBar
end

local function IsFrameDescendantOf(frame, ancestor)
	if not frame or not ancestor then
		return false
	end

	local current = frame
	while current do
		if current == ancestor then
			return true
		end
		if type(current.GetParent) == "function" then
			current = current:GetParent()
		else
			current = current.parent
		end
	end

	return false
end

MultiBot.RestoreAllPendingCollapsedUnitBars = function()
	local pendingOwners = MultiBot._pendingCollapsedRestoreOwners
	if type(pendingOwners) ~= "table" then
		return 0
	end

	local restored = 0
	for ownerBar in pairs(pendingOwners) do
		if ownerBar and type(ownerBar._mbCollapsedBars) == "table" and #ownerBar._mbCollapsedBars > 0 then
			if MultiBot.RestoreCollapsedUnitBarsFromDropdown then
				MultiBot.RestoreCollapsedUnitBarsFromDropdown(ownerBar)
			end
			restored = restored + 1
		end
		pendingOwners[ownerBar] = nil
	end

	return restored
end

local function EnsureCollapsedBarsOutsideClickRestoreHook()
	if MultiBot._outsideCollapsedRestoreHooked then
		return
	end

	local clickRoot = WorldFrame or UIParent
	if not clickRoot or not clickRoot.HookScript then
		return
	end

	clickRoot:HookScript("OnMouseDown", function()
		local unitsFrame = MultiBot.frames
			and MultiBot.frames["MultiBar"]
			and MultiBot.frames["MultiBar"].frames
			and MultiBot.frames["MultiBar"].frames["Units"]
		if not unitsFrame then
			return
		end

		local mouseFocus = GetMouseFocus and GetMouseFocus() or nil
		if IsFrameDescendantOf(mouseFocus, unitsFrame) then
			return
		end

		if MultiBot.RestoreAllPendingCollapsedUnitBars then
			MultiBot.RestoreAllPendingCollapsedUnitBars()
		end
	end)

	MultiBot._outsideCollapsedRestoreHooked = true
end

MultiBot.TransferCollapsedUnitBarsToOwner = function(targetFrame)
	if not targetFrame or type(targetFrame._mbCollapsedBars) ~= "table" then
		return false
	end

	local unitsFrame = MultiBot.frames
		and MultiBot.frames["MultiBar"]
		and MultiBot.frames["MultiBar"].frames
		and MultiBot.frames["MultiBar"].frames["Units"]
	if not unitsFrame or not unitsFrame.frames then
		return false
	end

	local ownerBar = ResolveOwnerUnitBar(targetFrame, unitsFrame)
	if not ownerBar then
		return false
	end

	ownerBar._mbCollapsedBars = ownerBar._mbCollapsedBars or {}
	local existing = {}
	for index = 1, #ownerBar._mbCollapsedBars do
		existing[ownerBar._mbCollapsedBars[index]] = true
	end

	for index = 1, #targetFrame._mbCollapsedBars do
		local frame = targetFrame._mbCollapsedBars[index]
		if frame and not existing[frame] then
			table.insert(ownerBar._mbCollapsedBars, frame)
			existing[frame] = true
		end
	end

	targetFrame._mbCollapsedBars = nil

	if #ownerBar._mbCollapsedBars > 0 and MultiBot.ArmCollapsedUnitBarsAutoRestore then
		MultiBot.ArmCollapsedUnitBarsAutoRestore(ownerBar)
	end

	return true
end

local COLLAPSED_RESTORE_DELAY_SECONDS = 10.0

MultiBot.ArmCollapsedUnitBarsAutoRestore = function(ownerBar, delaySeconds)
	if not ownerBar or type(ownerBar._mbCollapsedBars) ~= "table" or #ownerBar._mbCollapsedBars == 0 then
		return false
	end

	MultiBot._pendingCollapsedRestoreOwners = MultiBot._pendingCollapsedRestoreOwners or {}
	MultiBot._pendingCollapsedRestoreOwners[ownerBar] = true
	EnsureCollapsedBarsOutsideClickRestoreHook()

	ownerBar._mbCollapsedAutoRestoreNonce = (ownerBar._mbCollapsedAutoRestoreNonce or 0) + 1
	local nonce = ownerBar._mbCollapsedAutoRestoreNonce
	local delay = delaySeconds
	if type(delay) ~= "number" or delay <= 0 then
		delay = COLLAPSED_RESTORE_DELAY_SECONDS
	end

	MultiBot.TimerAfter(delay, function()
		if not ownerBar then
			return
		end
		if ownerBar._mbCollapsedAutoRestoreNonce ~= nonce then
			return
		end
		if type(ownerBar._mbCollapsedBars) ~= "table" or #ownerBar._mbCollapsedBars == 0 then
			return
		end
		if ownerBar.IsShown and ownerBar:IsShown() and MultiBot.RestoreCollapsedUnitBarsFromDropdown then
			MultiBot.RestoreCollapsedUnitBarsFromDropdown(ownerBar)
		end
	end)

	return true
end

MultiBot.CollapseOtherUnitBarsForDropdown = function(targetFrame)
	if not targetFrame or not targetFrame.parent then
		return
	end

	if targetFrame._mbSkipAutoCollapse then
		targetFrame._mbDropdownManaged = nil
		targetFrame._mbCollapsedBars = nil
		return
	end

	if MultiBot.GetDisableAutoCollapse and MultiBot.GetDisableAutoCollapse() then
		targetFrame._mbDropdownManaged = nil
		targetFrame._mbCollapsedBars = nil
		return
	end

	local unitsFrame = MultiBot.frames
		and MultiBot.frames["MultiBar"]
		and MultiBot.frames["MultiBar"].frames
		and MultiBot.frames["MultiBar"].frames["Units"]
	if not unitsFrame or not unitsFrame.frames then
		return
	end

	local ownerBar = ResolveOwnerUnitBar(targetFrame, unitsFrame)
	if not ownerBar then
		return
	end

	-- On ne collapse les autres barres que pour l'ouverture d'un sous-menu
	-- (pas lors de l'ouverture/fermeture de la barre du bot elle-même).
	if targetFrame == ownerBar then
		return
	end

	local collapsedBars = {}
	for key, frame in pairs(unitsFrame.frames) do
		if frame ~= ownerBar and key ~= "Alliance" and key ~= "Control"
				and frame and frame.Hide and frame.IsShown and frame:IsShown() then
			table.insert(collapsedBars, frame)
			frame:Hide()
		end
	end

	targetFrame._mbDropdownManaged = true
	targetFrame._mbCollapsedBars = collapsedBars
end

MultiBot.OnOffActionToTarget = function(pButton, pOn, pOff, pTarget)
	if(pButton.state) then
		MultiBot.ActionToTarget(pOff, pTarget)
		pButton.setDisable()
		return false
	else
		MultiBot.ActionToTarget(pOn, pTarget)
		pButton.setEnable()
		return true
	end
end

MultiBot.OnOffSwitch = function(pButton)
	if(pButton.state) then
		pButton.setDisable()
		return false
	end

	pButton.setEnable()
	return true
end

local function _mbEnsureRuntimeTable(key)
	if MultiBot.Store and MultiBot.Store.EnsureRuntimeTable then
		return MultiBot.Store.EnsureRuntimeTable(key)
	end
	MultiBot[key] = MultiBot[key] or {}
	return MultiBot[key]
end

local function _mbGetRuntimeTable(key)
	if MultiBot.Store and MultiBot.Store.GetRuntimeTable then
		return MultiBot.Store.GetRuntimeTable(key)
	end
	local value = MultiBot[key]
	if type(value) ~= "table" then
		return nil
	end
	return value
end

local function _mbEnsureTableField(parent, key, defaultValue)
	if MultiBot.Store and MultiBot.Store.EnsureTableField then
		return MultiBot.Store.EnsureTableField(parent, key, defaultValue)
	end
	if parent[key] == nil then
		parent[key] = defaultValue ~= nil and defaultValue or {}
	end
	return parent[key]
end

local _MB_EMPTY_TABLE = {}

-- CLICK BLOCKER --
-- Fond invisible placé sous les barres de boutons (et leurs zones extensibles) afin
-- d'empêcher les clics de "traverser" l'UI dans les espaces entre boutons.

MultiBot._clickBlockerQueue = _mbEnsureRuntimeTable("_clickBlockerQueue")

local function _mbQueueClickBlockerUpdate(f)
	if(not f or not f.clickBlocker) then return end
	MultiBot._clickBlockerQueue[f] = true
	if MultiBot._clickBlockerFlushQueued then return end
	MultiBot._clickBlockerFlushQueued = true

	local function flushQueue()
		MultiBot._clickBlockerFlushQueued = false

		local queue = MultiBot._clickBlockerQueue
		MultiBot._clickBlockerQueue = {}
		for frame in pairs(queue) do
			if(MultiBot.UpdateClickBlocker) then
				MultiBot.UpdateClickBlocker(frame)
			end
		end
	end

	local nextTick = MultiBot.NextTick
	if type(nextTick) == "function" then
		nextTick(flushQueue)
	else
		local timerAfter = MultiBot.TimerAfter or _G.TimerAfter
		if type(timerAfter) == "function" then
			timerAfter(0, flushQueue)
		else
			flushQueue()
		end
	end
end

-- Demande une mise à jour pour le frame et tous ses parents MultiBot.newFrame (cascade).
function MultiBot.RequestClickBlockerUpdate(frame)
	local f = frame
	while(f) do
		_mbQueueClickBlockerUpdate(f)
		f = f.parent
	end
end

-- Recalcule la zone à bloquer à partir des coordonnées réelles (écran) de tous les boutons visibles.
function MultiBot.UpdateClickBlocker(frame)
	local cb = frame and frame.clickBlocker
	if(not cb) then return end

	if(not frame:IsShown()) then
		cb:Hide()
		return
	end

	local brx, bry = frame:GetRight(), frame:GetBottom()
	if(not brx or not bry) then
		cb:Hide()
		return
	end

	local minL, maxR, minB, maxT
	local foundButton = false

	local function consider(l, r, b, t)
		if(not l or not r or not b or not t) then return end
		if(not minL or l < minL) then minL = l end
		if(not maxR or r > maxR) then maxR = r end
		if(not minB or b < minB) then minB = b end
		if(not maxT or t > maxT) then maxT = t end
	end

	local function scan(f)
		if(not f or not f.IsShown or not f:IsShown()) then return end

		if(f.buttons) then
			for _, b in pairs(f.buttons) do
				if(b and b.IsVisible and b:IsVisible()) then
					consider(b:GetLeft(), b:GetRight(), b:GetBottom(), b:GetTop())
					foundButton = true
				end
			end
		end
	end

	scan(frame)

	if(not foundButton) then
		cb:Hide()
		return
	end

	if(not minL or not maxR or not minB or not maxT) then
		cb:Hide()
		return
	end

	local pad = 2
	local minX = (minL - brx) - pad
	local maxX = (maxR - brx) + pad
	local minY = (minB - bry) - pad
	local maxY = (maxT - bry) + pad

	cb:ClearAllPoints()
	cb:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", maxX, minY)
	cb:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT", minX, maxY)
	cb:SetFrameLevel(frame:GetFrameLevel())
	cb:Show()
end

-- MULTIBOT:FRAME --

MultiBot.newFrame = function(pParent, pX, pY, pSize, oWidth, oHeight, oAlign)
	local frame = CreateFrame("Frame", nil, pParent)
	frame:SetPoint(MultiBot.IF(oAlign ~= nil, oAlign, "BOTTOMRIGHT"), pX, pY)
	frame:Show()

	if(oWidth ~= nil and oHeight ~= nil)
	then frame:SetSize(oWidth, oHeight)
	else frame:SetSize(pSize, pSize)
	end

	frame.buttons = {}
	frame.frames = {}
	frame.texts = {}

	frame.parent = pParent
	frame.height = MultiBot.IF(oHeight ~= nil, oHeight, pSize)
	frame.width = MultiBot.IF(oWidth ~= nil, oWidth, pSize)
	frame.align = MultiBot.IF(oAlign ~= nil, oAlign, "BOTTOMRIGHT")
	frame.size = pSize
	frame.x = pX
	frame.y = pY

	-- click blocker: absorbe les clics dans les espaces entre boutons
	frame.clickBlocker = CreateFrame("Frame", nil, frame)
	frame.clickBlocker:SetFrameLevel(frame:GetFrameLevel())
	frame.clickBlocker:EnableMouse(true)
	frame.clickBlocker.texture = frame.clickBlocker:CreateTexture(nil, "BACKGROUND")
	frame.clickBlocker.texture:SetAllPoints(frame.clickBlocker)
	frame.clickBlocker.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	frame.clickBlocker.texture:SetVertexColor(0, 0, 0, 0) -- fond totalement transparent
	frame.clickBlocker:SetAllPoints(frame)

	frame:HookScript("OnShow", function() if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(frame) end end)
	frame:HookScript("OnHide", function() if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(frame) end end)
	-- ADD --

	frame.addTexture = function(pTexture)
		if(frame.texture ~= nil) then frame.texture:Hide() end
		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		frame.texture:SetTexture(MultiBot.SafeTexturePath(pTexture))
		frame.texture:SetAllPoints(frame)
		frame.texture:Show()
		return frame.texture
	end

	frame.addModel = function(pName, x, y, pWidth, pHeight, oScale)
		if(frame.model ~= nil) then frame.model:Hide() end
		frame.model = CreateFrame("DressUpModel", "MyModel" .. pName, frame)
		frame.model:SetPoint("CENTER", x, y)
		frame.model:SetSize(pWidth, pHeight)
		frame.model:SetUnit(pName)
		if(oScale ~= nil) then frame.model:SetScale(oScale) end
		return frame.model
	end

	frame.addText = function(pIndex, pText, pAlign, x, y, fontSize)
		if(frame.texts[pIndex] ~= nil) then frame.texts[pIndex]:Hide() end
		frame.texts[pIndex] = frame:CreateFontString(nil, "ARTWORK")
        frame.texts[pIndex]:SetFont("Fonts\\ARIALN.ttf", fontSize, "PLAIN")
        frame.texts[pIndex]:SetPoint(pAlign, x, y)
		frame.texts[pIndex]:SetText(pText)
		frame.texts[pIndex]:Show()
		return frame.texts[pIndex]
	end

	frame.wowButton = function(pName, x, y, pWidth, pHeight, size)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		frame.buttons[pName] = MultiBot.wowButton(frame, pName, x, y, pWidth, pHeight, size)
		return frame.buttons[pName]
	end

	frame.addButton = function(pName, x, y, pTexture, pTip, oTemplate)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		frame.buttons[pName] = MultiBot.newButton(frame, x, y, frame.size, pTexture, pTip, oTemplate)
		return frame.buttons[pName]
	end

	frame.movButton = function(pName, x, y, size, pTip, oFrame)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		frame.buttons[pName] = MultiBot.movButton(frame, x, y, size, pTip, oFrame)
		return frame.buttons[pName]
	end

	frame.boxButton = function(pName, x, y, size, pState)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		frame.buttons[pName] = MultiBot.boxButton(frame, x, y, size, pState)
		return frame.buttons[pName]
	end

	frame.catButton = function(pName, x, y, pWidth, pHeight)
		if(frame.buttons[pName] ~= nil) then frame.buttons[pName]:Hide() end
		frame.buttons[pName] = MultiBot.catButton(frame, x, y, pWidth, pHeight)
		return frame.buttons[pName]
	end

	frame.addFrame = function(pName, x, y, oSize, subWidth, subHeight)
		if(frame.frames[pName] ~= nil) then frame.frames[pName]:Hide() end
		frame.frames[pName] = MultiBot.newFrame(frame, x, y, MultiBot.IF(oSize ~= nil, oSize, frame.size - 4), subWidth, subHeight)
		return frame.frames[pName]
	end

	-- SET --

    frame.setPoint = function(x, y)
        frame:SetPoint("BOTTOMRIGHT", x, y)
        frame.x = x
        frame.y = y
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(frame) end
		return frame
	end

	frame.setButton = function(pIndex, pTexture, pTip)
		frame.buttons[pIndex].setButton(pTexture, pTip)
		return frame
	end

	frame.setTexture = function(pTexture)
		frame.texture:SetTexture(MultiBot.SafeTexturePath(pTexture))
		frame.texture:SetAllPoints(frame)
		frame.texture:Show()
		return frame
	end

	frame.setText = function(pIndex, pText)
		frame.texts[pIndex]:SetText(pText)
		frame.texts[pIndex]:Show()
		return frame
	end

	frame.setLevel = function(pLevel)
		frame:SetFrameLevel(pLevel)
		return frame
	end

	frame.setAlpha = function(pAlpha)
		frame:SetAlpha(pAlpha)
		return frame
	end

	-- GET --

	frame.getButton = function(pIndex)
		if(frame.buttons[pIndex] ~= nil) then
			return frame.buttons[pIndex]
		end

		for key, value in pairs(frame.frames) do
			local tButton = value.getButton(pIndex)
			if(tButton ~= nil) then return tButton end
		end

		return nil
	end

	frame.getFrame = function(pIndex)
		if(frame.frames[pIndex] ~= nil) then
			return frame.frames[pIndex]
		end

		for key, value in pairs(frame.frames) do
			local tFrame = value.getFrame(pIndex)
			if(tFrame ~= nil) then return tFrame end
		end

		return nil
	end

	frame.getClass = function()
		if(frame.class ~= nil) then return frame.class end
		return frame.parent.getClass()
	end

	frame.getName = function()
		if(frame.name ~= nil) then return frame.name end
		return frame.parent.getName()
	end

	frame.get = function()
		if(frame.name ~= nil) then return frame end
		return frame.parent.get()
	end

	-- DO --

	frame.doShow = function()
		frame:Show()
		return frame
	end

	frame.doHide = function()
		frame:Hide()
		return frame
	end

	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(frame) end

	return frame
end

-- MULTIBOT:BUTTON --

MultiBot.newButton = function(pParent, pX, pY, pSize, pTexture, pTip, oTemplate)
	local button = CreateFrame("Button", nil, pParent, MultiBot.IF(oTemplate ~= nil, oTemplate, "ActionButtonTemplate"))
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pSize, pSize)
	button:Show()

	button.icon = button:CreateTexture(nil, "BACKGROUND")
	button.icon:SetTexture(MultiBot.SafeTexturePath(pTexture))
	button.icon:SetAllPoints(button)
	button.icon:Show()

	button.border = button:CreateTexture(nil, "ARTWORK")
	button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
	button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.border:SetSize(pSize + 4, pSize + 4)
	button.border:Hide()

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
	button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
	button:SetNormalTexture("")

    button.texture = MultiBot.SafeTexturePath(pTexture)
	button.parent = pParent
	button.size = pSize
	button.tip = pTip
	button.x = pX
	button.y = pY
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	button:HookScript("OnShow", function() if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end end)
	button:HookScript("OnHide", function() if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end end)

	-- ADD --

	button.addMacro = function(pType, pMacro)
		button:SetAttribute("macrotext", pMacro);
		button:SetAttribute(pType, "macro");
		return button
	end

	-- SET --

    button.setPoint = function(x, y)
        button:SetPoint("BOTTOMRIGHT", x, y)
        button.x = x
        button.y = y
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		return button
	end

    button.setButton = function(texture, tip)
        local safe = MultiBot.SafeTexturePath(texture)
        button.icon:SetTexture(safe)
		button.icon:SetAllPoints(button)
        button.texture = safe
        button.tip = tip
		return button
	end

    button.setTexture = function(texture)
        local safe = MultiBot.SafeTexturePath(texture)
        button.icon:SetTexture(safe)
		button.icon:SetAllPoints(button)
        button.texture = safe
		return button
	end

    button.setHighlight = function(texture)
        button:SetHighlightTexture(texture, "ADD")
		return button
	end

	button.setAmount = function(pAmount)
		if(button.amount ~= nil) then button.amount:Hide() end
		button.amount = button:CreateFontString(nil, "ARTWORK")
		button.amount:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
		button.amount:SetPoint("BOTTOMRIGHT", 0, 0)
		button.amount:SetText(pAmount)
		return button
	end

	button.setDisable = function(oBorder)
		button.icon:SetDesaturated(1)
		if(oBorder == nil) then oBorder = true end
		if(oBorder) then button.border:Hide() end
		button.state = false
		return button
	end

	button.setEnable = function(oBorder)
		button.icon:SetDesaturated(nil)
		if(oBorder == nil) then oBorder = true end
		if(oBorder) then button.border:Show() end
		button.state = true
		return button
	end

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- DO --

	button.doHide = function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)
		button:Hide()
		return button
	end

	button.doShow = function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)
		button:Show()
		return button
	end

	-- EVENT --

	button:SetScript("OnEnter", function()
		if(type(button.tip) == "string") then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 0 - button.size, 2)
			if(string.sub(button.tip, 1, 1) == "|") then GameTooltip:SetHyperlink(button.tip) else GameTooltip:SetText(button.tip) end
			GameTooltip:Show()
			return
		end

		if(type(button.tip) == "table") then
			button.tip:Show()
			return
		end
	end)

	button:SetScript("OnLeave", function()
		button:SetPoint("BOTTOMRIGHT", button.x, button.y)
		button:SetSize(button.size, button.size)

		button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		button.border:SetSize(button.size + 4, button.size + 4)

		if(type(button.tip) == "string") then GameTooltip:Hide() end
		if(type(button.tip) == "table") then button.tip:Hide() end
	end)

	button:SetScript("PostClick", function(pSelf, pEvent)
		button:SetPoint("BOTTOMRIGHT", button.x - 1, button.y + 1)
		button:SetSize(button.size - 2, button.size - 2)

		button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		button.border:SetSize(button.size + 2, button.size + 2)

		if(type(button.tip) == "string") then GameTooltip:Hide() end
		if(type(button.tip) == "table") then button.tip:Hide() end

		if(pEvent == "RightButton" and button.doRight ~= nil) then button.doRight(button) end
		if(pEvent == "LeftButton" and button.doLeft ~= nil) then button.doLeft(button) end
		if MultiBot.MainBarAutoHide_NotifyInteraction then
			MultiBot.MainBarAutoHide_NotifyInteraction()
		end

		if button.parent and button.parent._mbDropdownManaged then
			if MultiBot.TransferCollapsedUnitBarsToOwner then
				MultiBot.TransferCollapsedUnitBarsToOwner(button.parent)
			elseif MultiBot.RestoreCollapsedUnitBarsFromDropdown then
				MultiBot.RestoreCollapsedUnitBarsFromDropdown(button.parent)
			end
			button.parent:Hide()
			if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		end
	end)

	return button
end

-- BUTTON:WOW --

MultiBot.wowButton = function(pParent, pName, pX, pY, pWidth, pHeight, pSize)
	local button = CreateFrame("Button", nil, pParent, "UIPanelButtonTemplate")
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pWidth, pHeight)
	button:Show()

	button.text = button:CreateFontString(nil, "ARTWORK")
	button.text:SetFont("Fonts\\ARIALN.ttf", pSize, "OUTLINE")
	button.text:SetPoint("CENTER", 0, 0)
	button.text:SetText("|cffffcc00" .. pName .. "|r")
	button.text:Show()

	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonDown", "RightButtonDown")

	button.parent = pParent
	button.state = true
	button.y = pY
	button.x = pX

	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- SET --

	button.setDisable = function()
		button:GetNormalTexture():SetDesaturated(1)
		button.state = false
		return button
	end

	button.setEnable = function()
		button:GetNormalTexture():SetDesaturated(nil)
		button.state = true
		return button
	end

	-- DO --

	button.doHide = function()
		button:Hide()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	button.doShow = function()
		button:Show()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	-- EVENT --

	button:SetScript("OnEnter", function()
	end)

	button:SetScript("OnLeave", function()
		button.text:SetPoint("CENTER", 0, 0)
	end)

	button:SetScript("OnClick", function(pSelf, pEvent)
		button.text:SetPoint("CENTER", -1, -1)
		if(pEvent == "RightButton" and button.doRight ~= nil) then button.doRight(button) end
		if(pEvent == "LeftButton" and button.doLeft ~= nil) then button.doLeft(button) end
	end)

	return button
end

-- BUTTON:MOVE --

MultiBot.movButton = function(pParent, pX, pY, pSize, pTip, oFrame)
	local button = CreateFrame("Button", nil, pParent)
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pSize, pSize)
	button:Show()

	button:EnableMouse(true)
	button:RegisterForClicks("RightButtonDown")
	button:RegisterForDrag("RightButton")

	button.parent = pParent
	button.frame = oFrame
	button.size = pSize
	button.tip = pTip
	button.x = pX
	button.y = pY

	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	-- EVENT --

	button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 0 - button.size, 2)
		GameTooltip:SetText(button.tip)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(pSelf, pEvent)
		GameTooltip:Hide()
	end)

	button:SetScript("OnDragStart", function()
		if(button.frame ~= nil) then button.frame:StartMoving() else button.parent:StartMoving() end
	end)

	button:SetScript("OnDragStop", function()
		if(button.frame ~= nil) then button.frame:StopMovingOrSizing() else button.parent:StopMovingOrSizing() end
	end)

	return button
end

-- BUTTON:BOX --

MultiBot.boxButton = function(pParent, pX, pY, pSize, pState)
	local button = CreateFrame("CheckButton", nil, pParent, "ChatConfigCheckButtonTemplate");
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetHitRectInsets(0, 0, 0, 0)
	button:SetSize(pSize, pSize)
	button:SetChecked(pState)
	button:Show()

	button.parent = pParent
	button.state = pState
	button.size = pSize
	button.x = pX
	button.y = pY

	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	-- GET --

	button.getButton = function(pIndex)
		return button.parent.get().getButton(pIndex)
	end

	button.getFrame = function(pIndex)
		return button.parent.get().getFrame(pIndex)
	end

	button.getClass = function()
		return button.parent.getClass()
	end

	button.getName = function()
		return button.parent.getName()
	end

	button.get = function()
		return button.parent.get()
	end

	-- DO --

	button.doHide = function()
		button:Hide()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	button.doShow = function()
		button:Show()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
		return button
	end

	-- EVENT --

	button:SetScript("OnClick", function()
		if(button.doClick ~= nil) then button.doClick(button) end
	end)

	return button;
end

-- BUTTON REORDER (SHIFT + RIGHT CLICK) --

local function _mbParseButtonLayout(raw)
	local parsed = {}
	if(type(raw) ~= "string" or raw == "") then
		return parsed
	end

	for token in string.gmatch(raw, "([^;]+)") do
		local name, x, y = string.match(token, "^([^:]+):(-?%d+),(-?%d+)$")
		if(name and x and y) then
			parsed[name] = { x = tonumber(x), y = tonumber(y) }
		end
	end

	return parsed
end

local function _mbSerializeButtonLayout(entries)
	local chunks = {}
	for _, entry in ipairs(entries) do
		local button = entry.button
		if(button and type(button.x) == "number" and type(button.y) == "number") then
			table.insert(chunks, string.format("%s:%d,%d", entry.id or entry.name, button.x, button.y))
		end
	end
	return table.concat(chunks, ";")
end

local function _mbApplyLinkedFrameOffset(entry)
	if(not entry or not entry.frameName) then
		return
	end

	local button = entry.button
	local frame = entry.frame
	if(not button or not frame or not frame.setPoint) then
		return
	end

	local offsetX = entry.frameOffsetX or 0
	local offsetY = entry.frameOffsetY or 0
	frame.setPoint(button.x + offsetX, button.y + offsetY)
end

function MultiBot.BindShiftRightSwapButtons(host, contextKey, entries)
	if(not host or not contextKey or type(entries) ~= "table") then
		return nil
	end

	local shiftSwapGlobal = _mbEnsureRuntimeTable("_mbShiftSwapGlobal")
	local registeredLayoutKeys = _mbEnsureRuntimeTable("_mbRegisteredButtonLayoutKeys")
	registeredLayoutKeys["ButtonLayout:" .. contextKey] = true
	local state = shiftSwapGlobal[contextKey]
	if(not state) then
		local saveKey = "ButtonLayout:" .. contextKey
		local saved = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(saveKey) or nil
		state = {
			selected = nil,
			saveKey = saveKey,
			parsed = _mbParseButtonLayout(saved),
			entries = {},
			byName = {},
		}
		shiftSwapGlobal[contextKey] = state
	end

	local function persist()
		if(MultiBot.SetSavedLayoutValue) then
			MultiBot.SetSavedLayoutValue(state.saveKey, _mbSerializeButtonLayout(state.entries))
		end
	end

	local function paintEntry(entryRec, r, g, b, a)
		local button = entryRec and entryRec.button
		if(not button) then
			return
		end

		if(button.icon and button.icon.SetVertexColor) then
			button.icon:SetVertexColor(r or 1, g or 1, b or 1)
		end
		if(button.SetAlpha) then
			button:SetAlpha(a or 1)
		end
	end

	local function clearVisualState(entryRec)
		paintEntry(entryRec, 1, 1, 1, 1)
	end

	local function applySelectionVisuals()
		for _, entryRec in ipairs(state.entries or _MB_EMPTY_TABLE) do
			clearVisualState(entryRec)
		end

		if(state.selected) then
			paintEntry(state.selected, 1, 0.85, 0.35, 1)
		end

		if(state.hovered and state.hovered ~= state.selected) then
			paintEntry(state.hovered, 0.6, 1, 0.6, 1)
			if(state.selected) then
				paintEntry(state.selected, 1, 0.85, 0.35, 0.9)
			end
		end
	end

	local function clearSelectionState()
		state.selected = nil
		state.hovered = nil
		state.previewTarget = nil
		applySelectionVisuals()
	end

	local function swapButtons(entryA, entryB)
		local buttonA = entryA and entryA.button
		local buttonB = entryB and entryB.button
		if(not buttonA or not buttonB or not buttonA.setPoint or not buttonB.setPoint) then
			return
		end

		local absARight, absABottom = buttonA:GetRight(), buttonA:GetBottom()
		local absBRight, absBBottom = buttonB:GetRight(), buttonB:GetBottom()
		if(not absARight or not absABottom or not absBRight or not absBBottom) then
			return
		end

		local parentA = buttonA:GetParent()
		local parentB = buttonB:GetParent()
		if(not parentA or not parentB) then
			return
		end

		local parentARight, parentABottom = parentA:GetRight(), parentA:GetBottom()
		local parentBRight, parentBBottom = parentB:GetRight(), parentB:GetBottom()
		if(not parentARight or not parentABottom or not parentBRight or not parentBBottom) then
			return
		end

		local newAX, newAY = absBRight - parentARight, absBBottom - parentABottom
		local newBX, newBY = absARight - parentBRight, absABottom - parentBBottom
		buttonA.setPoint(newAX, newAY)
		buttonB.setPoint(newBX, newBY)

		_mbApplyLinkedFrameOffset(entryA)
		_mbApplyLinkedFrameOffset(entryB)
		persist()
	end

	local function wrapButton(entryRec)
		local button = entryRec and entryRec.button
		if(not button) then
			return
		end

		local originalDoRight = button.doRight
		button.doRight = function(btn)
			if(IsShiftKeyDown()) then
				if(state.selected == nil) then
					state.selected = entryRec
					state.hovered = nil
					state.previewTarget = nil
					applySelectionVisuals()
					if(UIErrorsFrame) then
						UIErrorsFrame:AddMessage(MultiBot.L("ui.swap.source_prefix") .. (entryRec.id or entryRec.name), 1, 0.82, 0, 1)
					end
					return
				end

				if(state.selected == entryRec) then
					clearSelectionState()
					if(UIErrorsFrame) then
						UIErrorsFrame:AddMessage(MultiBot.L("ui.swap.cancelled"), 1, 0.25, 0.25, 1)
					end
					return
				end

				local sourceEntry = state.selected
				clearSelectionState()
				swapButtons(sourceEntry, entryRec)
				if(UIErrorsFrame) then
					UIErrorsFrame:AddMessage((sourceEntry.id or sourceEntry.name) .. " <-> " .. (entryRec.id or entryRec.name), 0.25, 1, 0.25, 1)
				end
				return
			end

			if(originalDoRight) then
				originalDoRight(btn)
			end
		end

		button._mbSwapWrapped = true
		button:HookScript("OnEnter", function()
			if(state.selected and state.selected ~= entryRec) then
				state.hovered = entryRec
				applySelectionVisuals()
				if(UIErrorsFrame and state.previewTarget ~= entryRec) then
					state.previewTarget = entryRec
					UIErrorsFrame:AddMessage(MultiBot.L("ui.swap.preview_prefix") .. (state.selected.id or state.selected.name) .. " <-> " .. (entryRec.id or entryRec.name), 1, 1, 0.4, 1)
				end
			end
		end)
		button:HookScript("OnLeave", function()
			if(state.hovered == entryRec) then
				state.hovered = nil
				applySelectionVisuals()
			end
		end)
	end

	for _, entry in ipairs(entries) do
		local id = entry and (entry.id or entry.name) or nil
		if(id and not state.byName[id]) then
			state.byName[id] = true

			local button = host.buttons and host.buttons[entry.name]
			local frame = entry.frameName and host.frames and host.frames[entry.frameName] or nil
				local entryRec = {
					id = id,
					name = entry.name,
					frameName = entry.frameName,
					button = button,
					frame = frame,
					defaultX = button and button.x or nil,
					defaultY = button and button.y or nil,
				}
			table.insert(state.entries, entryRec)

			if(button and frame and type(frame.x) == "number" and type(frame.y) == "number") then
				entryRec.frameOffsetX = frame.x - button.x
				entryRec.frameOffsetY = frame.y - button.y
			end

			local savedPoint = state.parsed and state.parsed[id]
			if(button and savedPoint and button.setPoint) then
				button.setPoint(savedPoint.x, savedPoint.y)
			end
			_mbApplyLinkedFrameOffset(entryRec)
			wrapButton(entryRec)
		end
	end

	return state
end

function MultiBot.ResetButtonLayoutContext(contextKey, clearPersistedValue)
	local shiftSwapGlobal = _mbGetRuntimeTable("_mbShiftSwapGlobal")
	if(not contextKey or not shiftSwapGlobal) then
		return false
	end

	local state = shiftSwapGlobal[contextKey]
	if(not state) then
		return false
	end

	for _, entryRec in ipairs(state.entries or _MB_EMPTY_TABLE) do
		local button = entryRec and entryRec.button
		local defaultX = entryRec and entryRec.defaultX
		local defaultY = entryRec and entryRec.defaultY
		if(button and button.setPoint and type(defaultX) == "number" and type(defaultY) == "number") then
			button.setPoint(defaultX, defaultY)
		end
		_mbApplyLinkedFrameOffset(entryRec)
	end

	if(clearPersistedValue and MultiBot.SetSavedLayoutValue) then
		MultiBot.SetSavedLayoutValue(state.saveKey, nil)
	end

	state.parsed = {}
	state.selected = nil
	return true
end

function MultiBot.ApplySavedButtonLayout(contextKey)
	local shiftSwapGlobal = _mbGetRuntimeTable("_mbShiftSwapGlobal")
	if(not contextKey or not shiftSwapGlobal) then
		return false
	end

	local state = shiftSwapGlobal[contextKey]
	if(not state) then
		return false
	end

	local raw = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(state.saveKey) or nil
	state.parsed = _mbParseButtonLayout(raw)

	for _, entryRec in ipairs(state.entries or _MB_EMPTY_TABLE) do
		local button = entryRec and entryRec.button
		local id = entryRec and (entryRec.id or entryRec.name)
		local savedPoint = id and state.parsed and state.parsed[id] or nil
		if(button and savedPoint and button.setPoint) then
			button.setPoint(savedPoint.x, savedPoint.y)
		end
		_mbApplyLinkedFrameOffset(entryRec)
	end

	return true
end

-- BUTTON:CAT --

MultiBot.catButton = function(pParent, pX, pY, pWidth, pHeight)
	local button = CreateFrame("CheckButton", nil, pParent, "SecureActionButtonTemplate");
	button:SetPoint("BOTTOMRIGHT", pX, pY)
	button:SetSize(pWidth, pHeight)
	button:Show()

	button.parent = pParent
	if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end

	button:HookScript("OnShow", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	button:HookScript("OnHide", function()
		if(MultiBot.RequestClickBlockerUpdate) then MultiBot.RequestClickBlockerUpdate(button.parent) end
	end)

	-- EVENT --

	button:SetScript("OnClick", function()
		if(button.doClick ~= nil) then button.doClick(button) end
	end)

	return button;
end

-- MULTIBOT:ADD --

MultiBot.addFrame = function(pName, pX, pY, pSize)
	local tFrame = MultiBot.newFrame(MultiBot, pX, pY, pSize)
	MultiBot.frames[pName] = tFrame
	return tFrame
end

-- MULTIBOT: SELL ALL BOTS --
-- Envoie une commande de vente à tous les bots listés dans l’onglet "Units".
-- pCommand : "s *" (tout le gris) ou "s vendor" (tout ce qui est vendable).
MultiBot.SellAllBots = function(pCommand)
	-- Par défaut : vendre tous les objets gris (safe)
	pCommand = pCommand or "s *"

	if not MultiBot.isTarget or not MultiBot.isTarget() then
		return 0
	end

	local frames = MultiBot.frames
	if not frames then return 0 end

	local multiBar = frames["MultiBar"]
	if not multiBar or not multiBar.frames or not multiBar.frames["Units"] then
		return 0
	end

	local units = multiBar.frames["Units"]
	if not units.buttons then
		return 0
	end

	CancelTrade()

	local count = 0

	for key, btn in pairs(units.buttons) do
		if type(btn) == "table" then
			local botName = btn.name or (btn.getName and btn.getName()) or key
			if botName and botName ~= "" then
				SendChatMessage(pCommand, "WHISPER", nil, botName)
				count = count + 1
			end
		end
	end

	-- Si une fenêtre d’inventaire est ouverte, on la rafraîchit pour le bot affiché
	if MultiBot.inventory and MultiBot.inventory:IsVisible() and MultiBot.RefreshInventory then
		MultiBot.RefreshInventory(0.5)
	end

	return count
end

-- MULTIBOT: MAINTENANCE ALL BOTS --
-- Envoie la commande "maintenance" à tous les bots listés dans l’onglet "Units".
MultiBot.MaintenanceAllBots = function()
	local frames = MultiBot.frames
	if not frames then return 0 end

	local multiBar = frames["MultiBar"]
	if not multiBar or not multiBar.frames or not multiBar.frames["Units"] then
		return 0
	end

	local units = multiBar.frames["Units"]
	if not units.buttons then
		return 0
	end

	CancelTrade()

	local count = 0

	for key, btn in pairs(units.buttons) do
		if type(btn) == "table" then
			local botName = btn.name or (btn.getName and btn.getName()) or key
			if botName and botName ~= "" then
				SendChatMessage("maintenance", "WHISPER", nil, botName)
				count = count + 1
			end
		end
	end

	-- Si une fenêtre d’inventaire est ouverte, on peut la rafraîchir pour refléter d’éventuels changements
	if MultiBot.inventory and MultiBot.inventory:IsVisible() and MultiBot.RefreshInventory then
		MultiBot.RefreshInventory(0.5)
	end

	return count
end

MultiBot.addSelf = function(pClass, pName)
  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local btn   = units.buttons[pName]
  local tClass = (MultiBot.toClass and MultiBot.toClass(pClass)) or (pClass or "Unknown")
  tClass = tClass or "Unknown"
  if not btn then
   btn = units.addButton(pName, 0, 0, "inv_misc_head_clockworkgnome_01", MultiBot.L("tips.unit.selfbot"))
   btn:Hide()
  end
  -- Assurer la présence dans les index (sans doublons)
  local byClass = _mbEnsureTableField(MultiBot.index.classes.players, tClass, {})
  local found = false
  for i=1,#byClass do if byClass[i] == pName then found = true; break end end
  if not found then table.insert(byClass, pName) end
  local pidx = MultiBot.index.players
  local found2 = false
  for i=1,#pidx do if pidx[i] == pName then found2 = true; break end end
  if not found2 then table.insert(pidx, pName) end
  btn.roster = "players"
  btn.class  = tClass
  btn.name   = pName
  if MultiBot.IsFavorite and MultiBot.IsFavorite(pName) and MultiBot.UpdateFavoritesIndex then
    MultiBot.UpdateFavoritesIndex()
  end
  return btn
end

MultiBot.addPlayer = function(pClass, pName)
  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local btn   = units.buttons[pName]
  local tClass = (MultiBot.toClass and MultiBot.toClass(pClass)) or (pClass or "Unknown")
  tClass = tClass or "Unknown"
  local tTexture = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if not btn then
    btn = units.addButton(pName, 0, 0, tTexture, MultiBot.toTip(tClass, nil, pName))
    btn:Hide()
  else
    if btn.icon and tTexture then btn.icon:SetTexture(MultiBot.SafeTexturePath(tTexture)) end
  end
  -- Assurer la présence dans les index (sans doublons)
  local byClass = _mbEnsureTableField(MultiBot.index.classes.players, tClass, {})
  local found = false
  for i=1,#byClass do if byClass[i] == pName then found = true; break end end
  if not found then table.insert(byClass, pName) end
  local pidx = MultiBot.index.players
  local found2 = false
  for i=1,#pidx do if pidx[i] == pName then found2 = true; break end end
  if not found2 then table.insert(pidx, pName) end
  btn.roster = "players"
  btn.class  = tClass
  btn.name   = pName
  return btn
end

local function MB_InsertUnique(pTable, pValue)
  if(pTable == nil) then return end
  for i = 1, #pTable do
    if(pTable[i] == pValue) then return end
  end
  table.insert(pTable, pValue)
end

MultiBot.addMember = function(pClass, pLevel, pName)
  local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
  local tButton = tUnits.buttons[pName]
  local tClass = MultiBot.toClass(pClass)
  local tTexture = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if(tButton == nil) then
    tButton = tUnits.addButton(pName, 0, 0, tTexture, MultiBot.toTip(tClass, pLevel, pName))
    tButton:Hide()
  else
    if(tButton.setButton ~= nil) then
      tButton.setButton(tTexture, MultiBot.toTip(tClass, pLevel, pName))
    end
  end
  if(MultiBot.index.classes.members[tClass] == nil) then MultiBot.index.classes.members[tClass] = {} end
  MB_InsertUnique(MultiBot.index.classes.members[tClass], pName)
  MB_InsertUnique(MultiBot.index.members, pName)
  tButton.roster = "members"
  tButton.class = tClass
  tButton.name = pName
  return tButton
end

MultiBot.addFriend = function(pClass, pLevel, pName)
  local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
  local tButton = tUnits.buttons[pName]
  local tClass = MultiBot.toClass(pClass)
  local tTexture = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp"
  if(tButton == nil) then
    tButton = tUnits.addButton(pName, 0, 0, tTexture, MultiBot.toTip(tClass, pLevel, pName))
    tButton:Hide()
  else
    if(tButton.setButton ~= nil) then
      tButton.setButton(tTexture, MultiBot.toTip(tClass, pLevel, pName))
    end
  end
  if(MultiBot.index.classes.friends[tClass] == nil) then MultiBot.index.classes.friends[tClass] = {} end
  MB_InsertUnique(MultiBot.index.classes.friends[tClass], pName)
  MB_InsertUnique(MultiBot.index.friends, pName)
  tButton.roster = "friends"
  tButton.class = tClass
  tButton.name = pName
  return tButton
end

MultiBot.addActive = function(pClass, pLevel, pName)
	local tClass = MultiBot.toClass(pClass)
	local tTexture = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp"
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.buttons[pName]

	if(tButton == nil) then
		tButton = tUnits.addButton(pName, 0, 0, tTexture, MultiBot.toTip(tClass, pLevel, pName))
        tButton:Hide()
	elseif(tButton.setButton ~= nil) then
		tButton.setButton(tTexture, MultiBot.toTip(tClass, pLevel, pName))
	end

	tButton.roster = "actives"
	tButton.class = tClass
	tButton.name = pName
	return tButton
end

-- MULTIBOT:GET --

MultiBot.getBot = function(pName)
	return MultiBot.frames["MultiBar"].frames["Units"].buttons[pName]
end

local function getInventoryUnitButton(botName)
	if not botName or botName == "" then
		return nil
	end

	local frames = MultiBot.frames
	local multiBar = frames and frames["MultiBar"] or nil
	local units = multiBar and multiBar.frames and multiBar.frames["Units"] or nil
	local buttons = units and units.buttons or nil
	return buttons and buttons[botName] or nil
end

local function scheduleInventoryRefresh(delay, callback)
	if type(delay) == "number" and delay > 0 then
		if MultiBot.TimerAfter then
			MultiBot.TimerAfter(delay, callback)
		elseif C_Timer and C_Timer.After then
			C_Timer.After(delay, callback)
		else
			callback()
		end

		return true
	end

	return false
end

-- MULTIBOT:INVENTORY REFRESH --
-- Rafraîchit l’inventaire d’un bot en bridge-first.
-- Fallback chat conservé uniquement quand la bridge n’est pas disponible.
MultiBot.RequestInventoryRefresh = function(botName, delay, options)
	botName = botName or (MultiBot.inventory and MultiBot.inventory.name) or ""
	if not botName or botName == "" then
		return false
	end

	options = options or {}

	local function doRefresh()
		local waitButton = getInventoryUnitButton(botName)
		local bridge = MultiBot.bridge or nil
		local comm = MultiBot.Comm or nil
		local bridgeConnected = bridge and bridge.connected

		if bridgeConnected and comm and comm.RequestInventory and comm.RequestInventory(botName) then
			if waitButton and (waitButton.waitFor == "INVENTORY" or waitButton.waitFor == "ITEM" or waitButton.waitFor == "LOOT") then
				waitButton.waitFor = ""
			end
			return true
		end

		if bridgeConnected and options.noChatFallbackWhenBridgeConnected then
			return false
		end

		if options.bridgeOnly then
			return false
		end

		if not waitButton then
			return false
		end

		waitButton.waitFor = "INVENTORY"
		SendChatMessage("items", "WHISPER", nil, botName)
		return true
	end

	if scheduleInventoryRefresh(delay, doRefresh) then
		return true
	end

	return doRefresh()
end

MultiBot.RequestInventoryPostActionRefresh = function(botName, firstDelay, secondDelay, options)
	botName = botName or (MultiBot.inventory and MultiBot.inventory.name) or ""
	if not botName or botName == "" or not MultiBot.RequestInventoryRefresh then
		return false
	end

	options = options or {}
	local bridgeConnected = MultiBot.bridge and MultiBot.bridge.connected
	local requested = MultiBot.RequestInventoryRefresh(botName, firstDelay or 0.45, options)

	if requested and bridgeConnected and type(secondDelay) == "number" and secondDelay > 0 then
		MultiBot.RequestInventoryRefresh(botName, secondDelay, options)
	end

	return requested
end

-- Compat ancienne API : garde le comportement fenêtre Inventory,
-- mais son fallback bas niveau passe maintenant par RequestInventoryRefresh.
MultiBot.RefreshInventory = function(delay)
	if MultiBot.inventory and MultiBot.inventory.refresh then
		return MultiBot.inventory:refresh(delay)
	end

	if not MultiBot.inventory or not MultiBot.inventory:IsVisible() then
		return false
	end

	return MultiBot.RequestInventoryRefresh(MultiBot.inventory.name, delay)
end