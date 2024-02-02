local Options = UMT.Options
local Opt = UMT.Options.Opt

UMT.Options.Mods["AGP"] = {
    rows = Opt(4),
    columns = Opt(4),
    itemWidth = Opt(32),
    itemHeight = Opt(32),
    itemSize = Opt(32),
    space = Opt(3),
}

function Main()
    local options = UMT.Options.Mods["AGP"]
    Options.AddOptions("AGP", "Actions Grid Panel", {
        Options.Slider("Rows", 1, 10, 1, options.rows, 4),
        Options.Slider("Columns", 1, 10, 1, options.columns, 4),
        Options.Slider("Size", 10, 64, 1, options.itemSize, 4),
        Options.Slider("Space", 0, 10, 1, options.space, 4),
        --Options.Slider("Height", 10, 64, 1, options.itemHeight, 4),
    })
end
