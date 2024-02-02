local IItemComponent = import("IItemComponent.lua").IItemComponent

---@class ISelectionHandler
ISelectionHandler = Class()
{
    ---@param self ISelectionHandler
    ---@param selection UserUnit[]
    ---@return string[]?
    OnSelectionChanged = function(self, selection)
    end,

    ---@type IItemComponent
    ComponentClass = IItemComponent,
}
