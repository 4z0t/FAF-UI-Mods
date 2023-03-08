local Enhancements = import("Enhancements.lua")
local EnhanceCommon = import("/lua/enhancementcommon.lua")
local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")

local LuaQ = UMT.LuaQ


function HasPrerequisite(unit, prerequisite)

    local id = unit:GetEntityId()

    local existingEnhancements = EnhanceCommon.GetEnhancements(id) or {}
    local enhancementQueue = EnhancementQueueFile.getEnhancementQueue()
    local orderedEnhancements = enhancementQueue[id] or {}

    local pre = existingEnhancements | LuaQ.contains(prerequisite)

    return pre or orderedEnhancements | LuaQ.first(function(tbl)
        return tbl.ID == prerequisite
    end)
end

function UpgradeTech(unit)

    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    if HasPrerequisite(unit, "AdvancedEngineering") then
        Enhancements.OrderUnitEnhancement(unit, "T3Engineering")
    else
        Enhancements.OrderUnitEnhancement(unit, "AdvancedEngineering")
    end

end

function UpgradeRas(unit)

    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    if HasPrerequisite(unit, "ResourceAllocation") then
        Enhancements.OrderUnitEnhancement(unit, "ResourceAllocationAdvanced")
    else
        Enhancements.OrderUnitEnhancement(unit, "ResourceAllocation")
    end

end

function UpgradeTele(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    Enhancements.OrderUnitEnhancement(unit, "Teleporter")
end

local gunUpgradeMap =
{
    ["url0001"] = "CoolingUpgrade",
    ["uel0001"] = "HeavyAntiMatterCannon",
    ["xsl0001"] = "RateOfFire",
}

---comment
---@param unit UserUnit
function UpgradeGun(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    local upgrade = gunUpgradeMap[unit:GetBlueprint().BlueprintId:lower()]
    if not upgrade then return end

    Enhancements.OrderUnitEnhancement(unit, upgrade)
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

function OrderTechUpgrade()
    ApplyToSelectedUnits(UpgradeTech)
end

function OrderRASUpgrade()
    ApplyToSelectedUnits(UpgradeRas)
end

function OrderTeleUpgrade()
    ApplyToSelectedUnits(UpgradeTele)
end

function OrderGunUpgrade()
    ApplyToSelectedUnits(UpgradeGun)
end
