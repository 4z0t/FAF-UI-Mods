local function RGBA(color)
    if string.len(color) == 9 then -- #rrggbbaa -- > aarrggbb
        return string.sub(color, 2, 7) .. string.sub(color, 8)
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

-- normalUnchecked
-- normalChecked
-- overUnchecked
-- overChecked
-- disabledUnchecked
-- disabledChecked

checkboxes = {
    scores = {
        {
            tooltip = "kills-built-ratio",
            text = "B",
            nu = RGBA "",
            nc = normalMassColor,
            ou = RGBA "",
            oc = overMassColor,
            du = RGBA "",
            dc = RGBA "",
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
        },
        {
            tooltip = "score-points",
            text = "S",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        }
    },
    mass = {
        {
            tooltip = "mass-total",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "mass-reclaim",
            text = "R",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "mass-income",
            text = "M",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        }
    },
    energy = {
        {
            tooltip = "energy-total",
            text = "T",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "energy-reclaim",
            text = "R",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        },
        {
            tooltip = "energy-income",
            text = "E",
            nu = RGBA "",
            nc = RGBA "",
            ou = RGBA "",
            oc = RGBA "",
            du = RGBA "",
            dc = RGBA "",
        }
    },
    total = {
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
    units = {
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
        checkbox.nu = checkbox.nu or normalUncheckedColor
        checkbox.ou = checkbox.ou or overUncheckedColor

    end

end
