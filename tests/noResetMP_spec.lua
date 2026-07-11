--
-- Unit tests for FS25_NoResetMP (busted).
--
-- Run from the mod root with a Lua 5.1 / LuaJIT environment:
--     busted
--
-- The mod calls NoResetMP.install() at load time, which touches the engine
-- globals Vehicle / Utils / Logging. We stub those before loading the script,
-- and reproduce the real Utils.overwrittenFunction composition so the wrapped
-- getCanBeReset can be tested end to end.
--

local function loadMod()
    -- Fresh stubbed engine environment for every load.
    _G.Logging = {
        info = function() end,
        warning = function() end,
    }

    _G.Utils = {
        -- Faithful reproduction of GIANTS' Utils.overwrittenFunction:
        -- the new function is called as newFunc(self, oldFunc, ...).
        overwrittenFunction = function(oldFunc, newFunc)
            return function(self, ...)
                return newFunc(self, oldFunc, ...)
            end
        end,
    }

    -- Original engine getCanBeReset: returns the vehicle's own flag.
    _G.Vehicle = {
        getCanBeReset = function(self)
            return self.canBeReset
        end,
    }

    _G.g_currentMission = nil

    -- Load the mod fresh (clears any previous global state).
    _G.NoResetMP = nil
    dofile("scripts/NoResetMP.lua")

    return _G.NoResetMP
end

local function setMission(isMultiplayer)
    if isMultiplayer == nil then
        _G.g_currentMission = nil
    else
        _G.g_currentMission = {
            missionDynamicInfo = { isMultiplayer = isMultiplayer },
        }
    end
end

describe("NoResetMP.shouldDenyReset (pure logic)", function()
    local mod = loadMod()

    it("denies only when enabled AND multiplayer", function()
        assert.is_true(mod.shouldDenyReset(true, true))
    end)

    it("allows in singleplayer even when enabled", function()
        assert.is_false(mod.shouldDenyReset(false, true))
    end)

    it("allows in multiplayer when disabled", function()
        assert.is_false(mod.shouldDenyReset(true, false))
    end)

    it("treats nil multiplayer as not-multiplayer", function()
        assert.is_false(mod.shouldDenyReset(nil, true))
    end)

    it("treats nil enabled as disabled", function()
        assert.is_false(mod.shouldDenyReset(true, nil))
    end)
end)

describe("NoResetMP.isMultiplayer (safe mission access)", function()
    local mod = loadMod()

    it("is false when no mission is loaded", function()
        setMission(nil)
        assert.is_false(mod.isMultiplayer())
    end)

    it("is false in a singleplayer mission", function()
        setMission(false)
        assert.is_false(mod.isMultiplayer())
    end)

    it("is true in a multiplayer mission", function()
        setMission(true)
        assert.is_true(mod.isMultiplayer())
    end)

    it("is false when missionDynamicInfo is missing", function()
        _G.g_currentMission = {}
        assert.is_false(mod.isMultiplayer())
    end)

    it("is false (no throw) when missionDynamicInfo is a non-table value", function()
        _G.g_currentMission = { missionDynamicInfo = "unexpected" }
        assert.is_false(mod.isMultiplayer())
    end)
end)

describe("Vehicle.getCanBeReset (installed override)", function()
    it("blocks reset in multiplayer regardless of the vehicle flag", function()
        loadMod()
        setMission(true)
        local vehicle = { canBeReset = true }
        assert.is_false(_G.Vehicle.getCanBeReset(vehicle))
    end)

    it("preserves original behaviour in singleplayer (resettable)", function()
        loadMod()
        setMission(false)
        local vehicle = { canBeReset = true }
        assert.is_true(_G.Vehicle.getCanBeReset(vehicle))
    end)

    it("preserves original behaviour in singleplayer (non-resettable)", function()
        loadMod()
        setMission(false)
        local vehicle = { canBeReset = false }
        assert.is_false(_G.Vehicle.getCanBeReset(vehicle))
    end)

    it("does not block outside an active mission", function()
        loadMod()
        setMission(nil)
        local vehicle = { canBeReset = true }
        assert.is_true(_G.Vehicle.getCanBeReset(vehicle))
    end)

    it("honours the disabled switch even in multiplayer", function()
        local mod = loadMod()
        mod.DENY_IN_MP = false
        setMission(true)
        local vehicle = { canBeReset = true }
        assert.is_true(_G.Vehicle.getCanBeReset(vehicle))
    end)
end)

describe("NoResetMP.install (fail-loud + idempotency)", function()
    it("marks the mod as installed on success", function()
        local mod = loadMod()
        assert.is_true(mod.installed)
    end)

    it("does not re-wrap on a second install() call", function()
        local mod = loadMod()
        local wrapped = _G.Vehicle.getCanBeReset
        mod.install()
        assert.are.equal(wrapped, _G.Vehicle.getCanBeReset)
    end)

    it("fails loud and stays uninstalled when the engine hook API is missing", function()
        local errors = {}
        _G.Logging = {
            info = function() end,
            warning = function() end,
            error = function(msg) errors[#errors + 1] = msg end,
        }
        _G.Utils = {
            overwrittenFunction = function(oldFunc, newFunc)
                return function(self, ...) return newFunc(self, oldFunc, ...) end
            end,
        }
        _G.Vehicle = {} -- getCanBeReset missing
        _G.NoResetMP = nil
        dofile("scripts/NoResetMP.lua")

        assert.is_false(_G.NoResetMP.installed)
        assert.is_true(#errors > 0)
    end)
end)
