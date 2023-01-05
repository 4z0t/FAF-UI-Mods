local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"



player = {

    font = {
        name = OptionVar(modName, "player.font.name", "Arial"),
        rating = OptionVar(modName, "player.font.rating", "Arial"),
        focus = OptionVar(modName, "player.font.focus", "Arial"),
        mass = OptionVar(modName, "player.font.mass", "Arial"),
        energy = OptionVar(modName, "player.font.energy", "Arial"),
    },

    color = {

    }
}

style = OptionVar(modName, "scoreboardStyle", "default")


function Init()
    Options.AddOptions(modName, "4z0t's ScoreBoard", {
        Options.Strings("Scoreboard style", { "default", "semi glow border" }, style, 4),
        Options.Title("Player Fonts"),
        Options.Fonts("Name", player.font.name, 4),
        Options.Fonts("Rating", player.font.rating, 4),
        Options.Fonts("Mass", player.font.mass, 4),
        Options.Fonts("Energy", player.font.energy, 4),
    })
end
