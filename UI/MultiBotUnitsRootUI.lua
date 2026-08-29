if not MultiBot then return end

local UNITS_BUTTON_NAME = "Units"
local UNITS_FRAME_NAME = "Units"
local UNITS_FRAME_X = -40
local UNITS_FRAME_Y = 72
local UNITS_PAGE_SIZE = 10
local UNITS_FRIEND_FALLBACK_MAX = 50
local UNITS_GUILD_FALLBACK_MAX = 50
local UNITS_GUILD_RETRY_LIMIT = 6
local UNITS_GUILD_RETRY_DELAY = 0.25

local refreshStrategiesForActiveBots

local FACTION_BANNERS = {
    Alliance = "inv_misc_tournaments_banner_human",
    Horde = "inv_misc_tournaments_banner_orc",
}

local INVITE_BUTTONS = {
    {
        name = "Party+5",
        x = 0,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\invite_party_5.blp",
        tip = "tips.units.inviteParty5",
        needs = function(raidCount, partyCount)
            return MultiBot.IF(raidCount > 0, 5 - raidCount, MultiBot.IF(partyCount > 0, 4 - partyCount, 4))
        end,
    },
    {
        name = "Raid+10",
        x = 56,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_10.blp",
        tip = "tips.units.inviteRaid10",
        needs = function(raidCount, partyCount)
            return 10 - MultiBot.IF(raidCount > 0, raidCount, MultiBot.IF(partyCount > 0, partyCount + 1, 1))
        end,
    },
    {
        name = "Raid+25",
        x = 82,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_25.blp",
        tip = "tips.units.inviteRaid25",
        needs = function(raidCount, partyCount)
            return 25 - MultiBot.IF(raidCount > 0, raidCount, MultiBot.IF(partyCount > 0, partyCount + 1, 1))
        end,
    },
    {
        name = "Raid+40",
        x = 108,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_40.blp",
        tip = "tips.units.inviteRaid40",
        needs = function(raidCount, partyCount)
            return 40 - MultiBot.IF(raidCount > 0, raidCount, MultiBot.IF(partyCount > 0, partyCount + 1, 1))
        end,
    },
}

local function mergeLists(primary, secondary)
    local result = {}
    local seen = {}

    if primary then
        for index = 1, #primary do
            local name = primary[index]
            if name and not seen[name] then
                seen[name] = true
                table.insert(result, name)
            end
        end
    end

    if secondary then
        for index = 1, #secondary do
            local name = secondary[index]
            if name and not seen[name] then
                seen[name] = true
                table.insert(result, name)
            end
        end
    end

    return result
end

-- MB_ADDON_ROSTER_COHERENCE_D1_BEGIN
local function ensureSocialRosterPresence()
    if type(MultiBot._socialRosterPresence) ~= "table" then
        MultiBot._socialRosterPresence = {}
    end
    if type(MultiBot._socialRosterPresence.members) ~= "table" then
        MultiBot._socialRosterPresence.members = {}
    end
    if type(MultiBot._socialRosterPresence.friends) ~= "table" then
        MultiBot._socialRosterPresence.friends = {}
    end
    return MultiBot._socialRosterPresence
end


local function isSocialRosterOnline(value)
    return value == true or value == 1
end

local function setSocialRosterVisual(button, presenceState)
    if not button then
        return
    end

    local offline = presenceState == "OFFLINE"
    if button.icon and button.icon.SetDesaturated then
        button.icon:SetDesaturated(offline and 1 or 0)
    end
    if button.SetAlpha then
        button:SetAlpha(offline and 0.55 or 1)
    end

    if offline and button.parent and button.parent.frames and button.name then
        local unitFrame = button.parent.frames[button.name]
        if unitFrame then
            unitFrame:Hide()
        end
    end
end

local function restoreButtonStateVisual(button)
    if not button then
        return
    end

    if button.icon and button.icon.SetDesaturated then
        button.icon:SetDesaturated(button.state and 0 or 1)
    end
    if button.SetAlpha then
        button:SetAlpha(1)
    end
end

local function getDisplayedUnitsRosterForSocialRefresh()
    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsButton = multiBar and multiBar.buttons and multiBar.buttons[UNITS_BUTTON_NAME]
    return unitsButton and unitsButton.roster or nil
end

local function clearSocialRosterPresence(unitsFrame)
    local presence = ensureSocialRosterPresence()
    local seen = {}
    local displayedRoster = getDisplayedUnitsRosterForSocialRefresh()

    for _, roster in ipairs({ "members", "friends" }) do
        for name in pairs(presence[roster]) do
            if not seen[name] then
                seen[name] = true
                local button = unitsFrame and unitsFrame.buttons and unitsFrame.buttons[name]
                if button and displayedRoster == roster then
                    button._mbRosterPresence = nil
                    button._mbSocialRoster = nil
                    button._mbSocialForceCollapsed = nil
                    restoreButtonStateVisual(button)
                end
            end
        end
        presence[roster] = {}
    end
end

local function applySocialRosterPresence(button, roster, name, online)
    if not button or (roster ~= "members" and roster ~= "friends") then
        return
    end

    local state = online and "ONLINE" or "OFFLINE"
    local presence = ensureSocialRosterPresence()
    presence[roster][name] = state

    -- Cache social truth for every refresh, but do not mutate the shared
    -- button when another roster owns the visible row.
    if getDisplayedUnitsRosterForSocialRefresh() ~= roster then
        return
    end

    button._mbRosterPresence = state
    button._mbSocialRoster = roster
    button._mbSocialForceCollapsed = state == "OFFLINE"
    setSocialRosterVisual(button, state)
end

local function orderSocialRosterDisplay(roster, display)
    if roster ~= "members" and roster ~= "friends" then
        return display
    end

    local presence = ensureSocialRosterPresence()[roster]
    local online = {}
    local offline = {}

    for index = 1, #display do
        local name = display[index]
        if presence[name] == "OFFLINE" then
            table.insert(offline, name)
        else
            table.insert(online, name)
        end
    end

    return mergeLists(online, offline)
end
-- MB_ADDON_ROSTER_COHERENCE_D1_END

-- MB_ADDON_ALT_ROSTER_SECTIONS_V1_BEGIN
local function getAltLifecycleState(name)
    if not (MultiBot.GetBridgeAltEntry and type(name) == "string") then
        return nil
    end

    local entry = MultiBot.GetBridgeAltEntry(name)
    if not entry then
        return nil
    end

    return string.upper(tostring(entry.state or "OFFLINE"))
end

local function hasBridgeAltRoster()
    return MultiBot.bridge
        and type(MultiBot.bridge.altRoster) == "table"
        and #MultiBot.bridge.altRoster > 0
