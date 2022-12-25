local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"



player = {

    font = {
        name = OptionVar(modName, "playerFonts.name", "Arial"),
        rating = OptionVar(modName, "player.fonts.rating", "Arial"),
        focus = OptionVar(modName, "player.fonts.focus", "Arial")
        
    },

    color = {

    }
}



function Init()
    Options.AddOptions(modName, "4z0t's ScoreBoard", {

    })
end
