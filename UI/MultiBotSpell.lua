local SPELLBOOK_PAGE_SIZE = 18
local SPELLBOOK_FOOTER_REQUEST_DELAY = 0.35

local function getSpellBookUI()
	return MultiBot.SpellBookUISettings or {}
end

local function getSpellbookHeaderTokens()
	return {
		SPELLBOOK,
		MultiBot.L("info.spellbook") or "",
		"Spells",
		"Spels",
		"法术",
		"Магия",
	}
end

local function ensureSpellbookCollectionState(pButton)
	if(type(pButton.spellbookCollectionState) ~= "table") then
		pButton.spellbookCollectionState = {
			hasCollectedSpell = false,
			--nonSpellStreak = 0,
			footerRequestToken = 0,
			hasRequestedFooter = false,
		}
	end

	return pButton.spellbookCollectionState
end

local function resetSpellbookCollectionState(pButton)
	if(type(pButton) ~= "table") then
		return
	end

	pButton.spellbookCollectionState = nil
end

local function shouldFinishSpellbookCollection(pLine, pCollectionState)
	if(type(pCollectionState) ~= "table") then
		return false
	end

	if(MultiBot.isSpellbookFooterLine and MultiBot.isSpellbookFooterLine(pLine)) then
		return true
	end

	return false
end


local function scheduleSpellbookFooterRequest(pButton, pSender)
	if(type(pButton) ~= "table" or type(pSender) ~= "string" or pSender == "") then
		return
	end

	local tCollectionState = ensureSpellbookCollectionState(pButton)
	tCollectionState.footerRequestToken = (tonumber(tCollectionState.footerRequestToken) or 0) + 1
	local tToken = tCollectionState.footerRequestToken

	local function requestFooter()
		local tCurrentState = pButton and pButton.spellbookCollectionState
		if(tCurrentState ~= tCollectionState) then return end
		if((tonumber(tCurrentState.footerRequestToken) or 0) ~= tToken) then return end
		if(pButton.waitFor ~= "SPELL") then return end
		if(tCurrentState.hasRequestedFooter) then return end

		tCurrentState.hasRequestedFooter = true
		SendChatMessage("stats", "WHISPER", nil, pSender)
	end

	MultiBot.TimerAfter(SPELLBOOK_FOOTER_REQUEST_DELAY, requestFooter)
end

-- DEBUG --
local function debugSpellbookCapture(pKind, pSender, pLine, pSpellID)
	if(type(MultiBot) ~= "table" or type(MultiBot.dprint) ~= "function") then
		return
	end

	local tSender = tostring(pSender or "?")
	local tLine = tostring(pLine or "")
	local tSpellIDText = ""

	if(type(pSpellID) == "number" and pSpellID > 0) then
		tSpellIDText = " spellID=" .. pSpellID
	end

	MultiBot.dprint("SPELLBOOK", "[" .. tostring(pKind) .. "]", "sender=" .. tSender .. tSpellIDText, "line=" .. tLine)
end

-- END DEBUG --
MultiBot.getSpellID = function(pInfo)
	if(type(pInfo) ~= "string" or pInfo == "") then
		return 0
	end

	-- Primary path: extract any Hspell:id found in the chat line.
	local tSpellId = string.match(pInfo, "Hspell:(%d+)")
	if(tSpellId) then
		return tonumber(tSpellId) or 0
	end

	-- Fallback path for non-hyperlink lines like: [Spell Name] - gray
	local tSpellName = string.match(pInfo, "%[(.-)%]")
	if(type(tSpellName) == "string" and tSpellName ~= "") then
		local tLink = GetSpellLink(tSpellName)
		if(type(tLink) == "string") then
			local tFallbackId = string.match(tLink, "Hspell:(%d+)")
			if(tFallbackId) then
				return tonumber(tFallbackId) or 0
			end
		end
	end

	return 0
end

