if not MultiBot then return end

local function inventoryItemL(key, fallback)
    return MultiBot.L("info." .. key, fallback)
end

local function buildInventoryButtonKey(frame, itemName)
    return string.format("%s_%d", itemName or "Item", frame.index or 0)
end

local function buildInventoryItemLink(parts)
    return "|" .. parts[2] .. "|" .. parts[3] .. "|" .. parts[4] .. "|h|r"
end

local function splitInventoryItemPayload(itemInfo)
    local parts = MultiBot.doSplit(itemInfo or "", "|")
    local itemData = parts[3] and MultiBot.doSplit(parts[3], ":") or {}
    return parts, itemData
end

local function extractInventoryItemCount(parts)
    local amountInfo = parts and parts[6] or nil
    if type(amountInfo) ~= "string" or string.sub(amountInfo, 1, 2) ~= "rx" then
        return nil
    end

    local amountToken = MultiBot.doSplit(amountInfo, " ")[1]
    local amount = tonumber(string.sub(amountToken or "", 3))
    return amount and amount > 1 and amount or nil
end

local function resolveInventoryItemName(parts, itemName)
    if itemName ~= nil then
        return itemName
    end

    local rawLinkText = parts and parts[4] or nil
    if type(rawLinkText) ~= "string" or string.len(rawLinkText) < 4 then
        return "Item"
    end

    return string.sub(rawLinkText, 3, string.len(rawLinkText) - 1)
end

local function resolveInventoryItemLink(parts, itemLink)
    if itemLink ~= nil then
        return itemLink
    end

    return buildInventoryItemLink(parts)
end

local function resolveInventoryItemRarity(itemRare)
    if itemRare ~= nil then
        return itemRare
    end

    return 4
end

local function getInventoryItemPosition(frame)
    if frame and frame.getNextSlotPosition then
        return frame:getNextSlotPosition()
    end

    local index = (frame and frame.index) or 0
    local itemsPerRow = (frame and frame.itemsPerRow) or 8
    local spacingX = (frame and frame.spacingX) or 38
    local spacingY = (frame and frame.spacingY) or 37
    return (index % itemsPerRow) * spacingX, math.floor(index / itemsPerRow) * -spacingY
end

local function buildInventoryItemRecord(itemInfo)
    local parts, itemData = splitInventoryItemPayload(itemInfo)
    local itemId = itemData[2]
    if not itemId or itemId == "" then
        return nil
    end

    local itemIcon = GetItemIcon(itemId)
    local itemName, itemLink, itemRare, _, _, itemType, _, _, _, _, _, itemClassID = GetItemInfo(itemId)
    if (itemClassID == nil) and GetItemInfoInstant then
        local _, _, _, _, _, instantClassID = GetItemInfoInstant(tonumber(itemId) or itemId)
        itemClassID = instantClassID
    end

    return {
        id = itemId,
        icon = itemIcon,
        name = resolveInventoryItemName(parts, itemName),
        link = resolveInventoryItemLink(parts, itemLink),
        rare = resolveInventoryItemRarity(itemRare),
        classID = itemClassID,
        type = itemType,
        count = extractInventoryItemCount(parts),
        _serverCount = extractInventoryItemCount(parts) or 1,
        info = itemInfo,
        parts = parts,
    }
end

local function getInventoryItemActionState()
    local inventory = MultiBot.inventory or {}
    return inventory.action or "", inventory.name or ""
end

local function getNow()
    if GetTime then
        return GetTime()
    end

    return time and time() or 0
end

local function getInventoryPendingConsumeStore(botName, create)
    if not botName or botName == "" then
        return nil
    end

    local inventory = MultiBot.inventory
    if not inventory then
        if not create then
            return nil
        end

        MultiBot.inventory = {}
        inventory = MultiBot.inventory
    end

    if create and type(inventory.pendingConsumes) ~= "table" then
        inventory.pendingConsumes = {}
    end

    local root = inventory.pendingConsumes
    if type(root) ~= "table" then
        return nil
    end

    local botKey = string.lower(botName)
    if create and type(root[botKey]) ~= "table" then
        root[botKey] = {}
    end

    return root[botKey]
