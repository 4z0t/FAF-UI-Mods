local LuaQ = UMT.LuaQ


-- -- look for template that can be built
-- function availableTemplate(allTemplates, buildable)
--     local effectiveTemplates = {}
--     local effectiveIcons = {}
--     for templateIndex, template in allTemplates do
--         local valid = true
--         for _, entry in template.templateData do
--             if type(entry) == 'table' then
--                 if entry.id then
--                     if not table.find(buildable, entry.id) then -- factory templates
--                         valid = false
--                         break
--                     end
--                 else
--                     if not table.find(buildable, entry[1]) then -- build templates
--                         valid = false
--                         break
--                     end
--                 end
--             end
--         end
--         if valid then
--             template.templateID = templateIndex
--             table.insert(effectiveTemplates, template)
--             table.insert(effectiveIcons, template.icon)
--         end
--     end
--     return effectiveTemplates, effectiveIcons
-- end

function buildActionTemplateContext(modifier, context)
    LOG(context)
    local options = Prefs.GetFromCurrentProfile('options')

    -- Reset everything that could be fading or running
    hideCycleMap()


    -- Find all avaiable templates
    local allTemplates = Templates.GetTemplates()
    if (not allTemplates) or table.empty(allTemplates) then
        return
    end

    local effectiveTemplates = {}
    local effectiveIcons = {}

    local selection = GetSelectedUnits()
    local _, _, buildableCategories = GetUnitCommandData(selection)
    local buildableUnits = EntityCategoryGetUnitList(buildableCategories)

    -- Allow all races to build other races templates
    local currentFaction = selection[1]:GetBlueprint().General.FactionName
    if options.gui_all_race_templates ~= 0 and currentFaction then
        local function ConvertID(BPID)
            local prefixes = {
                ["AEON"] = { "uab", "xab", "dab" },
                ["UEF"] = { "ueb", "xeb", "deb" },
                ["CYBRAN"] = { "urb", "xrb", "drb" },
                ["SERAPHIM"] = { "xsb", "usb", "dsb" },
            }
            for i, prefix in prefixes[string.upper(currentFaction)] do
                if table.find(buildableUnits, string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")) then
                    return string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")
                end
            end
            return false
        end

        for templateIndex, template in allTemplates do
            local valid = true
            local converted = false
            for _, entry in template.templateData do
                if type(entry) == 'table' then
                    if not table.find(buildableUnits, entry[1]) then
                        entry[1] = ConvertID(entry[1])
                        converted = true
                        if not table.find(buildableUnits, entry[1]) then
                            valid = false
                            break
                        end
                    end
                end
            end
            if valid then
                if converted then
                    template.icon = ConvertID(template.icon)
                end
                local found = false
                for _, entry in template.templateData do
                    if type(entry) == 'table' then
                        if entry[1] == context or ConvertID(entry[1]) == ConvertID(context) then
                            found = true
                            break
                        end
                    end
                end
                if found then
                    template.templateID = templateIndex
                    table.insert(effectiveTemplates, template)
                    table.insert(effectiveIcons, template.icon)
                end
            end
        end
    else
        effectiveTemplates, effectiveIcons = availableTemplate(allTemplates, buildableUnits)
    end

    local maxPos = table.getsize(effectiveTemplates)
    if maxPos == 0 then return end

    cycleUnits(maxPos, '_templates' .. context, effectiveIcons, selection, modifier)

    hotbuildCyclePreview()

    local template = effectiveTemplates[cyclePos]
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
                    local tempTemplate = table.deepcopy(template.templateData)
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
end

local _buildActionTemplate = buildActionTemplate
function buildActionTemplate(modifier)

    local info = GetRolloverInfo()
    if info and info.blueprintId ~= "unknown" then
        buildActionTemplateContext(modifier, info.blueprintId)
        return
    end

    _buildActionTemplate(modifier)
end
