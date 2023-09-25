local KeyMapper = import('/lua/keymap/keymapper.lua')
KeyMapper.SetUserKeyAction('call chat wheel', {
    action = 'UI_Lua import("/mods/ChatWheel/modules/CWMain.lua").call()',
    category = 'Chat Wheel',
    order = 405
})

local originalCreateUI = CreateUI
function CreateUI(isReplay, parent)
    originalCreateUI(isReplay)
    import("/mods/ChatWheel/modules/CWMain.lua").init(isReplay)
end

