do
    local GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
    local OptionsUtils = import("/mods/UMT/modules/OptionsWindow.lua")
    local OptionVarCreate = import("/mods/UMT/modules/OptionVar.lua").Create

    local modName = "IEL"
    local function IELOptionVar(name, value)
        return OptionVarCreate(modName, name, value)
    end

    engineersOption = IELOptionVar("engineersOverlay", true)
    engineersWithNumbersOption = IELOptionVar("engineersWithNumbersOption", false)
    factoryOverlayWithTextOption = IELOptionVar("factoryOverlayWithTextOption", false)
    factoriesOption = IELOptionVar("factoriesOverlay", true)
    supportCommanderOption = IELOptionVar("supportCommanderOverlay", true)
    commanderOverlayOption = IELOptionVar("commanderOverlayOption", false)
    tacticalNukesOption = IELOptionVar("tacticalNukesOverlay", true)
    massExtractorsOption = IELOptionVar("massExtractorsOverlay", true)


    function Main(isReplay)
        GlobalOptions.AddOptions(modName, "Idle Engineers Light",
            {
                OptionsUtils.Filter("Show engineers ovelays", engineersOption),
                OptionsUtils.Filter("Show commander ovelays", commanderOverlayOption),
                OptionsUtils.Filter("Show engineers ovelays with numbers", engineersWithNumbersOption),
                OptionsUtils.Filter("Show factories ovelays", factoriesOption),
                OptionsUtils.Filter("Show facrory ovelays with text", factoryOverlayWithTextOption),
                OptionsUtils.Filter("Show Nukes and TMLs ovelays", tacticalNukesOption),
                OptionsUtils.Filter("Show Mex ovelays", massExtractorsOption)
            })
    end
end
