local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local current = nil
local activeSelection = nil
local activeCommandMode
local activeCommandModeData
local lastUnit
local continuous
local isStarted

local supress

local function IsActive()
    return activeSelection ~= nil
end

local function Reset(deselect)
    current = nil
    activeSelection = nil
    lastUnit = nil
    continuous = false
    isStarted = false
    if deselect then
        SelectUnits(nil)
    end
end

function Next(isManual)
    if not IsActive() then return end
    local unit
    local i = current
    repeat
        i, unit = next(activeSelection, i)
        if i == nil then
            Reset(true)
            return
        end
    until not unit:IsDead()
    lastUnit = unit

    SelectUnits { unit }

    if not isManual then
        CM.StartCommandMode(activeCommandMode, activeCommandModeData)
    end
    current = i
end

function Start(isContinuous)
    if not IsActive() then
        activeSelection = GetSelectedUnits()
        local cm = CM.GetCommandMode()
        continuous = isContinuous
        activeCommandMode, activeCommandModeData = cm[1], cm[2]
    end
    Next(true)
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)
    if not IsActive() then return end


    isStarted = true
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
---@param command any
function OnCommandIssued(commandMode, commandModeData, command)

    if not IsActive() then return end
    --if commandModeData and not commandModeData.isCancel then return end
    local selectedUnits = GetSelectedUnits()
    --check if selection changed
    if lastUnit and (not selectedUnits or table.getn(selectedUnits) ~= 1 or selectedUnits[1] ~= lastUnit) then
        -- check if unit died for some reason
        if not lastUnit:IsDead() then Reset(false) return end
    end


    
    if command.CommandType == 'Guard' then
        supress = not supress
    end

    if supress or command.CommandType == 'None' or continuous then
        return
    end

    ForkThread(Next, false)
end

function Main(isReplay)
    if isReplay then return end

    CM.AddStartBehavior(OnCommandStarted)
    --CM.AddEndBehavior(OnCommandEnded)

end

KeyMapper.SetUserKeyAction('Quick Group Scatter', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(false)',
    category = 'Group Scatter'
})
KeyMapper.SetUserKeyAction('Continuous Group Scatter', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(true)',
    category = 'Group Scatter'
})
