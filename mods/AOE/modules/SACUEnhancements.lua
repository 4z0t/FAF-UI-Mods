local Enhancements = import("Enhancements.lua")


local engUpgradeMap =
{
    ["url0301"] = "Switchback",
    ["uel0301"] = "Pod",
    ["xsl0301"] = "EngineeringThroughput",
    ["ual0301"] = "EngineeringFocusingModule",
}

---@param unit UserUnit
function UpgradeTech(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    local upgrade = engUpgradeMap[unit:GetBlueprint().BlueprintId:lower()]
    if not upgrade then return end

    Enhancements.OrderUnitEnhancement(unit, upgrade)
end

function OrderTechUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeTech)
end

