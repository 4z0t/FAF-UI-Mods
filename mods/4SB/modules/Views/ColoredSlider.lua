local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Border = import("Border.lua").Border
local LazyVar = import('/lua/lazyvar.lua').Create
local Text = import("/lua/maui/text.lua").Text
local Dragger = import("/lua/maui/dragger.lua").Dragger

local LayoutFor = UMT.Layouter.ReusedLayoutFor


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
                    control:SetColor(self._downColor)
                    local value = self:CalculateValueFromMouse(x, y)
                    if self:SetValue(value) then
                        self:OnScrub(value)
                    end
                end

                dragger.OnRelease = function(_dragger, x, y)
                    local value = self:CalculateValueFromMouse(x, y)
                    if control:HitTest(x, y) then
                        control:SetColor(self._overColor)
                    else
                        control:SetColor(self._upColor)
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
            if self:SetValue(value) then
                self:OnValueSet(self._currentValue())
            end
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
                :AtHorizontalCenterIn(self)
                :Width(lineWidth)
                :Top(self.Top)
                :Bottom(self.Bottom)
                :Color(lineColor)
                :DisableHitTest()

            LayoutFor(self._center)
                :AtCenterIn(self)
                :Width(function() return self.Width() / 2 end)
                :Height(lineWidth)
                :Color(lineColor)
                :DisableHitTest()

            LayoutFor(self._thumb)
                :Height(lineWidth * 5)
                :Width(self.Width)
                :AtHorizontalCenterIn(self)
                :Top(function()
                    return math.floor(self.Bottom() -
                        (((self._currentValue() - self._startValue) / (self._endValue - self._startValue)) *
                            (self.Height())) - self._thumb.Height() / 2)
                end)
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
        value = self:_Constrain(value)
        if value ~= self:GetValue() then
            self._currentValue:Set(value)
            self:OnValueChanged(value)
            return true
        end
        return false
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
        if self._isVertical then
            return self._startValue +
                (self.Bottom() - y) / (self.Height() - self._thumb.Height()) * (self._endValue - self._startValue)
        else
            return self._startValue +
                (x - self.Left()) / (self.Width() - self._thumb.Width()) * (self._endValue - self._startValue)
        end
    end,

    _Constrain = function(self, value)
        return math.clamp(value, self._startValue, self._endValue)
    end,

    OnValueSet = function(self, newValue) end,

    OnValueChanged = function(self, newValue) end,

    OnBeginChange = function(self) end,
    OnEndChange = function(self) end,

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
            if self:SetValue(value) then
                self:OnValueSet(self._currentValue())
            end
            return true
        end
        return ColoredSlider.HandleEvent(self, event)
    end,
}
