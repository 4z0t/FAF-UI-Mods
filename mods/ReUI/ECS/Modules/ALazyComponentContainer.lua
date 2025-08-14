---@diagnostic disable-next-line: different-requires
local ComponentContainer = import("ComponentContainer.lua").ComponentContainer

---@class ALazyComponentContainer : ComponentContainer
ALazyComponentContainer = Class(ComponentContainer)
{
    ---@param self ALazyComponentContainer
    ---@param name string
    ---@return IComponent
    GetComponent = function(self, name)
        local component = ComponentContainer.GetComponent(self, name)

        if not component then
            self:AddComponent(name, self:CreateComponent(name))
            component = self._components[name]
        end

        return component
    end,

    ---@param self ALazyComponentContainer
    ---@param name string
    ---@return IComponent
    CreateComponent = function(self, name)
        error("'ALazyComponentContainer.CreateComponent' Must be implemented!!")
    end,
}
