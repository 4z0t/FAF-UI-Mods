local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"

title = {
    font = {
        gameSpeed = OptionVar(modName, "title.font.gameSpeed", "Arial"),
        totalUnits = OptionVar(modName, "title.font.totalUnits", "Arial"),
        time = OptionVar(modName, "title.font.time", "Arial"),
        mapName = OptionVar(modName, "title.font.mapName", "Arial"),
        mapSize = OptionVar(modName, "title.font.mapSize", "Arial"),
        quality = OptionVar(modName, "title.font.quality", "Arial"),
    }
}

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
        Options.Title("Title Fonts"),
        Options.Fonts("Game speed", title.font.gameSpeed, 4),
        Options.Fonts("Unit cap", title.font.totalUnits, 4),
        Options.Fonts("Timer", title.font.time, 4),
        Options.Fonts("Quality", title.font.quality, 4),
        Options.Fonts("Map name", title.font.mapName, 4),
        Options.Fonts("Map size", title.font.mapSize, 4),
        Options.Title("Player Fonts"),
        Options.Fonts("Name", player.font.name, 4),
        Options.Fonts("Rating", player.font.rating, 4),
        Options.Fonts("Mass", player.font.mass, 4),
        Options.Fonts("Energy", player.font.energy, 4),
    })
end
