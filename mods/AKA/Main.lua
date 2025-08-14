ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Actions >= 1.0.0",
    "ReUI.LINQ >= 1.1.0",
    "ReUI.Hotbuild >= 1.0.0",
}

function Main()
    ReUI.Core.OnPostCreateUI(function(isReplay)
        local GetUnitCommandData = GetUnitCommandData

        local CategoryMatcher = ReUI.Actions.CategoryMatcher
        local CategoryAction = ReUI.Actions.CategoryAction
        local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator

        local CM = import("/lua/ui/game/commandmode.lua")

        local attackMoveModeData = {
            name = "RULEUCC_Script",
            AbilityName = 'AttackMove',
            TaskName = 'AttackMove',
            Cursor = 'ATTACK_MOVE',
        }

        local Contains = IPairsEnumerator:Contains()

        local AllFactories = IPairsEnumerator
            ---@param unit UserUnit
            :All(function(unit)
                return unit:IsInCategory 'FACTORY'
                    or unit:IsInCategory 'EXTERNALFACTORY'
            end)

        local AllRepeatQueue = IPairsEnumerator
            ---@param unit UserUnit
            :All(function(unit)
                return unit:IsRepeatQueue()
            end)

        CategoryMatcher "Transportation / Overcharge / Repeat queue"
        {
            CategoryAction(), -- do nothing if no selection
            CategoryAction(categories.TRANSPORTATION)
                :Action "StartCommandMode order RULEUCC_Transport",
            CategoryAction(categories.COMMAND + categories.SUBCOMMANDER)
                :Action(import('/lua/ui/game/orders.lua').EnterOverchargeMode),
            CategoryAction()
                :Match(AllFactories)
                :Action(function(selection)
                    local isRepeatBuild = AllRepeatQueue(selection)
                        and 'false'
                        or 'true'
                    ---@param unit UserUnit
                    for _, unit in selection do
                        unit:ProcessInfo('SetRepeatQueue', isRepeatBuild)
                        if EntityCategoryContains(categories.EXTERNALFACTORY + categories.EXTERNALFACTORYUNIT, unit) then
                            unit:GetCreator():ProcessInfo('SetRepeatQueue', isRepeatBuild)
                        end
                    end
                end)
        }:AddShiftVersion()

        CategoryMatcher "Launch missile / attack-reclaim / attack order"
        {
            CategoryAction(categories.SILO * categories.STRUCTURE * categories.TECH3)
                :Action 'StartCommandMode order RULEUCC_Nuke',
            CategoryAction(categories.SILO * categories.STRUCTURE * categories.TECH2)
                :Action 'StartCommandMode order RULEUCC_Tactical',
            CategoryAction(categories.ENGINEER * (categories.TECH1 + categories.TECH2 + categories.TECH3)
                + categories.FACTORY * categories.STRUCTURE - categories.SUBCOMMANDER)
                :Action(function(selection)
                    CM.StartCommandMode("order", attackMoveModeData)
                end),
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action 'StartCommandMode order RULEUCC_Attack',
        }:AddShiftVersion()

        CategoryMatcher "Select nearest idle t1 engineer / reclaim / toggle shields / toggle stealth"
        {
            CategoryAction()
                :Action "UI_SelectByCategory +inview +nearest +idle ENGINEER TECH1",
            CategoryAction(categories.ENGINEER)
                :Action "StartCommandMode order RULEUCC_Reclaim",
            CategoryAction()
                :Match(function(selection)
                    local orders, toggles, _ = GetUnitCommandData(selection)
                    return Contains(toggles, "RULEUTC_ShieldToggle")
                end)
                :Action "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").toggleScript(\"Shield\")",
            CategoryAction()
                :Match(function(selection)
                    local orders, toggles, _ = GetUnitCommandData(selection)
                    return Contains(toggles, "RULEUTC_StealthToggle")
                end)
                :Action "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").toggleScript(\"Stealth\")",
        }:AddShiftVersion()

        CategoryMatcher "Move / Select nearest transport"
        {
            CategoryAction()
                :Action "UI_SelectByCategory +nearest +idle AIR TRANSPORTATION",
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action "StartCommandMode order RULEUCC_Move",
        }:AddShiftVersion()

        CategoryMatcher "Select nearest air scout / build sensors"
        {
            CategoryAction()
                :Action "UI_SelectByCategory +nearest AIR INTELLIGENCE",
            CategoryAction(categories.AIR * categories.INTELLIGENCE)
                :Action "UI_SelectByCategory AIR INTELLIGENCE",
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action(function(selection)
                    ReUI.Hotbuild.ProcessHotbuild "Sensors"
                end),
        }:AddShiftVersion()


        local selectionChanged = true
        import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(function(info)
            selectionChanged = not table.empty(info.added)
        end)

        CategoryMatcher "Zoom out / Soft stop / Hard stop"
        {
            CategoryAction()
                :Action(import("/lua/ui/game/zoomslider.lua").ToggleWideView),
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action(function(selection)
                    if selectionChanged then
                        import("/lua/ui/game/orders.lua").SoftStop(selection)
                    else
                        import("/lua/ui/game/orders.lua").Stop(selection)
                    end
                    selectionChanged = false
                end),
        }

        CategoryMatcher "Zoom out / Hard stop"
        {
            CategoryAction()
                :Action(import("/lua/ui/game/zoomslider.lua").ToggleWideView),
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action(import("/lua/ui/game/orders.lua").Stop),
        }

    end)
end
