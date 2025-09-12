local FindClients = import('/lua/ui/game/chat.lua').FindClients
local armiesTable = GetArmiesTable().armiesTable
local FormatNumber = import("Utils.lua").FormatNumber

local function SendMessage(text, to)

    SessionSendChatMessage(FindClients(),
        {
            from = GetArmiesTable().armiesTable[GetFocusArmy()].nickname,
            to = to or "allies",
            Chat = true,
            text = text
        })

end

local function GiveResourcesToPlayer(resourceType, id, ratio)
    if GetFocusArmy() == id then return end

    ratio = ratio or 0.5
    local scoresCache = import("/lua/ui/game/score.lua").GetScoreCache()
    local armyScore = scoresCache[id]

    if not armyScore.resources then return end
    local econData = GetEconomyTotals()
    local resStored = econData.stored[string.upper(resourceType)]
    if resStored <= 0 then return end
    local sentValue = armyScore.resources.storage['max' .. resourceType] -
        armyScore.resources.storage['stored' .. resourceType]
    if sentValue <= 0 then return end
    sentValue = math.min(sentValue, resStored * ratio)

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

    armyScore.resources.storage['stored' .. resourceType] = armyScore.resources.storage['stored' .. resourceType] +
        sentValue
    SendMessage(string.format("Sent %s %s to %s", FormatNumber(sentValue), resourceType, scoresCache[id].name))
end

function GiveMassToPlayer(id, ratio)
    GiveResourcesToPlayer("Mass", id, ratio)
end

function GiveEnergyToPlayer(id, ratio)
    GiveResourcesToPlayer("Energy", id, ratio)
end

function GiveUnitsToPlayer(id)
    if GetFocusArmy() == id then
        return
    end
    local selectedUnits = GetSelectedUnits()
    if not table.empty(selectedUnits) then
        SimCallback(
            {
                Func = "GiveUnitsToPlayer",
                Args = {
                    From = GetFocusArmy(),
                    To = id
                },
            },
            true)

        SendMessage(string.format("Sent units to %s", armiesTable[id].nickname))
    end
end

local function RequestResourceFromPlayer(resourceType, id)
    if GetFocusArmy() == id then
        SendMessage(string.format("Please, give me %s", resourceType))
    else
        SendMessage(string.format("%s, please, give me %s", armiesTable[id].nickname, resourceType))
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
        SendMessage("Please give me T3 engineer")
    else
        SendMessage(string.format("%s, please, give me an engineer", armiesTable[id].nickname))
    end
end

function GiveAllMassToPlayer(id)
    GiveResourcesToPlayer("Mass", id, 1)
end

function GiveAllEnergyToPlayer(id)
    GiveResourcesToPlayer("Energy", id, 1)
end
