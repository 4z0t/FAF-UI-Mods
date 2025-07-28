local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt

ReUI.Options.Mods["ReUI.Construction"] = {
    rows = Opt(1),
    columns = Opt(8),
    itemSize = Opt(48),
    space = Opt(2),
    scale = Opt(100),
    width = Opt(400),
    canScroll = Opt(false),
    color = Opt("ffffffff"),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.Construction"]
    Options.AddOptions("ReUI.Construction", "ReUI.Construction", {
        -- Options.Slider("Rows", 1, 10, 1, options.rows, 4),
        -- Options.Slider("Columns", 1, 10, 1, options.columns, 4),
        -- Options.Slider("Size", 10, 64, 1, options.itemSize, 4),
        -- Options.Slider("Space", 0, 10, 1, options.space, 4),
        Options.Slider("Scale", 50, 300, 25, options.scale, 4),
        Options.Filter("Scroll through items", options.canScroll),
        Options.ColorSlider("Text color", options.color, 4),
    })

end
