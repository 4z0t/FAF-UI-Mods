local FindClients = import('/lua/ui/game/chat.lua').FindClients
local armiesTable = GetArmiesTable().armiesTable
local GetScoreCache = import("/lua/ui/game/score.lua").GetScoreCache

function GiveMassToPlayer(id)
    if GetFocusArmy() == id then
        return
    end
    local armyScore = GetScoreCache()[id]



end

function GiveEnergyToPlayer()

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

function RequestMassFromPlayer(id)

end

function RequestEnergyFromPlayer(id)

end

function RequestUnitFromPlayer(id)

end
