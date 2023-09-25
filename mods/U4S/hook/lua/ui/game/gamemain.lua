---@class UIToSimSyncData
---@field name string
---@field args table?

_G.UI4Sim = {
    ---Makes Sim callback from UI
    ---@param data any
    Callback = function(name, data)
        SimCallback
        {
            Func = "UI4Sim",
            Args = {
                Name = name,
                From = GetFocusArmy(),
                Data = data
            }
        }
    end
}
