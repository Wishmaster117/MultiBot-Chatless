local MB_REWARD_PAGE_SIZE = 12
local MB_REWARD_MAX_CHOICES = 6

local MB_REWARD_CONFIG_POPUP_KEY = "MULTIBOT_REWARD_CONFIG_WARNING"

local function showRewardConfigPopup()
	if(type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function") then return end

	if(not StaticPopupDialogs[MB_REWARD_CONFIG_POPUP_KEY]) then
		StaticPopupDialogs[MB_REWARD_CONFIG_POPUP_KEY] = {
			text = "",
			button1 = OKAY or "OK",
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			preferredIndex = 3,
		}
	end

	StaticPopupDialogs[MB_REWARD_CONFIG_POPUP_KEY].text = MultiBot.L("info.reward.popup")
	StaticPopup_Show(MB_REWARD_CONFIG_POPUP_KEY)
end

MultiBot.rewardShowConfigPopup = function()
	showRewardConfigPopup()
end

local function getClassToken(className)
	local canon = (MultiBot.toClass and MultiBot.toClass(className)) or className
	local tokenMap = {
		DeathKnight = "DEATHKNIGHT",
		Druid = "DRUID",
		Hunter = "HUNTER",
		Mage = "MAGE",
		Paladin = "PALADIN",
		Priest = "PRIEST",
		Rogue = "ROGUE",
		Shaman = "SHAMAN",
		Warlock = "WARLOCK",
		Warrior = "WARRIOR",
	}

	return tokenMap[canon]
end

local function getWotlkClassHexColor(className)
	local token = getClassToken(className)
	local colors = (token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]) or nil
	if(not colors) then return "ffffcc00" end

	local r = math.floor(((colors.r or 1) * 255) + 0.5)
	local g = math.floor(((colors.g or 1) * 255) + 0.5)
	local b = math.floor(((colors.b or 1) * 255) + 0.5)
	return string.format("ff%02x%02x%02x", r, g, b)
end

local function getClassIconMarkup(className, iconSize)
	local token = getClassToken(className)
	local coordsByToken = {
		WARRIOR = "0:64:0:64",
		MAGE = "64:128:0:64",
		ROGUE = "128:192:0:64",
		DRUID = "192:256:0:64",
		HUNTER = "0:64:64:128",
		SHAMAN = "64:128:64:128",
		PRIEST = "128:192:64:128",
		WARLOCK = "192:256:64:128",
		PALADIN = "0:64:128:192",
		DEATHKNIGHT = "64:128:128:192",
	}

	local coords = token and coordsByToken[token]
	if(coords == nil) then return "" end

	local size = math.max(12, math.min(24, tonumber(iconSize) or 16))
	return "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:" .. size .. ":" .. size .. ":0:0:256:256:" .. coords .. "|t"
end

local function collectQuestChoices()
	local tChoices = {}
	local tMaxChoices = math.min(MB_REWARD_MAX_CHOICES, GetNumQuestChoices() or 0)

	for i = 1, tMaxChoices do
		local tLink = GetQuestItemLink("CHOICE", i)
		local tName, tIcon = GetQuestItemInfo("CHOICE", i)
		if(tLink ~= nil and tName ~= nil) then
			table.insert(tChoices, { tLink, tName, tIcon or "inv_misc_questionmark" })
		end
	end

	return tChoices
end

local function collectEligibleUnits()
	local tUnits = {}
	local tPlayerName = UnitName("player")

	local function addIfBot(unitName)
		if(unitName == nil) then return end
		local tBot = MultiBot.getBot(unitName)
		if(tBot ~= nil and tBot.name ~= tPlayerName) then
			tBot.rewarded = false
			table.insert(tUnits, tBot)
		end
	end

	if(GetNumRaidMembers() > 0) then
		for i = 1, 40 do addIfBot(UnitName("raid" .. i)) end
	elseif(GetNumPartyMembers() > 0) then
		for i = 1, 5 do addIfBot(UnitName("party" .. i)) end
	end

	return tUnits
end

