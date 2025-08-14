local IItemComponent = import("IItemComponent.lua").IItemComponent

---@class ISelectionHandler
---@field Name string
---@field Description string
---@field Enabled boolean
ISelectionHandler = Class()
{
    Enabled = false,
    ---@param self ISelectionHandler
    ---@param selection UserUnit[]
    ---@return string[]?
    OnSelectionChanged = function(self, selection)
    end,

    ---@type IItemComponent
    ComponentClass = IItemComponent,
}
