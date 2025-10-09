local mod = KCDUtils.RegisterMod({ Name = "Fortitude" })
Fortitude = mod
ScriptLoader.LoadFolder("Scripts/Mods/Fortitude")

--- @type ModConfig
mod.Config = FortitudeConfig.defaultConfig

local function hookPickableArea()
  local function try()
    local t = _G.PickableArea
    if t and type(t.Gather)=="function" then
      KCDUtils.Hook.Method(t, "Gather", function(orig, self, user, slot)
        GatherHerb()
        return orig(self, user, slot)
      end)
      Fortitude.Logger:Info("[Fortitude] Hooked PickableArea.Gather via KCDUtils.Hook")
    else
      Script.SetTimer(500, try)
    end
  end
  try()
end

local function hookMiniGameEvents()
    Fortitude.On.SmitheryStarted = function(ev)
        Fortitude.Activity.StartCrafting("blacksmith")
    end
    Fortitude.On.AlchemyStarted = function(ev)
        Fortitude.Activity.StartCrafting("alchemy")
    end
end

local function initAfterConfigLoad()
    Fortitude.BuffManager.SyncFromConfig()
    Fortitude.BuffManager.HandleFatigueBuff()
    Fortitude.BuffManager.HandleExhaustionBuff()
    Fortitude.FatigueManager.UpdateFatigue()
    KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
    player.soul:AdvanceToSkillLevel(mod.Config.skill.name, mod.Config.skill.level or 5)

    hookMiniGameEvents()
    hookPickableArea()

    Fortitude.Logger:Info("[Fortitude] Initialization complete after Config load.")
end

-- Hook to save game
function Fortitude.SaveConfig()
  mod.DB:Set(mod.Name, mod.Config)
  Script.SetTimer(1000, function() Fortitude.SaveConfig() end)
end

mod.OnGameplayStarted = function()
    KCDUtils.Config.LoadFromDB(mod.Name, mod.Config)
    initAfterConfigLoad()
    Script.SetTimer(1000, function() Fortitude.SaveConfig() end)
end