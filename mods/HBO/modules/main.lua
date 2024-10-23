function Main(isReplay)
    local ViewModel = import('viewmodel.lua')
    local Model = import('model.lua')
    local View = import("views/view.lua")
    local Share = import("share.lua")
    local KeyMapper = import('/lua/keymap/keymapper.lua')

    Model.init()
    ViewModel.init()
    Share.Init(isReplay)
    KeyMapper.SetUserKeyAction('Open HBO editor', {
        action = 'UI_Lua import("/mods/HBO/modules/views/view.lua").init()',
        category = 'HotBuild Overhaul Editor',
        order = 404
    })
end
