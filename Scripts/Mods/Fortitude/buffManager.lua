--- @type KCDUtils*mod
local mod = Fortitude

--- @class BuffManager
local manager = {}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function ensureConfig()
  local cfg = Fortitude.Config
  if not cfg then
    return nil
  end
  return cfg
end

local function isValidTemplate(id)
  return type(id) == "string" and id ~= ""
end

local function safeRemove(slot, reason)
  if not slot then return end
  local label = slot.id or slot.template or "?"

  if slot.instance and slot.instance ~= "" then
    local ok, err = pcall(function() player.soul:RemoveBuff(slot.instance) end)
  end

  slot.instance = nil
  slot.template = nil
  slot.active = false
end

local function asIdAndEntry(v)
  if type(v) == "table" then
    return v.id, v
  elseif type(v) == "string" then
    return v, nil
  else
    return nil, nil
  end
end

local function resetBuffObjects(group)
  if type(group) ~= "table" then return end
  for name, entry in pairs(group) do
    if type(entry) == "table" then
      entry.isActive = false
      entry.instanceId = nil
    end
  end
end

---------------------------------------------------------------------
-- Core Buff Logic
---------------------------------------------------------------------

local function setBuff(slot, desiredTemplate)
  local label = slot.id or slot.template or "?"

  if not isValidTemplate(desiredTemplate) then
    if slot.instance then
      safeRemove(slot, "invalid template")
    end
    return
  end

  -- Template-Wechsel → alten Buff löschen
  if slot.template and slot.template ~= desiredTemplate then
    safeRemove(slot, "template changed")
  end

  -- Wenn aktiv und gleiches Template → nichts tun
  if slot.active and slot.template == desiredTemplate and slot.instance then
    return
  end

  -- neuen Buff anwenden
  local ok, instOrErr = pcall(function() return player.soul:AddBuff(desiredTemplate) end)

  if ok and instOrErr then
    slot.instance = instOrErr
    slot.template = desiredTemplate
    slot.active = true
  else
    slot.active = false
  end
end

---------------------------------------------------------------------
-- Fatigue Buff Handling
---------------------------------------------------------------------

local function selectFatigueTemplate(cfg, fatigue)
    local t = cfg.fatigue.thresholds
    local b = cfg.fatigue.buffs

    if fatigue < t.buffStart then
        return nil
    elseif fatigue <= t.buffEnd then
        return b.flowZone.id
    elseif fatigue <= t.bufferZone then
        return nil
    elseif fatigue <= t.firstOverExtend then
        return b.firstOverExtend.id
    elseif fatigue <= t.secondOverExtend then
        return b.secondOverExtend.id
    elseif fatigue <= t.thirdOverExtend then
        return b.thirdOverExtend.id
    elseif fatigue >= t.overkill then
        return b.overkill.id
    else
        return nil
    end
end

function manager.HandleFatigueBuff()
  local cfg = ensureConfig()
  if not cfg then return end

  local desired, entry = selectFatigueTemplate(cfg, cfg.player.fatigue)

  resetBuffObjects(cfg.fatigue.buffs)

  if not desired then
    safeRemove(cfg.buffStates.fatigue, "no buff desired")
    return
  end

  setBuff(cfg.buffStates.fatigue, desired)

  if entry and cfg.buffStates.fatigue.active then
    entry.isActive = true
    entry.instanceId = cfg.buffStates.fatigue.instance
  end
end

---------------------------------------------------------------------
-- Exhaustion Buff Handling
---------------------------------------------------------------------

function manager.HandleWakeupBuff()
end

---------------------------------------------------------------------
-- Exhaustion Buff Handling
---------------------------------------------------------------------

local function selectExhaustionTemplate(cfg, ex)
  local b = cfg.exhaustion.buffs
  if ex == 0 then
    return nil, nil
  elseif ex == 1 then
    return asIdAndEntry(b.level1)
  elseif ex == 2 then
    return asIdAndEntry(b.level2)
  elseif ex == 3 then
    return asIdAndEntry(b.level3)
  elseif ex == 4 then
    return asIdAndEntry(b.level4)
  elseif ex == 5 then
    return asIdAndEntry(b.level5)
  end
  return asIdAndEntry(b.level6)
end

function manager.HandleExhaustionBuff()
  local cfg = ensureConfig()
  if not cfg then return end

  local desired, entry = selectExhaustionTemplate(cfg, cfg.player.exhaustion or 0)

  resetBuffObjects(cfg.exhaustion.buffs)

  if not desired then
    safeRemove(cfg.buffStates.exhaustion, "no buff desired")
    return
  end

  setBuff(cfg.buffStates.exhaustion, desired)

  if entry and cfg.buffStates.exhaustion.active then
    entry.isActive = true
    entry.instanceId = cfg.buffStates.exhaustion.instance
  end
end

---------------------------------------------------------------------
-- Utility
---------------------------------------------------------------------

function manager.ClearAll()
  local cfg = ensureConfig()
  if not cfg then
    return
    end
  safeRemove(cfg.buffStates.fatigue, "clearAll")
  safeRemove(cfg.buffStates.exhaustion, "clearAll")
  resetBuffObjects(cfg.fatigue.buffs)
  resetBuffObjects(cfg.exhaustion.buffs)
end

function manager.SyncFromConfig()
  local cfg = ensureConfig()
  if not cfg then
    return
    end

  for name, slot in pairs(cfg.buffStates) do
    if slot.active and isValidTemplate(slot.template) and not slot.instance then
      local ok, inst = pcall(function() return player.soul:AddBuff(slot.template) end)
      if ok then
        slot.instance = inst
      else
        slot.active = false
      end
    end
  end

  local function resyncGroup(group, gname)
    for k, v in pairs(group) do
      if type(v) == "table" and v.isActive then
        if isValidTemplate(v.id) and (not v.instanceId or v.instanceId == "") then
          local ok, inst = pcall(function() return player.soul:AddBuff(v.id) end)
          if ok then
            v.instanceId = inst
          else
            v.isActive = false
            v.instanceId = nil
          end
        end
      end
    end
  end

  resyncGroup(cfg.fatigue.buffs, "fatigue")
  resyncGroup(cfg.exhaustion.buffs, "exhaustion")
end

---------------------------------------------------------------------
-- Export
---------------------------------------------------------------------

Fortitude.BuffManager = manager