end

local function getInventoryConsumeKey(item)
    if not item then
        return nil
    end

    local key = item.id or item.name or item.link
    if key == nil or key == "" then
        return nil
    end

    return tostring(key)
end

local function getInventoryItemDisplayCount(item)
    local count = tonumber(item and item.count or 1) or 1
    if count < 1 then
        return 1
    end

    return count
end

local function registerInventoryPendingConsume(botName, item, amount)
    local key = getInventoryConsumeKey(item)
    local store = getInventoryPendingConsumeStore(botName, true)
    if not key or not store then
        return false
    end

    amount = tonumber(amount or 1) or 1
    if amount < 1 then
        amount = 1
    end

    local baseline = tonumber(item and item._serverCount or item and item.count or 1) or 1
    if baseline < 1 then
        baseline = 1
    end

    local pending = store[key]
    if type(pending) ~= "table" then
        pending = { amount = 0, baseline = baseline }
        store[key] = pending
    end

    pending.amount = (tonumber(pending.amount or 0) or 0) + amount
    pending.baseline = math.max(tonumber(pending.baseline or 0) or 0, baseline)
    pending.expiresAt = getNow() + 60
    return true
end

local function applyInventoryPendingConsume(botName, item)
    local key = getInventoryConsumeKey(item)
    local store = getInventoryPendingConsumeStore(botName, false)
    if not key or not store or type(store[key]) ~= "table" then
        return item
    end

    local pending = store[key]
    local pendingAmount = tonumber(pending.amount or 0) or 0
    if pendingAmount <= 0 or (pending.expiresAt and getNow() > pending.expiresAt) then
        store[key] = nil
        return item
    end

    local serverCount = getInventoryItemDisplayCount(item)
    item._serverCount = serverCount

    local expectedServerCount = math.max(0, (tonumber(pending.baseline or serverCount) or serverCount) - pendingAmount)
    if serverCount <= expectedServerCount then
        store[key] = nil
        return item
    end

    local displayCount = serverCount - pendingAmount
    if displayCount <= 0 then
        item._pendingConsumed = true
        return nil
    end

    item.count = displayCount > 1 and displayCount or nil
    item._pendingConsumeAmount = pendingAmount
    return item
end

local function optimisticallyConsumeInventoryButton(button)
    if not button or not button.item then
        return
    end

    local count = getInventoryItemDisplayCount(button.item)
    if count <= 1 then
        if button.Hide then
            button:Hide()
        end
        return
    end

    count = count - 1
    button.item.count = count > 1 and count or nil

    if button.setAmount then
        if count > 1 then
            button.setAmount(count)
        elseif button.amount and button.amount.Hide then
            button.amount:Hide()
        end
    end
end

local function requestInventoryRefresh(delay, botName)
    local targetBotName = botName or (MultiBot.inventory and MultiBot.inventory.name) or ""

    if targetBotName ~= "" and MultiBot.RequestInventoryRefresh and MultiBot.RequestInventoryRefresh(targetBotName, delay) then
        return
    end

    if MultiBot.RefreshInventory then
        MultiBot.RefreshInventory(delay)
    end
end

local function requestInventoryPostActionRefresh(botName, firstDelay, secondDelay)
    local targetBotName = botName or (MultiBot.inventory and MultiBot.inventory.name) or ""

    if targetBotName ~= "" and MultiBot.RequestInventoryPostActionRefresh
        and MultiBot.RequestInventoryPostActionRefresh(targetBotName, firstDelay or 0.45, secondDelay or 1.20) then
        return
    end

    requestInventoryRefresh(firstDelay or 0.45, targetBotName)
end

local runBridgeInventoryItemDestroy

