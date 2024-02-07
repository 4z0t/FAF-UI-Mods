do
    for _, t in menus.main do
        table.insert(t, {
            action = 'AGP',
            label = 'Actions Grid Extensions',
            tooltip = 'TODO'
        })
    end
    actions['AGP'] = import('/mods/AGP/modules/Main.lua').CreateSelector
end
