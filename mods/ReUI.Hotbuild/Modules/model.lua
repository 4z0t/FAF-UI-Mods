local Prefs = import('/lua/user/prefs.lua')
local KeyMapper = import('/lua/keymap/keymapper.lua')
local Templates = import("/lua/ui/game/build_templates.lua")
local FactoryTemplates = import("/lua/ui/templates_factory.lua")


local Enumerate = ReUI.LINQ.Enumerate
local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
local PairsEnumerator = ReUI.LINQ.PairsEnumerator

---@alias SkinName 'cybran'|'seraphim'|'aeon'|'uef'
---@type SkinName[]
local skins = { 'cybran', 'seraphim', 'aeon', 'uef' }

---@class DivisionData
---@field name string
---@field category EntityCategory

---@type DivisionData[]
local divisions = {
    {
        name = 'Construction',
        category = categories.BUILTBYTIER3ENGINEER,
    },
    {
        name = 'Land_T1',
        category = categories.LAND * categories.BUILTBYTIER1FACTORY,
    },
    {
        name = 'Land_T2',
        category = categories.LAND * categories.BUILTBYTIER2FACTORY,
    },
    {
        name = 'Land_T3',
        category = categories.LAND * (categories.BUILTBYTIER3FACTORY + categories.BUILTBYLANDTIER3FACTORY),
    },
    {
        name = 'Air_T1',
        category = categories.AIR * categories.BUILTBYTIER1FACTORY,
    },
    {
        name = 'Air_T2',
        category = categories.AIR * categories.BUILTBYTIER2FACTORY,
    },
    {
        name = 'Air_T3',
        category = categories.AIR * (categories.BUILTBYTIER3FACTORY + categories.TRANSPORTBUILTBYTIER3FACTORY),
    },
    {
        name = 'Naval_T1',
        category = categories.NAVAL * categories.BUILTBYTIER1FACTORY,
    },
    {
        name = 'Naval_T2',
        category = categories.NAVAL * categories.BUILTBYTIER2FACTORY,
    },
    {
        name = 'Naval_T3',
        category = categories.NAVAL * categories.BUILTBYTIER3FACTORY,
    },
    {
        name = 'Gate',
        category = categories.BUILTBYQUANTUMGATE,
    }
}

local validCategory = categories.BUILTBYTIER1FACTORY +
    categories.BUILTBYTIER2FACTORY +
    categories.BUILTBYTIER3FACTORY +
    categories.BUILTBYTIER1ENGINEER +
    categories.BUILTBYTIER2ENGINEER +
    categories.BUILTBYTIER3ENGINEER +
    categories.BUILTBYCOMMANDER +
    categories.BUILTBYQUANTUMGATE +
    categories.BUILTBYLANDTIER3FACTORY +
    categories.TRANSPORTBUILTBYTIER3FACTORY

function GetBlueprintTech(bp)
    local bpId = bp
    if type(bp) == "table" then
        bpId = bp.icon
        if not bpId and bp.templateData and bp.templateData[1] then
            bpId = bp.templateData[1].id
        end
        if not bpId and bp.templateData and bp.templateData[3] then
            bpId = bp.templateData[3][1]
        end
    end
    if type(bpId) ~= "string" then
        return nil
    end
    local blueprint = __blueprints[bpId]
    if blueprint then
        local hash = blueprint.CategoriesHash
        if hash then
            if hash.TECH1 then return 1 end
            if hash.TECH2 then return 2 end
            if hash.TECH3 then return 3 end
            if hash.EXPERIMENTAL then return 3 end
        end
        if blueprint.Categories then
            for _, cat in ipairs(blueprint.Categories) do
                if cat == "TECH1" then return 1
                elseif cat == "TECH2" then return 2
                elseif cat == "TECH3" then return 3
                elseif cat == "EXPERIMENTAL" then return 3
                end
            end
        end
    end
    -- Fallback by ID naming convention (e.g. uel0104 -> 1, uel0205 -> 2, delk002 -> 3)
    local _, _, tierChar = string.find(bpId, "%a+0(%d)")
    if tierChar then
        local t = tonumber(tierChar)
        if t and t >= 1 and t <= 3 then
            return t
        elseif t and t >= 4 then
            return 3
        end
    end
    return 1
