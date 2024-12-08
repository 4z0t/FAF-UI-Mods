function OffsetOn(template, x, y)
    for _, entry in template.templateData do
        if type(entry) == 'table' then
            entry[3], entry[4] = entry[3] - x, entry[4] - y
        end
    end
    return template
end

function CenterTemplateToIndex(template, index)
    local template = table.deepcopy(template)
    local entry = template.templateData[index]
    local x, y = entry[3], entry[4]
    return OffsetOn(template, x, y)
end

function ConvertTemplate(template, converter)
    local newTemplate = template | UMT.LuaQ.deepcopy
    for i, entry in newTemplate.templateData do
        if type(entry) == 'table' then
            entry[1] = converter(entry[1])
        end
    end
    return newTemplate
end
