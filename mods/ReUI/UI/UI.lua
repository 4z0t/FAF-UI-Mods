ReUI.Require
{
    "ReUI.Core >= 1.0.0",
}

function Main(isReplay)
    local LayoutFunctions = import("Modules/LayoutFunctions.lua")
    local LayouterModule = import("Modules/Layouter.lua")
    local Layoutable = import("Modules/Layoutable.lua").Layoutable
    local BaseLayout = import("Modules/Layoutable.lua").BaseLayout

    return {
        Layouter = LayouterModule.Layouter,
        FloorLayouter = LayouterModule.FloorLayouter,
        RoundLayouter = LayouterModule.RoundLayouter,

        FloorLayoutFor = LayouterModule.FloorLayoutFor,
        RoundLayoutFor = LayouterModule.RoundLayoutFor,

        Layoutable = Layoutable,
        LayoutFunctions = LayoutFunctions,
        BaseLayout = BaseLayout,

        Global = {}
    }
end
