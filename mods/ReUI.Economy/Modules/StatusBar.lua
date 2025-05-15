local LazyVar = import('/lua/lazyvar.lua').Create

local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text


---@class EStatusBar : ReUI.UI.Controls.Bitmap
---@field _max Lazy<number>
---@field _min Lazy<number>
---@field _value Lazy<number>
---@field _bar ReUI.UI.Controls.Bitmap
StatusBar = ReUI.Core.Class(Bitmap)
{
    ---@param self EStatusBar
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self._min = LazyVar(0)
        self._max = LazyVar(1)
        self._value = LazyVar(0)

        self._bar = Bitmap(self)
    end,

    Percent = ReUI.Core.Property
    {
        ---@param self EStatusBar
        ---@return number
        get = function(self)
            local min = self._min()
            local max = self._max()
            local range = max - min

            if range == 0 then
                return 0
            end

            local value = self._value()

            return (value - min) / (range)
        end
    },

    ---@type number
    Value = ReUI.Core.Property
    {
        ---@param self EStatusBar
        get = function(self)
            return self._value()
        end,

        ---@param self EStatusBar
        set = function(self, value)
            self._value:Set(math.clamp(value, self._min(), self._max()))
        end
    },

    ---@type number
    Max = ReUI.Core.Property
    {
        ---@param self EStatusBar
        ---@return number
        get = function(self)
            return self._max()
        end,

        ---@param self EStatusBar
        ---@param value number
        set = function(self, value)
            self._max:Set(value)
        end
    },

    ---@type number
    Min = ReUI.Core.Property
    {
        ---@param self EStatusBar
        ---@return number
        get = function(self)
            return self._min()
        end,

        ---@param self EStatusBar
        ---@param value number
        set = function(self, value)
            self._min:Set(value)
        end
    },

    ---@type Color
    BarColor = ReUI.Core.Property
    {
        ---@param self EStatusBar
        ---@param color Color
        set = function(self, color)
            self._bar:SetSolidColor(color)
        end
    },

    ---@param self EStatusBar
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._bar)
            :Left(self.Left)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :Width(function()
                return self.Percent * self.Width()
            end)

        layouter(self)
            :Color("ff000000")
    end
}