local function buildInventoryDestroyRequest(button, botName)
    if not button or not button.item or not botName or botName == "" then
        return nil
    end

    local item = button.item
    local count = tonumber(item._serverCount or item.count or 1) or 1
    local request = {
        botName = botName,
        srcBag = tonumber(item.bag),
        srcSlot = tonumber(item.slot),
        srcItemId = tonumber(item.id or 0) or 0,
        srcCount = count,
        exactLocation = item.exactLocation == true,
        link = item.link,
        tip = tostring(button.tip or item.link or ""),
    }

    if request.srcCount < 1 or request.srcItemId <= 0 then
        return nil
    end

    return request
end

local function isInventoryItemHyperlink(value)
    return type(value) == "string"
        and string.sub(value, 1, 1) == "|"
        and string.find(value, "|Hitem:", 1, true) ~= nil
end

local function runLegacyInventoryItemDestroy(request)
    if MultiBot.allowLegacyChatFallback ~= true or type(request) ~= "table" then
        return false
    end

    if not request.botName or request.botName == "" or not request.tip or request.tip == "" then
        return false
    end

    if request.exactLocation == true and not isInventoryItemHyperlink(request.tip) then
        return false
    end

    SendChatMessage("destroy " .. request.tip, "WHISPER", nil, request.botName)
    requestInventoryPostActionRefresh(request.botName, 0.45, 1.20)
    return true
end

local function bindInventoryDestroyConfirm(button, botName)
    local request = buildInventoryDestroyRequest(button, botName)
    if not request then
        return false
    end

    if not StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] then
        StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] = {
            text = inventoryItemL("itemdestroyalert", "Are you sure you want to destroy this item?"),
            button1 = OKAY,
            button2 = CANCEL,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            OnAccept = function(_, data)
                local acceptedRequest = data and data.request or nil
                if not acceptedRequest then return end

                if runBridgeInventoryItemDestroy and runBridgeInventoryItemDestroy(acceptedRequest) then
                    return
                end

                runLegacyInventoryItemDestroy(acceptedRequest)
            end,
        }
    end

    StaticPopup_Show("MULTIBOT_CONFIRM_DESTROY", request.link, nil, {
        request = request,
    })
    return true
end

local function sendInventoryFeedback(key, fallback)
    SendChatMessage(inventoryItemL(key, fallback), "SAY")
end

local function addInventorySystemMessage(message)
    message = tostring(message or "")
    if message == "" then
        return
    end

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    elseif print then
        print(message)
    end
end

local function isInventoryProtectedKey(item)
    return MultiBot.isInside(item and item.info or "", "%f[%a][Kk]ey%f[%A]")
end

local function isInventoryProtectedHearthstone(item)
    return item and item.id == "6948"
end

local function isInventoryProtectedQuestItem(item)
    if not item then
        return false
    end

    if type(item.classID) == "number" then
        local questClassID = (type(LE_ITEM_CLASS_QUESTITEM) == "number") and LE_ITEM_CLASS_QUESTITEM or 12
        return item.classID == questClassID
    end

    return false
end

MultiBot.InventoryIsProtectedQuestItem = isInventoryProtectedQuestItem

MultiBot.InventoryIsProtectedSellItem = function(item)
    return isInventoryProtectedQuestItem(item)
        or isInventoryProtectedHearthstone(item)
        or isInventoryProtectedKey(item)
end


local function needsInventoryDestroyConfirmation(item)
    return isInventoryProtectedHearthstone(item)
        or isInventoryProtectedKey(item)
        or ((item and item.rare or 0) > 3)
end

local function sendInventoryItemCommand(command, button, botName, options)
    options = options or {}

    if not command or command == "" or not button or not botName or botName == "" then
        return false
    end

    if button.item and button.item.exactLocation == true and not isInventoryItemHyperlink(button.tip) then
        return false
    end

    SendChatMessage(command .. " " .. button.tip, "WHISPER", nil, botName)

    if options.hideButton and button.Hide then
        button:Hide()
    end

    if options.optimisticConsume then
        optimisticallyConsumeInventoryButton(button)
    end

    if options.postActionRefresh then
        requestInventoryPostActionRefresh(botName, options.refreshDelay, options.followupRefreshDelay)
    elseif options.refreshDelay ~= nil then
        requestInventoryRefresh(options.refreshDelay, botName)
    elseif options.refresh then
        requestInventoryRefresh(nil, botName)
    end

    if options.followupRefreshDelay ~= nil and not options.postActionRefresh then
        requestInventoryRefresh(options.followupRefreshDelay, botName)
    end

    return true
