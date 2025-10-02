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
    local cfg = Fortitude.Config
    if not cfg or not cfg.Fatigue then
        mod.Logger:Error("Config not initialized!")
        return nil
    end
    return cfg
end

local function getDistanceFactor()
    return 1
end

local function getCombatFactor()
    return 1
end

local function getLocationFactor()
    return 1
end

local function getDayTimeFactor()
    return 1
end

local function getWeatherFactor()
    return 1
end

local function getWeightFactor()
    return 1
end

local function getArmorFactor()
    return 1
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
    local distanceFactor = getDistanceFactor()
    local combatFactor = getCombatFactor()
    local locationFactor = getLocationFactor()
    local dayTimeFactor = getDayTimeFactor()
    local weatherFactor = getWeatherFactor()
    local mountedFactor = getMountedFactor()
    local weightFactor = getWeightFactor()
    local armorFactor = getArmorFactor()
    config.Fatigue.player = config.Fatigue.player + (distance * distanceFactor * combatFactor * locationFactor * dayTimeFactor * weatherFactor * mountedFactor * weightFactor * armorFactor)
    mod.Logger:Info("Henry ist so angestrengt: " .. tostring(config.Fatigue.player))
end

local function addHorseFatigue(distance)
    local config = ensureConfig()
    if manager.isMounted == false then
        return
    end
    config.Fatigue.horse = config.Fatigue.horse + (distance * config.FatiguePerMeter.horse)
    mod.Logger:Info("Pferd ist so angestrengt: " .. tostring(config.Fatigue.horse))
end

local function checkFatigueThreshold()
    local config = ensureConfig()
    if config.Fatigue.player > config.FatigueThresholds.firstOverExtend then
        player.soul:DealDamage(0, 0, nil, false, nil)
    end
end

function manager.AddDistance(distance)
    addHorseFatigue(distance)
    addPlayerFatigue(distance)

    checkFatigueThreshold()
end

function manager.AddActivity(activity)
end

Fortitude.FatigueManager = manager