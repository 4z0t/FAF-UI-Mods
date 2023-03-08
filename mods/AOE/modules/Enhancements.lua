local EnhanceCommon = import("/lua/enhancementcommon.lua")
local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")

local LuaQ = UMT.LuaQ


function HasOrderedUpgrades(unit)
    if not unit:IsIdle() then
        local cmdqueue = unit:GetCommandQueue()
        if cmdqueue and cmdqueue[1] and cmdqueue[1].type == 'Script' then
            return true
        end
    end
    return false
end

---@param bp Blueprint
function GetBluePrintEnhancements(bp)
    if not bp.Enhancements then return end

    --- this bullshit cames from construvtion.lua
    return bp.Enhancements | LuaQ.foreach(function(name, tbl)
        if name == "Slots" then return end
        tbl.ID = name
        tbl.UnitID = bp.BlueprintId
    end)
end

function GetAllInstalledEnhancements(unit)

    local id = unit:GetEntityId()

    local bpEnhancements = GetBluePrintEnhancements(unit:GetBlueprint()) or {}
    local existingEnhancements = EnhanceCommon.GetEnhancements(id) or {}

    local enhancements = {}

    for _, enh in existingEnhancements do
        table.insert(enhancements, enh)
        if bpEnhancements[enh].Prerequisite then
            table.insert(enhancements, bpEnhancements[enh].Prerequisite)
        end
    end

    return enhancements
end

---@param unit UserUnit
---@param enhancement any
function OrderUnitEnhancement(unit, enhancement)

    local bpEnhancements = GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    if not bpEnhancements[enhancement] then return end

    if GetAllInstalledEnhancements(unit) | LuaQ.contains(enhancement) then return end

    local id = unit:GetEntityId()

    local existingEnhancements = EnhanceCommon.GetEnhancements(id) or {}
    local enhancementQueue = EnhancementQueueFile.getEnhancementQueue()
    local orderedEnhancements = enhancementQueue[id] or {}


    local orders = {}
    local prerequisite = bpEnhancements[enhancement].Prerequisite

    local function RemoveUpgradeInRequiredSlot()
        if table.empty(existingEnhancements) then return end

        local slot = bpEnhancements[enhancement].Slot

        for _, enh in existingEnhancements do
            if bpEnhancements[enh].Slot == slot and enh ~= prerequisite then
                table.insert(orders, enh .. "Remove")
            end
        end

    end

    RemoveUpgradeInRequiredSlot()

    if prerequisite then
        local isInstalledPrerequisite = existingEnhancements | LuaQ.contains(prerequisite)

        local isQueudPrerequisite = orderedEnhancements | LuaQ.first(function(tbl)
            return tbl.ID == prerequisite
        end)

        if not isInstalledPrerequisite and not isQueudPrerequisite then
            table.insert(orders, prerequisite)
        end
    end

    table.insert(orders, enhancement)


    local cleanOrder = not HasOrderedUpgrades(unit)


    for _, order in orders do
        IssueCommand("UNITCOMMAND_Script",
            {
                TaskName = 'EnhanceTask',
                Enhancement = order
            },
            cleanOrder)
        cleanOrder = false
    end


end

function ApplyToSelectedUnits(fn)
    local selection = GetSelectedUnits()
    if not selection then return end

    UMT.Units.HiddenSelect(function()
        for _, unit in selection do
            SelectUnits { unit }
            fn(unit)
        end
    end)
end

function HasPrerequisite(unit, prerequisite)

    local id = unit:GetEntityId()

    local installedEnhancements = GetAllInstalledEnhancements(unit)
    local enhancementQueue = EnhancementQueueFile.getEnhancementQueue()
    local orderedEnhancements = enhancementQueue[id] or {}

    local pre = installedEnhancements | LuaQ.contains(prerequisite)

    return pre or orderedEnhancements | LuaQ.first(function(tbl)
        return tbl.ID == prerequisite
    end)
end

function OrderEnhancement(enhancement)
    ApplyToSelectedUnits(function(unit)
        OrderUnitEnhancement(unit, enhancement)
    end)
end
