local Prefs = import("/lua/user/prefs.lua")


local LINQ = ReUI.LINQ

-- Turn engine string reference to certain symbols into the actual symbol
local short = {
    ["CapsLock"] = "Cap",
    ["Comma"] = ",",
    ["Period"] = ".",
    ["Slash"] = "/",
    ["Backslash"] = "\\",
    ["Minus"] = "-",
    ["NumPlus"] = "+",
    ["NumMinus"] = "-",
    ["NumStar"] = "*",
    ["NumSlash"] = "/",
    ["Quote"] = "'",
    ["LeftBracket"] = "[", -- this key is the rightbracket for azerty
    ["RightBracket"] = "]",
    ["Chevron"] = "<", -- added for french keyboard
    ["Backtick"] = "`",
}

-- Which colour do we make the label? Shift is not taken into account here
local colours = {
    "ffffffff", -- White, no modifier
    "fffafa00", -- Yellow, ctrl
    "ffffbf80", -- Orange, alt
    "FFe80a0a", -- Red, ctrl + alt
}

-- Depends on amount of characters in the key name
local textSizes = {
    [1] = 18,
    [2] = 14,
    [3] = 14,
}

-- This table maps an action command to the tooltip of the button or buttons it corresponds to
local orderDelegations = {
    attack = { "attack" },
    shift_attack = { "attack" },
    move = { "move" },
    shift_move = { "move" },
    assist = { "assist" },
    shift_assist = { "assist" },
    guard = { "assist" },
    shift_guard = { "assist" },
    stop = { "stop" },
    soft_stop = { "stop" },
    patrol = { "patrol" },
    shift_patrol = { "patrol" },
    repair = { "repair" },
    shift_repair = { "repair" },
    capture = { "capture" },
    shift_capture = { "capture" },
    reclaim = { "reclaim" },
    shift_reclaim = { "reclaim" },
    overcharge = { "overcharge" },

    teleport = { "teleport" },
    dive = { "dive" },
    transport = { "transport" },
    ferry = { "ferry" },
    sacrifice = { "sacrifice" },
    dock = { "dock" },

    launch_tactical = { "fire_tactical" },
    shift_launch_tactical = { "fire_tactical" },
    build_tactical = { "build_tactical" },
    build_billy = { "build_billy" },
    nuke = { "fire_nuke" },
    shift_nuke = { "fire_nuke" },
    build_nuke = { "build_nuke" },

    toggle_all = { "toggle_shield", "toggle_shield_dome", "toggle_radar", "toggle_sonar", "toggle_omni",
        "toggle_cloak", "toggle_jamming", "toggle_stealth_field", "toggle_scrying" },

    toggle_intelshield = { "toggle_shield", "toggle_shield_dome", "toggle_radar", "toggle_sonar", "toggle_omni",
        "toggle_scrying" },
    toggle_shield = { "toggle_shield" },
    toggle_shield_dome = { "toggle_shield_dome" },

    toggle_cloakjammingstealth = { "toggle_cloak", "toggle_jamming", "toggle_stealth_field" },
    toggle_cloak = { "toggle_cloak" },
    toggle_jamming = { "toggle_jamming" },
    toggle_stealth_field = { "toggle_stealth_field" },

    mode = { "mode" },

    toggle_intel = { "toggle_radar", "toggle_sonar", "toggle_omni", "toggle_scrying" },
    toggle_scrying = { "toggle_scrying" },
    scry_target = { "scry_target" },
}


---@alias OrderName
---| "attack"
---| "move"
---| "assist"
---| "stop"
---| "patrol"
---| "capture"
---| "reclaim"
---| "teleport"
---| "transport"
---| "overcharge"
---| "fire_tactical"
---| "fire_nuke"

local orderNames = LINQ.IPairsEnumerator:ToSet() {
    "attack",
    "move",
    "assist",
    "stop",
    "patrol",
    "capture",
    "reclaim",
    "teleport",
    "transport",
    "overcharge",
    "fire_tactical",
    "fire_nuke",
}

