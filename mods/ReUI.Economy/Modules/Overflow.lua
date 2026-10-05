local GetFocusArmy = GetFocusArmy
local GameTick = GameTick
local LOG = LOG
local math = math

local SCAN_INTERVAL_TICKS = 10
local PRODUCER_REFRESH_TICKS = 50

local currentArmy = false
local lastReclaimed = 0
local lastScanTick = false
local lastProducerRefreshTick = false
local cachedOverflow = 0
local lastError = false
local producers = {}

local function Reset(army, tick, totals)
    currentArmy = army
    lastScanTick = tick
    lastProducerRefreshTick = false
    lastReclaimed = totals.reclaimed.ENERGY or 0
    cachedOverflow = 0
    producers = {}
end

local function RefreshProducers(tick)
    if lastProducerRefreshTick
        and tick - lastProducerRefreshTick < PRODUCER_REFRESH_TICKS then
        return
    end

    lastProducerRefreshTick = tick
    producers = {}

    -- ENERGYPRODUCTION covers power generators, hydrocarbon plants,
    -- ACUs, SACUs and other units that currently produce energy.
    for id, unit in ReUI.Units.Get() do
        if not unit:IsDead() then
            local blueprint = unit:GetBlueprint()
            if blueprint.CategoriesHash.ENERGYPRODUCTION then
                producers[id] = unit
            end
        end
    end
end

local function SumOwnEnergyProduction(tick)
    RefreshProducers(tick)

    local production = 0

    for id, unit in producers do
        if unit:IsDead() then
            producers[id] = nil
        else
            local econ = unit:GetEconData()
            production = production + (econ and econ.energyProduced or 0)
        end
    end

    return production
end

local function Calculate(totals, tps)
    local army = GetFocusArmy()
    if not army or army < 1 then
        currentArmy = false
        lastScanTick = false
        lastProducerRefreshTick = false
        cachedOverflow = 0
        producers = {}
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
    local ownProduction = SumOwnEnergyProduction(tick)

    -- A focus-army change while enumerating the shared unit cache invalidates
    -- both its units and the economy totals used for this sample.
    if GetFocusArmy() ~= army then
        currentArmy = false
        lastScanTick = false
        lastProducerRefreshTick = false
        cachedOverflow = 0
        producers = {}
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
