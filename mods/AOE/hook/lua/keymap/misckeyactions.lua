local KeyMapper = import("/lua/keymap/keymapper.lua")


-- Select ACU / OC mode
function ACUSelectOC()
    local selection = GetSelectedUnits()
    if not table.empty(selection) and table.getn(selection) == 1 and selection[1]:IsInCategory "COMMAND" then
        import("/lua/ui/game/orders.lua").EnterOverchargeMode()
    else
        ConExecute "UI_SelectByCategory +nearest COMMAND"
    end
end

-- Select nearest idle engineer / Reclaim mode
function ReclaimSelectIDLENearestT1()
    local selection = GetSelectedUnits()
    if table.empty(selection) then
        ConExecute "UI_SelectByCategory +inview +nearest +idle ENGINEER TECH1"
    else
        ConExecute "StartCommandMode order RULEUCC_Reclaim"
    end
end

-- Decrease Unit count in factory queue
local DecreaseBuildCountInQueue = import("/lua/ui/game/construction.lua").DecreaseBuildCountInQueue
local RefreshUI = import("/lua/ui/game/construction.lua").RefreshUI
function RemoveLastItem()
    local selectedUnits = GetSelectedUnits()
    if selectedUnits and selectedUnits[1]:IsInCategory "FACTORY" then
        local currentCommandQueue = SetCurrentFactoryForQueueDisplay(selectedUnits[1])
        local count = 1
        if IsKeyDown "Shift" then
            count = 5
        end
        DecreaseBuildCountInQueue(table.getsize(currentCommandQueue), count)
        ClearCurrentFactoryForQueueDisplay()
        RefreshUI()
    end
end

-- Select nearest air scout / build sensors
function SelectAirScoutBuildIntel()
    local selectedUnits = GetSelectedUnits()
    if selectedUnits then
        import("/lua/keymap/hotbuild.lua").buildAction "Sensors"
    else
        ConExecute "UI_SelectByCategory +nearest AIR INTELLIGENCE"
    end
end

function SelectNearestIdleTransportOrTransport()
    local selectedUnits = GetSelectedUnits()
    if selectedUnits then
        ConExecute "StartCommandMode order RULEUCC_Transport"
    else
        ConExecute "UI_SelectByCategory +nearest +idle AIR TRANSPORTATION"
    end
end

local currentMex = nil
function LoopOverMexes(onScreen, upgrade)
    if upgrade then
        local selectedUnits = GetSelectedUnits()
        if selectedUnits and table.getn(selectedUnits) == 1 and selectedUnits[1]:IsInCategory("MASSEXTRACTION") then
            local bp = selectedUnits[1]:GetBlueprint()
            IssueBlueprintCommand("UNITCOMMAND_Upgrade", bp.General.UpgradesTo, 1, false)
        end
    end
    local isFound = false
    for _, tech in { "TECH1", "TECH2" } do
        UISelectionByCategory("MASSEXTRACTION STRUCTURE " .. tech, false, onScreen, false, true)
        local selectedMexes = GetSelectedUnits()
        if selectedMexes and not table.empty(selectedMexes) then
            table.sort(selectedMexes, function(a, b)
                return a:GetEntityId() < b:GetEntityId()
            end)
            for _, mex in selectedMexes do
                if currentMex == nil or currentMex:IsDead() then
                    currentMex = mex
                    isFound = true
                    break
                elseif currentMex:GetEntityId() < mex:GetEntityId() then
                    currentMex = mex
                    isFound = true
                    break
                    -- else
                    --     currentMex = mex
                end
            end
            if not isFound then
                currentMex = selectedMexes[1]
                isFound = true
                break
            end
        end
        if isFound then
            break
        end
    end
    if isFound then
        SelectUnits({ currentMex })
    end
end

KeyMapper.SetUserKeyAction("Remove last ququed unit in factory", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").RemoveLastItem()",
    category = "orders",
    order = 17
})

KeyMapper.SetUserKeyAction("Shift Remove last queued unit in factory", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").RemoveLastItem()",
    category = "orders",
    order = 18
})

KeyMapper.SetUserKeyAction("Select All IDLE engineers on screen not ACU", {
    action = "UI_SelectByCategory +inview +idle ENGINEER TECH1,ENGINEER TECH2,ENGINEER TECH3",
    category = "selection",
    order = 19
})

KeyMapper.SetUserKeyAction("Select ACU / Enter OC mode", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").ACUSelectOC()",
    category = "selection",
    order = 20
})

KeyMapper.SetUserKeyAction("Goto ACU", {
    action = "UI_SelectByCategory +nearest +goto COMMAND",
    category = "selection",
    order = 20
})

KeyMapper.SetUserKeyAction("Select Nearest IDLE T1 engineer / enter reclaim mode", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").ReclaimSelectIDLENearestT1()",
    category = "selection",
    order = 21
})

KeyMapper.SetUserKeyAction("Shift Select Nearest IDLE T1 engineer / enter reclaim mode", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").ReclaimSelectIDLENearestT1()",
    category = "selection",
    order = 22
})


KeyMapper.SetUserKeyAction("Select nearest air scout / build sensors", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SelectAirScoutBuildIntel()",
    category = "selection",
    order = 23
})

KeyMapper.SetUserKeyAction("Shift Select nearest air scout / build sensors", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SelectAirScoutBuildIntel()",
    category = "selection",
    order = 24
})

KeyMapper.SetUserKeyAction("Select nearest idle transport / transport order", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SelectNearestIdleTransportOrTransport()",
    category = "selection",
    order = 25
})

KeyMapper.SetUserKeyAction("Shift Select nearest idle transport / transport order", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SelectNearestIdleTransportOrTransport()",
    category = "selection",
    order = 26
})

KeyMapper.SetUserKeyAction("Loop over mexes on screen", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").LoopOverMexes(true, false)",
    category = "selection",
    order = 27
})

KeyMapper.SetUserKeyAction("Loop over mexes on screen and upgrade previous", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").LoopOverMexes(true, true)",
    category = "selection",
    order = 28
})

KeyMapper.SetUserKeyAction("Loop over mexes", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").LoopOverMexes(false, false)",
    category = "selection",
    order = 27
})

KeyMapper.SetUserKeyAction("Loop over mexes and upgrade previous", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").LoopOverMexes(false, true)",
    category = "selection",
    order = 28
})