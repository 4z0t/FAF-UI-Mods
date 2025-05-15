ReUI.Require
{
    "ReUI.UI.Controls >= 1.0.0"
}

function Main(isReplay)
    local Brackets = import("Modules/Brackets.lua")
    return {
        Brackets = {
            RightGlow = Brackets.RightGlow,
        },
        VerticalCollapseArrow = import("Modules/CollapseArrow.lua").VerticalCollapseArrow,
        EscapeCover = import("Modules/EscapeCover.lua").EscapeCover,
        StaticScrollable = import("Modules/StaticScrollable.lua").StaticScrollable,
        DynamicScrollable = import("Modules/DynamicScrollable.lua").DynamicScrollable,
    }
end
