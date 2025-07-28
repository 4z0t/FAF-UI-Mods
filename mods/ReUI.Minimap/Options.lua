local Opt = ReUI.Options.Opt
ReUI.Options.Mods["ReUI.Minimap"] = {
    allowZoom = Opt(false)
}

function Main(isReplay)
    local Options = ReUI.Options.Builder
    local options = ReUI.Options.Mods["ReUI.Minimap"]

    Options.AddOptions("ReUI.Minimap", "ReUI.Minimap", {
        Options.Filter("Allow zoom", options.allowZoom, 4),
    })

end
