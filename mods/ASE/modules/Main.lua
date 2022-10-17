local Selection
local Lock
local Groups

local clearSelection = false
local ignored = false
local enabled = true
local isReplay

function SetIgnored(state)
    ignored = state
end

function GetIgnored()
    return ignored
end

function Toggle()
    enabled = not enabled
    if enabled then
        print "ASE enabled"
    else
        print "ASE disabled"
    end
end

local function SelectIgnored(units)
    ignored = true
    clearSelection = true
    SelectUnits(nil)
    clearSelection = false
    SelectUnits(units)
    ignored = false
end

function Main(_isReplay)
    isReplay = _isReplay
    if not isReplay then
        if exists("/mods/UMT/mod_info.lua") and import("/mods/UMT/mod_info.lua").version >= 6 then
            import("Options.lua").Main(_isReplay)
            Selection = import("Selection.lua")
            Lock = import("Lock.lua")
            Groups = import("Groups.lua")
            Lock.Main(_isReplay)
            Selection.Main(_isReplay)
        else
            isReplay = true
            ForkThread(function()
                WaitSeconds(4)
                print("Advanced Selection Extension requires UI mod tools version 7 and higher!!!")
            end)
            return
        end
    end
end

function SelectionChanged(oldSelection, newSelection, added, removed)
    if isReplay or not enabled or ignored or IsKeyDown("Shift") or table.empty(added) then
        return clearSelection
    end




    local changed = false
    local changedSel

    newSelection, changedSel = Groups.SelectionChanged(oldSelection, newSelection, added, removed)
    changed = changed or changedSel

    newSelection, changedSel = Selection.FilterAssisters(newSelection)
    changed = changed or changedSel


    newSelection, changedSel = Selection.FilterLocked(newSelection)
    changed = changed or changedSel


    newSelection, changedSel = Selection.FilterLayer(newSelection)
    changed = changed or changedSel



    if changed then
        ForkThread(SelectIgnored, newSelection)
        return true
    end



    return false
end
