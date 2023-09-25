local _OnSync = OnSync
local U4Sui = import("/mods/U4S/modules/UI/Main.lua")
function OnSync()
    _OnSync()

    if not Sync.UI4Sim then return end

    U4Sui.Process(Sync.UI4Sim)
end
