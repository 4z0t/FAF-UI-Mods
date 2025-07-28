local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt


ReUI.Options.Mods["ReUI"] = {
    construction = Opt(true),
    economy = Opt(true),
    score = Opt(true),
    -- reclaim = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI"]
    Options.AddOptions("ReUI", "ReUI mods", {
        Options.Title("ReUI mods (requires reload after change)", 20, "Arial"),
        Options.Filter("ReUI.Construction", options.construction, 4),
        Options.Filter("ReUI.Economy", options.economy, 4),
        Options.Filter("ReUI.Score", options.score, 4),
        -- Options.Filter("ReUI.Reclaim", options.reclaim, 4),
    })
end