local function applyRewardChoice(pButton)
	if(pButton == nil or pButton.link == nil) then return end

	pButton.parent:Hide()
	SendChatMessage("r " .. pButton.link, "WHISPER", nil, pButton.getName())

	local tClickedBot = MultiBot.getBot(pButton.getName())
	if(tClickedBot ~= nil) then tClickedBot.rewarded = true end

	MultiBot.rewardTryClose()
end

MultiBot.rewardSetClassIconSize = function(size)
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return 16 end

	local safeSize = math.max(12, math.min(24, tonumber(size) or tReward.classIconSize or 16))
	tReward.classIconSize = safeSize

	if(MultiBot.rewardHasRenderableData() and tReward:IsVisible()) then
		MultiBot.rewardRenderPage()
	end

	return safeSize
end

MultiBot.rewardSyncPageBounds = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return 0, 0 end

	local unitsCount = #tReward.units
	local rewardCount = #tReward.rewards
	if(unitsCount <= 0) then
		tReward.max = 1
		tReward.now = 1
		tReward.from = 1
		tReward.to = tReward.pageSize
		return unitsCount, rewardCount
	end

	tReward.max = math.max(1, math.ceil(unitsCount / tReward.pageSize))
	tReward.now = math.max(1, math.min(tReward.now or 1, tReward.max))
	tReward.from = ((tReward.now - 1) * tReward.pageSize) + 1
	tReward.to = math.min(tReward.from + tReward.pageSize - 1, unitsCount)
	return unitsCount, rewardCount
end

MultiBot.rewardChangePage = function(delta)
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil or not MultiBot.rewardHasRenderableData()) then return false end

	MultiBot.rewardSyncPageBounds()
	local tTarget = math.max(1, math.min((tReward.now or 1) + (delta or 0), tReward.max or 1))
	if(tTarget == tReward.now) then return false end

	tReward.now = tTarget
	MultiBot.rewardSyncPageBounds()
	MultiBot.rewardRenderPage()
	return true
end

MultiBot.rewardCollectQuestChoices = collectQuestChoices
MultiBot.rewardCollectEligibleUnits = collectEligibleUnits

MultiBot.rewardTryClose = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return end

	for _, value in pairs(tReward.units) do
		if(value ~= nil and value.rewarded == false) then return end
	end

	tReward:Hide()
end

MultiBot.rewardApplyChoice = function(pButton)
	applyRewardChoice(pButton)
end

MultiBot.rewardHasRenderableData = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return false end
	return (#tReward.rewards > 0 and #tReward.units > 0)
end

MultiBot.rewardSetEnabled = function(isEnabled)
	local tReward = MultiBot.rewardEnsureState()

	tReward.state = (isEnabled == true)

	if(not tReward.state) then
		MultiBot.rewardResetPagination()
		MultiBot.rewardClearPage()
		tReward:Hide()
	end

	return tReward.state
end

MultiBot.rewardReopenIfAvailable = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return false end
	if(not MultiBot.rewardHasRenderableData()) then return false end

	MultiBot.rewardRefreshPager()
	MultiBot.rewardRenderPage()
	tReward:Show()
	return true
end

MultiBot.rewardEnsureState = function()
	if(MultiBot.reward == nil) then return nil end

	if MultiBot.Store and MultiBot.Store.EnsureTableField then
		MultiBot.Store.EnsureTableField(MultiBot.reward, "rewards", {})
		MultiBot.Store.EnsureTableField(MultiBot.reward, "units", {})
		MultiBot.Store.EnsureTableField(MultiBot.reward, "pageSize", MB_REWARD_PAGE_SIZE)
		MultiBot.Store.EnsureTableField(MultiBot.reward, "now", 1)
		MultiBot.Store.EnsureTableField(MultiBot.reward, "max", 1)
		MultiBot.Store.EnsureTableField(MultiBot.reward, "from", 1)
		MultiBot.Store.EnsureTableField(MultiBot.reward, "to", MultiBot.reward.pageSize)
		MultiBot.Store.EnsureTableField(MultiBot.reward, "classIconSize", 16)
	else
		local function ensureField(target, key, defaultValue)
			if target[key] == nil then
				target[key] = defaultValue
			end
			return target[key]
		end

		ensureField(MultiBot.reward, "rewards", {})
		ensureField(MultiBot.reward, "units", {})
		ensureField(MultiBot.reward, "pageSize", MB_REWARD_PAGE_SIZE)
		ensureField(MultiBot.reward, "now", 1)
		ensureField(MultiBot.reward, "max", 1)
		ensureField(MultiBot.reward, "from", 1)
		ensureField(MultiBot.reward, "to", MultiBot.reward.pageSize)
		ensureField(MultiBot.reward, "classIconSize", 16)
	end

	return MultiBot.reward
end

MultiBot.rewardResetPagination = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return end

	tReward.now = 1
	tReward.max = 1
	tReward.from = 1
	tReward.to = tReward.pageSize
end

MultiBot.rewardClearPage = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil or tReward.rows == nil or tReward.pageLabel == nil or tReward.prevButton == nil or tReward.nextButton == nil) then return end

	for i = 1, tReward.pageSize do
		local tUnit = tReward.rows[i]
		if(tUnit ~= nil) then
			for j = 1, MB_REWARD_MAX_CHOICES do
				local tButton = tUnit.buttons["R" .. j]
				if(tButton ~= nil) then tButton:Hide() end
			end
			tUnit:Hide()
		end
	end
