local AGridItem = import("AGridItem.lua").AGridItem

---@class BaseGridItem : AGridItem
---@field _componentClasses table<string, fun(instance: BaseGridItem):AItemComponent>
BaseGridItem = ReUI.Core.Class(AGridItem)
{
    ---@param self BaseGridItem
    ---@param parent ReUI.UI.Controls.Control
    __init = function(self, parent)
        AGridItem.__init(self, parent)
        self._componentClasses = {}
    end,

    ---@type table<string, fun(instance: BaseGridItem):AItemComponent>
    ComponentClasses = ReUI.Core.Property
    {
        ---@param self BaseGridItem
        get = function(self)
            return self._componentClasses
        end,

        ---@param self BaseGridItem
        ---@param value table<string, fun(instance: BaseGridItem):AItemComponent>
        set = function(self, value)
            self._componentClasses = value
        end
    },

    ---@param self BaseGridItem
    ---@param name string
    ---@return fun(instance: BaseGridItem):AItemComponent
    GetComponentClassByName = function(self, name)
        local class = self._componentClasses[name]
        assert(class ~= nil, "There is no class for component '" .. name .. "'")
        return class
    end,

    ---@param self BaseGridItem
    OnDestroy = function(self)
        self._componentClasses = nil
        AGridItem.OnDestroy(self)
    end,
}
