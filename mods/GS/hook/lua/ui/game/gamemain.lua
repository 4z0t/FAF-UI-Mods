do
    local _CreateUI = CreateUI
    function CreateUI(isReplay)

        _CreateUI(isReplay)
        import('/mods/GS/modules/Main.lua').Main(isReplay)

    end
end


-- local originalOnSelectionChanged = OnSelectionChanged
-- function OnSelectionChanged(oldSelection, newSelection, added, removed)

--     if ignoreSelection then
--         return
--     end

--     if import('/lua/ui/game/selection.lua').IsHidden() then
--         return
--     end

--     originalOnSelectionChanged(oldSelection, newSelection, added, removed)
--      -- override selection here
-- end
