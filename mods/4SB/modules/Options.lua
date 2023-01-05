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

style = OptionVar(modName, "scoreboardStyle", "default")


function Init()
    Options.AddOptions(modName, "4z0t's ScoreBoard", {
        Options.Strings("Scoreboard style", { "default", "semi glow border" }, style, 4),
        Options.Fonts("Player name font",player.font.name),
        Options.Fonts("Player rating font",player.font.rating),
    })
end
