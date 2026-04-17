-- REWARD FRAME --

local MB_REWARD_INSPECT_X_OFFSET = -30

local function getRewardAceGUI()
	if(MultiBot.GetAceGUI) then
		local tAce = MultiBot.GetAceGUI()
		if(tAce) then return tAce end
	end

	if(type(LibStub) == "table" and LibStub.GetLibrary) then
		local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
		if(ok) then return aceGUI end
	end

	return nil
end

local function makeIconButton(parent, size)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(size, size)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	button.icon = icon

	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

	return button
end

local function requestBotInventory(botName)
	if(botName == nil) then return end

	if(MultiBot.RequestBotInventory) then
		MultiBot.RequestBotInventory(botName)
	end
end

local function buildRow(parent, yOffset)
	local rowFrame = CreateFrame("Frame", nil, parent)
	rowFrame:SetSize(420, 30)
	rowFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

	local panelBg = rowFrame:CreateTexture(nil, "BACKGROUND")
	panelBg:SetAllPoints(rowFrame)
	panelBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	panelBg:SetVertexColor(0.07, 0.07, 0.07, 0.45)

	local panelBorder = {
		top = rowFrame:CreateTexture(nil, "BORDER"),
		bottom = rowFrame:CreateTexture(nil, "BORDER"),
		left = rowFrame:CreateTexture(nil, "BORDER"),
		right = rowFrame:CreateTexture(nil, "BORDER"),
	}
	for _, edge in pairs(panelBorder) do
		edge:SetTexture("Interface\\Buttons\\WHITE8x8")
		edge:SetVertexColor(0.26, 0.26, 0.26, 0.95)
	end

	panelBorder.top:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", -1, 1)
	panelBorder.top:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", 1, 1)
	panelBorder.top:SetHeight(1)

	panelBorder.bottom:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", -1, -1)
	panelBorder.bottom:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 1, -1)
	panelBorder.bottom:SetHeight(1)

	panelBorder.left:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", -1, 1)
	panelBorder.left:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", -1, -1)
	panelBorder.left:SetWidth(1)

	panelBorder.right:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", 1, 1)
	panelBorder.right:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 1, -1)
	panelBorder.right:SetWidth(1)

	local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	nameText:SetPoint("LEFT", rowFrame, "LEFT", 6, 0)
	nameText:SetWidth(160)
	nameText:SetJustifyH("LEFT")
	nameText:SetText("|cffffcc00NAME - CLASS|r")

	local row = {
		frame = rowFrame,
		buttons = {},
		name = nil,
		class = nil,
		panelBg = panelBg,
		panelBorder = panelBorder,
	}

	function row:Show()
		self.frame:Show()
		if(self.panelBg) then self.panelBg:Show() end
		if(self.panelBorder) then
			for _, edge in pairs(self.panelBorder) do edge:Show() end
		end
	end

	function row:Hide()
		self.frame:Hide()
		if(self.panelBg) then self.panelBg:Hide() end
		if(self.panelBorder) then
			for _, edge in pairs(self.panelBorder) do edge:Hide() end
		end
	end

	function row.setText(_, textOrId, value)
		nameText:SetText(value or textOrId or "")
	end

	local inspectButton = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
	inspectButton:SetHeight(20)
	inspectButton:SetPoint("LEFT", nameText, "RIGHT", MB_REWARD_INSPECT_X_OFFSET, 0)
	inspectButton:SetText(INSPECT or "Inspect")

	local inspectText = inspectButton:GetFontString()
	local inspectWidth = 50
	if(inspectText ~= nil and inspectText.GetStringWidth) then
		inspectWidth = math.max(50, math.ceil((inspectText:GetStringWidth() or 0) + 24))
	end
	inspectButton:SetWidth(inspectWidth)

	local inspectProxy = {
		parent = row,
		doLeft = nil,
	}
	function inspectProxy.getName() return row.name end
	inspectButton:SetScript("OnClick", function()
		if(inspectProxy.doLeft) then inspectProxy.doLeft(inspectProxy) end
	end)
	inspectButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(inspectButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(MultiBot.L("tips.creator.inspect") or (INSPECT or "Inspect"), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	inspectButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	inspectProxy.doLeft = function(pButton)
		local tName = pButton.getName()
		if(tName) then
			InspectUnit(tName)
			requestBotInventory(tName)
		end
	end
	row.inspect = inspectProxy

	local buttonStartX = math.max(220, 170 + MB_REWARD_INSPECT_X_OFFSET + inspectWidth)
	for i = 1, 6 do
		local btn = makeIconButton(rowFrame, 20)
		btn:SetPoint("LEFT", rowFrame, "LEFT", buttonStartX + ((i - 1) * 24), 0)

		local proxy = {
			frame = btn,
			parent = row,
			link = nil,
			doLeft = nil,
		}

		function proxy:Show() self.frame:Show() end
		function proxy:Hide() self.frame:Hide() end
		function proxy.getName() return row.name end
		function proxy.setButton(iconPath, link)
			proxy.link = link
			proxy.frame.icon:SetTexture(iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
		end

		btn:SetScript("OnClick", function()
			if(proxy.doLeft) then proxy.doLeft(proxy) end
		end)
		btn:SetScript("OnEnter", function()
			if(proxy.link) then
				GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(proxy.link)
				GameTooltip:Show()
			end
		end)
		btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

		row.buttons["R" .. i] = proxy
	end

	return row
end

function MultiBot.InitializeRewardFrame()
	local aceGUI = getRewardAceGUI()
	if(not aceGUI) then
		UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Reward", 1, 0.2, 0.2, 1)
		return
	end

	local window = aceGUI:Create("Window")
	window:SetTitle(MultiBot.L("info.reward"))
	window:SetLayout("Manual")
	window:SetWidth(460)
	window:SetHeight(454)
	window.frame:SetClampedToScreen(true)
	window.frame:SetMovable(true)
	window.frame:EnableMouse(true)
	local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
	if strataLevel then
		window.frame:SetFrameStrata(strataLevel)
	end
	window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -754, 238)
	window:Hide()
	window:SetCallback("OnClose", function(widget)
		widget:Hide()
	end)

	if(window.EnableResize) then window:EnableResize(false) end
	if(window.SetStatusText) then window:SetStatusText("") end

	local content = window.content
	content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 12, -30)
	content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -12, 12)

	local pageLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pageLabel:SetPoint("TOP", content, "TOP", 0, -2)
	--pageLabel:SetText(MB_PAGE_DEFAULT)
	pageLabel:SetText(MultiBot.MB_PAGE_DEFAULT or "0/0")

	local prevButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	prevButton:SetSize(26, 20)
	prevButton:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -2)
	prevButton:SetText("<")

	local nextButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
	nextButton:SetSize(26, 20)
	nextButton:SetPoint("LEFT", prevButton, "RIGHT", 6, 0)
	nextButton:SetText(">")

	local rows = {}
	for i = 1, 12 do
		local yOffset = -30 - ((i - 1) * 32)
		rows[i] = buildRow(content, yOffset)
		rows[i]:Hide()
	end

	MultiBot.reward = {
		state = false,
		rewards = {},
		units = {},
		rows = rows,
		window = window,
		pageLabel = pageLabel,
		prevButton = prevButton,
		nextButton = nextButton,
		pageSize = 12,
	    classIconSize = 18,
		from = 1,
		max = 1,
		now = 1,
		to = 12,
	}

	function MultiBot.reward:Show()
		self.window:Show()
	end

	function MultiBot.reward:Hide()
		self.window:Hide()
	end

	function MultiBot.reward:IsVisible()
		return self.window.frame and self.window.frame:IsShown()
	end

	function MultiBot.reward:GetRight()
		return self.window.frame:GetRight()
	end

	function MultiBot.reward:GetBottom()
		return self.window.frame:GetBottom()
	end

	function MultiBot.reward.setPoint(x, y)
		if(x == nil or y == nil) then return end
		window.frame:ClearAllPoints()
		window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
	end

	MultiBot.reward.doClose = function()
		MultiBot.rewardTryClose()
	end

	prevButton:SetScript("OnClick", function()
		MultiBot.rewardChangePage(-1)
	end)

	nextButton:SetScript("OnClick", function()
		MultiBot.rewardChangePage(1)
	end)
end