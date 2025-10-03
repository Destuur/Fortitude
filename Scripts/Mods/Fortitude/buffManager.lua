--- @type KCDUtils*mod
local mod = Fortitude
--- @class BuffManager
local manager = {
    buffId = ""
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

function manager.HandleExhaustionBuff()
    local config = ensureConfig()

    if config.player_exhaustion > 1 then
        config.exhaustion_currentBuff = player.soul:AddBuff(config.exhaustion_testBuff)
    end
end

function manager.HandleFatigueBuff()
    local config = ensureConfig()

    if config.player_fatigue > config.fatigueThreshold_buffStart then
        config.fatigue_currentBuff = player.soul:AddBuff(config.fatigue_testBuff)
    end
end

Fortitude.BuffManager = manager