local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"



player = {

    font = {
        name = OptionVar(modName, "player.font.name", "Arial"),
        rating = OptionVar(modName, "player.font.rating", "Arial"),
        focus = OptionVar(modName, "player.font.focus", "Arial")
        
    },

    color = {

    }
}



function Init()
    Options.AddOptions(modName, "4z0t's ScoreBoard", {

    })
end
