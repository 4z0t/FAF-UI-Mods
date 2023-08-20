function Make(name, category)
    return {
        name = name,
        category = category
    }
end

function ToCategory(name)
    return ("{categories.%s}"):format(name)
end

local postfixToCategory = {
    -- engineers
    ["l0001"] = Make("ACUs", ToCategory "COMMAND"),
    ["l0105"] = Make("Engineers",
        "{categories.ENGINEER * categories.TECH3, categories.ENGINEER * categories.TECH2, categories.ENGINEER * categories.TECH1}"),
    ["l0301"] = Make("SACUs", ToCategory "SUBCOMMANDER"),

    --air
    ["a0303"] = Make("ASFs", ToCategory "ASF"),
    ["a0304"] = Make("Strat bombers", ToCategory "STRATEGICBOMBER"),
    ["a0107"] = Make("Transports", ToCategory "TRANSPORTATION"),
    ["a0204"] = Make("Torpedo bombers", "{categories.ANTINAVY * categories.BOMBER * categories.AIR}"),
    ["a0203"] = Make("Gunships", "{categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL}"),
    ["a0102"] = Make("Interseptors", "{categories.AIR * categories.MOBILE * categories.ANTIAIR}"),
    [""]      = Make("", ""),

    -- land
    ["l0111"] = Make("MMLs",
        "{categories.LAND * categories.MOBILE * categories.SILO * categories.TECH3, categories.LAND * categories.MOBILE * categories.SILO * categories.TECH2}"),
    [""] = Make("", ""),

    --naval
    ["s0103"] = Make("Frigates", ToCategory "FRIGATE"),
    ["s0202"] = Make("Cruisers", ToCategory "CRUISER"),
    ["s0201"] = Make("Destroyers", ToCategory "DESTROYER"),
    ["s0302"] = Make("BATTLESHIPs", ToCategory "BATTLESHIP"),
    ["s0303"] = Make("Carriers", ToCategory "NAVALCARRIER"),
    ["s0304"] = Make("Strategic subs", ToCategory "NUKESUB"),
    ["s0305"] = Make("Sonars",
        "{categories.MOBILESONAR , categories.STRUCTURE * categories.INTELLIGENCE * categories.SONAR}"),

    -- structures
    [""] = Make("", ""),
    [""] = Make("", ""),
}


postfixToCategory["b3102"] = postfixToCategory["s0305"] -- t1 sonars
postfixToCategory["b3202"] = postfixToCategory["s0305"] -- t2 sonars
postfixToCategory['a0104'] = postfixToCategory['a0107'] -- t2 transports
postfixToCategory["l0208"] = postfixToCategory["l0105"] -- t2 engineers
postfixToCategory['l0309'] = postfixToCategory["l0105"] -- t3 engineers
postfixToCategory['a0305'] = postfixToCategory["a0203"] -- t3 gunships


local snipers = Make("Snipers", "{categories.XSL0305 + categories.XAL0305}")

local specialToCategory =
{
    ["xea0306"] = postfixToCategory['a0107'], -- t3 uef transport
    ["xel0209"] = postfixToCategory["l0105"], -- sparky
    ["xaa0306"] = postfixToCategory["a0204"], -- t3 torp bomber
    ["xra0105"] = postfixToCategory["a0203"], -- t1 cybran gunship
    ["xel0306"] = postfixToCategory["l0111"], -- spearhead,
    ["xsl0305"] = snipers, -- sera sniper,
    ["xal0305"] = snipers, -- aeon sniper,

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

    local postfix = string.sub(bpId, 3, 7)
    local data = postfixToCategory[postfix]
    if data then
        return data.category, data.name
    end

    data = specialToCategory[bpId]
    if data then
        return data.category, data.name
    end

    local catType = string.sub(bpId, 3, 3)
    data = layerToCategory[catType]
    if data then
        return data.category, data.name
    end

end
