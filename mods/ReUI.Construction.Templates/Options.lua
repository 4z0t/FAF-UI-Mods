local Options = ReUI.Options.Builder
local Opt = ReUI.Options.Opt

ReUI.Options.Mods["ReUI.Construction.Templates"] = {
    templateNameLength = Opt(10),
    previewBuildTemplates = Opt(true),
    previewFactoryTemplates = Opt(true),
}

function Main()
    local options = ReUI.Options.Mods["ReUI.Construction.Templates"]
    Options.AddOptions("ReUI.Construction.Templates", "ReUI.Construction.Templates", {
        Options.Slider("Templates name length", 1, 10, 1, options.templateNameLength, 4),
        Options.Filter("Preview build templates", options.previewBuildTemplates, 4),
        Options.Filter("Preview factory templates", options.previewFactoryTemplates, 4),
    })

end
