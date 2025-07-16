local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('call better chat window', {
    action = 'UI_Lua import("/mods/better chat/modules/BCmain.lua").call()',
    category = 'Better chat',
    order = 404
})