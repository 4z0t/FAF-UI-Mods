---@class IItemComponent
IItemComponent = Class()
{
    __init = function(self, item)
        self:Create(item)
    end,

    ---Called when component is bond to an item
    ---@param self IItemComponent
    ---@param item Item
    Create = function(self, item)
    end,

    ---Called when grid item receives an event
    ---@param self IItemComponent
    ---@param item Item
    ---@param event KeyEvent
    HandleEvent = function(self, item, event)
    end,

    ---Called when item is activated with this component event handling
    ---@param self IItemComponent
    ---@param item Item
    Enable = function(self, item)
    end,

    ---@param self IItemComponent
    ---@param action string
    SetAction = function(self, action)
    end,

    ---Called when item is changing event handler
    ---@param self IItemComponent
    ---@param item Item
    Disable = function(self, item)
    end,

    ---Called when component is being destroyed
    ---@param self IItemComponent
    Destroy = function(self)
    end,
}
