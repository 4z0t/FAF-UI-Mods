function Make(name, category)
    return {
        name = name,
        category = category
    }
end

function TechDecreased(cat)
    return ("{(%s) * TECH3, (%s) * TECH2, (%s) * TECH1}"):format(cat, cat, cat)
end

local fabsCats = "MASSFABRICATION * STRUCTURE * TECH3, MASSFABRICATION * STRUCTURE * TECH2"
local mexesCats = "MASSEXTRACTION * STRUCTURE * TECH3, MASSEXTRACTION * STRUCTURE * TECH2, MASSEXTRACTION * STRUCTURE * TECH1"
local maaCat = "categories.LAND * categories.MOBILE * categories.ANTIAIR"
local aaCat = "categories.STRUCTURE * categories.DEFENSE * categories.ANTIAIR"

function ToCategory(name)
    return ("{categories.%s}"):format(name)
end

local intelligence = Make("Intelligence", "{STRUCTURE * INTELLIGENCE * OMNI, STRUCTURE * INTELLIGENCE * RADAR}")
local torpedoDefenses = Make("Torpedo defenses", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY}")

local snipers = Make("Snipers", "{categories.XSL0305 + categories.XAL0305}")

local antiAir = Make("AA", "{" .. aaCat .. "," .. maaCat .. "}")
local mobileAntiAir = Make("MAA", "{" .. maaCat .. "," .. aaCat .. "}")

local massFabs = Make("Mass (fabs)", "{" .. fabsCats .. "," .. mexesCats .. "}")
local massExtractors = Make("Mass (mexes)", "{" .. mexesCats .. "," .. fabsCats .. "}")

local power = Make("Power", TechDecreased "ENERGYPRODUCTION * STRUCTURE")

local engineers = Make("Engineers",
    "{categories.ENGINEER * categories.TECH3, categories.ENGINEER * categories.TECH2, categories.ENGINEER * categories.TECH1}")

local transports = Make("Transports", ToCategory "TRANSPORTATION")

local pds = Make("Point Defenses", TechDecreased "STRUCTURE * DEFENSE * DIRECTFIRE")

local sonars = Make("Sonars",
    "{categories.MOBILESONAR , categories.STRUCTURE * categories.INTELLIGENCE * categories.SONAR}")

local gunships = Make("Gunships", "{categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL}")

local staticArty = Make("Artillery Installation",
    "{categories.STRUCTURE * categories.ARTILLERY * categories.TECH3, categories.STRUCTURE * categories.ARTILLERY * categories.TECH2}")


local mobileArty = Make("Mobile Artillery", "{categories.Mobile * categories.ARTILLERY}")

local factory = Make("Factories", TechDecreased "FACTORY * STRUCTURE")

local scouts = Make("Scouts", ToCategory "SCOUT")

local staticShield = Make("Static Shields", "STRUCTURE * SHIELD")

