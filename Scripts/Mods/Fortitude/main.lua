--- @class KCDUtils*mod
Fortitude = Fortitude or {}
--- @type KCDUtils*mod
local mod       = Fortitude
--- @type FatigueManager
local manager   = Fortitude.FatigueManager

mod.On.DistanceTravelled = function(data)
    local delta = data.distance or 0
    local cfg = Fortitude.Config

    if delta < 0.01 then
        manager.isResting = true
        delta = 0
    else
        manager.isResting = false
    end

    cfg.travel.distanceDay   = cfg.travel.distanceDay + delta
    cfg.travel.distanceDelta = (cfg.travel.distanceDelta or 0) + delta
end

mod.On.CarryCorpseChanged = function(data)
    manager.isCarryingCorpse = data.isCarryingCorpse
end

mod.On.CombatStateChanged = function(data)
    manager.isFighting = data.inCombat
end

mod.On.MountedStateChanged = function(data)
    manager.isMounted = data.isMounted
end

mod.On.SittingChanged = function(data)
    manager.isSitting = data.isSitting
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

if UIAction and UIAction.RegisterElementListener then
    UIAction.RegisterElementListener(Fortitude, "SkipTime", -1, "", "OnSkipTimeEvent")
    Fortitude.Logger:Info("Registered OnSkipTimeEvent listener on SkipTime UI element.")
else
    System.LogAlways("[Fortitude] ⚠️ UIAction not available for SkipTime registration")
end

-- wh_pl_OrbitCameraPosition 0 15 3
-- wh_pl_FollowEntity dude
-- wait 100
-- wh_pl_FollowEntity 7
-- wh_ui_ShowCursor 0


-- Registrierung: genau der Elementname aus der XML
if UIAction and UIAction.RegisterElementListener then
    UIAction.RegisterElementListener(Fortitude, "ApseModalDialog", -1, "", "OnApseDialogEvent")
    Fortitude.Logger:Info("✅ Listening on 'ApseModalDialog' for ALL events.")
else
    System.LogAlways("[Fortitude] ⚠️ UIAction not available for ApseModalDialog registration")
end

-- Ein Listener für alles: wir loggen, filtern aber "Dialog"-Events extra hübsch
function Fortitude:OnApseDialogEvent(elementName, instanceId, eventName, argTable)
    -- Alles loggen:
    self.Logger:Info(string.format("[ApseDialog] event=%s | element=%s | instance=%s",
        tostring(eventName), tostring(elementName), tostring(instanceId)))

    if argTable then
        for k, v in pairs(argTable) do
            self.Logger:Info(string.format("  args.%s = %s", tostring(k), tostring(v)))
        end
    else
        self.Logger:Info("  (no args)")
    end

    -- Optional: hübsche Kurzmeldungen für die relevanten Dialog-Resultate
    if eventName == "onAmountDialogConfirmClicked" then
        self.Logger:Info("[ApseDialog] AmountDialog: CONFIRM")
        -- Falls du den Wert brauchst und die UI das unterstützt:
        -- UIAction.CallFunction("ApseModalDialog", -1, "fc_getAmountDialogValue")
        -- (Je nach Implementierung füllt die UI evtl. ein Array oder triggert ein anderes Event.)
    elseif eventName == "onAmountDialogCancelClicked" then
        self.Logger:Info("[ApseDialog] AmountDialog: CANCEL")
    elseif eventName == "onInfoDialogConfirmClicked" then
        self.Logger:Info("[ApseDialog] InfoDialog: OK")
    elseif eventName == "onHealingDialogConfirmClicked" then
        self.Logger:Info("[ApseDialog] HealingDialog: CONFIRM")
    elseif eventName == "onHealingDialogCancelClicked" then
        self.Logger:Info("[ApseDialog] HealingDialog: CANCEL")
    elseif eventName == "onCombineDialogConfirmClicked" then
        self.Logger:Info("[ApseDialog] CombineDialog: CONFIRM")
    elseif eventName == "onCombineDialogCancelClicked" then
        self.Logger:Info("[ApseDialog] CombineDialog: CANCEL")
    elseif eventName == "onCombineDialogSelectClicked" then
        self.Logger:Info("[ApseDialog] CombineDialog: SELECT")
    elseif eventName == "onCombineFocusChanged" then
        self.Logger:Info("[ApseDialog] CombineDialog: FOCUS CHANGED")
    end
end
