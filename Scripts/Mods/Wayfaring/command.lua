-- Wayfaring command.lua
--[[
    Command functions template for Kingdom Come: Deliverance II
    Generated with VS Code Extension

    Mod Name: Wayfaring
    Namespace / Table: Wayfaring
    Description: Handles console commands and binds them for KCD2 keybinder integration.
--]]

------------------------------------------------------------
-- Ensure the global mod table exists
------------------------------------------------------------
Wayfaring = Wayfaring or {}

------------------------------------------------------------
-- Local helper: retrieves mod, config, db, log safely
-- This prevents repeated nil-checks in command functions
------------------------------------------------------------
local function GetModStuff()
    local mod = Wayfaring
    if not mod then return nil, nil, nil, nil end
    local config = mod.Config
    local db     = mod.DB
    local log    = mod.Logger
    return mod, config, db, log
end

------------------------------------------------------------
-- Example console command functions
-- These functions will be bound to in-game commands
------------------------------------------------------------

local function showStatus()
    local mod, config, db, log = GetModStuff()
    if not config or not log then return end

    log:Info("Wayfaring Mod Status:")
    for k,v in pairs(config) do
        log:Info("  " .. k .. ": " .. tostring(v))
    end
end

local function resetConfig()
    local mod, config, db, log = GetModStuff()
    if not config or not db or not log or not mod then return end

    log:Info("Resetting Wayfaring configuration to defaults.")
    for k,v in pairs(WayfaringConfig.defaultConfig) do
        config[k] = v
    end

    KCDUtils.Config.SaveAll(mod.Name, config)
    KCDUtils.Menu.BuildWithDB(mod)
    KCDUtils.UI.ShowNotification("@ui_wayfaring_config_reset")
    log:Info("Wayfaring configuration reset to defaults.")
end

local function printHelp()
    local mod, config, db, log = GetModStuff()
    if not log then return end

    log:Info("Wayfaring Mod Commands:")
    log:Info("  wayfaring_show_status - Show current config")
    log:Info("  wayfaring_reset       - Reset config to defaults")
    log:Info("  wayfaring_help        - Show command help")
end

------------------------------------------------------------
-- Binding annotations for KCD2 Keybinder integration
-- @bindingCommand defines the console command string
-- @bindingMap specifies the context in which the keybind is active
------------------------------------------------------------
--- @bindingCommand wayfaring_show_status
--- @bindingMap movement
KCDUtils.Command.AddFunction("wayfaring", "show_status", showStatus, "Show current configuration and status")
KCDUtils.Command.AddFunction("wayfaring", "reset", resetConfig, "Reset configuration to defaults")
KCDUtils.Command.AddFunction("wayfaring", "help", printHelp, "Show command help")
