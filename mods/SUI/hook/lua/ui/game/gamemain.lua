

local OldCreateUI = CreateUI
function CreateUI(isReplay)
    OldCreateUI(isReplay)
    controls.selectionInfo = import('/mods/SUI/modules/SelectionInfo.lua').SelectionInfo(controls.status)
    controls.selectionInfo:Hide()
end

local originalOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)
    originalOnSelectionChanged(oldSelection, newSelection, added, removed)
    if (not table.empty(removed) or not table.empty(added)) then
        if (controls.selectionInfo) then
            controls.selectionInfo:Update(newSelection)
        end
    end

end