end

local function runBridgeInventoryItemAction(action, button, botName, options)
    options = options or {}
    if not action or action == "" or not button or not button.item or not botName or botName == "" then
        return false
    end

    local itemId = tonumber(button.item.id or 0) or 0
    if itemId <= 0 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemAction then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemAction(botName, action, itemId, options.count or 0)
    if not token then
        return false
    end

    return true
end

-- MB_ITEM_SELL_SINGLE_V1_HELPER_BEGIN
local function runBridgeInventoryItemSell(button, botName)
    if not button or not button.item or not botName or botName == "" then
        return false
    end

    local item = button.item
    if item.exactLocation ~= true then
        return false
    end

    local srcBag = tonumber(item.bag)
    local srcSlot = tonumber(item.slot)
    local itemId = tonumber(item.id or 0) or 0
    local count = tonumber(item._serverCount or item.count or 1) or 1
    if srcBag == nil or srcSlot == nil or itemId <= 0 or count < 1 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemSell then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemSell(
        botName, srcBag, srcSlot, itemId, count
    )
    return token and true or false
end
-- MB_ITEM_SELL_SINGLE_V1_HELPER_END

local function runBridgeInventoryItemTrade(button, botName)
    if not button or not button.item or not botName or botName == "" then
        return false
    end

    local item = button.item
    if item.exactLocation ~= true then
        return false
    end

    local srcBag = tonumber(item.bag)
    local srcSlot = tonumber(item.slot)
    local itemId = tonumber(item.id or 0) or 0
    local count = tonumber(item._serverCount or item.count or 1) or 1
    if srcBag == nil or srcSlot == nil or itemId <= 0 or count < 1 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemTrade then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemTrade(
        botName, srcBag, srcSlot, itemId, count
    )
    return token and true or false
end

local function runBridgeInventoryItemUse(button, botName)
    if not button or not button.item or not botName or botName == "" then
        return false
    end

    local item = button.item
    if item.exactLocation ~= true then
        return false
    end

    local srcBag = tonumber(item.bag)
    local srcSlot = tonumber(item.slot)
    local itemId = tonumber(item.id or 0) or 0
    local count = tonumber(item._serverCount or item.count or 1) or 1
    if srcBag == nil or srcSlot == nil or itemId <= 0 or count < 1 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemUse then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemUse(
        botName, srcBag, srcSlot, itemId, count
    )
    return token and true or false
end

local function runBridgeInventoryItemEquip(button, botName)
    if not button or not button.item or not botName or botName == "" then
        return false
    end

    local item = button.item
    if item.exactLocation ~= true then
        return false
    end

    local srcBag = tonumber(item.bag)
    local srcSlot = tonumber(item.slot)
    local itemId = tonumber(item.id or 0) or 0
    local count = tonumber(item._serverCount or item.count or 1) or 1
    if srcBag == nil or srcSlot == nil or itemId <= 0 or count < 1 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemEquip then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemEquip(botName, srcBag, srcSlot, itemId, count)
    return token and true or false
end

runBridgeInventoryItemDestroy = function(request)
    if type(request) ~= "table" or request.exactLocation ~= true then
        return false
    end

    local srcBag = tonumber(request.srcBag)
    local srcSlot = tonumber(request.srcSlot)
    local itemId = tonumber(request.srcItemId or 0) or 0
    local count = tonumber(request.srcCount or 0) or 0
    if srcBag == nil or srcSlot == nil or itemId <= 0 or count < 1 then
        return false
    end

    if not MultiBot.Comm or not MultiBot.Comm.RunInventoryItemDestroy then
        return false
    end

    local token = MultiBot.Comm.RunInventoryItemDestroy(
        request.botName, srcBag, srcSlot, itemId, count
    )
    return token and true or false
end

