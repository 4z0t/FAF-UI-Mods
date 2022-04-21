local KeyMapper = import('/lua/keymap/keymapper.lua')

function SetWeaponPrioritiesSpecific()
    local info = GetRolloverInfo()
    if info and info.blueprintId ~= 'unknown' then
        -- local bp = __blueprints[info.blueprintId].Description
        -- LOG(repr(bp))
        -- LOG(info.blueprintId)
        SetWeaponPriorities('{categories.' .. info.blueprintId .. '}', LOC(__blueprints[info.blueprintId].Description),
            false)
    end
end
-- Specific
KeyMapper.SetUserKeyAction('target_specific', {
    action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SetWeaponPrioritiesSpecific()',
    category = 'Target priorities',
    order = 109
})
KeyMapper.SetUserKeyAction('Shift_target_specific', {
    action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SetWeaponPrioritiesSpecific()',
    category = 'Target priorities',
    order = 110
})
