local CM = import("/lua/ui/game/commandmode.lua")
local GM = import("/lua/ui/game/gamemain.lua")
local KeyMapper = import('/lua/keymap/keymapper.lua')
local completeCycleSound = Sound { Cue = 'UI_Menu_Error_01', Bank = 'Interface', }


local templateData = nil
local current = nil
local prevSelection
local activeSelection = nil
local activeCommandMode
local activeCommandModeData
local lastUnit
local continuous

local function IsActive()
    return activeSelection ~= nil
end

local ignoreSelection = false
function Ignore()
    return ignoreSelection
end

local function IgnoredSelection(units)
    ignoreSelection = true
    SelectUnits(units)
    ignoreSelection = false
end

function Reset(deselect)
    --LOG("resetting")
    current = nil
    prevSelection = activeSelection
    activeSelection = nil
    lastUnit = nil
    continuous = false
    templateData = nil
    if deselect then
        IgnoredSelection(nil)
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
            PlaySound(completeCycleSound)
            return
        end
    until not unit:IsDead()
    lastUnit = unit
    IgnoredSelection { unit }
    if not isManual then
        CM.StartCommandMode(activeCommandMode, activeCommandModeData)
        if templateData then
            SetActiveBuildTemplate(templateData)
        end
    end
    current = i
end

function Start(isContinuous)
    if not IsActive() then
        activeSelection = GetSelectedUnits()
        if not activeSelection and prevSelection then
            templateData = nil
            IgnoredSelection(prevSelection)
            --LOG(" nil after reselect")
            prevSelection = nil
            return
        end
        --LOG("nil after new command")
        prevSelection = nil
        local cm = CM.GetCommandMode()
        continuous = isContinuous
        activeCommandMode, activeCommandModeData = cm[1], cm[2]
        templateData = GetActiveBuildTemplate()
    end
    Next(true)
end

---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandStarted(commandMode, commandModeData)
    if not IsActive() then return end
end

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

    if command.CommandType == 'Guard' and not command.Target.EntityId then
        return
    end

    if command.CommandType == 'None' or continuous then
        return
    end

    ForkThread(Next, false)
end

function OnSelectionChanged(info)
    if not Ignore() and
        not table.empty(info.added) and
        not table.empty(info.removed) then
        Reset()
    end
end

function Main(isReplay)
    if isReplay then return end

    CM.AddStartBehavior(OnCommandStarted)
    --CM.AddEndBehavior(OnCommandEnded)
    GM.ObserveSelection:AddObserver(OnSelectionChanged)
end

KeyMapper.SetUserKeyAction('Quick Group Scatter', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(false)',
    category = 'Group Scatter'
})
KeyMapper.SetUserKeyAction('Continuous Group Scatter', {
    action = 'UI_Lua import("/mods/GS/modules/Main.lua").Start(true)',
    category = 'Group Scatter'
})
