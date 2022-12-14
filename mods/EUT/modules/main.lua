local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

function main(parent)
    if ExistGlobal "UMT" and UMT.Version >= 7 then
        local MexManager = import("mexmanager.lua")
        local MexPanel = import("mexpanel.lua")
        local MexOverlay = import("mexoverlay.lua")
        local Options = import("options.lua")
        local KeyActions = import("KeyActions.lua")
        Options.Init()
        MexManager.init()
        MexPanel.init(parent)
        MexOverlay.init()
        KeyActions.Init()
    else
        ForkThread(function()
            WaitSeconds(4)
            print("ECO UI tools requires UI mod tools version 7 and higher!!!")
        end)
        return
    end
end
