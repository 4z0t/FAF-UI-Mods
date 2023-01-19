local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local locked = false

function IsLocked()
    return locked
end

function Reset()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

function Toggle(skip)
    locked = not locked
    if not skip then
        Reset()
    end
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)

end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if locked and (commandModeData and commandModeData.name == "RULEUCC_Move") then
        ForkThread(Reset)
    end
end

function Main(isReplay)
    if isReplay then return end

    CM.AddStartBehavior(OnCommandStarted)
    CM.AddEndBehavior(OnCommandEnded)

end

KeyMapper.SetUserKeyAction('Move only', {
    action = 'UI_Lua import("/mods/Move/modules/Main.lua").Toggle()',
    category = 'orders'
})