MultiBot.addSpell = function(pInfo, pName)
	local tID = MultiBot.getSpellID(pInfo)
	-- if(tID == 0) then return false end // Moded to DEBUG

	-- DEBUG --
	if(tID == 0) then
		debugSpellbookCapture("IGNORED", pName, pInfo, 0)
		return false
	end
	-- DEBUG END --

	local tName, tRank, tIcon = GetSpellInfo(tID)
	local tLink = GetSpellLink(tID)

	if(tName == nil) then tName = "" end
	if(tRank == nil) then tRank = "" end
	if(tIcon == nil) then tIcon = "inv_misc_questionmark" end
	if(tLink == nil) then tLink = "" end

	local tSpell = { tID, tName, tRank, tIcon, tLink }

	table.insert(MultiBot.spellbook.spells, tSpell)
	MultiBot.spellbook.index = MultiBot.spellbook.index + 1

	if(MultiBot.spells[pName] == nil) then MultiBot.spells[pName] = {} end
	if(MultiBot.spells[pName][tID] == nil) then MultiBot.spells[pName][tID] = true end

	if(MultiBot.spellbook.index < (SPELLBOOK_PAGE_SIZE + 1)) then
		MultiBot.setSpell(MultiBot.spellbook.index, tSpell, pName)
	end

-- DEBUG --
	debugSpellbookCapture("CAPTURED", pName, pInfo, tID)
-- DEBUG END --
	return true
end

MultiBot.beginSpellbookCollection = function(pName)
	--local tOverlay = MultiBot.spellbook.frames["Overlay"]
	local tSpellbook = MultiBot.spellbook
    local tWindowTitle = MultiBot.doReplace(MultiBot.L("info.spellbook"), "NAME", pName)

	for key in pairs(tSpellbook.spells) do tSpellbook.spells[key] = nil end
	if(tSpellbook.setTitle) then tSpellbook:setTitle(tWindowTitle) end
	tSpellbook.name = pName
	tSpellbook.index = 0
	tSpellbook.from = 1
	tSpellbook.to = SPELLBOOK_PAGE_SIZE
	tSpellbook.now = 1
	tSpellbook.max = 1

	for i = 1, SPELLBOOK_PAGE_SIZE do
		MultiBot.setSpell(i, nil, pName)
	end
end

