local Opt = ReUI.Options.Opt

ReUI.Options.Mods["Ctrl"] = {
    enableCtrlCopy = Opt(true),
    enableCtrlMove = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["Ctrl"]
    local builder = ReUI.Options.Builder
    builder.AddOptions("Ctrl", "Ctrl", {
        builder.Filter("Enable Ctrl-copy feature", options.enableCtrlCopy),
        builder.Filter("Enable Ctrl-move feature", options.enableCtrlMove),
    })
end
