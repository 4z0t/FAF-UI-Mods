local Main = import('main.lua')
local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction

local listeners = {}

function UpdateListeners()
    
end

function init(isReplay)
    AddBeatFunction(UpdateListeners, true)
end

function Add(unit)
    
end