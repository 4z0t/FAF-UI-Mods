local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"
---@param option string
---@return OptionVar
local function ArialFontOptionVar(option)
    return OptionVar(modName, option, "Arial")
end

title = {
    font = {
        gameSpeed = ArialFontOptionVar("title.font.gameSpeed"),
        totalUnits = ArialFontOptionVar("title.font.totalUnits"),
        time = ArialFontOptionVar("title.font.time"),
        mapName = ArialFontOptionVar("title.font.mapName"),
        mapSize = ArialFontOptionVar("title.font.mapSize"),
        quality = ArialFontOptionVar("title.font.quality"),
    },
    color = {
        time = OptionVar(modName, "title.color.time", 'ff00dbff'),
        gameSpeed = OptionVar(modName, "title.color.gameSpeed", 'ff00dbff'),
        quality = OptionVar(modName, "title.color.quality", 'ff00dbff'),
        totalUnits = OptionVar(modName, "title.color.totalUnits", 'ffff9900'),
        bg = OptionVar(modName, "title.color.bg", "66000000"),
    }
}

player = {

    font = {
        name = ArialFontOptionVar("player.font.name"),
        rating = ArialFontOptionVar("player.font.rating"),
        focus = ArialFontOptionVar("player.font.focus"),
        mass = ArialFontOptionVar("player.font.mass"),
        energy = ArialFontOptionVar("player.font.energy"),
        data = ArialFontOptionVar("player.font.data"),
    },

    color = {
        bg = OptionVar(modName, "player.color.bg", "66000000"),
    }
}

observer = {
    font = ArialFontOptionVar("observer.font"),
    color = {
        line = OptionVar(modName, "observer.color.line", "ffffffff"),
    }
}

style = OptionVar(modName, "scoreboardStyle", "default")
replayStyle = OptionVar(modName, "scoreboardReplayStyle", "default")

teamScoreSort = OptionVar(modName, "teamScoreSort", false)
teamColorAsBG = OptionVar(modName, "teamColorAsBG", false)
teamColorAlpha = OptionVar(modName, "teamColorAlpha", 20)
useDivisions = OptionVar(modName, "useDivisions", false)
useNickNameArmyColor = OptionVar(modName, "useNickNameArmyColor", false)

scoreboardScale = OptionVar(modName, "scoreboardScale", 100)

function Init(isReplay)

    local UIUtil = import('/lua/ui/uiutil.lua')

    Options.AddOptions(modName .. "General", "4z0t's ScoreBoard (General)",
        {
            isReplay and
                Options.Strings("Replay Scoreboard style",
                    {
                        "default",
                        "glow border",
                        "window border",
                    },
                    replayStyle, 4) or
                Options.Strings("Scoreboard style",
                    {
                        "default",
                        "semi glow border",
                        "glow border",
                        "window border",
                    },
                    style, 4),
            Options.Filter("Use divisions instead of rating", useDivisions, 4),
            Options.Filter("Use nickname color as army color", useNickNameArmyColor, 4),
            Options.Filter("In team score sorting", teamScoreSort, 4),
            Options.ColorSlider("Background", player.color.bg, 4),
            Options.Filter("Display Team color as background", teamColorAsBG, 4),
            Options.Slider("Team color alpha", 0, 64, 1, teamColorAlpha, 4),
            Options.Slider("ScoreBoard scale, %", 10, 200, 10, scoreboardScale, 4)
        })

    Options.AddOptions(modName .. "FontsColors", "4z0t's ScoreBoard (Fonts/Colors)", {



        Options.Title("Observer Panel", nil, nil, UIUtil.factionTextColor),
        Options.Fonts("Font", observer.font, 4),
        Options.ColorSlider("Slider color", observer.color.line, 4),
        Options.Title("Player", nil, nil, UIUtil.factionTextColor),
        Options.Fonts("Name", player.font.name, 4),
        Options.Fonts("Focus", player.font.focus, 4),
        Options.Fonts("Rating", player.font.rating, 4),
        Options.Fonts("Mass", player.font.mass, 4),
        Options.Fonts("Energy", player.font.energy, 4),
        Options.Fonts("Replay data", player.font.data, 4),
        Options.Column(2),
        Options.Title("Title", nil, nil, UIUtil.factionTextColor),
        Options.Fonts("Game speed", title.font.gameSpeed, 4),
        Options.Fonts("Unit cap", title.font.totalUnits, 4),
        Options.Fonts("Timer", title.font.time, 4),
        Options.Fonts("Quality", title.font.quality, 4),
        Options.Fonts("Map name", title.font.mapName, 4),
        Options.Fonts("Map size", title.font.mapSize, 4),
        Options.ColorSlider("Timer", title.color.time, 4),
        Options.ColorSlider("Game speed", title.color.gameSpeed, 4),
        Options.ColorSlider("Unit cap", title.color.totalUnits, 4),
        Options.ColorSlider("Quality", title.color.quality, 4),
    })
end
