Fortitude.Activity = Fortitude.Activity or {
    active = false,
    kind = nil,
    token = nil,
    dialogShows = 0,
    lastPos = nil,
    timerId = nil,
    threshold = 2,
    interval = 1000,
    maxIdle = 600000,
    idleTime = 0,
    movementActive = false,
}

--- @return ModConfig
local function ensureConfig()
    local config = Fortitude.Config
    if not config then
        Fortitude.Logger:Error("Config not initialized!")
        return nil
    end
    return config
end

function Fortitude.Activity.StartMovementWatcher()
    local A = Fortitude.Activity
    if A.movementActive then return end

    local playerEnt = System.GetEntity(player.id)
    if not playerEnt then return end

    A.lastPos = playerEnt:GetWorldPos()
    A.movementActive = true
    A.idleTime = 0

    local function checkMovement()
        if not A.movementActive then return end
        local pos = playerEnt:GetWorldPos()
        if not pos or not A.lastPos then return end

        local dx = pos.x - A.lastPos.x
        local dy = pos.y - A.lastPos.y
        local dz = pos.z - A.lastPos.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

        if dist > A.threshold then
            Fortitude.Logger:Info("[Activity] Movement detected → ending crafting session")
            Fortitude.Activity.FinishCrafting(false)
            A.movementActive = false
            return
        end

        A.idleTime = A.idleTime + A.interval
        if A.idleTime >= A.maxIdle then
            Fortitude.Logger:Info("[Activity] Timeout reached → auto ending crafting session")
            Fortitude.Activity.FinishCrafting(false)
            A.movementActive = false
            return
        end

        A.lastPos = pos
        Script.SetTimer(A.interval, checkMovement)
    end

    Script.SetTimer(A.interval, checkMovement)
    Fortitude.Logger:Info("[Activity] MovementWatcher started")
end

function Fortitude.Activity.StopMovementWatcher()
    Fortitude.Activity.movementActive = false
end

function Fortitude.Activity.StartCrafting(kind)
    local A = Fortitude.Activity
    if A.active then
        Fortitude.Logger:Info(("[Activity] interrupt %s → %s"):format(tostring(A.kind), tostring(kind)))
    end

    local cfg = ensureConfig()
    if not cfg or not cfg.activities or not cfg.activities[kind] then return end

    A.active, A.kind, A.token = true, kind, {}
    A.dialogShows = 0

    local baseRatio = (cfg.time and cfg.time.base_ratio) or 15
    local factor = tonumber(cfg.activities[kind].time_factor) or 1
    local finalRatio = math.max(1, baseRatio * factor)
    Fortitude.StartSpeedup(finalRatio)
    Fortitude.Activity.StartMovementWatcher()

    local timeoutMs = (cfg.activities[kind].timeout or 180000)
    Fortitude.Logger:Info(("[Activity] %s started (timeout %ds, ratio %.2f)"):format(kind, timeoutMs / 1000, finalRatio))

    local token = A.token
    Script.SetTimer(timeoutMs, function()
        if Fortitude.Activity.active and Fortitude.Activity.token == token then
            Fortitude.Logger:Info(("[Activity] %s timed out → reset (no credit)"):format(kind))
            A.active, A.kind, A.token = false, nil, nil
            A.dialogShows = 0
            Fortitude.Activity.StopMovementWatcher()
            Fortitude.EndSpeedup()
        end
    end)
end

function Fortitude.Activity.FinishCrafting(success)
    local A = Fortitude.Activity
    if not A.active then return end
    local kind = A.kind
    A.active, A.kind, A.token = false, nil, nil
    A.dialogShows = 0

    if success then
        Fortitude.Logger:Info(("[Activity] %s finished → credit fatigue"):format(kind))
        if Fortitude.FatigueManager and Fortitude.FatigueManager.AddActivity then
            Fortitude.FatigueManager.AddActivity(kind)
        end
    else
        Fortitude.Logger:Info(("[Activity] %s canceled/aborted → no credit"):format(kind))
    end

    Fortitude.Activity.StopMovementWatcher()
    Fortitude.EndSpeedup()
end

function GatherHerb()
    if Fortitude.FatigueManager and Fortitude.FatigueManager.AddActivity then
        Fortitude.FatigueManager.AddActivity("herbGathering")
    end
end