MultiBot.finishSpellbookCollection = function()
	local tSpellbook = MultiBot.spellbook
	local tOverlay = tSpellbook and tSpellbook.frames and tSpellbook.frames["Overlay"]
	if(not tSpellbook or not tOverlay) then
		return
	end

	tSpellbook.now = 1
	tSpellbook.max = math.max(1, math.ceil((tSpellbook.index or 0) / SPELLBOOK_PAGE_SIZE))
	tOverlay.setText("Pages", "|cff" .. (getSpellBookUI().PAGE_TEXT_COLOR_HEX or "ffffff") .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
	if(tSpellbook.now == tSpellbook.max) then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
	tOverlay.buttons["<"].doHide()
	tSpellbook:Show()
end

MultiBot.isSpellbookHeaderLine = function(pLine)
	if(type(pLine) ~= "string") then
		return false
	end

	--return MultiBot.isInside(pLine, SPELLBOOK, "Spells", "法术", "Магия")
    return MultiBot.isInside(pLine, unpack(getSpellbookHeaderTokens()))
end

MultiBot.isSpellbookFooterLine = function(pLine)
	if(type(pLine) ~= "string") then
		return false
	end

	local tBag = MultiBot.L("info.shorts.bag") or "Bag"
	local tDur = MultiBot.L("info.shorts.dur") or "Dur"
	local tXP = MultiBot.L("info.shorts.xp") or "XP"

	if(MultiBot.beInside(pLine, tBag, tDur) or MultiBot.beInside(pLine, tBag, tXP)) then
		return true
	end

	if(MultiBot.beInside(pLine, "Bag,", "Dur") or MultiBot.beInside(pLine, "Bag,", "XP")) then
		return true
	end

	if(MultiBot.beInside(pLine, "背包", "耐久度") or MultiBot.beInside(pLine, "背包", "经验值")) then
		return true
	end

	return false
end

MultiBot.handleSpellbookChatLine = function(pButton, pLine, pSender)
	if(not pButton or type(pButton.waitFor) ~= "string") then
		return false
	end

	if(pButton.waitFor == "SPELLBOOK" and MultiBot.isSpellbookHeaderLine and MultiBot.isSpellbookHeaderLine(pLine)) then
	-- DEBUG --
		debugSpellbookCapture("HEADER", pSender, pLine, 0)
	-- DEBUG END --
		if(MultiBot.beginSpellbookCollection) then
			MultiBot.beginSpellbookCollection(pSender)
		end
		resetSpellbookCollectionState(pButton)
		ensureSpellbookCollectionState(pButton)
		pButton.waitFor = "SPELL"
		scheduleSpellbookFooterRequest(pButton, pSender)
		return true
	end

	if(pButton.waitFor == "SPELL") then
		local tCollectionState = ensureSpellbookCollectionState(pButton)

		if(shouldFinishSpellbookCollection(pLine, tCollectionState)) then
		-- DEBUG --
			debugSpellbookCapture("FOOTER", pSender, pLine, 0)
		-- DEBUG END --
			if(MultiBot.finishSpellbookCollection) then
				MultiBot.finishSpellbookCollection()
			end
			resetSpellbookCollectionState(pButton)
			pButton.waitFor = ""
			InspectUnit(pSender)
			return true
		end

		local tAddedSpell = MultiBot.addSpell(pLine, pSender)
		if(tAddedSpell) then
			tCollectionState.hasCollectedSpell = true
			--tCollectionState.nonSpellStreak = 0
		--else
			--tCollectionState.nonSpellStreak = (tonumber(tCollectionState.nonSpellStreak) or 0) + 1
		end

		scheduleSpellbookFooterRequest(pButton, pSender)
		return true
	end

	return false
end

MultiBot.setSpell = function(pIndex, pSpell, pName)
	local tIndex = MultiBot.IF(pIndex < 10, "0", "") .. pIndex
	local tOverlay = MultiBot.spellbook.frames["Overlay"]

	if(pSpell ~= nil) then
		--local tTitle = MultiBot.IF(string.len(pSpell[2]) > 16, string.sub(pSpell[2], 1, 16) .. "...", pSpell[2])
		tOverlay.setButton("S" .. tIndex, pSpell[4], pSpell[5])
		--tOverlay.setText("T" .. tIndex, "|cffffcc00" .. tTitle .. "|r")
		tOverlay.setText("R" .. tIndex, "|cff" .. (getSpellBookUI().RANK_TEXT_COLOR_HEX or "ffcc00") .. pSpell[3] .. "|r")
		tOverlay.buttons["S" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["C" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["S" .. tIndex].doShow()
		tOverlay.buttons["C" .. tIndex].doShow()
		--tOverlay.texts["T" .. tIndex]:Show()
		tOverlay.texts["R" .. tIndex]:Show()
		tOverlay.buttons["C" .. tIndex]:SetChecked(MultiBot.spells[pName][pSpell[1]])
		tOverlay.buttons["C" .. tIndex].doClick = function(pButton)
			local tName = pButton.getName()
			local tAction = ""
			MultiBot.spells[tName][pButton.spell] = MultiBot.IF(MultiBot.spells[tName][pButton.spell], false, true)
			pButton:SetChecked(MultiBot.spells[tName][pButton.spell])
			for id, state in pairs(MultiBot.spells[tName]) do
				if(state == false) then tAction = tAction .. MultiBot.IF(tAction == "", "ss +", ", +") .. id end
			end
			MultiBot.ActionToTarget(MultiBot.IF(tAction == "", "ss -" .. pButton.spell, tAction), tName)
		end
	else
		tOverlay.buttons["S" .. tIndex].spell = 0
		tOverlay.buttons["C" .. tIndex].spell = 0
		tOverlay.buttons["S" .. tIndex].doHide()
		tOverlay.buttons["C" .. tIndex].doHide()
		tOverlay.texts["T" .. tIndex]:Hide()
		tOverlay.texts["R" .. tIndex]:Hide()
	end
end