end

local function splitPlayerDisplay(display)
    local online = {}
    local offline = {}

    for index = 1, #display do
        local name = display[index]
        local state = getAltLifecycleState(name)
        if state == "OFFLINE" or state == "CONNECTING" then
            table.insert(offline, name)
        else
            table.insert(online, name)
        end
    end

    return online, offline
end

local function layoutPlayerAltSections(
    unitsButton,
    unitsFrame,
    onlineNames,
    offlineNames,
    fromIndex,
    toIndex
)
    local effective = {}
    for index = 1, #onlineNames do
        table.insert(effective, onlineNames[index])
    end
    for index = 1, #offlineNames do
        table.insert(effective, offlineNames[index])
    end

    local newVisible = {}
    local y = 0
    local rowStep = unitsFrame.size + 2

    for index = fromIndex, toIndex do
        local name = effective[index]
        if name then
            local unitButton = unitsFrame.buttons[name]
            local unitFrame = unitsFrame.frames[name]

            if unitButton and unitButton.state and MultiBot.EnsureBridgeUnitFrame then
                unitFrame = MultiBot.EnsureBridgeUnitFrame(name) or unitFrame
            end

            if unitButton then
                unitButton.setPoint(0, y)
                if unitFrame then
                    unitFrame.setPoint(-34, y + 2)
                end
                if unitFrame and unitButton.state then
                    unitFrame:Show()
                end
                unitButton:Show()
                table.insert(newVisible, name)
                y = y + rowStep
            end
        end
    end

    unitsButton.from = fromIndex
    unitsButton.to = toIndex
    unitsButton._visibleNames = newVisible
    unitsFrame.frames.Control.setPoint(-2, y)
    return #effective
end
-- MB_ADDON_ALT_ROSTER_SECTIONS_V1_END

local function getUnitsRootObjects(button)
    local unitsFrame = button.parent.frames[UNITS_FRAME_NAME]
    return button.parent, unitsFrame
end

local function getUnitsSourceTable(unitsButton)
    if unitsButton.roster == "players" then
        if unitsButton.filter ~= "none" then
            return MultiBot.index.classes.players[unitsButton.filter]
        end

        return MultiBot.index.players
    end

    if unitsButton.filter ~= "none" then
        return MultiBot.index.classes[unitsButton.roster][unitsButton.filter]
    end

    return MultiBot.index[unitsButton.roster]
end

local function getDisplayableUnits(unitsFrame, sourceTable)
    local display = {}
    if not sourceTable then
        return display
    end

    for index = 1, #sourceTable do
        local name = sourceTable[index]
        if name ~= nil and unitsFrame.buttons[name] ~= nil then
            table.insert(display, name)
        else
            MultiBot.dprint("Units.skip", name or "<nil>", "(missing button)")
        end
    end

    return display
end

local function addRefreshTarget(targets, seen, unitsFrame, name)
    if type(name) ~= "string" or name == "" or name == UnitName("player") then
        return
    end

    if seen[name] or not (unitsFrame and unitsFrame.buttons and unitsFrame.buttons[name]) then
        return
    end

    local unitButton = unitsFrame.buttons[name]
    if unitButton and unitButton._mbRosterPresence == "OFFLINE" then
        return
    end

    if MultiBot.IsBridgeAltUnavailable and MultiBot.IsBridgeAltUnavailable(name) then
        return
    end

    seen[name] = true
    table.insert(targets, name)
end

