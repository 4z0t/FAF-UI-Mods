local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local name = "BetterColors"
countColor = OptionVar(name, "countColor", 'ffffffff')

function Init()
    Options.AddOptions(name, "Better Colors",
        {
            Options.ColorSlider("Units count color", countColor, 4)
        }
    )
end
