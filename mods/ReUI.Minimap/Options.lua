local OptionValue = ReUI.Options.OptionValue
ReUI.Options.Mods["ReUI.Minimap"] = {
    allowZoom = OptionValue(false),
    hideOnSplitScreen = OptionValue(false),
    hideAtCameraDistance = OptionValue(false),
    cameraDistanceThreshold = OptionValue(520),
}

function Main(isReplay)
    local Options = ReUI.Options.Builder
    local options = ReUI.Options.Mods["ReUI.Minimap"]

    Options.AddOptions("ReUI.Minimap", "ReUI.Minimap", {
        Options.Filter("Allow zoom", options.allowZoom, 4),
        Options.Filter("Hide in split-screen", options.hideOnSplitScreen, 4),
        Options.Filter("Hide at camera distance", options.hideAtCameraDistance, 4),
        Options.Slider("Camera distance threshold (10 km map)", 100, 1000, 10, options.cameraDistanceThreshold, 4),
    })

end
