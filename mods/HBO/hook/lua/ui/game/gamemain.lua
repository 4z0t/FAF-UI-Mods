do 
    local KeyMapper = import('/lua/keymap/keymapper.lua')
    KeyMapper.SetUserKeyAction('Open HBO editor', {
        action = 'UI_Lua import("/mods/HBO/modules/views/view.lua").init()',
        category = 'HotBuild Overhaul Editor',
        order = 404
    })
    
    local originalCreateUI = CreateUI
    function CreateUI(isReplay, parent)
        originalCreateUI(isReplay)
        import("/mods/HBO/modules/main.lua").init(isReplay)
    end
end
