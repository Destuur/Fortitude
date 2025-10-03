--- @type KCDUtils*mod
local mod = Fortitude
--- @class FatigueManager
local manager = {
    isMounted  = false,
    isOutdoor  = true,
    isFighting = false,
    isNight    = false,
}

--- @return ModConfig
local function ensureConfig()
    local config = Fortitude.Config
    if not config then
        mod.Logger:Error("Config not initialized!")
        return nil
    end
    return config
end

local function getDistanceFactor(distance)
    if distance < 3 then
        return 1
    elseif distance < 6 then
        return 1.2
    elseif distance < 8 then
        return 1.5
    else
        return 2
    end
end

local function getCombatFactor()
    if manager.isFighting == true then
        return 1.5
    else
        return 1
    end
end

local function getLocationFactor()
    if manager.isOutdoor == true then
        return 1.2
    else
        return 1
    end
end

local function getDayTimeFactor()
    return 1
end

local function getWeatherFactor()

    local factor = 1.0
    local lastWeatherFactor

    if not EnvironmentModule or type(EnvironmentModule.GetRainIntensity) ~= "function" then
        return factor
    end

    local success, rain = pcall(EnvironmentModule.GetRainIntensity)
    if not success or not rain then
        return factor
    end

    local wind = 0
    if type(System.GetWind) == "function" then
        local ok, w = pcall(System.GetWind)
        if ok and w then
            if w.x and w.y and w.z then
                wind = math.sqrt(w.x^2 + w.y^2 + w.z^2)
            end
        end
    end

    local rainScale = 0.35
    local windScale = 0.05
    factor = 1.0 + (rain * rainScale) + (wind * windScale)

    factor = math.min(factor, 2.0)
    factor = math.max(factor, 1.0)

    lastWeatherFactor = (lastWeatherFactor or 1.0) * 0.9 + factor * 0.1
    factor = lastWeatherFactor

    return factor
end

local function getWeightFactor()
    local config = ensureConfig()

    local relativeCarriedWeight = player.soul:GetDerivedStat("rcw") or 0
    if relativeCarriedWeight < 0.3 then
        return config.carriedWeight_light
    elseif relativeCarriedWeight < 0.7 then
        return config.carriedWeight_medium
    elseif relativeCarriedWeight < 1 then
        return config.carriedWeight_heavy
    else
        return config.carriedWeight_overload
    end
end

local function getArmorFactor()
    local config = ensureConfig()

    local armorWeight = player.soul:GetDerivedStat("aco") or 0
    if armorWeight < 30 then
        return config.armorWeight_light
    elseif armorWeight < 60 then
        return config.armorWeight_medium
    else
        return config.armorWeight_heavy
    end
end

local function getMountedFactor()
    if manager.isMounted then
        return 0.4
    else
        return 1
    end
end

local function addPlayerFatigue(distance)
    local config = ensureConfig()

    local distanceFactor = getDistanceFactor(distance)
    local combatFactor = getCombatFactor()
    local locationFactor = getLocationFactor()
    local dayTimeFactor = getDayTimeFactor()
    local weatherFactor = getWeatherFactor()
    local mountedFactor = getMountedFactor()
    local weightFactor = getWeightFactor()
    local armorFactor = getArmorFactor()

    local added = distance * distanceFactor * combatFactor * locationFactor *
                  dayTimeFactor * weatherFactor * mountedFactor * weightFactor * armorFactor

    config.player_fatigue = config.player_fatigue + added

    -- mod.Logger:Info(string.format("Player Fatigue +%.2f (total %.2f)", added, config.Fatigue.player))
    -- mod.Logger:Info(string.format("  Dist       = %.2f", distance))
    -- mod.Logger:Info(string.format("  distF      = %.2f", distanceFactor))
    -- mod.Logger:Info(string.format("  combatF    = %.2f", combatFactor))
    -- mod.Logger:Info(string.format("  locF       = %.2f", locationFactor))
    -- mod.Logger:Info(string.format("  dayF       = %.2f", dayTimeFactor))
    -- mod.Logger:Info(string.format("  weatherF   = %.2f", weatherFactor))
    -- mod.Logger:Info(string.format("  mountedF   = %.2f", mountedFactor))
    -- mod.Logger:Info(string.format("  weightF    = %.2f", weightFactor))
    -- mod.Logger:Info(string.format("  armorF     = %.2f", armorFactor))
