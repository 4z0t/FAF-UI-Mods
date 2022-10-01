local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction

local Update = import('update.lua')

local listeners = {}

function UpdateListeners()
    
end

function init(isReplay)
    AddBeatFunction(UpdateListeners, true)
end

function Add(unit)
    
end