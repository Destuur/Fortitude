FortitudeConfig = FortitudeConfig or {}

--- @class ModConfig
FortitudeConfig.defaultConfig = {
    Fatigue = {
        player      = 0,
        horse       = 0
    },
    FatiguePerMeter = {
        player = 0.1,
        horse = 0.05
    },
    FatigueThresholds = {
        buffStart           = 70,
        neutralHigh         = 100,
        bufferZone          = 105,
        firstOverExtend     = 120,
        secondOverExtend    = 135,
        thirdOverExtend     = 150,
        overkill            = 170
    },
    ActivityTable = {
        WashArmor   = 3,
        WashFace    = 3,
        RepairArmor = 6,
        Blacksmith  = 12,
        Alchemy     = 4
    },
    RainSeverity = {
        none   = 1.0,
        low    = 1.2,
        medium = 1.4,
        high   = 1.7
    },

    skillLevel = 0,
}