do
    local function UpdateSelectionInfo(units)
        if controls.selectionInfo then
            controls.selectionInfo:Update(units)
        end
    end

    local OldCreateUI = CreateUI
    function CreateUI(isReplay)
        OldCreateUI(isReplay)
        controls.selectionInfo = import('/mods/SUI/modules/SelectionInfo.lua').SelectionInfo(controls.status)
        controls.selectionInfo:Hide()
        AddBeatFunction(UpdateSelectionInfo, true)

    end

    local originalOnSelectionChanged = OnSelectionChanged
    function OnSelectionChanged(oldSelection, newSelection, added, removed)
        originalOnSelectionChanged(oldSelection, newSelection, added, removed)
        if not table.empty(removed) or not table.empty(added) then
            UpdateSelectionInfo(newSelection)
        end
    end
end
