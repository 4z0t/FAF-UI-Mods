ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Actions >= 1.0.0",
}

function Main(isReplay)
    local filters = {}

    local TechCategoryList = {
        TECH1 = 'T1 ',
        TECH2 = 'T2 ',
        TECH3 = 'T3 ',
        EXPERIMENTAL = 'EXP ',
    }

    local function AddFilterSelection(group, selection)
        if not selection then
            return
        end

        local names = {}
        local cats = {}

        for _, unit in selection do
            local bp = unit:GetBlueprint()
            local id = bp.BlueprintId
            if not cats[id] then
                names[id] = (TechCategoryList[bp.TechCategory] or "") .. LOC(bp.Description)
                cats[id] = true
            end
        end

        local message = 'Filter contains: '
        for _, unitName in names do
            message = message .. unitName .. ', '
        end

        print(message)

        do
            local cat = ""
            for s in cats do
                cat = cat .. s .. ","
            end
            filters[group] = cat
        end
    end

    local function FilterSelect(group, selection)
        if filters[group] == nil then
            AddFilterSelection(group, selection)
            return
        end

        UISelectionByCategory(filters[group], false, true, false, false)
    end

    ReUI.Core.OnPostCreateUI(function()
        for i = 1, 5 do
            local _i = i
            ReUI.Actions.SelectionAction('Add filter ' .. i,
                function(selection)
                    AddFilterSelection(_i, selection)
                end,
                'FilterSelection')

            ReUI.Actions.SelectionAction('Select filter ' .. i,
                function(selection)
                    FilterSelect(_i, selection)
                end,
                'FilterSelection')
        end
    end)
end
