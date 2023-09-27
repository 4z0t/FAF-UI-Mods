local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc

local ViewModel = import('viewmodel.lua')
local Model = import('model.lua')
local View = import("views/view.lua")

local chatTAG = "HBO"

local useNameFormat = true

function ReceiveBuildTable(name, data)
    ViewModel.SaveReceived(name, data)
end

function ProcessMessage(sender, data)
    local armies = GetArmiesTable()
    local me = GetFocusArmy()

    if armies.armiesTable[me].nickname == sender then
        return
    end
    if View.IsActiveUI() then
        if useNameFormat then
            ReceiveBuildTable(string.format("%s by %s", data.text[1], sender), data.text[2])
        else
            ReceiveBuildTable(unpack(data.text))
        end
    end
end

function SendBuildTable(recipients, name, data)
    SessionSendChatMessage({
        to = 'all',
        [chatTAG] = true,
        text = { name, data }
    })
end

function Init(isReplay)
    if isReplay then
        return
    end
    RegisterChatFunc(ProcessMessage, chatTAG)
end
