local SPELLBOOK_PAGE_SIZE = 18

local function getSpellBookUI()
	return MultiBot.SpellBookUISettings or {}
end

MultiBot.addSpellById = function(pSpellID, pName, pIgnored)
	local tID = tonumber(pSpellID or 0) or 0
	if(tID == 0) then
		return false
	end

	local tName, tRank, tIcon = GetSpellInfo(tID)
	local tLink = GetSpellLink(tID)

	if(tName == nil) then return false end
	if(tRank == nil) then tRank = "" end
	if(tIcon == nil) then tIcon = "inv_misc_questionmark" end
	if(tLink == nil) then tLink = "" end

	local tSpell = { tID, tName, tRank, tIcon, tLink }

	table.insert(MultiBot.spellbook.spells, tSpell)
	MultiBot.spellbook.index = MultiBot.spellbook.index + 1

	if(MultiBot.spells[pName] == nil) then MultiBot.spells[pName] = {} end
	MultiBot.spells[pName][tID] = pIgnored ~= true

	if(MultiBot.spellbook.index < (SPELLBOOK_PAGE_SIZE + 1)) then
		MultiBot.setSpell(MultiBot.spellbook.index, tSpell, pName)
	end

	return true
end

MultiBot.beginSpellbookCollection = function(pName)
	--local tOverlay = MultiBot.spellbook.frames["Overlay"]
	local tSpellbook = MultiBot.spellbook
    local tWindowTitle = MultiBot.doReplace(MultiBot.L("info.spellbook"), "NAME", pName)

	for key in pairs(tSpellbook.spells) do tSpellbook.spells[key] = nil end
	MultiBot.spells[pName] = {}
	if(tSpellbook.setTitle) then tSpellbook:setTitle(tWindowTitle) end
	tSpellbook.name = pName
	tSpellbook.index = 0
	tSpellbook.filterIgnored = false
	tSpellbook.from = 1
	tSpellbook.to = SPELLBOOK_PAGE_SIZE
	tSpellbook.now = 1
	tSpellbook.max = 1

	for i = 1, SPELLBOOK_PAGE_SIZE do
		MultiBot.setSpell(i, nil, pName)
	end

	if(MultiBot.refreshSpellbookFilterButton) then
		MultiBot.refreshSpellbookFilterButton()
	end
end

MultiBot.finishSpellbookCollection = function()
	local tSpellbook = MultiBot.spellbook
	local tOverlay = tSpellbook and tSpellbook.frames and tSpellbook.frames["Overlay"]
	if(not tSpellbook or not tOverlay) then
		return
	end

	if(MultiBot.refreshSpellbookView) then
		MultiBot.refreshSpellbookView(true)
	else
		tSpellbook.now = 1
		tSpellbook.max = math.max(1, math.ceil((tSpellbook.index or 0) / SPELLBOOK_PAGE_SIZE))
		tOverlay.setText("Pages", "|cff" .. (getSpellBookUI().PAGE_TEXT_COLOR_HEX or "ffffff") .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
		if(tSpellbook.now == tSpellbook.max) then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
		tOverlay.buttons["<"].doHide()
	end
	tSpellbook:Show()
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
		tOverlay.buttons["C" .. tIndex].ignorePending = false
		tOverlay.buttons["S" .. tIndex].doShow()
		tOverlay.buttons["C" .. tIndex].doShow()
		--tOverlay.texts["T" .. tIndex]:Show()
		tOverlay.texts["R" .. tIndex]:Show()
		tOverlay.buttons["C" .. tIndex]:SetChecked(MultiBot.spells[pName][pSpell[1]])
		tOverlay.buttons["C" .. tIndex].doClick = function(pButton)
			local tName = pButton.getName()
			local tSpellId = tonumber(pButton.spell or 0) or 0
			local tAllowed = MultiBot.spells[tName] and MultiBot.spells[tName][tSpellId] == true

			-- CheckButton toggles visually before OnClick. Restore the last
			-- authoritative server state until the structured ACK arrives.
			pButton:SetChecked(tAllowed)

			if(pButton.ignorePending or tName == "" or tSpellId == 0) then
				return
			end

			if(not MultiBot.Comm or type(MultiBot.Comm.RunSpellbookIgnore) ~= "function") then
				return
			end

			local tAction = MultiBot.IF(tAllowed, "IGNORE", "ALLOW")
			pButton.ignorePending = true

			local tToken = MultiBot.Comm.RunSpellbookIgnore(tName, tSpellId, tAction, function(pResult)
				pButton.ignorePending = false

				if(type(pResult) ~= "table" or pResult.status ~= "ok") then
					if(pButton.spell == tSpellId and pButton.getName() == tName) then
						pButton:SetChecked(MultiBot.spells[tName] and MultiBot.spells[tName][tSpellId] == true)
					end
					return
				end

				if(MultiBot.spells[tName] == nil) then
					MultiBot.spells[tName] = {}
				end

				MultiBot.spells[tName][tSpellId] = pResult.ignored ~= true

				if(pButton.spell == tSpellId and pButton.getName() == tName) then
					pButton:SetChecked(MultiBot.spells[tName][tSpellId])
				end

				if(MultiBot.refreshSpellbookView) then
					MultiBot.refreshSpellbookView(false)
				end
			end)

			if(not tToken) then
				pButton.ignorePending = false
				pButton:SetChecked(tAllowed)
			end
		end
	else
		tOverlay.buttons["S" .. tIndex].spell = 0
		tOverlay.buttons["C" .. tIndex].spell = 0
		tOverlay.buttons["C" .. tIndex].ignorePending = false
		tOverlay.buttons["S" .. tIndex].doHide()
		tOverlay.buttons["C" .. tIndex].doHide()
		tOverlay.texts["T" .. tIndex]:Hide()
		tOverlay.texts["R" .. tIndex]:Hide()
	end
end