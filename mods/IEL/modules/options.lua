local Options = UMT.Options
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
}

function Main()
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
            Options.Filter("Active in replays", options.activeInReplays)
        })
end
