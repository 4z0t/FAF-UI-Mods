local filters = {}

local TechCategoryList = {
    TECH1 = 'T1 ',
    TECH2 = 'T2 ',
    TECH3 = 'T3 ',
    EXPERIMENTAL = 'EXP ',
}

function AddFilterSelection(group)
    local selection = GetSelectedUnits()
    if not selection then
        return
    end

    local names = {}
    local cats = {}

    for _, unit in selection do
        local bp = unit:GetBlueprint()
        cats[bp.BlueprintId] = true
        names[bp.BlueprintId] = (TechCategoryList[bp.TechCategory] or "") .. LOC(bp.Description)
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

function FilterSelect(group)
    if filters[group] == nil then return AddFilterSelection(group) end

    LOG(filters[group])
    UISelectionByCategory(filters[group], false, true, false, false)
end

function Main()

    local KeyMapper = import('/lua/keymap/keymapper.lua')

    for i = 1, 5 do
        KeyMapper.SetUserKeyAction('add filter ' .. i,
            {
                action = "UI_Lua import('/mods/FilterSelection/modules/Main.lua').AddFilterSelection(" .. i .. ")",
                category = 'FilterSelection'
            })
        KeyMapper.SetUserKeyAction('select filter ' .. i,
            {
                action = "UI_Lua import('/mods/FilterSelection/modules/Main.lua').FilterSelect(" .. i .. ")",
                category = 'FilterSelection'
            })
    end
end
