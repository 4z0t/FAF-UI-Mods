---@class IComponentable<T> : {_components : table<string, T> }
IComponentable = Class()
{
    ---@generic T
    ---@param self IComponentable<T>
    ---@return table<string,T>?
    GetComponents = function(self)
        return self._components
    end,

    ---@generic T
    ---@param self IComponentable<T>
    ---@param name string
    ---@return T
    GetComponent = function(self, name)
        local component = self._components[name]
        assert(component, ("No such component with name '%s'"):format(name))
        return component
    end,

    ---@generic T
    ---@param self IComponentable<T>
    ---@param name string
    ---@param class fun(instance: IComponentable<T>):T
    AddComponent = function(self, name, class)
        if self._components == nil then self._components = {} end
        if self._components[name] ~= nil then
            error(("Component '%s' already exists"):format(name))
        end
        self._components[name] = class(self)
    end,

    ---@generic T
    ---@param self IComponentable<T>
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
