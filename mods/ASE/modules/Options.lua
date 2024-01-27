do
    local Options = UMT.Options

    local Opt = UMT.Options.Opt
    UMT.Options.Mods["ASE"] = {
        autoLayer = Opt(true),
        layerFilter = Opt(true),
        lockedFilter = Opt(true),
        assisterFilter = Opt(true),
    }

    function Main(isReplay)
        local options = UMT.Options.Mods["ASE"]
        Options.AddOptions("ASE", "Advanced Selection Extension", {
            Options.Filter("Filter units by layer", options.layerFilter),
            Options.Filter("Use auto layer selection", options.autoLayer),
            Options.Filter("Filter locked units", options.lockedFilter),
            Options.Filter("Filter assisters", options.assisterFilter),
        })
    end
end
