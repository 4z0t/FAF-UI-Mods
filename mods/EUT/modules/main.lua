local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

function Main(isReplay)
    if UMT.Version < 11 then
        WARN("EUT requires UMT Version 11 or higher")
        return
    end
    --local Options = import("options.lua")
    local MexManager = import("mexmanager.lua")
    local MexPanel = import("mexpanel.lua")
    local MexOverlay = import("mexoverlay.lua")
    local KeyActions = import("KeyActions.lua")
    --Options.Init()
    MexManager.init()
    MexPanel.init()
    MexOverlay.init()
    KeyActions.Init()
end
