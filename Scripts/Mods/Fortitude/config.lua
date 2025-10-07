FortitudeConfig = FortitudeConfig or {}

--- @class ModConfig
FortitudeConfig.defaultConfig = {
    -------------------------------------------------------------------
    --#region GENERAL CONFIG ------------------------------------------
    -------------------------------------------------------------------
    
    skill = {
        name = "first_aid",
        level = 5
    },

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
            flowZone         = { id = "ad7f10ef-d074-44f8-a3a2-da6394f12598", instanceId = nil, isActive = false },
            firstOverExtend  = { id = "afb12d78-72ad-4481-8942-8eae68d33bae" , instanceId = nil, isActive = false },
            secondOverExtend = { id = "50258931-75d2-4be1-9e52-7caa4b286a70" , instanceId = nil, isActive = false },
            thirdOverExtend  = { id = "c5bb4bef-30ca-49ff-b1c8-ebc163a6508a" , instanceId = nil, isActive = false },
            overkill         = { id = "5d51e01e-7c3f-4f14-8450-3245cfc3cebe"  , instanceId = nil, isActive = false },
        },
    },

    resting = {
        regenRateSitting = 0.03,
        regenRateStanding = 0.01,
        maxRegenFromRest = 10.0
    },
    --#endregion
    -------------------------------------------------------------------
    
    -------------------------------------------------------------------
    --#region EXHAUSTION CONFIG ---------------------------------------
    -------------------------------------------------------------------
    exhaustion = {
        buffs = {
            level1 = { id = "e0f5fa48-1c16-41bf-af31-5e59e03029e5", instanceId = nil, isActive = false },
            level2 = { id = "3fcfe05d-9233-4396-924f-35983b36204d", instanceId = nil, isActive = false },
            level3 = { id = "d5b6ab6d-9670-4ade-a1e9-c591e20d2c3b", instanceId = nil, isActive = false },
            level4 = { id = "5d85041d-afe1-46d0-b877-c81762f7c6e6", instanceId = nil, isActive = false },
            level5 = { id = "2f6a8b16-9388-43be-a29b-8f8a236fe0a4", instanceId = nil, isActive = false },
            level6 = { id = "5a7aca1f-80c8-4d08-8b02-3d0970dae771", instanceId = nil, isActive = false },
        },
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region WAKEUP CONFIG -------------------------------------------
    -------------------------------------------------------------------
    wakeup = {
        buffs = {
            level1    = "9b92b0f8-94e9-4e0f-997d-986f555ac49d",
            level2    = "19ee884d-3d69-49af-8b14-4039c88c32bb",
            level3    = "c6155983-0b80-413a-bcc1-615ef1003ee0",
            level4    = "dd68f7aa-710f-4b53-a956-99582857e1e0"
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
        washArmor       = 3,
        washFace        = 3,
        repairArmor     = 6,
        blacksmith      = 12,
        alchemy         = 4,
        herbGathering   = 0.5,
        butcher_small    = 3,
        butcher_medium   = 6,
        butcher_large    = 9
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region ARMOR ---------------------------------------------------
    -------------------------------------------------------------------
    armor = {
        weight = {
            light  = 1.0,
            medium = 1.5,
            heavy  = 2,
        }
    },
    --#endregion
    -------------------------------------------------------------------

    -------------------------------------------------------------------
    --#region CARRY WEIGHT --------------------------------------------
    -------------------------------------------------------------------
    carryWeight = {
        light    = 1.0,
        medium   = 1.5,
        heavy    = 2,
        overload = 3,
    },
    --#endregion
    -------------------------------------------------------------------
}