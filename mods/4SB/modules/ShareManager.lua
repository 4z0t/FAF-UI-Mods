local FindClients = import('/lua/ui/game/chat.lua').FindClients
local armiesTable = GetArmiesTable().armiesTable
local FormatNumber = import("Utils.lua").FormatNumber

local function GiveResourcesToPlayer(resourceType, id)
    local GetScoreCache = import("/lua/ui/game/score.lua").GetScoreCache
    if GetFocusArmy() == id then
        return
    end
    local scoresCache = GetScoreCache()
    local armyScore = scoresCache[id]

    if not armyScore.resources then return end
    local econData = GetEconomyTotals()
    local resStored = econData.stored[string.upper(resourceType)]
    if resStored <= 0 then return end
    local sentValue = armyScore.resources.storage['max' .. resourceType] - armyScore.resources.storage['stored' .. resourceType]
    if sentValue <= 0 then return end
    sentValue = math.min(sentValue, resStored * 0.25)

    local value        = sentValue / resStored
    local args         = {
        From   = GetFocusArmy(),
        To     = id,
        Mass   = 0,
        Energy = 0
    }
    args[resourceType] = value
    SimCallback({
        Func = "GiveResourcesToPlayer",
        Args = args
    })

    armyScore.resources.storage['stored' .. resourceType] = armyScore.resources.storage['stored' .. resourceType] + sentValue
    SessionSendChatMessage(FindClients(),
        {
            from = scoresCache[GetFocusArmy()].name,
            to = 'allies',
            Chat = true,
            text = 'Sent ' .. resourceType .. ' ' .. FormatNumber(sentValue) .. ' to ' .. scoresCache[id].name
        })
end

function GiveMassToPlayer(id)
    GiveResourcesToPlayer("Mass", id)


end

function GiveEnergyToPlayer(id)
    GiveResourcesToPlayer("Energy", id)
end

function GiveUnitsToPlayer(id)
    SimCallback(
        {
            Func = "GiveUnitsToPlayer",
            Args = {
                From = GetFocusArmy(),
                To = id
            },
        },
        true)
    SessionSendChatMessage(FindClients(),
        {
            from = armiesTable[GetFocusArmy()].nickname,
            to = 'allies',
            Chat = true,
            text = 'Sent units to ' .. armiesTable[id].nickname
        })
end

local function RequestResourceFromPlayer(resourceType, id)
    if GetFocusArmy() == id then
        SessionSendChatMessage(FindClients(),
            {
                from = armiesTable[GetFocusArmy()].nickname,
                to = 'allies',
                Chat = true,
                text = 'Give me ' .. resourceType
            })
    else
        SessionSendChatMessage(FindClients(),
            {
                from = armiesTable[GetFocusArmy()].nickname,
                to = 'allies',
                Chat = true,
                text = armiesTable[id].nickname .. ' give me ' .. resourceType
            })
    end
end

function RequestMassFromPlayer(id)
    RequestResourceFromPlayer("Mass", id)
end

function RequestEnergyFromPlayer(id)
    RequestResourceFromPlayer("Energy", id)
end

function RequestUnitFromPlayer(id)
    if GetFocusArmy() == id then
    else
    end
end
