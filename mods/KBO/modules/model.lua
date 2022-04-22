local Prefs = import('/lua/user/prefs.lua')
local From = import('/mods/UMT/modules/linq.lua').From

local skins = {'cybran', 'seraphim', 'aeon', 'uef'}

local divisions = {{
    name = 'Construction',
    all = {},
    any = {'BUILTBYTIER3ENGINEER'}
}, {
    name = 'Land',
    all = {'LAND'},
    any = {'BUILTBYTIER3FACTORY', 'BUILTBYLANDTIER3FACTORY'}
}, {
    name = 'Air',
    all = {'AIR'},
    any = {'BUILTBYTIER3FACTORY', 'TRANSPORTBUILTBYTIER3FACTORY'}
}, {
    name = 'Naval',
    all = {'NAVAL'},
    any = {'BUILTBYTIER3FACTORY'}
}, {
    name = 'Gate',
    all = {},
    any = {'BUILTBYQUANTUMGATE'}
}}

local legalCategories = From({'BUILTBYTIER1FACTORY', 'BUILTBYTIER2FACTORY', 'BUILTBYTIER3FACTORY',
                              'BUILTBYTIER1ENGINEER', 'BUILTBYTIER2ENGINEER', 'BUILTBYTIER3ENGINEER',
                              'BUILTBYCOMMANDER', 'BUILTBYQUANTUMGATE', 'BUILTBYLANDTIER3FACTORY', -- special for sparky
'TRANSPORTBUILTBYTIER3FACTORY' -- all transports and mercy
})

local sacu = {
    ["url0301"] = true,
    ["xsl0301"] = true,
    ["ual0301"] = true,
    ["uel0301"] = true
}

local strLen = string.len

local hotBuilds = Prefs.GetFromCurrentProfile('hotbuildoverhaul') or {}
globalBPs = {}

function init()
    FilterBlueprints()
end

function FilterBlueprints()
    local bps = From(__blueprints):Where(function(id, bp)
        -- add SACU filter
        if sacu[string.sub(id, 1, 7)] then
            return true
        end
        if strLen(id) == 7 then
            return From(bp.Categories):Any(function(i, cat)
                return legalCategories:Contains(cat)
            end)
        end
        return false
    end)

    From(divisions):Foreach(function(i, div)
        globalBPs[div.name] = {}
        From(skins):Foreach(function(k, skin)

            local upperSkin = string.upper(skin)
            globalBPs[div.name][skin] = bps:Where(function(id, bp)
                local categories = From(bp.Categories)
                return categories:Contains(upperSkin) and From(div.all):All(function(_, cat)
                    return categories:Contains(cat)
                end) and From(div.any):Any(function(_, cat)
                    return categories:Contains(cat)
                end)
            end):Keys():Sort(function(a, b)
                return string.sub(a, 4) < string.sub(b, 4)
            end):ToDictionary()
        end)
    end)
end

function FetchHotBuild(id)
    local data = hotBuilds[id]
    if data then
        return table.deepcopy(data)
    end
    return {}

end

-- local ModifyBuildables = import('/lua/ui/notify/enhancementqueue.lua').ModifyBuildablesForACU
-- local selection = GetSelectedUnits()
-- local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)
-- local newBuildableCategories = ModifyBuildables(buildableCategories, selection)
-- local buildable = EntityCategoryGetUnitList(buildableCategories)
-- LOG(repr(buildable))
