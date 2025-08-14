local Options = UMT.Options
local Opt = UMT.Options.Opt

UMT.Options.Mods["AGP"] = {
    rows = Opt(2),
    columns = Opt(8),
    itemSize = Opt(48),
    space = Opt(2),
}

function Main()
    local options = UMT.Options.Mods["AGP"]
    Options.AddOptions("AGP", "Actions Grid Panel", {
        Options.Slider("Rows", 1, 10, 1, options.rows, 4),
        Options.Slider("Columns", 1, 10, 1, options.columns, 4),
        Options.Slider("Size", 10, 64, 1, options.itemSize, 4),
        Options.Slider("Space", 0, 10, 1, options.space, 4),
    })

    Options.AddOptions("AGP_Ext", "Actions Grid Extensions", function(parent)
        return import("/mods/AGP/modules/Main.lua").CreateSelector(parent)
    end)
end
