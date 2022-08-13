local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Border = import("Border.lua").Border
local LazyVar = import('/lua/lazyvar.lua').Create
local LayoutFor = import("/lua/maui/layouthelpers.lua").ReusedLayoutFor
local Text = import("/lua/maui/text.lua").Text
local Dragger = import("/lua/maui/dragger.lua").Dragger


ColoredSlider = Class(Group)
{
    __init = function(self, parent,
                      isVertical,
                      startValue,
                      endValue,
                      lineColor,
                      thumbColor,
                      thumbOver,
                      thumbDown,
                      lineWidth)
        Group.__init(self, parent)

        self._isVertical = isVertical
        self._startValue = startValue
        self._currentValue = LazyVar(startValue)
        self._endValue = endValue

        self._overColor = thumbOver
        self._downColor = thumbDown
        self._upColor = thumbColor


        self._line = Bitmap(self)
        self._center = Bitmap(self)
        self._thumb = Border(self, thumbColor, lineWidth)


        self._thumb.HandleEvent = function(control, event)
            local eventHandled = false
            if event.Type == 'ButtonPress' then
                local dragger = Dragger()
                dragger.OnMove = function(_dragger, x, y)
                    local value = self:CalculateValueFromMouse(x, y)
                    value = self:_Constrain(value)
                    local curVal = self:GetValue()
                    self._thumb:SetColor(self._downColor)
                    if value ~= curVal then
                        self:SetValue(value)
                        self:OnScrub(value)
                    end
                end

                dragger.OnRelease = function(_dragger, x, y)
                    local value = self:CalculateValueFromMouse(x, y)
                    if (x < self._thumb.Left() or x > self._thumb.Right()) or
                        (y < self._thumb.Top() or y > self._thumb.Bottom()) then
                        self._thumb:SetColor(self._upColor)
                    else
                        self._thumb:SetColor(self._overColor)
                    end
                    self:SetValue(value)
                    self:OnValueSet(self:_Constrain(value))
                    self:OnEndChange()
                    dragger:Destroy()
                end
                control:SetColor(self._downColor)
                self:OnBeginChange()
                PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
                eventHandled = true
            elseif event.Type == 'MouseEnter' then
                control:SetColor(self._overColor)
            elseif event.Type == 'MouseExit' then
                control:SetColor(self._upColor)
            end

            return eventHandled
        end



    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local value = self:CalculateValueFromMouse(event.MouseX, event.MouseY)
            self:SetValue(value)
            self:OnValueSet(self._currentValue())
            return true
        end
    end,

    __post_init = function(self, parent,
                           isVertical,
                           startValue,
                           endValue,
                           lineColor,
                           thumbColor,
                           thumbOver,
                           thumbDown,
                           lineWidth)
        self:_Layout(lineColor, thumbColor, lineWidth)
    end,

    _Layout = function(self, lineColor, thumbColor, lineWidth)
        if self._isVertical then
            LayoutFor(self._line)
        else
            LayoutFor(self._line)
                :AtVerticalCenterIn(self)
                :Height(lineWidth)
                :Left(self.Left)
                :Right(self.Right)
                :Color(lineColor)
                :DisableHitTest()

            LayoutFor(self._center)
                :AtCenterIn(self)
                :Width(lineWidth)
                :Height(function() return self.Height() / 2 end)
                :Color(lineColor)
                :DisableHitTest()

            LayoutFor(self._thumb)
                :Height(self.Height)
                :Width(lineWidth * 5)
                :AtVerticalCenterIn(self)
                :Left(function()
                    return math.floor(self.Left() +
                        (((self._currentValue() - self._startValue) / (self._endValue - self._startValue)) *
                            (self.Width())) - self._thumb.Width() / 2)
                end)



        end

    end,

    -- this will constrain your values to not exceed min or max
    SetValue = function(self, value)
        self._currentValue:Set(self:_Constrain(value))
        self:OnValueChanged(self._currentValue())
    end,

    GetValue = function(self)
        return self._currentValue()
    end,

    SetStartValue = function(self, startValue)
        self._startValue = startValue
        self:SetValue(self._currentValue())
    end,

    SetEndValue = function(self, endValue)
        self._endValue = endValue
        self:SetValue(self._currentValue())
    end,

    CalculateValueFromMouse = function(self, x, y)
        local newValue = self._currentValue()
        if self._isVertical then
            newValue = self._startValue +
                (
                ((self.Bottom() - y) / (self.Height() - self._thumb.Height())) *
                    (self._endValue - self._startValue))
        else
            newValue = self._startValue +
                (
                ((x - self.Left()) / (self.Width() - self._thumb.Width())) *
                    (self._endValue - self._startValue))
        end
        return newValue
    end,

    _Constrain = function(self, value)
        return math.max(math.min(value, self._endValue), self._startValue)
    end,

    -- overload to be informed when the value is set by a mouse release
    OnValueSet = function(self, newValue) end,

    -- overload to be informed when the value is changed
    OnValueChanged = function(self, newValue) end,

    -- overload to be informed when someone starts and stops dragging the
    -- slider
    OnBeginChange = function(self) end,
    OnEndChange = function(self) end,

    -- overload to be informed during scrub
    OnScrub = function(self, value) end,


}


ColoredIntegerSlider = Class(ColoredSlider)
{
    __init = function(self, parent,
                      isVertical,
                      startValue,
                      endValue,
                      indentValue,
                      lineColor,
                      thumbColor,
                      thumbOver,
                      thumbDown,
                      lineWidth)
        ColoredSlider.__init(self, parent,
            isVertical,
            math.floor(startValue),
            math.floor(endValue),
            lineColor,
            thumbColor,
            thumbOver,
            thumbDown,
            lineWidth
        )
        self._indentValue = math.floor(indentValue)
    end,

    _Constrain = function(self, value)
        value = ColoredSlider._Constrain(self, value)
        value = math.floor(value / self._indentValue) * self._indentValue
        return value
    end,

    __post_init = function(self, parent,
                           isVertical,
                           startValue,
                           endValue,
                           indentValue,
                           lineColor,
                           thumbColor,
                           thumbOver,
                           thumbDown,
                           lineWidth)
        ColoredSlider.__post_init(self, parent,
            isVertical,
            math.floor(startValue),
            math.floor(endValue),
            lineColor,
            thumbColor,
            thumbOver,
            thumbDown,
            lineWidth)
    end,

    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local value = self._currentValue()
            if event.WheelRotation > 0 then
                value = value + self._indentValue
            else
                value = value - self._indentValue
            end
            self:SetValue(value)
            self:OnValueSet(self._currentValue())
            return true
        end
        return ColoredSlider.HandleEvent(self, event)
    end,
}
