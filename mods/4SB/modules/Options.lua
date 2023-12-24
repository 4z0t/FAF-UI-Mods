local Options = UMT.Options
local OptionVar = UMT.OptionVar.Create

local modName = "4SB"
---@param option string
---@return OptionVar
local function ArialFontOptionVar(option)
    return OptionVar(modName, option, "Arial")
end

local function OptVar4SB(name, default)
    return OptionVar(modName, name, default)
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
        time = OptVar4SB("title.color.time", 'ff00dbff'),
        gameSpeed = OptVar4SB("title.color.gameSpeed", 'ff00dbff'),
        quality = OptVar4SB("title.color.quality", 'ff00dbff'),
        totalUnits = OptVar4SB("title.color.totalUnits", 'ffff9900'),
        bg = OptVar4SB("title.color.bg", "66000000"),
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
        bg = OptVar4SB("player.color.bg", "66000000"),
    }
}

observer = {
    font = ArialFontOptionVar("observer.font"),
    color = {
        line = OptVar4SB("observer.color.line", "ffffffff"),
    }
}



style = OptVar4SB("scoreboardStyle", "glow border")
replayStyle = OptVar4SB("scoreboardReplayStyle", "glow border")

teamScoreSort = OptVar4SB("teamScoreSort", false)
teamColorAsBG = OptVar4SB("teamColorAsBG", false)
teamColorAlpha = OptVar4SB("teamColorAlpha", 20)
useDivisions = OptVar4SB("useDivisions", false)
useNickNameArmyColor = OptVar4SB("useNickNameArmyColor", false)

snowflakes = OptVar4SB("snowflakes", false)
snowflakesCount = OptVar4SB("snowflakesCount", 50)
snowflakesSpeed = OptVar4SB("snowflakesSpeed", 100)

scoreboardScale = OptVar4SB("scoreboardScale", 100)

local Opt = UMT.Options.Opt

UMT.Options.Mods["4SB"] = {
    hello = Opt "a",
    world = 1,
    kappa = {
        pride = Opt(1),
        ---@type Opt
        chat  = "b"
    },
    test = "c",
    test2 = {
        ---@type Opt
        a = 1,
        ---@type Opt
        b = 2,
        c = {
            ---@type Opt
            d = 3,
            ---@type Opt
            e = 4,
        },
    },
}

function Init(isReplay)

    local UIUtil = import('/lua/ui/uiutil.lua')

    Options.AddOptions(modName .. "General", "4z0t's ScoreBoard (General)",
        {
            isReplay and
                Options.Strings("Replay Scoreboard style",
                    {
                        "minimalictic",
                        "glow border",
                        "window border",
                    },
                    replayStyle, 4) or
                Options.Strings("Scoreboard style",
                    {
                        "minimalictic",
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
            Options.Slider("ScoreBoard scale, %", 50, 300, 10, scoreboardScale, 4),
            Options.Filter("Snowflakes in scoreboard", snowflakes, 4),
            Options.Slider("Snowflakes count", 25, 200, 25, snowflakesCount, 4),
            Options.Slider("Snowflakes speed", 10, 200, 10, snowflakesSpeed, 4),
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
