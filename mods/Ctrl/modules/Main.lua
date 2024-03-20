local IsKeyDown = IsKeyDown
local ForkThread = ForkThread

local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local isMoveLocked = false


function IsLocked()
    return isMoveLocked
end

function ResetMove()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

function Toggle(skip)
    isMoveLocked = not isMoveLocked
    if not skip then ResetMove() end
end

---@param command CommandModeData
---@return boolean
local function IsMoveCommand(command)
    return command and command.name == "RULEUCC_Move"
end

---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if not IsKeyDown("Control") then return end

    if IsMoveCommand(commandModeData) then
        ForkThread(ResetMove)
        return
    end
end

function Main(isReplay)
    if isReplay then return end

    CM.AddEndBehavior(OnCommandEnded)
end

KeyMapper.SetUserKeyAction('Ctrl Move', {
    action = 'UI_Lua import("/mods/Ctrl/modules/Main.lua").Toggle()',
    category = 'orders'
})
