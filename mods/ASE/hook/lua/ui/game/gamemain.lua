do
    local OldCreateUI = CreateUI
    function CreateUI(isReplay)
        OldCreateUI(isReplay)
        import('/mods/ASE/modules/Main.lua').Main(isReplay)
    end

    local ASE = import('/mods/ASE/modules/Main.lua')
    local originalOnSelectionChanged = OnSelectionChanged
    function OnSelectionChanged(oldSelection, newSelection, added, removed)

        if ignoreSelection or import('/lua/ui/game/selection.lua').IsHidden() then
            return
        end

        if not ASE.SelectionChanged(oldSelection, newSelection, added, removed) then
            originalOnSelectionChanged(oldSelection, newSelection, added, removed)
        end

    end

    local KeyMapper = import('/lua/keymap/keymapper.lua')
    KeyMapper.SetUserKeyAction('Toggle Advanced Selection Extension',
        {
            action = "UI_Lua import('/mods/ASE/modules/Main.lua').Toggle()",
            category = 'Advanced Selection Extension',

        })

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
    KeyMapper.SetUserKeyAction('Add Units Group',
        {
            action = "UI_Lua import('/mods/ASE/modules/Groups.lua').AssignGroup()",
            category = 'Advanced Selection Extension',

        })

    KeyMapper.SetUserKeyAction('Remove from groups',
        {
            action = "UI_Lua import('/mods/ASE/modules/Groups.lua').RemoveFromGroups()",
            category = 'Advanced Selection Extension',
        })
    KeyMapper.SetUserKeyAction('Rotate Domain order',
        {
            action = "UI_Lua import('/mods/ASE/modules/Selection.lua').RotateDomains()",
            category = 'Advanced Selection Extension',
        })


end
