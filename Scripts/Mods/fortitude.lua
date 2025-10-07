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
        StartCrafting("blacksmith")
    end
    Fortitude.On.AlchemyStarted = function(ev)
        StartCrafting("alchemy")
    end
end

-- local function hookOnce(tbl, fname, wrap)
--   if not (tbl and type(tbl[fname])=="function") then return false end
--   if not tbl["__orig_"..fname] then
--     tbl["__orig_"..fname] = tbl[fname]
--     tbl[fname] = function(self, ...) return wrap(tbl["__orig_"..fname], self, ...) end
--     return true
--   end
--   return false
-- end

-- local animals = {
--   "BasicAnimal","Horse","InventoryDummyHorse","WildDog","Raven","Pig","SheepEwe",
--   "RedDeerDoe","RedDeerStag","RoeDeerHind","RoeDeerBuck","Hare","InventoryDummyDog",
--   "Wolf","Hen","SheepRam","Dog","CattleCow","CattleBull","Boar",
-- }

-- local function HookButcherDebug()
--   -- 1) Der wirklich aufgerufene Callback des Buttons:
--   if hookOnce(_G.BasicAnimal, "OnButcher", function(orig, self, user, ...)
--     Fortitude.Logger:Info(("[BUTCHER] class=%s"):format(tostring(self.class or self.GetName and self:GetName() or "?")))
--     return orig(self, user, ...)
--   end) then
--     Fortitude.Logger:Info("Hooked BasicAnimal.OnButcher")
--   end

--   -- 2) Sehe, wann du nur lootest (ItemTransfer):
--   if hookOnce(_G.BasicAnimal, "OnUsed", function(orig, self, user, ...)
--     Fortitude.Logger:Info(("[USED] class=%s → ItemTransfer"):format(tostring(self.class or "?")))
--     return orig(self, user, ...)
--   end) then
--     Fortitude.Logger:Info("Hooked BasicAnimal.OnUsed")
--   end

--   -- 3) Logge die Gate-Flags bei Aktionsaufbau:
--   for _, name in ipairs(animals) do
--     local t = _G[name]
--     hookOnce(t, "GetActions", function(orig, self, user, firstFast)
--       local hp   = (self.actor and self.actor.GetHealth and self.actor:GetHealth()) or -1
--       local can  = (self.actor and self.actor.CanBeButchered and self.actor:CanBeButchered()) or false
--       local dist = (self.actor and self.actor.IsPlayerInButcheringDistance and self.actor:IsPlayerInButcheringDistance()) or false
--       local tense= (user and user.soul and user.soul.IsInTenseCircumstance and user.soul:IsInTenseCircumstance()) or false
--       Fortitude.Logger:Info(("[GetActions] class=%s hp<=0=%s can=%s dist=%s tense=%s")
--         :format(name, tostring(hp<=0), tostring(can), tostring(dist), tostring(tense)))
--       return orig(self, user, firstFast)
--     end)
--   end
-- end

mod.OnGameplayStarted = function()
    KCDUtils.Config.LoadFromDB(mod.Name, mod.Config)
    KCDUtils.UI.ShowNotification("@ui_notification_fortitude_loaded")
    player.soul:AdvanceToSkillLevel(mod.Config.skill.name, 5)
    Fortitude.FatigueManager.UpdateFatigue()

    -- HookButcherDebug()
    hookMiniGameEvents()
    hookPickableArea()
end