--- @type KCDUtils*mod
local mod = Fortitude
--- @class FatigueManager
local manager = {
    isMounted  = false,
    isOutdoor  = true,
    isFighting = false,
    isNight    = false,
    isCarryingCorpse = false,
    isSitting = false,
    isResting = false,

    restBudgetRemaining = 0,
    lastHourOfDay = nil,
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

local function updateRestBudget()
  local cfg = ensureConfig(); if not cfg then return end
  local hour = KCDUtils.Calendar.GetWorldHourOfDay() or 0

  if manager.lastHourOfDay == nil then
    manager.lastHourOfDay = hour
    if manager.restBudgetRemaining == 0 then
      manager.restBudgetRemaining = cfg.resting.maxRegenFromRest or 0
    end
    return
  end

  -- wrap über mitternacht -> neuer tag
  if hour < manager.lastHourOfDay then
    manager.restBudgetRemaining = cfg.resting.maxRegenFromRest or 0
  end

  manager.lastHourOfDay = hour
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

local function getCarryingCorpseFactor()
    if manager.isCarryingCorpse == true then
        return 100
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
        return config.carryWeight.light
    elseif rcw < 0.7 then
        return config.carryWeight.medium
    elseif rcw < 1.0 then
        return config.carryWeight.heavy
    else
        local overloadBase = config.carryWeight.overload
        local extra = (rcw - 1.0) * 0.5
        return overloadBase + extra
    end
end

local function getArmorFactor()
    local config = ensureConfig()

    local armorWeight = player.soul:GetDerivedStat("aco") or 0
    if armorWeight < 30 then
        return config.armor.weight.light
    elseif armorWeight < 60 then
        return config.armor.weight.medium
    else
        return config.armor.weight.heavy
    end
end

local function getMountedFactor(actor)
    if actor == "player" then
        if manager.isMounted then
            return 0.4
        else
            return 1
        end
    else
        if manager.isMounted then
            return 1.5
        else
            return 0
        end
    end
end

local function distScale(dKm)
  local normalized = math.min(dKm / 14.0, 4.0)
  local growth = 1.0 - math.exp(-normalized)
  return 1.0 + (growth * 0.5)
end

local function fatigueScale(fatigue, baseLimit)
  if fatigue <= (baseLimit or 100) then return 1.0 end
  local over = fatigue - baseLimit
  return 1.0 + ((over / 10.0) ^ 1.5) * 0.05
end

local function scalePreLimit(dKm, config)
  return 1.0 + (config.fatigue.baseSlope * dKm)
end

local function getDistanceContribution(deltaMeters, deltaSeconds)
  local config = ensureConfig()
  local travel = config.travel
  local baseLimit = config.fatigue.limitTarget or 100

  local d0 = travel.distanceDay
  local d1 = travel.distanceDay + (deltaMeters / 1000.0)

  local ds0 = distScale(d0)
  local ds1 = distScale(d1)
  local distScaleAvg = 0.5 * (ds0 + ds1)

  local fs = fatigueScale(config.player.fatigue, baseLimit)

  local fatigueGainMult = 5.0
  local baseRatePerMeter = (1.0 / (14000.0 * distScale(14.0))) * fatigueGainMult

  local speed = (deltaSeconds > 0) and (deltaMeters / deltaSeconds) or 0
  local speedFactor = getSpeedFactor(speed)

  return deltaMeters * baseRatePerMeter * distScaleAvg * fs * speedFactor
end

local function addPlayerFatigue()
  local config = ensureConfig()
  local fatigue = config.player.fatigue
  local fatigueCfg = config.fatigue

  if manager.isSitting or manager.isResting then
    updateRestBudget()

    local regenRate    = config.resting.regenRateSitting
    local passiveRate  = config.resting.regenRateStanding
    local dt           = 1.0 / config.player.refreshRate

    local baseRate = manager.isSitting and regenRate or passiveRate

    local dayTimeFactor = getDayTimeFactor() < 1.1 and 1.15 or 1.0
    local hungerFactor  = 1.0 / getHungerFactor()
    local weatherFactor = 1.0 / getWeatherFactor()

    local recovered = baseRate * dt * dayTimeFactor * hungerFactor * weatherFactor

    local allowed = math.min(recovered, manager.restBudgetRemaining or 0, fatigue)
    if allowed > 0 then
      manager.restBudgetRemaining = math.max(0, (manager.restBudgetRemaining or 0) - allowed)
      config.player.fatigue = math.max(0, fatigue - allowed)
    end
    return
  end

  local distanceContribution = getDistanceContribution(config.travel.distanceDelta, 1.0)
  if distanceContribution <= 0 then return end

  local added = distanceContribution
      * getCombatFactor()
      * getCarryingCorpseFactor()
      * getLocationFactor()
      * getDayTimeFactor()
      * getWeatherFactor()
      * getMountedFactor("player")
      * getWeightFactor()
      * getArmorFactor()
      * getHealthFactor()
      * getStaminaFactor()
      * getHungerFactor()
      * getExhaustionFactor()

  local newValue = fatigue + added
  config.player.fatigue = newValue
  mod.SkillManager.AddXPFromFatigue(added)
end

local function addHorseFatigue()
    local config = ensureConfig()
    local distanceContribution = getDistanceContribution(config.travel.distanceDelta, 1.0)
    local combatFactor   = getCombatFactor()
    local dayTimeFactor  = getDayTimeFactor()
    local weatherFactor  = getWeatherFactor()
    local mountedFactor  = getMountedFactor("horse")
    local weightFactor   = getWeightFactor()
    local armorFactor    = getArmorFactor()
    local healthFactor   = getHealthFactor()
    local staminaFactor  = getStaminaFactor()

    local added = distanceContribution
                * combatFactor
                * dayTimeFactor
                * weatherFactor
                * mountedFactor
                * weightFactor
                * armorFactor
                * healthFactor
                * staminaFactor

    local newValue = math.min(config.horse.fatigue + added, config.fatigue.limitTarget)
    config.horse.fatigue = newValue
end

local function checkFatigueThreshold()
    local config = ensureConfig()

    if config.player.fatigue > config.fatigue.thresholds.firstOverExtend then
        player.soul:DealDamage(0, 0, nil, false, nil)
    end
end

local function randomChance(p)
    return math.random(0, 100) <= p
end

local function increaseExhaustion(hoursSlept, fatigueLastDay)
    local cfg = ensureConfig()
    local added = 0

    if fatigueLastDay >= cfg.fatigue.thresholds.firstOverExtend
       and fatigueLastDay < cfg.fatigue.thresholds.secondOverExtend then
        local chance = math.min(20 + hoursSlept * 5, 80)
        if randomChance(chance) then
            added = added + 1
        end

    elseif fatigueLastDay >= cfg.fatigue.thresholds.secondOverExtend
           and fatigueLastDay < cfg.fatigue.thresholds.thirdOverExtend then
        added = added + 1

    elseif fatigueLastDay >= cfg.fatigue.thresholds.thirdOverExtend
           and fatigueLastDay < cfg.fatigue.thresholds.overkill then
        added = added + 1
        local chance = math.min(30 + hoursSlept * 10, 90)
        if randomChance(chance) then
            added = added + 1
        end

    elseif fatigueLastDay >= cfg.fatigue.thresholds.overkill then
        added = added + 2
    end

    return added
end

local function decreaseExhaustion(fatigueLastDay)
    local cfg = ensureConfig()
    local removed = 0

    local baseChance = 10
    local scale = math.max(0, (cfg.fatigue.thresholds.buffEnd - fatigueLastDay))
    local chance = math.min(baseChance + scale * 2, 90)

    if randomChance(chance) then
        removed = 1
    end

    return removed
end

local function handleExhaustion(hoursSlept, fatigueLastDay)
    local config = ensureConfig()
    local delta = 0

    if fatigueLastDay <= config.fatigue.thresholds.buffEnd and hoursSlept >= 6 then
        delta = -decreaseExhaustion(fatigueLastDay)
    elseif fatigueLastDay > config.fatigue.thresholds.bufferZone then
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
    local cfg = Fortitude.Config; if not cfg or not cfg.activities then return end
    local amount = tonumber(cfg.activities[activity] or 0) or 0
    if amount <= 0 then
        Fortitude.Logger:Info(("[Fatigue] No amount configured for activity '%s'"):format(tostring(activity)))
        return
    end

    local before = cfg.player.fatigue or 0
    cfg.player.fatigue = before + amount

    Fortitude.Logger:Info(string.format("[Fatigue] +%g from %s (%.2f → %.2f)",
        amount, activity, before, cfg.player.fatigue))

    if Fortitude.SkillManager and Fortitude.SkillManager.AddXPFromFatigue then
        Fortitude.SkillManager.AddXPFromFatigue(amount)
    end
end

function manager:RefreshFatigue(hoursSlept)
    local cfg = ensureConfig()
    if not cfg then return end

    local _, bedFactor = Fortitude.DetectBedQuality()
    bedFactor = bedFactor or 1.0

    local fatigueLastDay = cfg.player.fatigue
    local recovered = calcRecovery(hoursSlept, cfg) * bedFactor
    cfg.player.fatigue = math.max(0, cfg.player.fatigue - recovered)

    local change = handleExhaustion(hoursSlept, fatigueLastDay)
    cfg.player.exhaustion = math.min(6, math.max(0, cfg.player.exhaustion + change))

    Script.SetTimer(500, function()
        Fortitude.BuffManager.HandleExhaustionBuff()
    end)

    cfg.travel.distanceDay = 0
end

function manager.UpdateFatigue()
    local config = ensureConfig()
    -- local delta = config.travel.distanceDelta or 0

    -- if delta > 0 then
        addHorseFatigue()
        addPlayerFatigue()
    -- end

    mod.BuffManager.HandleFatigueBuff()

    config.travel.distanceDelta = 0

    Script.SetTimer(1000, Fortitude.FatigueManager.UpdateFatigue)
end

Fortitude.FatigueManager = manager