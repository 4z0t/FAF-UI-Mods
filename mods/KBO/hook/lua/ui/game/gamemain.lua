
local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('kbo', {
    action = 'UI_Lua import("/mods/KBO/modules/views/view.lua").init()',
    category = 'KBO',
    order = 404
})

-- local originalCreateUI = CreateUI
-- function CreateUI(isReplay, parent)
--     originalCreateUI(isReplay)
--     import("/mods/KBO/modules/main.lua").init(isReplay)
-- end
