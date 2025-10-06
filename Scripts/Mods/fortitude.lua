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

local function hookOnUsed(tableRef, name)
    if not tableRef then
        mod.Logger:Info(name .. ": table not found")
        return
    end

    local orig = tableRef.OnUsed
    if type(orig) ~= "function" then
        mod.Logger:Info(name .. ": OnUsed is not a function")
        return
    end

    -- prevent double-hooking
    if tableRef._orig_OnUsed then
        mod.Logger:Info(name .. ": already hooked")
        return
    end

    tableRef._orig_OnUsed = orig
    tableRef.OnUsed = function(self, user, slot)
        mod.Logger:Info(name .. " BEGIN (OnUsed)")
        return orig(self, user, slot)
    end

    mod.Logger:Info(name .. ": hooked successfully")
end

mod.OnGameplayStarted = function()
    KCDUtils.Config.LoadFromDB(mod.Name, mod.Config)
    KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
    Fortitude.FatigueManager.UpdateFatigue()
    player.soul:AdvanceToSkillLevel(mod.Config.skill.name, 5)

    hookOnUsed(Smithery, "Smithery")       -- Schmieden
    hookOnUsed(AlchemyTable, "Alchemy")    -- Alchemie
--  ingameInitialize()
end