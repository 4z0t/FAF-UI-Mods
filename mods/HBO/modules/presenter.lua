local Prefs = import("/lua/user/prefs.lua")
local Model = import("model.lua")
local From = import("/mods/UMT/modules/linq.lua").From
local active
local activeName

local prefixes = {
    ["aeon"] = {"ua", "xa", "da", "za"},
    ["uef"] = {"ue", "xe", "de", "ze"},
    ["cybran"] = {"ur", "xr", "dr", "zr"},
    ["seraphim"] = {"xs", "us", "ds", "zs"}
}
local globalBPs

function init()
    globalBPs = Model.globalBPs
end

function SaveActive(name)
    Model.DelHotBuild(activeName)
    if name and name ~= "" then
        Model.SaveHotBuild(name, active)
        activeName = name
    end
end

function SetActive(name)
    activeName = name or ""
    active = Model.FetchHotBuild(activeName)
end

function AddConstructionBlueprints()

end

function SetConstructionBlueprint(index, faction, bp)
    active["Construction"] = active["Construction"] or {}
    active["Construction"][index] = active["Construction"][index] or {}
    active["Construction"][index][faction] = bp
end

function SetBlueprint(category, faction, bp)
    active[category] = active[category] or {}
    active[category][faction] = bp
end

function Swap(i1, i2)
    active["Construction"] = active["Construction"] or {}
    local temp = active["Construction"][i1]
    active["Construction"][i1] = active["Construction"][i2]
    active["Construction"][i2] = temp
end

local function SingleBlueprint(bps)
    local activeBP
    local activeFaction
    for faction, bp in bps do
        if bp then
            if activeBP then
                return
            end
            activeBP = bp
            activeFaction = faction
        end
    end
    return activeFaction, activeBP
end
local similars = From({{
    ["aeon"] = "xal0305",
    ["uef"] = "xel0305",
    ["cybran"] = "xrl0305",
    ["seraphim"] = "xsl0305"
}, -- Snipers/Armored assault bots
{
    ["aeon"] = "xaa0202",
    ["uef"] = "dea0202",
    ["cybran"] = "dra0202",
    ["seraphim"] = "xsa0202"
}, -- t2 aa/bombers
{
    ["aeon"] = "ual0307",
    ["uef"] = "uel0307",
    ["cybran"] = "url0306",
    ["seraphim"] = "xsl0307"
}, -- land suppport units
{
    ["aeon"] = "dalk003",
    ["uef"] = "delk002",
    ["cybran"] = "drlk001",
    ["seraphim"] = "dslk004"
}, -- T3 MAA
{
    ["aeon"] = "xaa0305",
    ["uef"] = "uea0305",
    ["cybran"] = "xra0305"
} -- T3 gunships
})

local function FindSimilarBlueprints(faction, bp, category)
    local suffix = string.sub(bp, 3)
    local pref = string.sub(bp, 1, 2)
    local prefixId = 1
    for id, prefix in prefixes[faction] do
        if pref == prefix then
            prefixId = id
            break
        end
    end
    local bps = similars:First(function(k, v)
        return v[faction] == bp
    end)
    if not bps then
        bps = {}
        for prefixSkin, prefix in prefixes do
            if From(globalBPs[category][prefixSkin]):Contains(prefix[prefixId] .. suffix) then
                bps[prefixSkin] = prefix[prefixId] .. suffix
            end
        end
    end
    return bps
end

function FillBlueprints(category)
    local activeBP
    local activeFaction
    active[category] = active[category] or {}
    activeFaction, activeBP = SingleBlueprint(active[category])
    if activeBP then
        local bps = FindSimilarBlueprints(activeFaction, activeBP, category)
        for faction, bp in bps do
            SetBlueprint(category, faction, bp)
        end
    end
end

function ClearBlueprints(category)

end

function FetchConstructionCount()
    return table.getn(active["Construction"] or {}) + 1
end

function FillConstructionBlueprints(index)
    local activeBP
    local activeFaction

    active["Construction"] = active["Construction"] or {}
    active["Construction"][index] = active["Construction"][index] or {}
    activeFaction, activeBP = SingleBlueprint(active["Construction"][index])
    if activeBP then
        local bps = FindSimilarBlueprints(activeFaction, activeBP, "Construction")
        for faction, bp in bps do
            SetConstructionBlueprint(index, faction, bp)
        end
    end
end

function ClearConstructionBlueprints(index)

end

function FetchHotBuilds(new)
    local hotbuilds = Model.FetchHotBuildsKeys()
    if new then
        table.insert(hotbuilds, 1, "")
    end
    return hotbuilds
end

function FetchConstructionBlueprint(index, faction)
    active["Construction"] = active["Construction"] or {}
    active["Construction"][index] = active["Construction"][index] or {}
    return active["Construction"][index][faction]
end

function FetchBlueprint(category, faction)
    active[category] = active[category] or {}
    return active[category][faction]
end

function FetchConstructionBlueprints()
    return globalBPs["Construction"]
end

function FetchBlueprints(category, faction)
    return globalBPs[category][faction]
end

function IsEmpty(index)
    active["Construction"] = active["Construction"] or {}
    active["Construction"][index] = active["Construction"][index] or {}
    return table.empty(active["Construction"][index])
end
