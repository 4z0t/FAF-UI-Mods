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
        name = 'Land',
        category = categories.LAND * (categories.BUILTBYTIER3FACTORY + categories.BUILTBYLANDTIER3FACTORY),
    },
    {
        name = 'Air',
        category = categories.AIR * (categories.BUILTBYTIER3FACTORY + categories.TRANSPORTBUILTBYTIER3FACTORY),
    },
    {
        name = 'Naval',
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

function Compile(data)
    local res = {}
    for category, dat in data do
        if category == 'Construction' then
            for index, bps in dat do
                for faction, bp in bps do
                    table.insert(res, bp)
                end
            end
        else
            for faction, bp in dat do
                table.insert(res, bp)
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
    LOG(validCategory)
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
end

function AddToUnitkeygroups(name, compiled)
    local formattedName = ReUI.Actions.FormatActionName(name:lower())
    ReUI.Hotbuild.AddHotbuild(formattedName, compiled)
    local unitkeygroups = import("/lua/keymap/unitkeygroups.lua").unitkeygroups
    unitkeygroups[formattedName] = Enumerate(compiled)
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
    data.Construction = Enumerate(data.Construction)
        :Where(function(bps) return not table.empty(bps) end)
        :ToArray()
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
