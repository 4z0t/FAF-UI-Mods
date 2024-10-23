local Factions = import("/lua/factions.lua").Factions
local FactionInUnitBpToKey = import("/lua/factions.lua").FactionInUnitBpToKey
local TemplateUtils = import("/mods/ContextTemplates/modules/TemplateUtils.lua")
local LuaQ = UMT.LuaQ

function buildActionTemplateContext(modifier, context)
    local options = Prefs.GetFromCurrentProfile('options')

    -- Reset everything that could be fading or running
    hideCycleMap()

    -- Find all avaiable templates
    local allTemplates = Templates.GetTemplates()
    if not allTemplates or table.empty(allTemplates) then
        return false
    end

    local effectiveTemplates = {}
    local effectiveIcons = {}

    local selection = GetSelectedUnits()
    local _, _, buildableCategories = GetUnitCommandData(selection)
    local buildableUnits = EntityCategoryGetUnitList(buildableCategories)

    local buildableUnitsSet = buildableUnits | LuaQ.toSet
    local unitFactionName = selection[1]:GetBlueprint().General.FactionName
    local currentFaction = Factions[ FactionInUnitBpToKey[unitFactionName] ]
    local prefixes = currentFaction.GAZ_UI_Info.BuildingIdPrefixes or {}
    local function ConvertID(BPID)
        for i, prefix in prefixes do
            local convertedID = string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")
            if buildableUnitsSet[convertedID] then
                return convertedID
            end
        end
        return false
    end

    if options.gui_all_race_templates ~= 0 and currentFaction then
        for templateIndex, template in allTemplates do
            local valid = true
            local converted = false
            for _, entry in template.templateData do
                if type(entry) == 'table' then
                    if not buildableUnitsSet[ entry[1] ] then
                        local convertedID = ConvertID(entry[1])
                        converted = true
                        if not buildableUnitsSet[convertedID] then
                            valid = false
                            break
                        end
                    end
                end
            end

            if not valid then continue end

            if converted then
                template.icon = ConvertID(template.icon)
            end
            local found = false
            local index = nil
            for i, entry in template.templateData do
                if type(entry) == 'table' then
                    if entry[1] == context or ConvertID(entry[1]) == ConvertID(context) then
                        found = true
                        index = i
                        break
                    end
                end
            end
            if found then
                template = TemplateUtils.CenterTemplateToIndex(template, index)
                template.templateID = templateIndex
                table.insert(effectiveTemplates, template)
                table.insert(effectiveIcons, template.icon)
            end

        end
    else
        effectiveTemplates, effectiveIcons = availableTemplate(allTemplates, buildableUnits)
    end

    local maxPos = table.getsize(effectiveTemplates)
    if maxPos == 0 then
        return false
    end

    cycleUnits(maxPos, '_templates' .. context, effectiveIcons, selection, modifier)

    hotbuildCyclePreview()

    local template = TemplateUtils.ConvertTemplate(effectiveTemplates[cyclePos], ConvertID)
    local cmd = template.templateData[3][1]

    ClearBuildTemplates()
    CommandMode.StartCommandMode("build", { name = cmd })
    SetActiveBuildTemplate(template.templateData)

    if options.gui_template_rotator ~= 0 then
        -- Rotating templates
        local worldview = import("/lua/ui/game/worldview.lua").viewLeft
        local oldHandleEvent = worldview.HandleEvent
        worldview.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if event.Modifiers.Middle then
                    ClearBuildTemplates()
                    local tempTemplate = template.templateData
                    template.templateData[1] = tempTemplate[2]
                    template.templateData[2] = tempTemplate[1]
                    for i = 3, table.getn(template.templateData) do
                        local index = i
                        template.templateData[index][3] = 0 - tempTemplate[index][4]
                        template.templateData[index][4] = tempTemplate[index][3]
                    end
                    SetActiveBuildTemplate(template.templateData)
                elseif not event.Modifiers.Shift then
                    worldview.HandleEvent = oldHandleEvent
                end
            end
        end
    end
    return true
end

local _buildActionTemplate = buildActionTemplate
function buildActionTemplate(modifier)

    local info = GetRolloverInfo()
    if info and info.blueprintId ~= "unknown" then
        if __blueprints[info.blueprintId].CategoriesHash["STRUCTURE"] then
            if buildActionTemplateContext(modifier, info.blueprintId) then
                return
            end
        end
    end

    _buildActionTemplate(modifier)
end
