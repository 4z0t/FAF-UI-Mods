local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local isMoveLocked = false

local isOverCharge = false
local isOCSetting = false

function IsLocked()
    return isMoveLocked
end

function ResetMove()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

function SetOC()
    ConExecute 'StartCommandMode order RULEUCC_Overcharge'
end

function Toggle(skip)
    isMoveLocked = not isMoveLocked
    if not skip then ResetMove() end
    isOverCharge = false
    isOCSetting = false
end

---@param command CommandModeData
---@return boolean
local function IsMoveCommand(command)
    return command and command.name == "RULEUCC_Move"
end

---@param command CommandModeData
---@return boolean
local function IsOverChargeCommand(command)
    return command and command.name == "RULEUCC_Overcharge"
end

---@param command CommandModeData
---@return boolean
local function IsOverChargeCommandCanceled(command)
    return IsOverChargeCommand(command) and command.isCancel
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)
    if IsOverChargeCommand(commandModeData) then
        isOCSetting = not isOCSetting
        isOverCharge = true
    end
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if not isMoveLocked then return end
    
    if IsOverChargeCommand(commandModeData) and isOverCharge then
        if isOCSetting then
            ForkThread(SetOC)
            return
        end
        isOverCharge = false
        ForkThread(ResetMove)
        return
    end
    if IsMoveCommand(commandModeData) and not isOverCharge then
        ForkThread(ResetMove)
        return
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
