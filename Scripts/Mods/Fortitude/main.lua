--- @class KCDUtils*mod
Fortitude = Fortitude or {}

--- @type KCDUtils*mod
local mod       = Fortitude
--- @type FatigueManager
local manager   = Fortitude.FatigueManager
--- @type ModConfig
local config    = mod and mod.Config
local db        = mod and mod.DB
local log       = mod and mod.Logger

mod.On.DistanceTravelled = function(data)
    manager.AddDistance(data.distance)
end

mod.On.CombatStateChanged = function(data)
    manager.isFighting = data.inCombat
end

mod.On.MountedStateChanged = function(data)
    manager.isMounted = data.isMounted
end

function Fortitude:DoStuff()
    KCDUtils.UI.ShowNotification("Doing stuff in Fortitude mod!")
end

function Fortitude:DoMoreStuff()
    KCDUtils.UI.ShowNotification("Doing more stuff in Fortitude mod!")
end