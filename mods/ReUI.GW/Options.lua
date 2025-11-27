local Opt = ReUI.Options.Opt
ReUI.Options.Mods["ReUI.GW"] = {
    displayRankNames = Opt(true),
}

function Main(isReplay)
    local Options = ReUI.Options.Builder
    local options = ReUI.Options.Mods["ReUI.GW"]

    Options.AddOptions("ReUI.GW", "ReUI.GW", {
        Options.Filter("Display rank names", options.displayRankNames, 4),
    })

end
