local IsKeyDown = IsKeyDown
local ForkThread = ForkThread

local CM = import("/lua/ui/game/commandmode.lua")

local function ResetMove()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

---@param command CommandModeData
---@return boolean
local function IsMoveCommand(command)
    return command and command.name == "RULEUCC_Move"
end

local useCtrlMove

---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if not useCtrlMove or not IsKeyDown("Control") then return end

    if IsMoveCommand(commandModeData) then
        ForkThread(ResetMove)
        return
    end
end

function Main(isReplay)
    if isReplay then return end

    UMT.Options.Mods["Ctrl"].enableCtrlMove:Bind(function(opt)
        useCtrlMove = opt()
    end)

    CM.AddEndBehavior(OnCommandEnded)
end
