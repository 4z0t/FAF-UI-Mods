local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local current = nil
local activeSelection = nil
local activeCommandMode
local activeCommandModeData
local lastUnit

local supress

local function Reset()
    current = nil
    activeSelection = nil
    lastUnit = nil
    SelectUnits(nil)
end

function Next()
    if not activeSelection then return end
    local unit
    local i = current
    repeat
        i, unit = next(activeSelection, i)
        if i == nil then
            Reset()
            return
        end
    until not unit:IsDead()
    lastUnit = unit
    supress = true
    SelectUnits { unit }
    -- if activeCommandModeData and activeCommandModeData.name then
    --     ConExecute(("StartCommandMode order %s"):format(activeCommandModeData.name))
    -- end
    -- reprsl(activeCommandMode)
    -- reprsl(activeCommandModeData)
    CM.StartCommandMode(activeCommandMode, activeCommandModeData)
    current = i
end

function Start()
    if not activeSelection then
        activeSelection = GetSelectedUnits()
        local cm = CM.GetCommandMode()
        activeCommandMode, activeCommandModeData = cm[1], cm[2]
    end
    Next()
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)
    if not activeSelection then return end
end

---comment
---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if not activeSelection or supress then
        supress = false
        return
    end
    local selectedUnits = GetSelectedUnits()
    if not selectedUnits and lastUnit then
        if not lastUnit:IsDead() then Reset() return end
    end

    ForkThread(Next)
end

function Main(isReplay)
    if isReplay then return end

    -- CM.AddStartBehavior(OnCommandStarted)
    CM.AddEndBehavior(OnCommandEnded)

end

KeyMapper.SetUserKeyAction('Start Group Split', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start()',
    category = 'Group Split'
})
