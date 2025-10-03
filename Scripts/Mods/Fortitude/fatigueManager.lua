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

--- Normalizes a value (0–1) with a tolerance zone and exponential growth.
--- @param ratio number Value between 0 and 1 (e.g. current / max)
--- @param exponent number Controls how steep the growth is (2 = quadratic, 3 = cubic)
--- @param maxFactor number Maximum multiplier that can be reached
--- @param tolerance number Fraction (0–1) below which the factor stays at 1.0
--- @return number factor
local function normalizeFactor(ratio, exponent, maxFactor, tolerance)
    if ratio >= (1 - tolerance) then
        return 1.0
    end

    local deficit = (1 - ratio - tolerance) / (1 - tolerance)
    if deficit < 0 then deficit = 0 end
    if deficit > 1 then deficit = 1 end

    local scaled = deficit ^ exponent

    return 1.0 + scaled * (maxFactor - 1.0)
end

local function getSpeedFactor(speed)
    if speed < 2.0 then
        return 1.0
    elseif speed < 5.0 then
        return 1.25
    else
        return 1.5
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

local function getHealthFactor()
    local maxHealth = 100
    local currentHealth = KCDUtils.Player:GetHealth() or maxHealth
    if maxHealth <= 0 then return 1.0 end

    local ratio = currentHealth / maxHealth
    return normalizeFactor(ratio, 2.0, 2.0, 0.2)
end

local function getStaminaFactor()
    local maxStamina = player.soul:GetDerivedStat("mst") or 100
    local currentStamina = player.soul:GetState("stamina") or maxStamina
    if maxStamina <= 0 then return 1.0 end

    local ratio = currentStamina / maxStamina
    return normalizeFactor(ratio, 2.5, 2.5, 0.2)
end

local function getHungerFactor()
    local hunger = KCDUtils.Player:GetHunger() or 100

    if hunger == 100 then
        return 1.0
    end

    if hunger < 100 then
        local ratio = hunger / 100.0
        return normalizeFactor(ratio, 2.0, 2.0, 0.2)

    else
        local over = math.min(hunger, 150) - 100
        local ratio = 1.0 - (over / 50.0)
        return normalizeFactor(ratio, 2.0, 2.0, 0.2)
    end
end

local function getExhaustionFactor()
    local exhaust = KCDUtils.Player:GetExhaust() or 100
    local ratio = exhaust / 100.0
    return normalizeFactor(ratio, 2.0, 2.0, 0.2)
end

local function getDayTimeFactor()
    local hour = KCDUtils.Calendar.GetWorldHourOfDay()

    if hour >= 22 or hour < 5 then
        return 1.3
    -- elseif hour >= 12 and hour < 16 then
    --     return 1.15
    else
        return 1.0
    end
end

local function getWeatherFactor()
    local factor = 1.0

    local rain = 0
    if EnvironmentModule and type(EnvironmentModule.GetRainIntensity) == "function" then
        local success, r = pcall(EnvironmentModule.GetRainIntensity)
        if success and type(r) == "number" then
            rain = r
        end
    end

    local wind = 0
    if System and type(System.GetWind) == "function" then
        local ok, w = pcall(System.GetWind)
        if ok and type(w) == "table" and w.x and w.y and w.z then
            wind = math.sqrt(w.x^2 + w.y^2 + w.z^2)
        end
    end

    local rainScale = 0.35
    local windScale = 0.05
    factor = 1.0 + (rain * rainScale) + (wind * windScale)

    factor = math.min(factor, 2.0)
    factor = math.max(factor, 1.0)

    manager.lastWeatherFactor = (manager.lastWeatherFactor or 1.0) * 0.9 + factor * 0.1
    return manager.lastWeatherFactor
end

local function getWeightFactor()
    local config = ensureConfig()

    local rcw = player.soul:GetDerivedStat("rcw") or 0
    if rcw < 0.3 then
        return config.carriedWeight_light
    elseif rcw < 0.7 then
        return config.carriedWeight_medium
    elseif rcw < 1.0 then
        return config.carriedWeight_heavy
    else
        local overloadBase = config.carriedWeight_overload
        local extra = (rcw - 1.0) * 0.5
        return overloadBase + extra
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

local function scalePreLimit(dKm, config)
    return 1.0 + config.fatigue_baseSlope * dKm
end

local function scaleAll(dKm, config)
    if dKm <= 14.0 then
        return 1.0 + config.fatigue_baseSlope * dKm
    else
        local d = dKm - 14.0
        local s14 = 1.0 + config.fatigue_baseSlope * 14.0
        return s14
             + config.fatigue_extraSlope * d
             + config.fatigue_curveFactor * d * d
    end
end

local function getDistanceContribution(deltaMeters, deltaSeconds)
    local config = ensureConfig()
    local baseRatePerMeter = config.fatigue_limitTarget / (14000.0 * scalePreLimit(14.0, config))

    local d0 = config.distance_day
    local d1 = config.distance_day + (deltaMeters / 1000.0)
    local scale = 0.5 * (scaleAll(d0, config) + scaleAll(d1, config))

    local speed = (deltaSeconds > 0) and (deltaMeters / deltaSeconds) or 0
    local speedFactor = getSpeedFactor(speed)

    return deltaMeters * baseRatePerMeter * scale * speedFactor