local postfixToCategory = {
    -- engineers
    ["l0001"] = Make("ACUs", ToCategory "COMMAND"),
    ["l0301"] = Make("SACUs", ToCategory "SUBCOMMANDER"),
    ["l0105"] = engineers,
    ["l0208"] = engineers,
    ['l0309'] = engineers,

    ["b0101"] = factory,
    ["b0102"] = factory,
    ["b0103"] = factory,

    ["b0201"] = factory,
    ["b0202"] = factory,
    ["b0203"] = factory,

    ["b0301"] = factory,
    ["b0302"] = factory,
    ["b0303"] = factory,
    ["b0304"] = factory, -- gate

    ["b9501"] = factory, -- t2 hq land
    ["b9502"] = factory, -- t2 hq air
    ["b9503"] = factory, -- t2 hq naval

    ["b9601"] = factory, -- t3 hq land
    ["b9602"] = factory, -- t3 hq air
    ["b9603"] = factory, -- t3 hq naval

    --air
    ["a0303"] = Make("ASFs", ToCategory "ASF"),
    ["a0304"] = Make("Strat bombers", ToCategory "STRATEGICBOMBER"),
    ["a0107"] = transports,
    ['a0104'] = transports,
    ["a0204"] = Make("Torpedo bombers", "{categories.ANTINAVY * categories.BOMBER * categories.AIR}"),
    ["a0203"] = gunships,
    ['a0305'] = gunships,
    ["a0102"] = Make("Interseptors", "{categories.AIR * categories.MOBILE * categories.ANTIAIR}"),

    ["a0101"] = scouts, -- air scout
    ["a0302"] = scouts, -- spy plane

    -- land
    ["l0111"] = Make("MMLs",
        "{categories.LAND * categories.MOBILE * categories.SILO * categories.TECH3, categories.LAND * categories.MOBILE * categories.SILO * categories.TECH2}"),
    ["l0205"] = mobileAntiAir,
    ["l0104"] = mobileAntiAir,
    ["l0304"] = mobileArty,
    ["l0101"] = scouts,

    --naval
    ["s0103"] = Make("Frigates", ToCategory "FRIGATE"),
    ["s0202"] = Make("Cruisers", ToCategory "CRUISER"),
    ["s0201"] = Make("Destroyers", ToCategory "DESTROYER"),
    ["s0302"] = Make("Battleships", ToCategory "BATTLESHIP"),
    ["s0303"] = Make("Carriers", ToCategory "NAVALCARRIER"),
    ["s0304"] = Make("Nuke subs", ToCategory "NUKESUB"),
    ["s0305"] = sonars,
    ["b3102"] = sonars,
    ["b3202"] = sonars,

    -- structures

    --economy
    ["b1105"] = Make("Energy storages", ToCategory "ENERGYSTORAGE"),
    ["b1106"] = Make("Mass storages", ToCategory "MASSSTORAGE"),
    ["b1103"] = massExtractors,
    ["b1202"] = massExtractors,
    ["b1302"] = massExtractors,
    ["b1104"] = massFabs,
    ["b1303"] = massFabs,
    ["b1102"] = power,
    ["b1101"] = power,
    ["b1201"] = power,
    ["b1301"] = power,


    -- defense
    ["b2301"] = pds,
    ["b2101"] = pds,
    ["b4201"] = Make("TMDs", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2}"),
    ["b4302"] = Make("SMDs", "{categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH3}"),

    ["b2104"] = antiAir,
    ["b2204"] = antiAir,
    ["b2304"] = antiAir,

    ["b2109"] = torpedoDefenses,
    ["b2205"] = torpedoDefenses,

    ["b2108"] = Make("TMLs", "STRUCTURE * SILO * TECH2"),

    ["b4301"] = staticShield,
    ["b4202"] = staticShield,

    -- strategic
    ["b2302"] = staticArty,
    ["b2303"] = staticArty,
    ["b2305"] = Make("Nukes", "{categories.STRUCTURE * categories.NUKE}"),

    -- intelligence
    ["b3101"] = intelligence,
    ["b3201"] = intelligence,
    ["b3104"] = intelligence,

    [""] = Make("", ""),
}

local landExps = Make("Land Exps", "{categories.LAND * categories.EXPERIMENTAL}")
local airExps = Make("Air Exps", "{categories.AIR * categories.EXPERIMENTAL}")

local droneStations = Make("Drone stations", "{XEB0204 + XRB0304, XRB0204 + XEB0104, XRB0104}")

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

    ["urb4204"] = staticShield, -- cybran shield stage
    ["urb4205"] = staticShield, -- cybran shield stage
    ["urb4206"] = staticShield, -- cybran shield stage
    ["urb4207"] = staticShield, -- cybran shield stage

    ["drlk001"] = mobileAntiAir,
    ["delk002"] = mobileAntiAir,
    ["dalk003"] = mobileAntiAir,
    ["dslk004"] = mobileAntiAir,

    ["uel0401"] = landExps, -- fatty
    ["url0402"] = landExps, -- ml
    ["xrl0403"] = landExps, -- mega
    ["xsl0401"] = landExps, -- chicken
    ["ual0401"] = landExps, -- gc

    ["uaa0310"] = airExps, -- czar
    ["ura0401"] = airExps, -- bug
    ["xsa0402"] = airExps, -- ahwassa

    ["xeb0104"] = droneStations, -- kennel t1
    ["xeb0204"] = droneStations, -- kennel t2

    ["xrb0104"] = droneStations, -- hive t1
    ["xrb0204"] = droneStations, -- hive t2
    ["xrb0304"] = droneStations, -- hive t3
}


local layerExclusion = " - COMMAND - EXPERIMENTAL - ENGINEER"

local function Wrap(s)
    return ("{%s}"):format(s)
end

local layerToCategory = {
    ["l"] = Make("Land Units", TechDecreased("LAND" .. layerExclusion)),
    ["a"] = Make("Air Units", TechDecreased("AIR" .. layerExclusion)),
    ["s"] = Make("Naval Units", TechDecreased("NAVAL" .. layerExclusion)),
    ["b"] = Make("Structure Units", TechDecreased("STRUCTURE" .. layerExclusion)),
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
