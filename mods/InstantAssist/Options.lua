local Opt = ReUI.Options.Opt
ReUI.Options.Mods["InstantAssist"] = {
    enabled = Opt(true),
}

function Main(isReplay)
    local options = ReUI.Options.Mods["InstantAssist"]

    ReUI.Options.Builder.AddOptions("InstantAssist", "Instant Assist", {
        ReUI.Options.Builder.Filter("Mod enabled", options.enabled, 4)
    })

end
