local Prefs = import('/lua/user/prefs.lua')
local KeyMapper = import('/lua/keymap/keymapper.lua')
local Templates = import("/lua/ui/game/build_templates.lua")
local FactoryTemplates = import("/lua/ui/templates_factory.lua")


local LINQ = ReUI.LINQ
local Enumerate = LINQ.Enumerate
local ToSet = LINQ.IPairsEnumerator:ToSet()

---@alias SkinName 'cybran'|'seraphim'|'aeon'|'uef'
---@type SkinName[]
local skins = { 'cybran', 'seraphim', 'aeon', 'uef' }

---@class DivisionData
---@field name string
---@field all string[]
---@field any string[]

---@type DivisionData[]
local divisions = {
    {
        name = 'Construction',
        all = {},
        any = { 'BUILTBYTIER3ENGINEER' }
    },
    {
        name = 'Land',
        all = { 'LAND' },
        any = { 'BUILTBYTIER3FACTORY', 'BUILTBYLANDTIER3FACTORY' }
    },
    {
        name = 'Air',
        all = { 'AIR' },
        any = { 'BUILTBYTIER3FACTORY', 'TRANSPORTBUILTBYTIER3FACTORY' }
    },
    {
        name = 'Naval',
        all = { 'NAVAL' },
        any = { 'BUILTBYTIER3FACTORY' }
    },
    {
        name = 'Gate',
        all = {},
        any = { 'BUILTBYQUANTUMGATE' }
    }
}

local legalCategories = ToSet
{
    'BUILTBYTIER1FACTORY', 'BUILTBYTIER2FACTORY',
    'BUILTBYTIER3FACTORY',
    'BUILTBYTIER1ENGINEER', 'BUILTBYTIER2ENGINEER', 'BUILTBYTIER3ENGINEER',
    'BUILTBYCOMMANDER', 'BUILTBYQUANTUMGATE', 'BUILTBYLANDTIER3FACTORY', -- special for sparky
    'TRANSPORTBUILTBYTIER3FACTORY' -- all transports and mercy
}

local sacu = ToSet
{
    "url0301",
    "xsl0301",
    "ual0301",
    "uel0301",
}

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

local function ResetIdRelations()

end

local strLen = string.len

---@alias BPHotbuildData string|table

local hotBuilds
---@type table<string,table<SkinName, BPHotbuildData>>
globalBPs = {}

function ClearHotBuildActions()
    local actions = Prefs.GetFromCurrentProfile("UserKeyActions") or {}
    for name, action in actions do
        if action.category == 'ReUI.Hotbuild' then
            actions[name] = nil
        end
    end
    Prefs.SetToCurrentProfile("UserKeyActions", actions)
end

function FilterBlueprints()
    local bps = Enumerate(__blueprints, next)
        ---@param bp EntityBlueprint
        ---@param id string
        :Where(function(bp, id)
            -- add SACU filter
            if sacu[string.sub(id, 1, 7)] then
                return true
            end
            if strLen(id) == 7 then
                return Enumerate(bp.Categories):Any(function(cat) return legalCategories[cat] end)
            end
            return false
        end)
        :ToTable()

    local templates = Templates.GetTemplates()
    for i, div in divisions do
        globalBPs[div.name] = {}
        for j, skin in skins do
            local upperSkin = string.upper(skin)

            local bpIds = Enumerate(bps, next)
                ---@param bp UnitBlueprint
                :Where(function(bp)
                    local categories = bp.CategoriesHash
                    return categories[upperSkin] and
                        Enumerate(div.all):All(function(cat) return categories[cat] end) and
                        Enumerate(div.any):Any(function(cat) return categories[cat] end)
                end)
                :Keys()
                :ToSet()

            globalBPs[div.name][skin] = Enumerate(bpIds, next)
                :Keys()
                :OrderBy(function(value) return string.sub(value, 4) end)
                :ToArray()

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

            for _, template in templates do
                if CanBuildTemplate(template, bpIds) then
                    table.insert(globalBPs[div.name][skin], template)
                end
            end

        end
    end
end

function AddToUnitkeygroups(name, compiled)
    local formattedName = ReUI.Actions.FormatActionName(name)
    ReUI.Hotbuild.AddHotbuild(formattedName, compiled)
    ReUI.Actions.AddSimpleAction
    {
        formattedName = formattedName,
        description = name,
        action = string.format('UI_Lua ReUI.Hotbuild.ProcessHotbuild("%s")', formattedName),
        category = 'ReUI.Hotbuild',
    }
end

function LoadHotBuilds()
    ClearHotBuildActions()
    hotBuilds = Prefs.GetFromCurrentProfile('hotbuildoverhaul') or {}
    for name, hotbuild in hotBuilds do
        local compiled = Compile(hotbuild)
        AddToUnitkeygroups(name, compiled)
    end
    ResetIdRelations()
end

function FetchHotBuildsKeys()
    return Enumerate(hotBuilds, next)
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

function SaveHotBuild(name, data)
    hotBuilds[name] = FilterEmptyTables(data)
    local compiled = Compile(data)
    AddToUnitkeygroups(name, compiled)
    ResetIdRelations()
    Prefs.SetToCurrentProfile("hotbuildoverhaul", hotBuilds)
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
