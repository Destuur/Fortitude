FortitudeConfig = FortitudeConfig or {}

--- @class ModConfig
FortitudeConfig.defaultConfig = {

--- =========================================
--- Player Resources
--- =========================================

    player_fatigue               = 0,
    player_fatiguePerMeter       = 0.1,
    player_exhaustion            = 0,
    player_skillLevel            = 0,
    player_refresh               = 10,

--- =========================================
--- Horse Resources
--- =========================================

    horse_fatigue                = 0,
    horse_fatiguePerMeter        = 0.05,

--- =========================================
--- Fatigue Config
--- =========================================

    fatigue_limitTarget    = 105.0,
    fatigue_baseSlope      = 0.1,
    -- fatigue_baseSlope      = 0.005,
    fatigue_extraSlope     = 0.0005,
    fatigue_curveFactor    = 0.0001,

--- =========================================
--- Fatigue Thresholds
--- =========================================

    fatigueThreshold_buffStart        = 70,
    fatigueThreshold_buffEnd          = 100,
    fatigueThreshold_bufferZone       = 105,
    fatigueThreshold_firstOverExtend  = 120,
    fatigueThreshold_secondOverExtend = 135,
    fatigueThreshold_thirdOverExtend  = 150,
    fatigueThreshold_overkill         = 170,
    
--- =========================================
--- Fatigue Buffs
--- =========================================

    fatigue_currentBuff = "",
    fatigue_testBuff = "1aa6a7cc-4cee-4b73-8080-562bebc21443",

--- =========================================
--- Exhaustion Buffs
--- =========================================

    exhaustion_currentBuff = "",
    exhaustion_testBuff = "b9f062d3-c06e-4698-90d4-e642e863337b",

--- =========================================
--- Distance
--- =========================================

    distance_day = 0,
    distance_delta = 0,

--- =========================================
--- Activities
--- =========================================

    activity_washArmor   = 3,
    activity_washFace    = 3,
    activity_repairArmor = 6,
    activity_blacksmith  = 12,
    activity_alchemy     = 4,

--- =========================================
--- Armor Weights
--- =========================================

    armorWeight_light  = 1.0,
    armorWeight_medium = 1.2,
    armorWeight_heavy  = 1.4,

--- =========================================
--- Carried Weights
--- =========================================

    carriedWeight_light    = 1.0,
    carriedWeight_medium   = 1.3,
    carriedWeight_heavy    = 1.4,
    carriedWeight_overload = 1.8,
}