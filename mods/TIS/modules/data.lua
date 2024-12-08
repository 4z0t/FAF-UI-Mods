local FindClients = import('/lua/ui/game/chat.lua').FindClients
local SessionSendChatMessage = SessionSendChatMessage
local Exp = import('exp.lua')
local Nuke = import('nuke.lua')
local Smd = import('smd.lua')

local is_replay

function init(isReplay)
    is_replay = isReplay

    if is_replay then
        return
    end

    import('/lua/ui/game/gamemain.lua').RegisterChatFunc(ProcessData, 'TIS')
end

local function isAllytoMe(nickname, me)
    for id, player in GetArmiesTable().armiesTable do
        if player.nickname == nickname then
            return IsAlly(me, id)
        end
    end
end

function ProcessData(player, msg)
    local armies = GetArmiesTable()
    local data = msg.text
    local me = GetFocusArmy()

    if GetArmiesTable().armiesTable[me].nickname == player or not isAllytoMe(player, me) then
        return
    end
    if data.init then
        if data.nuke then
            Nuke.AddExternal(data)
        elseif data.exp then
            Exp.AddExternal(data)
        end
    elseif data.remove then
        if data.nuke then
            Nuke.RemoveExternal(data.id)
        elseif data.exp then
            Exp.RemoveExternal(data.id)
        end
    else
        if data.nuke then
            Nuke.UpdateOverlay(data)
        elseif data.exp then
            Exp.UpdateOverlay(data)
        end
    end
end

function SendData(data)
    if is_replay then
        return
    end
    SessionSendChatMessage(FindClients(), {
        to = 'allies',
        TIS = true,
        text = data
    })
end

-- function InitData(data)
--     SessionSendChatMessage(FindClients(), {
--         to = 'allies',
--         TIS = true,
--         text = data
--     })
-- end
