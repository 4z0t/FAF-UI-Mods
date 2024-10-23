local Options = UMT.Options
local Opt = UMT.Options.Opt

UMT.Options.Mods["Ctrl"] = {
    enableCtrlCopy = Opt(true),
    enableCtrlMove = Opt(true),
}

function Main()
    local options = UMT.Options.Mods["Ctrl"]
    Options.AddOptions("Ctrl", "Ctrl", {
        Options.Filter("Enable Ctrl-copy feature", options.enableCtrlCopy),
        Options.Filter("Enable Ctrl-move feature", options.enableCtrlMove),
    })
end
