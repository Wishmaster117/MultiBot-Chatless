local function applySavedStatsPoint(frame)
	if not frame then
		return
	end

	local savedPoint = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue("StatsPoint") or nil
	if type(savedPoint) ~= "string" or savedPoint == "" then
		return
	end

	local pointX, pointY = string.match(savedPoint, "^%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
	pointX = tonumber(pointX)
	pointY = tonumber(pointY)
	if pointX and pointY then
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", pointX, pointY)
	end
end

local function shortLabel(key, fallback)
	return MultiBot.L("info.shorts." .. key, fallback)
end

local STATS_ROOT_X = -60
local STATS_ROOT_Y = 560
local STATS_ROOT_SIZE = 32
local STATS_MOVE_BUTTON_X = 0
local STATS_MOVE_BUTTON_Y = -80
local STATS_MOVE_BUTTON_WIDTH = 160
local STATS_PARTY_SLOTS = {
	{ index = "party1", y = 0 },
	{ index = "party2", y = -60 },
	{ index = "party3", y = -120 },
	{ index = "party4", y = -180 },
}
local STATS_SLOT_X = 0
local STATS_SLOT_SIZE = 32
local STATS_SLOT_WIDTH = 192
local STATS_SLOT_HEIGHT = 96

MultiBot.addStats = function(pFrame, pIndex, pX, pY, pSize, pWidth, pHeight)
	local tFrame = pFrame.addFrame(pIndex, pX, pY, pSize, pWidth, pHeight)
	local tAddon = tFrame.addFrame("Addon", -2, 46, 48)
	tAddon.addTexture("Interface\\AddOns\\MultiBot\\Icons\\xp_progress_99_percent.blp")
	tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Stats.blp")
	tFrame:Hide()

	tFrame.addText("Name", "", "TOPLEFT", 54, -11, 11)
	tFrame.addText("Values", "", "TOPLEFT", 54, -27, 11)
	tAddon.addText("Percent", "", "CENTER", 0, 0, 11)
	tFrame.addText("Level", "", "CENTER", 85.25, 5, 11)

	tFrame.setProgress = function(frame, pProgress)
		local addonFrame = frame.frames["Addon"]

		addonFrame.texture:Hide()

		if pProgress >= 99 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_99_percent.blp"
			)
		elseif pProgress >= 90 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_90_percent.blp"
			)
		elseif pProgress >= 81 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_81_percent.blp"
			)
		elseif pProgress >= 72 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_72_percent.blp"
			)
		elseif pProgress >= 63 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_63_percent.blp"
			)
		elseif pProgress >= 54 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_54_percent.blp"
			)
		elseif pProgress >= 45 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_45_percent.blp"
			)
		elseif pProgress >= 36 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_36_percent.blp"
			)
		elseif pProgress >= 27 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_27_percent.blp"
			)
		elseif pProgress >= 18 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_18_percent.blp"
			)
		elseif pProgress >= 9 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_9_percent.blp"
			)
		end

		return pProgress
	end

	tFrame.setStats = function(pName, pLevel, pStats, oPlayer)
		local statsFrame = MultiBot.stats.frames[MultiBot.toUnit(pName)]
		local addonFrame = statsFrame.frames["Addon"]
		local tChina = GetLocale() == "zhCN"

		if oPlayer ~= nil and oPlayer == true then
			local tStats = MultiBot.doSplit(pStats, ", ")
			local tMana = tonumber(tStats[5])
			local tXP = tonumber(tStats[4])

			statsFrame.texts["Name"]:SetText(pName)
			statsFrame.texts["Level"]:SetText(pLevel)
			statsFrame.texts["Values"]:SetText(PLAYER)

			if pLevel == 80 then
				addonFrame.texts["Percent"]:SetText(
					statsFrame.setProgress(statsFrame, tMana)
					.. "%\n"
					.. shortLabel("mp", "MP")
				)
			else
				addonFrame.texts["Percent"]:SetText(
					statsFrame.setProgress(statsFrame, tXP)
					.. "%\n"
					.. shortLabel("xp", "XP")
				)
			end

			statsFrame:Show()
			return
		end

		local tStats = MultiBot.doSplit(pStats, ", ")
		local tMoney = "|cffffdd55" .. tStats[1] .. "|r, "
		local tBag = MultiBot.IF(
			tChina,
			MultiBot.doReplace(tStats[2], "Bag", shortLabel("bag", "Bag")),
			tStats[2]
		)

		statsFrame.texts["Name"]:SetText(pName)
		statsFrame.texts["Level"]:SetText(pLevel)
		statsFrame.texts["Values"]:SetText(tMoney .. tBag)

		if pLevel == 80 then
			local durabilityString = MultiBot.doSplit(tStats[3], "|")[2]
			local tDur = MultiBot.doSplit(string.sub(durabilityString, 10), " ")
			local tQuality = tonumber(string.sub(tDur[1], 1, string.len(tDur[1]) - 1))
			local tRepair = tonumber(string.sub(tDur[2], 2, string.len(tDur[2]) - 1))

			if tQuality == 0 and tRepair == 0 then
				tQuality = 100
			end

			addonFrame.texts["Percent"]:SetText(
				statsFrame.setProgress(statsFrame, tQuality)
				.. "%\n"
				.. shortLabel("dur", "Dur")
			)
		else
			local xpString = MultiBot.doSplit(tStats[4], "|")[2]
			local tXP = tonumber(string.sub(xpString, 10))

			addonFrame.texts["Percent"]:SetText(
				statsFrame.setProgress(statsFrame, tXP)
				.. "%\n"
				.. shortLabel("xp", "XP")
			)
		end

		statsFrame:Show()
		return
	end
end

function MultiBot.InitializeStatsUI()
	if MultiBot.stats then
		return MultiBot.stats
	end

	local statsFrame = MultiBot.newFrame(MultiBot, STATS_ROOT_X, STATS_ROOT_Y, STATS_ROOT_SIZE)
	applySavedStatsPoint(statsFrame)
	statsFrame:SetMovable(true)
	statsFrame:Hide()

	statsFrame.movButton("Move", STATS_MOVE_BUTTON_X, STATS_MOVE_BUTTON_Y, STATS_MOVE_BUTTON_WIDTH, MultiBot.L("tips.move.stats"))

	for _, slot in ipairs(STATS_PARTY_SLOTS) do
		MultiBot.addStats(
			statsFrame,
			slot.index,
			STATS_SLOT_X,
			slot.y,
			STATS_SLOT_SIZE,
			STATS_SLOT_WIDTH,
			STATS_SLOT_HEIGHT
		)
	end

	MultiBot.stats = statsFrame
	return statsFrame
end

function MultiBot.EnsureStatsUI()
	if MultiBot.stats then
		return MultiBot.stats
	end

	if type(MultiBot.InitializeStatsUI) == "function" then
		return MultiBot.InitializeStatsUI()
	end

	return nil
end