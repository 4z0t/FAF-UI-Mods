do
    for _, t in menus.main do
        table.insert(t, {
            action = 'HBO',
            label = 'HotBuild Overhaul',
            tooltip = 'TODO'
        })
    end

    actions['HBO'] = import("/mods/HBO/modules/views/view.lua").init
end
