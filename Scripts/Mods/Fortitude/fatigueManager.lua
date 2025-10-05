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

local function scalePreLimit(dKm, config)
    return 1.0 + config.fatigue.baseSlope * dKm
end

--- Berechnet eine sanft ansteigende, aber gedeckelte Skalierung
--- für Distanz-basiertes Fatigue-Wachstum.
--- Wachstum flacht ab, je näher man an limitTarget kommt.
--- @param dKm number Distanz (in km)
--- @param config ModConfig
--- @return number scaleFactor
local function scaleAll(dKm, config)
    -- Zielwert aus Konfiguration (z. B. 105.0 → 1.05)
    local maxFactor = config.fatigue.limitTarget / 100.0

    -- Normierte Distanz (0 = Start, 1 = 14 km)
    local normalized = math.min(dKm / 14.0, 4.0)

    -- Logarithmische Dämpfung: steigt schnell, flacht dann ab
    -- (1 - exp(-x)) ergibt eine weiche Sättigungskurve
    local growth = 1.0 - math.exp(-normalized)

    -- Basiswachstum + leichte Krümmung
    local factor = 1.0 + (maxFactor - 1.0) * growth

    -- Sicherheitshalber clampen
    return math.min(factor, maxFactor)
end

--- Liefert einen geglätteten Anstieg pro Meter,
--- unter Berücksichtigung von Sättigung bei höheren Distanzen.
--- @param deltaMeters number Neue zurückgelegte Strecke
--- @param deltaSeconds number Zeitintervall (Sekunden)
--- @return number contribution
local function getDistanceContribution(deltaMeters, deltaSeconds)
    local config = ensureConfig()
    local fatigue = config.fatigue
    local travel = config.travel

    local d0 = travel.distanceDay
    local d1 = travel.distanceDay + (deltaMeters / 1000.0)

    -- Durchschnittliche Skalierung zwischen Start und Ende
    local scale = 0.5 * (scaleAll(d0, config) + scaleAll(d1, config))

    -- Basisrate: entspricht linearer Steigung bis 14 km
    local baseRatePerMeter = 1.0 / (14000.0 * scaleAll(14.0, config))

    -- Geschwindigkeit einbeziehen
    local speed = (deltaSeconds > 0) and (deltaMeters / deltaSeconds) or 0
    local speedFactor = getSpeedFactor(speed)

    local contribution = deltaMeters * baseRatePerMeter * scale * speedFactor

    -- Begrenzen: Fatigue darf limitTarget nicht überschreiten
    local projectedFatigue = config.player.fatigue + contribution
    if projectedFatigue > fatigue.limitTarget then
        contribution = math.max(0, fatigue.limitTarget - config.player.fatigue)
    end

    return contribution
end

--- Addiert Fatigue für den Spieler mit stabiler Skalierung.
local function addPlayerFatigue()
    local config = ensureConfig()
    local distanceContribution = getDistanceContribution(config.travel.distanceDelta, 1.0)
    if distanceContribution <= 0 then return end

    local added = distanceContribution
        * getCombatFactor()
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

    local newValue = math.min(config.player.fatigue + added, config.fatigue.limitTarget)
    local delta = newValue - config.player.fatigue

    config.player.fatigue = newValue
    mod.SkillManager.AddXPFromFatigue(delta)
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
end

function manager:RefreshFatigue(hoursSlept)
    local cfg = ensureConfig()
    if not cfg then return end

    local _, bedFactor = Fortitude.DetectBedQuality()

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
    local delta = config.travel.distanceDelta or 0

    if delta > 0 then
        addHorseFatigue()
        addPlayerFatigue()
    end

    mod.BuffManager.HandleFatigueBuff()

    config.travel.distanceDelta = 0

    Script.SetTimer(1000, Fortitude.FatigueManager.UpdateFatigue)
end

Fortitude.FatigueManager = manager