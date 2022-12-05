local CM = import("/lua/ui/game/commandmode.lua")



---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)

end

function Main(isReplay)
    if isReplay then return end

    CM.AddEndBehavior(OnCommandEnded)

end
