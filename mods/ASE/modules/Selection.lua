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
    NAVAL = categories.NAVAL,
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

function FilterLayer(selection)
    local filtered = EntityCategoryFilterDown(layerCategory[activeLayer], selection)
    if table.empty(filtered) then
        if isAuto then
            AutoLayer(selection)
        end
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
