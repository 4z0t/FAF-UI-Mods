ReUI.Require
{
    "ReUI.Core >= 1.0.0"
}

function Main()
    ---@diagnostic disable-next-line:deprecated
    local TableGetN = table.getn
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    local IsKeyDown = IsKeyDown


    ReUI.Core.Hook("/lua/ui/game/gamemain.lua", "DeselectSelens", function(field, module)
        return function(selection)
            local isShift = IsKeyDown("shift")
            local isAlt = IsKeyDown("menu")
            if isAlt and isShift then
                local newSelection = EntityCategoryFilterDown(categories.ENGINEER, selection)
                if TableGetN(newSelection) == TableGetN(selection) then
                    return selection, false
                end
                return newSelection, true
            end
            return field(selection)
        end
    end)
end
