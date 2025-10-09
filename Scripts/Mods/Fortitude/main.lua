--- @class KCDUtils*mod
Fortitude = Fortitude or {}
--- @type KCDUtils*mod
local mod       = Fortitude
--- @type FatigueManager
local manager   = Fortitude.FatigueManager

local CONFIRM_LC = {
  onamountdialogconfirmclicked  = true,
  oninfodialogconfirmclicked    = true,
  onhealingdialogconfirmclicked = true,
  oncombinedialogconfirmclicked = true,
  onquestiondialogconfirmclicked= true,
}

local CANCEL_LC = {
  onamountdialogcancelclicked   = true,
  onhealingdialogcancelclicked  = true,
  oncombinedialogcancelclicked  = true,
  onquestiondialogcancelclicked = true,
}

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

Fortitude.On.ButcherStarted = function(ev)
  Fortitude.Logger:Info(("[ButcherStarted] class=%s id=%s"):format(tostring(ev.class), tostring(ev.entity and ev.entity.id)))

  local sizeByClass = {
    Hare="small", Hen="small", Raven="small",
    SheepEwe="medium", SheepRam="medium", Pig="medium", Dog="medium", Wolf="medium",
    Boar="large", CattleCow="large", CattleBull="large", Horse="large",
  }
  local size = sizeByClass[ev.class] or "medium"
  local key  = "butcher_"..size

  if Fortitude.FatigueManager and Fortitude.FatigueManager.AddActivity then
    Fortitude.FatigueManager.AddActivity(key)
  end
end

function mod:DoStuff()
    KCDUtils.UI.ShowNotification("Doing stuff in Fortitude mod!")
end

function mod:DoMoreStuff()
    KCDUtils.UI.ShowNotification("Doing more stuff in Fortitude mod!")
end

function mod:OnSkipTimeEvent(elementName, instanceId, eventName, argTable)
    if eventName == "OnSetFaderState" and argTable and argTable[1] == "sleep" then
        self.sleepStartHour = KCDUtils.Calendar.GetWorldHourOfDay()

    elseif eventName == "OnHide" and self.sleepStartHour ~= nil then
        local sleepEndHour = KCDUtils.Calendar.GetWorldHourOfDay()
        local slept = (sleepEndHour - self.sleepStartHour) % 24

        self.FatigueManager:RefreshFatigue(slept)

        self.sleepStartHour = nil
    end
end

-- wh_pl_OrbitCameraPosition 0 15 3
-- wh_pl_FollowEntity dude
-- wait 100
-- wh_pl_FollowEntity 7
-- wh_ui_ShowCursor 0

if UIAction and UIAction.RegisterElementListener then
    UIAction.RegisterElementListener(Fortitude, "SkipTime", -1, "", "OnSkipTimeEvent")
end

if UIAction and UIAction.RegisterElementListener then
  UIAction.RegisterElementListener(Fortitude, "ApseModalDialog", -1, "", "OnApseDialogEvent")
end

function Fortitude:OnApseDialogEvent(elementName, instanceId, eventName, argTable)
  self.Logger:Info(("[ApseDialog] event=%s | element=%s | instance=%s")
    :format(tostring(eventName), tostring(elementName), tostring(instanceId)))

  if type(Fortitude.Activity.FinishCrafting) ~= "function" or type(Fortitude.Activity.StartCrafting) ~= "function" then
    self.Logger:Error("[ApseDialog] Activity helpers not loaded yet (Start/FinishCrafting)")
    return
  end

  local ev = tostring(eventName or ""):lower()

  if CONFIRM_LC[ev] then
    return Fortitude.Activity.FinishCrafting(true)
  elseif CANCEL_LC[ev] then
    return Fortitude.Activity.FinishCrafting(false)
  end

  local A = Fortitude.Activity
  if not (A and A.active) then return end

  if ev == "onshow" then
    if A.kind == "blacksmith" then
      A.dialogShows = (A.dialogShows or 0) + 1
      self.Logger:Info(("[ApseDialog] blacksmith OnShow #%d"):format(A.dialogShows))
      if A.dialogShows >= 2 then
        return Fortitude.Activity.FinishCrafting(true)
      end
      return
    else
      return Fortitude.Activity.FinishCrafting(true)
    end
  end
end
