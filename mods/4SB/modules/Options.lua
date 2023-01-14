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
    },
    color = {
        bg = OptionVar(modName, "title.color.bg", "66000000"),
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
        bg = OptionVar(modName, "player.color.bg", "66000000"),
    }
}

style = OptionVar(modName, "scoreboardStyle", "default")
replayStyle = OptionVar(modName, "scoreboardReplayStyle", "default")


function Init(isReplay)
    Options.AddOptions(modName, "4z0t's ScoreBoard", {
        isReplay and Options.Strings("Replay Scoreboard style",
            {
                "default",
                "glow border"
            },
            replayStyle, 4) or Options.Strings("Scoreboard style",
            {
                "default",
                "semi glow border",
            },
            style, 4),
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
        Options.Title("Title colors"),
        Options.ColorSlider("Background", title.color.bg, 4),
        Options.Title("Player colors"),
        Options.ColorSlider("Background", player.color.bg, 4),
    })
end
