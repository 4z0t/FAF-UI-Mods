do
    local Options = UMT.Options
    local OptionVar = UMT.OptionVar.Create

    local modName = "EUT"
    local function EUTOption(name, default)
        return OptionVar(modName, name, default)
    end

    overlayOption = EUTOption("MexOverlay", true)
    useNumberOverlay = EUTOption("NumberOverlay", false)
    overlaySize = EUTOption("OverlaySize", 10)
    upgradeT1Option = EUTOption("UpgradeT1", false)
    upgradeT2Option = EUTOption("UpgradeT2", false)
    unpauseAssisted = EUTOption("UnpauseAssisted", false)
    unpauseOnce = EUTOption("UnpauseOnce", false)
    unpauseAssistedBP = EUTOption("unpauseAssistedBP", 4)
    panelScale = EUTOption("panelScale", 100)

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
            Options.Slider("Panel scale, %", 50, 300, 10, panelScale)
        })
    end
end
