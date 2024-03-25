local Lock = import("Lock.lua")
local IsLocked = Lock.IsLocked
local IsLockEmpty = Lock.IsEmpty
local ContainsLocked = Lock.ContainsLocked
local EntityCategoryFilterDown = EntityCategoryFilterDown
local TableGetN = table.getn


local layers = { "NAVAL", "LAND", "AIR" }
local activeLayer = "LAND"


-- determines whether last selected units not containing active category replace active actegory
local isAuto

local assistBPs = {
    -- t1 scouts
    ["ual0101"] = true, --Spirit
    ["url0101"] = true, --Mole
    ["xsl0101"] = true, --Selen
    ["uel0101"] = true, --Snoop
    -- mobile shields
    ["xsl0307"] = true, --Athanah
    ["uel0307"] = true, --Parashield
    ["ual0307"] = true, --Asylum

    ["url0306"] = true --Deceiver
}

local layerCategory = {
    NAVAL = categories.NAVAL, -- + categories.LAND * categories.HOVER,
    AIR = categories.AIR,
    LAND = categories.LAND,
}

function SetActiveLayer(layer)
    activeLayer = layer
    print("Active layer is " .. layer)
end

function FilterAssisters(selection)
    local newSelection = {}
    local changed = false
    for _, unit in selection do
        local guard = unit:GetGuardedEntity()
        if not (assistBPs[unit:GetBlueprint().BlueprintId:lower()] and guard ~= nil) then
            table.insert(newSelection, unit)
        else
            changed = true
        end
    end

    if table.empty(newSelection) then
        return selection, false
    end
    return newSelection, changed
end

function FilterLocked(selection)
    if IsLockEmpty() or not ContainsLocked(selection) then
        return selection, false
    end
    local newSelection = {}
    local changed = false
    for _, unit in selection do
        if not IsLocked(unit) then
            table.insert(newSelection, unit)
        else
            changed = true
        end
    end
    if table.empty(newSelection) then
        return selection, false
    end
    return newSelection, changed
end

function AutoLayer(selection)
    local newLayer
    for layer, cat in layerCategory do
        if layer ~= activeLayer then
            local units = EntityCategoryFilterDown(cat, selection)
            if not table.empty(units) then
                if newLayer == nil then
                    newLayer = layer
                else
                    return
                end
            end
        end
    end
    if newLayer then
        SetActiveLayer(newLayer)
    end
end

---@type EntityCategory
local exoticUnitsLandCategory = categories.xsl0305 + categories.xal0305 -- sniper bots
    + categories.LAND * categories.MOBILE * categories.SILO -- mmls
    + categories.MOBILE * categories.ARTILLERY * categories.TECH3 -- mobile arty
    + categories.dal0310

-- ---@type EntityCategory
-- local exoticUnitsAirCategory = categories.


function FilterExotic(selection)
    local filtered = EntityCategoryFilterOut(exoticUnitsLandCategory, selection)
    if TableGetN(filtered) == TableGetN(selection) or table.empty(filtered) then
        return selection, false
    end
    return filtered, true
end

local currentDomainOrder = 3
local domainsOrders =
{
    { key = "NAVAL > LAND  > AIR", value = { "NAVAL", "LAND", "AIR" } },
    { key = "NAVAL > AIR   > LAND", value = { "NAVAL", "AIR", "LAND" } },
    { key = "LAND  > AIR   > NAVAL", value = { "LAND", "AIR", "NAVAL" } },
    { key = "LAND  > NAVAL > AIR", value = { "LAND", "NAVAL", "AIR" } },
    { key = "AIR   > LAND  > NAVAL", value = { "AIR", "LAND", "NAVAL" } },
    { key = "AIR   > NAVAL > LAND", value = { "AIR", "NAVAL", "LAND" } },
}


function RotateDomains()
    local k, v = next(domainsOrders, currentDomainOrder)
    if k == nil then
        k = 1
        v = domainsOrders[1]
    end
    print(v.key)
    currentDomainOrder = k
end

function FilterLayer(selection)
    local domainOrder = domainsOrders[currentDomainOrder].value
    local filtered

    for _, domain in domainOrder do
        filtered = EntityCategoryFilterDown(layerCategory[domain], selection)
        if not table.empty(filtered) then
            break
        end
    end

    if table.empty(filtered) then
        return selection, false
    end
    return filtered, (TableGetN(filtered) ~= TableGetN(selection))
end

function Main(_isReplay)
    local Options = UMT.Options.Mods["ASE"]
    Options.autoLayer:Bind(function(var)
        isAuto = var()
    end)
end
