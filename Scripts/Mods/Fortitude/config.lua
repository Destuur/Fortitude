FortitudeConfig = FortitudeConfig or {}

--- @class ModConfig
FortitudeConfig.defaultConfig = {
    -------------------------------------------------------------------
    --#region GENERAL CONFIG ------------------------------------------
    -------------------------------------------------------------------
    
    skillName = "first_aid",

    --#endregion

    -------------------------------------------------------------------
    --#region PLAYER --------------------------------------------------
    -------------------------------------------------------------------
    player = {
        fatigue          = 0,
        fatiguePerMeter  = 0.1,
        exhaustion       = 0,
        skillLevel       = 0,
        refreshRate      = 13,
    },
    --#endregion
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    --#region HORSE ---------------------------------------------------
    -------------------------------------------------------------------
    horse = {
        fatigue          = 0,
        fatiguePerMeter  = 0.05,
    },
    --#endregion
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    --#region FATIGUE CONFIG ------------------------------------------
    -------------------------------------------------------------------
    fatigue = {
        limitTarget = 105.0,
        baseSlope   = 0.005,
        extraSlope  = 0.0005,
        curveFactor = 0.0001,

        thresholds = {
            buffStart        = 70,
            buffEnd          = 100,
            bufferZone       = 105,
            firstOverExtend  = 120,
            secondOverExtend = 135,
            thirdOverExtend  = 150,
            overkill         = 170,
        },

        buffs = {
            flowZone         = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            firstOverExtend  = { id = "10fc25ca-c095-44c6-b88b-d54ad58ab0a6" , instanceId = nil, isActive = false },
            secondOverExtend = { id = "30725214-37be-4afd-aabf-a9a35869be38" , instanceId = nil, isActive = false },
            thirdOverExtend  = { id = "54e47564-c338-4de0-808d-fde58ec3c5be" , instanceId = nil, isActive = false },
            overkill         = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443"  , instanceId = nil, isActive = false },
        },
    },
    --#endregion
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    --#region EXHAUSTION CONFIG ---------------------------------------
    -------------------------------------------------------------------
    exhaustion = {
        buffs = {
            level1 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            level2 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            level3 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            level4 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            level5 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
            level6 = { id = "1aa6a7cc-4cee-4b73-8080-562bebc21443", instanceId = nil, isActive = false },
        },
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region WAKEUP CONFIG -------------------------------------------
    -------------------------------------------------------------------
    wakeup = {
        buffs = {
            firstOverExtend     = "",
            secondOverExtend    = "",
            thirdOverExtend     = "",
            overkill            = ""
        }
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region BUFF STATES ---------------------------------------------
    -------------------------------------------------------------------
    buffStates = {
        fatigue = {
            id = "fatigue",
            instance = nil,
            template = nil,
            active = false,
        },
        exhaustion = {
            id = "exhaustion",
            instance = nil,
            template = nil,
            active = false,
        }
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region TRAVEL / DISTANCE ---------------------------------------
    -------------------------------------------------------------------
    travel = {
        distanceDay   = 0,
        distanceDelta = 0,
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region ACTIVITIES ----------------------------------------------
    -------------------------------------------------------------------
    activities = {
        washArmor   = 3,
        washFace    = 3,
        repairArmor = 6,
        blacksmith  = 12,
        alchemy     = 4,
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region ARMOR ---------------------------------------------------
    -------------------------------------------------------------------
    armor = {
        weight = {
            light  = 1.0,
            medium = 1.2,
            heavy  = 1.4,
        }
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region CARRY WEIGHT --------------------------------------------
    -------------------------------------------------------------------
    carryWeight = {
        light    = 1.0,
        medium   = 1.3,
        heavy    = 1.4,
        overload = 1.8,
    },
    --#endregion
    -------------------------------------------------------------------
}