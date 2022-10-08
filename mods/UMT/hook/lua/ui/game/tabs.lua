do
    for _, t in menus.main do
        table.insert(t, {
            action = 'UMToptions',
            label = 'UI mods options',
            tooltip = 'TODO'
        })
    end
    actions['UMToptions'] = import('/mods/UMT/modules/GlobalOptions.lua').main
end
