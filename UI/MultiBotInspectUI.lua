if not MultiBot then
    return
end

local EQUIPMENT_SLOT_BY_NAME = {
    HeadSlot = 1,
    NeckSlot = 2,
    ShoulderSlot = 3,
    ShirtSlot = 4,
    ChestSlot = 5,
    WaistSlot = 6,
    LegsSlot = 7,
    FeetSlot = 8,
    WristSlot = 9,
    HandsSlot = 10,
    Finger0Slot = 11,
    Finger1Slot = 12,
    Trinket0Slot = 13,
    Trinket1Slot = 14,
    BackSlot = 15,
    MainHandSlot = 16,
    SecondaryHandSlot = 17,
    RangedSlot = 18,
    TabardSlot = 19,
}

local INSPECT_SLOT_SUFFIXES = {
    "HeadSlot",
    "NeckSlot",
    "ShoulderSlot",
    "ShirtSlot",
    "ChestSlot",
    "WaistSlot",
    "LegsSlot",
    "FeetSlot",
    "WristSlot",
    "HandsSlot",
    "Finger0Slot",
    "Finger1Slot",
    "Trinket0Slot",
    "Trinket1Slot",
    "BackSlot",
    "MainHandSlot",
    "SecondaryHandSlot",
    "RangedSlot",
    "TabardSlot",
}

local function getInspectedBotName()
    local inspectUnit = InspectFrame and InspectFrame.unit
    if inspectUnit and UnitExists(inspectUnit) then
        return UnitName(inspectUnit)
    end

    return UnitName("target")
end

local function canUnequipInspectedBot(botName)
    if not botName or botName == "" then
        return false
    end

    if MultiBot.isActive then
        return MultiBot.isActive(botName)
    end

    return UnitIsPlayer("target") and not UnitIsUnit("target", "player")
end

local function requestInventorySync(botName)
    if not botName or botName == "" then
        return
    end

    if MultiBot.RequestInventoryPostActionRefresh and MultiBot.RequestInventoryPostActionRefresh(botName, 0.45, 1.20) then
        return
    end

    if MultiBot.RequestInventoryRefresh and MultiBot.RequestInventoryRefresh(botName, 0.45) then
        return
    end

    local function fallbackRefresh()
        if MultiBot.RequestBotInventory then
            MultiBot.RequestBotInventory(botName)
            return
        end

        if MultiBot.RefreshInventory then
            MultiBot.RefreshInventory(nil, botName)
        end
    end

    if MultiBot.TimerAfter then
        MultiBot.TimerAfter(0.45, fallbackRefresh)
    else
        fallbackRefresh()
    end
end

local function getSlotItemLink(inspectButton)
    if not inspectButton then
        return nil
    end

    local slotId = inspectButton.GetID and inspectButton:GetID() or nil
    if not slotId or slotId <= 0 then
        slotId = EQUIPMENT_SLOT_BY_NAME[inspectButton.mbSlotName or ""]
    end

    local inspectUnit = InspectFrame and InspectFrame.unit
    if inspectUnit and UnitExists(inspectUnit) and slotId then
        return GetInventoryItemLink(inspectUnit, slotId)
    end

    return nil
end

local function showRightClickHint(self)
    if not GameTooltip or not GameTooltip:IsShown() then
        return
    end

    local botName = getInspectedBotName()
    if canUnequipInspectedBot(botName) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Clic droit : déséquiper (ue)", 1, 0.82, 0)
        GameTooltip:Show()
    end
end

local function onInspectSlotClick(self, mouseButton)
    if mouseButton ~= "RightButton" then
        return
    end

    local botName = getInspectedBotName()
    if not canUnequipInspectedBot(botName) then
        return
    end

    local itemLink = getSlotItemLink(self)
    if not itemLink or itemLink == "" then
        return
    end

    SendChatMessage("ue " .. itemLink, "WHISPER", nil, botName)
    requestInventorySync(botName)
end

local function hookInspectSlot(slotSuffix)
    local buttonName = "Inspect" .. slotSuffix
    local button = _G[buttonName]
    if not button or button.__mbUnequipHooked then
        return
    end

    button.__mbUnequipHooked = true
    button.mbSlotName = slotSuffix
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:HookScript("OnClick", onInspectSlotClick)
    button:HookScript("OnEnter", showRightClickHint)
end

local function hookInspectSlots()
    for _, suffix in ipairs(INSPECT_SLOT_SUFFIXES) do
        hookInspectSlot(suffix)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("INSPECT_READY")
loader:SetScript("OnEvent", function()
    hookInspectSlots()
end)