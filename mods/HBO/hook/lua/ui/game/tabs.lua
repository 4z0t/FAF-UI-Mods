do
    for _, t in menus.main do
        table.insert(t, {
            action = 'HBO',
            label = 'HotBuild Overhaul',
            tooltip = 'TODO'
        })
    end

    actions['HBO'] = function() import("/mods/HBO/modules/views/view.lua").init() end
end
