function setSelection(expression)
    local others = utils.StringJoin(expression.others, " ")

    local units
    UMT.Units.HiddenSelect(function()
        ConExecute("Ui_SelectByCategory " .. others)
        units = GetSelectedUnits()
    end)

    for k, v in expression.negatives do
        if units ~= nil then
            units = EntityCategoryFilterOut(categories[v], units)
        end
    end

    SelectUnits(units)
end
