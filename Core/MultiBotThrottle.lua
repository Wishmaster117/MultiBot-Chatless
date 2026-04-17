-- MultiBotThrottle.lua
-- print("MultiBotThrottle.lua loaded")
MultiBot = MultiBot or {}

-- pack/unpack avec longueur n (pour gérer les nil au milieu)
local function pack(...)
  return { n = select('#', ...), ... }
end

function MultiBot.Throttle_Init()
  if MultiBot._throttleInited then return end

  local function perfCount(counterName, delta)
    local debugApi = MultiBot and MultiBot.Debug
    if type(debugApi) ~= "table" or type(debugApi.IncrementCounter) ~= "function" or type(debugApi.IsPerfEnabled) ~= "function" or not debugApi.IsPerfEnabled() then
      return
    end

    debugApi.IncrementCounter(counterName, delta)
  end

  local function perfDuration(counterName, elapsed)
    local debugApi = MultiBot and MultiBot.Debug
    if type(debugApi) ~= "table" or type(debugApi.AddDuration) ~= "function" or type(debugApi.IsPerfEnabled) ~= "function" or not debugApi.IsPerfEnabled() then
      return
    end

    debugApi.AddDuration(counterName, elapsed)
  end

  local orig_SendChatMessage = SendChatMessage

  -- Read configured throttle values through centralized config helpers.
  local rate = (MultiBot.GetThrottleRate and MultiBot.GetThrottleRate()) or 5
  local burst = (MultiBot.GetThrottleBurst and MultiBot.GetThrottleBurst()) or 8

  local RATE_PER_SEC, BURST = rate, burst
  local tokens = BURST
  local queue = {}

  -- M11 ownership: keep this OnUpdate local.
  -- Reason: token-bucket anti-spam requires frame-level refill/flush behavior.
  -- Frame de vidage
  local f = CreateFrame("Frame")
  f:Show()
  f:SetScript("OnUpdate", function(_, dt)
    perfCount("throttle.onupdate.calls")
    perfDuration("throttle.onupdate.elapsed", tonumber(dt) or 0)
    tokens = math.min(BURST, tokens + RATE_PER_SEC * dt)
    while tokens >= 1 and #queue > 0 do
      local item = table.remove(queue, 1)
      -- IMPORTANT: passer la borne haute à unpack (Lua 5.1)
      orig_SendChatMessage(unpack(item.args, 1, item.args.n))
      perfCount("throttle.sent")
      tokens = tokens - 1

      -- Debug optionnel: ne log que les messages de test [MB_TEST]
      if item.args and type(item.args[1]) == "string" and string.find(item.args[1], "^%[MB_TEST%]") then
        if DEFAULT_CHAT_FRAME and GetTime then
          DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff88ff88[Throttle]|r %.2fs -> %s", GetTime(), item.args[1]))
        end
      end
    end
  end)

  -- Surcharge globale (enfile tous les envois)
  SendChatMessage = function(msg, chatType, language, target)
    queue[#queue+1] = { args = pack(msg, chatType, language, target) }
    perfCount("throttle.enqueued")
    perfCount("throttle.queue.size_total", #queue)
  end

  -- API interne pour MAJ live depuis les sliders
  MultiBot._ThrottleStats = function(newRate, newBurst)
    if type(newRate)  == "number" and newRate  > 0 then RATE_PER_SEC = newRate end
    if type(newBurst) == "number" and newBurst > 0 then BURST = newBurst; tokens = math.min(tokens, BURST) end
  end

  MultiBot._throttleInited = true
  MultiBot._throttleOrig   = orig_SendChatMessage
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(MultiBot.L("tips.sliders.throttleinstalled") .. " (%.0f msg/s, rafale %d)", RATE_PER_SEC, BURST))
  end
end
