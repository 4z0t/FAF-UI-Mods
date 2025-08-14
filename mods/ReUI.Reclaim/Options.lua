local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt


ReUI.Options.Mods["ReUI.Reclaim"] = {
    useBatching   = Opt(true),
    maxLabels     = Opt(1000),
    zoomThreshold = Opt(150),
    heightRatio   = Opt(12),
    updateRate    = Opt(17),

}

function Main()
    local options = ReUI.Options.Mods["ReUI.Reclaim"]
    Options.AddOptions("ReUI.Reclaim", "ReUI.Reclaim", {
        Options.Filter("Use batching", options.useBatching, 4),
        Options.Slider("Max labels", 100, 10000, 100, options.maxLabels, 4),
        Options.Slider("Zoom threshold", 150, 600, 10, options.zoomThreshold, 4),
        Options.Slider("Grouping distance", 5, 20, 1, options.heightRatio, 4),
        Options.Slider("Update rate (ms)", 10, 500, 10, options.updateRate, 4),
    })
end
