do
    local __ReUI = { Require = import("/mods/ReUI.Core/Modules/Loader.lua").Require }
    ---@type ReUI
    local ReUI = setmetatable({ __data = __ReUI, },
        {
            __newindex = function(self, k, v)
                error("Manual assignment into ReUI is forbidden")
            end,

            __index = function(self, k)
                local v = __ReUI[k]
                if not v then
                    error(("'ReUI.%s' doesn't exist"):format(k))
                end
                return v
            end,
        })
    _G.ReUI = ReUI
end
