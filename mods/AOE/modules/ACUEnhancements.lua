local Enhancements = import("Enhancements.lua")


function UpgradeTech(unit)

    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    if Enhancements.HasPrerequisite(unit, "AdvancedEngineering") then
        Enhancements.OrderUnitEnhancement(unit, "T3Engineering")
    else
        Enhancements.OrderUnitEnhancement(unit, "AdvancedEngineering")
    end

end

function UpgradeRas(unit)

    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    if Enhancements.HasPrerequisite(unit, "ResourceAllocation") then
        Enhancements.OrderUnitEnhancement(unit, "ResourceAllocationAdvanced")
    else
        Enhancements.OrderUnitEnhancement(unit, "ResourceAllocation")
    end

end

function UpgradeTele(unit)
    Enhancements.OrderUnitEnhancement(unit, "Teleporter")
end

local gunUpgradeMap =
{
    ["url0001"] = "CoolingUpgrade",
    ["uel0001"] = "HeavyAntiMatterCannon",
    ["xsl0001"] = "RateOfFire",
    ["ual0001"] = "HeatSink",
}


---@param unit UserUnit
function UpgradeGun(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    local upgrade = gunUpgradeMap[unit:GetBlueprint().BlueprintId:lower()]
    if not upgrade then return end

    Enhancements.OrderUnitEnhancement(unit, upgrade)
end

local specialUpgradeMap =
{
    ["url0001"] = "MicrowaveLaserGenerator",
    ["uel0001"] = "TacticalNukeMissile",
    ["xsl0001"] = "BlastAttack",
    ["ual0001"] = "ChronoDampener",
}


---@param unit UserUnit
function UpgradeSpecial(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    local upgrade = specialUpgradeMap[unit:GetBlueprint().BlueprintId:lower()]
    if not upgrade then return end

    Enhancements.OrderUnitEnhancement(unit, upgrade)
end

local nanoUpgrades = {
    ["url0001"] = { "StealthGenerator", "FAF_SelfRepairSystem", "CloakingGenerator", },
    ["uel0001"] = { "Shield", "ShieldGeneratorField", },
    ["xsl0001"] = { "DamageStabilization", "DamageStabilizationAdvanced", },
    ["ual0001"] = { "Shield", "ShieldHeavy", },
}

---@param unit UserUnit
function UpgradeNano(unit)
    local bpEnhancements = Enhancements.GetBluePrintEnhancements(unit:GetBlueprint())
    if not bpEnhancements then return end

    local bpId = unit:GetBlueprint().BlueprintId:lower()
    local upgrades = nanoUpgrades[bpId]
    if not upgrades then return end

    for _, upgrade in upgrades do
        if not Enhancements.HasPrerequisite(unit, upgrade) then
            Enhancements.OrderUnitEnhancement(unit, upgrade)
            break
        end
    end
end

function OrderTechUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeTech)
end

function OrderRASUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeRas)
end

function OrderTeleUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeTele)
end

function OrderGunUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeGun)
end

function OrderNanoUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeNano)
end

function OrderSpecialUpgrade()
    Enhancements.ApplyToSelectedUnits(UpgradeSpecial)
end
