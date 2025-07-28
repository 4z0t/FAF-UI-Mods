local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler

---@class ExampleContext
local ExampleContext = ReUI.Core.Class()
{
}

---@class ExampleHandler : ASelectionHandler
---@field _context ExampleContext
ExampleHandler = ReUI.Core.Class(ASelectionHandler)
{
    Name = "ExampleHandler",

    OnInit = function(self)
        self._context = ExampleContext()
    end,

    ---@param self ExampleHandler
    ---@param context any
    ---@return string[]?
    ---@return ExampleContext?
    Update = function(self, context)
    end,

    ---@param self ExampleHandler
    OnDestroy = function(self)
    end,

    ---@class ExampleItem : AItemComponent
    ComponentClass = ReUI.Core.Class(AItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self ExampleItem
        ---@param item AGridItem
        Create = function(self, item)
        end,

        ---Called when grid item receives an event
        ---@param self ExampleItem
        ---@param item AGridItem
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
        end,

        ---Called when grid item is updated on frame
        ---@param self ExampleItem
        ---@param item AGridItem
        ---@param delta number
        OnFrame = function(self, item, delta)
        end,

        ---Called when item is activated with this component event handling
        ---@param self ExampleItem
        ---@param item AGridItem
        ---@param action any
        ---@param context ExampleContext
        Enable = function(self, item, action, context)
        end,

        ---Called when item is changing event handler
        ---@param self ExampleItem
        ---@param item AGridItem
        Disable = function(self, item)
        end,

        ---Called when component is being destroyed
        ---@param self ExampleItem
        Destroy = function(self)
        end,
    },
}
