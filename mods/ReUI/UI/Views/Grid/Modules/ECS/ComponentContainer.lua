---@class IComponent : Destroyable

---@class ComponentContainer
---@field _components table<string, IComponent>
ComponentContainer = Class()
{
    ---@param self ComponentContainer
    ---@return table<string, IComponent>?
    GetComponents = function(self)
        return self._components
    end,

    ---@param self ComponentContainer
    ---@param name string
    ---@return IComponent
    GetComponent = function(self, name)
        local component = self._components[name]
        assert(component, ("No such component with name '%s'"):format(name))
        return component
    end,

    ---@param self ComponentContainer
    ---@param name string
    ---@param class fun(instance: ComponentContainer):IComponent
    AddComponent = function(self, name, class)
        if self._components == nil then self._components = {} end
        if self._components[name] ~= nil then
            error(("Component '%s' already exists"):format(name))
        end
        self._components[name] = class(self)
    end,

    ---@param self ComponentContainer
    DestroyComponents = function(self)
        if self._components == nil then
            return
        end

        for _, component in self._components do
            component:Destroy()
        end
        self._components = nil
    end,
}
