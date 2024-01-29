do
    local HiddenSelect = UMT.Units.HiddenSelect
    local prevUnit = nil

    local function SetAutoOC(state)
        SimCallback({ Func = 'AutoOvercharge', Args = { auto = state } }, true)
    end

    import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(function(info)
        if prevUnit and (not table.empty(info.added) or not table.empty(info.removed)) then
            print("Switching OC to auto back")
            HiddenSelect(function()
                SelectUnits { prevUnit }
                SetAutoOC(true)
            end)
            prevUnit = nil
        end
    end)

    function EnterOverchargeMode()
        local unit = currentSelection[1]
        if not unit or unit:IsDead() then return end

        local weapon = FindOCWeapon(unit:GetBlueprint())
        if not weapon then return end

        if IsAutoOCMode(currentSelection) then
            print("Switching OC to manual")
            SetAutoOC(false)
            prevUnit = currentSelection[1]
        end
        
        if unit:IsOverchargePaused() then return end

        local econData = GetEconomyTotals()
        if econData.stored["ENERGY"] >= weapon.EnergyRequired then
            ConExecute('StartCommandMode order RULEUCC_Overcharge')
        end
    end
end
