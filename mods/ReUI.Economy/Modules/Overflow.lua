local Selection = import('/lua/ui/game/selection.lua')

local GetFocusArmy = GetFocusArmy
local GetSelectedUnits = GetSelectedUnits
local GameTick = GameTick
local LOG = LOG
local math = math
local table = table

local SCAN_INTERVAL_TICKS = 10

local currentArmy = false
local lastReclaimed = 0
local lastScanTick = false
local cachedOverflow = 0
local lastError = false

local function Reset(army, tick, totals)
    currentArmy = army
    lastScanTick = tick
    lastReclaimed = totals.reclaimed.ENERGY or 0
    cachedOverflow = 0
end

local function SumOwnEnergyProduction()
    local production = 0

    Selection.Hidden(function()
        -- ENERGYPRODUCTION covers power generators, hydrocarbon plants,
        -- ACUs, SACUs and other units that currently produce energy.
        UISelectionByCategory('ENERGYPRODUCTION', false, false, false, false)
        local units = GetSelectedUnits()
        if not units then
            return
        end

        for i = 1, table.getn(units) do
            local unit = units[i]
            if unit and not unit:IsDead() then
                local econ = unit:GetEconData()
                production = production + (econ and econ.energyProduced or 0)
            end
        end
    end)

    return production
end

local function Calculate(totals, tps)
    local army = GetFocusArmy()
    if not army or army < 1 then
        currentArmy = false
        lastScanTick = false
        cachedOverflow = 0
        return cachedOverflow
    end

    local tick = GameTick()
    if currentArmy ~= army or not lastScanTick then
        Reset(army, tick, totals)
        return cachedOverflow
    end

    local ticksPassed = tick - lastScanTick
    if ticksPassed < SCAN_INTERVAL_TICKS then
        return cachedOverflow
    end

    local reclaimed = totals.reclaimed.ENERGY or 0
    local reclaimRate = (reclaimed - lastReclaimed) / ticksPassed * tps
    local ownProduction = SumOwnEnergyProduction()

    -- A focus-army change during the hidden selection invalidates both the
    -- selected units and the economy totals used for this sample.
    if GetFocusArmy() ~= army then
        currentArmy = false
        lastScanTick = false
        cachedOverflow = 0
        return cachedOverflow
    end

    local totalIncome = (totals.income.ENERGY or 0) * tps
    cachedOverflow = math.max(0, totalIncome - reclaimRate - ownProduction)
    lastReclaimed = reclaimed
    lastScanTick = tick

    return cachedOverflow
end

function Update(totals, tps)
    local ok, overflow = pcall(Calculate, totals, tps)
    if ok then
        lastError = false
        return overflow
    end

    if overflow ~= lastError then
        lastError = overflow
        LOG('ReUI.Economy Overflow ERROR: ' .. tostring(overflow))
    end

    return cachedOverflow
end
