local KeyMapper = import("/lua/keymap/keymapper.lua")


-- Select ACU / goto ACU / OC mode
local lastACUSelectionTime = 0
function ACUSelectOCCG()
    local curTime = GetSystemTimeSeconds()
    local diffTime = curTime - lastACUSelectionTime
    if diffTime > 1.0 then
        local selection = GetSelectedUnits()
        if not table.empty(selection) and table.getn(selection) == 1 and selection[1]:IsInCategory "COMMAND" then
            import("/lua/ui/game/orders.lua").EnterOverchargeMode()
        else
            ConExecute "UI_SelectByCategory +nearest COMMAND"
        end
    else
        ConExecute "UI_SelectByCategory +nearest +goto COMMAND"
    end
    lastACUSelectionTime = curTime
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


KeyMapper.SetUserKeyAction("Remove last ququed unit in factory", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").RemoveLastItem()",
    category = "orders",
    order = 17
})

KeyMapper.SetUserKeyAction("Shift Remove last ququed unit in factory", {
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
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").ACUSelectOCCG()",
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
