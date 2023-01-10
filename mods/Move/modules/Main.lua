local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local locked = false



function Reset()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

function Start()
    locked = not locked
    if locked then
        Reset()
    end
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)
    if locked and not (not commandModeData or commandModeData.name ~= "RULEUCC_Move") then
        ForkThread(Reset)
    end
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)

end

function Main(isReplay)
    if isReplay then return end

    CM.AddStartBehavior(OnCommandStarted)
    CM.AddEndBehavior(OnCommandEnded)

end

KeyMapper.SetUserKeyAction('Move only', {
    action = 'UI_Lua import("/mods/Move/modules/Main.lua").Start()',
    category = 'orders'
})
