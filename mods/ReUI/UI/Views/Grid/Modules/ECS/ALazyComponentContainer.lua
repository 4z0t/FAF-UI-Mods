local ComponentContainer = import("ComponentContainer.lua").ComponentContainer

---@class ALazyComponentContainer : ComponentContainer
ALazyComponentContainer = Class(ComponentContainer)
{
    ---@param self ALazyComponentContainer
    ---@param name string
    ---@return IComponent
    GetComponent = function(self, name)
        local component = self._components[name]

        if not component then
            local componentClass = self:GetComponentClassByName(name)
            self:AddComponent(name, componentClass)
            component = self._components[name]
        end

        return component
    end,

    ---@param self ALazyComponentContainer
    ---@param name string
    ---@return fun(instance: ALazyComponentContainer):IComponent
    GetComponentClassByName = function(self, name)
        error("'GetComponentClassByName' Must be implemented!!")
    end,
}
