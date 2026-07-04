local Options = ReUI.Options.Builder
local Opt = ReUI.Options.OptionValue


ReUI.Options.Mods["ReUI.Selection"] = {
    enabled = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.Selection"]
    Options.AddOptions("ReUI.Selection", "ReUI.Selection", {
        Options.Filter("Mod enabled", options.enabled, 4),
    })
end
