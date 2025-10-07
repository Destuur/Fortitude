Fortitude.Activity = Fortitude.Activity or { 
    active = false,
    kind = nil,
    token = nil,
    dialogShows = 0
}

function StartCrafting(kind)
  local A = Fortitude.Activity
  if A.active then
    Fortitude.Logger:Info(("[Activity] interrupt %s → %s"):format(tostring(A.kind), tostring(kind)))
  end
  A.active, A.kind, A.token = true, kind, {}
  A.dialogShows = 0

  local timeoutMs = (Fortitude.Config.activitiesTimeoutMs or 180000)
  Fortitude.Logger:Info(("[Activity] %s started (timeout %ds)"):format(kind, timeoutMs/1000))

  local token = A.token
  Script.SetTimer(timeoutMs, function()
    if Fortitude.Activity.active and Fortitude.Activity.token == token then
      Fortitude.Logger:Info(("[Activity] %s timed out → reset (no credit)"):format(kind))
      Fortitude.Activity.active, Fortitude.Activity.kind, Fortitude.Activity.token = false, nil, nil
      Fortitude.Activity.dialogShows = 0
    end
  end)
end

function FinishCrafting(success)
  local A = Fortitude.Activity
  if not A.active then return end
  local kind = A.kind
  A.active, A.kind, A.token = false, nil, nil
  A.dialogShows = 0

  if success then
    Fortitude.Logger:Info(("[Activity] %s finished → credit fatigue"):format(kind))
    if Fortitude.FatigueManager and Fortitude.FatigueManager.AddActivity then
      Fortitude.FatigueManager.AddActivity(kind)
    end
  else
    Fortitude.Logger:Info(("[Activity] %s canceled/aborted → no credit"):format(kind))
  end
end

function GatherHerb()
    if Fortitude.FatigueManager and Fortitude.FatigueManager.AddActivity then
        Fortitude.FatigueManager.AddActivity("herbGathering")
    end
end