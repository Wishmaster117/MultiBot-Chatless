if not MultiBot then return end

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

local sharedTimerAfter = MultiBot.TimerAfter or _G.TimerAfter

if type(sharedTimerAfter) ~= "function" then
    local function runProtectedCallback(callback)
        if type(callback) ~= "function" then
            return
        end

        local ok, err = pcall(callback)
        if not ok and MultiBot and type(MultiBot.dprint) == "function" then
            MultiBot.dprint("TimerAfter", err)
        end
    end

    sharedTimerAfter = function(delay, callback)
        perfCount("scheduler.timerafter.calls")
        if type(callback) ~= "function" then
            return nil
        end

        local waitTime = math.max(tonumber(delay) or 0, 0)
        perfDuration("scheduler.timerafter.delay_total", waitTime)

        if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
            perfCount("scheduler.timerafter.ctime")
            return C_Timer.After(waitTime, callback)
        end

        -- M11 ownership: keep this fallback OnUpdate local to the scheduler wrapper only.
        -- Reason: legacy compatibility when C_Timer.After is unavailable.
        perfCount("scheduler.timerafter.fallback")
        local timerFrame = CreateFrame("Frame")
        local elapsed = 0

        timerFrame:SetScript("OnUpdate", function(self, dt)
            perfCount("scheduler.fallback.onupdate.calls")
            perfDuration("scheduler.fallback.onupdate.elapsed", tonumber(dt) or 0)
            elapsed = elapsed + (tonumber(dt) or 0)
            if elapsed < waitTime then
                return
            end

            self:SetScript("OnUpdate", nil)
            runProtectedCallback(callback)
        end)

        return timerFrame
    end
end

MultiBot.TimerAfter = sharedTimerAfter
_G.TimerAfter = sharedTimerAfter

-- M11 scheduler contract:
-- TimerAfter/NextTick are the only delay APIs that should be used outside this file.
function MultiBot.NextTick(callback)
    perfCount("scheduler.nexttick.calls")
    if type(callback) ~= "function" then
        return nil
    end

    return sharedTimerAfter(0, callback)
end