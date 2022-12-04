---@module "ColorUtils"
local ColorUtils = import("ColorUtils.lua")

local Utils = import("Utils.lua")

local function RGBA(color)
    if string.len(color) == 9 then -- #rrggbbaa -- > aarrggbb
        return string.sub(color, 8) .. string.sub(color, 2, 7)
    elseif string.len(color) == 7 then -- #rrggbb -- > rrggbb
        return 'ff' .. string.sub(color, 2)
    else
        return -- no color
    end
end

local normalMassColor = RGBA '#45a329'
local normalEnergyColor = RGBA '#f7c70f'

local overMassColor = RGBA "#68e344"
local overEnergyColor = RGBA "#faf202"


local normalUncheckedColor = RGBA "#3f3f3f"
local overUncheckedColor = RGBA "#555555"


local normalCheckedColor = RGBA "#e0e0e0"
local overCheckedColor = RGBA "#f0f0f0"





--[[
-- local categoriesToCollect = {
--     land = categories.LAND,
--     air = categories.AIR,
--     naval = categories.NAVAL,
--     cdr = categories.COMMAND,
--     sacu = categories.SUBCOMMANDER,
--     engineer = categories.ENGINEER,
--     tech1 = categories.TECH1,
--     tech2 = categories.TECH2,
--     tech3 = categories.TECH3,
--     experimental = categories.EXPERIMENTAL,
--     structures = categories.STRUCTURE,
--     transportation = categories.TRANSPORTATION
-- }

--armyscore:
-- ArmyScore[index] = {
--     faction = brain:GetFactionIndex(),
--     name = brain.Nickname,
--     type = '',
--     general = {
--         score = 0,
--         lastupdatetick = 0,
--         kills = {
--             count = 0,
--             mass = 0,
--             energy = 0
--         },
--         built = {
--             count = 0,
--             mass = 0,
--             energy = 0
--         },
--         lost = {
--             count = 0,
--             mass = 0,
--             energy = 0
--         },
--         currentunits = 0,
--         currentcap = 0
--     },
--     blueprints = {}, -- filled dynamically below
--     units = {},      -- filled dynamically below
--     resources = {
--         massin = {
--             total = 0,
--             rate = 0,
--             reclaimed = 0,
--             reclaimRate = 0
--         },
--         massout = {
--             total = 0,
--             rate = 0,
--             excess = 0
--         },
--         energyin = {
--             total = 0,
--             rate = 0,
--             reclaimed = 0,
--             reclaimRate = 0
--         },
--         energyout = {
--             total = 0,
--             rate = 0,
--             excess = 0
--         },
--         storage = {
--             storedMass = 0,
--             storedEnergy = 0,
--             maxMass = 0,
--             maxEnergy = 0
--         }
--     }
-- }
-- for categoryName, category in categoriesToCollect do
--     ArmyScore[index].units[categoryName] = {
--         kills = 0,
--         built = 0,
--         lost = 0
--     }
-- end

]]



