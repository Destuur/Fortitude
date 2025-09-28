-- main.lua
--[[
    Main logic template for Kingdom Come: Deliverance II mod
    Generated with VS Code Extension

    Mod Name: Wayfaring
    Namespace / Table: Wayfaring
    Description: Handles in-game logic, menu events, and notifications.
--]]

------------------------------------------------------------
-- Ensure the global mod table exists
-- Wayfaring acts as both namespace and mod object
------------------------------------------------------------
Wayfaring = Wayfaring or {}

-- Shortcuts for convenience
local mod    = Wayfaring
local config = mod and mod.Config
local db     = mod and mod.DB
local log    = mod and mod.Logger

------------------------------------------------------------
-- Event: called when the in-game configuration menu changes
-- This updates the config and triggers mod-specific logic
------------------------------------------------------------
mod.OnMenuChanged:Add(function(newConfig)
    -- Update internal config values
    WayfaringConfig.OnMenuChanged(mod, newConfig)

    -- Optional: trigger custom mod logic after config change
    Wayfaring:DoStuff()
end)

------------------------------------------------------------
-- Example function: perform an action in-game
-- Can be called from events, commands, or other scripts
------------------------------------------------------------
function Wayfaring:DoStuff()
    KCDUtils.UI.ShowNotification("Doing stuff in Wayfaring mod!")
end

------------------------------------------------------------
-- Another example function, e.g., called on gameplay start
------------------------------------------------------------
function Wayfaring:DoMoreStuff()
    KCDUtils.UI.ShowNotification("Doing more stuff in Wayfaring mod!")
end