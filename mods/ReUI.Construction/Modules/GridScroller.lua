local math = math

---@class GridScroller
---@field _current number
---@field _max number
---@field _grid BaseGridPanel
GridScroller = ReUI.Core.Class()
{
    ---@param self GridScroller
    ---@param grid BaseGridPanel
    __init = function(self, grid)
        self._grid = grid

        self._current = 1
        self._max = 1
    end,

    ItemCount = ReUI.Core.Property
    {
        ---@param self GridScroller
        set = function(self, value)
            self._max = math.ceil(value / self.LineSize)
        end
    } --[[@as number]] ,

    Max = ReUI.Core.Property
    {
        ---@param self GridScroller
        get = function(self)
            return math.max(1, self._max - self.LineCount + 1)
        end,
    } --[[@as number]] ,

    Current = ReUI.Core.Property
    {
        ---@param self GridScroller
        get = function(self)
            return math.clamp(self._current, 1, self.Max)
        end,
    } --[[@as number]] ,

    StartIndex = ReUI.Core.Property
    {
        ---@param self GridScroller
        get = function(self)
            return (self.Current - 1) * self.LineSize + 1
        end,
    } --[[@as number]] ,

    LineSize = ReUI.Core.Property
    {
        ---@param self GridScroller
        get = function(self)
            return 1
        end,
    } --[[@as number]] ,

    LineCount = ReUI.Core.Property
    {
        ---@param self GridScroller
        get = function(self)
            return 1
        end,
    } --[[@as number]] ,


    ---@param self GridScroller
    ---@param delta number
    ---@return boolean
    ---@return number
    TryScroll = function(self, delta)
        local maxTop = self._max - self.LineCount + 1
        local curTop = math.max(1, math.min(maxTop, self._current))
        local newTop = math.max(1, math.min(maxTop, curTop + delta))
        return curTop ~= newTop, newTop
    end,

    ---@param self GridScroller
    ---@param delta number
    ---@return boolean
    Scroll = function(self, delta)
        local can, newTop = self:TryScroll(delta)
        if can then
            self._current = newTop
            return true
        end
        return false
    end,

    ---@param self GridScroller
    ---@return boolean
    IsEnd = function(self)
        local can = self:TryScroll(1)
        return not can
    end,

    ---@param self GridScroller
    ---@return boolean
    IsStart = function(self)
        local can = self:TryScroll(-1)
        return not can
    end,

    ---@param self GridScroller
    ---@return boolean
    Next = function(self)
        return self:Scroll(1)
    end,

    ---@param self GridScroller
    ---@return boolean
    Prev = function(self)
        return self:Scroll(-1)
    end,

    ---@param self GridScroller
    ScrollStart = function(self)
        if self._current == 1 then
            return false
        end
        self._current = 1
        return true
    end,

    ---@param self GridScroller
    ScrollEnd = function(self)
        local endValue = self.Max

        if self._current == endValue then
            return false
        end
        self._current = endValue
        return true
    end,

    ---@param self GridScroller
    Destroy = function(self)
        self._grid = nil
    end,

}

---@class HorizontalGridScroller : GridScroller
HorizontalGridScroller = ReUI.Core.Class(GridScroller)
{
    LineSize = ReUI.Core.Property
    {
        ---@param self HorizontalGridScroller
        get = function(self)
            return self._grid.Rows
        end,
    } --[[@as number]] ,

    LineCount = ReUI.Core.Property
    {
        ---@param self HorizontalGridScroller
        get = function(self)
            return self._grid.Columns
        end,
    } --[[@as number]] ,
}

---@class VerticalGridScroller : GridScroller
VerticalGridScroller = ReUI.Core.Class(GridScroller)
{
    LineSize = ReUI.Core.Property
    {
        ---@param self VerticalGridScroller
        get = function(self)
            return self._grid.Columns
        end,
    } --[[@as number]] ,

    LineCount = ReUI.Core.Property
    {
        ---@param self HorizontalGridScroller
        get = function(self)
            return self._grid.Rows
        end,
    } --[[@as number]] ,
}
