local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

function Main(isReplay)
    local MexManager = import("mexmanager.lua")
    local MexPanel = import("mexpanel.lua")
    local MexOverlay = import("mexoverlay.lua")
    local Options = import("options.lua")
    local KeyActions = import("KeyActions.lua")
    Options.Init()
    MexManager.init()
    MexPanel.init()
    MexOverlay.init()
    KeyActions.Init()
end
