do
    local ASESelectionChanged = import('/mods/ASE/modules/Main.lua').SelectionChanged
    local _OnSelectionChanged = OnSelectionChanged
    function OnSelectionChanged(oldSelection, newSelection, added, removed)

        if ignoreSelection or import('/lua/ui/game/selection.lua').IsHidden() then
            return
        end

        if not ASESelectionChanged(oldSelection, newSelection, added, removed) then
            _OnSelectionChanged(oldSelection, newSelection, added, removed)
        end

    end

    local KeyMapper = import('/lua/keymap/keymapper.lua')
    KeyMapper.SetUserKeyAction('Toggle units lock',
        {
            action = "UI_Lua import('/mods/ASE/modules/Lock.lua').ToggleUnits()",
            category = 'Advanced Selection Extension',

        })
    KeyMapper.SetUserKeyAction('Toggle unit lock',
        {
            action = "UI_Lua import('/mods/ASE/modules/Lock.lua').ToggleUnit()",
            category = 'Advanced Selection Extension',

        })

    KeyMapper.SetUserKeyAction('Set AIR layer',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetActiveLayer('AIR')",
            category = 'Advanced Selection Extension',

        })
    KeyMapper.SetUserKeyAction('Set NAVAL layer',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetActiveLayer('NAVAL')",
            category = 'Advanced Selection Extension',

        })
    KeyMapper.SetUserKeyAction('Set LAND layer',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetActiveLayer('LAND')",
            category = 'Advanced Selection Extension',

        })
    -- KeyMapper.SetUserKeyAction('Add Units Group',
    --     {
    --         action = "UI_Lua import('/mods/ASE/modules/Groups.lua').AssignGroup()",
    --         category = 'Advanced Selection Extension',

    --     })

    -- KeyMapper.SetUserKeyAction('Remove from groups',
    --     {
    --         action = "UI_Lua import('/mods/ASE/modules/Groups.lua').RemoveFromGroups()",
    --         category = 'Advanced Selection Extension',
    --     })
    KeyMapper.SetUserKeyAction('Rotate Domain order',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').RotateDomains()",
            category = 'Advanced Selection Extension',
        })

    KeyMapper.SetUserKeyAction("NAVAL > LAND  > AIR",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(1)",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction("NAVAL > AIR   > LAND",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(2)",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction("LAND  > AIR   > NAVAL",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(3)",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction("LAND  > NAVAL > AIR",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(4)",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction("AIR   > LAND  > NAVAL",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(5)",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction("AIR   > NAVAL > LAND",
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').SetDomain(6)",
            category = 'Advanced Selection Extension',
        })

    KeyMapper.SetUserKeyAction('Rotate Domain order',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').RotateDomains()",
            category = 'Advanced Selection Extension',
        })

    KeyMapper.SetUserKeyAction("Toggle Domain Filter",
        {
            action = "UI_Lua import('/mods/ASE/modules/Main.lua').ToggleLayerFilter()",
            category = "Advanced Selection Extension"
        })

    KeyMapper.SetUserKeyAction("Toggle Exotic Filter",
        {
            action = "UI_Lua import('/mods/ASE/modules/Main.lua').ToggleExoticFilter()",
            category = "Advanced Selection Extension"
        })

    KeyMapper.SetUserKeyAction("Toggle Assisters Filter",
        {
            action = "UI_Lua import('/mods/ASE/modules/Main.lua').ToggleAssisterFilter()",
            category = "Advanced Selection Extension"
        })

end
