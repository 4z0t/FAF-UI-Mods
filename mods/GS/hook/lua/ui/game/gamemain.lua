do
    local _CreateUI = CreateUI
    function CreateUI(isReplay)

        _CreateUI(isReplay)
        import('/mods/GS/modules/Main.lua').Main(isReplay)

    end
end

do
    local _OnSelectionChanged = OnSelectionChanged
    function OnSelectionChanged(oldSelection, newSelection, added, removed)

        if ignoreSelection then
            return
        end

        if import('/lua/ui/game/selection.lua').IsHidden() then
            return
        end
        if not import('/mods/GS/modules/Main.lua').Ignore() then
            import('/mods/GS/modules/Main.lua').Reset()
        end
        _OnSelectionChanged(oldSelection, newSelection, added, removed)
    end
end
