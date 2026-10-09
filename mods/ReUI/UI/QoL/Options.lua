local Opt = ReUI.Options.OptionValue


ReUI.Options.Mods["ReUI.UI.QoL"] = {
    movableMenuPanel = Opt(true),
    multifunctionPanelCollapsed = Opt(true),
    menuPanelCollapsed = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.UI.QoL"]
    ReUI.Options.Add("ReUI.UI.QoL", "ReUI.UI.QoL", function(frame)
        return ReUI.Options.Window("ReUI.UI.QoL", function(q)
            q:OptionCheckbox("Movable menu panel", options.movableMenuPanel)
            q:OptionCheckbox("Start game with multifunction panel closed", options.multifunctionPanelCollapsed)
            q:OptionCheckbox("Start game with menu panel closed", options.menuPanelCollapsed)
        end)
    end)
end