MultiBot.OnBridgeInventoryItemDestroyResult = function(botName, _, reason)
    if reason == "DISCONNECTED" then
        return
    end

    requestInventoryRefresh(0.15, botName)
end
MultiBot.OnBridgeInventoryItemTradeResult = function(_, status, reason)
    if reason == "DISCONNECTED" then
        return
    end

    if status ~= "OK" then
        addInventorySystemMessage(
            inventoryItemL("inventory.item_trade.failed", "The item could not be added to the trade.")
                .. " [" .. tostring(reason or "FAILED") .. "]"
        )
    end
end

local function handleInventoryItemClick(button)
    local item = button and button.item or nil
    local inventoryBotName = MultiBot.inventory and MultiBot.inventory.name or nil
    if item
        and MultiBot.TryProfessionRecipeTargetInventoryItem
        and MultiBot.TryProfessionRecipeTargetInventoryItem(inventoryBotName, item) then
        return
    end

    local action, botName = getInventoryItemActionState()
    if action == "" then
        sendInventoryFeedback("action", "Choose an action first")
        return
    end

    -- MB_ITEM_SELL_SINGLE_V1_ACTION_BEGIN
    if action == "s" then
        if isInventoryProtectedQuestItem(item) then
            sendInventoryFeedback("questitemsellalert", "I cannot sell quest items.")
            return
        end

        if isInventoryProtectedHearthstone(item) then
            sendInventoryFeedback("itemsellalert", "You cannot sell this item")
            return
        end

        if isInventoryProtectedKey(item) then
            sendInventoryFeedback("keydestroyalert", "I will not sell Keys.")
            return
        end

        local bridgeCapable = MultiBot.Comm
            and MultiBot.Comm.IsInventoryItemSellCapable
            and MultiBot.Comm.IsInventoryItemSellCapable()

        if bridgeCapable then
            if runBridgeInventoryItemSell(button, botName) then
                return
            end

            addInventorySystemMessage(inventoryItemL(
                "inventory.item_sell.send_failed",
                "The item-sale request could not be sent."
            ))
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            if not MultiBot.isTarget() then
                sendInventoryFeedback("inventoryvendortarget", "Target a vendor first")
                return
            end

            sendInventoryItemCommand(action, button, botName, {
                hideButton = true,
                refreshDelay = 0.3,
            })
        else
            addInventorySystemMessage(inventoryItemL(
                "inventory.item_sell.unavailable",
                "Item selling via the bridge is unavailable."
            ))
        end
        return
    end
    -- MB_ITEM_SELL_SINGLE_V1_ACTION_END

    if action == "e" then
        if runBridgeInventoryItemEquip(button, botName) then
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            sendInventoryItemCommand(action, button, botName)
        end
        return
    end

    if action == "give" then
        local bridgeCapable = MultiBot.Comm
            and MultiBot.Comm.IsInventoryItemTradeCapable
            and MultiBot.Comm.IsInventoryItemTradeCapable()

        if bridgeCapable then
            if runBridgeInventoryItemTrade(button, botName) then
                return
            end

            addInventorySystemMessage(inventoryItemL(
                "inventory.item_trade.send_failed",
                "The item-trade request could not be sent."
            ))
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            sendInventoryItemCommand(action, button, botName)
        else
            addInventorySystemMessage(inventoryItemL(
                "inventory.item_trade.unavailable",
                "Item trading via the bridge is unavailable."
            ))
        end
        return
    end

    if action == "bank" then
        if runBridgeInventoryItemAction("BANK_DEPOSIT", button, botName) then
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            sendInventoryItemCommand("bank", button, botName, {
                postActionRefresh = true,
                refreshDelay = 0.45,
                followupRefreshDelay = 1.20,
            })
        end
        return
    end

    if action == "gb" then
        if runBridgeInventoryItemAction("GBANK_DEPOSIT", button, botName) then
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            sendInventoryItemCommand("gb", button, botName, {
                postActionRefresh = true,
                refreshDelay = 0.45,
                followupRefreshDelay = 1.20,
            })
        end
        return
    end

    if action == "b" then
        if runBridgeInventoryItemAction("BUY_ITEM", button, botName, { count = 1 }) then
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            sendInventoryItemCommand("b", button, botName, {
                postActionRefresh = true,
                refreshDelay = 0.45,
                followupRefreshDelay = 1.20,
            })
        end
        return
    end

    if action == "u" then
        local bridgeCapable = MultiBot.Comm
            and MultiBot.Comm.IsInventoryItemUseCapable
            and MultiBot.Comm.IsInventoryItemUseCapable()

        if bridgeCapable then
            if runBridgeInventoryItemUse(button, botName) then
                return
            end

            addInventorySystemMessage(MultiBot.L(
                "inventory.item_use.send_failed",
                "The item-use request could not be sent."
            ))
            return
        end

        if MultiBot.allowLegacyChatFallback == true then
            registerInventoryPendingConsume(botName, item, 1)
            sendInventoryItemCommand(action, button, botName, {
                optimisticConsume = true,
                postActionRefresh = true,
                refreshDelay = 0.45,
                followupRefreshDelay = 1.20,
            })
        else
            addInventorySystemMessage(MultiBot.L(
                "inventory.item_use.unavailable",
                "Item use via the bridge is unavailable."
            ))
        end
        return
    end

    if action ~= "destroy" then
        return
    end

    if needsInventoryDestroyConfirmation(item) then
        bindInventoryDestroyConfirm(button, botName)
        return
    end

    local destroyRequest = buildInventoryDestroyRequest(button, botName)
    if not destroyRequest then
        return
    end

    if runBridgeInventoryItemDestroy(destroyRequest) then
        return
    end

    runLegacyInventoryItemDestroy(destroyRequest)
