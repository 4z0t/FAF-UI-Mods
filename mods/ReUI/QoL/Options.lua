local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt


ReUI.Options.Mods["ReUI.QoL"] = {
    movableMenuPanel = Opt(true),
    multifunctionPanelCollapsed = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.QoL"]
    Options.AddOptions("ReUI.QoL", "ReUI.QoL", {
        Options.Filter("Movable menu panel", options.movableMenuPanel, 4),
        Options.Filter("Start game with multifunction panel closed", options.multifunctionPanelCollapsed, 4),
    })
end
