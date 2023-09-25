local U4Ssim = import("/mods/U4S/modules/Sim/Main.lua")
_G.UI4Sim = {
    ---Makes callback to UI
    ---@param data SimToUISyncData
    Callback = function(data)
        Sync.UI4Sim = Sync.UI4Sim or {}
        
        if not U4Ssim.ValidateArgs(data.args) then return end

        Sync.UI4Sim[data.name] = {
            fileName = data.fileName,
            functionName = data.functionName,
            args = data.args,
        }
        if data.func then
            U4Ssim.Add(data.name, data.func)
        end

    end
}