end

local function getInventoryItemActionLabel(action)
    action = tostring(action or "")
    return inventoryItemL("inventory.action." .. action, action)
end

local function getInventoryItemActionReason(reason)
    reason = tostring(reason or "")
    if reason == "" or reason == "OK" then
        return ""
    end

    local fallback = inventoryItemL(
        "inventory.item_action.reason.UNKNOWN",
        "The server returned an unknown item-action error."
    )
    return inventoryItemL("inventory.item_action.reason." .. reason, fallback)
end

-- MB_ITEM_SELL_SINGLE_V1_CALLBACK_BEGIN
local function getInventoryItemSellReason(reason)
    reason = tostring(reason or "")
    if reason == "" or reason == "OK" then
        return ""
    end

    local fallback = inventoryItemL(
        "inventory.item_sell.reason.UNKNOWN",
        "The server returned an unknown item-sale error."
    )
    return inventoryItemL("inventory.item_sell.reason." .. reason, fallback)
end

function MultiBot.OnBridgeInventoryItemSellResult(botName, result, reason)
    if reason == "DISCONNECTED" then
        return
    end

    if result == "OK" then
        requestInventoryRefresh(0.30, botName)
        return
    end

    addInventorySystemMessage(string.format(
        inventoryItemL("inventory.item_sell.err", "Failed to sell item: %s"),
        getInventoryItemSellReason(reason)
    ))

    if reason == "SOURCE_STALE" or reason == "BAD_RESPONSE" or reason == "RESPONSE_MISMATCH" or reason == "TIMEOUT" then
        requestInventoryRefresh(0.15, botName)
    end
end
-- MB_ITEM_SELL_SINGLE_V1_CALLBACK_END

local function getInventoryItemUseReason(reason)
    local code = tostring(reason or "UNKNOWN")
    local fallback = MultiBot.L("inventory.item_use.reason.UNKNOWN", "Unknown item-use error.")
    return MultiBot.L("inventory.item_use.reason." .. code, fallback)
end

function MultiBot.OnBridgeInventoryItemUseResult(botName, result, reason)
    if reason == "DISCONNECTED" then
        return
    end

    if result == "OK" then
        requestInventoryRefresh(0.45, botName)
        return
    end

    addInventorySystemMessage(string.format(
        MultiBot.L("inventory.item_use.err", "Use failed: %s"),
        getInventoryItemUseReason(reason)
    ))

    if reason == "SOURCE_STALE" or reason == "BAD_RESPONSE" or reason == "RESPONSE_MISMATCH" or reason == "TIMEOUT" then
        requestInventoryRefresh(0.15, botName)
    end
