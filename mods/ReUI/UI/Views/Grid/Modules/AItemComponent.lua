---Abstract class for Item component.
---@class AItemComponent : IComponent
AItemComponent = Class()
{
    ---@param self AItemComponent
    ---@param item AGridItem
    __init = function(self, item)
        self:Create(item)
    end,

    ---Called when component is bond to an item
    ---@param self AItemComponent
    ---@param item AGridItem
    Create = function(self, item)
    end,

    ---Called when grid item receives an event
    ---@param self AItemComponent
    ---@param item AGridItem
    ---@param event KeyEvent
    HandleEvent = function(self, item, event)
    end,

    ---Called when grid item is updated on frame
    ---@param self AItemComponent
    ---@param item AGridItem
    ---@param delta number
    OnFrame = function(self, item, delta)
    end,

    ---Called when item is activated with this component event handling
    ---@param self AItemComponent
    ---@param item AGridItem
    ---@param action string
    ---@param context any
    Enable = function(self, item, action, context)
    end,

    ---Called when item is changing event handler
    ---@param self AItemComponent
    ---@param item AGridItem
    Disable = function(self, item)
    end,

    ---Called when component is being destroyed
    ---@param self AItemComponent
    Destroy = function(self)
    end,
}