checkboxes = {
    { --scores
        {
            tooltip = "score-points",
            title = "Army score",
            description = "Score points of army",
            text = "S",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.score
            end
        },
        {
            tooltip = "kills-built-ratio",
            title = "Kills-built ratio",
            description = "Ratio of killed units to built",
            text = "B",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                if score.general.built.mass == 0 then
                    return 0, Utils.FormatRatioNumber
                end
                return score.general.kills.mass / score.general.built.mass, Utils.FormatRatioNumber
            end
        },
        {
            tooltip = "kills-loses-ratio",
            title = "Kills-loses ratio",
            description = "Ratio of killed units to lost",
            text = "K",
            nu = RGBA "",
            nc = RGBA "#ff0000",
            ou = RGBA "",
            oc = RGBA "#ff2222",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                if score.general.lost.mass == 0 then
                    return 0, Utils.FormatRatioNumber
                end
                return score.general.kills.mass / score.general.lost.mass, Utils.FormatRatioNumber
            end
        },

    },
    { --mass
        {
            tooltip = "mass-income",
            title = "Mass income",
            description = "Mass income of an army",
            text = "M",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.massin.rate * 10
            end
        },
        {
            tooltip = "mass-total",
            title = "Total Mass",
            description = "Total amount of mass got by army",
            text = "T",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.massin.total
            end
        },
        {
            tooltip = "mass-reclaim",
            title = "Reaclaimed Mass",
            description = "Total amount of reaclaimed mass by army",
            text = "R",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.massin.reclaimed
            end
        },

    },
    { --energy
        {
            tooltip = "energy-income",
            title = "Energy income",
            description = "Energy income of an army",
            text = "E",
            nu = RGBA "",
            nc = normalEnergyColor,
            ou = RGBA "",
            oc = overEnergyColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.energyin.rate * 10
            end
        },
        {
            tooltip = "energy-total",
            title = "Total Energy",
            description = "Total amount of energy got by army",
            text = "T",
            nu = RGBA "",
            nc = normalEnergyColor,
            ou = RGBA "",
            oc = overEnergyColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.energyin.total
            end
        },
        {
            tooltip = "energy-reclaim",
            title = "Reaclaimed Energy",
            description = "Total amount of reaclaimed energy by army",
            text = "R",
            nu = RGBA "",
            nc = normalEnergyColor,
            ou = RGBA "",
            oc = overEnergyColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.energyin.reclaimed
            end
        },

    },
    { --total
        {
            tooltip = "total-mass-killed",
            title = "Mass killed",
            description = "Total amount of mass killed by army",
            text = "T",
            nu = RGBA "",
            nc = RGBA "#ff0000",
            ou = RGBA "",
            oc = RGBA "#ff2222",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.kills.mass
            end
        },
        {
            tooltip = "total-mass-rate",
            title = "Mass rate",
            description = "Mass rate of army",
            text = "T",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return (score.resources.massin.rate - score.resources.massout.rate) * 10
            end
        },

        {
            tooltip = "total-mass-collected",
            title = "Total Mass",
            description = "Total amount of mass got by army",
            text = "T",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.resources.massin.total
            end
        }
    },
    { --units
        {
            tooltip = "all-units",
            title = "All units",
            description = "Amount of all units",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.currentunits
            end
        },
        {
            tooltip = "naval-units",
            title = "Naval units",
            description = "Amount of naval units",
            text = "N",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.units.naval.built - score.units.naval.lost
            end
        },
        {
            tooltip = "air-units",
            title = "Air units",
            description = "Amount of air units",
            text = "A",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.units.air.built - score.units.air.lost
            end
        },
        {
            tooltip = "land-units",
            title = "Land units",
            description = "Amount of land units",
            text = "L",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.units.land.built - score.units.land.lost
            end
        },
        {
            tooltip = "sacu-units",
            title = "SACU",
            description = "Amount of SACUs",
            text = "S",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.units.sacu.built - score.units.sacu.lost
            end
        },
        {
            tooltip = "experimental-units",
            title = "EXP",
            description = "Amount of EXPs",
            text = "E",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.units.experimental.built - score.units.experimental.lost
            end
        },
    }
}
do
    local tooltips = import('/lua/ui/help/tooltips.lua').Tooltips
    for name, category in checkboxes do
        for i, checkbox in category do
            checkbox.nc = checkbox.nc or normalCheckedColor
            checkbox.oc = checkbox.oc or overCheckedColor

            checkbox.nu = checkbox.nu or normalUncheckedColor
            checkbox.ou = checkbox.ou or overUncheckedColor

            checkbox.du = checkbox.du or ColorUtils.ColorMult(checkbox.nu, 0.8)
            checkbox.dc = checkbox.dc or ColorUtils.ColorMult(checkbox.nc or RGBA "#ffffff", 0.8)

            checkbox.GetData = checkbox.GetData or function(armyScore) return 0 end

            tooltips[checkbox.tooltip] = {
                title = checkbox.title,
                description = checkbox.description
            }
        end
    end
end
