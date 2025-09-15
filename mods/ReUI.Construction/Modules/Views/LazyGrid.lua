local BaseGridPanel = ReUI.UI.Views.Grid.BaseGridPanel

---@class LazyGrid : BaseGridPanel
LazyGrid = ReUI.Core.Class(BaseGridPanel)
{
    ---@param self LazyGrid
    Resize = function(self)
        self:ClearGrid()
    end,

    ---@param self LazyGrid
    CheckItems = function(self)
        if self._items then
            return
        end

        local rows = self:ComputeRows()
        local columns = self:ComputeColumns()
        self:CreateItems(rows, columns)
        self:LayoutItems()
    end,

    ---@param self LazyGrid
    ---@return ReUI.UI.Controls.Control[][]
    GetItems = function(self)
        self:CheckItems()
        return BaseGridPanel.GetItems(self)
    end,
}
