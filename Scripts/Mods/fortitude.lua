local mod = KCDUtils.RegisterMod({ Name = "Fortitude" })
Fortitude = mod
ScriptLoader.LoadFolder("Scripts/Mods/Fortitude")

--- @type ModConfig
mod.Config = FortitudeConfig.defaultConfig

-- KCDUtils.Menu.RegisterMod(mod, FortitudeConfig.menuConfigTable)

-- local function ingameInitialize()
--     -- if player then
--     --     mod.Config.skillLevel = player.soul:GetSkillLevel("fortitude") or 0
--     -- end

--     KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
-- end

mod.OnGameplayStarted = function()
    KCDUtils.Config.LoadFromDB(mod.Name, mod.Config)
    KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
    Fortitude.FatigueManager.UpdateFatigue()
    player.soul:AdvanceToSkillLevel(mod.Config.skill.name, 5)

--  ingameInitialize()
end