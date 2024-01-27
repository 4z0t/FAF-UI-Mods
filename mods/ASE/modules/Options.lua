do
    local Options = UMT.Options
    local OptionVar = import("/mods/UMT/modules/OptionVar.lua").Create

    local modName = "ASE"

    autoLayer = OptionVar(modName, "AutoLayer", true)


    function Main(isReplay)
        Options.AddOptions(modName, "Advanced Selection Extension", {
            Options.Filter("Use auto layer selection", autoLayer),
        })
    end
end