end

local function addPlayerFatigue()
    local config = ensureConfig()
    local distanceContribution = getDistanceContribution(config.distance_delta, 1.0)
    local combatFactor   = getCombatFactor()
    local locationFactor = getLocationFactor()
    local dayTimeFactor  = getDayTimeFactor()
    local weatherFactor  = getWeatherFactor()
    local mountedFactor  = getMountedFactor()
    local weightFactor   = getWeightFactor()
    local armorFactor    = getArmorFactor()
    local healthFactor   = getHealthFactor()
    local staminaFactor  = getStaminaFactor()
    local hungerFactor   = getHungerFactor()
    local exhaustFactor  = getExhaustionFactor()

    local added = distanceContribution
                * combatFactor
                * locationFactor
                * dayTimeFactor
                * weatherFactor
                * mountedFactor
                * weightFactor
                * armorFactor
                * healthFactor
                * staminaFactor
                * hungerFactor
                * exhaustFactor

    config.player_fatigue = config.player_fatigue + added

    System.ClearConsole()
    mod.Logger:Info(string.format("Player Fatigue calculation:"))
    mod.Logger:Info(string.format("  deltaDistance     = %.2f", config.distance_delta))
    mod.Logger:Info(string.format("  baseContribution = %.4f", distanceContribution))
    mod.Logger:Info(string.format("  combatFactor     = %.2f", combatFactor))
    mod.Logger:Info(string.format("  locationFactor   = %.2f", locationFactor))
    mod.Logger:Info(string.format("  dayTimeFactor    = %.2f", dayTimeFactor))
    mod.Logger:Info(string.format("  weatherFactor    = %.2f", weatherFactor))
    mod.Logger:Info(string.format("  mountedFactor    = %.2f", mountedFactor))
    mod.Logger:Info(string.format("  weightFactor     = %.2f", weightFactor))
    mod.Logger:Info(string.format("  armorFactor      = %.2f", armorFactor))
    mod.Logger:Info(string.format("  healthFactor     = %.2f", healthFactor))
    mod.Logger:Info(string.format("  staminaFactor    = %.2f", staminaFactor))
    mod.Logger:Info(string.format("  hungerFactor     = %.2f", hungerFactor))
    mod.Logger:Info(string.format("  exhaustFactor    = %.2f", exhaustFactor))
    mod.Logger:Info(string.format("  --> addedFatigue = %.2f", added))
    mod.Logger:Info(string.format("  totalFatigue     = %.2f", config.player_fatigue))
end

local function addHorseFatigue()
    local config = ensureConfig()
    if manager.isMounted then
        config.horse_fatigue = config.horse_fatigue + (config.distance_delta * config.horse_fatiguePerMeter)
    end
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

    if fatigueLastDay >= cfg.fatigueThreshold_firstOverExtend
       and fatigueLastDay < cfg.fatigueThreshold_secondOverExtend then
        local chance = math.min(20 + hoursSlept * 5, 80)
        if randomChance(chance) then
            added = added + 1
        end

    elseif fatigueLastDay >= cfg.fatigueThreshold_secondOverExtend
           and fatigueLastDay < cfg.fatigueThreshold_thirdOverExtend then
        added = added + 1

    elseif fatigueLastDay >= cfg.fatigueThreshold_thirdOverExtend
           and fatigueLastDay < cfg.fatigueThreshold_overkill then
        added = added + 1
        local chance = math.min(30 + hoursSlept * 10, 90)
        if randomChance(chance) then
            added = added + 1
        end

    elseif fatigueLastDay >= cfg.fatigueThreshold_overkill then
        added = added + 2
    end

    return added
end

local function decreaseExhaustion(fatigueLastDay)
    local cfg = ensureConfig()
    local removed = 0

    local baseChance = 10
    local scale = math.max(0, (cfg.fatigueThreshold_buffEnd - fatigueLastDay))
    local chance = math.min(baseChance + scale * 2, 90)

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

function manager.AddActivity(activity)
end

function manager:RefreshFatigue(hoursSlept)
    local config = ensureConfig()

    local fatigueLastDay = config.player_fatigue
    local recovered = calcRecovery(hoursSlept, config)
    config.player_fatigue = math.max(0, config.player_fatigue - recovered)

    local change = handleExhaustion(hoursSlept, fatigueLastDay)
    config.player_exhaustion = math.min(6, math.max(0, config.player_exhaustion + change))

    mod.BuffManager.HandleExhaustionBuff()

    config.distance_day = 0

    mod.Logger:Info(string.format(
        "Slept %.2f hours → Fatigue before=%.2f, recovered=%.2f, after=%.2f",
        hoursSlept, fatigueLastDay, recovered, config.player_fatigue
    ))
end

function manager.UpdateFatigue()
    local config = ensureConfig()
    local delta = config.distance_delta or 0

    mod.Logger:Info(string.format("Start Updating | delta=%.5f", delta))

    if delta > 0 then
        addHorseFatigue()
        addPlayerFatigue()
    end

    mod.BuffManager.HandleFatigueBuff()

    config.distance_delta = 0

    Script.SetTimer(1000, Fortitude.FatigueManager.UpdateFatigue)
end

Fortitude.FatigueManager = manager