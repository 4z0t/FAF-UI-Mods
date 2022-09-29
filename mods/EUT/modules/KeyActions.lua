function Init()
    local KeyMapper = import('/lua/keymap/keymapper.lua')

    local nameEUT = 'ECO UI Tools'
    local prefix = 'import("/mods/EUT/modules/mexmanager.lua").'
    KeyMapper.SetUserKeyAction('Select all idle t1 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(1)',
        category = nameEUT,
        order = 1000
    })

    KeyMapper.SetUserKeyAction('Select all upgrading paused t1 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(2)',
        category = nameEUT,
        order = 1001
    })

    KeyMapper.SetUserKeyAction('Select all upgrading t1 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(3)',
        category = nameEUT,
        order = 1002
    })

    KeyMapper.SetUserKeyAction('Select all idle t2 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(4)',
        category = nameEUT,
        order = 1003
    })

    KeyMapper.SetUserKeyAction('Select all upgrading paused t2 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(5)',
        category = nameEUT,
        order = 1004
    })

    KeyMapper.SetUserKeyAction('Select all upgrading t2 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(6)',
        category = nameEUT,
        order = 1005
    })

    KeyMapper.SetUserKeyAction('Select all idle t3 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SelectAll(7)',
        category = nameEUT,
        order = 1006
    })

    KeyMapper.SetUserKeyAction('Upgrade all idle t1 mexes', {
        action = 'UI_Lua ' .. prefix .. 'UpgradeAll(1)',
        category = nameEUT,
        order = 1007
    })

    KeyMapper.SetUserKeyAction('Upgrade all idle t2 mexes', {
        action = 'UI_Lua ' .. prefix .. 'UpgradeAll(4)',
        category = nameEUT,
        order = 1008
    })

    KeyMapper.SetUserKeyAction('Select best paused upgrading t1 mex', {
        action = 'UI_Lua ' .. prefix .. 'SelectBest(2)',
        category = nameEUT,
        order = 1009
    })
    KeyMapper.SetUserKeyAction('Select best paused upgrading t2 mex', {
        action = 'UI_Lua ' .. prefix .. 'SelectBest(5)',
        category = nameEUT,
        order = 1010
    })


    KeyMapper.SetUserKeyAction('Pause all upgrading t1 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SetPausedAll(3, true)',
        category = nameEUT,
        order = 1011
    })

    KeyMapper.SetUserKeyAction('Pause all upgrading t2 mexes', {
        action = 'UI_Lua ' .. prefix .. 'SetPausedAll(6, true)',
        category = nameEUT,
        order = 1012
    })

    KeyMapper.SetUserKeyAction('Pause all upgrading mexes', {
        action = 'UI_Lua ' .. prefix .. 'SetPausedAll(3, true); UI_Lua ' .. prefix .. 'SetPausedAll(6, true) ',
        category = nameEUT,
        order = 1012
    })

    KeyMapper.SetUserKeyAction('Pause worst upgrading t1 mex', {
        action = 'UI_Lua ' .. prefix .. 'PauseWorst(3)',
        category = nameEUT,
        order = 1013
    })

    KeyMapper.SetUserKeyAction('Pause worst upgrading t2 mex', {
        action = 'UI_Lua ' .. prefix .. 'PauseWorst(6)',
        category = nameEUT,
        order = 1014
    })
    KeyMapper.SetUserKeyAction('Unpause best upgrading t1 mex', {
        action = 'UI_Lua ' .. prefix .. 'UnPauseBest(2)',
        category = nameEUT,
        order = 1015
    })

    KeyMapper.SetUserKeyAction('Unpause best upgrading t2 mex', {
        action = 'UI_Lua ' .. prefix .. 'UnPauseBest(5)',
        category = nameEUT,
        order = 1016
    })
end
