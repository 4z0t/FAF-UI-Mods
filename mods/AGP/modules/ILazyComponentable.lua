local IComponentable = import("IComponentable.lua").IComponentable
---@class ILazyComponentable : IComponentable
ILazyComponentable = Class(IComponentable)
{
    ---@generic T
    ---@param self ILazyComponentable
    ---@param name string
    ---@return T
    GetComponent = function(self, name)
        local component = self._components[name]

        if not component then
            local classes = self:GetClassProvider()
            self:AddComponent(name, classes[name])
            component = self._components[name]
        end
        return component
    end,


    ---@generic T
    ---@param self ILazyComponentable
    ---@return table<string, fun():T>
    GetClassProvider = function(self)
        error("'GetClassProvider' Must be implemented!!")
        return nil
    end,
}
