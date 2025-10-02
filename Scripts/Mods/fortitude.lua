local mod = KCDUtils.RegisterMod({ Name = "fortitude" })
Fortitude = mod
ScriptLoader.LoadFolder("Scripts/Mods/Fortitude")

--- @return ModConfig
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

--- @type ModConfig
mod.Config = deepCopy(FortitudeConfig.defaultConfig)

-- KCDUtils.Menu.RegisterMod(mod, FortitudeConfig.menuConfigTable)

-- local function ingameInitialize()
--     if player then
--         mod.Config.skillLevel = player.soul:GetSkillLevel("fortitude") or 0
--     end
--     KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
-- end

mod.OnGameplayStarted = function()
    KCDUtils.Config.LoadFromDB(mod.Name, mod.Config)
    KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")

    -- ingameInitialize()
end