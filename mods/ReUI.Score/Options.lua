local Opt = ReUI.Options.Opt

ReUI.Options.Mods["ReUI.Score"] = {
    title = {
        font = {
            gameSpeed = Opt("Arial"),
            totalUnits = Opt("Arial"),
            time = Opt("Arial"),
            mapName = Opt("Arial"),
            mapSize = Opt("Arial"),
            quality = Opt("Arial"),
        },
        color = {
            time = Opt('ff00dbff'),
            gameSpeed = Opt('ff00dbff'),
            quality = Opt('ff00dbff'),
            totalUnits = Opt('ffff9900'),
            bg = Opt("66000000"),
        }
    },

    player = {

        font = {
            name = Opt("Arial"),
            rating = Opt("Arial"),
            focus = Opt("Arial"),
            mass = Opt("Arial"),
            energy = Opt("Arial"),
            data = Opt("Arial"),
        },

        color = {
            bg = Opt("66000000"),
            rating = Opt "plain",
            name = Opt "player color",
            icon = Opt "plain",
        },
    },

    observer = {
        font = Opt("Arial"),
        color = {
            line = Opt("ffffffff"),
        }
    },

    style = Opt("glow border"),
    replayStyle = Opt("glow border"),

    teamScoreSort = Opt(false),
    displayMode = Opt("default"),
    teamColorAsBG = Opt(true),
    teamColorAlpha = Opt(45),
    useDivisions = Opt(false),
    useNickNameArmyColor = Opt(false),

    -- snowflakes = Opt(false),
    -- snowflakesCount = Opt(50),
    -- snowflakesSpeed = Opt(100),

    scoreboardScale = Opt(100),

    shortenAINickName = Opt(false),

}

function Main(isReplay)
    local Options = ReUI.Options.Builder
    local UIUtil = import('/lua/ui/uiutil.lua')

    local options = ReUI.Options.Mods["ReUI.Score"]

    Options.AddOptions("ReUI.Score.General", "ReUI.Score : General",
        {
            (isReplay or IsObserver()) and
                Options.Strings("Replay Scoreboard style",
                    ReUI.LINQ.Enumerate(ReUI.Score.Layouts, next):Keys():ToArray(),
                    options.replayStyle, 4) or
                Options.Strings("Scoreboard style",
                    ReUI.LINQ.Enumerate(ReUI.Score.Layouts, next):Keys():ToArray(),
                    options.style, 4),
            Options.Filter("Use divisions instead of rating", options.useDivisions, 4),
            -- Options.Filter("Use nickname color as army color", options.useNickNameArmyColor, 4),
            Options.Filter("In team score sorting", options.teamScoreSort, 4),
            Options.Strings("Display mode of resource data", {
                "default",
                "income+storage",
                "income+storage+maxstorage",
            }, options.displayMode, 4),
            Options.ColorSlider("Background", options.player.color.bg, 4),
            Options.Filter("Display Team color as background", options.teamColorAsBG, 4),
            Options.Slider("Team color alpha", 0, 64, 1, options.teamColorAlpha, 4),
            Options.Slider("ScoreBoard scale, %", 50, 300, 10, options.scoreboardScale, 4),
            -- Options.Filter("Snowflakes in scoreboard", options.snowflakes, 4),
            -- Options.Slider("Snowflakes count", 25, 200, 25, options.snowflakesCount, 4),
            -- Options.Slider("Snowflakes speed", 10, 200, 10, options.snowflakesSpeed, 4),
            Options.Filter("Shorten AI nicknames", options.shortenAINickName, 4),
        })

    Options.AddOptions("ReUI.Score.FontsColors", "ReUI.Score : Fonts / Colors", {
        Options.Title("Observer Panel", nil, nil, UIUtil.factionTextColor),
        Options.Fonts("Font", options.observer.font, 4),
        Options.ColorSlider("Slider color", options.observer.color.line, 4),
        Options.Title("Player", nil, nil, UIUtil.factionTextColor),
        Options.Strings("Faction icon color", {
            "plain",
            "player color",
            "team color",
        }, options.player.color.icon, 4),
        Options.Fonts("Name font", options.player.font.name, 4),
        Options.Strings("Name color", {
            "plain",
            "player color",
            "team color",
        }, options.player.color.name, 4),
        Options.Fonts("Focus", options.player.font.focus, 4),
        Options.Fonts("Rating font", options.player.font.rating, 4),
        Options.Strings("Rating color", {
            "plain",
            "player color",
            "team color",
        }, options.player.color.rating, 4),
        Options.Fonts("Mass", options.player.font.mass, 4),
        Options.Fonts("Energy", options.player.font.energy, 4),
        Options.Fonts("Replay data", options.player.font.data, 4),
        Options.Column(2),
        Options.Title("Title", nil, nil, UIUtil.factionTextColor),
        Options.Fonts("Game speed", options.title.font.gameSpeed, 4),
        Options.Fonts("Unit cap", options.title.font.totalUnits, 4),
        Options.Fonts("Timer", options.title.font.time, 4),
        Options.Fonts("Quality", options.title.font.quality, 4),
        Options.Fonts("Map name", options.title.font.mapName, 4),
        Options.Fonts("Map size", options.title.font.mapSize, 4),
        Options.ColorSlider("Timer", options.title.color.time, 4),
        Options.ColorSlider("Game speed", options.title.color.gameSpeed, 4),
        Options.ColorSlider("Unit cap", options.title.color.totalUnits, 4),
        Options.ColorSlider("Quality", options.title.color.quality, 4),
    })
end