end

function MigrateHotBuild(data)
    if not data or type(data) ~= "table" then
        return data
    end

    local factoryLayers = { "Land", "Air", "Naval" }

    -- 1. Migrate legacy Land, Air, Naval tables into tech-specific slots
    for _, layer in ipairs(factoryLayers) do
        local legacy = data[layer]
        if legacy and type(legacy) == "table" and not table.empty(legacy) then
            for faction, bp in pairs(legacy) do
                if bp then
                    local tech = GetBlueprintTech(bp) or 1
                    local targetCat = string.format("%s_T%d", layer, tech)
                    data[targetCat] = data[targetCat] or {}
                    if not data[targetCat][faction] then
                        data[targetCat][faction] = bp
                    end
                end
            end
            data[layer] = nil
        end
    end

    -- 2. Repair any previous faulty migration where Land/Air/Naval was dumped into T3
    --    even though the units were actually Tech 1 or Tech 2.
    for _, layer in ipairs(factoryLayers) do
        local t3Cat = layer .. "_T3"
        if data[t3Cat] and type(data[t3Cat]) == "table" then
            for faction, bp in pairs(data[t3Cat]) do
                if bp then
                    local tech = GetBlueprintTech(bp)
                    if tech and tech < 3 then
                        local actualCat = string.format("%s_T%d", layer, tech)
                        data[actualCat] = data[actualCat] or {}
                        if not data[actualCat][faction] then
                            data[actualCat][faction] = bp
                            data[t3Cat][faction] = nil
                        end
                    end
                end
            end
        end

        local t2Cat = layer .. "_T2"
        if data[t2Cat] and type(data[t2Cat]) == "table" then
            for faction, bp in pairs(data[t2Cat]) do
                if bp then
                    local tech = GetBlueprintTech(bp)
                    if tech and tech == 1 then
                        local actualCat = layer .. "_T1"
                        data[actualCat] = data[actualCat] or {}
                        if not data[actualCat][faction] then
                            data[actualCat][faction] = bp
                            data[t2Cat][faction] = nil
                        end
                    end
                end
            end
        end
    end

    return data
end

function Compile(data)
    local res = {}
    for category, dat in pairs(data) do
        if category == 'Construction' then
            for index, bps in pairs(dat) do
                for faction, bp in pairs(bps) do
                    table.insert(res, bp)
                end
            end
        else
            for k, val in pairs(dat) do
                if type(val) == "string" or (type(val) == "table" and val.templateData) then
                    table.insert(res, val)
                elseif type(val) == "table" then
                    for faction, bp in pairs(val) do
                        table.insert(res, bp)
                    end
                end
            end
        end
    end
    return res
end

local function ResetIdRelations(hotBuilds)
    import('/lua/keymap/hotkeylabels.lua').init()
end

---@alias BPHotbuildData string|table

local hotBuilds
---@type table<string,table<SkinName, BPHotbuildData[]>>
globalBPs = {}

local function CanBuildTemplate(template, bpIds)
    local templateData = template.templateData
    for i = 3, table.getn(templateData) do
        local entry = templateData[i]
        local id = entry[1]
        if not id or not bpIds[id] then
            return false
        end
    end
    return true
end

local function CanBuildFactoryTemplate(template, bpIds)
    local templateData = template.templateData
    for _, entry in ipairs(templateData) do
        if not bpIds[entry.id] then
            return false
        end
    end
    return true
end

