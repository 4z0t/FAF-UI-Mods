do

    local __ReUI = {}
    ---@type ReUI.Loader
    local loader = import("/mods/ReUI/Core/Modules/Loader.lua").Loader(__ReUI,
        {
            --[[ internal modules list]]
        })

    ---@param tag string
    ---@return ReUI.Module?
    function __ReUI.Exists(tag)
        return loader:Exists(tag)
    end

    ---@param deps string[]|DependencyInfo
    function __ReUI.Require(deps)
        return loader:Require(deps)
    end

    ---@param name string
    ---@return ReUI.Module?
    function __ReUI.Get(name)
        return loader:GetModule(name)
    end

    ---@type ReUI
    local ReUI = setmetatable({ __loader = loader, },
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
