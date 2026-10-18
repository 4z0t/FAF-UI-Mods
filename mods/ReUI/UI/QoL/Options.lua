local Opt = ReUI.Options.OptionValue


ReUI.Options.Mods["ReUI.UI.QoL"] = {
    movableMenuPanel = Opt(true),
    multifunctionPanelCollapsed = Opt(true),
    menuPanelCollapsed = Opt(true),
    advancedPingDialog = Opt(false),
}

function Main()
    ReUI.Options.Add("ReUI.UI.QoL", function(frame)
        local options = ReUI.Options.Mods["ReUI.UI.QoL"]
        return ReUI.Options.Window("ReUI.UI.QoL", function(q)
            q:OptionCheckbox("Movable menu panel", options.movableMenuPanel)
            q:OptionCheckbox("Start game with multifunction panel closed", options.multifunctionPanelCollapsed)
            q:OptionCheckbox("Start game with menu panel closed", options.menuPanelCollapsed)
            q:Splitter()
            q:OptionCheckbox("Use advanced ping dialog", options.advancedPingDialog)
        end)
    end)
end