end

MultiBot.rewardRefreshPager = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil or tReward.rows == nil or tReward.pageLabel == nil or tReward.prevButton == nil or tReward.nextButton == nil) then return end

	MultiBot.rewardSyncPageBounds()
	local tMaxDisplay = math.max(1, tReward.max or 1)
	tReward.pageLabel:SetText(tReward.now .. "/" .. tMaxDisplay)
	tReward.prevButton:Show()
	tReward.nextButton:Show()

	if(tReward.now <= 1) then tReward.prevButton:Hide() end
	if(tReward.now >= tMaxDisplay) then tReward.nextButton:Hide() end
end

MultiBot.rewardRenderPage = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil) then return end

	MultiBot.rewardSyncPageBounds()
	MultiBot.rewardClearPage()
	MultiBot.rewardRefreshPager()

	if(#tReward.units == 0 or #tReward.rewards == 0) then return end

	for tRow = 1, tReward.pageSize do
		local tBot = tReward.units[tReward.from + tRow - 1]
		local tUnit = MultiBot.setReward(tRow, tBot)

		if(tUnit ~= nil and tBot ~= nil and (not tBot.rewarded)) then
			for j = 1, #tReward.rewards do
				local tRewardChoice = tReward.rewards[j]
				local tButton = tUnit.buttons["R" .. j]
				if(tRewardChoice ~= nil and tButton ~= nil) then
					tButton:Show()
					tButton.link = tRewardChoice[1]
					tButton.setButton(tRewardChoice[3], tRewardChoice[1])
					tButton.doLeft = applyRewardChoice
				end
			end
		end
	end
end

MultiBot.setRewards = function()
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil or tReward.state == false) then return end

	tReward.rewards = collectQuestChoices()
	tReward.units = collectEligibleUnits()
	MultiBot.rewardResetPagination()

	local unitsCount, rewardCount = MultiBot.rewardSyncPageBounds()
	if(unitsCount == 0 or rewardCount == 0) then
		MultiBot.rewardClearPage()
		MultiBot.rewardRefreshPager()
		tReward:Hide()
		return
	end

	MultiBot.rewardRenderPage()
	tReward:Show()
end

MultiBot.setReward = function(pIndex, pBot, oRewarded)
	local tReward = MultiBot.rewardEnsureState()
	if(tReward == nil or tReward.rows == nil) then return nil end

	local tUnit = tReward.rows[pIndex]
	if(tUnit == nil) then return nil end

	if(pBot == nil) then
		tUnit:Hide()
		return tUnit
	end

	if(oRewarded ~= nil) then pBot.rewarded = oRewarded end
	if(pBot.rewarded) then tUnit:Hide() else tUnit:Show() end
	local classHex = getWotlkClassHexColor(pBot.class)
	local classIcon = getClassIconMarkup(pBot.class, tReward.classIconSize)
	tUnit.setText("", "|c" .. classHex .. pBot.name .. "|r " .. classIcon)
	tUnit.class = pBot.class
	tUnit.name = pBot.name
	return tUnit
end