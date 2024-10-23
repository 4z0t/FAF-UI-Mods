local Opt = UMT.Options.Opt
UMT.Options.Mods["SRD"] = {
    previewKey = Opt "SHIFT",
}

function Main()
    local Options = UMT.Options
    local options = UMT.Options.Mods["SRD"]
    Options.AddOptions("SRD", "Smart Ring Display",
        {
            Options.Strings("Preview key (restart required)",
                {
                    "SHIFT",
                    "CONTROL"
                },
                options.previewKey),

        })
end
