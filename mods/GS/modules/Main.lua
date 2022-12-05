local CM = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')

local current = nil
local activeSelection = nil
local activeCommandMode
local activeCommandModeData
local lastUnit
local continuous

local supress

local function Reset(deselect)
    current = nil
    activeSelection = nil
    lastUnit = nil
    continuous = false
    if deselect then
        SelectUnits(nil)
    end
end

function Next()
    if not activeSelection then return end
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

function Start(isContinuous)
    if not activeSelection then
        activeSelection = GetSelectedUnits()
        local cm = CM.GetCommandMode()
        continuous = isContinuous
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
        supress = continuous
        return
    end
    local selectedUnits = GetSelectedUnits()
    --check if selection changed
    if lastUnit  and (not selectedUnits or table.getn(selectedUnits) ~= 1 or selectedUnits[1] ~= lastUnit) then
        -- check if unit died for some reason
        if not lastUnit:IsDead() then Reset(false) return end
    end

    ForkThread(Next)
end

function Main(isReplay)
    if isReplay then return end

    -- CM.AddStartBehavior(OnCommandStarted)
    CM.AddEndBehavior(OnCommandEnded)

end

KeyMapper.SetUserKeyAction('Start Group Split', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(false)',
    category = 'Group Split'
})
KeyMapper.SetUserKeyAction('Start Group Split continuous', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(true)',
    category = 'Group Split'
})