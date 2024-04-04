local ForkThread = ForkThread
local IsKeyDown = IsKeyDown
local TableEmpty = table.empty
local SelectUnits = SelectUnits

local Selection
local Lock
local Groups

local ignored = false
local enabled = false
local isReplay

function SetIgnored(state)
    ignored = state
end

function GetIgnored()
    return ignored
end

local function SelectIgnored(units)
    ignored = true
    SelectUnits(nil)
    SelectUnits(units)
    ignored = false
end

local layer
local locked
local assisters
local exotic
function BindOptions()
    local Options = UMT.Options.Mods["ASE"]
    Options.assisterFilter:Bind(function(opt)
        assisters = opt()
    end)
    Options.layerFilter:Bind(function(opt)
        layer = opt()
    end)
    Options.lockedFilter:Bind(function(opt)
        locked = opt()
    end)
    Options.exoticFilter:Bind(function(opt)
        exotic = opt()
    end)
    Options.enabled:Bind(function(opt)
        enabled = opt()
    end)
end

function Main(_isReplay)
    isReplay = _isReplay
    if isReplay then return end

    Selection = import("Selection.lua")
    Lock = import("Lock.lua")
    Groups = import("Groups.lua")
    Lock.Main(_isReplay)
    Selection.Main(_isReplay)
    BindOptions()

end

function SelectionChanged(oldSelection, newSelection, added, removed)
    if isReplay or not enabled or ignored or IsKeyDown("Shift") or TableEmpty(added) then
        return false
    end

    local changed = false
    local changedSel

    -- newSelection, changedSel = Groups.SelectionChanged(oldSelection, newSelection, added, removed)
    -- changed = changed or changedSel

    if assisters then
        newSelection, changedSel = Selection.FilterAssisters(newSelection)
        changed = changed or changedSel
    end

    if locked then
        newSelection, changedSel = Selection.FilterLocked(newSelection)
        changed = changed or changedSel
    end

    if layer then
        newSelection, changedSel = Selection.FilterLayer(newSelection)
        changed = changed or changedSel
    end

    if exotic then
        newSelection, changedSel = Selection.FilterExotic(newSelection)
        changed = changed or changedSel
    end

    if changed then
        ForkThread(SelectIgnored, newSelection)
        return true
    end

    return false
end
