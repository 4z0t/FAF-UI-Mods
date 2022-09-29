local GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
local Options = import("/mods/UMT/modules/OptionsWindow.lua")
local OptionVar = import("/mods/UMT/modules/OptionVar.lua").Create

overlayOption = OptionVar("EUT", "MexOverlay", true)
upgradeT1Option = OptionVar("EUT", "UpgradeT1", false)

function Init()
    GlobalOptions.AddOptions("EUT", "ECO UI Tools", {
        Options.Filter("Show mex overlay", overlayOption),
        Options.Filter("Auto T1 mex upgrade", upgradeT1Option),
    })
end

