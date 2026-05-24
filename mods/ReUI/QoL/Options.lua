local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt


ReUI.Options.Mods["ReUI.QoL"] = {
    movableMenuPanel = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.QoL"]
    Options.AddOptions("ReUI.QoL", "ReUI.QoL", {
        Options.Filter("Movable menu panel", options.movableMenuPanel, 4),
    })
end
