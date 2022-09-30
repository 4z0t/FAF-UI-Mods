local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')

IScrollable = Class(Group) {
    --[[
        _dataSize
        _topLine
        _numLines
    ]]
    __init = function(self, parent, useScroll)
        Group.__init(self, parent)
        self._topLine = 1
        if useScroll then 
            self._scroll = UIUtil.CreateVertScrollbarFor(self) -- scroller
        end
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

    -- determines what controls should be visible or not
    CalcVisible = function(self)
        local invIndex = 1
        local lineIndex = 1
        for index = self._topLine, self._numLines + self._topLine - 1 do
            self:RenderLine(lineIndex, index)
            lineIndex = lineIndex + 1
        end
    end,

    -- overload
    RenderLine = function(self, lineIndex, scrollIndex)

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

    -- overload
    OnEvent = function(self, event)
        return true
    end
}