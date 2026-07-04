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

        if component == nil then
            component = self:CreateComponent(name)
            self:AddComponent(name, component)
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
