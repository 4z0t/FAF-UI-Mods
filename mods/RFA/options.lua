local Opt = UMT.Options.Opt
UMT.Options.Mods["RFA"] = {
    hoverPreviewKey = Opt "SHIFT",
    selectedPreviewKey = Opt "SHIFT",
    buildPreviewKey = Opt "SHIFT",
    showDirectFire = Opt(true),
    showIndirectFire = Opt(true),
    showAntiAir = Opt(true),
    showAntiNavy = Opt(true),
    showCountermeasure = Opt(true),
    showOmni = Opt(true),
    showRadar = Opt(true),
    showSonar = Opt(true),
    showCounterIntel = Opt(true),
    showInMinimap = Opt(false),
}

function Main()
    local Options = UMT.Options
    local options = UMT.Options.Mods["RFA"]
    Options.AddOptions("RFA", "Rings For All",
        {
            Options.Strings("Hover Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.hoverPreviewKey),
            Options.Strings("Selected Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.selectedPreviewKey),
            Options.Filter("Show range rings in minimap", options.showInMinimap, 4),
            Options.Filter("Show Direct Fire weapon range", options.showDirectFire, 4),
            Options.Filter("Show Indirect Fire weapon range", options.showIndirectFire, 4),
            Options.Filter("Show Anti air weapon range", options.showAntiAir, 4),
            Options.Filter("Show Countermeasure weapon range", options.showCountermeasure, 4),
            Options.Filter("Show Anti navy weapon range", options.showAntiNavy, 4),
            Options.Filter("Show Omni range", options.showOmni, 4),
            Options.Filter("Show Radar range", options.showRadar, 4),
            Options.Filter("Show Sonar range", options.showSonar, 4),
            Options.Filter("Show Counter-intel range", options.showCounterIntel, 4),
            Options.Strings("Build Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.buildPreviewKey),
        })
end
