local Options = UMT.Options
local Opt = UMT.Options.Opt

local modName = "EUT"
UMT.Options.Mods["EUT"] = {
    overlayOption = Opt(true),
    useNumberOverlay = Opt(false),
    overlaySize = Opt(10),
    upgradeT1Option = Opt(false),
    upgradeT2Option = Opt(false),
    unpauseAssisted = Opt(false),
    unpauseOnce = Opt(false),
    unpauseAssistedBP = Opt(4),
    t1MexText = Opt("1"),
    t2MexText = Opt("2"),
    t3MexText = Opt("3"),
    upgradeRounded = Opt(false),
    panelScale = Opt(100),
}

function Main()
    local options = UMT.Options.Mods["EUT"]
    Options.AddOptions(modName, "ECO UI Tools", {
        Options.Filter("Show mex overlay", options.overlayOption),
        Options.Filter("Auto T1 mex upgrade", options.upgradeT1Option),
        Options.Filter("Auto T2 capped mex upgrade", options.upgradeT2Option),
        Options.Filter("Display mex overlay with numbers", options.useNumberOverlay),
        Options.Slider("Number overlay size", 5, 25, 1, options.overlaySize),
        Options.Filter("Unpause mexes being assisted", options.unpauseAssisted),
        Options.Filter("Unpause once", options.unpauseOnce),
        Options.Filter("Upgrade only rounded t2 mexes", options.upgradeRounded),
        Options.Slider("Assist BP threshold: mex unpauses if summary BP greater than this value", 4, 100, 1,
            options.unpauseAssistedBP),
        Options.TextEdit("T1 mex overlay text", options.t1MexText, 1, 4),
        Options.TextEdit("T2 mex overlay text", options.t2MexText, 1, 4),
        Options.TextEdit("T3 mex overlay text", options.t3MexText, 1, 4),
        Options.Slider("Panel scale", 50, 300, 25, options.panelScale),
    })
end
