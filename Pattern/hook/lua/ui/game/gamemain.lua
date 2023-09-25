local OldCreateUI = CreateUI
function CreateUI(isReplay)

    OldCreateUI(isReplay)
    -- your mod's UI may start here
    import('/mods/Pattern/modules/Main.lua').Main(isReplay)

end


local originalOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)

    if ignoreSelection then
        return
    end

    if import('/lua/ui/game/selection.lua').IsHidden() then
        return
    end

    originalOnSelectionChanged(oldSelection, newSelection, added, removed)
     -- override selection here
end
