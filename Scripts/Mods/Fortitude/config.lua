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