---@diagnostic disable-next-line:different-requires
local BaseGridItem = import("BaseGridItem.lua").BaseGridItem

---@type ReUI.UI.Views.Grid.Grid
local Grid = import("Grid.lua").Grid

---@class BaseGridPanel : ReUI.UI.Views.Grid.Grid
BaseGridPanel = ReUI.Core.Class(Grid)
{
    ItemClass = BaseGridItem,

    ---@param self BaseGridPanel
    ---@param row number
    ---@param column number
    ---@return BaseGridItem
    CreateItem = function(self, row, column)
        return self.ItemClass(self)
    end,

    ---@param self BaseGridPanel
    ---@param columns number
    ---@param rows number
    CreateItems = function(self, rows, columns)
        Grid.CreateItems(self, rows, columns)

        local componentClasses = self:GetItemComponentClasses()
        self:IterateItemsVertically(function(grid, item, row, column)
            item.ComponentClasses = componentClasses
        end)
    end,

    ---@param self BaseGridPanel
    ---@param name string
    ---@param class fun(instance:BaseGridItem):AItemComponent
    AddItemComponent = function(self, name, class)
        self:IterateItemsVertically(function(grid, item, row, column)
            item:AddComponent(name, class(item))
        end)
    end,

    ---@param self BaseGridPanel
    DisableItems = function(self)
        self:IterateItemsVertically(function(grid, item, row, column)
            item:Disable()
        end)
    end,

    ---@param self BaseGridPanel
    OnResized = function(self)
        self:DisableItems()
    end,

    ---@param self BaseGridPanel
    Refresh = function(self)
    end,

    ---@param self BaseGridPanel
    ---@return table<string, fun(instance: BaseGridItem):AItemComponent>
    GetItemComponentClasses = function(self)
        return {}
    end,
}