end

function MultiBot.OnBridgeInventoryItemActionResult(botName, action, itemId, result, reason, moved)
    local actionLabel = getInventoryItemActionLabel(action)
    local itemName = tostring(itemId or "")
    if GetItemInfo then
        itemName = GetItemInfo(tonumber(itemId or 0) or 0) or itemName
    end

    if result == "OK" then
        if action == "SELL_GREY" then
            addInventorySystemMessage(string.format(
                inventoryItemL("inventory.item_action.sell_grey.ok", "Grey item sale: %d item(s) sold."),
                tonumber(moved or 0) or 0
            ))
        elseif action == "SELL_VENDOR" then
            addInventorySystemMessage(string.format(
                inventoryItemL("inventory.item_action.sell_vendor.ok", "Vendor item sale: %d item(s) sold."),
                tonumber(moved or 0) or 0
            ))
        else
            addInventorySystemMessage(string.format(
                inventoryItemL("inventory.item_action.ok", "%s: %s x%d."),
                actionLabel,
                itemName,
                tonumber(moved or 0) or 0
            ))
        end

        requestInventoryPostActionRefresh(botName, 0.45, 1.20)
        if MultiBot.RefreshBotBank and (action == "BANK_DEPOSIT" or action == "BANK_WITHDRAW") then
            MultiBot.RefreshBotBank(botName, 0.65)
        end
        if (action == "GBANK_DEPOSIT" or action == "GBANK_WITHDRAW") and MultiBot.RefreshBotGuildBank then
            MultiBot.RefreshBotGuildBank(botName, 0.65)
        end
        if action == "BUY_ITEM" and MultiBot.professionRecipeFrame and MultiBot.professionRecipeFrame:IsShown()
            and MultiBot.professionRecipeFrame.botName == botName
            and MultiBot.professionRecipeFrame.skill
            and MultiBot.Comm and MultiBot.Comm.RequestProfessionRecipes then
            local skillId = tonumber(MultiBot.professionRecipeFrame.skill.skillId or 0) or 0
            if MultiBot.professionRecipeFrame.status then
                MultiBot.professionRecipeFrame.status:SetText(inventoryItemL("inventory.item_action.buy.ok", "Purchase completed."))
            end
            if skillId > 0 then
                if type(MultiBot.TimerAfter) == "function" then
                    MultiBot.TimerAfter(0.75, function()
                        MultiBot.Comm.RequestProfessionRecipes(botName, skillId)
                    end)
                else
                    MultiBot.Comm.RequestProfessionRecipes(botName, skillId)
                end
            end
        end
        return
    end

    local reasonText = getInventoryItemActionReason(reason)
    if (action == "BANK_WITHDRAW" or action == "GBANK_WITHDRAW")
        and MultiBot.bankFrame and MultiBot.bankFrame.IsShown and MultiBot.bankFrame:IsShown()
        and MultiBot.bankFrame.botName == botName then
        if MultiBot.bankFrame.status then
            MultiBot.bankFrame.status:SetText(reasonText ~= "" and reasonText or inventoryItemL("inventory.item_action.reason.UNKNOWN", "The server returned an unknown item-action error."))
        end
        if MultiBot.bankFrame.render then
            MultiBot.bankFrame:render()
        end
    end

    if action == "BUY_ITEM" and MultiBot.professionRecipeFrame and MultiBot.professionRecipeFrame:IsShown()
        and MultiBot.professionRecipeFrame.botName == botName
        and MultiBot.professionRecipeFrame.status then
        MultiBot.professionRecipeFrame.status:SetText(string.format(
            inventoryItemL("inventory.item_action.buy.err", "Purchase failed: %s"),
            reasonText ~= "" and reasonText or inventoryItemL("inventory.item_action.reason.UNKNOWN", "The server returned an unknown item-action error.")
        ))
    end

    if reasonText ~= "" then
        addInventorySystemMessage(string.format(
            inventoryItemL("inventory.item_action.err", "%s failed: %s"),
            actionLabel,
            reasonText
        ))
    else
        addInventorySystemMessage(string.format(
            inventoryItemL("inventory.item_action.failed", "%s failed."),
            actionLabel
        ))
    end
