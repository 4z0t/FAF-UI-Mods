local SetIgnoreSelection = import('/lua/ui/game/gamemain.lua').SetIgnoreSelection
local CommandMode = import('/lua/ui/game/commandmode.lua')

function Hidden(callback)
    local current_command = CommandMode.GetCommandMode()
    local old_selection = GetSelectedUnits() or {}
    SetIgnoreSelection(true)
    callback()
    SelectUnits(old_selection)
    CommandMode.StartCommandMode(current_command[1], current_command[2])
    SetIgnoreSelection(false)
end
