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
---@field tech EntityCategory?

---@type DivisionData[]
local divisions = {
    {
        name = 'Construction',
        category = categories.BUILTBYTIER3ENGINEER,
    },
    {
        name = 'Land_T1',
        category = categories.LAND * categories.BUILTBYTIER1FACTORY,
        tech = categories.TECH1,
    },
    {
        name = 'Land_T2',
        category = categories.LAND * categories.BUILTBYTIER2FACTORY,
        tech = categories.TECH2,
    },
    {
        name = 'Land_T3',
        category = categories.LAND * (categories.BUILTBYTIER3FACTORY + categories.BUILTBYLANDTIER3FACTORY),
        tech = categories.TECH3,
    },
    {
        name = 'Air_T1',
        category = categories.AIR * categories.BUILTBYTIER1FACTORY,
        tech = categories.TECH1,
    },
    {
        name = 'Air_T2',
        category = categories.AIR * categories.BUILTBYTIER2FACTORY,
        tech = categories.TECH2,
    },
    {
        name = 'Air_T3',
        category = categories.AIR * (categories.BUILTBYTIER3FACTORY + categories.TRANSPORTBUILTBYTIER3FACTORY),
        tech = categories.TECH3,
    },
    {
        name = 'Naval_T1',
        category = categories.NAVAL * categories.BUILTBYTIER1FACTORY,
        tech = categories.TECH1,
    },
    {
        name = 'Naval_T2',
        category = categories.NAVAL * categories.BUILTBYTIER2FACTORY,
        tech = categories.TECH2,
    },
    {
        name = 'Naval_T3',
        category = categories.NAVAL * categories.BUILTBYTIER3FACTORY,
        tech = categories.TECH3,
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
    local templates = Templates.GetTemplates() or {}
    local factoryTemplates = FactoryTemplates.GetTemplates() or {}

    ---@param div DivisionData
    for _, div in divisions do
        globalBPs[div.name] = {}
        for _, skin in skins do
            local upperSkin = string.upper(skin)

            local category = div.category * categories[upperSkin] * validCategory
            local templateCategory = category

            if div.tech ~= nil then
                ---@type EntityCategory
                category = category * div.tech --[[@diagnostic disable-line:assign-type-mismatch]]
            end

            local bpIds = IPairsEnumerator:Enumerate(EntityCategoryGetUnitList(category)):ToSet()

            globalBPs[div.name][skin] = PairsEnumerator
                :Enumerate(bpIds)
                :Keys()
                :OrderBy(function(value) return string.sub(value, 4) end)
                :ToArray()

            local templateBps = IPairsEnumerator:Enumerate(EntityCategoryGetUnitList(templateCategory)):ToSet()

            for _, template in templates do
                if CanBuildTemplate(template, templateBps) then
                    table.insert(globalBPs[div.name][skin], template)
                end
            end

            for _, template in factoryTemplates do
                if CanBuildFactoryTemplate(template, templateBps) then
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
