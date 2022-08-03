---@module "ColorUtils"
local ColorUtils = import("ColorUtils.lua")


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

local normalCheckedColor = ColorUtils.ColorMult(overUncheckedColor, 2)
local overCheckedColor = ColorUtils.ColorMult(normalCheckedColor, 1.4)





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

--checkbox

    -- normalUnchecked
    -- normalChecked
    -- overUnchecked
    -- overChecked
    -- disabledUnchecked
    -- disabledChecked
    -- GetData = function (armyScore) return 0 end
    
]]



checkboxes = {
    { --scores
        {
            tooltip = "kills-built-ratio",
            text = "B",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.kills.mass / score.general.built.mass
            end
        },
        {
            tooltip = "kills-loses-ratio",
            text = "K",
            nu = RGBA "",
            nc = RGBA "#ff0000",
            ou = RGBA "",
            oc = RGBA "#ff2222",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.kills.mass / score.general.lost.mass
            end
        },
        {
            tooltip = "score-points",
            text = "S",
            nu = RGBA "",
            nc = RGBA "#e0e0e0",
            ou = RGBA "",
            oc = RGBA "#f0f0f0",
            du = RGBA "",
            dc = RGBA "",
            GetData = function(score)
                return score.general.score
            end
        }
    },
    { --mass
        {
            tooltip = "mass-total",
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
        {
            tooltip = "mass-income",
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
        }
    },
    { --energy
        {
            tooltip = "energy-total",
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
        {
            tooltip = "energy-income",
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
        }
    },
    { --total
        {
            tooltip = "total-mass-in",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "total-mass-killed",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "total-mass-collected",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        }
    },
    { --units
        {
            tooltip = "naval-units",
            text = "N",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "air-units",
            text = "A",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "land-units",
            text = "L",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "all-units",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        }
    }
}

for name, category in checkboxes do
    for i, checkbox in category do
        checkbox.nc = checkbox.nc or normalCheckedColor
        checkbox.oc = checkbox.oc or overCheckedColor

        checkbox.nu = checkbox.nu or normalUncheckedColor
        checkbox.ou = checkbox.ou or overUncheckedColor

        checkbox.du = checkbox.du or ColorUtils.ColorMult(checkbox.nu, 0.8)
        checkbox.dc = checkbox.dc or ColorUtils.ColorMult(checkbox.nc or RGBA "#ffffff", 0.8)

        checkbox.GetData = checkbox.GetData or function(armyScore) return 0 end
    end
end
