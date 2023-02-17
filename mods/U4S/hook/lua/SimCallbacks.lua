local U4Ssim = import("/mods/U4S/modules/Sim/Main.lua")

Callbacks.UI4Sim = function(data)
    U4Ssim.Process(data.Name, data.Data, data.From)
end
