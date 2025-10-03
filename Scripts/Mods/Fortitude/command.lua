Fortitude = Fortitude or {}

local function GetModStuff()
    local mod = Fortitude
    if not mod then return nil, nil, nil, nil end
    local config = mod.Config
    local db     = mod.DB
    local log    = mod.Logger
    return mod, config, db, log
end

local function showPlayerStatus()
    local mod, config, db, log = GetModStuff()
    if not config or not log then return end

    log:Info("Fortitude Mod Player Status:")
    for k, v in pairs(config) do
        if type(k) == "string" and k:match("^player_") then
            log:Info("  " .. k .. ": " .. tostring(v))
        end
        if type(k) == "string" and k:match("^distance_") then
            log:Info("  " .. k .. ": " .. tostring(v))
        end
    end
end

local function resetConfig()
    local mod, config, db, log = GetModStuff()
    if not config or not db or not log or not mod then return end

    log:Info("Resetting Fortitude configuration to defaults.")
    for k,v in pairs(FortitudeConfig.defaultConfig) do
        config[k] = v
    end

    KCDUtils.Config.SaveAll(mod.Name, config)
    KCDUtils.Menu.BuildWithDB(mod)
    KCDUtils.UI.ShowNotification("@ui_fortitude_config_reset")
    log:Info("Fortitude configuration reset to defaults.")
end

local function printHelp()
    local mod, config, db, log = GetModStuff()
    if not log then return end

    log:Info("Fortitude Mod Commands:")
    log:Info("  fortitude_show_status - Show current config")
    log:Info("  fortitude_reset       - Reset config to defaults")
    log:Info("  fortitude_help        - Show command help")
end

--- @bindingCommand fortitude_show_status
--- @bindingMap movement
KCDUtils.Command.AddFunction("fortitude", "show_status", showPlayerStatus, "Show current configuration and status")
KCDUtils.Command.AddFunction("fortitude", "reset", resetConfig, "Reset configuration to defaults")
KCDUtils.Command.AddFunction("fortitude", "help", printHelp, "Show command help")
