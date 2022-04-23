local Prefs = import('/lua/user/prefs.lua')
local Model = import('model.lua')
local From = import('/mods/UMT/modules/linq.lua').From
local active
local activeName

local prefixes = {
    ["aeon"] = {"ua", "xa", "da"},
    ["uef"] = {"ue", "xe", "de"},
    ["cybran"] = {"ur", "xr", "dr"},
    ["seraphim"] = {"xs", "us", "ds"}
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
    active['Construction'] = active['Construction'] or {}
    active['Construction'][index] = active['Construction'][index] or {}
    active['Construction'][index][faction] = bp
end

function SetBlueprint(category, faction, bp)
    active[category] = active[category] or {}
    active[category][faction] = bp
end

function Swap(i1, i2)
    active['Construction'] = active['Construction'] or {}
    local temp = active['Construction'][i1]
    active['Construction'][i1] = active['Construction'][i2]
    active['Construction'][i2] = temp
end

function FillBlueprints(category)
    local activeBP
    local activeFaction
    active[category] = active[category] or {}
    for faction, bp in active[category] do
        if bp then
            if activeBP then
                return
            end
            activeBP = bp
            activeFaction = faction
        end
    end
    if activeBP then
        local suffix = string.sub(activeBP, 3)
        local pref = string.sub(activeBP, 1, 2)
        local prefixId = 1
        for id, prefix in prefixes[activeFaction] do
            if pref == prefix then
                prefixId = id
                break
            end
        end
        for prefixSkin, prefix in prefixes do
            if From(globalBPs[category][prefixSkin]):Contains(prefix[prefixId] .. suffix) then
                SetBlueprint(category, prefixSkin, prefix[prefixId] .. suffix)
            end
        end
    end
end

function ClearBlueprints(category)

end

function FillConstructionBlueprints(index)
    local activeBP
    local activeFaction
    active['Construction'] = active['Construction'] or {}
    active['Construction'][index] = active['Construction'][index] or {}
    for faction, bp in active['Construction'][index] do
        if bp then
            if activeBP then
                return
            end
            activeBP = bp
            activeFaction = faction
        end
    end
    if activeBP then
        local suffix = string.sub(activeBP, 3)
        local pref = string.sub(activeBP, 1, 2)
        local prefixId = 1
        for id, prefix in prefixes[activeFaction] do
            if pref == prefix then
                prefixId = id
                break
            end
        end
        for prefixSkin, prefix in prefixes do
            if From(globalBPs['Construction'][prefixSkin]):Contains(prefix[prefixId] .. suffix) then
                SetConstructionBlueprint(index, prefixSkin, prefix[prefixId] .. suffix)
            end
        end
    end
end

function ClearConstructionBlueprints(index)

end

function FetchHotBuilds(new)
    local hotbuilds = Model.FetchHotBuildsKeys()
    if new then
        table.insert(hotbuilds, 1, '')
    end
    return hotbuilds
end

function FetchConstructionBlueprint(index, faction)
    active['Construction'] = active['Construction'] or {}
    active['Construction'][index] = active['Construction'][index] or {}
    return active['Construction'][index][faction]
end

function FetchBlueprint(category, faction)
    active[category] = active[category] or {}
    return active[category][faction]
end

function FetchConstructionBlueprints()
    return globalBPs['Construction']
end

function FetchBlueprints(category, faction)
    return globalBPs[category][faction]
end

function IsEmpty(index)
    active['Construction'] = active['Construction'] or {}
    active['Construction'][index] = active['Construction'][index] or {}
    return table.empty(active['Construction'][index])
end