function FilterBlueprints()
    local bps = PairsEnumerator
        :Enumerate(__blueprints)
        ---@param bp EntityBlueprint
        ---@param id string
        :Where(function(bp, id)
            return type(id) == "string" and
                EntityCategoryContains(validCategory, id)
        end)
        :ToTable()

    local templates = Templates.GetTemplates() or {}
    local factoryTemplates = FactoryTemplates.GetTemplates() or {}

    ---@param div DivisionData
    for _, div in divisions do
        globalBPs[div.name] = {}
        for _, skin in skins do
            local upperSkin = string.upper(skin)
            local category = div.category * categories[upperSkin]

            local bpIds = PairsEnumerator
                :Enumerate(bps)
                ---@param bp UnitBlueprint
                :Where(function(bp)
                    return EntityCategoryContains(category, bp.BlueprintId)
                end)
                :Keys()
                :ToSet()

            globalBPs[div.name][skin] = PairsEnumerator
                :Enumerate(bpIds)
                :Keys()
                :OrderBy(function(value) return string.sub(value, 4) end)
                :ToArray()

            for _, template in templates do
                if CanBuildTemplate(template, bpIds) then
                    table.insert(globalBPs[div.name][skin], template)
                end
            end

            for _, template in factoryTemplates do
                if CanBuildFactoryTemplate(template, bpIds) then
                    table.insert(globalBPs[div.name][skin], template)
                end
            end
        end
    end

    -- Backwards compatibility aliases
    globalBPs['Land'] = globalBPs['Land_T3']
    globalBPs['Air'] = globalBPs['Air_T3']
    globalBPs['Naval'] = globalBPs['Naval_T3']
end

function AddToUnitkeygroups(name, compiled)
    local formattedName = ReUI.Actions.FormatActionName(name:lower())
    ReUI.Hotbuild.AddHotbuild(formattedName, compiled)
    local unitkeygroups = import("/lua/keymap/unitkeygroups.lua").unitkeygroups
    unitkeygroups[formattedName] = IPairsEnumerator
        :Enumerate(compiled)
        :Select(function(value)
            if type(value) == 'string' then
                return value
            end
            return value.templateData[3][1] or false
        end)
        :Where(function(value) return value end)
        :ToArray()

    ReUI.Actions.AddSimpleAction
    {
        formattedName = formattedName,
        description = name,
        action = string.format('UI_Lua ReUI.Hotbuild.ProcessHotbuild("%s")', formattedName),
        category = 'ReUI.Hotbuild',
        modifiers = { shift = true, alt = true }
    }
end

function LoadHotBuilds()
    hotBuilds = Prefs.GetFromCurrentProfile('hotbuildoverhaul') or {}
    for name, hotbuild in hotBuilds do
        MigrateHotBuild(hotbuild)
        local compiled = Compile(hotbuild)
        AddToUnitkeygroups(name, compiled)
    end
    ResetIdRelations(hotBuilds)
end

function FetchHotBuildsKeys()
    return PairsEnumerator
        :Enumerate(hotBuilds)
        :Keys()
        :ToArray()
end

function FilterEmptyTables(data)
    data = table.deepcopy(data)
    if data.Construction then
        data.Construction = IPairsEnumerator
            :Enumerate(data.Construction)
            :Where(function(bps) return not table.empty(bps) end)
            :ToArray()
    end
    return data
end

function SaveHotBuild(name, data, save)
    hotBuilds[name] = FilterEmptyTables(data)
    local compiled = Compile(data)
    AddToUnitkeygroups(name, compiled)
    ResetIdRelations(hotBuilds)
    Prefs.SetToCurrentProfile("hotbuildoverhaul", hotBuilds)
    if save then
        SavePreferences()
    end
end

function DelHotBuild(name)
    if name then
        hotBuilds[name] = nil
        Prefs.SetToCurrentProfile("hotbuildoverhaul", hotBuilds)
    end
end

function FetchHotBuild(id)
    local data = hotBuilds[id]
    if data then
        return table.deepcopy(data)
    end
    return {}
end

function init()
    FilterBlueprints()
    LoadHotBuilds()
    import("/lua/keymap/hotbuild.lua").addModifiers()
end
