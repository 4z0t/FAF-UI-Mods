local ISelectionHandler = import("ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("IItemComponent.lua").IItemComponent



---@class ExampleHandler : ISelectionHandler
ExampleHandler = Class(ISelectionHandler)
{
    Name = "Example extension",
    Enabled = false,
    ---@param self ExampleHandler
    ---@param selection UserUnit[]
    ---@return string[]?
    OnSelectionChanged = function(self, selection)
        if table.empty(selection) then
            return
        end
        if table.empty(EntityCategoryFilterDown(categories.COMMAND, selection)) then
            return { 1, 2, 3 }
        end
        return { 4, 5, 6 }
    end,

    ---@class ExampleComponent : IItemComponent
    ---@field text UMT.Text
    ---@field index number
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self ExampleComponent
        ---@param item Item
        Create = function(self, item)
            self.text = UMT.Controls.Text(item)
            self.text:SetFont("Arial", 16)
            self.index = 0
            item.Layouter(self.text)
                :AtCenterIn(item)
                :DisableHitTest()
        end,

        ---Called when grid item receives an event
        ---@param self ExampleComponent
        ---@param item Item
        ---@param event KeyEvent
        HandleEvent = function(self, item, event)
            LOG(self.index)
        end,

        ---Called when item is activated with this component event handling
        ---@param self ExampleComponent
        ---@param item Item
        Enable = function(self, item)
            self.text:Show()
        end,

        ---@param self ExampleComponent
        ---@param action string
        SetAction = function(self, action)
            self.index = action
            self.text:SetText(action)
        end,

        ---Called when item is changing event handler
        ---@param self ExampleComponent
        ---@param item Item
        Disable = function(self, item)
            self.text:Hide()
        end,

        ---Called when component is being destroyed
        ---@param self ExampleComponent
        Destroy = function(self)
            self.text:Destroy()
            self.text = nil
        end,
    },
}
