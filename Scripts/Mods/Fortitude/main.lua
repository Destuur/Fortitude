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

function Fortitude:OnSkipTimeEvent(elementName, instanceId, eventName, argTable)
    if eventName == "OnSetFaderState" and argTable and argTable[1] == "sleep" then
        self.sleepStartHour = KCDUtils.Calendar.GetWorldHourOfDay()

    elseif eventName == "OnHide" and self.sleepStartHour ~= nil then
        local sleepEndHour = KCDUtils.Calendar.GetWorldHourOfDay()
        local slept = (sleepEndHour - self.sleepStartHour) % 24

        self.FatigueManager:RefreshFatigue(slept)

        self.sleepStartHour = nil
    end
end

function Fortitude:OnHudButtonEvent(elementName, instanceId, eventName, argTable)
    if eventName == "OnActionButtonActivated" and argTable then
        local actionName = tostring(argTable[1] or "nil")
        local activationMode = tonumber(argTable[2] or -1)

        -- Mode interpretieren
        local modeText = ({
            [0] = "Pressed",
            [1] = "Held",
            [2] = "Released"
        })[activationMode] or ("Unknown(" .. activationMode .. ")")

        self.Logger:Info(string.format(
            "[HudButton] Action='%s' (%s) | element=%s | instance=%s",
            actionName, modeText, tostring(elementName), tostring(instanceId)
        ))

    elseif eventName == "GetButtonId" and argTable then
        local actionName = tostring(argTable[1] or "nil")
        self.Logger:Info(string.format(
            "[HudButton] GetButtonId | Action='%s' | element=%s | instance=%s",
            actionName, tostring(elementName), tostring(instanceId)
        ))

    -- Nur für Debugging: alle anderen Events (abschaltbar)
    else
        -- Debug-only: Kannst du entfernen, wenn es zu viel Spam wird
        self.Logger:Debug(string.format(
            "[HudButton] Ignored Event=%s | element=%s | instance=%s",
            tostring(eventName), tostring(elementName), tostring(instanceId)
        ))
    end
end

if UIAction and UIAction.RegisterElementListener then
    UIAction.RegisterElementListener(Fortitude, "SkipTime", -1, "", "OnSkipTimeEvent")
    Fortitude.Logger:Info("Registered OnSkipTimeEvent listener on SkipTime UI element.")
else
    System.LogAlways("[Fortitude] ⚠️ UIAction not available for SkipTime registration")
end

-- Registrierung
if UIAction and UIAction.RegisterElementListener then
    UIAction.RegisterElementListener(Fortitude, "HUD", -1, "", "OnHudButtonEvent")
    Fortitude.Logger:Info("Registered OnHudButtonEvent listener on hud UI element.")
else
    System.LogAlways("[Fortitude] ⚠️ UIAction not available for hud registration")
end


-- wh_pl_OrbitCameraPosition 0 15 3
-- wh_pl_FollowEntity dude
-- wait 100
-- wh_pl_FollowEntity 7
-- wh_ui_ShowCursor 0