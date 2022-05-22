function main()
    if not exists("/mods/UMT/mod_info.lua") or not exists("/mods/common/units.lua") then
        ForkThread(function()
            WaitSeconds(4)
            print("ECO UI tools requires UI mod tools and Common Mod tools!!!")
        end)
        return
    else
        local MexManager = import("mexmanager.lua")
        local MexPanel = import("mexpanel.lua")
        MexManager.init()
        MexPanel.init()
    end
end
