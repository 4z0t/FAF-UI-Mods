function init(isReplay)
    if exists('/mods/UMT/modules/linq.lua') then
        local ViewModel = import('viewmodel.lua')
        local Model = import('model.lua')
        local View = import("views/view.lua")
        Model.init()
        ViewModel.init()
    else
        ForkThread(function()
            WaitSeconds(4)
            for i = 1, 10 do
                print("HotBuild Overhaul requires UI mod tools!!!")
            end
        end)
    end
end
