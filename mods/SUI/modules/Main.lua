local IsDestroyed = IsDestroyed

local selectionInfo = nil
local function UpdateSelectionInfo(units)
    if IsDestroyed(selectionInfo) then return end

    selectionInfo:Update(units)
end

local function OnSelectionChanged(info)
    if not table.empty(info.removed) or not table.empty(info.added) then
        UpdateSelectionInfo(info.newSelection)
    end
end

function Main(isReplay)
    local GM = import("/lua/ui/game/gamemain.lua")
    GM.ObserveSelection:AddObserver(OnSelectionChanged)
    GM.AddBeatFunction(UpdateSelectionInfo, true)
    selectionInfo = import('SelectionInfo.lua').SelectionInfo(GM.GetStatusCluster())
    selectionInfo:Hide()
end