end

local function addHorseFatigue(distance)
    local config = ensureConfig()
    if manager.isMounted == false then
        return
    end
    config.horse_fatigue = config.horse_fatigue + (distance * config.horse_fatiguePerMeter)
end

local function checkFatigueThreshold()
    local config = ensureConfig()

    if config.player_fatigue > config.fatigueThreshold_firstOverExtend then
        player.soul:DealDamage(0, 0, nil, false, nil)
    end
end

local function randomChance(p)
    return math.random(0, 100) <= p
end

local function increaseExhaustion(hoursSlept, fatigueLastDay)
    local cfg = ensureConfig()
    local added = 0

    -- First Overextend
    if fatigueLastDay >= cfg.fatigueThreshold_firstOverExtend
       and fatigueLastDay < cfg.fatigueThreshold_secondOverExtend then
        -- Chance abhängig von Stunden Schlaf
        -- je länger geschlafen, desto größer die Chance
        local chance = math.min(20 + hoursSlept * 5, 80) -- z.B. 20–80%
        if randomChance(chance) then
            added = added + 1
        end

    -- Second Overextend
    elseif fatigueLastDay >= cfg.fatigueThreshold_secondOverExtend
           and fatigueLastDay < cfg.fatigueThreshold_thirdOverExtend then
        added = added + 1

    -- Third Overextend
    elseif fatigueLastDay >= cfg.fatigueThreshold_thirdOverExtend
           and fatigueLastDay < cfg.fatigueThreshold_overkill then
        added = added + 1
        -- Bonus-Chance auf +1
        local chance = math.min(30 + hoursSlept * 10, 90) -- 30–90%
        if randomChance(chance) then
            added = added + 1
        end

    -- Overkill
    elseif fatigueLastDay >= cfg.fatigueThreshold_overkill then
        added = added + 2
    end

    return added
end

local function decreaseExhaustion(fatigueLastDay)
    local cfg = ensureConfig()
    local removed = 0

    -- Je niedriger fatigueLastDay, desto größer die Chance
    local baseChance = 10 -- Minimum 10%
    local scale = math.max(0, (cfg.fatigueThreshold_buffEnd - fatigueLastDay))
    local chance = math.min(baseChance + scale * 2, 90) -- bis max. 90%

    if randomChance(chance) then
        removed = 1
    end

    return removed
end

local function handleExhaustion(hoursSlept, fatigueLastDay)
    local config = ensureConfig()
    local delta = 0

    if fatigueLastDay <= config.fatigueThreshold_buffEnd and hoursSlept >= 6 then
        delta = -decreaseExhaustion(fatigueLastDay)
    elseif fatigueLastDay > config.fatigueThreshold_bufferZone then
        delta = increaseExhaustion(hoursSlept, fatigueLastDay)
    end

    if delta ~= 0 then
        Fortitude.Logger:Info(string.format(
            "[Exhaustion] hoursSlept=%.1f, fatigueLastDay=%.1f → delta=%d",
            hoursSlept, fatigueLastDay, delta
        ))
    end

    return delta
end

local function calcRecovery(hoursSlept, config)
    local scale = 100 / (8^2)
    local recovered = (hoursSlept ^ 2) * scale

    return math.min(recovered, 140)
end

function manager.AddDistance(distance)
    addHorseFatigue(distance)
    addPlayerFatigue(distance)

    -- checkFatigueThreshold()
end

function manager.AddActivity(activity)
end

function manager:RefreshFatigue(hoursSlept)
    local config = ensureConfig()

    local fatigueLastDay = config.player_fatigue
    local recovered = calcRecovery(hoursSlept, config)
    config.player_fatigue = math.max(0, config.player_fatigue - recovered)

    local change = handleExhaustion(hoursSlept, fatigueLastDay)
    config.player_exhaustion = math.min(6, math.max(0, config.player_exhaustion + change))

    mod.Logger:Info(string.format(
        "Slept %.2f hours → Fatigue before=%.2f, recovered=%.2f, after=%.2f",
        hoursSlept, fatigueLastDay, recovered, config.player_fatigue
    ))
end

Fortitude.FatigueManager = manager