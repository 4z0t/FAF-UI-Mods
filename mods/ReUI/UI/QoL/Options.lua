local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt


ReUI.Options.Mods["ReUI.UI.QoL"] = {
    movableMenuPanel = Opt(true),
    multifunctionPanelCollapsed = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.UI.QoL"]
    Options.AddOptions("ReUI.UI.QoL", "ReUI.UI.QoL", {
        Options.Filter("Movable menu panel", options.movableMenuPanel, 4),
        Options.Filter("Start game with multifunction panel closed", options.multifunctionPanelCollapsed, 4),
    })
end
