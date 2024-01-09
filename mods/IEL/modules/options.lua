local Opt = UMT.Options.Opt
UMT.Options.Mods["IEL"] = {
    engineersWithNumbersOption = Opt(false),
    factoryOverlayWithTextOption = Opt(false),
    factoriesOption = Opt(true),
    supportCommanderOption = Opt(true),
    commanderOverlayOption = Opt(false),
    tacticalNukesOption = Opt(true),
    massExtractorsOption = Opt(true),
    engineersOption = Opt(true),
    overlayColor = Opt("ffff00ff"),
    activeInReplays = Opt(true),
    scanDelay = Opt(10),
}

function Main()
    local Options = UMT.Options
    local options = UMT.Options.Mods["IEL"]
    Options.AddOptions("IEL", "Idle Engineers Light",
        {
            Options.Filter("Show engineers ovelays", options.engineersOption),
            Options.Filter("Show commander ovelays", options.commanderOverlayOption),
            Options.Filter("Show engineers ovelays with numbers", options.engineersWithNumbersOption),
            Options.Filter("Show factories ovelays", options.factoriesOption),
            Options.Filter("Show facrory ovelays with text", options.factoryOverlayWithTextOption),
            Options.Filter("Show Nukes and TMLs ovelays", options.tacticalNukesOption),
            Options.Filter("Show Mex ovelays", options.massExtractorsOption),
            Options.ColorSlider("overlay color", options.overlayColor),
            Options.Filter("Active in replays", options.activeInReplays),
            Options.Slider([[Unit scanner delay in ticks (increase if you expirience performance issues in late game)]],
                1, 100, 1, options.scanDelay),
        })
end
