local OldDeselectSelens = DeselectSelens

function DeselectSelens(selection)
    local isShift = IsKeyDown("shift")
    local isAlt = IsKeyDown("menu")
    if isAlt and isShift then
        local newSelection = EntityCategoryFilterDown(categories.ENGINEER, selection)
        if table.getn(newSelection) == table.getn(selection) then
            return selection, false
        end
        return newSelection, true
    else
        local a, b = OldDeselectSelens(selection)
        return a, b
    end
end
