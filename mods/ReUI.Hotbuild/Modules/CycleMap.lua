local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local BaseGridPanel = ReUI.UI.Views.Grid.BaseGridPanel

local UIUtil = import("/lua/ui/uiutil.lua")

---@class CycleMapBorder : ReUI.UI.Controls.Group
CycleMapBorder = ReUI.Core.Class(Group)
{
    ---@param self CycleMapBorder
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)
    end,

    ---@param self CycleMapBorder
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

    end,
}



---@class CycleMap : BaseGridPanel
---@field _position number
---@field _frameTimer number
---@field _max number
---@field _name string
CycleMap = ReUI.Core.Class(BaseGridPanel)
{
    ResetTime = 1.1,

    ItemClass = Bitmap,

    ---@param self CycleMap
    ---@param parent Control
    __init = function(self, parent)
        BaseGridPanel.__init(self, parent)
        self.Rows = 1
        self.Columns = 1

        self.ColumnWidth = 48
        self.RowHeight = 48

        self.HorizontalSpacing = 2
        self.VerticalSpacing = 2

        self._position = 0
        self._frameTimer = 0
        self._max = 0
    end,

    ---@param self BaseGridPanel
    ---@param item AGridItem
    ---@param row number
    ---@param column number
    PositionItem = function(self, item, row, column)
        BaseGridPanel.PositionItem(self, item, row, column)
        local layouter = self.Layouter
        layouter(item)
            :Width(layouter:ScaleVar(self._columnWidth))
            :Height(layouter:ScaleVar(self._rowHeight))
            :DisableHitTest()
    end,

    ---@param self CycleMap
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        BaseGridPanel.InitLayout(self, layouter)

        layouter(self)
            :Depth(1000)
            :DisableHitTest()
    end,

    ---@param self CycleMap
    ---@param delta number
    OnFrame = function(self, delta)
        self._frameTimer = self._frameTimer + delta
        if self._frameTimer > self.ResetTime then
            self:HideCycle()
        end
    end,

    ---@param self CycleMap
    ---@param blueprints BlueprintId[]
    SetBlueprintsForDisplay = function(self, blueprints)
        self.Columns = table.getn(blueprints)

        local i = 1
        self:IterateItemsHorizontally(function(grid, item, row, column)
            item:SetTexture(UIUtil.SkinnableFile('/icons/units/' .. blueprints[i] .. '_icon.dds'--[[@as FileName]] ))
            i = i + 1
        end)
    end,

    ---@param self CycleMap
    ---@param maxPos number
    ---@param name string
    ---@param blueprints BlueprintId[]
    ---@param modifier ("Alt"|"Shift")?
    ---@return number
    Cycle = function(self, maxPos, name, blueprints, modifier)
        if self._name == name and self._max == maxPos then
            if modifier == 'Alt' then
                self._position = self._position - 1
                if self._position < 1 then
                    self._position = maxPos
                end
            else
                self._position = self._position + 1
                if self._position > maxPos then
                    self._position = 1
                end
            end
        else
            self:SetBlueprintsForDisplay(blueprints)
            self._name = name
            self._max = maxPos
            self._position = 1
        end
        self:Preview()
        return self._position
    end,

    ---@param self CycleMap
    ResetCycle = function(self)
        self._position = 0
        self._name = nil
    end,

    ---@param self CycleMap
    HideCycle = function(self)
        self._frameTimer = 0
        self:SetNeedsFrameUpdate(false)
        self:Hide()
    end,

    ---@param self CycleMap
    Preview = function(self)
        local pos = self._position
        self:Show()
        local i = 1
        self:IterateItemsHorizontally(function(grid, item, row, column)
            if i == pos then
                item:SetAlpha(1)
            else
                item:SetAlpha(0.4)
            end

            i = i + 1
        end)
        self:SetNeedsFrameUpdate(true)
    end,


}
