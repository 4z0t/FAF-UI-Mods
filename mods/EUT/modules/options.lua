local Options = UMT.Options
local Opt = Options.Opt

UMT.Options.Mods["EUT"] = {
    overlayOption = Opt(true),
    useNumberOverlay = Opt(false),
    overlaySize = Opt(10),
    upgradeT1Option = Opt(false),
    upgradeT2Option = Opt(false),
    unpauseAssisted = Opt(false),
    unpauseOnce = Opt(false),
    unpauseAssistedBP = Opt(4),
    panelScale = Opt(100),
}

function Main()
    local options = UMT.Options.Mods["EUT"]
    Options.AddOptions("EUT", "ECO UI Tools", {
        Options.Filter("Show mex overlay", options.overlayOption),
        Options.Filter("Auto T1 mex upgrade", options.upgradeT1Option),
        Options.Filter("Auto T2 capped mex upgrade", options.upgradeT2Option),
        Options.Filter("Display mex overlay with numbers", options.useNumberOverlay),
        Options.Slider("Number overlay size", 5, 25, 1, options.overlaySize),
        Options.Filter("Unpause mexes being assisted", options.unpauseAssisted),
        Options.Filter("Unpause once", options.unpauseOnce),
        Options.Slider("Assist BP threshold: mex unpauses if summary BP greater than this value", 4, 100, 1,
            options.unpauseAssistedBP),
        Options.Slider("Panel scale, %", 50, 300, 10, options.panelScale)
    })
end
