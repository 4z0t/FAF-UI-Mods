local Group = import('/lua/maui/group.lua').Group

local math = math

---@class ReUI.UI.Views.StaticScrollable : Group
---@field _topLine  number
---@field _dataSize number
---@field _numLines number
StaticScrollable = Class(Group) {

    ---@param self ReUI.UI.Views.StaticScrollable
    ---@param topIndex number
    ---@param dataSize number
    ---@param numLines number
    Setup = function(self, topIndex, dataSize, numLines)
        self._topLine = topIndex
        self._dataSize = dataSize
        self._numLines = numLines
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    GetScrollValues = function(self, axis)
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines - 1, self._dataSize)
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + delta)
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + math.floor(delta) * self._numLines)
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    ScrollSetTop = function(self, axis, top)
        top = math.floor(math.max(math.min(self._dataSize - self._numLines + 1, top), 1))
        if top == self._topLine then return end
        self._topLine = top
        self:CalcVisible()
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self._numLines)
    end,

    ---Determines what controls should be visible or not
    ---@param self ReUI.UI.Views.StaticScrollable
    CalcVisible = function(self)
        local lineIndex = 1
        for index = self._topLine, self._numLines + self._topLine - 1 do
            self:RenderLine(lineIndex, index)
            lineIndex = lineIndex + 1
        end
    end,

    ---Overload for rendering lines
    ---@param self ReUI.UI.Views.StaticScrollable
    ---@param lineIndex number
    ---@param scrollIndex number
    RenderLine = function(self, lineIndex, scrollIndex)
        WARN(debug.traceback("Not implemented method!"))
    end,

    ---@param self ReUI.UI.Views.StaticScrollable
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
        end
        return self:OnEvent(event)
    end,

    ---HandleEvent overload
    ---@param self ReUI.UI.Views.StaticScrollable
    ---@param event KeyEvent
    ---@return boolean
    OnEvent = function(self, event)
        return true
    end
}