end

local function cloneInventoryExactItem(sourceItem, location)
    if type(location) ~= "table" then
        return nil
    end

    local numericItemId = tonumber(location.itemId or 0) or 0
    if numericItemId <= 0 then
        return nil
    end

    local itemId = tostring(numericItemId)
    local item = {}
    if type(sourceItem) == "table" then
        for key, value in pairs(sourceItem) do
            item[key] = value
        end
    end

    local itemName, itemLink, itemRare, _, _, itemType, _, _, _, _, _, itemClassID = GetItemInfo(numericItemId)
    if itemClassID == nil and GetItemInfoInstant then
        local _, _, _, _, _, instantClassID = GetItemInfoInstant(numericItemId)
        itemClassID = instantClassID
    end

    item.id = itemId
    item.icon = item.icon or GetItemIcon(numericItemId)
    item.name = item.name or itemName or ("Item " .. itemId)
    item.link = item.link or itemLink or item.name
    item.rare = item.rare or resolveInventoryItemRarity(itemRare)
    item.classID = item.classID or itemClassID
    item.type = item.type or itemType

    local count = math.max(1, tonumber(location.count or 1) or 1)
    item.count = count > 1 and count or nil
    item._serverCount = count
    item.bag = tonumber(location.bag or 0) or 0
    item.slot = tonumber(location.slot or 0) or 0
    item.soulbound = location.soulbound == true
    item.exactLocation = true

    return item
end

MultiBot.InventoryAddExactItem = function(frame, sourceItem, location, layoutIndex)
    if not frame or not frame.addButton then
        return nil
    end

    local item = cloneInventoryExactItem(sourceItem, location)
    if not item then
        return nil
    end

    local index = math.max(0, tonumber(layoutIndex or frame.index or 0) or 0)
    local itemX, itemY
    if frame.getSlotPosition then
        itemX, itemY = frame:getSlotPosition(index)
    else
        local previousIndex = frame.index
        frame.index = index
        itemX, itemY = getInventoryItemPosition(frame)
        frame.index = previousIndex
    end

    local buttonKey = string.format("Exact_%d_%d", item.bag, item.slot)
    local button = frame.addButton(buttonKey, itemX, itemY, item.icon, item.link, index)
    if not button then
        return nil
    end

    item.index = index
    item.x = itemX
    item.y = itemY
    button.item = item
    local inventory = MultiBot.inventory
    if inventory and inventory.configureExactItemButton then
        inventory:configureExactItemButton(button, item)
    end
    button.doLeft = handleInventoryItemClick

    if item.count then
        button.setAmount(item.count)
    end

    frame.index = math.max(frame.index or 0, index + 1)
    return button
end

MultiBot.InventoryAddItem = function(frame, itemInfo)
    if not frame then
        return nil
    end

    local item = buildInventoryItemRecord(itemInfo)
    if not item then
        return nil
    end

    local botName = frame and frame.getName and frame:getName() or (MultiBot.inventory and MultiBot.inventory.name) or ""
    item = applyInventoryPendingConsume(botName, item)
    if not item then
        return nil
    end

    local itemX, itemY = getInventoryItemPosition(frame)
    local itemIndex = frame.index or 0
    local buttonKey = buildInventoryButtonKey(frame, item.name)
    local button = frame.addButton(buttonKey, itemX, itemY, item.icon, item.link)

    item.index = itemIndex
    item.x = itemX
    item.y = itemY
    button.item = item

    button.doLeft = handleInventoryItemClick

    if item.count then
        button.setAmount(item.count)
    end

    frame.index = itemIndex + 1
    return button
end

MultiBot.addItem = MultiBot.InventoryAddItem