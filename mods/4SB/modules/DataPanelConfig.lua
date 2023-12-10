---@module "ColorUtils"
local ColorUtils = UMT.ColorUtils

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


---@alias CollectedCategory
--- |"land"
--- |"air"
--- |"naval"
--- |"cdr"
--- |"experimental"
--- |"structures"


---@class GeneralStatsScoreData
---@field count  integer
---@field mass  integer
---@field energy integer

---@class GeneralScoreData
---@field score number
---@field lastupdatetick integer
---@field kills GeneralStatsScoreData
---@field built GeneralStatsScoreData
---@field lost GeneralStatsScoreData
---@field currentunits integer
---@field currentcap integer


---@class IncomeStats
---@field total  number
---@field rate  number
---@field reclaimed  number
---@field reclaimRate number

---@class OutcomeStats
---@field total  number
---@field rate  number
---@field excess number

---@class StorageStats
---@field storedMass  number
---@field storedEnergy  number
---@field maxMass  number
---@field maxEnergy number

---@class ResourcesStats
---@field massin IncomeStats
---@field massout OutcomeStats
---@field energyin IncomeStats
---@field energyout OutcomeStats
---@field storage StorageStats


---@class UnitStats
---@field kills integer
---@field built integer
---@field lost integer

---@class CollectedUnitsStats
---@field land UnitStats
---@field air UnitStats
---@field naval UnitStats
---@field cdr UnitStats
---@field experimental UnitStats
---@field structures UnitStats

---@class ArmyScoreData
---@field faction Faction
---@field name string
---@field type BrainType
---@field general GeneralScoreData
---@field units CollectedUnitsStats
---@field resources ResourcesStats


---@alias FormatFunc  fun(num:number) :string

---@alias ScoreDataFunc fun(armyScoreData: ArmyScoreData): number, FormatFunc?

---@class ScoreDataView
---@field  tooltip string
---@field  title string
---@field  description string
---@field  text string
---@field  nu string|nil
---@field  nc string|nil
---@field  ou string|nil
---@field  oc string|nil
---@field  du string|nil
---@field  dc string|nil
---@field  GetData ScoreDataFunc

---@type ScoreDataView[][]
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
            ---@param score ArmyScoreData
            ---@return number
            GetData = function(score)
                return (score.general.score or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                if score.general.built.mass == 0 then return 0, Utils.FormatRatioNumber end
                return (score.general.kills.mass or 0) / (score.general.built.mass or 1), Utils.FormatRatioNumber
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                if score.general.lost.mass == 0 then return 0, Utils.FormatRatioNumber end
                return (score.general.kills.mass or 0) / (score.general.lost.mass or 1), Utils.FormatRatioNumber
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
            ---@param score ArmyScoreData
            ---@return number
            GetData = function(score)
                return (score.resources.massin.rate or 0) * 10
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.massin.total or 0)
            end
        },
        {
            tooltip = "mass-reclaim",
            title = "Reclaimed Mass",
            description = "Total amount of reaclaimed mass by army",
            text = "R",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.massin.reclaimed or 0)
            end
        },
        {
            tooltip = "mass-storage",
            title = "Mass in storage",
            description = "Current amount of mass in storage of an army",
            text = "S",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.storage.storedMass or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.energyin.rate or 0) * 10
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.energyin.total or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.energyin.reclaimed or 0)
            end
        },
        {
            tooltip = "energy-storage",
            title = "Energy in storage",
            description = "Current amount of energy in storage of an army",
            text = "S",
            nu = RGBA "",
            nc = normalEnergyColor,
            ou = RGBA "",
            oc = overEnergyColor,
            du = RGBA "",
            dc = RGBA "",
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.storage.storedEnergy or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.general.kills.mass or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return ((score.resources.massin.rate or 0) - (score.resources.massout.rate or 0)) * 10
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.resources.massin.total or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.general.currentunits or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.units.naval.built or 0) - (score.units.naval.lost or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.units.air.built or 0) - (score.units.air.lost or 0)
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.units.land.built or 0) - (score.units.land.lost or 0)
            end
        },
        -- {
        --     tooltip = "sacu-units",
        --     title = "SACU",
        --     description = "Amount of SACUs",
        --     text = "S",
        --     nu = RGBA "",
        --     nc = RGBA "",
        --     ou = RGBA "",
        --     oc = RGBA "",
        --     du = RGBA "",
        --     dc = RGBA "",
        --     GetData = function(score)
        --         return (score.units.sacu.built or 0) - (score.units.sacu.lost or 0)
        --     end
        -- },
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
            ---@param score ArmyScoreData
            ---@return number, FormatFunc?
            GetData = function(score)
                return (score.units.experimental.built or 0) - (score.units.experimental.lost or 0)
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
