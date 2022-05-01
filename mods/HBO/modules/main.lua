function init(isReplay)
    if exists('/mods/UMT/modules/linq.lua') then
        local Presenter = import('presenter.lua')
        local Model = import('model.lua')
        local View = import("/mods/HBO/modules/views/view.lua")
        Model.init()
        Presenter.init()
    else
        ForkThread(function()
            WaitSeconds(4)
            for i = 1, 10 do
                print("HotBuild Overhaul requires UI mod tools!!!")
            end
        end)
    end
end
