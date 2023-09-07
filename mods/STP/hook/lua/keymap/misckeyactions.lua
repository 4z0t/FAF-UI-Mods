do
    local KeyMapper = import("/lua/keymap/keymapper.lua")
    local PriorityMapper = import("/mods/STP/modules/PriorityMapper.lua")

    local prevBpId = nil
    local prevTick = 0
    function SetWeaponPrioritiesSpecific()
        local curTick = GetSystemTimeSeconds()
        local info = GetRolloverInfo()
        local isDoubleClick = curTick - prevTick < 1.0

        if info and info.blueprintId ~= "unknown" then
            local bpId = info.blueprintId

            if bpId == prevBpId and isDoubleClick then -- specifically target that one unit type
                local text = LOC(__blueprints[bpId].General.UnitName)
                if text then
                    text = "\n" .. text .. " — " .. LOC(__blueprints[bpId].Interface.HelpText)
                else
                    text = "\n" .. LOC(__blueprints[bpId].Interface.HelpText)
                end

                SetWeaponPriorities(PriorityMapper.ToCategory(bpId), text, false)
            else -- find common category for that unit
                local category, text = PriorityMapper.Get(bpId)
                if category then
                    SetWeaponPriorities(category, "\n" .. text, false)
                end
            end
        elseif not prevBpId and isDoubleClick then -- double click on ground -> reset to default
            SetWeaponPriorities(0, "Default", false)
        end

        prevBpId = info.blueprintId
        prevTick = curTick
    end

    function SetWeaponPrioritiesSpecificType()
        local info = GetRolloverInfo()

        if info and info.blueprintId ~= "unknown" then
            local bpId = info.blueprintId

            local text = LOC(__blueprints[bpId].General.UnitName)
            if text then
                text = "\n" .. text .. " — " .. LOC(__blueprints[bpId].Interface.HelpText)
            else
                text = "\n" .. LOC(__blueprints[bpId].Interface.HelpText)
            end

            SetWeaponPriorities(PriorityMapper.ToCategory(bpId), text, false)
        end
    end

    function SetWeaponPrioritiesSpecificCommon()
        local info = GetRolloverInfo()

        if info and info.blueprintId ~= "unknown" then
            local bpId = info.blueprintId

            local category, text = PriorityMapper.Get(bpId)
            if category then
                SetWeaponPriorities(category, "\n" .. text, false)
            end
        end
    end

    -- Specific
    KeyMapper.SetUserKeyAction("target_specific", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecific()",
        category = "Target priorities"
    })
    KeyMapper.SetUserKeyAction("Shift_target_specific", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecific()",
        category = "Target priorities"
    })
    KeyMapper.SetUserKeyAction("target_specific_type", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecificType()",
        category = "Target priorities"
    })
    KeyMapper.SetUserKeyAction("Shift_target_specific_type", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecificType()",
        category = "Target priorities"
    })
    KeyMapper.SetUserKeyAction("target_specific_common", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecificCommon()",
        category = "Target priorities"
    })
    KeyMapper.SetUserKeyAction("Shift_target_specific_common", {
        action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecificCommon()",
        category = "Target priorities"
    })
end
