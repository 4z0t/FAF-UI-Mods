local Opt = ReUI.Options.Opt
ReUI.Options.Mods["ReUI.Economy"] = {
    scale = Opt(100),
}

function Main(isReplay)
    local options = ReUI.Options.Mods["ReUI.Economy"]

    ReUI.Options.Builder.AddOptions("ReUI.Economy", "ReUI.Economy", {
        ReUI.Options.Builder.Slider("Scale", 50, 300, 25, options.scale, 4)
    })

end
