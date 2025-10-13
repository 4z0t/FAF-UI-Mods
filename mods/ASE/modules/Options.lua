local Options = UMT.Options

local Opt = UMT.Options.Opt
UMT.Options.Mods["ASE"] = {
    enabled = Opt(true),

    autoLayer = Opt(false),
    layerFilter = Opt(true),
    lockedFilter = Opt(true),
    assisterFilter = Opt(true),
    doubleClickAssisters = Opt(true),
    includeHovers = Opt(true),
    exoticFilter = Opt(true),
    filters = {
        --land
        Snipers = Opt(true),
        MMLs = Opt(true),
        T3MobileArty = Opt(true),
        FireBeetle = Opt(true),
        --air
        Torps = Opt(true),
        Strats = Opt(true),
        --naval
        StrategicSubs = Opt(true),
        Carriers = Opt(true),
        T3Sonar = Opt(true),
    }
}

function Main(isReplay)
    local options = UMT.Options.Mods["ASE"]
    local filters = options.filters
    Options.AddOptions("ASE", "Advanced Selection Extension", {
        Options.Filter("Mod enabled", options.enabled),
        Options.Filter("Filter units by domain", options.layerFilter),
        Options.Filter("Use auto domain selection", options.autoLayer),
        Options.Filter("Filter locked units", options.lockedFilter),
        Options.Filter("Filter assisters", options.assisterFilter),
        Options.Filter("Double click assisters to select only assisters", options.doubleClickAssisters, 16),
        Options.Filter("Include hovers in naval domain", options.includeHovers),
        Options.Filter("Filter exotics", options.exoticFilter),
        Options.Title("Land", 12, nil, nil, 16),
        Options.Filter("Filter snipers+absolver", filters.Snipers, 16),
        Options.Filter("Filter MMLs", filters.MMLs, 16),
        Options.Filter("Filter T3 mobile arty", filters.T3MobileArty, 16),
        Options.Filter("Filter Fire beetle", filters.FireBeetle, 16),
        Options.Title("Air", 12, nil, nil, 16),
        Options.Filter("Filter torps", filters.Torps, 16),
        Options.Filter("Filter strats", filters.Strats, 16),
        Options.Title("Naval", 12, nil, nil, 16),
        Options.Filter("Filter strat subs", filters.StrategicSubs, 16),
        Options.Filter("Filter carriers", filters.Carriers, 16),
        Options.Filter("Filter sonars", filters.T3Sonar, 16),

    })
end
