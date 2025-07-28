ReUI.Require
{
    "ReUI.UI.Controls >= 1.0.0"
}

function Main(isReplay)
    local Brackets = import("Modules/Brackets.lua")
    return {
        Button = import("Modules/Button.lua").Button,
        Brackets = {
            RightGlow = Brackets.RightGlow,
            FactionRight = Brackets.FactionRightBracket,
        },
        WindowFrame = import("Modules/WindowFrame.lua").WindowFrame,
        VerticalCollapseArrow = import("Modules/CollapseArrow.lua").VerticalCollapseArrow,
        HorizontalCollapseArrow = import("Modules/CollapseArrow.lua").HorizontalCollapseArrow,
        EscapeCover = import("Modules/EscapeCover.lua").EscapeCover,
        StaticScrollable = import("Modules/StaticScrollable.lua").StaticScrollable,
        DynamicScrollable = import("Modules/DynamicScrollable.lua").DynamicScrollable,
        GlowBorder = import("Modules/GlowBorder.lua").GlowBorder,
    }
end