---@param unitkeygroups table<string, BlueprintId[]>
---@param ids table<string, BlueprintId[]>
---@param orders any
---@return table
---@return table|unknown|nil
---@return table
function GetKeyLabels(unitkeygroups, ids, orders)
    local idRelations = {}
    local helpIdRelations = {}
    local otherRelations = {}
    local upgradeKey = nil
    local orderKeys = {
        -- Special assignment for the attack move order because it can't be bound from the user key map
        -- Keyed the same as the tooltip for the attack move button
        ["attack_move"] = {
            ["key"] = 'RMB',
            ["colour"] = colours[3],
        }
    }

    -- Get them from the building tab
    for groupName, groupItems in unitkeygroups do -- Since this file hardcodes all unit ids that can be affected by hotbuild, helpidrelations will get them all
        local g = groupName:lower()
        for _, item in groupItems do
            local i = item:lower()

            if __blueprints[i] then
                if not helpIdRelations[i] then
                    helpIdRelations[i] = { g }
                else
                    table.insert(helpIdRelations[i], g)
                end
            else
                if otherRelations[i] then
                    table.insert(otherRelations[i], g)
                else
                    otherRelations[i] = { g }
                end
            end
        end
    end

    -- Go through unitkeygroups to properly map IDs
    for id, group in pairs(helpIdRelations) do
        for key, value in group do
            if otherRelations[value] then -- Check if the group contained more than just unit IDs
                for ids, values in pairs(otherRelations[value]) do
                    table.insert(helpIdRelations[id], values:lower())
                end
            end
        end
    end

    -- Match user pref keymap
    local savedPrefs = Prefs.GetFromCurrentProfile("UserKeyMap")
    for keyCombo, action in savedPrefs or {} do
        local baseKey, colour = import("/lua/keymap/hotkeylabels.lua").getKeyUse(keyCombo) -- Returns the base key without modifiers, and a colour key to say which modifiers got removed (Were there)

        -- Handle unit IDs
        for id, group in pairs(helpIdRelations) do
            for key, value in group do
                if value == action then -- If it's an action that's assigned to a key at all, link the id to the key
                    idRelations[id] = {
                        ["key"] = baseKey,
                        ["colour"] = colour,
                    }
                end
            end
        end

        -- Handle orders
        if orderDelegations[action] then
            for _, o in orderDelegations[action] do
                orderKeys[o] = {
                    ["key"] = baseKey,
                    ["colour"] = colour,
                }
            end
        end

        -- Handle upgrades
        if action == "upgrades" then
            upgradeKey = {
                ["key"] = baseKey,
                ["colour"] = colour,
            }
        end

        local actionOrders = orders[action]
        if actionOrders then
            for _, o in actionOrders do
                orderKeys[o] = {
                    ["key"] = baseKey,
                    ["colour"] = colour,
                }
            end
        end

        local actionBPIds = ids[action]
        if actionBPIds then
            for _, id in actionBPIds do
                idRelations[id] = {
                    ["key"] = baseKey,
                    ["colour"] = colour,
                }
            end
        end
    end


    -- Rename signs for Unit ID list and orders
    for _, metagroup in { idRelations, orderKeys } do
        for id1, group in metagroup do
            if short[group.key] then
                metagroup[id1].key = short[group.key]
            end
        end
    end

    -- Handle signs for upgrades seperately
    if upgradeKey then
        if short[upgradeKey.key] then
            upgradeKey.key = short[upgradeKey.key]
        end
    end

    -- Remove unused ones (too long)
    for _, metagroup in { idRelations, orderKeys } do
        for id1, group in metagroup do
            group["textsize"] = textSizes[string.len(group.key)]
            if not group["textsize"] then
                WARN('Not showing label for keybind ' .. group.key .. ' due to length')
                metagroup[id1] = nil
            end
        end
    end

    -- Handle textsize for upgrades seperately
    if upgradeKey then
        upgradeKey["textsize"] = textSizes[string.len(upgradeKey.key)]
        if not upgradeKey["textsize"] then
            WARN('Not showing label for keybind ' .. upgradeKey.key .. ' due to length')
            upgradeKey = nil
        end
    end

    return idRelations, upgradeKey, orderKeys
end
