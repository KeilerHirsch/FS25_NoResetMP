--
-- NoResetMP
--
-- The Man, The Mythos, The Legend : KeilerHirsch
--
-- Hardcore multiplayer realism for Farming Simulator 25:
-- removes the free player-triggered "reset vehicle to shop" option in
-- multiplayer, while leaving singleplayer and the engine's own
-- out-of-world safety net completely untouched.
--
-- HOW IT WORKS (verified against the FS25 base source, gameSource.zip):
--   * The player "reset to shop" action is gated by Vehicle:getCanBeReset()
--     (dataS/scripts/vehicles/Vehicle.lua:4183). The game itself uses the
--     same mechanism: ProtectedBundleVehicle sets self.canBeReset = false to
--     make a vehicle non-resettable.
--   * We overwrite Vehicle.getCanBeReset so it returns false in multiplayer.
--     The Attachable specialization chains through superFunc, so the block
--     also propagates to implements; Locomotive/Pallet/Rideable are already
--     non-resettable in the base game.
--   * The engine out-of-world safety net (Vehicle.lua ~1928-1963) calls
--     self:reset(true, nil, true) DIRECTLY and does NOT consult
--     getCanBeReset(). It therefore keeps working - a vehicle that genuinely
--     leaves the world is still rescued. We never touch Vehicle:reset itself,
--     so nothing gets bricked.
--   * There is no vehicle-reset network event and no in-vehicle recover
--     action in the base game, so this single gate is the complete choke.
--
-- Multiplayer detection uses g_currentMission.missionDynamicInfo.isMultiplayer,
-- the standard FS idiom (used by the base game and by mods such as ADS). The
-- field's shape is not pinned to a source line the way getCanBeReset is, so the
-- access below is written defensively.
--
-- Author: KeilerHirsch
-- License: MIT
--

NoResetMP = {}

NoResetMP.VERSION = "1.0.0.0"

-- Hardcore switch. v1 is always on; a later version can turn this into a
-- server-side setting without touching the hook logic below.
NoResetMP.DENY_IN_MP = true

-- Set by install(): true once the hook is in place, false if it could not be
-- installed. Lets other code / tests observe whether the mod is actually active.
NoResetMP.installed = false

---Emit a loud, single line to the log, tolerating a missing Logging global.
-- @param string level "error", "warning" or "info"
-- @param string message the message (mod tag + version are prepended)
local function logLine(level, message)
    local line = string.format("[NoResetMP %s] %s", NoResetMP.VERSION, message)
    if Logging ~= nil and Logging[level] ~= nil then
        Logging[level](line)
    else
        print(line)
    end
end

---Pure decision function - no engine access, fully unit-testable.
-- Contract: both arguments are expected to be booleans. Any non-true value
-- (nil, false, or garbage) is treated as false via strict equality, so the
-- function fails safe (allow reset) rather than coercing truthy junk to "deny".
-- @param boolean isMultiplayer whether the current mission is multiplayer
-- @param boolean enabled whether the hardcore block is enabled
-- @return boolean deny true if the player reset must be denied
function NoResetMP.shouldDenyReset(isMultiplayer, enabled)
    return enabled == true and isMultiplayer == true
end

---Safely determine whether the current mission is a multiplayer session.
-- Returns false when no mission is loaded yet (e.g. during early load) or when
-- missionDynamicInfo is not a table, so we never accidentally block anything
-- outside an active multiplayer game and never throw from inside the override.
-- @return boolean isMultiplayer
function NoResetMP.isMultiplayer()
    local mission = g_currentMission
    if mission == nil or type(mission.missionDynamicInfo) ~= "table" then
        return false
    end

    return mission.missionDynamicInfo.isMultiplayer == true
end

---Overwrite for Vehicle:getCanBeReset.
-- In multiplayer (with the block enabled) no vehicle can be reset by the
-- player; otherwise the original game behaviour is preserved.
-- @param table self the vehicle instance
-- @param function superFunc the original Vehicle:getCanBeReset
-- @return boolean canBeReset
function NoResetMP.getCanBeReset(self, superFunc)
    if NoResetMP.shouldDenyReset(NoResetMP.isMultiplayer(), NoResetMP.DENY_IN_MP) then
        return false
    end

    return superFunc(self)
end

---Install the hook once, at mod load time (before vehicle types are
-- finalized, so the override sits at the bottom of every specialization chain).
-- Fails LOUD (Logging.error) and leaves NoResetMP.installed = false if the
-- engine surface it needs is missing, so the mod never silently no-ops.
function NoResetMP.install()
    if NoResetMP.installed then
        return
    end

    if Vehicle == nil or Vehicle.getCanBeReset == nil
        or Utils == nil or Utils.overwrittenFunction == nil then
        logLine("error", "engine hook API missing (Vehicle.getCanBeReset / Utils.overwrittenFunction) - mod INACTIVE, resets are NOT blocked. Check for an FS25 update changing the vehicle API.")
        return
    end

    Vehicle.getCanBeReset = Utils.overwrittenFunction(Vehicle.getCanBeReset, NoResetMP.getCanBeReset)
    NoResetMP.installed = true
    logLine("info", "loaded - player vehicle reset is blocked in multiplayer.")
end

NoResetMP.install()
