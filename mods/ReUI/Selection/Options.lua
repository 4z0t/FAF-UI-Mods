local Opt = ReUI.Options.OptionValue


ReUI.Options.Mods["ReUI.Selection"] = {
    enabled = Opt(true),
}

function Main()
    ReUI.Options.Add("ReUI.Selection", function(frame)
        local options = ReUI.Options.Mods["ReUI.Selection"]
        return ReUI.Options.Window("ReUI.Selection", function(q)
            q:OptionCheckbox("Mod enabled", options.enabled)
            q:Tooltip("Selection", "enables all selection extension mods")
        end)
    end)
end
