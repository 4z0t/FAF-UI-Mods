local Options = UMT.Options

local Opt = UMT.Options.Opt
UMT.Options.Mods["ASE"] = {
    autoLayer = Opt(false),
    layerFilter = Opt(true),
    lockedFilter = Opt(true),
    assisterFilter = Opt(true),
    exoticFilter = Opt(true),

    filterSnipers = Opt(true),
    filterMMLs = Opt(true),
    filterT3MobileArty = Opt(true),
}

function Main(isReplay)
    local options = UMT.Options.Mods["ASE"]
    Options.AddOptions("ASE", "Advanced Selection Extension", {
        Options.Filter("Filter units by layer", options.layerFilter),
        Options.Filter("Use auto layer selection", options.autoLayer),
        Options.Filter("Filter locked units", options.lockedFilter),
        Options.Filter("Filter assisters", options.assisterFilter),
        Options.Filter("Filter exotics", options.exoticFilter),

        Options.Filter("Filter snipers+absolver", options.filterSnipers, 8),
        Options.Filter("Filter MMLs", options.filterMMLs, 8),
        Options.Filter("Filter T3 mobile arty", options.filterT3MobileArty, 8),
    })
end
