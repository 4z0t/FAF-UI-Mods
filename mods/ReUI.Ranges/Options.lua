local OptionValue = ReUI.Options.OptionValue

ReUI.Options.Mods["ReUI.Ranges"] = {
    hoverPreviewKey = OptionValue("SHIFT"),
    selectedPreviewKey = OptionValue("SHIFT"),
    buildPreviewKey = OptionValue("SHIFT"),
    selectionRangeMode = OptionValue("all"),
    ringOpacity = OptionValue(100),
    showDirectFire = OptionValue(true),
    showIndirectFire = OptionValue(true),
    showAntiAir = OptionValue(true),
    showAntiNavy = OptionValue(true),
    showCountermeasure = OptionValue(true),
    showShield = OptionValue(true),
    showOmni = OptionValue(true),
    showRadar = OptionValue(true),
    showSonar = OptionValue(true),
    showCounterIntel = OptionValue(true),
    showInMinimap = OptionValue(false),
    displayActualBuildRange = OptionValue(false),
}

function Main(isReplay)
    ReUI.Options.Add("ReUI.Ranges", function(frame)
        local options = ReUI.Options.Mods["ReUI.Ranges"]
        return ReUI.Options.Window("ReUI.Ranges", function(q)
            q:Title("Keybindings & Modes", 16)

            if q:Collapsible("Preview keys") then
                local keys = {
                    { text = "Disabled", value = "NONE" },
                    { text = "Shift", value = "SHIFT" },
                    { text = "Ctrl", value = "CONTROL" },
                    { text = "Ctrl or Shift", value = "EITHER" },
                }
                q:PushItemWidth(100)
                q:OptionCombo("Hover", options.hoverPreviewKey, keys)
                q:SameLine(25)
                q:OptionCombo("Selected", options.selectedPreviewKey, keys)
                q:SameLine(25)
                q:OptionCombo("Build", options.buildPreviewKey, keys)
                q:PopItemWidth()
            end

            q:OptionCombo("Selection ranges", options.selectionRangeMode, {
                { text = "All ranges", value = "all" },
                { text = "Only min and max", value = "min_max" },
                { text = "Only max", value = "max" },
            })
            q:OptionSlider("Ring opacity, %", options.ringOpacity, 0, 100, 5)

            q:Title("Weapon Ranges", 16)
            q:OptionCheckbox("Show Direct Fire weapon range", options.showDirectFire)
            q:OptionCheckbox("Show Indirect Fire weapon range", options.showIndirectFire)
            q:OptionCheckbox("Show Anti air weapon range", options.showAntiAir)
            q:OptionCheckbox("Show Countermeasure weapon range", options.showCountermeasure)
            q:OptionCheckbox("Show Anti navy weapon range", options.showAntiNavy)
            q:OptionCheckbox("Show Shield range", options.showShield)

            q:Title("Intel & Build Ranges", 16)
            q:OptionCheckbox("Show Omni range", options.showOmni)
            q:OptionCheckbox("Show Radar range", options.showRadar)
            q:OptionCheckbox("Show Sonar range", options.showSonar)
            q:OptionCheckbox("Show Counter-intel range", options.showCounterIntel)
            q:OptionCheckbox("Display actual build range (including skirt size)", options.displayActualBuildRange)
            q:OptionCheckbox("Show range rings in minimap", options.showInMinimap)
        end)
    end)
end
