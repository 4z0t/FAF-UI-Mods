ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.Actions >= 1.3.0",
    "ReUI.LINQ >= 1.1.0",
}

function Main()
    ReUI.Core.OnPostCreateUI(function(isReplay)
        local GetUnitCommandData = GetUnitCommandData

        local CategoryMatcher = ReUI.Actions.CategoryMatcher
        local CategoryAction = ReUI.Actions.CategoryAction
        local IPairsEnumerator = ReUI.LINQ.IPairsEnumerator
        local Hotbuild = ReUI.Exists "ReUI.Hotbuild >= 1.1.0" --[[@as ReUI.Hotbuild?]]

        local CM = import("/lua/ui/game/commandmode.lua")

        local attackMoveModeData = {
            name = "RULEUCC_Script",
            AbilityName = 'AttackMove',
            TaskName = 'AttackMove',
            Cursor = 'ATTACK_MOVE',
        }

        local Contains = IPairsEnumerator:Contains()

        local AllRepeatQueue = IPairsEnumerator
            ---@param unit UserUnit
            :All(function(unit)
                return unit:IsRepeatQueue()
            end)

        CategoryMatcher "Transportation / Overcharge / Repeat queue"
            :Modifiers { shift = true }
            {
                CategoryAction(), -- do nothing if no selection
                CategoryAction(categories.TRANSPORTATION)
                    :Action "StartCommandMode order RULEUCC_Transport",
                CategoryAction(categories.COMMAND + categories.SUBCOMMANDER)
                    :Action(import('/lua/ui/game/orders.lua').EnterOverchargeMode),
                CategoryAction(categories.FACTORY + categories.EXTERNALFACTORY)
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
            }

        CategoryMatcher "Launch missile / attack-reclaim / attack order"
            :Modifiers { shift = true }
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
            }

        CategoryMatcher "Select nearest idle t1 engineer / reclaim / toggle shields / toggle stealth"
            :Modifiers { shift = true }
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
            }

        CategoryMatcher "Move / Select nearest transport"
            :Modifiers { shift = true }
            {
                CategoryAction()
                    :Action "UI_SelectByCategory +nearest +idle AIR TRANSPORTATION",
                CategoryAction()
                    :Match(function(selection, category)
                        return true
                    end)
                    :Action "StartCommandMode order RULEUCC_Move",
            }

        local BuildSensorsF
        if Hotbuild then
            Hotbuild.AddHotbuild("SensorsAKA", {
                -- Air scouts
                'uea0101',
                'xsa0101',
                'ura0101',
                'uaa0101',
                -- Land scouts
                'uel0101',
                'xsl0101',
                'url0101',
                'ual0101',
                -- Omni sensors with pgens
                {
                    templateData = {
                        6,
                        6,
                        {
                            'ueb3104',
                            1318,
                            0,
                            0
                        },
                        {
                            'ueb1101',
                            1362,
                            2,
                            0
                        },
                        {
                            'ueb1101',
                            1364,
                            0,
                            2
                        },
                        {
                            'ueb1101',
                            1367,
                            -2,
                            0
                        },
                        {
                            'ueb1101',
                            1370,
                            0,
                            -2
                        }
                    },
                    name = 'Omni Sensor Array',
                    icon = 'ueb3104',
                    templateID = 15
                },
                {
                    templateData = {
                        6,
                        6,
                        {
                            'xsb3104',
                            1318,
                            0,
                            0
                        },
                        {
                            'xsb1101',
                            1362,
                            2,
                            0
                        },
                        {
                            'xsb1101',
                            1364,
                            0,
                            2
                        },
                        {
                            'xsb1101',
                            1367,
                            -2,
                            0
                        },
                        {
                            'xsb1101',
                            1370,
                            0,
                            -2
                        }
                    },
                    name = 'Omni Sensor Array',
                    icon = 'xsb3104',
                    templateID = 15
                },
                {
                    templateData = {
                        6,
                        6,
                        {
                            'urb3104',
                            1318,
                            0,
                            0
                        },
                        {
                            'urb1101',
                            1362,
                            2,
                            0
                        },
                        {
                            'urb1101',
                            1364,
                            0,
                            2
                        },
                        {
                            'urb1101',
                            1367,
                            -2,
                            0
                        },
                        {
                            'urb1101',
                            1370,
                            0,
                            -2
                        }
                    },
                    name = 'Omni Sensor Array',
                    icon = 'urb3104',
                    templateID = 15
                },
                {
                    templateData = {
                        6,
                        6,
                        {
                            'uab3104',
                            1318,
                            0,
                            0
                        },
                        {
                            'uab1101',
                            1362,
                            2,
                            0
                        },
                        {
                            'uab1101',
                            1364,
                            0,
                            2
                        },
                        {
                            'uab1101',
                            1367,
                            -2,
                            0
                        },
                        {
                            'uab1101',
                            1370,
                            0,
                            -2
                        }
                    },
                    name = 'Omni Sensor Array',
                    icon = 'uab3104',
                    templateID = 15
                },
                -- t2 radars
                'ueb3201',
                'xsb3201',
                'urb3201',
                'uab3201',

                -- t1 radars
                'ueb3101',
                'xsb3101',
                'urb3101',
                'uab3101',

                -- t3 sonars
                'urs0305',
                'ues0305',
                'uas0305',

                -- t2 sonars
                'ueb3202',
                'xsb3202',
                'urb3202',
                'uab3202',

                -- t1 sonars
                'ueb3102',
                'xsb3102',
                'urb3102',
                'uab3102',

                -- Eye and Soothsayer
                'xrb3301',
                'xab3301',
            })
            BuildSensorsF = function()
                Hotbuild.ProcessHotbuild "SensorsAKA"
            end
        else
            BuildSensorsF = function()
                import("/lua/keymap/hotbuild.lua").buildAction "Sensors"
            end
        end

        CategoryMatcher "Select nearest air scout / build sensors"
            :Modifiers { shift = true }
            {
                CategoryAction()
                    :Action "UI_SelectByCategory +nearest AIR INTELLIGENCE",
                CategoryAction(categories.AIR * categories.INTELLIGENCE)
                    :Action "UI_SelectByCategory AIR INTELLIGENCE",
                CategoryAction()
                    :Match(function(selection, category)
                        return true
                    end)
                    :Action(BuildSensorsF),
            }


        local selectionChanged = true
        import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(function(info)
            selectionChanged = not table.empty(info.added)
        end)


        ---@type UserCameraSettings?
        local defaultSettings
        ---@type UserCameraSettings?
        local lastSettings

        ---@param v1 Vector
        ---@param v2 Vector
        ---@return boolean
        local function CompareVectors(v1, v2)
            return v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3]
        end

        local function ZoomToggle()
            if defaultSettings == nil then
                lastSettings = GetCamera('WorldCamera'):SaveSettings()
                GetCamera('WorldCamera'):Reset()
                defaultSettings = GetCamera('WorldCamera'):SaveSettings()
                return
            end

            local current = GetCamera('WorldCamera'):SaveSettings()
            if not CompareVectors(current.Focus, defaultSettings.Focus)
                or current.Heading ~= defaultSettings.Heading
                or current.Pitch ~= defaultSettings.Pitch
                or current.Zoom ~= defaultSettings.Zoom
                or lastSettings == nil then
                GetCamera('WorldCamera'):Reset()
                lastSettings = current
            else
                GetCamera('WorldCamera'):RestoreSettings(lastSettings)
                lastSettings = nil
            end
        end

        CategoryMatcher "Zoom out / Soft stop / Hard stop"
        {
            CategoryAction()
                :Action(ZoomToggle),
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
                :Action(ZoomToggle),
            CategoryAction()
                :Match(function(selection, category)
                    return true
                end)
                :Action(import("/lua/ui/game/orders.lua").Stop),
        }

    end)
end
