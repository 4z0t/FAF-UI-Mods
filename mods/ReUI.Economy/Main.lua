ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.UI >= 1.4.0",
    "ReUI.UI.Animation >= 1.0.0",
    "ReUI.UI.Controls >= 1.0.0",
    "ReUI.UI.Views >= 1.2.0",
    "ReUI.Options >= 1.0.0"
}

function Main(isReplay)
    local _IsDestroyed = IsDestroyed

    local EconomyHook = ReUI.Core.HookModule "/lua/ui/game/economy.lua"

    function EconomyHook.CreateEconomyBar(field, module)
        return function(parent)
            local options = ReUI.Options.Mods["ReUI.Economy"]
            local scale = options.scale:Raw()

            ---@type EconomyPanel
            local panel = ReUI.Economy.EconomyPanel(parent)
            panel.Layouter.Scale = ReUI.UI.LayoutFunctions.Div(scale, 100)

            options.style:Bind(function(var)
                panel.Layout = ReUI.Economy.Layouts[var()]
            end)

            ReUI.UI.Global["EconomyPanel"] = panel
            module.GUI.bg = panel

            local GM = import("/lua/ui/game/gamemain.lua")
            GM.AddBeatFunction(function()
                panel:Update()
            end, true)

            return panel
        end
    end

    EconomyHook("ToggleEconPanel", function(field, module)
        return function(state)
            local panel = ReUI.UI.Global["EconomyPanel"]

            if _IsDestroyed(panel) then
                return
            end

            if state then
                panel:Expand()
            else
                panel:Contract()
            end

        end
    end)

    EconomyHook("InitialAnimation", function(field, module)
        return function()
            local panel = ReUI.UI.Global["EconomyPanel"]

            if _IsDestroyed(panel) then
                return
            end

            panel:InitialAnimation()
        end
    end)

    EconomyHook("SetLayout", function(field, module)
        return function()
            local panel = ReUI.UI.Global["EconomyPanel"]

            if _IsDestroyed(panel) then
                return
            end

            panel:ReLayout()
        end
    end)

    return {
        Layouts = {
            ["default"] = false,
        },
        EconomyPanel = import("Modules/Panel.lua").EconomyPanel,
    }
end
