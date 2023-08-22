function Make(name, category)
    return {
        name = name,
        category = category
    }
end

local fabsCats = "MASSFABRICATION * STRUCTURE * TECH3, MASSFABRICATION * STRUCTURE * TECH2"
local mexesCats = "MASSEXTRACTION * STRUCTURE * TECH3, MASSEXTRACTION * STRUCTURE * TECH2, MASSEXTRACTION * STRUCTURE * TECH1"
function ToCategory(name)
    return ("{categories.%s}"):format(name)
end

local intelligence = Make("Intelligence", "{STRUCTURE * INTELLIGENCE * OMNI, STRUCTURE * INTELLIGENCE * RADAR}")
local torpedoDefenses = Make("Torpedo defenses", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY}")

local snipers = Make("Snipers", "{categories.XSL0305 + categories.XAL0305}")

local antiAir = Make("AA", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR}")
local mobileAntiAir = Make("MAA", "{categories.LAND * categories.MOBILE * categories.ANTIAIR}")

local massExtractors = Make("Mass (mexes)", "{" .. fabsCats .. "," .. mexesCats .. "}")
local massFabs = Make("Mass (fabs)", "{" .. mexesCats .. "," .. fabsCats .. "}")

local engineers = Make("Engineers",
    "{categories.ENGINEER * categories.TECH3, categories.ENGINEER * categories.TECH2, categories.ENGINEER * categories.TECH1}")

local transports = Make("Transports", ToCategory "TRANSPORTATION")

local pds = Make("Point Defenses",
    "{categories.STRUCTURE * categories.DEFENSE * categories.DIRECTFIRE * categories.TECH3,categories.STRUCTURE * categories.DEFENSE * categories.DIRECTFIRE * categories.TECH2,categories.STRUCTURE * categories.DEFENSE * categories.DIRECTFIRE * categories.TECH1}")

local sonars = Make("Sonars",
    "{categories.MOBILESONAR , categories.STRUCTURE * categories.INTELLIGENCE * categories.SONAR}")

local gunships = Make("Gunships", "{categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL}")

local staticArty = Make("Artillery Installation",
    "{categories.STRUCTURE * categories.ARTILLERY * categories.TECH3, categories.STRUCTURE * categories.ARTILLERY * categories.TECH2}")

local postfixToCategory = {
    -- engineers
    ["l0001"] = Make("ACUs", ToCategory "COMMAND"),
    ["l0301"] = Make("SACUs", ToCategory "SUBCOMMANDER"),
    ["l0105"] = engineers,
    ["l0208"] = engineers,
    ['l0309'] = engineers,
    --air
    ["a0303"] = Make("ASFs", ToCategory "ASF"),
    ["a0304"] = Make("Strat bombers", ToCategory "STRATEGICBOMBER"),
    ["a0107"] = transports,
    ['a0104'] = transports,
    ["a0204"] = Make("Torpedo bombers", "{categories.ANTINAVY * categories.BOMBER * categories.AIR}"),
    ["a0203"] = gunships,
    ['a0305'] = gunships,
    ["a0102"] = Make("Interseptors", "{categories.AIR * categories.MOBILE * categories.ANTIAIR}"),
    [""]      = Make("", ""),

    -- land
    ["l0111"] = Make("MMLs",
        "{categories.LAND * categories.MOBILE * categories.SILO * categories.TECH3, categories.LAND * categories.MOBILE * categories.SILO * categories.TECH2}"),
    ["l0205"] = mobileAntiAir,
    ["l0104"] = mobileAntiAir,


    --naval
    ["s0103"] = Make("Frigates", ToCategory "FRIGATE"),
    ["s0202"] = Make("Cruisers", ToCategory "CRUISER"),
    ["s0201"] = Make("Destroyers", ToCategory "DESTROYER"),
    ["s0302"] = Make("BATTLESHIPs", ToCategory "BATTLESHIP"),
    ["s0303"] = Make("Carriers", ToCategory "NAVALCARRIER"),
    ["s0304"] = Make("Nuke subs", ToCategory "NUKESUB"),
    ["s0305"] = sonars,
    ["b3102"] = sonars,
    ["b3202"] = sonars,
    -- structures
    ["b1105"] = Make("Energy storages", ToCategory "ENERGYSTORAGE"),
    ["b1103"] = massExtractors,
    ["b1202"] = massExtractors,
    ["b1302"] = massExtractors,
    ["b1104"] = massFabs,
    ["b1303"] = massFabs,

    ["b2301"] = pds,
    ["b2101"] = pds,
    ["b4201"] = Make("TMDs", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2}"),
    ["b4302"] = Make("SMDs", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH3}"),
    ["b2303"] = staticArty,
    ["b2302"] = staticArty,
    ["b2305"] = Make("Nukes", "{categories.STRUCTURE * categories.NUKE}"),

    ["b2104"] = antiAir,
    ["b2204"] = antiAir,
    ["b2304"] = antiAir,

    ["b3101"] = intelligence,
    ["b3201"] = intelligence,
    ["b3104"] = intelligence,
    ["b2109"] = torpedoDefenses,
    ["b2205"] = torpedoDefenses,

    [""] = Make("", ""),
}

local landExps = Make("Land Exps", "{categories.LAND * categories.EXPERIMENTAL}")
local airExps = Make("Air Exps", "{categories.AIR * categories.EXPERIMENTAL}")

local specialToCategory =
{
    ["xea0306"] = transports, -- t3 uef transport
    ["xel0209"] = engineers, -- sparky
    ["xaa0306"] = postfixToCategory["a0204"], -- t3 torp bomber
    ["xra0105"] = gunships, -- t1 cybran gunship
    ["xel0306"] = postfixToCategory["l0111"], -- spearhead
    ["xsl0305"] = snipers, -- sera sniper
    ["xal0305"] = snipers, -- aeon sniper
    ["xeb2306"] = pds, -- ravager
    ["xrb2308"] = torpedoDefenses, -- harms
    ["drlk001"] = mobileAntiAir,
    ["dflk002"] = mobileAntiAir,
    ["dalk003"] = mobileAntiAir,
    ["dslk004"] = mobileAntiAir,

    ["uel0401"] = landExps, -- fatty
    ["url0402"] = landExps, -- ml
    ["url0403"] = landExps, -- mega
    ["xsl0401"] = landExps, -- chicken
    ["ual0401"] = landExps, -- gc

    ["uaa0310"] = airExps, -- czar
    ["ura0401"] = airExps, -- bug
    ["xsa0402"] = airExps, -- ahwassa
}



local layerToCategory = {
    ["l"] = Make("Land Units", ToCategory "LAND"),
    ["a"] = Make("Air Units", ToCategory "AIR"),
    ["s"] = Make("Naval Units", ToCategory "NAVAL"),
    ["b"] = Make("Structure Units", ToCategory "STRUCTURE"),
}






---@param bpId string
---@return string?
---@return string?
function Get(bpId)
    if not bpId then
        return
    end

    bpId = string.lower(bpId)

    local data = specialToCategory[bpId]
    if data then
        return data.category, data.name
    end

    local postfix = string.sub(bpId, 3, 7)
    data = postfixToCategory[postfix]
    if data then
        return data.category, data.name
    end

    local catType = string.sub(bpId, 3, 3)
    data = layerToCategory[catType]
    if data then
        return data.category, data.name
    end

end
