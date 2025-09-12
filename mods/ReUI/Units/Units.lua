ReUI.Require
{
}


function Main(isReplay)

    local updateCacheTicks = 10
    local updateAllTicks = 50

    local GetSelectedUnits = GetSelectedUnits
    local SelectUnits = SelectUnits
    local GetFocusArmy = GetFocusArmy
    local GameTick = GameTick
    local UISelectionByCategory = UISelectionByCategory

    local SetIgnoreSelection = import("/lua/ui/game/gamemain.lua").SetIgnoreSelection
    local CommandMode = import('/lua/ui/game/commandmode.lua')

    ---@param callback fun(currentSelection:UserUnit[]?)
    local function HiddenSelect(callback)
        local currentCommand = CommandMode.GetCommandMode()
        local oldSelection = GetSelectedUnits()
        SetIgnoreSelection(true)
        callback(oldSelection)
        SelectUnits(oldSelection)
        CommandMode.StartCommandMode(currentCommand[1], currentCommand[2])
        SetIgnoreSelection(false)
    end

    ---@param fn fun(unit:UserUnit)
    local function ApplyToSelectedUnits(fn)
        local selection = GetSelectedUnits()
        if not selection then return end

        HiddenSelect(function(currentSelection)
            local cachedTable = {}
            for _, unit in currentSelection do
                cachedTable[1] = unit
                SelectUnits(cachedTable)
                fn(unit)
            end
        end)
    end

    ---@type number
    local currentArmy
    ---@type table<string, UserUnit>
    local units

    ---@type number
    local prevReset = 0
    local prevUpdate = 0

    local function ProcessAllUnits()
        UISelectionByCategory("ALLUNITS", false, false, false, false)
        local selection = GetSelectedUnits()
        if not selection then
            return
        end
        ---@param unit UserUnit
        for _, unit in selection do
            units[unit:GetEntityId()] = unit
        end
    end

    local function UpdateAllUnits()
        HiddenSelect(ProcessAllUnits)
    end

    local function OnArmyChanged()
    end

    local focused = {}
    local function UpdateUnits()
        ---@param id string
        ---@param unit UserUnit
        for id, unit in units do
            if unit:IsDead() then
                units[id] = nil
            else
                local focus = unit:GetFocus()
                if focus and not focus:IsDead() then
                    local focusId = focus:GetEntityId()
                    if not unit[focusId] then
                        focused[focusId] = focus
                    end
                end
            end
        end

        ---@param id string
        ---@param unit UserUnit
        for id, unit in focused do
            units[id] = unit
            focused[id] = nil
        end
    end

    local function Update()
        local currentTick = GameTick()
        local army = GetFocusArmy()

        if army ~= currentArmy then
            prevReset = 0
            prevUpdate = 0
            currentArmy = army
            units = ReUI.Core.Weak.Value {}
            OnArmyChanged()
        end

        if army ~= -1 and currentTick - updateCacheTicks >= prevUpdate then
            if currentTick - updateAllTicks > prevReset then
                UpdateAllUnits()
                prevReset = currentTick
            end

            UpdateUnits()
            prevUpdate = currentTick
        end
    end

    ---@return table<string, UserUnit>
    local function Get()
        Update()
        return units
    end

    return {
        HiddenSelect = HiddenSelect,
        ApplyToSelectedUnits = ApplyToSelectedUnits,
        Get = Get,
    }

end
