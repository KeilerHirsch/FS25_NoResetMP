-- luacheck configuration for FS25_NoResetMP
-- FS25 runs LuaJIT (Lua 5.1 semantics).
std = "lua51"

-- Globals this mod defines.
globals = {
    "NoResetMP",
}

-- Engine-provided globals the mod reads (never assigns).
read_globals = {
    "Vehicle",
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
