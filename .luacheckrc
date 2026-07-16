-- luacheck configuration for FS25_NoResetMP
-- FS25 runs LuaJIT (Lua 5.1 semantics).
std = "lua51"

-- Globals this mod defines.
globals = {
    "NoResetMP",
    -- Vehicle is engine-provided but WRITABLE here on purpose: patching
    -- Vehicle.getCanBeReset via Utils.overwrittenFunction IS the mod. Listing it
    -- read-only made luacheck flag the mod's own mechanism as a warning.
    "Vehicle",
}

-- Engine-provided globals the mod only reads.
read_globals = {
    "Utils",
    "Logging",
    "g_currentMission",
}

-- The test file loads the mod with stubbed engine globals.
files["tests/"] = {
    std = "+busted",
    globals = {
        "Vehicle",
        "Utils",
        "Logging",
        "g_currentMission",
        "NoResetMP",
    },
}
