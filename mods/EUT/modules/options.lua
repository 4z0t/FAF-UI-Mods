do
    local GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
    local Options = import("/mods/UMT/modules/OptionsWindow.lua")
    local OptionVar = import("/mods/UMT/modules/OptionVar.lua").Create

    local modName = "EUT"

    overlayOption = OptionVar(modName, "MexOverlay", true)
    useNumberOverlay = OptionVar(modName, "NumberOverlay", false)
    upgradeT1Option = OptionVar(modName, "UpgradeT1", false)
    upgradeT2Option = OptionVar(modName, "UpgradeT2", false)
    unpauseAssisted = OptionVar(modName, "UnpauseAssisted", false)

    function Init()
        GlobalOptions.AddOptions(modName, "ECO UI Tools", {
            Options.Filter("Show mex overlay", overlayOption),
            Options.Filter("Auto T1 mex upgrade", upgradeT1Option),
            Options.Filter("Auto T2 capped mex upgrade", upgradeT2Option),
            Options.Filter("Display mex overlay with numbers", useNumberOverlay),
            Options.Filter("Unpause mexes being assisted", unpauseAssisted),
        })
    end
end
