local Opt = ReUI.Options.Opt
ReUI.Options.Mods["ReUI.Economy"] = {
    scale = Opt(100),
    style = Opt("default"),
}

function Main(isReplay)
    local Options = ReUI.Options.Builder
    local options = ReUI.Options.Mods["ReUI.Economy"]

    Options.AddOptions("ReUI.Economy", "ReUI.Economy", {
        Options.Slider("Scale", 50, 300, 25, options.scale, 4),
        Options.Strings("Style",
            ReUI.LINQ.Enumerate(ReUI.Economy.Layouts, next):Keys():ToArray(),
            options.style, 4)
    })

end
