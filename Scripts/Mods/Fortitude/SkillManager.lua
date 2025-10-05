--- @type KCDUtils*mod
local mod = Fortitude

--- @class SkillManager
local manager = {
    xpGainBuffer = 0
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

function manager.AddXPFromFatigue(fatigueDelta)
    local cfg = ensureConfig()
    if not cfg or fatigueDelta <= 0 then
        return
    end

    local level = cfg.player.fortitudeLevel or 1
    local baseRate = 0.5
    local levelFactor = 1 - (level / 60)

    local xpGain = fatigueDelta * baseRate * levelFactor
    if xpGain <= 0 then return end

    manager.xpGainBuffer = manager.xpGainBuffer + xpGain
    
    if manager.xpGainBuffer > 5 then
        player.soul:AddSkillXP(cfg.skillName, manager.xpGainBuffer)
        manager.xpGainBuffer = 0
    end

end

Fortitude.SkillManager = manager