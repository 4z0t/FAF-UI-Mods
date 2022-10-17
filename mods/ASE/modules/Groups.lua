local groups = {}


local function Contains(tbl, entry)
    for i, v in ipairs(tbl) do
        if entry == v then
            return i
        end
    end
    return nil
end

local function AddGroup(selection)
    local group = UMT.Weak.Value {}

    for i, unit in selection do
        group[i] = unit
    end

    table.insert(groups, group)
end

local function RemoveFromOtherGroups(selection)
    for _, unit in selection do

        for k, group in groups do

            if table.empty(group) then

                groups[k] = nil

            else

                local id = Contains(group, unit)
                if id then
                    table.remove(group, id)
                    break
                end

            end

        end

    end
end

local function FilterUnitsInGroups(selection)

    local newSelection = {}
    local found

    for _, unit in selection do

        found = false

        for k, group in groups do
            local id = Contains(group, unit)
            if id then
                found = true
                break
            end
        end

        if not found then
            table.insert(newSelection, unit)
        end

    end

    if table.empty(newSelection) then
        return selection, false
    end

    return newSelection, (table.getn(newSelection) ~= table.getn(selection))
end

function AssignGroup()

    local selection = GetSelectedUnits()
    if not selection then return end

    RemoveFromOtherGroups(selection)
    AddGroup(selection)
    print "Group assigned"

end

function RemoveFromGroups()

    local selection = GetSelectedUnits()
    if not selection then return end

    RemoveFromOtherGroups(selection)
    print "Group disbanded"

end

local lastSelectedUnit
local groupId

function SelectionChanged(oldSelection, newSelection, added, removed)


    if not lastSelectedUnit then
        -- selected one unit, but we didn't have one before
        if not table.empty(newSelection) and table.getn(newSelection) == 1 then

            lastSelectedUnit = newSelection[1]
            groupId = nil

            -- find unit group id
            for k, group in groups do
                local id = Contains(group, lastSelectedUnit)
                if id then
                    groupId = k
                    break
                end
            end

            return newSelection, false
        end
    else

        --selected one, but it isnt same one
        if not table.empty(newSelection) and table.getn(newSelection) == 1 then
            if newSelection[1] ~= lastSelectedUnit then
                lastSelectedUnit = nil
                return newSelection, false
            end
        end

        --double clicked, we get all unit of same type
        if table.getn(EntityCategoryFilterDown(categories[lastSelectedUnit:GetBlueprint().BlueprintId], newSelection)) ==
            table.getn(newSelection)
        then
            lastSelectedUnit = nil
            -- we found group that unit belongs to
            if groupId then
                newSelection = groups[groupId]
                groupId = nil
                return newSelection, true
            end
        end

    end


    lastSelectedUnit = nil

    local changed = false
    newSelection, changed = FilterUnitsInGroups(newSelection)
    return newSelection, changed
end
