---@class IComponent : Destroyable
---@field enabled boolean

local next = next

---@param components table<string, IComponent>?
---@param key string?
---@return string?, IComponent?
local function EnabledComponentsIterator(components, key)
    if components then
        for name, component in next, components, key do
            if component.enabled then
                return name, component
            end
        end
    end
    return nil, nil
end

---@param components table<string, IComponent>?
---@param key string?
---@return string?, IComponent?
local function ComponentsIterator(components, key)
    if components then
        return next(components, key)
    end
    return nil, nil
end

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
    ---@return fun(components: table<string, IComponent>?, key: string): string?, IComponent?
    ---@return table<string, IComponent>
    ---@return string?
    IterateComponents = function(self)
        return ComponentsIterator, self._components, nil
    end,

    ---Returns an iterator over enabled components
    ---@param self ComponentContainer
    ---@return fun(components: table<string, IComponent>?, key: string): string?, IComponent?
    ---@return table<string, IComponent>
    ---@return string?
    IterateEnabledComponents = function(self)
        return EnabledComponentsIterator, self._components, nil
    end,

    ---@param self ComponentContainer
    ---@param name string
    ---@return IComponent?
    GetComponent = function(self, name)
        return self._components[name]
    end,

    ---@param self ComponentContainer
    ---@param name string
    ---@param component IComponent
    AddComponent = function(self, name, component)
        if self._components == nil then self._components = {} end
        if self._components[name] ~= nil then
            error(("Component '%s' already exists"):format(name))
        end
        self._components[name] = component
    end,

    ---@param self ComponentContainer
    ---@param name string
    RemoveComponent = function(self, name)
        local components = self._components
        if components == nil then
            return
        end
        local component = components[name]
        if component == nil then
            return
        end
        component:Destroy()
        components[name] = nil
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
