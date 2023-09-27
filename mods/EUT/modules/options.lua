do
    local Options = UMT.Options
    local OptionVar = UMT.OptionVar.Create

    local modName = "EUT"

    overlayOption = OptionVar(modName, "MexOverlay", true)
    useNumberOverlay = OptionVar(modName, "NumberOverlay", false)
    overlaySize = OptionVar(modName, "OverlaySize", 10)
    upgradeT1Option = OptionVar(modName, "UpgradeT1", false)
    upgradeT2Option = OptionVar(modName, "UpgradeT2", false)
    unpauseAssisted = OptionVar(modName, "UnpauseAssisted", false)
    unpauseOnce = OptionVar(modName, "UnpauseOnce", false)
    unpauseAssistedBP = OptionVar(modName, "unpauseAssistedBP", 4)
    panelScale = OptionVar(modName, "panelScale", 100)

    function Init()
        Options.AddOptions(modName, "ECO UI Tools", {
            Options.Filter("Show mex overlay", overlayOption),
            Options.Filter("Auto T1 mex upgrade", upgradeT1Option),
            Options.Filter("Auto T2 capped mex upgrade", upgradeT2Option),
            Options.Filter("Display mex overlay with numbers", useNumberOverlay),
            Options.Slider("Number overlay size", 5, 25, 1, overlaySize),
            Options.Filter("Unpause mexes being assisted", unpauseAssisted),
            Options.Filter("Unpause once", unpauseOnce),
            Options.Slider("Assist BP threshold: mex unpauses if summary BP greater than this value", 4, 100, 1,
                unpauseAssistedBP),
            Options.Slider("Panel scale, %", 10, 200, 10, panelScale)
        })
    end
end
