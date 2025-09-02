ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Actions >= 1.0.0"
}

function Main(isReplay)
    if isReplay then
        return
    end

    ReUI.Core.OnPostCreateUI(function()
        ---@diagnostic disable-next-line:deprecated
        local TableGetN = table.getn
        local SelectUnits = SelectUnits
        local TableEmpty = table.empty
        local GetSelectedUnits = GetSelectedUnits

        local CM = import("/lua/ui/game/commandmode.lua")
        local GM = import("/lua/ui/game/gamemain.lua")
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
        local function Ignore()
            return ignoreSelection
        end

        local function IgnoredSelection(units)
            ignoreSelection = true
            SelectUnits(units)
            ignoreSelection = false
        end

        local function Reset(deselect)
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

        local function Next(isManual)
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

        local function Start(isContinuous)
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
                if templateData and TableEmpty(templateData) then
                    templateData = nil
                end
            end
            Next(true)
        end

        ---@param commandMode CommandMode
        ---@param commandModeData CommandModeData
        local function OnCommandStarted(commandMode, commandModeData)
            if not IsActive() then return end
        end

        local function OnSelectionChanged(info)
            if not Ignore() and
                not TableEmpty(info.added) and
                not TableEmpty(info.removed) then
                Reset()
            end
        end

        CM.AddStartBehavior(OnCommandStarted)
        GM.ObserveSelection:AddObserver(OnSelectionChanged)


        ReUI.Actions.SelectionAction("Quick Group Scatter", function(selection)
            Start(false)
        end)
        ReUI.Actions.SelectionAction("Continuous Group Scatter", function(selection)
            Start(true)
        end)

        ---@param command any
        local function OnCommandIssued(command)
            if not IsActive() then
                return
            end

            local selectedUnits = GetSelectedUnits()
            --check if selection changed
            if lastUnit and (not selectedUnits or TableGetN(selectedUnits) ~= 1 or selectedUnits[1] ~= lastUnit) then
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

        local _OnCommandIssued = CM.OnCommandIssued
        CM.OnCommandIssued = function(command)
            _OnCommandIssued(command)

            if not command.Clear then
                return
            end

            OnCommandIssued(command)
        end
    end)
end
