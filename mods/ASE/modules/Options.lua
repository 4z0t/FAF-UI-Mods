do
    local GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
    local Options = import("/mods/UMT/modules/OptionsWindow.lua")
    local OptionVar = import("/mods/UMT/modules/OptionVar.lua").Create

    local modName = "ASE"

    autoLayer = OptionVar(modName, "AutoLayer", true)


    function Main(isReplay)
        GlobalOptions.AddOptions(modName, "Advanced Selection Extension", {
            Options.Filter("Use auto layer selection", autoLayer),
        })
    end
end
