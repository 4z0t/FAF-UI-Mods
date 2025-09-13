---@meta


---@class ReUI.UI.Views.Grid : ReUI.Module
ReUI.UI.Views.Grid = {}

ReUI.UI.Views.Grid.Abstract = {
    ---@class AItemComponent
    AItemComponent = ...,
    ---@class ASelectionHandler
    ASelectionHandler = ...,
}

---@class BaseGridItem
ReUI.UI.Views.Grid.BaseGridItem = ...
---@class BaseGridPanel
ReUI.UI.Views.Grid.BaseGridPanel = ...

---@type ReUI.UI.Views.Grid.Grid
ReUI.UI.Views.Grid.Grid = ...