local function getVisibleRefreshTargets(unitsButton, unitsFrame)
    local targets = {}
    local seen = {}

    if not unitsButton or not unitsFrame then
        return targets
    end

    local visibleNames = unitsButton._visibleNames
    if type(visibleNames) == "table" and #visibleNames > 0 then
        for index = 1, #visibleNames do
            addRefreshTarget(targets, seen, unitsFrame, visibleNames[index])
        end

        return targets
    end

    local sourceTable = getUnitsSourceTable(unitsButton)
    local display = getDisplayableUnits(unitsFrame, sourceTable)
    local fromIndex = tonumber(unitsButton.from) or 1
    local toIndex = tonumber(unitsButton.to) or math.min(#display, UNITS_PAGE_SIZE)

    if fromIndex < 1 then
        fromIndex = 1
    end
    if toIndex < fromIndex then
        toIndex = math.min(#display, UNITS_PAGE_SIZE)
    end

    for index = fromIndex, math.min(toIndex, #display) do
        addRefreshTarget(targets, seen, unitsFrame, display[index])
    end

    return targets
end

local function hideTrackedVisibleUnits(unitsButton, unitsFrame)
    local visibleNames = unitsButton and unitsButton._visibleNames
    if type(visibleNames) ~= "table" then
        unitsButton._visibleNames = {}
        return
    end

    for index = 1, #visibleNames do
        local name = visibleNames[index]
        local unitButton = name and unitsFrame.buttons[name]
        local unitFrame = name and unitsFrame.frames[name]
        if unitFrame then
            unitFrame:Hide()
        end
        if unitButton then
            unitButton:Hide()
        end
    end

    unitsButton._visibleNames = {}
end

local function layoutVisibleUnits(unitsButton, unitsFrame, display, fromIndex, toIndex)
    local visibleCount = 0
    local startIndex = fromIndex or 1
    local endIndex = toIndex or 0

    local newVisible = {}

    for index = startIndex, endIndex do
        local name = display[index]
        local unitButton = name and unitsFrame.buttons[name]
        local unitFrame = name and unitsFrame.frames[name]
        local isOnline = unitButton and (
            (MultiBot.IsUnitBotOnline and MultiBot.IsUnitBotOnline(unitButton, name))
            or (not MultiBot.IsUnitBotOnline and unitButton.state == true)
        )

        if isOnline and MultiBot.EnsureBridgeUnitFrame then
            unitFrame = MultiBot.EnsureBridgeUnitFrame(name) or unitFrame
        end
        if unitButton then
            visibleCount = visibleCount + 1
            unitButton.setPoint(0, (unitsFrame.size + 2) * (visibleCount - 1))
            if unitFrame then
                unitFrame.setPoint(-34, (unitsFrame.size + 2) * (visibleCount - 1) + 2)
                if isOnline then
                    unitFrame:Show()
                else
                    unitFrame:Hide()
                end
            end
            unitButton:Show()
            table.insert(newVisible, name)
        end
    end

    unitsButton.from = startIndex
    unitsButton.to = endIndex
    unitsFrame.frames.Control.setPoint(-2, (unitsFrame.size + 2) * visibleCount)
    unitsButton._visibleNames = newVisible
end

local function relayoutUnitsDisplay(unitsButton, unitsFrame)
    if not unitsButton or not unitsFrame then
        return
    end


    for _, value in pairs(unitsFrame.buttons) do
        value:Hide()
    end
    for _, value in pairs(unitsFrame.frames) do
        value:Hide()
    end

    if unitsFrame.frames["Alliance"] then
        unitsFrame.frames["Alliance"]:Show()
    end
    if unitsFrame.frames["Control"] then
        unitsFrame.frames["Control"]:Show()
    end

    local sourceTable = getUnitsSourceTable(unitsButton)
    local display = getDisplayableUnits(unitsFrame, sourceTable)

    if unitsButton.roster == "members" or unitsButton.roster == "friends" then
        display = orderSocialRosterDisplay(unitsButton.roster, display)
    end

    if unitsButton.roster == "players" and hasBridgeAltRoster() then
        local onlineNames, offlineNames = splitPlayerDisplay(display)
        local effectiveLimit = #onlineNames + #offlineNames

        unitsButton.limit = effectiveLimit
        local fromIndex = tonumber(unitsButton.from) or 1
        if fromIndex < 1 then
            fromIndex = 1
        end
        if effectiveLimit > 0 and fromIndex > effectiveLimit then
            fromIndex = math.max(1, effectiveLimit - UNITS_PAGE_SIZE + 1)
        end

        local toIndex = effectiveLimit > 0
            and math.min(effectiveLimit, fromIndex + UNITS_PAGE_SIZE - 1)
            or 0

        hideTrackedVisibleUnits(unitsButton, unitsFrame)
        layoutPlayerAltSections(
            unitsButton,
            unitsFrame,
            onlineNames,
            offlineNames,
            fromIndex,
            toIndex
        )

        if effectiveLimit < UNITS_PAGE_SIZE + 1 then
            unitsFrame.frames.Control.buttons["Browse"]:Hide()
        else
            unitsFrame.frames.Control.buttons["Browse"]:Show()
        end
        return
    end

    unitsButton.limit = #display
    if unitsButton.limit <= 0 then
        unitsButton.from = 1
        unitsButton.to = 0
        hideTrackedVisibleUnits(unitsButton, unitsFrame)
        unitsFrame.frames.Control.setPoint(-2, 0)
        if unitsFrame.frames.Control.buttons["Browse"] then
            unitsFrame.frames.Control.buttons["Browse"]:Hide()
        end
        return
    end

    local fromIndex = tonumber(unitsButton.from) or 1
    if fromIndex < 1 then
        fromIndex = 1
    end
    if fromIndex > unitsButton.limit then
        fromIndex = math.max(1, unitsButton.limit - UNITS_PAGE_SIZE + 1)
    end

    local toIndex = math.min(unitsButton.limit, fromIndex + UNITS_PAGE_SIZE - 1)

    hideTrackedVisibleUnits(unitsButton, unitsFrame)
    layoutVisibleUnits(unitsButton, unitsFrame, display, fromIndex, toIndex)

    if unitsButton.limit < UNITS_PAGE_SIZE + 1 then
        unitsFrame.frames.Control.buttons["Browse"]:Hide()
    else
        unitsFrame.frames.Control.buttons["Browse"]:Show()
    end
end

local function refreshUnitsDisplay(unitsButton, requestedRoster, requestedFilter)
    MultiBot.dprint("Units.doLeft", "roster=", requestedRoster or unitsButton.roster, "filter=", requestedFilter or unitsButton.filter)

    local _, unitsFrame = getUnitsRootObjects(unitsButton)
    if not unitsFrame then
        return
    end

    if requestedRoster == nil and requestedFilter == nil then
        MultiBot.ShowHideSwitch(unitsFrame)
    elseif requestedRoster ~= nil then
        unitsButton.roster = requestedRoster
    elseif requestedFilter ~= nil then
        unitsButton.filter = requestedFilter
    end

    if unitsButton.roster == "favorites" then
        if MultiBot.UpdateFavoritesIndex then
            MultiBot.UpdateFavoritesIndex()
        elseif MultiBot.EnsureFavoriteButtons then
            MultiBot.EnsureFavoriteButtons()
        end
    end

    if requestedRoster == "players" or unitsButton.roster == "players" then
        if MultiBot.bridge and MultiBot.bridge.connected then
            if MultiBot.bridge.roster and #MultiBot.bridge.roster > 0 then
                if MultiBot.SyncBridgeRosterToPlayers then
                    MultiBot.SyncBridgeRosterToPlayers(MultiBot.bridge.roster)
                end
            elseif MultiBot.Comm and MultiBot.Comm.RequestRoster then
                MultiBot.Comm.RequestRoster()
            end

            if MultiBot.bridge.altRosterCapable
                and MultiBot.Comm
                and MultiBot.Comm.RequestAltRoster then
                MultiBot.Comm.RequestAltRoster()
            end
        end

        if not (MultiBot.index.players and #MultiBot.index.players > 0) then
            if MultiBot.RebuildPlayersIndexFromButtons then
                MultiBot.RebuildPlayersIndexFromButtons()
            end
            if not (MultiBot.index.players and #MultiBot.index.players > 0) then
                if MultiBot.bridge and MultiBot.Comm and MultiBot.Comm.RequestRoster then
                    if MultiBot.bridge.connected then
                        MultiBot.Comm.RequestRoster()
                    else
                        MultiBot.TimerAfter(0.5, function()
                            if MultiBot.bridge and MultiBot.bridge.connected and MultiBot.Comm and MultiBot.Comm.RequestRoster then
                                MultiBot.Comm.RequestRoster()
                            end
                        end)
                    end
                end
            end
        end
    end

    local sourceTable = getUnitsSourceTable(unitsButton)
    MultiBot.dprint("Units.tTable.size", sourceTable and #sourceTable or 0)

    if requestedRoster ~= nil or requestedFilter ~= nil then
        unitsButton.from = 1
        unitsButton.to = UNITS_PAGE_SIZE
    elseif (tonumber(unitsButton.from) or 0) < 1 then
        unitsButton.from = 1
        unitsButton.to = UNITS_PAGE_SIZE
    end

    relayoutUnitsDisplay(unitsButton, unitsFrame)

    if refreshStrategiesForActiveBots then
        refreshStrategiesForActiveBots(unitsButton)
    end
end

function MultiBot.RelayoutUnitsDisplay()
    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsButton = multiBar and multiBar.buttons and multiBar.buttons[UNITS_BUTTON_NAME]
    local unitsFrame = multiBar and multiBar.frames and multiBar.frames[UNITS_FRAME_NAME]

    if not unitsButton or not unitsFrame or not unitsFrame:IsVisible() then
        return false
    end

    relayoutUnitsDisplay(unitsButton, unitsFrame)
    return true
end

local function configureRosterRetry(button, isGuildRetry, retryCount, needGuildRetry)
    if (not isGuildRetry) and needGuildRetry and retryCount < UNITS_GUILD_RETRY_LIMIT then
        button._guildRosterRetryCount = retryCount + 1
        button._guildRosterRetrying = true
        MultiBot.TimerAfter(UNITS_GUILD_RETRY_DELAY, function()
            if button and button.doRight then
                button.doRight(button)
            end
        end)
        return
    end

    button._guildRosterRetryCount = 0
end

-- MB_D2B_GUILD_STRUCTURED_LIFECYCLE_V1_BEGIN
local function getCurrentUnitsRoster()
    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsButton = multiBar and multiBar.buttons and multiBar.buttons[UNITS_BUTTON_NAME]
    return unitsButton and unitsButton.roster or nil
end

local function getSocialRosterPresenceForButton(button, roster)
    local presence = ensureSocialRosterPresence()
    local bucket = presence and presence[roster]
    if button and bucket and bucket[button.name] then
        return bucket[button.name]
    end
    if button and button._mbSocialRoster == roster then
        return button._mbRosterPresence
    end
    return nil
end

local function hideGuildUnitFrame(button)
    local frames = button and button.parent and button.parent.frames
    local frame = frames and frames[button.name]
    if frame and frame.Hide then
        frame:Hide()
    end
end

local function requestGuildRosterRefresh()
    if type(GuildRoster) == "function" then
        GuildRoster()
    end
    MultiBot.TimerAfter(UNITS_GUILD_RETRY_DELAY, function()
        if type(GuildRoster) == "function" then
            GuildRoster()
        end
    end)
end

local function isGuildLifecyclePending(button)
    local phase = button and button._mbGuildLifecyclePhase
    return phase == "RESOLVING"
        or phase == "CONNECTING"
        or phase == "DISCONNECTING"
end

local function runGuildLifecycleByGuid(button, action, guid)
    if not button or isGuildLifecyclePending(button) then
        return false
    end
    if not MultiBot.Comm or type(MultiBot.Comm.RunBotLifecycle) ~= "function" then
        return false
    end

    button._mbGuildLifecyclePhase = action == "CONNECT" and "CONNECTING" or "DISCONNECTING"

    local token = MultiBot.Comm.RunBotLifecycle(action, guid, function(result)
        button._mbGuildLifecyclePhase = nil
        if result and result.status == "OK" then
            if result.guid then
                button._mbGuildResolvedGuid = tonumber(result.guid) or button._mbGuildResolvedGuid
            end

            local lifecycleState = string.upper(tostring(result.lifecycleState or ""))
            if MultiBot.SetBridgeBotOnlineState
                and (lifecycleState == "ONLINE" or lifecycleState == "OFFLINE") then
                MultiBot.SetBridgeBotOnlineState(button, lifecycleState == "ONLINE")
            end
        end
        requestGuildRosterRefresh()
    end)

    if not token then
        button._mbGuildLifecyclePhase = nil
        requestGuildRosterRefresh()
        return false
    end

    if action == "DISCONNECT" then
        button._mbSocialForceCollapsed = true
        if MultiBot.SetBridgeBotOnlineState then
            MultiBot.SetBridgeBotOnlineState(button, false)
        else
            hideGuildUnitFrame(button)
            if button.setDisable then
                button.setDisable()
            end
        end
    end
    return true
end

local function resolveAndRunGuildLifecycle(button, action)
    if not button or isGuildLifecyclePending(button) then
        return
    end

    local cachedGuid = tonumber(button._mbGuildResolvedGuid)
    if cachedGuid and cachedGuid > 0 then
        runGuildLifecycleByGuid(button, action, cachedGuid)
        return
    end

    if not MultiBot.Comm or type(MultiBot.Comm.ResolveBotTarget) ~= "function" then
        return
    end

    button._mbGuildLifecyclePhase = "RESOLVING"
    local token = MultiBot.Comm.ResolveBotTarget(button.name, function(result)
        button._mbGuildLifecyclePhase = nil

        if not result or result.status ~= "OK" then
            requestGuildRosterRefresh()
            return
        end

        local guid = tonumber(result.guid)
        if not guid or guid <= 0 then
            requestGuildRosterRefresh()
            return
        end
        button._mbGuildResolvedGuid = guid

        if action == "CONNECT" then
            if result.lifecycleState == "ONLINE" then
                if MultiBot.SetBridgeBotOnlineState then
                    MultiBot.SetBridgeBotOnlineState(button, true)
                else
                    button.setEnable()
                end
                requestGuildRosterRefresh()
                return
            end
            if result.lifecycleState ~= "OFFLINE" or result.reason == "IN_USE" then
                requestGuildRosterRefresh()
                return
            end
        elseif action == "DISCONNECT" then
            if result.lifecycleState ~= "ONLINE" then
                requestGuildRosterRefresh()
                return
            end
        else
            return
        end

        runGuildLifecycleByGuid(button, action, guid)
    end)

    if not token then
        button._mbGuildLifecyclePhase = nil
    end
end

local function openGuildEveryBar(button)
    if not button or isGuildLifecyclePending(button) then
        return
    end

    button._mbSocialForceCollapsed = false

    local function showOrToggle()
        if getCurrentUnitsRoster() ~= "members" then
            return
        end
        if getSocialRosterPresenceForButton(button, "members") ~= "ONLINE" then
            return
        end

        button._mbGuildLifecyclePhase = nil
        button._mbSocialForceCollapsed = false
        if button._mbGroupRejoinCollapsed == true then
            button._mbGroupRejoinCollapsed = false
        end

        local frames = button.parent and button.parent.frames
        local unitFrame = frames and frames[button.name]
        if not unitFrame and MultiBot.EnsureBridgeUnitFrame then
            unitFrame = MultiBot.EnsureBridgeUnitFrame(button.name)
        end
        if unitFrame then
            MultiBot.ShowHideSwitch(unitFrame)
        end
    end

    if button.state then
        showOrToggle()
        return
    end

    if not MultiBot.Comm or type(MultiBot.Comm.ResolveBotTarget) ~= "function" then
        return
    end

    button._mbGuildLifecyclePhase = "RESOLVING"
    local token = MultiBot.Comm.ResolveBotTarget(button.name, function(result)
        if not result or result.status ~= "OK"
            or result.lifecycleState ~= "ONLINE" then
            button._mbGuildLifecyclePhase = nil
            requestGuildRosterRefresh()
            return
        end

        local guid = tonumber(result.guid)
        if not guid or guid <= 0 then
            button._mbGuildLifecyclePhase = nil
            requestGuildRosterRefresh()
            return
        end

        button._mbGuildResolvedGuid = guid
        if MultiBot.SetBridgeBotOnlineState then
            MultiBot.SetBridgeBotOnlineState(button, true)
        else
            button.setEnable()
        end

        if MultiBot.Comm and type(MultiBot.Comm.RequestState) == "function" then
            MultiBot.Comm.RequestState(button.name)
        end

        MultiBot.TimerAfter(0.20, showOrToggle)
    end)

    if not token then
        button._mbGuildLifecyclePhase = nil
    end
end
-- MB_D2B_GUILD_STRUCTURED_LIFECYCLE_V1_END

local function isSharedRosterButtonOnline(button)
    if not button then
        return false
    end
    if MultiBot.IsUnitBotOnline then
        return MultiBot.IsUnitBotOnline(button, button.name)
    end
    return button.state == true
end

local function hideSharedRosterUnitFrame(button)
    local frames = button and button.parent and button.parent.frames
    local unitFrame = frames and frames[button.name]
    if unitFrame and unitFrame.Hide then
        unitFrame:Hide()
    end
end

local function addRosterMemberButton(member, socialRoster)
    -- Guild/Friends rebuilds run in the background and reuse the same button
    -- object by character name. Only the displayed social roster may alter
    -- the shared button's visual connection state here.
    if getCurrentUnitsRoster() == socialRoster then
        if member.state == false then
            member.setDisable()
        else
            member.setEnable()
        end
    end

    member.doRight = function(button)
        local currentRoster = getCurrentUnitsRoster()

        if currentRoster == "actives" then
            if not isSharedRosterButtonOnline(button) then
                return
            end

            if MultiBot.TryStructuredGroupDisconnect
                and MultiBot.TryStructuredGroupDisconnect(button) then
                return
            end

            -- Preserve the pre-existing fallback only when structured
            -- lifecycle capabilities are unavailable.
            SendChatMessage(".playerbot bot remove " .. button.name, "SAY")
            if MultiBot.SetBridgeBotOnlineState and button.bridge ~= nil then
                MultiBot.SetBridgeBotOnlineState(button, false)
            else
                hideSharedRosterUnitFrame(button)
                if button.setDisable then
                    button.setDisable()
                end
            end
            return
        end

        if currentRoster == "members" then
            if getSocialRosterPresenceForButton(button, "members") ~= "ONLINE" then
                return
            end
            resolveAndRunGuildLifecycle(button, "DISCONNECT")
            return
        end

        if button._mbRosterPresence == "OFFLINE" then
            return
        end
        if button.state == false then
            return
        end
        button._mbSocialForceCollapsed = true
        SendChatMessage(".playerbot bot remove " .. button.name, "SAY")
        if button.parent.frames[button.name] ~= nil then
            button.parent.frames[button.name]:Hide()
        end
        button.setDisable()
    end

    member.doLeft = function(button)
        local currentRoster = getCurrentUnitsRoster()

        if currentRoster == "actives" then
            if isSharedRosterButtonOnline(button) then
                if button.parent and button.parent.frames
                    and button.parent.frames[button.name] ~= nil then
                    if button._mbGroupRejoinCollapsed == true then
                        button._mbGroupRejoinCollapsed = false
                    end
                    MultiBot.ShowHideSwitch(button.parent.frames[button.name])
                end
                return
            end

            if MultiBot.TryStructuredGroupReconnect
                and MultiBot.TryStructuredGroupReconnect(button) then
                return
            end

            SendChatMessage(".playerbot bot add " .. button.name, "SAY")
            if button.setEnable then
                button.setEnable()
            end
            return
        end

        if currentRoster == "members" then
            local guildPresence = getSocialRosterPresenceForButton(button, "members")
            if guildPresence == "OFFLINE" then
                resolveAndRunGuildLifecycle(button, "CONNECT")
            elseif guildPresence == "ONLINE" then
                openGuildEveryBar(button)
            end
            return
        end

        if button._mbRosterPresence == "OFFLINE" then
            if getCurrentUnitsRoster() == "actives"
                and MultiBot.TryStructuredGroupReconnect
                and MultiBot.TryStructuredGroupReconnect(button) then
                return
            end
            return
        end

        button._mbSocialForceCollapsed = false
        if button.state then
            if button.parent.frames[button.name] ~= nil then
                if button._mbGroupRejoinCollapsed == true then
                    button._mbGroupRejoinCollapsed = false
                end
                MultiBot.ShowHideSwitch(button.parent.frames[button.name])
            end
            return
        end

        SendChatMessage(".playerbot bot add " .. button.name, "SAY")
        button.setEnable()
    end
end

local function rebuildGuildAndFriendIndexes(button)
    local isGuildRetry = button._guildRosterRetrying == true
    button._guildRosterRetrying = false
    local retryCount = tonumber(button._guildRosterRetryCount) or 0
    if not isGuildRetry then
        retryCount = 0
    end

    local needGuildRetry = false

    local inGuild = false
    if type(IsInGuild) == "function" then
        inGuild = IsInGuild()
    elseif type(GetGuildInfo) == "function" then
        inGuild = GetGuildInfo("player") ~= nil
    end

    local previousShowOffline = nil
    if inGuild and type(GetGuildRosterShowOffline) == "function" and type(SetGuildRosterShowOffline) == "function" then
        previousShowOffline = GetGuildRosterShowOffline()
        if previousShowOffline == false then
            SetGuildRosterShowOffline(true)
        end
    end

    if inGuild and type(GuildRoster) == "function" then
        GuildRoster()
    end
    if type(ShowFriends) == "function" then
        ShowFriends()
    end

    local _, unitsFrame = getUnitsRootObjects(button)
    clearSocialRosterPresence(unitsFrame)

    MultiBot.index.members = {}
    MultiBot.index.classes.members = {}
    MultiBot.index.friends = {}
    MultiBot.index.classes.friends = {}

    local maxMembers = 0
    if type(GetNumGuildMembers) == "function" then
        maxMembers = select(1, GetNumGuildMembers()) or 0
    end
    maxMembers = tonumber(maxMembers) or 0
    if maxMembers <= 0 then
        maxMembers = UNITS_GUILD_FALLBACK_MAX
        if inGuild then
            needGuildRetry = true
        end
    end

    local guildCount = 0
    for index = 1, maxMembers do
        local name, _, _, level, className, _, _, _, online = GetGuildRosterInfo(index)
        if name ~= nil and level ~= nil and className ~= nil
            and name ~= UnitName("player") then
            guildCount = guildCount + 1
            local member = MultiBot.addMember(className, level, name)
            addRosterMemberButton(member, "members")
            applySocialRosterPresence(member, "members", name, isSocialRosterOnline(online))
        elseif name == nil or level == nil or className == nil then
            if inGuild and index < maxMembers then
                needGuildRetry = true
            end
            break
        end
    end

    if previousShowOffline == false and type(SetGuildRosterShowOffline) == "function" then
        SetGuildRosterShowOffline(false)
    end

    if not isGuildRetry and inGuild and maxMembers == UNITS_GUILD_FALLBACK_MAX and guildCount == UNITS_GUILD_FALLBACK_MAX then
        needGuildRetry = true
    end

    local maxFriends = 0
    if type(GetNumFriends) == "function" then
        maxFriends = GetNumFriends() or 0
    end
    maxFriends = tonumber(maxFriends) or 0
    if maxFriends <= 0 then
        maxFriends = UNITS_FRIEND_FALLBACK_MAX
    end

    for index = 1, maxFriends do
        local name, level, className, _, online = GetFriendInfo(index)
        if name ~= nil and level ~= nil and className ~= nil
            and name ~= UnitName("player") then
            local friend = MultiBot.addFriend(className, level, name)
            addRosterMemberButton(friend, "friends")
            applySocialRosterPresence(friend, "friends", name, isSocialRosterOnline(online))
        elseif name == nil or level == nil or className == nil then
            needGuildRetry = true
        end
    end

    configureRosterRetry(button, isGuildRetry, retryCount, needGuildRetry)
    return isGuildRetry
end

-- MB_ADDON_ROSTER_COHERENCE_D1_EVENTS_BEGIN
local socialRosterEventPending = false
local socialRosterEventFrame = CreateFrame("Frame")

local function scheduleSocialRosterRefresh()
    if socialRosterEventPending then
        return
    end

    socialRosterEventPending = true

    local function runRefresh()
        local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
        local unitsButton = multiBar and multiBar.buttons and multiBar.buttons[UNITS_BUTTON_NAME]
        local unitsFrame = multiBar and multiBar.frames and multiBar.frames[UNITS_FRAME_NAME]

        if unitsButton and unitsFrame then
            rebuildGuildAndFriendIndexes(unitsButton)
            if unitsButton.roster == "members" or unitsButton.roster == "friends" then
                relayoutUnitsDisplay(unitsButton, unitsFrame)
            end
        end

        local function releaseGuard()
            socialRosterEventPending = false
        end

        if MultiBot.TimerAfter then
            MultiBot.TimerAfter(0.50, releaseGuard)
        else
            releaseGuard()
        end
    end

    if MultiBot.TimerAfter then
        MultiBot.TimerAfter(0.20, runRefresh)
    else
        runRefresh()
    end
end

socialRosterEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
socialRosterEventFrame:RegisterEvent("FRIENDLIST_UPDATE")
socialRosterEventFrame:SetScript("OnEvent", scheduleSocialRosterRefresh)
-- MB_ADDON_ROSTER_COHERENCE_D1_EVENTS_END

refreshStrategiesForActiveBots = function(unitsButton)
    local unitsFrame = MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames[UNITS_FRAME_NAME]
    local scopedToDisplayedUnits = unitsButton ~= nil
    local targetNames = scopedToDisplayedUnits and getVisibleRefreshTargets(unitsButton, unitsFrame) or nil

    if MultiBot.bridge and MultiBot.Comm and MultiBot.Comm.RequestStates then
        if not MultiBot.bridge.connected then
            return
        end

        local function markBridgeStateWait(name)
            if not name or name == UnitName("player") then
                return
            end

            local button = unitsFrame and unitsFrame.buttons and unitsFrame.buttons[name]
            if button then
                button.waitFor = "BRIDGE_STATE"
            end
        end

        if scopedToDisplayedUnits then
            if targetNames and #targetNames > 0 and MultiBot.Comm.RequestState then
                for index = 1, #targetNames do
                    local name = targetNames[index]
                    markBridgeStateWait(name)
                    MultiBot.Comm.RequestState(name)
                end
            end

            return
        end

        if IsInRaid() then
            for index = 1, GetNumGroupMembers() do
                markBridgeStateWait(UnitName("raid" .. index))
            end
        elseif IsInGroup() then
            for index = 1, GetNumSubgroupMembers() do
                markBridgeStateWait(UnitName("party" .. index))
            end
        end

        MultiBot.Comm.RequestStates()
        return
    end

    if MultiBot.allowLegacyChatFallback ~= true then
        return
    end

    local function refreshStrategiesFor(name)
        if not name or name == UnitName("player") then
            return
        end

        local rosters = { "actives", "players", "members", "friends", "favorites" }
        local isBot = false
        local hasAnyRoster = false

        if MultiBot.isRoster and MultiBot.index then
            for index = 1, #rosters do
                local rosterName = rosters[index]
                local list = MultiBot.index[rosterName]
                if list and next(list) ~= nil then
                    hasAnyRoster = true
                end
                if list and MultiBot.isRoster(rosterName, name) then
                    isBot = true
                    break
                end
            end
        end

        if not isBot and hasAnyRoster then
            return
        end

        local button = unitsFrame and unitsFrame.buttons and unitsFrame.buttons[name]

        if button then
            button.waitFor = "CO"
        end

        SendChatMessage("co ?", "WHISPER", nil, name)
    end

    if scopedToDisplayedUnits then
        if targetNames and #targetNames > 0 then
            for index = 1, #targetNames do
                refreshStrategiesFor(targetNames[index])
            end
        end

        return
    end

    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do
            refreshStrategiesFor(UnitName("raid" .. index))
        end
        return
    end

    if IsInGroup() then
        for index = 1, GetNumSubgroupMembers() do
            refreshStrategiesFor(UnitName("party" .. index))
        end
    end
end

local function requestRosterBootstrap(button)
    if MultiBot.Comm then
        if MultiBot.Comm.SendHello then
            MultiBot.Comm.SendHello()
        end
        if MultiBot.Comm.SendPing then
            MultiBot.Comm.SendPing()
        end
        if MultiBot.Comm.RequestRoster then
            MultiBot.Comm.RequestRoster()
        end
        if MultiBot.Comm.RequestAltRoster then
            MultiBot.Comm.RequestAltRoster()
        end
        if MultiBot.Comm.RequestStates then
            MultiBot.Comm.RequestStates()
        end
        if MultiBot.Comm.RequestBotDetails then
            MultiBot.Comm.RequestBotDetails()
        end
     end

    local function fallbackToSystemRoster()
        local bridge = MultiBot.bridge
        local bridgeRosterSize = 0

        if bridge and bridge.roster then
            bridgeRosterSize = #bridge.roster
        end

        if bridge and bridge.connected then
            if bridgeRosterSize > 0 then
                if MultiBot.SyncBridgeRosterToPlayers then
                    MultiBot.SyncBridgeRosterToPlayers(bridge.roster)
                end
            end
        end
    end

    if MultiBot.TimerAfter then
        MultiBot.TimerAfter(0.75, fallbackToSystemRoster)
    else
        fallbackToSystemRoster()
    end
end

local function requestRosterRefreshIfNeeded(button, isGuildRetry)
    if isGuildRetry then
        return
    end

    local roster = button.roster or "players"
    if roster == "players" or roster == "actives" or roster == "favorites" then
        requestRosterBootstrap(button)
        if roster == "favorites" and MultiBot.UpdateFavoritesIndex ~= nil then
            MultiBot.UpdateFavoritesIndex()
        end
    end

    refreshStrategiesForActiveBots()
end

local function onUnitsButtonRightClick(button)
    local isGuildRetry = rebuildGuildAndFriendIndexes(button)
    requestRosterRefreshIfNeeded(button, isGuildRetry)

    button.doLeft(button, button.roster, button.filter)

    MultiBot.TimerAfter(UNITS_GUILD_RETRY_DELAY, function()
        local unitsButton = MultiBot.frames
            and MultiBot.frames["MultiBar"]
            and MultiBot.frames["MultiBar"].buttons
            and MultiBot.frames["MultiBar"].buttons[UNITS_BUTTON_NAME]
        if unitsButton and unitsButton.doLeft then
            unitsButton.doLeft(unitsButton, unitsButton.roster, unitsButton.filter)
        end
    end)
end

local function createFactionBanner(unitsFrame)
    local allianceFrame = unitsFrame.addFrame("Alliance", 0, -34, 32)
    allianceFrame:Show()

    local faction = UnitFactionGroup("player")
    local bannerIcon = FACTION_BANNERS[faction] or FACTION_BANNERS.Alliance

    local button = allianceFrame.addButton("FactionBanner", 0, 0, bannerIcon, MultiBot.L("tips.units.alliance"))
    button:doShow()
    button.doRight = function()
        SendChatMessage(".playerbot bot remove *", "SAY")
    end
    button.doLeft = function()
        SendChatMessage(".playerbot bot add *", "SAY")
    end

    return allianceFrame, button
end

local function createPvpStatsControls(controlFrame)
    local mainButton = controlFrame.addButton("PvPStats", 0, 60, "Ability_Parry", MultiBot.L("tips.units.pvpstatsmaster")).setEnable()
    local whisperButton = controlFrame.addButton("PvPStatsWhisper", 31, 60, "inv_Mask_04", MultiBot.L("tips.units.pvpstatstobot"))
    local partyButton = controlFrame.addButton("PvPStatsParty", 61, 60, "achievement_reputation_08", MultiBot.L("tips.units.pvpstatstoparty"))
    local raidButton = controlFrame.addButton("PvPStatsRaid", 91, 60, "achievement_pvp_o_10", MultiBot.L("tips.units.pvpstatstoraid"))

    whisperButton:doHide()
    partyButton:doHide()
    raidButton:doHide()

    local function showPvpFrame()
        if MultiBotPVPFrame and MultiBotPVPFrame.Show then
            MultiBotPVPFrame:Show()
        end
    end

    local PVP_STATS_LEGACY_FILTER_TTL = 8

    local function pvpStatsNow()
        if GetTime then
            return GetTime()
        end

        return time and time() or 0
    end

    local function normalizePvpStatsAuthorName(author)
        if type(author) ~= "string" then
            return ""
        end

        local name = author
        if Ambiguate then
            name = Ambiguate(author, "none") or author
        end

        name = string.match(name, "^[^-]+") or name
        return string.lower(name or "")
    end

    local function isPvpStatsLegacyLine(message)
        return type(message) == "string" and string.find(message, "%[PVP%]") ~= nil
    end

    local function ensurePvpStatsLegacyFilter()
        if MultiBot._pvpStatsLegacyFilterInstalled then
            return true
        end

        if type(ChatFrame_AddMessageEventFilter) ~= "function" then
            return false
        end

        MultiBot._pvpStatsLegacyFilterInstalled = true
        ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, _, message, author, ...)
            local state = MultiBot and MultiBot._pvpStatsLegacyFilter or nil
            if type(state) ~= "table" then
                return false
            end

            if state.expiresAt and pvpStatsNow() > state.expiresAt then
                MultiBot._pvpStatsLegacyFilter = nil
                return false
            end

            if state.botKey and normalizePvpStatsAuthorName(author) ~= state.botKey then
                return false
            end

            if isPvpStatsLegacyLine(message) then
                return true
            end

            return false
        end)

        return true
    end

    local function suppressNextPvpStatsLegacyWhisper(botName)
        if not ensurePvpStatsLegacyFilter() then
            return
        end

        local botKey = nil
        if botName and botName ~= "" then
            botKey = normalizePvpStatsAuthorName(botName)
        end

        MultiBot._pvpStatsLegacyFilter = {
            botKey = botKey ~= "" and botKey or nil,
            expiresAt = pvpStatsNow() + PVP_STATS_LEGACY_FILTER_TTL,
        }
    end

    local function requestBridgePvpStats(botName)
        local comm = MultiBot.Comm or nil

        if comm and comm.RequestPvpStats and comm.RequestPvpStats(botName) then
            suppressNextPvpStatsLegacyWhisper(botName)
            showPvpFrame()
            return true
        end

        return false
    end

    mainButton.doLeft = function()
        if whisperButton:IsShown() then
            whisperButton:doHide()
            partyButton:doHide()
            raidButton:doHide()
            return
        end

        whisperButton:doShow()
        partyButton:doShow()
        raidButton:doShow()
    end

    whisperButton.doLeft = function()
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
            UIErrorsFrame:AddMessage(MultiBot.L("pvp.stats.error_select_bot"), 1, 0.2, 0.2, 1)
            return
        end

        if requestBridgePvpStats(bot) then
            return
        end

        SendChatMessage("pvp stats", "WHISPER", nil, bot)
        showPvpFrame()
    end

    partyButton.doLeft = function()
        if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
            UIErrorsFrame:AddMessage(MultiBot.L("pvp.stats.error_not_in_group"), 1, 0.2, 0.2, 1)
            return
        end

        if requestBridgePvpStats(nil) then
            return
        end

        SendChatMessage("pvp stats", "PARTY")
        showPvpFrame()
    end

    raidButton.doLeft = function()
        if GetNumRaidMembers() == 0 then
            UIErrorsFrame:AddMessage(MultiBot.L("pvp.stats.error_not_in_raid"), 1, 0.2, 0.2, 1)
            return
        end

        if requestBridgePvpStats(nil) then
            return
        end

        SendChatMessage("pvp stats", "RAID")
        showPvpFrame()
    end
end

local function createAllBotsCommands(controlFrame)
    local mainButton = controlFrame.addButton("AllBotsCommands", 0, 90, "Temp", MultiBot.L("tips.allbots.commandsallbots"))
    mainButton.doLeft = function()
        local menu = controlFrame.frames and controlFrame.frames["AllBotsCommandsMenu"]
        if not menu then
            return
        end

        if menu:IsShown() then
            menu:Hide()
        else
            menu:Show()
        end
    end

    local menuFrame = controlFrame.addFrame("AllBotsCommandsMenu", -30, 92, 32, 64)
    menuFrame:Hide()

    menuFrame.addButton("MaintenanceAllBots", 0, 34, "achievement_halloween_smiley_01", MultiBot.L("tips.allbots.maintenanceallbots"))
        .doLeft = function()
            if MultiBot.MaintenanceAllBots then
                MultiBot.MaintenanceAllBots()
            end
        end

    menuFrame.addButton("SellAllBotsGrey", 0, 0, "inv_misc_coin_18", MultiBot.L("tips.allbots.sellallvendor"))
        .doLeft = function()
            if MultiBot.SellAllBots then
                MultiBot.SellAllBots("s *")
            end
        end
end

local function createInviteControls(controlFrame)
    local inviteButton = controlFrame.addButton("Invite", 0, 120, "Interface\\AddOns\\MultiBot\\Icons\\invite.blp", MultiBot.L("tips.units.invite")).setEnable()

    inviteButton.doRight = function()
        if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
            return
        end
        MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons[UNITS_BUTTON_NAME].roster
        MultiBot.timer.invite.needs = #MultiBot.index[MultiBot.timer.invite.roster]
        MultiBot.timer.invite.index = 1
        MultiBot.auto.invite = true
        SendChatMessage(MultiBot.L("info.starting"), "SAY")
    end

    inviteButton.doLeft = function(button)
        if button.state then
            MultiBot.ShowHideSwitch(button.parent.frames["Invite"])
        end
    end

    local inviteFrame = controlFrame.addFrame("Invite", -30, 122)
    inviteFrame:Hide()
    inviteFrame._mbSkipAutoCollapse = true

    for _, definition in ipairs(INVITE_BUTTONS) do
        inviteFrame.addButton(definition.name, definition.x, 0, definition.icon, MultiBot.L(definition.tip))
            .doLeft = function(button)
                if MultiBot.auto.invite then
                    SendChatMessage(MultiBot.L("info.wait"), "SAY")
                    return
                end

                local raidCount = GetNumRaidMembers()
                local partyCount = GetNumPartyMembers()
                MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons[UNITS_BUTTON_NAME].roster
                MultiBot.timer.invite.needs = definition.needs(raidCount, partyCount)
                MultiBot.timer.invite.index = 1
                MultiBot.auto.invite = true
                button.parent:Hide()
                SendChatMessage(MultiBot.L("info.starting"), "SAY")
            end
    end
end

local function createBrowseButton(controlFrame)
    controlFrame.addButton("Browse", 0, 180, "Interface\\AddOns\\MultiBot\\Icons\\browse.blp", MultiBot.L("tips.units.browse"))
        .doLeft = function()
            local unitsButton = MultiBot.frames.MultiBar.buttons[UNITS_BUTTON_NAME]
            local unitsFrame = unitsButton.parent.frames[UNITS_FRAME_NAME]
            local sourceTable = getUnitsSourceTable(unitsButton)
            local total = sourceTable and #sourceTable or 0
            if total == 0 then
                return
            end

            local fromIndex = (unitsButton.to or UNITS_PAGE_SIZE) + 1
            local toIndex = fromIndex + UNITS_PAGE_SIZE - 1
            if fromIndex > total then
                fromIndex = 1
                toIndex = math.min(UNITS_PAGE_SIZE, total)
            end
            if toIndex > total then
                toIndex = total
            end

            local display = getDisplayableUnits(unitsFrame, sourceTable)
            hideTrackedVisibleUnits(unitsButton, unitsFrame)
            layoutVisibleUnits(unitsButton, unitsFrame, display, fromIndex, math.min(toIndex, #display))
        end
end

function MultiBot.InitializeUnitsRootUI(tMultiBar)
    if not tMultiBar or not tMultiBar.addButton or not tMultiBar.addFrame then
        return nil
    end

    local unitsButton = tMultiBar.addButton(UNITS_BUTTON_NAME, -38, 0, "inv_scroll_04", MultiBot.L("tips.units.master"))
    unitsButton.roster = "players"
    unitsButton.filter = "none"
    unitsButton.doRight = function(button)
        onUnitsButtonRightClick(button)
    end
    unitsButton.doLeft = function(button, roster, filter)
        refreshUnitsDisplay(button, roster, filter)
    end

    local unitsFrame = tMultiBar.addFrame(UNITS_FRAME_NAME, UNITS_FRAME_X, UNITS_FRAME_Y)
    unitsFrame:Hide()

    local allianceFrame = createFactionBanner(unitsFrame)
    local controlFrame = unitsFrame.addFrame("Control", -2, 0)
    controlFrame:Show()

    MultiBot.BuildFilterUI(controlFrame)
    MultiBot.BuildRosterUI(controlFrame)

    createPvpStatsControls(controlFrame)
    createAllBotsCommands(controlFrame)
    createInviteControls(controlFrame)
    createBrowseButton(controlFrame)
    if MultiBot.BuildRTIControlUI then
        MultiBot.BuildRTIControlUI(controlFrame)
    end

    if MultiBot.UpdateFavoritesIndex then
        MultiBot.UpdateFavoritesIndex()
    elseif MultiBot.EnsureFavoriteButtons then
        MultiBot.EnsureFavoriteButtons()
    end

    if MultiBot.bridge and MultiBot.bridge.roster and #MultiBot.bridge.roster > 0 then
        if MultiBot.SyncBridgeRosterToPlayers then
            MultiBot.SyncBridgeRosterToPlayers(MultiBot.bridge.roster)
        end
        if MultiBot.ApplyAllBridgeStates then
            MultiBot.ApplyAllBridgeStates()
        end
    end

    return {
        mainButton = unitsButton,
        frame = unitsFrame,
        allianceFrame = allianceFrame,
        controlFrame = controlFrame,
    }
end
