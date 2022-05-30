local KeyMapper = import("/lua/keymap/keymapper.lua")

function SetWeaponPrioritiesSpecific()
    local info = GetRolloverInfo()
    if info and info.blueprintId ~= "unknown" then

        local bpId = info.blueprintId
        local text = LOC(__blueprints[bpId].General.UnitName)
        
        if text then
            text = "\n" .. text .. " — " .. LOC(__blueprints[bpId].Interface.HelpText)
        else
            text = "\n" .. LOC(__blueprints[bpId].Interface.HelpText)
        end

        SetWeaponPriorities("{categories." .. bpId .. "}", text, false)
    end
end
-- Specific
KeyMapper.SetUserKeyAction("target_specific", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecific()",
    category = "Target priorities",
    order = 109
})
KeyMapper.SetUserKeyAction("Shift_target_specific", {
    action = "UI_Lua import(\"/lua/keymap/misckeyactions.lua\").SetWeaponPrioritiesSpecific()",
    category = "Target priorities",
    order = 110
})
