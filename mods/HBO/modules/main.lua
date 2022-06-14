function init(isReplay)
    if exists("/mods/UMT/mod_info.lua") and import("/mods/UMT/mod_info.lua").version >= 4 then
        local ViewModel = import('viewmodel.lua')
        local Model = import('model.lua')
        local View = import("views/view.lua")
        local Share = import("share.lua")
        Model.init()
        ViewModel.init()
        Share.Init(isReplay)
    else
        ForkThread(function()
            WaitSeconds(4)
            print("HotBuild Overhaul requires UI mod tools!!!")
        end)
    end
end
