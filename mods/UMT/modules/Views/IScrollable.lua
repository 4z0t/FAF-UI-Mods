local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')



---@class IScrollable
---@field _topLine  integer
---@field _dataSize integer
---@field _numLines integer
IScrollable = Class(Group) {

    Setup = function(self, topIndex, dataSize, numLines)
        self._topLine = topIndex
        self._dataSize = dataSize
        self._numLines = numLines
    end,

    GetScrollValues = function(self, axis)
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines - 1, self._dataSize)
    end,

    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + delta)
    end,

    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + math.floor(delta) * self._numLines)
    end,

    ScrollSetTop = function(self, axis, top)
        top = math.floor(math.max(math.min(self._dataSize - self._numLines + 1, top), 1))
        if top == self._topLine then
            return
        end
        self._topLine = top
        self:CalcVisible()
    end,

    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self._numLines)
    end,

    ---Determines what controls should be visible or not
    ---@generic K, V
    ---@param self IScrollable
    ---@param data? table<K,V>
    CalcVisible = function(self, data)
        local lineIndex = 1
        local key, value = self:DataIter(data, nil)

        for index = self._topLine, self._numLines + self._topLine - 1 do
            self:RenderLine(lineIndex, index, key, value)
            if key ~= nil then
                key, value = self:DataIter(data, key)
            end
            lineIndex = lineIndex + 1
        end
    end,

    ---Iterates over given data while CalcVisible, overload for more functions
    ---@generic K, V
    ---@param self IScrollable
    ---@param data? table<K,V>
    ---@param key? any
    ---@return K
    ---@return V
    DataIter = function(self, data, key)
        return nil, nil
    end,

    ---Overload for rendering lines
    ---@generic K, V
    ---@param self IScrollable
    ---@param lineIndex integer
    ---@param scrollIndex integer
    ---@param key K
    ---@param value V
    RenderLine = function(self, lineIndex, scrollIndex, key, value)
        WARN(debug.traceback("Not implemented method!"))
    end,

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
    ---@param self IScrollable
    ---@param event Event
    ---@return boolean
    OnEvent = function(self, event)
        return true
    end
}
